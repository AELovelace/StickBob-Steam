

// Step event
var gui_x = 16;
var gui_y = display_get_gui_height() - 32;
// If the user clicks on the slider's button
if point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), gui_x, gui_y, gui_x + slider_width, gui_y+button_width){
	if mouse_check_button_pressed(mb_left){
		slider_state = "active";
		slider_button_clicked_x_position = device_mouse_x_to_gui(0) - slider_x;
	}
}

// If the user releases the left mouse button
if mouse_check_button_released(mb_left)
{
    slider_state = "idle";
}

switch (slider_state)
{
    // If the user clicks on the slider's horizontal bar
case "idle":
    if mouse_check_button_pressed(mb_left)
    {
        if point_in_rectangle(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), gui_x, gui_y, gui_x + slider_width + button_width, gui_y + 16)
        {
            slider_x = clamp(device_mouse_x_to_gui(0) - (button_width / 2), gui_x, gui_x + slider_width);
            global.masterVolume = ((slider_x - gui_x) / slider_width * 100) div 5 * 5;
            slider_state = "active";
            slider_button_clicked_x_position = device_mouse_x_to_gui(0) - slider_x;
        }
    }
    break;
    
    // If the user has clicked on the slider button
    case "active":
        // If the user drags the mouse to the right ...
        if (device_mouse_x_to_gui(0) - mouse_x_prev) > 0
        {
            // ... past the point where the user first clicked on the slider button
            if device_mouse_x_to_gui(0) >= gui_x + slider_button_clicked_x_position
            {
                slider_x = clamp(slider_x + (device_mouse_x_to_gui(0) - mouse_x_prev), gui_x, gui_x + slider_width);
                global.masterVolume = ((slider_x - gui_x) / slider_width * 100) div 5 * 5;
            }
        }
        // If the user drags the mouse to the left
        else
        {
            // ... past the point where the user first clicked on the slider button
            if device_mouse_x_to_gui(0) <= gui_x + slider_width + slider_button_clicked_x_position
            {
                slider_x = clamp(slider_x + (device_mouse_x_to_gui(0) - mouse_x_prev), gui_x, gui_x + slider_width);
                global.masterVolume = ((slider_x - gui_x) / slider_width * 100) div 5 * 5;
            }
        }
        break;
}

