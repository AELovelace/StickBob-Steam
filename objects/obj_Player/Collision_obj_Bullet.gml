var _other_owner_steam_id = other.owner_steam_id
var _other_bullet_id = other.id

mp_debug_log("player-hit-enter",
	"selfSteam=" + string(steamID)
	+ " otherOwnerSteam=" + string(_other_owner_steam_id)
	+ " isHost=" + string(isHost)
	+ " isLocal=" + string(isLocal)
	+ " health=" + string(playerHealth)
	+ " maxHealth=" + string(maxHealth)
	+ " bullet=" + string(_other_bullet_id)
)
if (_other_owner_steam_id == steamID) {
	mp_debug_log("player-hit-ignore-self",
		"selfSteam=" + string(steamID)
		+ " bullet=" + string(_other_bullet_id)
	)
	exit;
}

instance_destroy(other)
mp_debug_log("player-hit-bullet-destroyed",
	"selfSteam=" + string(steamID)
	+ " bullet=" + string(_other_bullet_id)
)

if !isHost {
	mp_debug_log("player-hit-nonhost-exit",
		"selfSteam=" + string(steamID)
		+ " isLocal=" + string(isLocal)
	)
	exit;
}
if sprite_index == sprPlayerDie {
	mp_debug_log("player-hit-already-dead-exit",
		"selfSteam=" + string(steamID)
	)
	exit;
}

if global.gameParams.modeSelection == global.GAME_MODE_CLASSIC {
	playerHealth = 0
} else {
	playerHealth = max(0, playerHealth - 1)
}
mp_debug_log("player-hit-health-updated",
	"selfSteam=" + string(steamID)
	+ " newHealth=" + string(playerHealth)
	+ " mode=" + string(global.gameParams.modeSelection)
)

if (playerHealth <= 0){
	mp_debug_log("player-hit-lethal",
		"selfSteam=" + string(steamID)
		+ " killerSteam=" + string(_other_owner_steam_id)
	)
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
	// Host reports the PvP kill to the SGC gateway. Idempotency is keyed on
	// (match, victim, killer, death_seq), so accidental duplicate dispatches
	// (re-trigger of the same death) won't double-pay.
	if (variable_instance_exists(id, "sgc_pvp_death_seq") == false) sgc_pvp_death_seq = 0;
	sgc_pvp_death_seq += 1;
	sgc_gateway_report_pvp_kill({
		victim_steam_id      : string(steamID),
		beneficiary_steam_id : string(_other_owner_steam_id),
		death_seq            : sgc_pvp_death_seq,
	});
	if(random(10) >= 6){
		x = 200

	}
	else{
		x = room_width - 200;		
	}
	y = room_height / 2;
	set_player_health(steamID, 5)
} else {
	mp_debug_log("player-hit-nonlethal",
		"selfSteam=" + string(steamID)
		+ " health=" + string(playerHealth)
	)
	global.stopShooting = false
}

set_player_health(steamID, playerHealth)
mp_debug_log("player-hit-health-applied",
	"selfSteam=" + string(steamID)
	+ " health=" + string(playerHealth)
)
if (instance_exists(obj_Server)) {
	mp_debug_log("player-hit-health-broadcast",
		"selfSteam=" + string(steamID)
		+ " health=" + string(playerHealth)
	)
	send_player_health_to_clients(steamID, playerHealth)
}
