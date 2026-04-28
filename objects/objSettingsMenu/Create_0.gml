menu_x = room_width / 2
menu_y = room_height / 2
button_h = 40

// Ensure a valid app settings struct exists before building UI state.
if !variable_global_exists("appSettings") then variable_global_set("appSettings", app_settings_defaults())
var _settings = variable_global_get("appSettings")
if !is_struct(_settings) {
    _settings = app_settings_defaults()
    variable_global_set("appSettings", _settings)
}

var _resW = 1366
var _resH = 768
var _fullscreen = false
if variable_struct_exists(_settings, "resolution_width") then _resW = real(variable_struct_get(_settings, "resolution_width"))
if variable_struct_exists(_settings, "resolution_height") then _resH = real(variable_struct_get(_settings, "resolution_height"))
if variable_struct_exists(_settings, "fullscreen") then _fullscreen = (variable_struct_get(_settings, "fullscreen") == true)

// Supported output resolutions for now.
resolution_options = [
    { w: 1280, h: 720, label: "1280x720" },
    { w: 1600, h: 900, label: "1600x900" },
    { w: 1920, h: 1080, label: "1920x1080" }
]

selected_resolution = 0
for (var i = 0; i < array_length(resolution_options); i++) {
    if (resolution_options[i].w == _resW
    &&  resolution_options[i].h == _resH) {
        selected_resolution = i
        break
    }
}

button = []
var _initialOption = resolution_options[selected_resolution]
button[0] = "Resolution: " + string(variable_struct_get(_initialOption, "label"))
button[1] = "Fullscreen: " + string(_fullscreen)
button[2] = "Save and Back"
button[3] = "Back"

buttons = array_length_1d(button)
menu_index = 0
last_selected = 0
fullscreen_value = _fullscreen

// --- Color picker state ---
var _color = c_white
if variable_struct_exists(_settings, "player_color") then _color = real(variable_struct_get(_settings, "player_color"))
sliderR       = color_get_red(_color)
sliderG       = color_get_green(_color)
sliderB       = color_get_blue(_color)
draggingSlider = -1   // -1 = none, 0 = R, 1 = G, 2 = B

// Layout constants: place the picker to the right of the button list
colorPickerX  = menu_x + 200   // left edge of slider tracks
colorPickerW  = 180            // track width in GUI pixels
colorPickerH  = 14             // track height in GUI pixels