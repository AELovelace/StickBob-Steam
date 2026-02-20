if(global.isPaused){
	exit;
}
// Apply gravity
ySpeed += grv;
var target_x = O_Player.x;
var target_y = O_Player.y;
// Horizontal movement (will be determined by AI logic later)
var hit_wall = (collision_line(x, y, target_x, target_y, obj_Wall, false, true))

if(ySpeed < 10){
	ySpeed+= grv	
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
    while (!place_meeting(x+15, y + sign(ySpeed), objSolid)) {
        y += sign(ySpeed);
    }
    ySpeed = 0;
}
// Check for the end of a platform
// Check one step forward and one step down

var player_distance = distance_to_object(O_Player);
var chase_range = 350; // Set a range in pixels

if (player_distance < chase_range && !hit_wall) {
    state = "chase";
	mouseAngle = point_direction(x,y, O_Player.x, O_Player.y)

}else {
    state = "patrol";
}

if (state == "chase") {
    // ... (logic to set 'dir')
    // Simple jump logic: if player is significantly higher and we are on the ground
		var dist = 32;
	gun_distance = 20
	if currentCooldown > 0 then --currentCooldown;
	if(currentCooldown <= 0 && global.stopShooting == false){
		var bullet_x = x + lengthdir_x(dist, mouseAngle);
		var bullet_y = y + lengthdir_y(dist, mouseAngle);
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

// ... (rest of the movement code goes after this)
// Update position
//x += xSpeed;
//y += ySpeed;
	
	if(xSpeed > 0.1){
		sprite_index = sprPlayerRun;
	}
	else if(xSpeed < -.1){
		sprite_index = sprPlayerRunLeft;	
	}
	else{
		sprite_index = sprPlayerNoArm
	}