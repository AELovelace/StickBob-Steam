// Create Event
leftness = 2;
topness = 2;
menu_x = window_get_width() / leftness; // Center the menu horizontally
menu_y = window_get_height() / topness; // Position vertically
button_h = 40; // Vertical spacing between options

// Array of menu options (strings)
button[0] = "Resume Game";
button[1] = "Save";
button[2] = "Load";
button[3] = "Main Menu";
button[4] = "Exit Game";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
last_mouse_x = mouse_x;
last_mouse_y = mouse_y;

