// Create an array (or a list) of your sound assets
track_list = [radio_3, bassything, flute_loop_4, all_my_heroes_quit,wailing ]; // Add all your tracks
track_position = 0; // Start with the first track (index 0)
audio_instance = -1; // Variable to store the currently playing sound's ID
refStringLength = string_length("ref sound ");
mp3Open = true
paused = false;

currentPos = 1
songDuration = 1
songPercent = 1


hwidth = display_get_gui_width()
// Function to play the current track
function play_current_track() {
    // Stop any currently playing music first
    if (audio_instance != -1) {
        audio_stop_sound(audio_instance);
    }
    // Play the new track, priority 10, looping (true)
    audio_instance = audio_play_sound(track_list[track_position], 10, false);
    // Set a variable to ensure the song only plays once
    song_playing = true; 
}

// Start the initial track
play_current_track();