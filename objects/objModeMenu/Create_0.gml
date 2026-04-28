// Create Event
menu_x = room_width / 2; // Center the menu horizontally
menu_y = room_height / 3; // Position vertically
button_h = 40; // Vertical spacing between options
button = []

// Array of menu options (strings)
button[0] = "MPB - Classic";
button[1] = "MPB - 5 HP";
button[2] = "Back";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
