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

var _left = keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"));
var _right = keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"));
var _confirm = menu_neo_confirm_pressed(_hovered_index == menu_index && _mouse_pressed);

if (keyboard_check_pressed(vk_escape)) {
	instance_create_layer(x, y, "Instances", objMainMenuNeo);
	instance_destroy();
	exit;
}

if (menu_index == 0 && (_left || _right || _confirm)) {
	selected_resolution += (_right - _left);
	if (_confirm && !_left && !_right) selected_resolution += 1;
	if (selected_resolution < 0) selected_resolution = array_length(resolution_options) - 1;
	if (selected_resolution >= array_length(resolution_options)) selected_resolution = 0;
}

if (menu_index == 1 && (_left || _right || _confirm)) {
	fullscreen_value = !fullscreen_value;
}

if (_confirm) {
	if (menu_index == 2) {
		var _settings = app_settings_defaults();
		if variable_global_exists("appSettings") then _settings = variable_global_get("appSettings");
		if !is_struct(_settings) then _settings = app_settings_defaults();
		variable_struct_set(_settings, "player_color", make_color_rgb(sliderR, sliderG, sliderB));
		variable_global_set("appSettings", _settings);

		var _selected_option = resolution_options[selected_resolution];
		app_settings_apply_choice(_selected_option, fullscreen_value);
		instance_create_layer(x, y, "Instances", objMainMenuNeo);
		instance_destroy();
		exit;
	}
	if (menu_index == 3) {
		instance_create_layer(x, y, "Instances", objMainMenuNeo);
		instance_destroy();
		exit;
	}
}

var _rY = 426;
var _gY = 470;
var _bY = 514;

if mouse_check_button_pressed(mb_left) {
	if point_in_rectangle(_mouse_x, _mouse_y, colorPickerX, _rY - colorPickerH, colorPickerX + colorPickerW, _rY + colorPickerH) draggingSlider = 0;
	else if point_in_rectangle(_mouse_x, _mouse_y, colorPickerX, _gY - colorPickerH, colorPickerX + colorPickerW, _gY + colorPickerH) draggingSlider = 1;
	else if point_in_rectangle(_mouse_x, _mouse_y, colorPickerX, _bY - colorPickerH, colorPickerX + colorPickerW, _bY + colorPickerH) draggingSlider = 2;
}

if mouse_check_button(mb_left) && draggingSlider != -1 {
	var _val = round(clamp((_mouse_x - colorPickerX) / colorPickerW, 0, 1) * 255);
	switch (draggingSlider) {
		case 0: sliderR = _val; break;
		case 1: sliderG = _val; break;
		case 2: sliderB = _val; break;
	}
}
if mouse_check_button_released(mb_left) then draggingSlider = -1;

last_mouse_x = _mouse_x;
last_mouse_y = _mouse_y;
