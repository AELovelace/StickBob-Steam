// obj_RunnerHazard  Collision: O_Player
// Instant kill on hazard touch. other = O_Player instance.
if (other.sprite_index == sprPlayerDie) exit;  // already dying

other.playerHealth -=1;
instance_destroy(self)
//other.sprite_index = sprPlayerDie;
//other.image_speed  = 1;
//global.stopShooting = true;
//if (audio_is_playing(i_fucked_ur_mum) == false) {
//    audio_play_sound(i_fucked_ur_mum, 10, false);
//}
