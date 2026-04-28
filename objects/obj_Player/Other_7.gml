if(sprite_index == sprPlayerDie){
	global.stopShooting = false;
	if(random(10) >= 6){
		x = 200

	}
	else{
		x = room_width - 200;		
	}
	y = room_height / 2;
	if isHost {
		playerHealth = maxHealth
		set_player_health(steamID, 5)
		send_player_health_to_clients(steamID, playerHealth)
	}
}