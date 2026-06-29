/// @description Fly forward
x+= lengthdir_x(moveSpeed,direction)
y+= lengthdir_y(moveSpeed,direction)
if (place_meeting(x, y+1, collision_tilemap_id)){
	instance_destroy()	
}

// Particle sparkle trail
var _bx = x - lengthdir_x(6, direction);
var _by = y - lengthdir_y(6, direction);
part_particles_create(global.ps, _bx, _by, global.p_bullet_trail, 3);
