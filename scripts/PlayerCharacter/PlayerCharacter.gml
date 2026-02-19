// Core player character logic: variable setup, physics movement, shooting,
// and sprite state selection.  These functions are shared between the
// singleplayer and multiplayer player objects.

// ---------------------------------------------------------------------------
// Initialises every instance variable the player needs before the first step.
// Call this once in the Create event after steamID has been set.
// ---------------------------------------------------------------------------
function variableInitAll(){
	// Steam session identifiers
	localSteamID = steam_get_user_steam_id()
	lobbyHost    = steam_lobby_get_owner_id()
	isHost       = steam_lobby_is_owner()
	isLocal      = (localSteamID == steamID)  // true only for the instance owned by this machine
	playerID     = id

	// Collision references
	// collision_tilemap_id — terrain tiles on the CollisionLayer
	// objSolid             — physics solid objects placed in the room
	collision_tilemap_id = layer_tilemap_get_id("CollisionLayer");
	collisionObjects = [objSolid, collision_tilemap_id]
	collision = false;

	// Frame-count timers
	cwjt           = 0   // coyote / wall-jump grace timer (counts down from wallJumpTimer)
	fireCooldown   = 10  // minimum frames between shots
	currentCooldown = 0  // current frames remaining before next shot is allowed

	// Movement state flags
	wallJump     = 0;    // 1 while the wall-jump window is active
	canJump      = true; // false while airborne (prevents double-jump)
	canSlide     = false
	isCrawling   = false;
	releasedJump = false;

	// Physics constants
	grav        = 0.4;
	jumpSpeed   = -10;   // applied to ySpeed on jump (negative = upward in GML)
	fallCooldown = 0;    // coyote-time counter: lets the player jump for a few frames after walking off a ledge
	climbHeight  = 8;    // maximum pixels the slope-climber can step up per frame
	wallJumpTimer = 20;  // frames the wall-jump window stays open after leaving a wall

	// Set by horizontal wall collision: 0 = left wall hit, 180 = right wall hit
	collisionAngle = 0;
}

// ---------------------------------------------------------------------------
// Stores the current room position as the respawn point (singleplayer only).
// Call after placing the player at the intended spawn location.
// ---------------------------------------------------------------------------
function variableInitSP(){
	respawn_x = x;
	respawn_y = y;
}

// ---------------------------------------------------------------------------
// Creates a ds_map that pairs each parallax background layer ID with its
// scroll coefficient.  Positive values scroll slower than the camera
// (distant layers); negative values scroll faster (foreground layers).
// ---------------------------------------------------------------------------
function parallaxDefinition(){
	background_map = ds_map_create();
	background_map[? layer_get_id("bgClouds")]        =  0.3;
	background_map[? layer_get_id("bgDistantGround")] =  0.2;
	background_map[? layer_get_id("bgNearGround")]    =  0.1;
	background_map[? layer_get_id("bgGroundPath")]    =  0;
	background_map[? layer_get_id("bgForeground")]    = -0.5;
}

// ---------------------------------------------------------------------------
// Sets up the viewport for the local player (singleplayer).
// The game renders at a 320×240 internal resolution then scales to 1280×720.
// Only the local player's instance configures the view; remote instances skip.
// ---------------------------------------------------------------------------
function viewInitSP(){
	vpSizeWidth  = 1280
	vpSizeLength = 720
	if(isLocal){
	    view_enabled    = true;
		view_visible[1] = true;
		view_wport[1]   = vpSizeWidth
		view_hport[1]   = vpSizeLength
		camera_set_view_size(view_camera[1], 320, 240); // internal render resolution
		surface_resize(application_surface, view_wport[1], view_hport[1]);
		window_set_size(vpSizeWidth, vpSizeLength);
		window_center();
		camera_set_view_size(view_camera[1], 320, 240);
		target_instance = playerID  // camera follows this instance
	}
}

// ---------------------------------------------------------------------------
// Main physics update — call every Step event.
// Handles acceleration, deceleration, gravity, jumping, wall-jumping,
// slope climbing, and the slide/crawl mechanic.
// ---------------------------------------------------------------------------
function paddle_movement() {
    var maxSpeedX = 7
	var maxSpeedY = 15
    var accel = 0.3;

	// Ground-contact checks used repeatedly below
	var onGround = place_meeting(x, y+1, collision_tilemap_id);
	var onSolid  = place_meeting(x, y+1, objSolid)

    // --- Acceleration / deceleration ---
    // clamp keeps speed within [-max, max]; adding xInput * accel ramps up
    xSpeed = clamp(xSpeed + xInput * accel, -maxSpeedX, maxSpeedX);
    ySpeed = clamp(ySpeed + yInput * accel, -maxSpeedY, maxSpeedY);
	ySpeed += grav;  // gravity applied every frame

    // Friction: bleed horizontal speed toward 0 when no directional input
    if (xInput == 0) {
        if (xSpeed > 0) xSpeed = max(0, xSpeed - accel);
        else if (xSpeed < 0) xSpeed = min(0, xSpeed + accel);
    }
    // Same for vertical (mainly relevant for swimming / floating modes)
    if (yInput == 0) {
        if (ySpeed > 0) ySpeed = max(0, ySpeed - accel);
        else if (ySpeed < 0) ySpeed = min(0, ySpeed + accel);
    }

	// --- Ground state ---
	if(onGround){
		ySpeed = -0.25  // tiny upward push keeps the player flush with the surface
		if(yInput == 0) {
			canJump = true;
		}
		fallCooldown = 20;  // reset coyote-time window
	}

	// While on the ground (or within the coyote window) keep cwjt fully charged
	if(wallJump == 0 && canJump == true){
		cwjt = wallJumpTimer;
	}

	// Extra gravity pass to enforce terminal velocity
	if(ySpeed < 10){
		ySpeed += grav
	}

	// Open the wall-jump window whenever cwjt has been charged
	if(cwjt > 0){
		wallJump = 1
	}

	// --- Horizontal wall collision (also drives wall-jump) ---
	if (place_meeting(x + xSpeed, y + ySpeed, objSolid)){
		// Record which side was hit so wall-jump can kick off in the right direction
		if (xSpeed > 0){
			collisionAngle = 180;  // right wall
		}
		if (xSpeed < 0){
			collisionAngle = 0;    // left wall
		}
		wallJump = 0;

		// Wall-jump: player is airborne, pressing up, and within the fall-cooldown window
		if(canJump == 0 && yInput == -1 && fallCooldown <= 0){
			if(collisionAngle == 0 && xInput == -1 && xSpeed <= .5){
				xSpeed = xSpeed + 15   // launch away from the left wall
				ySpeed -= 15
			}
			else if(collisionAngle == 180 && xInput == 1 && xSpeed <= .5){
				xSpeed -= xSpeed + 15  // launch away from the right wall
				ySpeed -= 15
			}
		}
	}

	// --- Vertical collision with solid objects ---
	if (place_meeting(x, y + ySpeed, objSolid)){
		canJump = true;
		// Nudge to exact contact before zeroing speed
		while (!place_meeting(x, y + sign(ySpeed), objSolid)){
			y += sign(ySpeed);
			wallJump = 0;
		}
		ySpeed = 0;
		// Jump from solid surface
		if(yInput == -1 && place_meeting(x, y + 1, objSolid) && canJump){
			ySpeed = jumpSpeed
			canJump = false;
		}
	}

	// --- Vertical collision with tilemap terrain (same logic as above) ---
	if (place_meeting(x, y + ySpeed, collision_tilemap_id)){
		while (!place_meeting(x, y + sign(ySpeed), collision_tilemap_id)){
			y += sign(ySpeed);
			wallJump = 0;
		}
		ySpeed = 0;
		// Jump from tile surface
		if(yInput == -1 && place_meeting(x, y + 1, collision_tilemap_id) && canJump){
			ySpeed = jumpSpeed
			canJump = false;
		}
	}

	// Tick down timers each frame
	if (fallCooldown > 0 && !canJump){
		fallCooldown -= 1;
	}
	if (cwjt >= 0){
		cwjt -= 1;
	}
	// When the wall-jump window expires, close it
	if (cwjt <= 0){
		cwjt     = 0
		wallJump = 0;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	///////////////////
	// Enable Slopes //
	///////////////////
	// When the player would walk into a solid horizontally, check whether
	// the obstacle is short enough to step over (i.e. a slope or low ledge).
	if (place_meeting(x + xSpeed, y, objSolid))
	{
	    // Slide up to the wall pixel-by-pixel
	    while (!place_meeting(x + sign(xSpeed), y, objSolid))
	    {
	        x += sign(xSpeed);
	    }

		// Scan upward one pixel at a time until the path is clear or we exceed climbHeight
		var dy = 0;
		while(place_meeting(x + xSpeed, y - dy, objSolid) && dy < climbHeight){
			dy++;
		}
		if (!place_meeting(x + xSpeed, y - dy, objSolid)) {
			// Obstacle is short enough — push the player up to walk over it
			y -= dy;
		}
		else {
			// Obstacle is too tall — stop horizontal movement
			xSpeed = 0;
		}
	}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**************/
	/* Slide Code */
	/**************/
	// Pressing down while moving triggers a speed-boost slide.
	// Pressing down while nearly still switches to the crawl state instead.
	if(yInput == 0 && sprite_index != sprPlayerDie){
		canSlide  = true;
		isCrawling = false
		mask_index = sprPlayerIdle;  // restore normal collision mask when upright
	}
	if(yInput == 1){
		if(canSlide && xSpeed > 0){
			xSpeed = xSpeed + 2    // boost forward
		}
		else if(canSlide && xSpeed < 0){
			xSpeed = xSpeed - 2    // boost forward (left direction)
		}
		else if(xSpeed >= -.3 && xSpeed < .3){
			isCrawling = true;     // nearly stationary → enter crawl
		}
		canSlide = false;  // slide can only trigger once per down-press
	}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////
	// Apply final player position //
	/////////////////////////////////
    x += xSpeed;
    y += ySpeed;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Decrement the fire cooldown each frame
	if currentCooldown > 0 then --currentCooldown;
}

// ---------------------------------------------------------------------------
// Fires a bullet in the direction of the mouse cursor.
// Creates muzzle-flash effects at the gun barrel position.
// Respects the fireCooldown so the player cannot shoot every frame.
// ---------------------------------------------------------------------------
function playerShoot(){
	if (actionKey == 1 && currentCooldown <= 0){
		var dist = 32;     // spawn bullet this many pixels from the player origin
		gun_distance = 20  // muzzle-flash effect distance (shorter than bullet spawn)
		var bullet_x = x + lengthdir_x(dist, mouseAngle);
		var bullet_y = y + lengthdir_y(dist, mouseAngle);
		var bullet = instance_create_layer(bullet_x, bullet_y, "Instances", obj_Bullet)
			bullet.direction  = mouseAngle
			bullet.image_angle = bullet.direction
			bullet.owner_id   = id   // track who fired for hit attribution
		audio_play_sound(wob_wob_2, 10, 0)
		// Muzzle-flash particle effects at the gun barrel
	    var _x = x + lengthdir_x(gun_distance, mouseAngle);
	    var _y = y + lengthdir_y(gun_distance, mouseAngle);
		effect_create_above(ef_smokeup, _x, _y, .05, c_ltgray);
		effect_create_above(ef_smoke,   _x, _y, .05, c_grey);
		effect_create_above(ef_spark,   _x, _y, .05, c_orange);
		currentCooldown = fireCooldown  // start the inter-shot cooldown
	}
}

// ---------------------------------------------------------------------------
// Chooses the correct sprite for the player's current movement state.
// Priority order (highest to lowest):
//   skidding → running → crawling → sliding → falling → idle
// global.stopShooting suppresses all sprite changes during a hit/death
// animation so those sequences play uninterrupted.
// ---------------------------------------------------------------------------
function playerSpriteIndexer(){
	var onGround = place_meeting(x, y+1, collision_tilemap_id);
	var onSolid  = place_meeting(x, y+1, objSolid)

	// Skid: moving but no input in that direction (decelerating)
	if(xSpeed < 3.5 && xSpeed > 0.05 && xInput == 0 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerSkid;
	}
	else if(xSpeed > -3.5 && xSpeed < -0.05 && xInput == 0 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerSkidLeft;
	}
	// Running right / left
	else if(xSpeed > 0.1 && xInput == 1 && canSlide && global.stopShooting == false){
		sprite_index = sprPlayerRun;
	}
	else if(xSpeed < -.1 && xInput == -1 && canSlide && global.stopShooting == false){
		sprite_index = sprPlayerRunLeft;
	}
	// Crawling (slow, ducked movement)
	else if(xSpeed < 0 && yInput == 1 && isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerCrawlLeft;
		mask_index   = sprPlayerCrawlLeft;
	}
	else if(isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerCrawl;
		mask_index   = sprPlayerCrawl;
	}
	// Sliding (speed-boost low stance)
	else if(xSpeed > 0 && yInput == 1 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerSlide;
		mask_index   = sprPlayerSlide;
	}
	else if(xSpeed < 0 && yInput == 1 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerSlideLeft;
		mask_index   = sprPlayerSlideLeft;
	}
	// Falling (airborne and moving downward, past coyote-time)
	else if(ySpeed > 0.5 && yInput != -1 && !onGround && fallCooldown <= 0 && xSpeed >= 0 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerFalling;
	}
	else if(ySpeed > 0.5 && yInput != -1 && !onGround && fallCooldown <= 0 && xSpeed < 0 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerFallingLeft;
	}
	// Idle: completely still
	else if(xInput == 0 && yInput == 0 && xSpeed == 0 && global.stopShooting == false){
		sprite_index = sprPlayerIdle
	}
}
