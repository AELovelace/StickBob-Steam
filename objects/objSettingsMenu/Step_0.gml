menu_move = keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up)
menu_index = clamp(menu_index + menu_move, 0, buttons - 1)

var _left = keyboard_check_pressed(vk_left)
var _right = keyboard_check_pressed(vk_right)
var _confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)

if (menu_index == 0 && (_left || _right)) {
    // Cycle resolution options and keep label in sync with selection.
    selected_resolution += (_right - _left)
    if (selected_resolution < 0) selected_resolution = array_length(resolution_options) - 1
    if (selected_resolution >= array_length(resolution_options)) selected_resolution = 0
	var _currentOption = resolution_options[selected_resolution]
	button[0] = "Resolution: " + string(variable_struct_get(_currentOption, "label"))
}

if (menu_index == 1 && (_left || _right || _confirm)) {
    // Toggle fullscreen flag and show current state in menu text.
    fullscreen_value = !fullscreen_value
	if(fullscreen_value == true){
		button[1] = "Fullscreen: True"	
	} else{
		button[1] = "Fullscreen: False"
	}
}

if (_confirm) {
    var _selectedOption

    if (menu_index == 2) {
        var _settings = app_settings_defaults()
        if variable_global_exists("appSettings") then _settings = variable_global_get("appSettings")
        if !is_struct(_settings) then _settings = app_settings_defaults()
        variable_struct_set(_settings, "player_color", make_color_rgb(sliderR, sliderG, sliderB))
        variable_global_set("appSettings", _settings)
    }

    switch (menu_index) {
        case 2:
            _selectedOption = resolution_options[selected_resolution]
            app_settings_apply_choice(_selectedOption, fullscreen_value)

            instance_create_layer(x, y, "Instances", objMainMenu)
            instance_destroy()
            break

        case 3:
            instance_create_layer(x, y, "Instances", objMainMenu)
            instance_destroy()
            break
    }
}

// --- Color picker slider interaction ---
var _cx  = colorPickerX
var _cw  = colorPickerW
var _ch  = colorPickerH
var _rY  = menu_y           // R slider row
var _gY  = menu_y + 40      // G slider row
var _bY  = menu_y + 80      // B slider row

// Draw_64 uses GUI-space coordinates, so slider input must also use GUI-space mouse coords.
var _mx = device_mouse_x_to_gui(0)
var _my = device_mouse_y_to_gui(0)

if mouse_check_button_pressed(mb_left) {
    if point_in_rectangle(_mx, _my, _cx, _rY - _ch, _cx + _cw, _rY + _ch) {
        draggingSlider = 0
    } else if point_in_rectangle(_mx, _my, _cx, _gY - _ch, _cx + _cw, _gY + _ch) {
        draggingSlider = 1
    } else if point_in_rectangle(_mx, _my, _cx, _bY - _ch, _cx + _cw, _bY + _ch) {
        draggingSlider = 2
    }
}

if mouse_check_button(mb_left) && draggingSlider != -1 {
    var _val = round(clamp((_mx - _cx) / _cw, 0, 1) * 255)
    switch draggingSlider {
        case 0: sliderR = _val; break
        case 1: sliderG = _val; break
        case 2: sliderB = _val; break
    }
}

if mouse_check_button_released(mb_left) then draggingSlider = -1