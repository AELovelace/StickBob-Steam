// Create Event
leftness = 5;
topness = 6;
menu_x = window_get_width() / leftness; // Center the menu horizontally
menu_y = window_get_height() / topness; // Position vertically

button_h = 40; // Vertical spacing between options

// Array of menu options (strings)
button[0] = "Host Game";
button[1] = "Join Game";
button[2] = "SinglePlayer";
button[3] = "Runner";
button[4] = "Settings";
button[5] = "Exit";
button[6] = "Link SGC OAuth";
button[7] = "SadGirlsClub.WTF";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
last_mouse_x = mouse_x;
last_mouse_y = mouse_y;

// Pre-establish a gateway session from the main menu so the OAuth button
// can resolve immediately when pressed.
sgc_gateway_bootstrap(false);
