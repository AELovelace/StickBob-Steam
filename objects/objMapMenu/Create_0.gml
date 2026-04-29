// Create Event
leftness = 5;
topness = 6;
menu_x = window_get_width() / leftness; // Center the menu horizontally
menu_y = window_get_height() / topness; // Position vertically
button_h = 40; // Vertical spacing between options
button = []

// Array of menu options (strings)
button[0] = "MPB1";
button[1] = "MPB2";
button[2] = "Back";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
last_mouse_x = mouse_x;
last_mouse_y = mouse_y;

start_host_lobby = function(_room) {
	var _initialised = steam_initialised()
	var _logged_on = steam_is_user_logged_on()
	if (!_initialised || !_logged_on)
	{
		show_debug_message("Lobby create blocked. initialised=" + string(_initialised) + " logged_on=" + string(_logged_on) + " app_id=" + string(steam_get_app_id()) + " user_id=" + string(steam_get_user_steam_id()) + " subscribed=" + string(steam_is_subscribed()))
		return
	}

	global.gameParams.mapSelection = _room
	var _mode = global.gameParams.modeSelection 

	if (!instance_exists(obj_Server)) {
		global.server = instance_create_depth(0,0,0,obj_Server)
	}

	var _max_members = max(2, global.gameParams.numberPlayers)
	var _create_request_ok = steam_lobby_create(steam_lobby_type_public, _max_members)
	show_debug_message("Lobby create requested. submitted=" + string(_create_request_ok) + " max_members=" + string(_max_members) + " app_id=" + string(steam_get_app_id()) + " logged_on=" + string(steam_is_user_logged_on()))
}

