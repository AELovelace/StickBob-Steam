var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);
var _mouse_pressed = mouse_check_button_pressed(mb_left);
var _mouse_moved = (_mouse_x != last_mouse_x) || (_mouse_y != last_mouse_y);
var _hovered_index = -1;

for (var _i = 0; _i < buttons; _i++) {
	var _top = action_card_y + _i * (action_card_h + action_card_gap);
	if (point_in_rectangle(_mouse_x, _mouse_y, action_card_x, _top, action_card_x + action_card_w, _top + action_card_h)) {
		_hovered_index = _i;
		break;
	}
}

menu_index += (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")))
	- (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")));
if (menu_index < 0) menu_index = buttons - 1;
if (menu_index >= buttons) menu_index = 0;
if (_hovered_index != -1 && (_mouse_moved || _mouse_pressed)) menu_index = _hovered_index;

last_mouse_x = _mouse_x;
last_mouse_y = _mouse_y;

if (keyboard_check_pressed(vk_escape)) {
	instance_create_layer(x, y, "Instances", objPlayerMenuNeo);
	instance_destroy();
	exit;
}

var _confirm = menu_neo_confirm_pressed(_hovered_index == menu_index && _mouse_pressed);
if (!_confirm) exit;

switch (menu_index) {
	case 0:
		global.gameParams.practiceMode = false;
		global.gameParams.modeSelection = global.GAME_MODE_CLASSIC;
		instance_create_layer(x, y, "Instances", objMapMenuNeo);
		instance_destroy();
		break;
	case 1:
		global.gameParams.practiceMode = false;
		global.gameParams.modeSelection = global.GAME_MODE_HP5;
		instance_create_layer(x, y, "Instances", objMapMenuNeo);
		instance_destroy();
		break;
	case 2:
		global.gameParams.practiceMode = true;
		global.gameParams.modeSelection = global.GAME_MODE_CLASSIC;
		instance_create_layer(x, y, "Instances", objMapMenuNeo);
		instance_destroy();
		break;
	case 3:
		instance_create_layer(x, y, "Instances", objPlayerMenuNeo);
		instance_destroy();
		break;
}
