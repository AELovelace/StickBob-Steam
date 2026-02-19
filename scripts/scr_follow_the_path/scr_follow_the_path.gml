// Drives an enemy along the path built by scr_build_the_path().
//
// The enemy stores a path as a GML path asset (number_of_points is the asset
// index).  path_point tracks which point in the path the enemy is currently
// walking toward (0-indexed; the path is read backwards from goal → start).
//
// State variables on the calling instance:
//   action      – 0 = decide what to do next, 1 = currently executing a move
//   jump_action – 0 = not jumping, 1 = jump was already triggered this segment
//   speed_h     – current horizontal speed
//   speed_v     – current vertical speed (negative = upward in GML)
//   max_speed   – maximum walk speed
//   jump_height – vertical impulse for jumps (negative value)
//
// Call once per Step event from the enemy's step event.
function scr_follow_the_path(number_of_points){
	var path_direction;

	// Determine whether the next point is to the left (-1) or right (+1)
	path_direction = sign(path_get_point_x(number_of_points, path_point + 1) - path_get_point_x(number_of_points, path_point));

	if action == 0
	{
	    // --- Flat walk: same Y, exactly one cell away ---
	    if path_get_point_y(number_of_points, path_point) == path_get_point_y(number_of_points, path_point + 1)
	    && path_get_point_x(number_of_points, path_point) + O_Grid.cell_width * path_direction == path_get_point_x(number_of_points, path_point + 1)
	    {
	    speed_h = max_speed * path_direction;
	    action = 1;
	    }
	     else {
	            // --- Gap jump: same Y, two cells away (leap over a void) ---
	            if path_get_point_y(number_of_points, path_point) == path_get_point_y(number_of_points, path_point + 1)
	            && path_get_point_x(number_of_points, path_point) + 2 * O_Grid.cell_width * path_direction == path_get_point_x(number_of_points, path_point + 1)
	            {
	            speed_h = max_speed * path_direction;
	            speed_v = jump_height * 0.7;  // shallow arc to clear the gap
	            action = 1;
	            }
	                else {
	                    // --- Fall: next point is lower (positive Y in GML) ---
	                    if path_get_point_y(number_of_points, path_point) < path_get_point_y(number_of_points, path_point + 1)
	                    {
	                    speed_h = max_speed * path_direction;
	                        // Snap X once the enemy is directly above the landing cell
	                        if x <= path_get_point_x(number_of_points, path_point + 1)
	                        && path_get_point_x(number_of_points, path_point + 1) < (x + speed_h * path_direction)
	                        {
	                        action  = 1;
	                        speed_h = 0;
	                        x = path_get_point_x(number_of_points, path_point + 1);
	                        }
	                    }
	                        else {
	                                // --- Diagonal / big jump: two cells right/left AND one cell up ---
	                                if path_get_point_x(number_of_points, path_point) == path_get_point_x(number_of_points, path_point + 1) - O_Grid.cell_width * 2 * path_direction
	                                && path_get_point_y(number_of_points, path_point) == path_get_point_y(number_of_points, path_point + 1) + O_Grid.cell_height
	                                {
	                                speed_h = max_speed * path_direction * 0.625;  // slightly slower to arc higher
	                                speed_v = jump_height * 1.1;                   // taller arc than a gap jump
	                                action = 1;
	                                }
	                                    else {
	                                            // --- Step-up jump: one cell right/left AND one cell up ---
	                                            if path_get_point_y(number_of_points, path_point) == path_get_point_y(number_of_points, path_point + 1) + O_Grid.cell_height
	                                            && path_get_point_x(number_of_points, path_point) + O_Grid.cell_width * path_direction == path_get_point_x(number_of_points, path_point + 1)
	                                            {
	                                            speed_h = max_speed * path_direction / 2;  // slower approach before jump
	                                                // Only jump once the enemy is on the ground and hasn't already triggered this jump
	                                                if place_meeting(x, y + 1, objSolid) && jump_action == 0
	                                                {
	                                                speed_v     = jump_height * 0.9;
	                                                jump_action = 1;
	                                                speed_h     = max_speed * path_direction;  // accelerate during jump
	                                                }
	                                            }
	                                    }
	                        }
	                    }
	        }
	}

	// --- Arrival check: has the enemy reached the next path point? ---
	if x <= path_get_point_x(number_of_points, path_point + 1)
	&& path_get_point_x(number_of_points, path_point + 1) <= x + speed_h * path_direction
	&& path_get_point_y(number_of_points, path_point + 1) == y - sprite_yoffset - (O_Grid.cell_height / 2 - sprite_height)
	    {
	    path_point  = path_point + 1;
	    action      = 0;  // reset so the next segment's move type is re-evaluated
	    jump_action = 0;
	        if path_point == number_of_points - 1  // reached the last point (the goal)
	            {
	            speed_h = 0;
	            speed_v = 0;
	            path_delete(number_of_points);  // free the GML path asset
	            path_point = 0;
	            }
	    }
	}
