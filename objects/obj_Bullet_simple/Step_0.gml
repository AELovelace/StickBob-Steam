/// @description Fly forward
x+= lengthdir_x(moveSpeed,direction)
y+= lengthdir_y(moveSpeed,direction)
if (place_meeting(x, y+1, collision_tilemap_id)){
	instance_destroy()	
}
