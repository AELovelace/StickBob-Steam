leftness = 2;
topness = 6;
menu_x = display_get_gui_width() * 0.22;
menu_y = display_get_gui_height() * 0.18;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);
steam_leaderboards_state_init();
steam_leaderboards_ui_request(true);
