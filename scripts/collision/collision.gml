// Generic axis-aligned collision resolution against O_Collision objects.
// Separates horizontal and vertical axes so corners are handled cleanly.
// Used by enemies and simple physics entities; the player uses the more
// complex collision logic inside paddle_movement() instead.
function scr_collision(){
	// Horizontal: slide the instance up to the wall pixel-by-pixel, then stop
	if place_meeting(x+speed_h, y, O_Collision) {
	    while !place_meeting(x+sign(speed_h), y, O_Collision) {
	        x += sign(speed_h);
	    }
	    speed_h = 0;
	}
	x += speed_h;

	// Vertical: same approach — nudge to contact, then zero out vertical speed
	if place_meeting(x, y+speed_v, O_Collision) {
	    while !place_meeting(x, y+sign(speed_v), O_Collision) {
	        y += sign(speed_v);
	    }
	    speed_v = 0;
	}
	y += speed_v;
}
