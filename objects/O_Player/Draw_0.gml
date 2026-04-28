/// @description Visual reaction to being hit

// Tint body with the player's chosen colour, then restore blend for other sprites
image_blend = playerColor
draw_self()
image_blend = c_white

// Nameplate — Steam name floating above the character
draw_set_font(fontMenuSmall)
draw_set_halign(fa_center)
draw_set_valign(fa_bottom)
draw_set_color(c_white)
draw_text(x, y - sprite_height - 4, steamName)
draw_set_valign(fa_top)

// If paddle is hit by bullet
//if moveSpeed < 5 {
//	draw_set_color(c_white);
//	draw_set_alpha(1-moveSpeed/5)
//	draw_rectangle(bbox_left,bbox_top,bbox_right-1,bbox_bottom-1,false)
//}
draw_set_alpha(1)
	if (sprite_index == sprPlayerSkidLeft){
		draw_sprite_ext(sprPlayerGun, 0, x+5,y-3, image_xscale, -1, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerRunLeft){
		draw_sprite_ext(sprPlayerGun, 0, x+3,y+1, image_xscale, -1, mouseAngle, playerColor, 1)
		
	}
	else if (sprite_index == sprPlayerSlideLeft){
		draw_sprite_ext(sprPlayerGun, 0, x+8,y+10, image_xscale, -1, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerFallingLeft){
		draw_sprite_ext(sprPlayerGun, 0, x-3,y-8, image_xscale, -1, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerCrawlLeft){
		draw_sprite_ext(sprPlayerGun, 0, x-7,y+8, image_xscale, -1, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerSkid){
		draw_sprite_ext(sprPlayerGun, 0, x-5,y-3, image_xscale, image_yscale, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerRun){
		draw_sprite_ext(sprPlayerGun, 0, x+1,y-1, image_xscale, image_yscale, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerSlide){
		draw_sprite_ext(sprPlayerGun, 0, x-8,y+10, image_xscale, image_yscale, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerFalling){
		draw_sprite_ext(sprPlayerGun, 0, x-3,y-8, image_xscale, image_yscale, mouseAngle, playerColor, 1)
	}
	else if (sprite_index == sprPlayerCrawl){
		draw_sprite_ext(sprPlayerGun, 0, x+7,y+8, image_xscale, image_yscale, mouseAngle, playerColor, 1)
	}
	else if(mouseAngle < 270 && mouseAngle > 90 && sprite_index == sprPlayerIdle){	
		draw_sprite_ext(sprPlayerGun, 0, x,y, image_xscale, -1, mouseAngle, playerColor, 1)
	}
	else{
		draw_sprite_ext(sprPlayerGun, 0, x,y, image_xscale, image_yscale, mouseAngle, playerColor, 1)
	}

//blood effect
if(playerHealth <= 4){
		draw_sprite_ext(sprPlayerHit, image_index, x, y, image_xscale, image_yscale, 0, c_white, 1)
}
if(playerHealth <= 3){
		draw_sprite_ext(sprPlayerHit, image_index, x, y, image_xscale, -1, 180, c_white, 1)
}
if(playerHealth == 2){
	if(xSpeed >= 0){
		draw_sprite_ext(sprPlayerPuddle, image_index, x, y, image_xscale, image_yscale, 0, c_white, 1)
	} else {
		draw_sprite_ext(sprPlayerPuddle, image_index, x, y, image_xscale, -1, 180, c_white, 1)
	}
}
if(playerHealth <= 1){
		draw_sprite_ext(sprPlayerPuddle, image_index, x, y, image_xscale, image_yscale, 0, c_white, 1)
		draw_sprite_ext(sprPlayerPuddle, image_index, x, y, image_xscale, -1, 180, c_white, 1)
}