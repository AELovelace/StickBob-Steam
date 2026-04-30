var _selected_option = resolution_options[selected_resolution];
var _preview_color = make_color_rgb(sliderR, sliderG, sliderB);
var _c = menu_neo_palette();

menu_neo_draw_shell(
	"NOTICE BOARD // SETTINGS TERMINAL",
	">LINKS/RES :: DISPLAY + COLOR CALIBRATION",
	"W/S: SELECT   A/D: ADJUST   ENTER: TOGGLE/APPLY   ESC: BACK"
);
menu_neo_draw_left_panel(button, menu_index, action_card_x, action_card_y, action_card_w, action_card_h, action_card_gap);
menu_neo_draw_info_panel(
	button[menu_index],
	[
		button_desc[menu_index],
		"Player color preview and output settings stay inside the neo flow.",
	],
	[
		{ label : "RESOLUTION", value : _selected_option.label, color : _c.accent },
		{ label : "FULLSCREEN", value : string(fullscreen_value), color : _c.ice },
	]
);

draw_set_font(fontMenuSmall);
draw_set_color(_c.paper);
draw_text(352, 392, "PLAYER COLOR");

var _labels = ["R", "G", "B"];
var _vals = [sliderR, sliderG, sliderB];
var _cols = [make_color_rgb(200, 40, 40), make_color_rgb(40, 180, 40), make_color_rgb(40, 80, 220)];
var _row_y = [426, 470, 514];

for (var _i = 0; _i < 3; _i++) {
	var _sy = _row_y[_i];
	var _t = _vals[_i] / 255;
	draw_set_color(_c.bg_light);
	draw_rectangle(colorPickerX, _sy - colorPickerH, colorPickerX + colorPickerW, _sy + colorPickerH, false);
	draw_set_color(_cols[_i]);
	draw_rectangle(colorPickerX, _sy - colorPickerH, colorPickerX + colorPickerW * _t, _sy + colorPickerH, false);
	draw_set_color(c_white);
	draw_circle(colorPickerX + colorPickerW * _t, _sy, colorPickerH + 3, false);
	draw_set_color(_c.paper);
	draw_set_halign(fa_right);
	draw_text(colorPickerX - 10, _sy - 8, _labels[_i]);
	draw_set_halign(fa_left);
	draw_text(colorPickerX + colorPickerW + 10, _sy - 8, string(_vals[_i]));
}

draw_set_color(_c.paper);
draw_text(352, 548, "PREVIEW");
draw_set_color(c_white);
draw_rectangle(388, 574, 648, 610, true);
draw_set_color(_preview_color);
draw_rectangle(390, 576, 646, 608, false);

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
