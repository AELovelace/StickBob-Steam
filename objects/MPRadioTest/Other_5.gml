if(autoSkip == true){
	track_position = (track_position + 1);	
	if(track_position >= array_length(track_list)){
			track_position = 0;
	} else if(track_position >= 0) {
		play_current_track()
	}
}