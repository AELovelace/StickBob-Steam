var _ui = steam_leaderboards_ui_state();
var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);
var _mouse_pressed = mouse_check_button_pressed(mb_left);
var _mouse_moved = (_mouse_x != last_mouse_x) || (_mouse_y != last_mouse_y);

if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_backspace)) {
	instance_create_layer(x, y, "Instances", objMainMenuNeo);
	instance_destroy();
	exit;
}

if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
	_ui.board_index -= 1;
	if (_ui.board_index < 0) _ui.board_index = array_length(_ui.boards) - 1;
	steam_leaderboards_ui_request(true);
}

if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
	_ui.board_index += 1;
	if (_ui.board_index >= array_length(_ui.boards)) _ui.board_index = 0;
	steam_leaderboards_ui_request(true);
}

if (keyboard_check_pressed(vk_tab)) {
	_ui.scope_index += 1;
	if (_ui.scope_index >= array_length(_ui.scopes)) _ui.scope_index = 0;
	steam_leaderboards_ui_request(true);
}

if (keyboard_check_pressed(ord("R"))) {
	steam_leaderboards_ui_request(true);
}

if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
	_ui.selected_row = max(0, _ui.selected_row - 1);
}

if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
	_ui.selected_row = min(max(0, array_length(_ui.entries) - 1), _ui.selected_row + 1);
}

var _board_y = 128;
var _board_h = 34;
for (var _i = 0; _i < array_length(_ui.boards); _i++) {
	var _top = _board_y + _i * (_board_h + 8);
	var _left = 36;
	var _right = 256;
	var _bottom = _top + _board_h;
	if (point_in_rectangle(_mouse_x, _mouse_y, _left, _top, _right, _bottom)) {
		if (_mouse_pressed) {
			_ui.board_index = _i;
			steam_leaderboards_ui_request(true);
		}
	}
}

var _scope_x = 300;
var _scope_w = 130;
for (var _j = 0; _j < array_length(_ui.scopes); _j++) {
	var _left2 = _scope_x + _j * (_scope_w + 12);
	var _top2 = 96;
	var _right2 = _left2 + _scope_w;
	var _bottom2 = _top2 + 28;
	if (point_in_rectangle(_mouse_x, _mouse_y, _left2, _top2, _right2, _bottom2) && _mouse_pressed) {
		_ui.scope_index = _j;
		steam_leaderboards_ui_request(true);
	}
}

var _refresh_left = display_get_gui_width() - 178;
var _refresh_top = display_get_gui_height() - 46;
var _refresh_right = display_get_gui_width() - 22;
var _refresh_bottom = display_get_gui_height() - 18;
if (point_in_rectangle(_mouse_x, _mouse_y, _refresh_left, _refresh_top, _refresh_right, _refresh_bottom) && _mouse_pressed) {
	steam_leaderboards_ui_request(true);
}

if (!_ui.loading
	&& _ui.request_id < 0
	&& array_length(_ui.entries) <= 0
	&& steam_leaderboards_is_available()) {
	steam_leaderboards_ui_request(true);
}

last_mouse_x = _mouse_x;
last_mouse_y = _mouse_y;
