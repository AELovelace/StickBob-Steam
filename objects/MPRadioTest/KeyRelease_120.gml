
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
	