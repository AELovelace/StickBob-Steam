var _selected_category = store_categories[category_index];
var _has_items = (menu_layer == "items") && (array_length(store_items) > 0);
var _item = _has_items ? store_items[menu_index] : undefined;
var _owned = _has_items ? unlockables_is_unlocked(_item.id) : false;
var _feedback = unlockables_purchase_feedback();
var _c = menu_neo_palette();
var _gui_w = display_get_gui_width();
var _status_text = global.sgc_gateway.ready ? (global.sgc_gateway.linked ? "LINKED" : "NOT LINKED") : "CONNECTING";
var _purchase_color = _c.ice;

switch (_feedback.purchase_state) {
	case "success":
		_purchase_color = make_color_rgb(40, 200, 42);
		break;
	case "failed":
		_purchase_color = _c.accent;
		break;
	case "pending":
		_purchase_color = _c.ice;
		break;
}

menu_neo_draw_shell(
	"NOTICE BOARD // UNLOCK STORE",
	">LINKS/RES :: SGC PURCHASE TERMINAL",
	menu_layer == "categories"
		? "W/S OR MOUSE: SELECT   ENTER: OPEN CATEGORY   R: REFRESH BALANCE   ESC: BACK"
		: "W/S OR MOUSE: SELECT   ENTER: BUY   R: REFRESH BALANCE   ESC: CATEGORIES"
);
menu_neo_draw_left_panel(button, menu_index, action_card_x, action_card_y, action_card_w, action_card_h, action_card_gap);
menu_neo_draw_info_panel(
	menu_layer == "categories" ? store_categories[menu_index].label : _item.label,
	menu_layer == "categories"
		? [
			button_desc[menu_index],
			"Select a category first, then browse the unlocks inside it."
		]
		: [
			button_desc[menu_index],
			_owned ? "Owned and ready to use." : "Spend SadGirlCoin to unlock this item permanently on this machine."
		],
	[
		{ label : "CATEGORY", value : _selected_category.label, color : _c.accent },
		{ label : "PRICE", value : _has_items ? string(_item.price) + " SGC" : "--", color : _c.accent },
		{ label : "OWNERSHIP", value : _has_items ? (_owned ? "OWNED" : "LOCKED") : "--", color : _owned ? make_color_rgb(40, 200, 42) : _c.paper },
		{ label : "SGC STATUS", value : _status_text, color : global.sgc_gateway.linked ? make_color_rgb(40, 200, 42) : _c.paper },
		{ label : "BALANCE", value : sgc_gateway_balance_text(), color : global.sgc_gateway.linked ? _c.ice : _c.paper },
	]
);

draw_set_font(fontMenuSmall);
draw_set_color(_c.paper);
draw_text(352, 392, "PURCHASE STATUS");

draw_set_color(_c.bg_light);
draw_rectangle(352, 420, _gui_w - 54, 470, false);
draw_set_color(_purchase_color);
draw_text(366, 436, string_length(_feedback.purchase_message) > 0 ? _feedback.purchase_message : "Select an item to purchase.");

draw_set_color(_c.paper);
draw_text(352, 500, "DETAILS");
draw_set_color(_c.ice);
if (menu_layer == "categories") {
	draw_text(366, 528, "Choose a category to drill into the items inside it.");
} else {
	draw_text(366, 528, _item.category == "weapon" ? "Weapon unlock applies to slot 2 in gameplay." : "Playlist unlock updates the menu radio immediately.");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
