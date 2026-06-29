
global.musicVolume = 0
var _s = app_settings_current();
global.musicVolume = variable_struct_exists(_s, "music_volume") ? clamp(real(_s.music_volume), 0, 100) : 100;
audio_group_load(SADP3);
display_reset(4, true);
// Draw GUI ordering in this project behaves more reliably with the radio
// on a very deep positive layer so it renders after the menu shells.
depth = 1000000;

musicPlayerLoadArtists()	//load artist music
startArtist = irandom(numArtists - 1)	//pick a random unlocked playlist on boot
musicPlayerInitVariables()	//init vars
track_position = irandom(max(0, array_length(track_list) - 1))	//random track in that playlist

// Apply saved volume to the audio group BEFORE starting playback so the
// sound never plays at the wrong gain for even one frame.
var _gain = (global.musicVolume <= 0) ? 0 : power(10, ((global.musicVolume / 100) - 1) * 2);
audio_group_set_gain(SADP3, _gain / 8, 0);

play_current_track();		//playCurrentTrack

// Music volume slider


music_slider_button_width = sprite_get_width(sprSliderKnob) * 2;
music_slider_width = sprite_get_width(sprSliderBar) * 2 - music_slider_button_width;
music_slider_x = 0; // synced every step from volume
music_slider_state = "idle";
music_slider_clicked_x = 0;
music_mouse_x_prev = 0;
