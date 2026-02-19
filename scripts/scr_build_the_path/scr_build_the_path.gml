// Reconstructs a walkable GML path from the BFS wave-number grid produced
// by scr_fill_the_grid().
//
// After BFS completes, each visited cell holds the wave number i at which it
// was first reached.  This function traces backwards from the goal (wave = N)
// down to wave 1, adding a path point at each step, then appends the enemy's
// current world position as the final (start) point.
//
// The resulting path (path_building) is an open GML path asset stored on the
// calling instance.  scr_follow_the_path() reads it to drive movement.
//
// Parameters:
//   xgoal, ygoal – goal grid cell coordinates (same values passed to scr_fill_the_grid)
//
// Uses ds_gridpathfinding (instance var set by scr_fill_the_grid) for lookups.
function scr_build_the_path(xgoal, ygoal){
	path_building = path_add();  // create a new GML path asset on this instance
	var value;         // wave number stored in the grid at the current backtrack cell
	var x_previous;   // x of the cell we're tracing back from (used for fall-scan)
	var a = -1;        // fall-scan: grid value to the left during backtrack
	var b = -1;        // fall-scan: grid value to the right during backtrack
	var n = 0;         // fall-scan: how many cells above we have scanned

	// Add the goal position as the first path point (path will be reversed at the end)
	path_add_point(path_building,
	    xgoal * O_Grid.cell_width  + (O_Grid.cell_width  / 2),
	    ygoal * O_Grid.cell_height + (O_Grid.cell_height / 2), 100);

	value = ds_grid_get(ds_gridpathfinding, xgoal, ygoal);  // highest wave number = goal

	// Walk backwards through decreasing wave numbers to retrace the BFS path
	for (var i = value - 1; i > 0; i -= 1)
	{
	    x_previous = xgoal;
	    n = 0;

	    // Check adjacent cells (±1 in x, same or +1 in y) for wave number i
	    // This covers: walk left/right and step-up one block left/right
	    if ds_grid_value_exists(ds_gridpathfinding, xgoal-1, ygoal, xgoal+1, ygoal+1, i)
	       {
	       xgoal = ds_grid_value_x(ds_gridpathfinding, xgoal-1, ygoal, xgoal+1, ygoal+1, i);
	       ygoal = ds_grid_value_y(ds_gridpathfinding, x_previous-1, ygoal, x_previous+1, ygoal+1, i);
	       path_add_point(path_building,
	           xgoal * O_Grid.cell_width  + (O_Grid.cell_width  / 2),
	           ygoal * O_Grid.cell_height + (O_Grid.cell_height / 2), 100);
	       }
	            else
	            {
	                // Wider search (±2 in x, same or +1 in y): covers diagonal / gap jumps
	                if ds_grid_value_exists(ds_gridpathfinding, xgoal-2, ygoal, xgoal+2, ygoal+1, i)
	                {
	                xgoal = ds_grid_value_x(ds_gridpathfinding, xgoal-2, ygoal, xgoal+2, ygoal+1, i);
	                    // Sanity-check: can the enemy actually jump that direction, or did it fall?
	                    if ds_grid_get(ds_gridpathfinding, x_previous + sign(xgoal - x_previous), ygoal) == -1
	                    {
	                    // Genuine jump — the intermediate cell is open
	                    ygoal = ds_grid_value_y(ds_gridpathfinding, x_previous-2, ygoal, x_previous+2, ygoal+1, i);
	                    path_add_point(path_building,
	                        xgoal * O_Grid.cell_width  + (O_Grid.cell_width  / 2),
	                        ygoal * O_Grid.cell_height + (O_Grid.cell_height / 2), 100);
	                    }
	                        else {
	                            // Intermediate cell is solid — the enemy must have fallen here.
	                            // Scan upward from ygoal to find which cell above held wave i
	                            {
	                            do
	                               {
	                               n = n + 1;
	                               a = ds_grid_get(ds_gridpathfinding, x_previous-1, ygoal-n);
	                               b = ds_grid_get(ds_gridpathfinding, x_previous+1, ygoal-n);
	                               }
	                            until (a == i) || (b == i) || ((ygoal - n) < 0)
	                            }
	                                    if ds_grid_value_exists(ds_gridpathfinding, x_previous-1, ygoal-n, x_previous+1, ygoal-n, i)
	                                    {
	                                       xgoal = ds_grid_value_x(ds_gridpathfinding, x_previous-1, ygoal-n, x_previous+1, ygoal, i);
	                                       ygoal = ds_grid_value_y(ds_gridpathfinding, x_previous-1, ygoal-n, x_previous+1, ygoal, i);
	                                       path_add_point(path_building,
	                                           xgoal * O_Grid.cell_width  + (O_Grid.cell_width  / 2),
	                                           ygoal * O_Grid.cell_height + (O_Grid.cell_height / 2), 100);
	                                    }
	                        }
	                }
	                            else {
	                                // No cell found within ±2 — the enemy fell to this position.
	                                // Scan upward to locate the departure cell (same fall-recovery logic as above)
	                                {
	                                do
	                                   {
	                                   n = n + 1;
	                                   a = ds_grid_get(ds_gridpathfinding, x_previous-1, ygoal-n);
	                                   b = ds_grid_get(ds_gridpathfinding, x_previous+1, ygoal-n);
	                                   }
	                                    until (a == i) || (b == i) || ((ygoal - n) < 0)
	                                }
	                                    if ds_grid_value_exists(ds_gridpathfinding, x_previous-1, ygoal-n, x_previous+1, ygoal-n, i)
	                                    {
	                                       xgoal = ds_grid_value_x(ds_gridpathfinding, x_previous-1, ygoal-n, x_previous+1, ygoal, i);
	                                       ygoal = ds_grid_value_y(ds_gridpathfinding, x_previous-1, ygoal-n, x_previous+1, ygoal, i);
	                                       path_add_point(path_building,
	                                           xgoal * O_Grid.cell_width  + (O_Grid.cell_width  / 2),
	                                           ygoal * O_Grid.cell_height + (O_Grid.cell_height / 2), 100);
	                                    }
	                            }
	            }
	}

	// Append the enemy's current world position as the final (start) point of the path
	path_add_point(path_building,
	    floor(x / O_Grid.cell_width)  * O_Grid.cell_width  + (O_Grid.cell_width  / 2),
	    floor(y / O_Grid.cell_height) * O_Grid.cell_height + (O_Grid.cell_height / 2), 100);

	// Open path (no looping) — the enemy walks it once from start to goal
	path_set_closed(path_building, 0);
	//path_reverse(path_building);  // reversed path is read backwards during follow; currently disabled
}
