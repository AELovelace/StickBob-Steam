menu_neo_draw_shell(
	"NOTICE BOARD // HOST LOBBY CAPACITY",
	">LINKS/RES :: PLAYER SLOT ALLOCATION",
	"W/S OR MOUSE: SELECT   ENTER: CONFIRM   ESC: BACK"
);
menu_neo_draw_left_panel(button, menu_index, action_card_x, action_card_y, action_card_w, action_card_h, action_card_gap);
menu_neo_draw_info_panel(
	button[menu_index],
	[
		button_desc[menu_index],
		"CURRENT COUNT WILL BE WRITTEN TO global.gameParams.numberPlayers.",
	],
	[
		{ label : "CURRENT VALUE", value : string(global.gameParams.numberPlayers), color : menu_neo_palette().accent },
		{ label : "NEXT SCREEN", value : "MODE SELECT", color : menu_neo_palette().ice },
	]
);
