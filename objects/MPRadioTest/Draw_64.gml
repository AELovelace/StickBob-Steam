draw_set_font(fontMenuSmall)
draw_set_color(c_white)

draw_set_halign(fa_center);
draw_set_valign(fa_top);
if(mp3Open == true){
	draw_sprite_ext(sprMP3Open, image_number, hwidth-128,0,2,1.5,0,c_white,1)
	draw_sprite_ext(spr_Button, image_number, hwidth-63,55,1.5,1.5,0,c_white,1)
	draw_text(hwidth-64, 10, "SADP3-PLR!");
	draw_text(hwidth-64, 25, "now playing:");
	draw_text(hwidth-64, 40, string_delete(string(track_list[track_position]), 1, 10 ));
	draw_healthbar(hwidth-96,55, hwidth-30, 60, songPercent, c_black, c_fuchsia, c_fuchsia, 0, true, true)
	draw_sprite_ext(Play, image_number, hwidth-25, 140,1,1,0,c_white,1)
	draw_sprite_ext(Play, image_number, hwidth-96, 142,1,1,180,c_white,1)
	draw_sprite_ext(Stop, image_number, hwidth-62, 140,1,1,0,c_white,1)
	if(paused == true){
		draw_text(hwidth-64, 70, "PAUSED");	
	}
}