action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 54;
action_card_gap = 12;

lobbies = [];
menu_index = 0;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);
status_text = "REQUESTING LOBBIES";
join_pending = false;
join_target_id = -1;
join_target_map = "";
join_target_mode = string(global.GAME_MODE_CLASSIC);
refresh_frames = room_speed * 8;

request_lobby_feed = function() {
	if (!steam_initialised() || !steam_is_user_logged_on()) {
		status_text = "STEAM OFFLINE";
		lobbies = [];
		menu_index = 0;
		return;
	}

	status_text = "QUERYING";
	steam_lobby_list_add_string_filter("isStickBobPlaytest", "true", steam_lobby_list_filter_eq);
	steam_lobby_list_request();
};

resolve_lobby_room = function(_raw_map) {
	var _map_name = string(_raw_map);
	if (string_pos("ref room ", _map_name) == 1) {
		_map_name = string_delete(_map_name, 1, 9);
	}

	var _room = asset_get_index(_map_name);
	if (_room == -1) {
		if (_map_name == "MPB1") return MPB1;
		if (_map_name == "MPB2") return MPB2;
	}

	return _room;
};

request_lobby_feed();
alarm[0] = refresh_frames;
