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
	if !variable_instance_exists(id, "steamID")
		|| steamID == undefined
		|| steamID == -1
		|| steamID == "-1"
		|| steamID == "" {
		steamID = localSteamID
	}
	if !variable_instance_exists(id, "steamName")
		|| steamName == undefined
		|| steamName == ""
		|| steamName == "Player" {
		steamName = steam_get_persona_name()
	}
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

	// Network reconciliation / interpolation
	netX      = 0      // server-authoritative x target
	netY      = 0      // server-authoritative y target
	hasNetPos = false  // true once first PLAYER_POSITION packet is received

	// Visual / cosmetic
	// steamName: may already be set via instance_create_layer variable struct (remote players);
	// fall back to the local Steam name for the own-player / singleplayer instance.
	if !variable_instance_exists(id, "steamName") || steamName == undefined {
		steamName = steam_get_persona_name()
	}
	playerColor = app_settings_current().player_color  // overridden post-spawn for remote players

	// Melee attack
	meleeTimer    = 0   // counts down from meleeDuration while kick animation plays
	meleeDuration = 32  // 8 anim frames * 4 steps/frame (15 fps sprite, 60 fps room)
	lastFacingDir = 1   // 1 = facing right, -1 = facing left

	// Slash (knife) attack
	slashTimer      = 0    // counts down while knife slash is active
	slashDuration   = 22   // 11 anim frames * 2 steps/frame (30 fps sprite, 60 fps room)
	slashFrame      = 0    // current animation frame 0-10 (read by Draw)
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
    var maxSpeedX = 8
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
		if(canJump == 0 && yInput == -1 && fallCooldown <= 0 && place_meeting(x + xSpeed, y + ySpeed, obj_Wall)){
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
//	if(place_meeting(x, y+1, objSolid) && canJump != 1){
//		audio_play_sound(land,10,0,5,.3,1)
//	}
	// --- Vertical collision with solid objects ---
	if (place_meeting(x, y + ySpeed, objSolid)){
		canJump = true;
		// Nudge to exact contact before zeroing speed
		var _solidStep = sign(ySpeed)
		if (_solidStep == 0) {
			mp_debug_log("move-guard", "solid overlap with zero y-step steam=" + string(steamID) + " pos=(" + string(x) + "," + string(y) + ")")
		} else {
			var _solidGuard = 0
			while (!place_meeting(x, y + _solidStep, objSolid) && _solidGuard < 1024){
				y += _solidStep;
				wallJump = 0;
				_solidGuard += 1
			}
			if (_solidGuard >= 1024) {
				mp_debug_log("move-guard", "solid vertical guard tripped steam=" + string(steamID) + " pos=(" + string(x) + "," + string(y) + ") step=" + string(_solidStep))
			}
		}
		ySpeed = 0;
		// Jump from solid surface
		if(yInput == -1 && place_meeting(x, y + 1, objSolid) && canJump){
			ySpeed = jumpSpeed
			canJump = false;
			audio_play_sound(jump,10,0,5,.3,1)
		}
	}

	// --- Vertical collision with tilemap terrain (same logic as above) ---
	if (place_meeting(x, y + ySpeed, collision_tilemap_id)){
		var _tileStep = sign(ySpeed)
		if (_tileStep == 0) {
			mp_debug_log("move-guard", "tile overlap with zero y-step steam=" + string(steamID) + " pos=(" + string(x) + "," + string(y) + ")")
		} else {
			var _tileGuard = 0
			while (!place_meeting(x, y + _tileStep, collision_tilemap_id) && _tileGuard < 1024){
				y += _tileStep;
				wallJump = 0;
				_tileGuard += 1
			}
			if (_tileGuard >= 1024) {
				mp_debug_log("move-guard", "tile vertical guard tripped steam=" + string(steamID) + " pos=(" + string(x) + "," + string(y) + ") step=" + string(_tileStep))
			}
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
		var _slideStep = sign(xSpeed)
		if (_slideStep == 0) {
			mp_debug_log("move-guard", "horizontal overlap with zero x-step steam=" + string(steamID) + " pos=(" + string(x) + "," + string(y) + ")")
			xSpeed = 0;
		} else {
	    // Slide up to the wall pixel-by-pixel
	    var _slideGuard = 0
	    while (!place_meeting(x + _slideStep, y, objSolid) && _slideGuard < 1024)
	    {
	        x += _slideStep;
			_slideGuard += 1
	    }
		if (_slideGuard >= 1024) {
			mp_debug_log("move-guard", "horizontal slide guard tripped steam=" + string(steamID) + " pos=(" + string(x) + "," + string(y) + ") step=" + string(_slideStep))
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
			bullet.owner_steam_id = steamID
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
// Reconciles the local predicted position with the server-authoritative
// position (isLocal) or interpolates remote players toward server truth.
// Call once per Step after paddle_movement().
// ---------------------------------------------------------------------------
function reconcile_net_position() {
    if (!hasNetPos) return;

    if (isLocal) {
        // Prediction reconciliation: correct local player gently toward server truth.
        // Large errors (>64 px total) snap immediately (desync recovery).
        // Small errors lerp at 25% per frame so corrections are invisible.
        // Note: speed is NOT zeroed on snap — killing momentum here would cause
        // the player to feel frozen whenever a correction fires under latency.
        var _err = abs(x - netX) + abs(y - netY);
        if (_err > 64) {
            x = netX;  y = netY;
        } else if (_err > 4) {
            x = lerp(x, netX, 0.25);
            y = lerp(y, netY, 0.25);
        }
        // Within 4 px: prediction was accurate, keep local position unchanged.
    } else {
        // Remote player interpolation: slide toward last known server position.
        x = lerp(x, netX, 0.3);
        y = lerp(y, netY, 0.3);
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
		if(!audio_is_playing(slide)){
			if(place_meeting(x, y+1, objSolid)){
				audio_play_sound(slide, 10, 0, 3,.2,2)
			}
		}
	}
	else if(xSpeed < 0 && yInput == 1 && !isCrawling && global.stopShooting == false){
		sprite_index = sprPlayerSlideLeft;
		mask_index   = sprPlayerSlideLeft;
		if(!audio_is_playing(slide)){
			audio_play_sound(slide, 10, 0, 3,.2,2)	
		}
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

	// Track last horizontal facing direction for the kick flip
	if (xInput > 0 || xSpeed > 0.1) {
		lastFacingDir = 1;
	} else if (xInput < 0 || xSpeed < -0.1) {
		lastFacingDir = -1;
	}
}

function playerSounds(){
	
	if (xInput != 0 && yInput == 0){
		if(!audio_is_playing(running)){
			audio_play_sound(running, 10, 0, 3,.5,2)	
		}
	}
	if(xInput == 0 || yInput != 0){
		audio_stop_sound(running)	
	}
	if(!place_meeting(x, y+1, objSolid)){
		audio_stop_sound(running)	
	}


}

// ---------------------------------------------------------------------------
// Handles the melee (kick) attack.
// Triggered by right-click (mb_right) or E key (meleeKeyPressed).
// Locks the player sprite to sprPlayerKick for meleeDuration frames.
// 8-frame sprite at 15 fps with 60 fps room speed = 4 steps per frame = 32 steps total.
// Damage fires once at the start of the 2nd animation frame (meleeTimer == 28).
// Enemies are identified by having the isDying variable.
// Call once per Step after movement and the global.stopShooting reset.
// ---------------------------------------------------------------------------
function playerMelee() {
	if (meleeKeyPressed && meleeTimer <= 0) {
		meleeTimer    = meleeDuration;
		image_index   = 0;              // always start kick from frame 0
		image_xscale  = lastFacingDir;  // flip sprite to match last travel direction
	}

	if (meleeTimer > 0) {
		sprite_index = sprPlayerKick;
		global.stopShooting = true;
		meleeTimer--;

		// Damage window: fires once at the start of the 2nd animation frame
		// (frame index 1, meleeTimer == 28 = 32 - 1*4 steps elapsed).
		if (meleeTimer == 28) {
			var _pw = bbox_right - bbox_left;  // one player-width expansion each side
			var _list = ds_list_create();
			var _count = collision_rectangle_list(bbox_left - _pw, bbox_top, bbox_right + _pw, bbox_bottom, all, false, true, _list, false);
			for (var _i = 0; _i < _count; _i++) {
				var _inst = _list[| _i];
				if (instance_exists(_inst) && _inst != id
						&& variable_instance_exists(_inst, "isDying")
						&& !_inst.isDying) {
					with (_inst) {
						playerHealth = max(0, playerHealth - 1);
						if (playerHealth <= 0) {
							isDying = true;
							state   = "dead";
							xSpeed  = 0;
							ySpeed  = 0;
							image_speed = 1;
							image_index = 0;
							sprite_index = sprPlayerDie;
						}
					}
				}
			}
			ds_list_destroy(_list);
		}

		if (meleeTimer == 0) {
			global.stopShooting = false;
			image_xscale = 1;  // restore scale so normal sprites aren't mirrored
		}
	}
}

// ---------------------------------------------------------------------------
// Handles the knife slash attack.
// Triggered by F or middle mouse button (slashKeyPressed).
// Plays the sprPlayerKnife animation (11 frames, 20 fps).
// Every enemy touching the player's bbox each step is instantly killed.
// Call once per Step after movement.
// ---------------------------------------------------------------------------
function playerSlash() {
	if (slashKeyPressed && slashTimer <= 0) {
		slashTimer = slashDuration;
	}

	if (slashTimer > 0) {
		slashFrame = min(floor((slashDuration - slashTimer) / 2), 10);
		slashTimer--;

		// Instantly kill every enemy touching the player
		var _list = ds_list_create();
		var _count = collision_rectangle_list(bbox_left, bbox_top, bbox_right, bbox_bottom, all, false, true, _list, false);
		for (var _i = 0; _i < _count; _i++) {
			var _inst = _list[| _i];
			if (instance_exists(_inst) && _inst != id
					&& variable_instance_exists(_inst, "isDying")
					&& !_inst.isDying) {
				with (_inst) {
					playerHealth = 0;
					isDying      = true;
					state        = "dead";
					xSpeed       = 0;
					ySpeed       = 0;
					image_speed  = 1;
					image_index  = 0;
					sprite_index = sprPlayerDie;
				}
			}
		}
		ds_list_destroy(_list);
	}
}
