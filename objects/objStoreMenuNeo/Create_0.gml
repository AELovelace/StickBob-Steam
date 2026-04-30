action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 38;
action_card_gap = 10;

store_categories = unlockables_get_store_categories();
store_items = [];
button = [];
button_desc = [];
menu_layer = "categories";
category_index = 0;
item_index = 0;
menu_index = 0;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);

function store_menu_set_category_layer() {
	menu_layer = "categories";
	button = [];
	button_desc = [];
	for (var _i = 0; _i < array_length(store_categories); _i++) {
		button[_i] = store_categories[_i].label;
		button_desc[_i] = store_categories[_i].description;
	}
	buttons = array_length_1d(button);
	menu_index = clamp(category_index, 0, max(0, buttons - 1));
}

function store_menu_open_category(_category_idx) {
	category_index = clamp(_category_idx, 0, max(0, array_length(store_categories) - 1));
	menu_layer = "items";
	store_items = unlockables_get_items_for_category(store_categories[category_index].id);
	button = [];
	button_desc = [];
	for (var _i = 0; _i < array_length(store_items); _i++) {
		button[_i] = store_items[_i].label;
		button_desc[_i] = store_items[_i].description;
	}
	buttons = array_length_1d(button);
	item_index = clamp(item_index, 0, max(0, buttons - 1));
	menu_index = item_index;
}

store_menu_set_category_layer();

sgc_gateway_bootstrap(false);
if (global.sgc_gateway.ready && global.sgc_gateway.linked) {
	sgc_gateway_check_balance();
}
