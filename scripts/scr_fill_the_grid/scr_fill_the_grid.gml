// Breadth-first search (BFS) pathfinding over the global AI grid.
//
// Grid cell conventions:
//   -1  = walkable (open air with solid floor beneath, or passable space)
//   -2  = solid / impassable
//    0  = starting cell (set during init)
//    i  = visited at BFS wave i  (i > 0 means "reachable in i steps")
//
// The algorithm expands outward from (ax, ay) wave by wave.  Each wave checks
// six movement types for every frontier cell: walk right/left, step-up one
// block right/left, diagonal big-jump right/left, horizontal gap-jump
// right/left, and fall right/left.  When the goal cell (xgoal, ygoal) is
// reached, scr_build_the_path() is called immediately to reconstruct the
// route before the grid is cleaned up.
//
// Parameters:
//   ax, ay        – starting grid cell (enemy's current grid position)
//   xgoal, ygoal  – target grid cell (player's current grid position)
//
// Returns:
//   1 if a path was found (path_found is also set on the calling instance)
//   0 if no path exists
function scr_fill_the_grid(ax, ay, xgoal, ygoal){
	path_found = undefined;
	n = undefined;  // reused fall-scan counter
	a = undefined;  // reused fall-scan cell value
	path_found = 0; // 0 = not yet found

	// Work on a per-call copy so the master grid is never modified
	ds_gridpathfinding = ds_grid_create(ds_grid_width(global.ds_grid_pathfinding), ds_grid_height(global.ds_grid_pathfinding));
	ds_grid_copy(ds_gridpathfinding, global.ds_grid_pathfinding);

	// Seed the BFS with the starting cell
	var point_list = ds_list_create();
	ds_list_add(point_list, ax);
	ds_list_add(point_list, ay);
	ds_grid_set(ds_gridpathfinding, ax, ay, 0);  // mark start as visited (wave 0)

	// i = current BFS wave depth (caps at 200 to prevent infinite loops)
	for (var i = 1; i < 200; i += 1)
	{
	    if path_found == 1 {
	        ds_list_destroy(point_list);
	        ///ds_grid_destroy(ds_gridpathfinding); // kept for debug; uncomment to free memory
	        return path_found;
	        break;
	    }

		var size_list = ds_list_size(point_list);  // number of coordinates (pairs) in the frontier

		if size_list == 0 {
			// Frontier exhausted with no path found
			ds_list_destroy(point_list);
			ds_grid_destroy(ds_gridpathfinding);
			return path_found;  // returns 0
			break;
		}

		// Iterate over every cell in the current wave (stored as x,y pairs)
		for (var j = 0; j < size_list; j += 2){
	        ax = ds_list_find_value(point_list, j)
	        ay = ds_list_find_value(point_list, j + 1)

	        if ax == xgoal && ay == ygoal {
	            path_found = 1;
	            scr_build_the_path(xgoal, ygoal);  // reconstruct path before grid changes
	            break;
	        }

		n = 1;  // reset fall-scan depth for the RIGHT side

		// --- Move right (flat ground) ---
		// Cell to the right is open AND has solid floor beneath it
		if ds_grid_get(ds_gridpathfinding, ax+1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax+1, ay+1) == -2 {
			ds_grid_set(ds_gridpathfinding, ax+1, ay, i);
			ds_list_add(point_list, ax + 1);
			ds_list_add(point_list, ay);
		}
		else {
			// Only check jump/fall variants when the direct walk is blocked

			// --- Step up one block (right) ---
			// Cell to the right is solid but the cell above it is open
			if (ds_grid_get(ds_gridpathfinding, ax+1, ay) == -2 && ds_grid_get(ds_gridpathfinding, ax+1, ay-1) == -1)
	            {
	            ds_grid_set(ds_gridpathfinding, ax+1, ay-1, i);
	            ds_list_add(point_list, ax + 1);
	            ds_list_add(point_list, ay - 1);
	            }
			else {

				// --- Diagonal / big jump (right) ---
				// Right cell is open, two-right cell is solid, two-right cell above is open
				if ds_grid_get(ds_gridpathfinding, ax+1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax+2, ay) == -2 && ds_grid_get(ds_gridpathfinding, ax+2, ay-1) == -1
	                {
	                ds_grid_set(ds_gridpathfinding, ax+2, ay-1, i);
	                ds_list_add(point_list, ax + 2);
	                ds_list_add(point_list, ay - 1);
	                }

				// --- Horizontal gap jump (right) ---
				// Two cells to the right are open and the landing cell has a floor
				if ds_grid_get(ds_gridpathfinding, ax+1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax+2, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax+2, ay+1) == -2
	                {
	                ds_grid_set(ds_gridpathfinding, ax+2, ay, i);
	                ds_list_add(point_list, ax + 2);
	                ds_list_add(point_list, ay);
	                }

				// --- Fall right ---
				// Cell to the right is open and the cell below it is also open — scan downward
				// until we find a floor cell or hit the grid boundary
				if ds_grid_get(ds_gridpathfinding, ax+1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax+1, ay+1) == -1
	                {
	                    {
	                    do
	                       {
	                       n = n + 1;
	                       a = ds_grid_get(ds_gridpathfinding, ax+1, ay+n);
	                       }
	                    until (a == -2) || (ay + n == ds_grid_height(ds_gridpathfinding))
	                    }
	                    // Add the last open cell just above the floor as a reachable landing spot
	                    if ds_grid_get(ds_gridpathfinding, ax+1, ay+n-1) == -1 && ds_grid_get(ds_gridpathfinding, ax+1, ay+n) == -2
	                        {
	                        ds_grid_set(ds_gridpathfinding, ax+1, ay+n-1, i);
	                        ds_list_add(point_list, ax + 1);
	                        ds_list_add(point_list, ay + n - 1);
	                        }
	                }
	            }
		}

		n = 1;  // reset fall-scan depth for the LEFT side

		// --- Move left (flat ground) ---
		if ds_grid_get(ds_gridpathfinding, ax-1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax-1, ay+1) == -2 {
			ds_grid_set(ds_gridpathfinding, ax-1, ay, i);
			ds_list_add(point_list, ax - 1);
			ds_list_add(point_list, ay);
		}
		else {

			// --- Step up one block (left) ---
			if ds_grid_get(ds_gridpathfinding, ax-1, ay) == -2 && ds_grid_get(ds_gridpathfinding, ax-1, ay-1) == -1 {
				ds_grid_set(ds_gridpathfinding, ax-1, ay-1, i);
				ds_list_add(point_list, ax - 1);
				ds_list_add(point_list, ay - 1);
			}
			else {

				// --- Diagonal / big jump (left) ---
				if ds_grid_get(ds_gridpathfinding, ax-1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax-2, ay) == -2 && ds_grid_get(ds_gridpathfinding, ax-2, ay-1) == -1 {
					ds_grid_set(ds_gridpathfinding, ax-2, ay-1, i);
					ds_list_add(point_list, ax - 2);
					ds_list_add(point_list, ay - 1);
				}

				// --- Horizontal gap jump (left) ---
				if ds_grid_get(ds_gridpathfinding, ax-1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax-2, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax-2, ay+1) == -2 {
					ds_grid_set(ds_gridpathfinding, ax-2, ay, i);
					ds_list_add(point_list, ax - 2);
					ds_list_add(point_list, ay);
				}

				// --- Fall left ---
				if ds_grid_get(ds_gridpathfinding, ax-1, ay) == -1 && ds_grid_get(ds_gridpathfinding, ax-1, ay+1) == -1
	                {
	                    {
	                    do
	                       {
	                       n = n + 1;
	                       a = ds_grid_get(ds_gridpathfinding, ax-1, ay+n);
	                       }
	                    until (a = -2) || (ay + n == ds_grid_height(ds_gridpathfinding))
	                    }
	                    if ds_grid_get(ds_gridpathfinding, ax-1, ay+n-1) == -1 && ds_grid_get(ds_gridpathfinding, ax-1, ay+n) == -2
	                    {
	                        ds_grid_set(ds_gridpathfinding, ax-1, ay+n-1, i);
	                        ds_list_add(point_list, ax - 1);
	                        ds_list_add(point_list, ay + n - 1);
	                    }
	                }
			}
		}
		}

		// Remove the cells that were part of this wave from the frontier list
		// so the next iteration only processes newly discovered cells
		for (var k = 0; k < size_list; k += 1)
	    {
	    ds_list_delete(point_list, 0);
	    }
	}
}
