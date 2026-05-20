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
if (keyboard_check_pressed(vk_enter) || (_hovered_index == menu_index && _mouse_pressed)) {
    switch(menu_index) {
        case 0:
			// Multiplayer Logic
			instance_destroy(obj_LobbyItem)
			instance_destroy(obj_LobbyList)
			instance_create_layer(x,y,"Instances",objPlayerMenu);
			instance_destroy()
            break;
        case 1:
            // Action for "Load Game"
			//multiplayer Logic
			for (var _i = 0; _i < 5; _i++){
			var _inst = instance_find(obj_Button,_i)
				if _inst != noone then _inst.disabled = true;
			}
		
			var lobby_list = instance_create_depth(416,208,-10,obj_LobbyList)
            break;
			
			//draw_text(200,200,"Not Available in HTML5 Demo")
			break;
        case 2:
            // Action for "Options"
			room_goto(rm_GameRoom)
			break;
        case 3:
			// Runner mode
			room_goto(rm_Runner)
			break;
		case 4:
			instance_create_layer(x,y,"Instances",objSettingsMenu);
			instance_destroy()
			break;
		case 5:
			shutdown_multiplayer("main_menu_exit_game")
			game_end(); // Closes the game
            show_debug_message("Open Options Menu");
            break;
            // Action for "Exit"
			
		case 6:
			// Link the player's Steam identity to their SadGirlCoin wallet
			// via the gateway's OAuth flow. Opens in the system browser
			// so the player can use their normal Discord login session.
			sgc_gateway_begin_link_flow();
			break;

		case 7:
			url_open("https://sadgirlsclub.wtf")
            break;

		case 8:
			instance_create_layer(x, y, "Instances", objLeaderboardMenu);
			instance_destroy();
			break;

		case 9:
			instance_create_layer(x, y, "Instances", objMainMenuNeo);
			instance_destroy();
			break;
    }
}
