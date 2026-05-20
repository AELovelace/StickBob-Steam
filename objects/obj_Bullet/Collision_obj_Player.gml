/// @description Slow down other Players
mp_debug_log("bullet-hit-player",
	"bullet=" + string(id)
	+ " ownerSteam=" + string(owner_steam_id)
	+ " targetSteam=" + string(other.steamID)
	+ " targetIsHost=" + string(other.isHost)
	+ " targetIsLocal=" + string(other.isLocal)
	+ " pos=(" + string(x) + "," + string(y) + ")"
)
if (other.steamID == owner_steam_id){
	mp_debug_log("bullet-hit-self",
		"bullet=" + string(id)
		+ " steam=" + string(owner_steam_id)
	)
	instance_destroy()
	exit;
}
mp_debug_log("bullet-destroy-on-player-hit",
	"bullet=" + string(id)
	+ " targetSteam=" + string(other.steamID)
)
instance_destroy()
