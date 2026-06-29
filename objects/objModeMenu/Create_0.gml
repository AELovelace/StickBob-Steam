// Create Event
leftness = 5;
topness = 6;
menu_x = window_get_width() / leftness; // Center the menu horizontally
menu_y = window_get_height() / topness; // Position vertically
button_h = 40; // Vertical spacing between options
button = []

// Array of menu options (strings)
button[0] = "MPB - Classic";
button[1] = "MPB - 5 HP";
button[2] = "MPB - Practice";
button[3] = "MPB - Practice 5HP";
button[4] = "Back";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
last_mouse_x = mouse_x;
last_mouse_y = mouse_y;
