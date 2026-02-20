if(global.isPaused){
	exit;
}
// Apply gravity
ySpeed += grv;
var target_x = O_Player.x;
var target_y = O_Player.y;
// Horizontal movement (will be determined by AI logic later)
//var hit_wall = (collision_line(x, y, target_x, target_y, obj_Wall, false, true))
var min_distance = 100;
var jumpCheck = 128;
var nearest_instance = instance_nearest(x, y, objBouncyBottom);
var player_distance = distance_to_object(O_Player);
var chase_range = 250; // Set a range in pixels
var shoot_range = 100;

if(player_distance > 50){
	xSpeed = walksp * dir;
}
if(nearest_instance != noone){
	var dist = point_distance(x, y, nearest_instance.x, nearest_instance.y);
	if (dist <= min_distance && canCheck == true){
        dir *= -1
		canCheck = false

    }
	if (dist >= min_distance){
		canCheck =true;
	}

}

// Check horizontal collisions with walls


if (place_meeting(x + xSpeed, y, objSolid)) {
		if (xSpeed > 0){
			collisionAngle = 180;
			x += -20
			dir = -1
			mouseAngle = collisionAngle
		}
		if (xSpeed < 0){
			collisionAngle = 0;
			x += 20;
			dir = 1;
			mouseAngle = collisionAngle
		}
}

// Check vertical collisions (platformer physics)
if (place_meeting(x, y + ySpeed, objSolid)) {
    // Stop vertical movement if colliding
    if (!place_meeting(x+15, y + sign(ySpeed), objSolid)) {
      y += sign(ySpeed);
    }
    ySpeed = 0;
}
// Check for the end of a platform
// Check one step forward and one step down
if (!place_meeting(x + (walksp * dir), y + 2, objSolid)) {
    dir *= -1; // Turn around if no platform ahead
}

if (player_distance < chase_range && player_distance > 50) {
    state = "chase";
	mouseAngle = point_direction(x,y, O_Player.x, O_Player.y)

}else {
    state = "patrol";
}

if (state == "chase") {
    // ... (logic to set 'dir')
    if (O_Player.x < x) {
        dir = -1;
    } else {
        dir = 1;
    }
    // Simple jump logic: if player is significantly higher and we are on the ground
    if (O_Player.y < y - 32 && ySpeed == 0) { // Player is 32 pixels above us and we are on the ground
        ySpeed = -7; // Give a jump velocity
    }
	var distance = 48;
	gun_distance = 20
	if currentCooldown > 0 then --currentCooldown;
	if(currentCooldown <= 0 && global.stopShooting == false && player_distance < shoot_range){
		var bullet_x = x + lengthdir_x(distance, mouseAngle);
		var bullet_y = y + lengthdir_y(distance, mouseAngle);
		var bullet = instance_create_layer(bullet_x, bullet_y, "Instances", obj_Bullet)
		bullet.direction = mouseAngle
		bullet.image_angle = bullet.direction
		bullet.owner_id = id
		audio_play_sound(wob_wob_2, 10, 0)
	    var _x = x + lengthdir_x(gun_distance, mouseAngle);
	    var _y = y + lengthdir_y(gun_distance, mouseAngle);
		effect_create_above(ef_smokeup, _x, _y, .05, c_ltgray);
		effect_create_above(ef_smoke, _x, _y, .05, c_grey);
		effect_create_above(ef_spark, _x, _y, .05, c_orange);
		currentCooldown = fireCooldown;
	}
}

if (place_meeting(x + xSpeed, y, objSolid))
{
    // Move pixel by pixel towards the wall until contact
    while (!place_meeting(x + sign(xSpeed), y, objSolid))
    {
        x += sign(xSpeed);
    }
	
    //RIGHT SIDE COLLISION

	
	//STOP MOVEMENT
	
	//handle slopes
	//dy gets incremented up the height until first clear pixel. if it is less than climb max player is pushed up
	var dy = 0;
	while(place_meeting(x + xSpeed, y - dy, objSolid) && dy < climbHeight){
		dy++;
	}
	if (!place_meeting(x+ xSpeed, y- dy, objSolid)) {
		//x += xSpeed;
		y -=dy;
	}
	//stop movement
    else {
		xSpeed = 0;
	}
}

// ... (rest of the movement code goes after this)
// Update position
x += xSpeed;
y += ySpeed;
	
	if(xSpeed > 0.1){
		sprite_index = sprPlayerRun;
	}
	else if(xSpeed < -.1){
		sprite_index = sprPlayerRunLeft;	
	}
	else{
		sprite_index = sprPlayerIdle
	}