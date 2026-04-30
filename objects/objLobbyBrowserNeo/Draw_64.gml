var _c = menu_neo_palette();
var _rows = array_length(lobbies);
var _selected = undefined;
if (_rows > 0 && menu_index >= 0 && menu_index < _rows) {
	_selected = lobbies[menu_index];
}

menu_neo_draw_shell(
	"NOTICE BOARD // OPEN LOBBIES",
	">LINKS/RES :: LIVE STEAM BROWSER",
	"W/S OR MOUSE: SELECT   ENTER: JOIN   R: REFRESH   ESC: BACK"
);

draw_set_color(_c.bg_mid);
draw_rectangle(22, 116, 300, display_get_gui_height() - 52, false);
draw_set_color(_c.accent);
draw_rectangle(22, 116, 300, display_get_gui_height() - 52, true);

draw_set_font(fontMenuSmall);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (_rows <= 0) {
	draw_set_color(_c.paper);
	draw_text(action_card_x + 10, action_card_y + 8, "NO OPEN LOBBIES");
	draw_set_color(_c.ice);
	draw_text(action_card_x + 10, action_card_y + 32, "Press ENTER or R to query again.");
} else {
	for (var _i = 0; _i < _rows; _i++) {
		var _top = action_card_y + _i * (action_card_h + action_card_gap);
		var _entry = lobbies[_i];
		var _active = (_i == menu_index);
		draw_set_color(_active ? _c.accent : _c.paper);
		if (_active) {
			draw_rectangle(action_card_x, _top, action_card_x + action_card_w, _top + action_card_h, false);
			draw_set_color(c_black);
		}

		draw_text(action_card_x + 10, _top + 8, _entry.creator);
		draw_text(action_card_x + 10, _top + 28, _entry.mode_name + " // " + _entry.map_short);

		if (!_active) {
			draw_set_halign(fa_right);
			draw_text(action_card_x + action_card_w - 10, _top + 18, "#" + string(_i + 1));
			draw_set_halign(fa_left);
		}
	}
}

var _title = "NO LOBBY SELECTED";
var _body = [
	"The browser waits for Steam's join callback before switching rooms.",
	"That removes the old instant-jump behavior that made joining feel brittle.",
];

if (is_struct(_selected)) {
	_title = _selected.creator;
	_body = [
		"Map: " + _selected.map_name,
		"Mode: " + _selected.mode_name,
		"Lobby ID: " + string(_selected.lobby_id),
	];
}

menu_neo_draw_info_panel(
	_title,
	_body,
	[
		{ label : "STEAM", value : steam_initialised() ? "ONLINE" : "OFFLINE", color : steam_initialised() ? _c.ice : _c.paper },
		{ label : "QUERY", value : status_text, color : join_pending ? _c.accent : _c.paper },
		{ label : "RESULTS", value : string(_rows), color : _c.accent },
	]
);

draw_set_color(_c.paper);
draw_set_font(fontMenuSmall);
draw_text(352, 392, "JOIN FLOW");
draw_set_color(_c.ice);
draw_text(352, 420, "Steam lobby list -> select host -> wait for lobby_joined -> room_goto");

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
