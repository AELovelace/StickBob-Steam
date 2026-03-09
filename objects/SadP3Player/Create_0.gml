audio_group_load(SADP3);

musicPlayerLoadArtists()	//load artist music
musicPlayerInitVariables()	//init vars
play_current_track();		//playCurrentTrack

// Music volume slider
global.musicVolume = 100;
music_slider_button_width = sprite_get_width(sprSliderKnob) * 2;
music_slider_width = sprite_get_width(sprSliderBar) * 2 - music_slider_button_width;
music_slider_x = 0; // synced every step from volume
music_slider_state = "idle";
music_slider_clicked_x = 0;
music_mouse_x_prev = 0;