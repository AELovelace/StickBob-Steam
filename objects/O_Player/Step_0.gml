/// @description Movement & Actions based off of Input
if(global.isPaused){
	exit;
}
getSPControls()
if (keyboard_check_pressed(ord("1")) || keyboard_check_pressed(vk_numpad1)) {
	selectedWeaponSlot = 1;
}
if ((keyboard_check_pressed(ord("2")) || keyboard_check_pressed(vk_numpad2))
	&& unlockables_is_unlocked("weapon.machinegun")) {
	selectedWeaponSlot = 2;
}
paddle_movement()
if (actionKey == 1 && currentCooldown <= 0){
	var dist = 32;
	gun_distance = 20
	var bullet_x = x + lengthdir_x(dist, mouseAngle);
	var bullet_y = y + lengthdir_y(dist, mouseAngle);
	var bullet = instance_create_layer(bullet_x, bullet_y, "Instances", obj_Bullet)
		bullet.direction = mouseAngle
		bullet.image_angle = bullet.direction
		bullet.owner_id = id
		bullet.owner_steam_id = steamID
	audio_play_sound(wob_wob_2, 10, 0)
    var _x = x + lengthdir_x(gun_distance, mouseAngle);
    var _y = y + lengthdir_y(gun_distance, mouseAngle);
	effect_create_above(ef_smokeup, _x, _y, .05, c_ltgray);
	effect_create_above(ef_smoke, _x, _y, .05, c_grey);
	effect_create_above(ef_spark, _x, _y, .05, c_orange);
	currentCooldown = fireCooldown
	if (selectedWeaponSlot == 2) {
		currentCooldown = machinegunFireCooldown;
	}
}
playerSpriteIndexer()
playerSounds()
speedBar = xSpeed * 12.5
if(speedBar < 0){
	speedBar *=-1	
}
vpSizeWidth = window_get_width()
vpSizeLength = window_get_height();
if (sprite_index != sprPlayerDie){
	global.stopShooting = false;	
}
