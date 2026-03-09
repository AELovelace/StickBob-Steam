/// @description Insert description here
// You can write your code in this editor

// Inherit the parent event
event_inherited();


selectAction = function() {
	var _initialised = steam_initialised();
	var _logged_on = steam_is_user_logged_on();
	if (!_initialised || !_logged_on) {
		show_debug_message("Lobby create blocked. initialised=" + string(_initialised) + " logged_on=" + string(_logged_on) + " app_id=" + string(steam_get_app_id()) + " user_id=" + string(steam_get_user_steam_id()) + " subscribed=" + string(steam_is_subscribed()));
		return;
	}

	global.server = instance_create_depth(0,0,0,obj_Server)
	var _max_members = 4
	var _create_request_ok = steam_lobby_create(steam_lobby_type_public, _max_members)
	show_debug_message("Lobby create requested. submitted=" + string(_create_request_ok) + " max_members=" + string(_max_members) + " app_id=" + string(steam_get_app_id()) + " logged_on=" + string(_logged_on) + " subscribed=" + string(steam_is_subscribed()))
}