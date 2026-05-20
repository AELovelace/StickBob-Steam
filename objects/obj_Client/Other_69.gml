// Async Steam: hand off to the SGC gateway so it can finalise auth
// once Steam validates the auth-session ticket.
sgc_gateway_handle_async_steam();

switch(async_load[?"event_type"])
{
	case "lobby_joined":
		var _joined_success = async_load[? "success"];
		var _joined_result  = async_load[? "result"];
		var _joined_lobby   = async_load[? "lobby_id"];
		mp_debug_log("client-lobby-joined", "success=" + string(_joined_success) + " lobby=" + string(_joined_lobby) + " result=" + string(_joined_result));

		if (!_joined_success) {
			mp_debug_log("client-lobby-join-failed", "lobby=" + string(_joined_lobby) + " result=" + string(_joined_result));
			break;
		}

		lobbyHost = steam_lobby_get_owner_id();
		spawn_resync_active = true;
		spawn_resync_attempts = 0;
		spawn_resync_next_time = current_time + 600;
		spawn_resync_last_host = lobbyHost;

		var _mode_raw = string(steam_lobby_get_data("Mode"));
		if (string_length(_mode_raw) <= 0 && variable_global_exists("mp_join_target_mode")) {
			_mode_raw = string(global.mp_join_target_mode);
		}
		if (string_length(_mode_raw) > 0) {
			global.gameParams.modeSelection = real(_mode_raw);
		} else {
			global.gameParams.modeSelection = global.GAME_MODE_CLASSIC;
		}

		var _map_name = string(steam_lobby_get_data("MapName"));
		if (string_length(_map_name) <= 0 && variable_global_exists("mp_join_target_map")) {
			_map_name = string(global.mp_join_target_map);
		}
		if (string_pos("ref room ", _map_name) == 1) {
			_map_name = string_delete(_map_name, 1, 9);
		}

		var _target_room = asset_get_index(_map_name);
		if (_target_room == -1) {
			if (_map_name == "MPB1") _target_room = MPB1;
			if (_map_name == "MPB2") _target_room = MPB2;
		}
		mp_debug_log("client-room-resolve", "map=" + _map_name + " room=" + string(_target_room) + " current=" + string(room));

		if (_target_room != -1 && room != _target_room) {
			room_goto(_target_room);
		} else if (_target_room == -1) {
			mp_debug_log("client-room-missing", "map=" + _map_name);
		}
		break;
}
