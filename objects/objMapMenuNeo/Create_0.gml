action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 38;
action_card_gap = 10;

button[0] = "MPB1";
button[1] = "MPB2";
button[2] = "BACK";

button_desc[0] = "Launch the first multiplayer board with the current host settings.";
button_desc[1] = "Launch the second multiplayer board with the current host settings.";
button_desc[2] = "Return to mode selection.";

buttons = array_length_1d(button);
menu_index = 0;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);

start_host_lobby_neo = function(_room) {
	if (global.gameParams.practiceMode) {
		global.gameParams.mapSelection = _room;
		if (instance_exists(obj_Server)) with (obj_Server) instance_destroy();
		if (instance_exists(obj_Client)) with (obj_Client) instance_destroy();
		room_goto(_room);
		return;
	}

	var _initialised = steam_initialised();
	var _logged_on = steam_is_user_logged_on();
	if (!_initialised || !_logged_on) {
		show_debug_message("Lobby create blocked. initialised=" + string(_initialised) + " logged_on=" + string(_logged_on) + " app_id=" + string(steam_get_app_id()) + " user_id=" + string(steam_get_user_steam_id()) + " subscribed=" + string(steam_is_subscribed()));
		return;
	}

	global.gameParams.mapSelection = _room;
	if (!instance_exists(obj_Server)) {
		global.server = instance_create_depth(0, 0, 0, obj_Server);
	}

	var _max_members = max(2, global.gameParams.numberPlayers);
	var _create_request_ok = steam_lobby_create(steam_lobby_type_public, _max_members);
	show_debug_message("Lobby create requested. submitted=" + string(_create_request_ok) + " max_members=" + string(_max_members) + " app_id=" + string(steam_get_app_id()) + " logged_on=" + string(steam_is_user_logged_on()));
}
