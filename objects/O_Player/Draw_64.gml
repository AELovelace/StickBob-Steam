draw_set_color(c_red); // Set the text color to white
draw_set_halign(fa_left); // Align text to the left
draw_set_valign(fa_top); // Align text to the top
draw_set_font(fontMenu)
draw_sprite_ext(sprMP3Open, image_number, 0,0,1,1,0,c_white,1)
if(playerHealth > 0){
	draw_sprite_ext(sprPlayerIdle, image_number, 64,64,2,2,0,c_white,1)
}

if(playerHealth <= 4){
		draw_sprite_ext(sprPlayerHit, image_index, 64, 64, 2, 2, 0, c_white, 1)
}
if(playerHealth <= 3){
		draw_sprite_ext(sprPlayerHit, image_index, 64, 64, 2, -2, 180, c_white, 1)
}
if(playerHealth <= 2){
		draw_sprite_ext(sprPlayerPuddle, image_index, 64, 64, 2, 2, 0, c_white, 1)
}
if(playerHealth <= 1){
		draw_sprite_ext(sprPlayerPuddle, image_index, 64, 64, 2, -2, 180, c_white, 1)
}
if(playerHealth <= 0){
	draw_sprite_ext(sprPlayerDie, image_index, 64, 64, 2, -2, 180, c_white, 1)
}
draw_text(15, 6, "Health:" + string(playerHealth));
draw_healthbar(10,105, 120, 115, speedBar, c_black, c_red, c_green, 0, true, true)
//draw_text(10,116,"Speed:" + string(speedBar))
//draw_text(10, 30, "ySpeed: " + string(ySpeed));
//draw_text(10, 45, "xInput: " + string(xInput));
//draw_text(10, 60, "yInput: " + string(yInput));
//draw_text(10, 75, "wallJump: " + string(wallJump));
//draw_text(10, 90, "wallJumpTimer: " + string(cwjt));
//draw_text(10, 105, "canJump: " + string(canJump));
//draw_text(10, 120, "isCrawling: " + string(isCrawling));
//draw_text(10, 135, "fallCooldown: " + string(fallCooldown));
//draw_text(10, 150, "collisionAngle: " + string(collisionAngle));
