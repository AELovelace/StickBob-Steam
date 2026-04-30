/// @description Steam leaderboard/stat syncing for kills, time, and SGC worth.

function steam_leaderboards_state_init() {
	if (variable_global_exists("steam_leaderboards")) return;
	global.steam_leaderboards = {
		leaderboards_requested : false,
		stats_loaded           : false,
		last_step_ms           : current_time,
		sp_time_accumulator_ms : 0,
		mp_time_accumulator_ms : 0,
		stat_base : {
			sp_kills_total        : 0,
			mp_kills_total        : 0,
			sp_time_seconds_total : 0,
			mp_time_seconds_total : 0,
		},
		stat_delta : {
			sp_kills_total        : 0,
			mp_kills_total        : 0,
			sp_time_seconds_total : 0,
			mp_time_seconds_total : 0,
		},
		stat_last_written : {
			sp_kills_total        : undefined,
			mp_kills_total        : undefined,
			sp_time_seconds_total : undefined,
			mp_time_seconds_total : undefined,
		},
		leaderboard_last_uploaded : {
			lb_sp_kills    : undefined,
			lb_mp_kills    : undefined,
			lb_sp_time     : undefined,
			lb_mp_time     : undefined,
			lb_sgc_balance : undefined,
		},
		verified_mp_kills_total : undefined,
		sgc_balance_total       : undefined,
		ui : {
			boards : [
				{ label : "SINGLEPLAYER KILLS", board_name : "lb_sp_kills", value_mode : "number" },
				{ label : "MULTIPLAYER KILLS", board_name : "lb_mp_kills", value_mode : "number" },
				{ label : "SINGLEPLAYER TIME", board_name : "lb_sp_time", value_mode : "time" },
				{ label : "MULTIPLAYER TIME", board_name : "lb_mp_time", value_mode : "time" },
				{ label : "SADGIRLCOIN WORTH", board_name : "lb_sgc_balance", value_mode : "coin" },
			],
			scopes : [
				{ label : "GLOBAL", mode : "global" },
				{ label : "AROUND YOU", mode : "around" },
				{ label : "FRIENDS", mode : "friends" },
			],
			board_index : 0,
			scope_index : 0,
			selected_row : 0,
			request_id   : -1,
			loading      : false,
			error_text   : "",
			status_text  : "CONNECTING TO STEAM...",
			entries      : [],
			last_request_signature : "",
		},
	};
}

function steam_leaderboards_is_available() {
	return steam_initialised() && steam_stats_ready();
}

function steam_leaderboards_request_boards() {
	steam_leaderboards_state_init();
	if (global.steam_leaderboards.leaderboards_requested) return;
	if (!steam_leaderboards_is_available()) return;

	global.steam_leaderboards.leaderboards_requested = true;
	steam_create_leaderboard("lb_sp_kills", lb_sort_descending, lb_disp_numeric);
	steam_create_leaderboard("lb_mp_kills", lb_sort_descending, lb_disp_numeric);
	steam_create_leaderboard("lb_sp_time", lb_sort_descending, lb_disp_time_sec);
	steam_create_leaderboard("lb_mp_time", lb_sort_descending, lb_disp_time_sec);
	steam_create_leaderboard("lb_sgc_balance", lb_sort_descending, lb_disp_numeric);
}

function steam_leaderboards_load_stats() {
	steam_leaderboards_state_init();
	if (global.steam_leaderboards.stats_loaded) return;
	if (!steam_leaderboards_is_available()) return;

	var _base = global.steam_leaderboards.stat_base;
	var _last = global.steam_leaderboards.stat_last_written;

	_base.sp_kills_total = steam_get_stat_int("sp_kills_total");
	_base.mp_kills_total = steam_get_stat_int("mp_kills_total");
	_base.sp_time_seconds_total = steam_get_stat_int("sp_time_seconds_total");
	_base.mp_time_seconds_total = steam_get_stat_int("mp_time_seconds_total");

	_last.sp_kills_total = _base.sp_kills_total;
	_last.mp_kills_total = _base.mp_kills_total;
	_last.sp_time_seconds_total = _base.sp_time_seconds_total;
	_last.mp_time_seconds_total = _base.mp_time_seconds_total;

	global.steam_leaderboards.stats_loaded = true;
}

function steam_leaderboards_find_local_singleplayer_player() {
	var _count = instance_number(O_Player);
	for (var _i = 0; _i < _count; _i++) {
		var _player = instance_find(O_Player, _i);
		if (!instance_exists(_player)) continue;
		if (variable_instance_exists(_player, "isLocal") && _player.isLocal) return _player;
	}
	return noone;
}

function steam_leaderboards_find_local_multiplayer_player() {
	var _count = instance_number(obj_Player);
	for (var _i = 0; _i < _count; _i++) {
		var _player = instance_find(obj_Player, _i);
		if (!instance_exists(_player)) continue;
		if (variable_instance_exists(_player, "isLocal") && _player.isLocal) return _player;
	}
	return noone;
}

function steam_leaderboards_active_mode() {
	if (steam_leaderboards_find_local_multiplayer_player() != noone
		&& (instance_exists(obj_Server) || instance_exists(obj_Client))) {
		return "mp";
	}
	if (steam_leaderboards_find_local_singleplayer_player() != noone) return "sp";
	if (steam_leaderboards_find_local_multiplayer_player() != noone
		&& !instance_exists(obj_Server) && !instance_exists(obj_Client)) {
		return "sp";
	}
	return "";
}

function steam_leaderboards_add_singleplayer_kill(_amount) {
	steam_leaderboards_state_init();
	global.steam_leaderboards.stat_delta.sp_kills_total += max(0, floor(_amount));
}

function steam_leaderboards_note_pve_kill(_beneficiary_steam_id) {
	if (string(_beneficiary_steam_id) != string(steam_get_user_steam_id())) return false;
	if (instance_exists(obj_Server) || instance_exists(obj_Client)) return false;
	steam_leaderboards_add_singleplayer_kill(1);
	return true;
}

function steam_leaderboards_set_verified_mp_kills(_total) {
	steam_leaderboards_state_init();
	global.steam_leaderboards.verified_mp_kills_total = max(0, floor(real(_total)));
}

function steam_leaderboards_set_sgc_balance(_total) {
	steam_leaderboards_state_init();
	global.steam_leaderboards.sgc_balance_total = max(0, floor(real(_total)));
}

function steam_leaderboards_stat_total(_stat_name) {
	var _base = variable_struct_get(global.steam_leaderboards.stat_base, _stat_name);
	var _delta = variable_struct_get(global.steam_leaderboards.stat_delta, _stat_name);
	return max(0, floor(_base + _delta));
}

function steam_leaderboards_sync_stat_int(_stat_name, _value) {
	var _last = variable_struct_get(global.steam_leaderboards.stat_last_written, _stat_name);
	if (_last == _value) return;
	steam_set_stat_int(_stat_name, _value);
	variable_struct_set(global.steam_leaderboards.stat_last_written, _stat_name, _value);
}

function steam_leaderboards_sync_board(_board_name, _value) {
	var _last = variable_struct_get(global.steam_leaderboards.leaderboard_last_uploaded, _board_name);
	if (_last == _value) return;
	steam_upload_score_ext(_board_name, _value, true);
	variable_struct_set(global.steam_leaderboards.leaderboard_last_uploaded, _board_name, _value);
}

function steam_leaderboards_update_playtime() {
	steam_leaderboards_state_init();
	var _now = current_time;
	var _dt = _now - global.steam_leaderboards.last_step_ms;
	global.steam_leaderboards.last_step_ms = _now;
	_dt = clamp(_dt, 0, 1000);

	if (variable_global_exists("isPaused") && global.isPaused) return;

	var _mode = steam_leaderboards_active_mode();
	if (_mode == "sp") {
		global.steam_leaderboards.sp_time_accumulator_ms += _dt;
		while (global.steam_leaderboards.sp_time_accumulator_ms >= 1000) {
			global.steam_leaderboards.sp_time_accumulator_ms -= 1000;
			global.steam_leaderboards.stat_delta.sp_time_seconds_total += 1;
		}
	} else if (_mode == "mp") {
		global.steam_leaderboards.mp_time_accumulator_ms += _dt;
		while (global.steam_leaderboards.mp_time_accumulator_ms >= 1000) {
			global.steam_leaderboards.mp_time_accumulator_ms -= 1000;
			global.steam_leaderboards.stat_delta.mp_time_seconds_total += 1;
		}
	}
}

function steam_leaderboards_update() {
	steam_leaderboards_state_init();
	steam_leaderboards_update_playtime();
	if (!steam_leaderboards_is_available()) return;

	steam_leaderboards_load_stats();
	steam_leaderboards_request_boards();

	var _sp_kills = steam_leaderboards_stat_total("sp_kills_total");
	var _sp_time = steam_leaderboards_stat_total("sp_time_seconds_total");
	var _mp_time = steam_leaderboards_stat_total("mp_time_seconds_total");

	steam_leaderboards_sync_stat_int("sp_kills_total", _sp_kills);
	steam_leaderboards_sync_stat_int("sp_time_seconds_total", _sp_time);
	steam_leaderboards_sync_stat_int("mp_time_seconds_total", _mp_time);

	steam_leaderboards_sync_board("lb_sp_kills", _sp_kills);
	steam_leaderboards_sync_board("lb_sp_time", _sp_time);
	steam_leaderboards_sync_board("lb_mp_time", _mp_time);

	if (global.steam_leaderboards.verified_mp_kills_total != undefined) {
		var _mp_kills = max(
			global.steam_leaderboards.stat_base.mp_kills_total,
			global.steam_leaderboards.verified_mp_kills_total
		);
		steam_leaderboards_sync_stat_int("mp_kills_total", _mp_kills);
		steam_leaderboards_sync_board("lb_mp_kills", _mp_kills);
	}

	if (global.steam_leaderboards.sgc_balance_total != undefined) {
		steam_leaderboards_sync_board("lb_sgc_balance", global.steam_leaderboards.sgc_balance_total);
	}
}

function steam_leaderboards_ui_state() {
	steam_leaderboards_state_init();
	return global.steam_leaderboards.ui;
}

function steam_leaderboards_ui_scope() {
	var _ui = steam_leaderboards_ui_state();
	return _ui.scopes[_ui.scope_index];
}

function steam_leaderboards_ui_board() {
	var _ui = steam_leaderboards_ui_state();
	return _ui.boards[_ui.board_index];
}

function steam_leaderboards_ui_request_signature() {
	var _board = steam_leaderboards_ui_board();
	var _scope = steam_leaderboards_ui_scope();
	return _board.board_name + ":" + _scope.mode;
}

function steam_leaderboards_ui_format_score(_value, _mode) {
	var _score = max(0, floor(real(_value)));
	switch (_mode) {
		case "time":
			var _hours = floor(_score / 3600);
			var _mins = floor((_score mod 3600) / 60);
			var _secs = _score mod 60;
			if (_hours > 0) {
				return string(_hours) + "h " + string_format(_mins, 2, 0) + "m " + string_format(_secs, 2, 0) + "s";
			}
			return string(_mins) + "m " + string_format(_secs, 2, 0) + "s";
		case "coin":
			return string(_score) + " SGC";
	}
	return string(_score);
}

function steam_leaderboards_ui_request(force_refresh=false) {
	steam_leaderboards_state_init();
	var _ui = global.steam_leaderboards.ui;
	var _board = steam_leaderboards_ui_board();
	var _scope = steam_leaderboards_ui_scope();
	var _signature = steam_leaderboards_ui_request_signature();

	if (!steam_leaderboards_is_available()) {
		_ui.loading = false;
		_ui.error_text = "STEAM STATS NOT READY";
		_ui.status_text = "WAITING FOR STEAM";
		return false;
	}

	if (!force_refresh && _ui.loading && _ui.last_request_signature == _signature) {
		return false;
	}

	_ui.loading = true;
	_ui.error_text = "";
	_ui.status_text = "REQUESTING " + _scope.label;
	_ui.entries = [];
	_ui.selected_row = 0;
	_ui.last_request_signature = _signature;

	switch (_scope.mode) {
		case "friends":
			_ui.request_id = steam_download_friends_scores(_board.board_name);
			break;
		case "around":
			_ui.request_id = steam_download_scores_around_user(_board.board_name, -4, 5);
			break;
		default:
			_ui.request_id = steam_download_scores(_board.board_name, 1, 10);
			break;
	}

	if (_ui.request_id < 0) {
		_ui.loading = false;
		_ui.error_text = "REQUEST FAILED TO START";
		_ui.status_text = "STEAM REQUEST ERROR";
		return false;
	}

	return true;
}

function steam_leaderboards_ui_parse_entries(_entries_json, _value_mode) {
	var _entries = [];
	var _map = json_decode(_entries_json);
	if (!ds_map_exists(_map, "entries")) {
		ds_map_destroy(_map);
		return _entries;
	}

	var _list = ds_map_find_value(_map, "entries");
	var _len = ds_list_size(_list);
	for (var _i = 0; _i < _len; _i++) {
		var _entry = _list[| _i];
		_entries[array_length(_entries)] = {
			rank  : _entry[? "rank"],
			score : _entry[? "score"],
			name  : string(_entry[? "name"]),
			user_id : _entry[? "userID"],
			value_text : steam_leaderboards_ui_format_score(_entry[? "score"], _value_mode),
		};
	}

	ds_map_destroy(_map);
	return _entries;
}

function steam_leaderboards_handle_async(_event) {
	steam_leaderboards_state_init();
	var _type = _event[? "event_type"];
	if (_type != "leaderboard_download") return false;

	var _ui = global.steam_leaderboards.ui;
	if (_event[? "id"] != _ui.request_id) return false;

	_ui.loading = false;
	var _board = steam_leaderboards_ui_board();
	var _num_entries = _event[? "num_entries"];

	if (is_undefined(_num_entries) || _num_entries <= 0) {
		_ui.entries = [];
		_ui.status_text = "NO ENTRIES RETURNED";
		_ui.error_text = "";
		return true;
	}

	var _entries_json = ds_map_find_value(_event, "entries");
	_ui.entries = steam_leaderboards_ui_parse_entries(_entries_json, _board.value_mode);
	_ui.status_text = "SYNCED " + string(array_length(_ui.entries)) + " ENTRIES";
	_ui.error_text = "";
	_ui.selected_row = clamp(_ui.selected_row, 0, max(0, array_length(_ui.entries) - 1));
	return true;
}
