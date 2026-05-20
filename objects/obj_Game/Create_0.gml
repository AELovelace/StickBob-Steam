randomize();
global.isPaused = false;
// Create Event
var _settings = app_settings_load()
variable_global_set("appSettings", _settings)
app_settings_apply(_settings)
mp_debug_init(true)
crash_log_install()
mp_debug_log("boot", "obj_Game created room=" + room_get_name(room))
mp_debug_log("boot", "tail helper: tools\\Start-MpLogTail.cmd \"" + mp_debug_log_path() + "\"")
mp_debug_log("boot", "crash handler path=" + crash_log_path())

menu_x = room_width / 2; // Center the menu horizontally
menu_y = room_height / 2; // Position vertically
button_h = 40; // Vertical spacing between options
button = []

// Array of menu options (strings)
button[0] = "Resume";
button[1] = "Save";
button[2] = "Load";
button[3] = "Main Menu";
button[4] = "Exit Game";


buttons = array_length_1d(button); // Get the number of buttons
menu_index = 0; // Current selected item index (starts at 0)
last_selected = 0; // Track the last selection to prevent repeated sound playing
