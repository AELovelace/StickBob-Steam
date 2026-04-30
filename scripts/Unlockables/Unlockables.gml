function unlockables_catalog() {
	return [
		{
			id : "weapon.machinegun",
			category : "weapon",
			key : "machinegun",
			label : "MACHINEGUN",
			price : 1000,
			default_unlocked : false,
			description : "Slot 2 weapon. Same rounds, same aim, faster fire rate."
		},
		{
			id : "playlist.ang3lware",
			category : "playlist",
			key : "ang3lware",
			label : "ANG3LWARE",
			price : 0,
			default_unlocked : true,
			description : "Default broadcast playlist. Starts unlocked."
		},
		{
			id : "playlist.phosphorrgirl",
			category : "playlist",
			key : "phosphorrgirl",
			label : "PHOSPHORRGIRL",
			price : 500,
			default_unlocked : false,
			description : "Unlock an extra playlist for the menu MP3 player."
		},
		{
			id : "playlist.gloomstone",
			category : "playlist",
			key : "gloomstone",
			label : "GLOOMSTONE",
			price : 500,
			default_unlocked : false,
			description : "Unlock an extra playlist for the menu MP3 player."
		}
	];
}

function unlockables_default_state() {
	return {
		weapons : {
			machinegun : false,
		},
		playlists : {
			ang3lware : true,
			phosphorrgirl : false,
			gloomstone : false,
		}
	};
}

function unlockables_state_init() {
	if (variable_global_exists("unlockables_runtime")) return;
	global.unlockables_runtime = {
		purchase_state : "idle",
		purchase_message : "",
		purchase_item_id : "",
		mp3_refresh_pending : false,
	};
}

function unlockables_bucket_name(_category) {
	switch (string(_category)) {
		case "weapon": return "weapons";
		case "playlist": return "playlists";
	}
	return "";
}

function unlockables_default_weapons_bucket() {
	return {
		machinegun : false,
	};
}

function unlockables_default_playlists_bucket() {
	return {
		ang3lware : true,
		phosphorrgirl : false,
		gloomstone : false,
	};
}

function unlockables_normalize_state(_value) {
	var _state = {
		weapons : unlockables_default_weapons_bucket(),
		playlists : unlockables_default_playlists_bucket(),
	};

	if (is_struct(_value)) {
		if (variable_struct_exists(_value, "weapons")) {
			var _weapons = variable_struct_get(_value, "weapons");
			if (is_struct(_weapons) && variable_struct_exists(_weapons, "machinegun")) {
				_state.weapons.machinegun = (_weapons.machinegun == true);
			}
		}

		if (variable_struct_exists(_value, "playlists")) {
			var _playlists = variable_struct_get(_value, "playlists");
			if (is_struct(_playlists)) {
				if (variable_struct_exists(_playlists, "ang3lware")) {
					_state.playlists.ang3lware = (_playlists.ang3lware == true);
				}
				if (variable_struct_exists(_playlists, "phosphorrgirl")) {
					_state.playlists.phosphorrgirl = (_playlists.phosphorrgirl == true);
				}
				if (variable_struct_exists(_playlists, "gloomstone")) {
					_state.playlists.gloomstone = (_playlists.gloomstone == true);
				}
			}
		}
	}

	_state.playlists.ang3lware = true;
	return _state;
}

function unlockables_item_by_id(_item_id) {
	var _catalog = unlockables_catalog();
	for (var _i = 0; _i < array_length(_catalog); _i++) {
		if (_catalog[_i].id == _item_id) return _catalog[_i];
	}
	return undefined;
}

function unlockables_state() {
	unlockables_state_init();
	var _settings = app_settings_current();
	if (!variable_struct_exists(_settings, "unlockables")) {
		_settings.unlockables = unlockables_default_state();
		variable_global_set("appSettings", _settings);
		app_settings_save(_settings);
	}
	_settings.unlockables = unlockables_normalize_state(_settings.unlockables);
	return _settings.unlockables;
}

function unlockables_save_state(_state) {
	unlockables_state_init();
	var _settings = app_settings_current();
	_settings.unlockables = unlockables_normalize_state(_state);
	variable_global_set("appSettings", _settings);
	app_settings_save(_settings);
}

function unlockables_set_purchase_feedback(_state, _message, _item_id) {
	unlockables_state_init();
	global.unlockables_runtime.purchase_state = string(_state);
	global.unlockables_runtime.purchase_message = string(_message);
	global.unlockables_runtime.purchase_item_id = string(_item_id);
}

function unlockables_purchase_feedback() {
	unlockables_state_init();
	return global.unlockables_runtime;
}

function unlockables_is_unlocked(_item_id) {
	var _item = unlockables_item_by_id(_item_id);
	if (!is_struct(_item)) return false;
	var _bucket_name = unlockables_bucket_name(_item.category);
	if (string_length(_bucket_name) <= 0) return false;

	var _state = unlockables_state();
	if (!variable_struct_exists(_state, _bucket_name)) return (_item.default_unlocked == true);
	var _bucket = variable_struct_get(_state, _bucket_name);
	if (!variable_struct_exists(_bucket, _item.key)) return (_item.default_unlocked == true);
	return (variable_struct_get(_bucket, _item.key) == true);
}

function unlockables_mark_owned(_item_id) {
	var _item = unlockables_item_by_id(_item_id);
	if (!is_struct(_item)) return false;
	var _bucket_name = unlockables_bucket_name(_item.category);
	if (string_length(_bucket_name) <= 0) return false;

	var _state = unlockables_state();
	if (!variable_struct_exists(_state, _bucket_name)) {
		variable_struct_set(_state, _bucket_name, {});
	}
	var _bucket = variable_struct_get(_state, _bucket_name);
	variable_struct_set(_bucket, _item.key, true);
	unlockables_save_state(_state);
	unlockables_refresh_runtime();
	return true;
}

function unlockables_get_price(_item_id) {
	var _item = unlockables_item_by_id(_item_id);
	if (!is_struct(_item)) return -1;
	return max(0, floor(real(_item.price)));
}

function unlockables_get_store_items() {
	return unlockables_catalog();
}

function unlockables_get_store_categories() {
	return [
		{ id : "weapon", label : "WEAPONS", description : "Combat unlocks for gameplay loadouts." },
		{ id : "playlist", label : "PLAYLISTS", description : "Music packs for the menu MP3 player." },
	];
}

function unlockables_get_items_for_category(_category_id) {
	var _items = [];
	var _catalog = unlockables_catalog();
	for (var _i = 0; _i < array_length(_catalog); _i++) {
		if (_catalog[_i].category == _category_id) array_push(_items, _catalog[_i]);
	}
	return _items;
}

function unlockables_get_weapon_entries() {
	return unlockables_get_items_for_category("weapon");
}

function unlockables_get_playlist_entries() {
	return unlockables_get_items_for_category("playlist");
}

function unlockables_refresh_runtime() {
	unlockables_state_init();
	global.unlockables_runtime.mp3_refresh_pending = true;
}

function unlockables_complete_purchase_success(_item_id, _balance_after) {
	var _item = unlockables_item_by_id(_item_id);
	if (!is_struct(_item)) {
		unlockables_set_purchase_feedback("failed", "Unknown item.", _item_id);
		return false;
	}
	unlockables_mark_owned(_item_id);
	if (_balance_after != undefined) {
		sgc_gateway_apply_balance_sync(real(_balance_after));
	} else if (global.sgc_gateway.ready && global.sgc_gateway.linked) {
		sgc_gateway_check_balance();
	}
	unlockables_set_purchase_feedback("success", _item.label + " unlocked.", _item_id);
	return true;
}

function unlockables_complete_purchase_failure(_item_id, _reason) {
	unlockables_set_purchase_feedback("failed", _reason, _item_id);
}

function unlockables_purchase(_item_id) {
	var _item = unlockables_item_by_id(_item_id);
	if (!is_struct(_item)) {
		unlockables_set_purchase_feedback("failed", "Store item missing.", _item_id);
		return false;
	}
	if (unlockables_is_unlocked(_item_id)) {
		unlockables_set_purchase_feedback("failed", _item.label + " is already owned.", _item_id);
		return false;
	}

	var _price = unlockables_get_price(_item_id);
	var _result = sgc_gateway_purchase_unlockable(_item_id, _price, "unlock " + _item.label);
	if (!_result.ok) {
		unlockables_set_purchase_feedback("failed", _result.message, _item_id);
		return false;
	}

	unlockables_set_purchase_feedback("pending", "Purchasing " + _item.label + "...", _item_id);
	return true;
}
