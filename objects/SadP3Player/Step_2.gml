mouse_x_prev = mouse_x;
//var _gain = (global.musicVolume <= 0) ? 0 : power(10, ((global.musicVolume / 100) - 1) * 2);
var _gain = (global.masterGain/8)
audio_group_set_gain(SADP3, _gain, 0);
