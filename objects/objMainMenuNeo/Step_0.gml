var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);
var _mouse_pressed = mouse_check_button_pressed(mb_left);
var _mouse_moved = (_mouse_x != last_mouse_x) || (_mouse_y != last_mouse_y);
var _hovered_index = -1;

for (var _i = 0; _i < buttons; _i++) {
	var _top = action_card_y + _i * (action_card_h + action_card_gap);
	var _left = action_card_x;
	var _right = action_card_x + action_card_w;
	var _bottom = _top + action_card_h;
	if (point_in_rectangle(_mouse_x, _mouse_y, _left, _top, _right, _bottom)) {
		_hovered_index = _i;
		break;
	}
}

var _menu_down = keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"));
var _menu_up = keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
menu_index += (_menu_down - _menu_up);

if (menu_index < 0) menu_index = buttons - 1;
if (menu_index >= buttons) menu_index = 0;

if (_hovered_index != -1 && (_mouse_moved || _mouse_pressed)) {
	menu_index = _hovered_index;
}

if (menu_index != last_selected) {
	last_selected = menu_index;
}

last_mouse_x = _mouse_x;
last_mouse_y = _mouse_y;

if (keyboard_check_pressed(vk_escape)) {
	shutdown_multiplayer("main_menu_neo_exit_game");
	game_end();
	exit;
}

var _confirm = menu_neo_confirm_pressed(_hovered_index == menu_index && _mouse_pressed);

if (!_confirm) exit;

switch (menu_index) {
	case 0:
		instance_destroy(obj_LobbyItem);
		instance_destroy(obj_LobbyList);
		instance_create_layer(x, y, "Instances", objPlayerMenuNeo);
		instance_destroy();
		break;

	case 1:
		instance_create_layer(x, y, "Instances", objLobbyBrowserNeo);
		instance_destroy();
		break;

	case 2:
		room_goto(rm_GameRoom);
		break;

	case 3:
		room_goto(rm_Runner);
		break;

	case 4:
		instance_create_layer(x, y, "Instances", objLeaderboardMenu);
		instance_destroy();
		break;

	case 5:
		sgc_gateway_begin_link_flow();
		break;

	case 6:
		url_open("https://sadgirlsclub.wtf");
		break;

	case 7:
		instance_create_layer(x, y, "Instances", objSettingsMenuNeo);
		instance_destroy();
		break;

	case 8:
		instance_create_layer(x, y, "Instances", objStoreMenuNeo);
		instance_destroy();
		break;

	case 9:
		shutdown_multiplayer("main_menu_neo_exit_game")
		game_end();
		break;
}
