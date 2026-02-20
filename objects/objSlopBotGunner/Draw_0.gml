/// @description Visual reaction to being hit
draw_self()

// If paddle is hit by bullet
//if moveSpeed < 5 {
//	draw_set_color(c_white);
//	draw_set_alpha(1-moveSpeed/5)
//	draw_rectangle(bbox_left,bbox_top,bbox_right-1,bbox_bottom-1,false)
//}

draw_set_alpha(1)
	if(mouseAngle < 270 && mouseAngle > 90){	
		draw_sprite_ext(sprMG, 0, x,y, image_xscale, -1, mouseAngle, c_white, 1)
	}
	else{
		draw_sprite_ext(sprMG, 0, x,y, image_xscale, image_yscale, mouseAngle, c_white, 1)
	}