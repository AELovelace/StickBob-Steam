
// This needs to be called every frame so that the extension
// gets updated you should place this call in a controller object
// that is persistent through the entire duration of you game.
steam_update();

var _steam_init = steam_initialised()
var _steam_logged = steam_is_user_logged_on()

if (_steam_init != steam_initialised_last || _steam_logged != steam_logged_on_last)
{
	show_debug_message("Steam state changed: initialised=" + string(_steam_init) + " logged_on=" + string(_steam_logged) + " app_id=" + string(steam_get_app_id()) + " user_id=" + string(steam_get_user_steam_id()) + " subscribed=" + string(steam_is_subscribed()))
	steam_initialised_last = _steam_init
	steam_logged_on_last = _steam_logged
	if (_steam_init) steam_set_warning_message_hook()
}

sgc_gateway_update();
steam_leaderboards_update();

