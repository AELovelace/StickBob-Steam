if (global.isPaused) {
    exit;
}

scr_smart_nav_update(O_Player);
scr_smart_nav_update_sprite();
var player_distance = distance_to_object(O_Player);
var shoot_range = 100;
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
		bullet.owner_steam_id = bot_owner_steam_id
		audio_play_sound(wob_wob_2, 10, 0)
	    var _x = x + lengthdir_x(gun_distance, mouseAngle);
	    var _y = y + lengthdir_y(gun_distance, mouseAngle);
		effect_create_above(ef_smokeup, _x, _y, .05, c_ltgray);
		effect_create_above(ef_smoke, _x, _y, .05, c_grey);
		effect_create_above(ef_spark, _x, _y, .05, c_orange);
		currentCooldown = fireCooldown;
	}
