draw_sprite_ext(sprSliderBar, 0, 16, display_get_gui_height() - 32, 1, 1, 0, c_white, 1);
draw_sprite_ext(sprSliderKnob, 0, slider_x, display_get_gui_height() - 32, 1, 1, 0, c_white, 1);
draw_text(16, display_get_gui_height() - 60, "volume: " + string(global.masterVolume));