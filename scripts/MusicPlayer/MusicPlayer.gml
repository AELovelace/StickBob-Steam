function musicPlayerLoadArtists(){
	track_list = [];
	ANG3LWARE_LIST = [radio_3, bassything, flute_loop_4, all_my_heroes_quit, wailing]
	GLOOMSTONE_LIST = [CryToDeath, ESAL, LockYourDoors, trashworld, BetterOffAlone]
	PHOSPHORRGIRL_LIST = [verdant_homeworld, hybridheart, Raigekill, spearmint_trance, Water_Form_Heart]
	musicPlayerRefreshUnlockedArtists()
	startArtist = 0
	numArtists = array_length(artists)
}

function musicPlayerRefreshUnlockedArtists(){
	var _current_label = ""
	if (variable_instance_exists(id, "artistPosition")
		&& variable_instance_exists(id, "artistName")
		&& artistPosition >= 0
		&& artistPosition < array_length(artistName)) {
		_current_label = artistName[artistPosition]
	}

	artists = [ANG3LWARE_LIST]
	artistName = ["ANG3LWARE"]

	if (unlockables_is_unlocked("playlist.gloomstone")) {
		array_push(artists, GLOOMSTONE_LIST)
		array_push(artistName, "GLOOMSTONE")
	}
	if (unlockables_is_unlocked("playlist.phosphorrgirl")) {
		array_push(artists, PHOSPHORRGIRL_LIST)
		array_push(artistName, "PHOSPHORRGIRL")
	}

	numArtists = array_length(artists)
	if (numArtists <= 0) {
		artists = [ANG3LWARE_LIST]
		artistName = ["ANG3LWARE"]
		numArtists = 1
	}

	if (variable_instance_exists(id, "artistPosition")) {
		var _next_index = 0
		if (string_length(_current_label) > 0) {
			for (var _i = 0; _i < array_length(artistName); _i++) {
				if (artistName[_i] == _current_label) {
					_next_index = _i
					break
				}
			}
		}

		artistPosition = clamp(_next_index, 0, array_length(artists) - 1)
		musicPlayerSetArtist(artistPosition, false)
	}
}

function musicPlayerSetArtist(_index, _play_track){
	if (!variable_instance_exists(id, "track_position")) track_position = 0
	artistPosition = clamp(_index, 0, array_length(artists) - 1)
	track_list = []
	array_copy(track_list, 0, artists[artistPosition], 0, array_length(artists[artistPosition]))
	track_position = clamp(track_position, 0, max(0, array_length(track_list) - 1))
	if (_play_track && array_length(track_list) > 0) {
		play_current_track()
	}
}

function musicPlayerInitVariables(){
	musicPlayerSetArtist(startArtist, false)
	mp3Open = true
	autoSkip = true
	paused = false
	randomizeSong = false
	currentPos = 1
	songDuration = 1
	songPercent = 1
	songName = "dogs"
	artistPosition = startArtist
	track_position = 0
	audio_instance = -1
	refStringLength = string_length("ref sound ")
	hwidth = display_get_gui_width()
}

function play_current_track() {
	if (audio_instance != -1) {
		audio_stop_sound(audio_instance)
	}
	audio_instance = audio_play_sound(track_list[track_position], 10, false, 5)
	song_playing = true
}

function pauseCurrentTrack(){
	show_debug_message("Pause Clicked!")
	switch (paused){
		case true:
			audio_resume_sound(audio_instance)
			paused = false
			show_debug_message("Paused")
			break
		case false:
			audio_pause_sound(audio_instance)
			paused = true
			show_debug_message("unpaused")
			break
	}
}

function nextTrack(){
	show_debug_message("Next Clicked!")
	if (randomizeSong == true){
		pickRandomSong()
		play_current_track()
		return
	}
	track_position = (track_position + 1)
	if(track_position >= array_length(track_list)){
		track_position = 0
	} else if(track_position >= 0) {
		play_current_track()
	}
}

function prevTrack(){
	show_debug_message("Prev. Clicked!")
	if (randomizeSong == true){
		pickRandomSong()
		play_current_track()
		return
	}
	track_position = (track_position - 1)
	if(track_position < 0){
		track_position = array_length(track_list)-1
	} else if(track_position >= 0) {
		play_current_track()
	}
}

function nextArtist(){
	show_debug_message("Next Artist Clicked!")
	paused = false
	artistPosition = (artistPosition + 1) mod array_length(artists)
	track_position = 0
	musicPlayerSetArtist(artistPosition, true)
}

function prevArtist(){
	show_debug_message("Prev Artist Clicked!")
	artistPosition = (artistPosition - 1)
	paused = false
	if(artistPosition < 0){
		artistPosition = array_length(artists) - 1
	}
	track_position = 0
	musicPlayerSetArtist(artistPosition, true)
}

function pickRandomSong(){
	artistPosition = irandom(max(0, numArtists - 1))
	musicPlayerSetArtist(artistPosition, false)
	track_position = irandom_range(0, array_length(track_list)-1)
}
