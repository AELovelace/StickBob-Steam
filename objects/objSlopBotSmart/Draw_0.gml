/// @description Visual reaction to being hit
vfx_draw_afterimage(c_white);
draw_self()

if (isDying || sprite_index == sprPlayerDie) {
	exit;
}

scr_smart_nav_draw_debug();

draw_set_alpha(1)
	if (sprite_index == sprPlayerSkidLeft){
		draw_sprite_ext(sprPlayerGun, 0, x+5,y-3, image_xscale, -1, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerRunLeft){
		draw_sprite_ext(sprPlayerGun, 0, x-1,y-1, image_xscale, -1, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerSlideLeft){
		draw_sprite_ext(sprPlayerGun, 0, x+8,y+10, image_xscale, -1, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerFallingLeft){
		draw_sprite_ext(sprPlayerGun, 0, x-3,y-8, image_xscale, -1, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerCrawlLeft){
		draw_sprite_ext(sprPlayerGun, 0, x-7,y+8, image_xscale, -1, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerSkid){
		draw_sprite_ext(sprPlayerGun, 0, x-5,y-3, image_xscale, image_yscale, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerRun){
		draw_sprite_ext(sprPlayerGun, 0, x+1,y-1, image_xscale, image_yscale, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerSlide){
		draw_sprite_ext(sprPlayerGun, 0, x-8,y+10, image_xscale, image_yscale, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerFalling){
		draw_sprite_ext(sprPlayerGun, 0, x-3,y-8, image_xscale, image_yscale, mouseAngle, c_white, 1)
	}
	else if (sprite_index == sprPlayerCrawl){
		draw_sprite_ext(sprPlayerGun, 0, x+7,y+8, image_xscale, image_yscale, mouseAngle, c_white, 1)
	}
	//else if(mouseAngle < 270 && mouseAngle > 90 && sprite_index == sprPlayerIdle){	
	//	draw_sprite_ext(sprPlayerGun, 0, x,y, image_xscale, -1, mouseAngle, c_white, 1)
	//}
	//else{
	//	draw_sprite_ext(sprPlayerGun, 0, x,y, image_xscale, image_yscale, mouseAngle, c_white, 1)
	//}

vfx_draw_bloom(make_color_rgb(255, 60, 60));
