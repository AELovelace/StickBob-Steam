var _mouse_x = device_mouse_x_to_gui(0);
var _mouse_y = device_mouse_y_to_gui(0);
var _mouse_pressed = mouse_check_button_pressed(mb_left);
var _mouse_moved = (_mouse_x != last_mouse_x) || (_mouse_y != last_mouse_y);
var _hovered_index = -1;
var _row_count = max(1, array_length(lobbies));

for (var _i = 0; _i < _row_count; _i++) {
	var _top = action_card_y + _i * (action_card_h + action_card_gap);
	if (point_in_rectangle(_mouse_x, _mouse_y, action_card_x, _top, action_card_x + action_card_w, _top + action_card_h)) {
		_hovered_index = _i;
		break;
	}
}

menu_index += (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")))
	- (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")));

if (_row_count > 0) {
	if (menu_index < 0) menu_index = _row_count - 1;
	if (menu_index >= _row_count) menu_index = 0;
}

if (_hovered_index != -1 && (_mouse_moved || _mouse_pressed)) {
	menu_index = _hovered_index;
}

last_mouse_x = _mouse_x;
last_mouse_y = _mouse_y;

if (keyboard_check_pressed(ord("R"))) {
	request_lobby_feed();
	alarm[0] = refresh_frames;
}

if (keyboard_check_pressed(vk_escape)) {
	instance_create_layer(x, y, "Instances", objMainMenuNeo);
	instance_destroy();
	exit;
}

var _confirm = menu_neo_confirm_pressed(_hovered_index == menu_index && _mouse_pressed);

if (!_confirm || join_pending) exit;

if (array_length(lobbies) <= 0) {
	request_lobby_feed();
	alarm[0] = refresh_frames;
	exit;
}

var _selected = lobbies[menu_index];
join_pending = true;
join_target_id = _selected.lobby_id;
join_target_map = _selected.map_name;
join_target_mode = _selected.mode_raw;
status_text = "JOINING " + _selected.creator;

global.mp_join_target_id = join_target_id;
global.mp_join_target_map = join_target_map;
global.mp_join_target_mode = join_target_mode;

if (instance_exists(obj_Server)) with (obj_Server) instance_destroy();
if (instance_exists(obj_Client)) with (obj_Client) instance_destroy();
global.client = instance_create_depth(0, 0, 0, obj_Client);

steam_lobby_join_id(join_target_id);
