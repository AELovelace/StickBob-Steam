// Step Event
var _menu_down = keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"));
var _menu_up = keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
var _mouse_pressed = mouse_check_button_pressed(mb_left);
var _mouse_moved = (mouse_x != last_mouse_x) || (mouse_y != last_mouse_y);
var _hovered_index = -1;
menu_x = window_get_width() / leftness; // Center the menu horizontally
menu_y = window_get_height() / topness; // Position vertically

for (var _i = 0; _i < buttons; _i++) {
    var _item_y = (room_height/topness) + (button_h/3) * _i;
    var _text_w = string_width(button[_i]);
    var _text_h = string_height(button[_i]);
    var _left = (room_width/leftness) - _text_w * 0.5 - 12;
    var _right = (room_width/leftness) + _text_w * 0.5 + 12;
    var _top = _item_y - _text_h;
    var _bottom = _item_y + 8;

    if (point_in_rectangle(mouse_x, mouse_y, _left, _top, _right, _bottom)) {
        _hovered_index = _i;
        break;
    }
}

menu_move = _menu_down - _menu_up;
menu_index += menu_move;

if (_hovered_index != -1 && (_mouse_moved || _mouse_pressed)) {
    menu_index = _hovered_index;
}

// Wrap index around the array length (looping menu)
if (menu_index < 0) menu_index = buttons - 1;
if (menu_index > buttons - 1) menu_index = 0;

// Optional: Play a sound when the selection changes
if (menu_index != last_selected) {
    // audio_play_sound(snd_menu_switch, 1, false); // Uncomment and replace with your sound asset
}
last_selected = menu_index;
last_mouse_x = mouse_x;
last_mouse_y = mouse_y;

// Handle selection (Enter/Space key)
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || (_hovered_index == menu_index && _mouse_pressed)) {
    switch(menu_index) {
        case 0:
            // Action for "New Game"
            global.gameParams.numberPlayers = 2;
			instance_create_layer(x,y,"Instances", objModeMenu)
			instance_destroy()
            break;
        case 1:
            global.gameParams.numberPlayers = 3;
			instance_create_layer(x,y,"Instances", objModeMenu)
            instance_destroy()
			break;
        case 2:
            global.gameParams.numberPlayers = 4;
			instance_create_layer(x,y,"Instances", objModeMenu)
            instance_destroy()
			break;
        case 3:
			global.gameParams.numberPlayers = 0;
			instance_create_layer(x,y,"Instances", objMainMenu)
            instance_destroy()
            break;
    }
}
