/// @description Shared styling helpers for the neo menu flow.

function menu_neo_palette() {
	return {
		accent     : make_color_rgb(235, 48, 87),
		accent_dim : make_color_rgb(120, 25, 42),
		ice        : make_color_rgb(170, 235, 255),
		phosphor   : make_color_rgb(130, 255, 210),
		paper      : make_color_rgb(220, 220, 220),
		bg_dark    : make_color_rgb(14, 14, 14),
		bg_mid     : make_color_rgb(24, 24, 24),
		bg_light   : make_color_rgb(36, 36, 36),
	};
}

function menu_neo_flicker() {
	return 0.92 + random(0.08);
}

function menu_neo_draw_glow_text(_x, _y, _text, _main_color, _glow_color) {
	var _flicker = menu_neo_flicker();
	draw_set_alpha(0.12 * _flicker);
	draw_set_color(_glow_color);
	draw_text(_x - 1, _y, _text);
	draw_text(_x + 1, _y, _text);
	draw_text(_x, _y - 1, _text);
	draw_text(_x, _y + 1, _text);
	draw_set_alpha(0.05 * _flicker);
	draw_text(_x - 3, _y, _text);
	draw_text(_x + 3, _y, _text);
	draw_set_alpha(_flicker);
	draw_set_color(_main_color);
	draw_text(_x, _y, _text);
	draw_set_alpha(1);
}

function menu_neo_draw_flicker_overlay() {
	var _gui_w = display_get_gui_width();
	var _gui_h = display_get_gui_height();
	var _drift = current_time * 0.004;
	var _c = menu_neo_palette();

	draw_set_alpha(0.025 + random(0.02));
	draw_set_color(_c.phosphor);
	for (var _i = 0; _i < 5; _i++) {
		var _y = frac(_drift + _i * 0.19) * _gui_h;
		draw_rectangle(0, _y, _gui_w, _y + 2, false);
	}

	draw_set_alpha(0.035);
	draw_set_color(make_color_rgb(255, 255, 255));
	for (var _line = 0; _line < _gui_h; _line += 4) {
		draw_line(0, _line, _gui_w, _line);
	}

	if (irandom(14) == 0) {
		draw_set_alpha(0.035);
		draw_set_color(_c.paper);
		draw_rectangle(0, 0, _gui_w, _gui_h, false);
	}
	draw_set_alpha(1);
}

function menu_neo_draw_shell(_title, _subtitle, _footer) {
	var _c = menu_neo_palette();
	var _gui_w = display_get_gui_width();
	var _gui_h = display_get_gui_height();

	draw_set_alpha(0.94);
	draw_set_color(c_black);
	draw_rectangle(0, 0, _gui_w, _gui_h, false);
	draw_set_alpha(1);

	draw_set_color(_c.accent_dim);
	for (var _line = 0; _line < 16; _line++) {
		var _y = 58 + _line * 26;
		draw_line(0, _y, _gui_w, _y);
	}

	draw_set_font(fontMenu);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	menu_neo_draw_glow_text(30, 18, "SADGIRLSCLUB.WTF", _c.paper, _c.phosphor);
	menu_neo_draw_glow_text(30, 48, _title, _c.accent, _c.phosphor);

	draw_set_font(fontMenuSmall);
	menu_neo_draw_glow_text(32, 78, _subtitle, _c.ice, _c.phosphor);
	menu_neo_draw_glow_text(32, _gui_h - 36, _footer, _c.paper, _c.phosphor);
	menu_neo_draw_flicker_overlay();
}

function menu_neo_draw_left_panel(_buttons, _menu_index, _x, _y, _w, _h, _gap) {
	var _c = menu_neo_palette();
	var _gui_h = display_get_gui_height();

	draw_set_color(_c.bg_mid);
	draw_rectangle(22, 116, 300, _gui_h - 52, false);
	draw_set_alpha(0.08);
	draw_set_color(_c.phosphor);
	draw_rectangle(18, 112, 304, _gui_h - 48, false);
	draw_set_alpha(1);
	draw_set_color(_c.accent);
	draw_rectangle(22, 116, 300, _gui_h - 52, true);

	draw_set_font(fontMenuSmall);
	for (var _i = 0; _i < array_length(_buttons); _i++) {
		var _selected = (_i == _menu_index);
		var _top = _y + _i * (_h + _gap);
		draw_set_color(_selected ? _c.accent : _c.paper);
		if (_selected) {
			draw_rectangle(_x, _top, _x + _w, _top + _h, false);
			menu_neo_draw_glow_text(_x + 10, _top + 8, ">" + _buttons[_i], c_black, _c.paper);
		} else {
			menu_neo_draw_glow_text(_x + 10, _top + 8, _buttons[_i], _c.paper, _c.phosphor);
		}
	}
}

function menu_neo_draw_info_panel(_header, _body_lines, _status_lines) {
	var _c = menu_neo_palette();
	var _gui_w = display_get_gui_width();

	draw_set_color(_c.bg_dark);
	draw_rectangle(318, 116, _gui_w - 22, display_get_gui_height() - 52, false);
	draw_set_alpha(0.08);
	draw_set_color(_c.phosphor);
	draw_rectangle(314, 112, _gui_w - 18, display_get_gui_height() - 48, false);
	draw_set_alpha(1);
	draw_set_color(_c.accent);
	draw_rectangle(318, 116, _gui_w - 22, display_get_gui_height() - 52, true);

	draw_set_font(fontMenu);
	menu_neo_draw_glow_text(338, 138, _header, _c.paper, _c.phosphor);

	draw_set_font(fontMenuSmall);
	for (var _i = 0; _i < array_length(_body_lines); _i++) {
		menu_neo_draw_glow_text(340, 172 + _i * 22, _body_lines[_i], _c.ice, _c.phosphor);
	}

	draw_set_color(_c.accent_dim);
	draw_rectangle(338, 246, _gui_w - 42, 364, false);
	menu_neo_draw_glow_text(352, 260, "STATUS", _c.paper, _c.phosphor);

	for (var _j = 0; _j < array_length(_status_lines); _j++) {
		var _line = _status_lines[_j];
		var _y = 290 + _j * 28;
		menu_neo_draw_glow_text(352, _y, _line.label, _c.paper, _c.phosphor);
		draw_set_halign(fa_right);
		menu_neo_draw_glow_text(
			_gui_w - 54,
			_y,
			_line.value,
			variable_struct_exists(_line, "color") ? _line.color : _c.ice,
			_c.phosphor
		);
		draw_set_halign(fa_left);
	}
}
