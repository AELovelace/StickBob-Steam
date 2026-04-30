action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 38;
action_card_gap = 10;

if !variable_global_exists("appSettings") then variable_global_set("appSettings", app_settings_defaults());
var _settings = variable_global_get("appSettings");
if !is_struct(_settings) {
	_settings = app_settings_defaults();
	variable_global_set("appSettings", _settings);
}

var _resW = 1366;
var _resH = 768;
var _fullscreen = false;
if variable_struct_exists(_settings, "resolution_width") then _resW = real(variable_struct_get(_settings, "resolution_width"));
if variable_struct_exists(_settings, "resolution_height") then _resH = real(variable_struct_get(_settings, "resolution_height"));
if variable_struct_exists(_settings, "fullscreen") then _fullscreen = (variable_struct_get(_settings, "fullscreen") == true);

resolution_options = [
	{ w: 1280, h: 720, label: "1280x720" },
	{ w: 1600, h: 900, label: "1600x900" },
	{ w: 1920, h: 1080, label: "1920x1080" }
];

selected_resolution = 0;
for (var _i = 0; _i < array_length(resolution_options); _i++) {
	if (resolution_options[_i].w == _resW && resolution_options[_i].h == _resH) {
		selected_resolution = _i;
		break;
	}
}

button = [];
button[0] = "RESOLUTION";
button[1] = "FULLSCREEN";
button[2] = "SAVE AND BACK";
button[3] = "BACK";

button_desc[0] = "Cycle through the supported output resolutions.";
button_desc[1] = "Toggle fullscreen mode for the next apply step.";
button_desc[2] = "Apply current resolution, fullscreen, and color values.";
button_desc[3] = "Return to the neo main terminal without saving.";

buttons = array_length_1d(button);
menu_index = 0;
fullscreen_value = _fullscreen;

var _color = c_white;
if variable_struct_exists(_settings, "player_color") then _color = real(variable_struct_get(_settings, "player_color"));
sliderR = color_get_red(_color);
sliderG = color_get_green(_color);
sliderB = color_get_blue(_color);
draggingSlider = -1;

colorPickerX = 388;
colorPickerW = 260;
colorPickerH = 14;

last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);
