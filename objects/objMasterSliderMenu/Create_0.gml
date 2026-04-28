audio_group_load(SFX);
button_width = sprite_get_width(sprSliderKnob);
slider_width = sprite_get_width(sprSliderBar) - button_width;
var _s = app_settings_current();
global.masterVolume = variable_struct_exists(_s, "master_volume") ? clamp(real(_s.master_volume), 0, 100) : 25;
slider_x = 16 + (global.masterVolume / 100) * slider_width;
slider_button_clicked_x_position = 0;
mouse_x_prev = 0;
slider_state = "idle";