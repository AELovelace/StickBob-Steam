function musicPlayerLoadArtists(){
	track_list = [];
	ANG3LWARE_LIST = [radio_3, bassything, flute_loop_4, all_my_heroes_quit,wailing ]
	GLOOMSTONE_LIST = [CryToDeath,ESAL,LockYourDoors,trashworld,BetterOffAlone]
	PHOSPHORRGIRL_LIST = [verdant_homeworld,hybridheart,Raigekill,spearmint_trance,Water_Form_Heart]
	artists = [ANG3LWARE_LIST,GLOOMSTONE_LIST,PHOSPHORRGIRL_LIST]
	artistName = ["ANG3LWARE", "GLOOMSTONE","PHOSPHORRGIRL"]
	startArtist = random(3)
	numArtists = 3;

}
function musicPlayerInitVariables(){
	array_copy(track_list,0,artists[startArtist],0,array_length(artists[startArtist]))
	mp3Open = true
	autoSkip = true
	paused = false;
	randomizeSong = false;
	currentPos = 1
	songDuration = 1
	songPercent = 1	
	songName = "dogs"
	artistPosition = startArtist
	track_position = 0; // Start with the first track (index 0)
	audio_instance = -1; // Variable to store the currently playing sound's ID
	refStringLength = string_length("ref sound ");
	hwidth = display_get_gui_width()

}

function play_current_track() {
    // Stop any currently playing music first
    if (audio_instance != -1) {
        audio_stop_sound(audio_instance);
    }
    // Play the new track, priority 10, looping (true)
    audio_instance = audio_play_sound(track_list[track_position], 10, false,5);
    // Set a variable to ensure the song only plays once
    song_playing = true; 
}
function pauseCurrentTrack(){
	show_debug_message("Pause Clicked!");
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
function nextTrack(){
	show_debug_message("Next Clicked!");
	if (randomizeSong == true){
		pickRandomSong()
		play_current_track()	
		return;
	}
	track_position = (track_position + 1);	
	if(track_position >= array_length(track_list)){
		track_position = 0;
	} else if(track_position >= 0) {
		play_current_track()
	}
}

function prevTrack(){
	show_debug_message("Prev. Clicked!");
	if (randomizeSong == true){
		pickRandomSong()
		play_current_track()	
		return;
	}
	track_position = (track_position - 1);	
	if(track_position < 0){
		track_position = array_length(track_list)-1;
	} else if(track_position >= 0) {
		play_current_track()
	}	
}

function nextArtist(){
	show_debug_message("Next Artist Clicked!");
	paused = false
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
function prevArtist(){
	show_debug_message("Prev Artist Clicked!");
	artistPosition = (artistPosition - 1);	
	paused = false
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

function pickRandomSong(){
	artistPosition = random(numArtists)
	array_copy(track_list,0,artists[artistPosition],0,array_length(track_list))
	track_position = irandom_range(0, array_length(track_list)-1)
}