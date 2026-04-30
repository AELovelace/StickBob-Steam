switch(async_load[?"event_type"])
{
	case "lobby_created":
		var _result_name = function(_code)
		{
			switch(_code)
			{
				case 1:  return "OK";
				case 2:  return "Fail";
				case 3:  return "NoConnection";
				case 8:  return "InvalidParam";
				case 15: return "AccessDenied";
				case 16: return "Timeout";
				case 20: return "ServiceUnavailable";
				case 21: return "NotLoggedOn";
				default: return "Unknown";
			}
		};

		var _created_success = async_load[? "success"];
		var _created_result  = async_load[? "result"];
		var _created_lobby   = async_load[? "lobby_id"];

		if (_created_success) {
			show_debug_message("Lobby created OK. lobby_id=" + string(_created_lobby) + " result=" + string(_created_result) + " (" + _result_name(_created_result) + ")");
			steam_lobby_join_id(_created_lobby);
		} else {
			show_debug_message("Lobby create FAILED. lobby_id=" + string(_created_lobby) + " result=" + string(_created_result) + " (" + _result_name(_created_result) + ")");
		}
		break;

	case "lobby_joined":
		var _joined_success = async_load[? "success"];
		var _joined_result  = async_load[? "result"];
		var _joined_lobby   = async_load[? "lobby_id"];

		if (!_joined_success) {
			show_debug_message("Lobby join FAILED. lobby_id=" + string(_joined_lobby) + " result=" + string(_joined_result));
			break;
		}

		if (steam_lobby_is_owner()) {
			steam_lobby_set_data("isStickBobPlaytest", "true");
			steam_lobby_set_data("Creator", steam_get_persona_name());
			steam_lobby_set_data("MapName", global.gameParams.mapSelection);
			steam_lobby_set_data("Mode", string(global.gameParams.modeSelection));
			steam_lobby_set_data("ModeName", (global.gameParams.modeSelection == global.GAME_MODE_HP5) ? "HP5" : "Classic");
			room_goto(global.gameParams.mapSelection);
		} else {
			var _mode_raw = steam_lobby_get_data("Mode");
			if (string_length(_mode_raw) > 0) {
				global.gameParams.modeSelection = real(_mode_raw);
			} else {
				global.gameParams.modeSelection = global.GAME_MODE_CLASSIC;
			}

			var _map_name = string(steam_lobby_get_data("MapName"));
			if (string_pos("ref room ", _map_name) == 1) {
				_map_name = string_delete(_map_name, 1, 9);
			}

			var _room = asset_get_index(_map_name);
			if (_room != -1) {
				room_goto(_room);
			}
		}
		break;
}
