if(sprite_index == sprPlayerDie){
	global.stopShooting = false;
	if variable_instance_exists(id, "respawn_x") then x = variable_instance_get(id, "respawn_x")
	if variable_instance_exists(id, "respawn_y") then y = variable_instance_get(id, "respawn_y")
	playerHealth = 5
}

