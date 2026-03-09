

// End Step event

mouse_x_prev = device_mouse_x_to_gui(0);

var _gain = (global.masterVolume <= 0) ? 0 : power(10, ((global.masterVolume / 100) - 1) * 2);
global.masterGain = _gain
audio_master_gain(_gain);
audio_group_set_gain(SFX,_gain)