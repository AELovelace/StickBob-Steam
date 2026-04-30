var _mode_name = (global.gameParams.modeSelection == global.GAME_MODE_HP5) ? "5 HP" : "CLASSIC";
if (global.gameParams.practiceMode) _mode_name = "PRACTICE";
menu_neo_draw_shell(
	"NOTICE BOARD // MAP UPLINK",
	">LINKS/RES :: LOBBY DESTINATION MATRIX",
	"W/S OR MOUSE: SELECT   ENTER: LAUNCH   ESC: BACK"
);
menu_neo_draw_left_panel(button, menu_index, action_card_x, action_card_y, action_card_w, action_card_h, action_card_gap);
menu_neo_draw_info_panel(
	button[menu_index],
	[
		button_desc[menu_index],
		"Practice launches directly; standard mode creates the Steam lobby first.",
	],
	[
		{ label : "PLAYERS", value : string(global.gameParams.numberPlayers), color : menu_neo_palette().accent },
		{ label : "MODE", value : _mode_name, color : menu_neo_palette().ice },
	]
);
