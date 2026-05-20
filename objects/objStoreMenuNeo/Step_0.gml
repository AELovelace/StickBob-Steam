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

if (_hovered_index != -1 && (_mouse_moved || _mouse_pressed)) {
	menu_index = _hovered_index;
}

if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_backspace)) {
	if (menu_layer == "items") {
		item_index = menu_index;
		store_menu_set_category_layer();
		last_mouse_x = _mouse_x;
		last_mouse_y = _mouse_y;
		exit;
	}
	instance_create_layer(x, y, "Instances", objMainMenuNeo);
	instance_destroy();
	exit;
}

if (keyboard_check_pressed(ord("R")) && global.sgc_gateway.ready && global.sgc_gateway.linked) {
	sgc_gateway_check_balance();
}

var _confirm = menu_neo_confirm_pressed(_hovered_index == menu_index && _mouse_pressed);

if (_confirm) {
	if (menu_layer == "categories") {
		category_index = menu_index;
		item_index = 0;
		store_menu_open_category(category_index);
	} else if (menu_layer == "items" && menu_index >= 0 && menu_index < array_length(store_items)) {
		item_index = menu_index;
		unlockables_purchase(store_items[item_index].id);
	}
}

last_mouse_x = _mouse_x;
last_mouse_y = _mouse_y;
