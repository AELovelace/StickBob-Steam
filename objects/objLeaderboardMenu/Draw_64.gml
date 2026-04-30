var _ui = steam_leaderboards_ui_state();
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _accent = make_color_rgb(235, 48, 87);
var _accent_dim = make_color_rgb(120, 25, 42);
var _ice = make_color_rgb(170, 235, 255);
var _paper = make_color_rgb(220, 220, 220);
var _ink = make_color_rgb(10, 10, 10);

draw_set_alpha(0.88);
draw_set_color(c_black);
draw_rectangle(0, 0, _gui_w, _gui_h, false);
draw_set_alpha(1);

draw_set_color(_accent_dim);
for (var _line = 0; _line < 14; _line++) {
	var _y = 54 + _line * 28;
	draw_line(0, _y, _gui_w, _y);
}

draw_set_font(fontMenu);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(_paper);
draw_text(32, 18, "SADGIRLSCLUB.WTF");
draw_set_color(_accent);
draw_text(32, 48, "NOTICE BOARD // LEADER RANKINGS");

draw_set_font(fontMenuSmall);
draw_set_color(_ice);
draw_text(34, 78, ">LINKS/RES :: STEAM UPLINK ACTIVE");
draw_set_color(_paper);
draw_text(34, _gui_h - 42, "ESC: BACK   TAB: SCOPE   LEFT/RIGHT: BOARD   R: REFRESH");

draw_set_color(make_color_rgb(18, 18, 18));
draw_rectangle(24, 118, 268, _gui_h - 58, false);
draw_set_color(_accent);
draw_rectangle(24, 118, 268, _gui_h - 58, true);

draw_set_font(fontMenuSmall);
for (var _i = 0; _i < array_length(_ui.boards); _i++) {
	var _selected = (_ui.board_index == _i);
	var _top = 128 + _i * 42;
	draw_set_color(_selected ? _accent : _paper);
	if (_selected) {
		draw_rectangle(34, _top - 2, 258, _top + 30, false);
		draw_set_color(c_black);
		draw_text(44, _top + 4, ">" + _ui.boards[_i].label);
	} else {
		draw_text(44, _top + 4, _ui.boards[_i].label);
	}
}

draw_set_color(make_color_rgb(14, 14, 14));
draw_rectangle(286, 86, _gui_w - 24, _gui_h - 58, false);
draw_set_color(_accent);
draw_rectangle(286, 86, _gui_w - 24, _gui_h - 58, true);

for (var _j = 0; _j < array_length(_ui.scopes); _j++) {
	var _left = 300 + _j * 142;
	var _active = (_ui.scope_index == _j);
	draw_set_color(_active ? _accent : make_color_rgb(36, 36, 36));
	draw_rectangle(_left, 96, _left + 130, 124, false);
	draw_set_color(_active ? c_black : _paper);
	draw_text(_left + 10, 102, _ui.scopes[_j].label);
}

var _board = steam_leaderboards_ui_board();
draw_set_font(fontMenu);
draw_set_color(_paper);
draw_text(302, 136, _board.label);
draw_set_font(fontMenuSmall);
draw_set_color(_ice);
draw_text(304, 166, "DollOS V-3.0 // community uplink");

draw_set_color(_ui.loading ? _accent : _paper);
draw_text(304, 196, "STATUS: " + _ui.status_text);
if (string_length(_ui.error_text) > 0) {
	draw_set_color(_accent);
	draw_text(304, 216, "ERROR: " + _ui.error_text);
}

var _list_top = 248;
var _row_h = 38;
var _name_x = 356;
var _value_x = _gui_w - 54;
draw_set_color(_accent_dim);
draw_rectangle(300, _list_top - 8, _gui_w - 36, _list_top + 24, false);
draw_set_color(_paper);
draw_text(314, _list_top, "RANK");
draw_text(_name_x, _list_top, "NAME");
draw_set_halign(fa_right);
draw_text(_value_x, _list_top, "VALUE");
draw_set_halign(fa_left);

for (var _row = 0; _row < max(10, array_length(_ui.entries)); _row++) {
	var _y = _list_top + 34 + _row * _row_h;
	var _filled = _row < array_length(_ui.entries);
	var _selected_row = (_ui.selected_row == _row);
	var _entry_bg = _selected_row ? make_color_rgb(52, 9, 20) : ((_row mod 2 == 0) ? make_color_rgb(22, 22, 22) : make_color_rgb(15, 15, 15));
	draw_set_color(_entry_bg);
	draw_rectangle(300, _y - 2, _gui_w - 36, _y + 28, false);

	if (_filled) {
		var _entry = _ui.entries[_row];
		draw_set_color(_selected_row ? _ice : _paper);
		draw_text(314, _y + 4, string(_entry.rank));
		draw_text(_name_x, _y + 4, _entry.name);
		draw_set_halign(fa_right);
		draw_text(_value_x, _y + 4, _entry.value_text);
		draw_set_halign(fa_left);
	} else {
		draw_set_color(make_color_rgb(85, 85, 85));
		draw_text(314, _y + 4, "--");
	}
}

draw_set_color(_accent);
draw_rectangle(_gui_w - 178, _gui_h - 46, _gui_w - 22, _gui_h - 18, true);
draw_set_color(c_black);
draw_text(_gui_w - 164, _gui_h - 40, "REFRESH FEED");

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
