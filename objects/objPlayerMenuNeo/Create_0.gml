action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 38;
action_card_gap = 10;

button[0] = "2 PLAYERS";
button[1] = "3 PLAYERS";
button[2] = "4 PLAYERS";
button[3] = "BACK";

button_desc[0] = "Small lobby, quicker setup, easiest way to test the full flow.";
button_desc[1] = "Mid-size chaos with one extra slot for the lobby feed.";
button_desc[2] = "Open the full four-player host capacity before mode selection.";
button_desc[3] = "Return to the neo home terminal.";

buttons = array_length_1d(button);
menu_index = 0;
last_selected = 0;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);
