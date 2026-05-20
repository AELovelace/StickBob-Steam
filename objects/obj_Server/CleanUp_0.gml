/// @description Leave lobby and clean up networking resources

mp_debug_log("lobby-leave", "steam=" + string(steamID) + " reason=cleanup")
steam_lobby_leave()

if buffer_exists(inbuf) {
	buffer_delete(inbuf)
}
