if(!audio_is_playing(audio_instance)){
	songPercent = 0;
	if (randomizeSong == true){
		pickRandomSong()
		play_current_track()
		return;
	} else{
	track_position = (track_position + 1);
	}
	if(track_position >= array_length(track_list)){
			track_position = 0;
	} else if(track_position >= 0) {
		play_current_track()
	}
} 
else {
	currentPos = audio_sound_get_track_position(audio_instance)
	songDuration = audio_sound_length(audio_instance)
	songPercent = ((currentPos/songDuration)*100)
}

//check for clicks in step event
var mouse_gui_x = device_mouse_x_to_gui(0);
var mouse_gui_y = device_mouse_y_to_gui(0);
var _hwidth = display_get_gui_width();
var playWidth = sprite_get_width(Stop);
var playHeight = sprite_get_height(Stop);
var playX = _hwidth-63; // The x position where you drew it in Draw GUI
var playY = 140; // The y position where you drew it in Draw GUI
var skipX = _hwidth-25
var skipY = 140
var prevX = _hwidth-96
var prevY = 140
var artUpX = _hwidth-62
var ArtUpY = 105
var artDownX = _hwidth-62
var artDownY = 173


if (point_in_rectangle(mouse_gui_x, mouse_gui_y, playX-16, playY-16, playX + 16, playY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		pauseCurrentTrack();
    }
}
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, skipX-16,skipY-16, skipX + 16, skipY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		nextTrack()
    }
}
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, prevX-16, prevY-16, prevX + 16, prevY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		prevTrack()
    }
}
//TODO: implement artist up/down in mp3 player
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, artUpX-16, ArtUpY-16, artUpX + 16, ArtUpY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		nextArtist()
    }
}
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, artDownX-16, artDownY-16, artDownX + 16, artDownY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		prevArtist();    
    }
}

// Music volume slider (only active when mp3 is open)
if (mp3Open == true) {
    var _sgui_x = _hwidth - 128;
    var _sgui_y = 200;
    
    // Ensure slider_x is anchored correctly on first open (music_slider_x starts at 0)
    if (music_slider_x < _sgui_x || music_slider_x > _sgui_x + music_slider_width) {
        music_slider_x = _sgui_x + (global.musicVolume / 100) * music_slider_width;
        music_mouse_x_prev = mouse_gui_x;
    }

    // Release resets state and snaps knob to exact volume position
    if (mouse_check_button_released(mb_left)) {
        music_slider_state = "idle";
        music_slider_x = _sgui_x + (global.musicVolume / 100) * music_slider_width;
    }

    switch (music_slider_state) {
        case "idle":
            // Click on knob — begin drag
            if (point_in_rectangle(mouse_gui_x, mouse_gui_y, music_slider_x - 16, _sgui_y - 16, music_slider_x + music_slider_button_width + 16, _sgui_y + 8)) {
                if (mouse_check_button_pressed(mb_left)) {
                    music_slider_state = "active";
                    music_mouse_x_prev = mouse_gui_x;
                }
            // Click on bar — jump knob to clicked position
            } else if (mouse_check_button_pressed(mb_left)) {
                if (point_in_rectangle(mouse_gui_x, mouse_gui_y, _sgui_x, _sgui_y - 16, _sgui_x + music_slider_width + music_slider_button_width, _sgui_y + 8)) {
                    music_slider_x = clamp(mouse_gui_x - (music_slider_button_width / 2), _sgui_x, _sgui_x + music_slider_width);
                    global.musicVolume = ((music_slider_x - _sgui_x) / music_slider_width * 100) div 5 * 5;
                    music_slider_state = "active";
                    music_mouse_x_prev = mouse_gui_x;
                }
            }
            break;
        case "active":
            music_slider_x = clamp(music_slider_x + (mouse_gui_x - music_mouse_x_prev), _sgui_x, _sgui_x + music_slider_width);
            global.musicVolume = ((music_slider_x - _sgui_x) / music_slider_width * 100) div 5 * 5;
            music_mouse_x_prev = mouse_gui_x;
            break;
    }
}