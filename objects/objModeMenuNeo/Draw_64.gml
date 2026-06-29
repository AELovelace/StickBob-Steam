var _mode_text = "CLASSIC";
if (global.gameParams.modeSelection == global.GAME_MODE_HP5) _mode_text = "5 HP";
if (global.gameParams.practiceMode && global.gameParams.modeSelection == global.GAME_MODE_CLASSIC) _mode_text = "PRACTICE";
if (global.gameParams.practiceMode && global.gameParams.modeSelection == global.GAME_MODE_HP5) _mode_text = "PRACTICE 5HP";
menu_neo_draw_shell(
	"NOTICE BOARD // MODE SELECTION",
	">LINKS/RES :: COMBAT RULESET ROUTER",
	"W/S OR MOUSE: SELECT   ENTER: CONFIRM   ESC: BACK"
);
menu_neo_draw_left_panel(button, menu_index, action_card_x, action_card_y, action_card_w, action_card_h, action_card_gap);
menu_neo_draw_info_panel(
	button[menu_index],
	[
		button_desc[menu_index],
		"Practice mode changes the hosting path before map launch.",
	],
	[
		{ label : "PLAYERS", value : string(global.gameParams.numberPlayers), color : menu_neo_palette().accent },
		{ label : "CURRENT MODE", value : _mode_text, color : menu_neo_palette().ice },
	]
);
