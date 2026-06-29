/// @description Movement & Actions based off of Input
get_controls(isHost,isLocal)

if (isLocal && (instance_exists(obj_Server) || instance_exists(obj_Client)) && current_time >= debug_next_heartbeat) {
	debug_next_heartbeat = current_time + 1000;
	mp_debug_log("player-heartbeat",
		"steam=" + string(steamID)
		+ " pos=(" + string(x) + "," + string(y) + ")"
		+ " speed=(" + string(xSpeed) + "," + string(ySpeed) + ")"
		+ " input=(" + string(xInput) + "," + string(yInput) + ")"
		+ " sprite=" + string(sprite_index)
	)
}

paddle_movement()
reconcile_net_position()

if (sprite_index != sprPlayerDie && meleeTimer <= 0){
	global.stopShooting = false;	
}
playerSpriteIndexer()
// Logic for shooting a bullet
if (actionKey == 1 && currentCooldown <= 0 && meleeTimer <= 0 && !meleeKeyPressed && slashTimer <= 0){
	var dist = 32;
	gun_distance = 20
	var bullet_x = x + lengthdir_x(dist, mouseAngle);
	var bullet_y = y + lengthdir_y(dist, mouseAngle);
	mp_debug_log("shoot-attempt",
		"steam=" + string(steamID)
		+ " local=" + string(isLocal)
		+ " host=" + string(isHost)
		+ " pos=(" + string(x) + "," + string(y) + ")"
		+ " bulletPos=(" + string(bullet_x) + "," + string(bullet_y) + ")"
		+ " angle=" + string(mouseAngle)
	)
	var bullet = instance_create_layer(bullet_x, bullet_y, "Instances", obj_Bullet)
		bullet.direction = mouseAngle
		bullet.image_angle = bullet.direction
		bullet.owner_id = id
		bullet.owner_steam_id = steamID
	mp_replicate_spawn(bullet, ENTITY_KIND.BULLET)
	mp_debug_log("shoot-spawn",
		"steam=" + string(steamID)
		+ " bullet=" + string(bullet)
		+ " owner=" + string(id)
		+ " bulletPos=(" + string(bullet.x) + "," + string(bullet.y) + ")"
		+ " angle=" + string(bullet.direction)
	)
	audio_play_sound(wob_wob_2, 10, 0)
    var _x = x + lengthdir_x(gun_distance, mouseAngle);
    var _y = y + lengthdir_y(gun_distance, mouseAngle);
	effect_create_above(ef_smokeup, _x, _y, .05, c_ltgray);
	effect_create_above(ef_smoke, _x, _y, .05, c_grey);
	effect_create_above(ef_spark, _x, _y, .05, c_orange);
	mp_debug_log("shoot-complete",
		"steam=" + string(steamID)
		+ " bullet=" + string(bullet)
		+ " fxPos=(" + string(_x) + "," + string(_y) + ")"
	)
	currentCooldown = fireCooldown
}
playerMelee()
playerSlash()

// Safety net: catch any health-below-zero case that slipped past collision handlers
if (playerHealth <= 0 && sprite_index != sprPlayerDie) {
	playerHealth = 0;
	global.stopShooting = true;
	sprite_index = sprPlayerDie;
	audio_play_sound(i_fucked_ur_mum, 10, 0)
}

