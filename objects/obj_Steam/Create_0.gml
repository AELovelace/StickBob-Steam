
randomize()
is_game_restarting = false;

global.GAME_MODE_CLASSIC = 0;
global.GAME_MODE_HP5 = 1;
global.gameParams = {
				numberPlayers: 0,
				mapSelection: 0,
				playerColor: 0,
				modeSelection: global.GAME_MODE_CLASSIC,
				practiceMode: false
}

var _steam_init = steam_initialised()
var _steam_logged = steam_is_user_logged_on()
var _steam_app = steam_get_app_id()
var _steam_user = steam_get_user_steam_id()
var _steam_subscribed = steam_is_subscribed()

show_debug_message("Steam boot state: initialised=" + string(_steam_init) + " logged_on=" + string(_steam_logged) + " app_id=" + string(_steam_app) + " user_id=" + string(_steam_user) + " subscribed=" + string(_steam_subscribed))

steam_initialised_last = _steam_init
steam_logged_on_last = _steam_logged

if (_steam_init) {
	steam_set_warning_message_hook()
	show_debug_message("Steam warning hook enabled")
}

steam_leaderboards_state_init();

if (os_browser != browser_not_a_browser) {
	vpSizeWidthFS = browser_width-5;
	vpSizeLengthFS = browser_height-5;
	view_wport[0] = vpSizeWidthFS
	view_hport[0] = vpSizeLengthFS
	window_set_size(view_wport[0], view_hport[0]);
	surface_resize(application_surface, view_wport[0]-10, view_hport[0]-10);
}
