if (other.owner_steam_id == steamID) exit;

instance_destroy(other)

if !isHost exit;
if sprite_index == sprPlayerDie exit;

if global.gameParams.modeSelection == global.GAME_MODE_CLASSIC {
	playerHealth = 0
} else {
	playerHealth = max(0, playerHealth - 1)
}

if (playerHealth <= 0){
	global.stopShooting = true
	image_speed = 1
	sprite_index = sprPlayerDie
	instance_create_layer(x,y,"Instances",objPlayerDeath)
	if(isLocal){
		audio_play_sound(i_fucked_ur_mum, 10, 0)
	}
	if(!isLocal){
		audio_play_sound(crunch, 10, 0)
	}
	if(random(10) >= 6){
		x = 200

	}
	else{
		x = room_width - 200;		
	}
	y = room_height / 2;
	set_player_health(steamID, 5)
} else {
	global.stopShooting = false
}

set_player_health(steamID, playerHealth)
send_player_health_to_clients(steamID, playerHealth)