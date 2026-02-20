if(!audio_is_playing(audio_instance)){
	songPercent = 0;
	track_position = (track_position + 1);
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
var playWidth = sprite_get_width(Stop);
var playHeight = sprite_get_height(Stop);
var playX = hwidth-63; // The x position where you drew it in Draw GUI
var playY = 140; // The y position where you drew it in Draw GUI
var skipX = hwidth-25
var skipY = 140
var prevX = hwidth-96
var prevY = 140
var artUpX = hwidth-62
var ArtUpY = 105
var artDownX = hwidth-62
var artDownY = 173
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, playX-16, playY-16, playX + 16, playY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		show_debug_message("Button Clicked!");
		switch (paused){
			case true:
				audio_resume_sound(audio_instance)
				paused = false
				show_debug_message("Paused");
				break;
			case false:
				audio_pause_sound(audio_instance)
				paused = true;
				show_debug_message("unpaused");
				break;
		
		}
    
    }
}
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, skipX-16,skipY-16, skipX + 16, skipY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		show_debug_message("Button Clicked!");
		track_position = (track_position + 1);	
		if(track_position >= array_length(track_list)){
			track_position = 0;
		} else if(track_position >= 0) {
			play_current_track()
		}
    
    }
}
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, prevX-16, prevY-16, prevX + 16, prevY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
		show_debug_message("Button Clicked!");
		show_debug_message("Button Clicked!");
		track_position = (track_position - 1);	
		if(track_position < 0){
			track_position = array_length(track_list)-1;
		} else if(track_position >= 0) {
			play_current_track()
		}
    
    }
}
//TODO: implement artist up/down in mp3 player
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, artUpX-16, ArtUpY-16, artUpX + 16, ArtUpY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
	show_debug_message("Button Clicked!");
	artistPosition = (artistPosition + 1);	
	if(artistPosition >= array_length(artists)){
		artistPosition = 0;
		array_copy(track_list,0,artists[artistPosition],0,array_length(track_list))
		track_position = 0;
		play_current_track()
	} else if(artistPosition >= 0) {
		array_copy(track_list,0,artists[artistPosition],0,array_length(track_list))
		track_position = 0;
		play_current_track()

	}
    
    }
}
if (point_in_rectangle(mouse_gui_x, mouse_gui_y, artDownX-16, artDownY-16, artDownX + 16, artDownY + 16)) {
    if (mouse_check_button_pressed(mb_left)) {
	artistPosition = (artistPosition - 1);	
	if(artistPosition >= array_length(artists)){
		artistPosition = 0;
		array_copy(track_list,0,artists[artistPosition],0,array_length(track_list))
		track_position = 0;
		play_current_track()
	} else if(artistPosition >= 0) {
		array_copy(track_list,0,artists[artistPosition],0,array_length(track_list))
		track_position = 0;
		play_current_track()

	} else {
		artistPosition = (array_length(artists)-1)	
	}
    
    }
}