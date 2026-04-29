// Create Event
leftness = 5;
topness = 6;
menu_x = window_get_width() / leftness; // Center the menu horizontally
menu_y = window_get_height() / topness; // Position vertically
button_h = 40; // Vertical spacing between options

// Array of menu options (strings)
button[0] = "2 Player";
button[1] = "3 Player";
button[2] = "4 Player";
button[3] = "Back";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
last_mouse_x = mouse_x;
last_mouse_y = mouse_y;

