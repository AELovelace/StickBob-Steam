draw_set_font(fontMenuSmall)
draw_set_color(c_white)

draw_set_halign(fa_center);
draw_set_valign(fa_top);
if(mp3Open == true){
	hwidth = display_get_gui_width()
	draw_sprite_ext(sprMP3Open, image_number, hwidth-128,0,2,1.5,0,c_white,1)
	draw_sprite_ext(spr_Button, image_number, hwidth-63,55,1.5,1.5,0,c_white,1)
	draw_text(hwidth-64, 10, "SADP3-PLR!");
	draw_text(hwidth-64, 25, "now playing:");
	draw_text(hwidth-64, 40, string(artistName[artistPosition]));
	draw_text(hwidth-64, 60, string_delete(string(track_list[track_position]), 1, 10 ));
	draw_healthbar(hwidth-96,75, hwidth-30, 80, songPercent, c_black, c_fuchsia, c_fuchsia, 0, true, true)
	draw_sprite_ext(artist, image_number, hwidth-62, 105,1,1,0,c_white,1)
	draw_sprite_ext(Play, image_number, hwidth-25, 140,1,1,0,c_white,1)
	draw_sprite_ext(Play, image_number, hwidth-96, 142,1,1,180,c_white,1)
	draw_sprite_ext(Stop, image_number, hwidth-62, 140,1,1,0,c_white,1)
	draw_sprite_ext(artist, image_number, hwidth-62, 173,1,1,180,c_white,1)
	if(paused == true){
		draw_text(hwidth-64, 70, "PAUSED");	
	}
}