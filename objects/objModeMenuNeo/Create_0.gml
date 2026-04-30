action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 38;
action_card_gap = 10;

button[0] = "MPB CLASSIC";
button[1] = "MPB 5 HP";
button[2] = "MPB PRACTICE";
button[3] = "BACK";

button_desc[0] = "One-hit lethal classic mode. Fast resets, fast grudges.";
button_desc[1] = "Five-hit variant for longer duels and messier comebacks.";
button_desc[2] = "Practice path with hosted flow intact but softer stakes.";
button_desc[3] = "Return to player-count selection.";

buttons = array_length_1d(button);
menu_index = 0;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);
