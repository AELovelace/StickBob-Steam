sgc_gateway_state_init();
var _ui = steam_leaderboards_ui_state();
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _c = menu_neo_palette();
var _accent = _c.accent;
var _accent_dim = _c.accent_dim;
var _accentGreen = make_color_rgb(40, 200, 42);
var _ice = _c.ice;
var _paper = _c.paper;
var _bg_dark = _c.bg_dark;
var _bg_mid = _c.bg_mid;

draw_set_alpha(0.94);
draw_set_color(c_black);
draw_rectangle(0, 0, _gui_w, _gui_h, false);
draw_set_alpha(1);

draw_set_color(_accent_dim);
for (var _line = 0; _line < 16; _line++) {
	var _y = 58 + _line * 26;
	draw_line(0, _y, _gui_w, _y);
}

draw_set_font(fontMenu);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
menu_neo_draw_glow_text(30, 18, "SADGIRLSCLUB.WTF", _paper, _c.phosphor);
menu_neo_draw_glow_text(30, 48, "NOTICE BOARD // STICKBOB MAIN TERMINAL", _accent, _c.phosphor);

draw_set_font(fontMenuMed);
menu_neo_draw_glow_text(32, 78, ">LINKS/RES :: DOLLOS V-3.01", _ice, _c.phosphor);
menu_neo_draw_glow_text(32, _gui_h - 36, "W/S OR MOUSE: SELECT   ENTER: OPEN   ESC: EXIT", _paper, _c.phosphor);

draw_set_color(_bg_mid);
draw_rectangle(22, 116, 300, _gui_h - 52, false);
draw_set_alpha(0.08);
draw_set_color(_c.phosphor);
draw_rectangle(18, 112, 304, _gui_h - 48, false);
draw_set_alpha(1);
draw_set_color(_accent);
draw_rectangle(22, 116, 300, _gui_h - 52, true);

draw_set_font(fontMenuSmall);
for (var _i = 0; _i < buttons; _i++) {
	var _selected = (_i == menu_index);
	var _top = action_card_y + _i * (action_card_h + action_card_gap);
	draw_set_color(_selected ? _accent : _paper);
	if (_selected) {
		draw_rectangle(action_card_x, _top, action_card_x + action_card_w, _top + action_card_h, false);
		menu_neo_draw_glow_text(action_card_x + 10, _top + 8, ">" + button[_i], c_black, _paper);
	} else {
		menu_neo_draw_glow_text(action_card_x + 10, _top + 8, button[_i], _paper, _c.phosphor);
	}
}

draw_set_color(_bg_dark);
draw_rectangle(318, 116, _gui_w - 22, _gui_h - 52, false);
draw_set_alpha(0.08);
draw_set_color(_c.phosphor);
draw_rectangle(314, 112, _gui_w - 18, _gui_h - 48, false);
draw_set_alpha(1);
draw_set_color(_accent);
draw_rectangle(318, 116, _gui_w - 22, _gui_h - 52, true);

draw_set_font(fontMenu);
menu_neo_draw_glow_text(338, 138, button[menu_index], _paper, _c.phosphor);

draw_set_font(fontMenuSmall);
menu_neo_draw_glow_text(340, 172, button_desc[menu_index], _ice, _c.phosphor);

var _status = "CONNECTING";
if (global.sgc_gateway.ready) {
	_status = global.sgc_gateway.linked ? "LINKED" : "NOT LINKED";
}

draw_set_color(_accent_dim);
draw_rectangle(338, 224, _gui_w - 42, 348, false);
menu_neo_draw_glow_text(352, 238, "SGC STATUS", _paper, _c.phosphor);
draw_set_halign(fa_right);
menu_neo_draw_glow_text(_gui_w - 54, 238, _status, global.sgc_gateway.linked ? _accent : _paper, _c.phosphor);
draw_set_halign(fa_left);
menu_neo_draw_glow_text(352, 268, "BALANCE", _paper, _c.phosphor);
draw_set_halign(fa_right);
menu_neo_draw_glow_text(_gui_w - 54, 268, sgc_gateway_balance_text(), global.sgc_gateway.linked ? _accentGreen : _paper, _c.phosphor);
draw_set_halign(fa_left);
menu_neo_draw_glow_text(352, 298, "STEAM", _paper, _c.phosphor);
draw_set_halign(fa_right);
menu_neo_draw_glow_text(_gui_w - 54, 298, steam_initialised() ? "ONLINE" : "OFFLINE", steam_initialised() ? _ice : _paper, _c.phosphor);
draw_set_halign(fa_left);
menu_neo_draw_glow_text(352, 328, "LEADERBOARD FEED", _paper, _c.phosphor);
draw_set_halign(fa_right);
menu_neo_draw_glow_text(_gui_w - 54, 328, _ui.status_text, _ice, _c.phosphor);
draw_set_halign(fa_left);

draw_set_color(_accent_dim);
draw_rectangle(338, 372, _gui_w - 42, _gui_h - 74, false);
menu_neo_draw_glow_text(352, 386, "LIVE BOARDS", _paper, _c.phosphor);

for (var _b = 0; _b < array_length(_ui.boards); _b++) {
	var _row_y = 418 + _b * 34;
	var _active = (_b == _ui.board_index);
	menu_neo_draw_glow_text(352, _row_y, _ui.boards[_b].label, _active ? _accent : ((_b mod 2 == 0) ? _paper : _ice), _c.phosphor);
	if (_active) {
		draw_set_halign(fa_right);
		menu_neo_draw_glow_text(_gui_w - 54, _row_y, steam_leaderboards_ui_scope().label, _paper, _c.phosphor);
		draw_set_halign(fa_left);
	}
}

menu_neo_draw_flicker_overlay();

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
