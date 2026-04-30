switch (async_load[? "event_type"]) {
	case "lobby_list":
		lobbies = [];

		for (var _i = 0; _i < steam_lobby_list_get_count(); _i++) {
			var _map_name = string(steam_lobby_list_get_data(_i, "MapName"));
			var _map_short = _map_name;
			if (string_pos("ref room ", _map_short) == 1) {
				_map_short = string_delete(_map_short, 1, 9);
			}

			var _mode_name = string(steam_lobby_list_get_data(_i, "ModeName"));
			if (string_length(_mode_name) <= 0) _mode_name = "Classic";

			array_push(lobbies, {
				lobby_index : _i,
				lobby_id    : steam_lobby_list_get_lobby_id(_i),
				creator     : string(steam_lobby_list_get_data(_i, "Creator")),
				map_name    : _map_name,
				map_short   : _map_short,
				mode_raw    : string(steam_lobby_list_get_data(_i, "Mode")),
				mode_name   : _mode_name,
			});
		}

		if (array_length(lobbies) <= 0) {
			status_text = "NO MATCHES";
			menu_index = 0;
		} else {
			status_text = "READY";
			menu_index = clamp(menu_index, 0, array_length(lobbies) - 1);
		}
		break;

	case "lobby_joined":
		if (!join_pending) break;

		var _joined_success = async_load[? "success"];
		var _joined_result = async_load[? "result"];
		var _joined_lobby = async_load[? "lobby_id"];

		if (!_joined_success || _joined_lobby != join_target_id) {
			status_text = "JOIN FAILED " + string(_joined_result);
			join_pending = false;
			break;
		}

		if (!instance_exists(obj_Client)) {
			global.client = instance_create_depth(0, 0, 0, obj_Client);
		}

		if (string_length(join_target_mode) > 0) {
			global.gameParams.modeSelection = real(join_target_mode);
		} else {
			global.gameParams.modeSelection = global.GAME_MODE_CLASSIC;
		}

		var _target_room = resolve_lobby_room(steam_lobby_get_data("MapName"));
		if (_target_room == -1) {
			_target_room = resolve_lobby_room(join_target_map);
		}

		join_pending = false;
		status_text = "JOINED";

		if (_target_room != -1) {
			room_goto(_target_room);
		} else {
			status_text = "ROOM MISSING";
		}
		break;
}
