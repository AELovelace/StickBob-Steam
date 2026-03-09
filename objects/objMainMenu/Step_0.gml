// Step Event
// Check for input (Down key - Up key)
menu_move = keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up);

// Update menu index
menu_index += menu_move;

// Wrap index around the array length (looping menu)
if (menu_index < 0) menu_index = buttons - 1;
if (menu_index > buttons - 1) menu_index = 0;

// Optional: Play a sound when the selection changes
if (menu_index != last_selected) {
    // audio_play_sound(snd_menu_switch, 1, false); // Uncomment and replace with your sound asset
}
last_selected = menu_index;

// Handle selection (Enter/Space key)
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
    switch(menu_index) {
        case 0:
			// Multiplayer Logic
			instance_destroy(obj_LobbyItem)
			instance_destroy(obj_LobbyList)
			instance_create_layer(x,y,"Instances",objPlayerMenu);
			instance_destroy()
            break;
			
			draw_text(200,200,"Not Available in HTML5 Demo")
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
			game_end(); // Closes the game
            show_debug_message("Open Options Menu");
            break;
            // Action for "Exit"
			
		case 4:	
			url_open("https://sadgirlsclub.wtf")
            break;
    }
}