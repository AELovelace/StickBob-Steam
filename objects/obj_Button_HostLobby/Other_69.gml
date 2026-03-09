
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
		}

		var _created_success = async_load[? "success"]
		var _created_result  = async_load[? "result"]
		var _created_lobby   = async_load[? "lobby_id"]

		if (_created_success)
		{
			show_debug_message("Lobby created OK. lobby_id=" + string(_created_lobby) + " result=" + string(_created_result) + " (" + _result_name(_created_result) + ")")
			steam_lobby_join_id(_created_lobby)
		}
		else
		{
			show_debug_message("Lobby create FAILED. lobby_id=" + string(_created_lobby) + " result=" + string(_created_result) + " (" + _result_name(_created_result) + ")")
		}
		
	break
	
	case "lobby_joined":
		var _joined_success = async_load[? "success"]
		var _joined_result  = async_load[? "result"]
		var _joined_lobby   = async_load[? "lobby_id"]

		if (!_joined_success)
		{
			show_debug_message("Lobby join FAILED. lobby_id=" + string(_joined_lobby) + " result=" + string(_joined_result))
			break
		}
	
		if(steam_lobby_is_owner())
		{
			steam_lobby_set_data("isStickBobPlaytest","true");
			steam_lobby_set_data("Creator",steam_get_persona_name());
			
		}
		
		room_goto(MPB2)
		
	break
	
}







