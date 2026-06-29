/// @description SadGirlCoin Gateway client-side library
///
/// All SadGirlCoin traffic from the game goes through our own backend
/// gateway (sgc-gateway-server). The game NEVER holds a real SGC token.
/// The gateway is reverse-proxied at https://sadgirlsclub.wtf/gmlapi by
/// default; override global.sgc_gateway_base_url before calling
/// sgc_gateway_bootstrap() for local testing.
///
/// Public API:
///   sgc_gateway_bootstrap(_force)         - establish a session with the gateway
///   sgc_gateway_begin_link_flow()         - start the SGC OAuth link flow
///   sgc_gateway_check_balance()           - request the linked player's balance
///   sgc_gateway_update()                  - pump periodic balance/summary refresh
///   sgc_gateway_match_create()            - host: register a match
///   sgc_gateway_match_join(_match_id)     - client: join a match
///   sgc_gateway_match_close()             - host: close a match
///   sgc_gateway_report_pve_kill(_args)    - report a PvE kill (1 SGC)
///   sgc_gateway_report_level_complete(_a) - report a level completion (10 SGC)
///   sgc_gateway_report_pvp_kill(_args)    - report a PvP kill (5 SGC)
///   sgc_gateway_handle_async_http()       - call from any Async HTTP event
///   sgc_gateway_handle_async_steam()      - call from any Async Steam event

#macro SGC_GATEWAY_DEFAULT_URL "https://sadgirlsclub.wtf/gmlapi"

function sgc_gateway_base_url() {
	if (variable_global_exists("sgc_gateway_base_url")
		&& is_string(global.sgc_gateway_base_url)
		&& string_length(global.sgc_gateway_base_url) > 0) {
		return global.sgc_gateway_base_url;
	}
	return SGC_GATEWAY_DEFAULT_URL;
}

function sgc_gateway_state_init() {
	if (variable_global_exists("sgc_gateway")) return;
	global.sgc_gateway = {
		ready             : false,
		bootstrapping     : false,
		session_token     : "",
		steam_id          : "",
		persona_name      : "",
		auth_nonce        : "",
		ticket_handle     : -1,
		ticket_buffer     : -1,
		ticket_validated  : false,
		linked            : false,
		pending_link      : false,
		pending_match_create : false,
		pending_match_join   : "",
		pending_reports      : [],
		singleplayer_mode    : false,
		balance_value        : undefined,
		balance_synced_value : undefined,
		balance_level_base   : undefined,
		balance_level_pending : 0,
		run_total_earned     : 0,
		balance_reset_on_next_fetch : false,
		balance_pending      : false,
		next_balance_poll_ms : 0,
		leaderboard_summary_pending : false,
		next_leaderboard_summary_poll_ms : 0,
		verified_mp_kills_total : undefined,
		purchase_pending      : false,
		purchase_item_id      : "",
		match_id          : "",
		match_token       : "",
		server_instance   : "",
		http_requests     : ds_map_create(),
	};
}

function sgc_gateway_log(_msg) {
	show_debug_message("[sgc-gateway] " + string(_msg));
}

function sgc_gateway_begin_singleplayer_match() {
	sgc_gateway_state_init();
	global.sgc_gateway.singleplayer_mode = true;
	if (string_length(global.sgc_gateway.match_id) > 0) return;
	var _nonce = string(current_time) + "_" + string(irandom(0x7fffffff));
	global.sgc_gateway.match_id        = "sp_match_" + _nonce;
	global.sgc_gateway.match_token     = "sp_token_" + _nonce;
	global.sgc_gateway.server_instance = "sp_srv_" + _nonce;
	sgc_gateway_log("singleplayer synthetic match prepared: "
		+ global.sgc_gateway.match_id);
}

function sgc_gateway_queue_report(_event_type, _args) {
	sgc_gateway_state_init();
	var _idx = array_length(global.sgc_gateway.pending_reports);
	global.sgc_gateway.pending_reports[_idx] = {
		event_type : _event_type,
		args       : _args,
	};
}

function sgc_gateway_submit_report(_event_type, _args) {
	var _body = {
		event_type           : _event_type,
		event_id             : variable_struct_exists(_args, "event_id") ? _args.event_id : sgc_gateway_iso_now() + ":" + string(irandom(0x7fffffff)),
		match_id             : global.sgc_gateway.match_id,
		match_token          : global.sgc_gateway.match_token,
		server_instance_id   : global.sgc_gateway.server_instance,
		reporter_steam_id    : global.sgc_gateway.steam_id,
		beneficiary_steam_id : variable_struct_exists(_args, "beneficiary_steam_id")
			? string(_args.beneficiary_steam_id)
			: global.sgc_gateway.steam_id,
		occurred_at          : sgc_gateway_iso_now(),
	};
	if (variable_struct_exists(_args, "victim_steam_id"))
		_body.victim_steam_id = string(_args.victim_steam_id);
	if (variable_struct_exists(_args, "enemy_spawn_id"))
		_body.enemy_spawn_id = string(_args.enemy_spawn_id);
	if (variable_struct_exists(_args, "level_id"))
		_body.level_id = string(_args.level_id);
	if (variable_struct_exists(_args, "run_id"))
		_body.run_id = string(_args.run_id);
	if (variable_struct_exists(_args, "death_seq"))
		_body.death_seq = real(_args.death_seq);
	if (variable_struct_exists(_args, "amount"))
		_body.amount = real(_args.amount);
	if (variable_struct_exists(_args, "collectible_id"))
		_body.collectible_id = string(_args.collectible_id);

	sgc_gateway_post_json("/matches/report-event", _body, "report_event", _body);
}

function sgc_gateway_flush_pending_reports() {
	sgc_gateway_state_init();
	if (string_length(global.sgc_gateway.match_id) <= 0) return;
	var _pending = global.sgc_gateway.pending_reports;
	global.sgc_gateway.pending_reports = [];
	for (var _i = 0; _i < array_length(_pending); _i++) {
		var _entry = _pending[_i];
		if (is_struct(_entry)) {
			sgc_gateway_submit_report(_entry.event_type, _entry.args);
		}
	}
}

/// @desc Track an outbound http_request_id so the async HTTP event can route it.
function sgc_gateway_track_request(_id, _kind, _payload) {
	sgc_gateway_state_init();
	if (_id < 0) {
		sgc_gateway_log("http_request returned invalid id for " + string(_kind));
		return;
	}
	ds_map_add(global.sgc_gateway.http_requests, _id, {
		kind    : _kind,
		payload : _payload,
	});
}

function sgc_gateway_auth_header() {
	sgc_gateway_state_init();
	if (string_length(global.sgc_gateway.session_token) <= 0) return "";
	return "Bearer " + global.sgc_gateway.session_token;
}

function sgc_gateway_post_json(_path, _body, _kind, _payload) {
	var _url = sgc_gateway_base_url() + _path;
	var _headers = ds_map_create();
	ds_map_add(_headers, "Content-Type", "application/json");
	var _auth = sgc_gateway_auth_header();
	if (string_length(_auth) > 0) ds_map_add(_headers, "Authorization", _auth);
	var _id = http_request(_url, "POST", _headers, json_stringify(_body));
	ds_map_destroy(_headers);
	sgc_gateway_track_request(_id, _kind, _payload);
	return _id;
}

function sgc_gateway_get(_path, _kind, _payload) {
	var _url = sgc_gateway_base_url() + _path;
	var _headers = ds_map_create();
	var _auth = sgc_gateway_auth_header();
	if (string_length(_auth) > 0) ds_map_add(_headers, "Authorization", _auth);
	var _id = http_request(_url, "GET", _headers, "");
	ds_map_destroy(_headers);
	sgc_gateway_track_request(_id, _kind, _payload);
	return _id;
}

/// @desc Kick off a session with the gateway. Safe to call any time;
///       no-ops while a bootstrap is in flight or when already ready.
/// @param _force  set true to force a re-auth
function sgc_gateway_bootstrap(_force) {
	sgc_gateway_state_init();
	if (!_force && (global.sgc_gateway.ready || global.sgc_gateway.bootstrapping)) {
		return;
	}
	global.sgc_gateway.bootstrapping = true;
	global.sgc_gateway.steam_id     = string(steam_get_user_steam_id());
	global.sgc_gateway.persona_name = steam_get_persona_name();
	sgc_gateway_post_json("/auth/steam/start", {
		steam_id     : global.sgc_gateway.steam_id,
		persona_name : global.sgc_gateway.persona_name,
	}, "auth_start", undefined);
}

/// @desc Convert a Steamworks auth-ticket buffer to lowercase hex.
///       Returns "" on any failure (caller decides whether to send empty).
function sgc_gateway_ticket_to_hex(_buffer) {
	if (_buffer < 0) return "";
	try {
		var _size = buffer_get_size(_buffer);
		var _hex = "";
		buffer_seek(_buffer, buffer_seek_start, 0);
		for (var _i = 0; _i < _size; _i++) {
			var _b = buffer_read(_buffer, buffer_u8);
			var _hi = _b >> 4;
			var _lo = _b & 0x0F;
			_hex += string_char_at("0123456789abcdef", _hi + 1)
			      + string_char_at("0123456789abcdef", _lo + 1);
		}
		return _hex;
	} catch (_e) {
		return "";
	}
}

/// @desc Request a fresh Steam auth-session ticket. Stores the buffer and
///       handle on global state. The actual /auth/finish post is deferred
///       until Steam fires its ticket_response async event with success.
function sgc_gateway_request_steam_ticket() {
	sgc_gateway_state_init();
	if (global.sgc_gateway.ticket_buffer >= 0) {
		buffer_delete(global.sgc_gateway.ticket_buffer);
		global.sgc_gateway.ticket_buffer = -1;
	}
	global.sgc_gateway.ticket_handle    = -1;
	global.sgc_gateway.ticket_validated = false;
	try {
		var _ticket = steam_user_get_auth_session_ticket();
		if (is_struct(_ticket)) {
			if (variable_struct_exists(_ticket, "buffer"))
				global.sgc_gateway.ticket_buffer = _ticket.buffer;
			if (variable_struct_exists(_ticket, "auth_ticket_handle"))
				global.sgc_gateway.ticket_handle = _ticket.auth_ticket_handle;
		} else if (is_real(_ticket)) {
			global.sgc_gateway.ticket_buffer = _ticket;
		}
		if (global.sgc_gateway.ticket_buffer < 0) {
			sgc_gateway_log("steam ticket request returned no buffer");
		}
	} catch (_e) {
		sgc_gateway_log("steam ticket request threw: " + string(_e));
	}
}

/// @desc Post /auth/steam/finish using whatever ticket is currently held.
///       Sends an empty ticket if none was acquired; the gateway only
///       accepts that when ALLOW_INSECURE_STEAM_AUTH=true.
function sgc_gateway_finish_auth() {
	sgc_gateway_state_init();
	var _hex = "";
	if (global.sgc_gateway.ticket_buffer >= 0) {
		_hex = sgc_gateway_ticket_to_hex(global.sgc_gateway.ticket_buffer);
		buffer_delete(global.sgc_gateway.ticket_buffer);
		global.sgc_gateway.ticket_buffer = -1;
	}
	sgc_gateway_post_json("/auth/steam/finish", {
		steam_id     : global.sgc_gateway.steam_id,
		persona_name : global.sgc_gateway.persona_name,
		nonce        : global.sgc_gateway.auth_nonce,
		ticket_hex   : _hex,
	}, "auth_finish", undefined);
}

/// @desc Start SGC OAuth link flow. If the gateway session isn't ready yet,
///       this will bootstrap first and resume automatically.
function sgc_gateway_begin_link_flow() {
	sgc_gateway_state_init();
	global.sgc_gateway.pending_link = true;
	if (!global.sgc_gateway.ready) {
		sgc_gateway_bootstrap(false);
		return;
	}
	sgc_gateway_post_json("/sgc/link/start", {}, "link_start", undefined);
}

function sgc_gateway_check_balance() {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) {
		sgc_gateway_log("balance requested before gateway ready");
		return;
	}
	if (global.sgc_gateway.balance_pending) return;
	global.sgc_gateway.balance_pending = true;
	sgc_gateway_get("/sgc/balance", "balance", undefined);
}

function sgc_gateway_fetch_leaderboard_summary() {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) return;
	if (global.sgc_gateway.leaderboard_summary_pending) return;
	global.sgc_gateway.leaderboard_summary_pending = true;
	sgc_gateway_get("/leaderboards/summary", "leaderboard_summary", undefined);
}

function sgc_gateway_balance_available() {
	sgc_gateway_state_init();
	var _base = global.sgc_gateway.balance_level_base;
	if (_base == undefined) _base = global.sgc_gateway.balance_synced_value;
	if (_base == undefined) return undefined;
	return max(0, floor(real(_base + global.sgc_gateway.balance_level_pending)));
}

function sgc_gateway_apply_balance_sync(_balance_value) {
	sgc_gateway_state_init();
	var _value = max(0, floor(real(_balance_value)));
	global.sgc_gateway.balance_value = _value;
	global.sgc_gateway.balance_synced_value = _value;
	global.sgc_gateway.balance_level_base = _value;
	global.sgc_gateway.balance_level_pending = 0;
	global.sgc_gateway.balance_reset_on_next_fetch = false;
	steam_leaderboards_set_sgc_balance(_value);
}

function sgc_gateway_extract_error_message(_data, _http, _body) {
	if (is_struct(_data)) {
		if (variable_struct_exists(_data, "error")) {
			var _error = _data.error;
			if (is_struct(_error) && variable_struct_exists(_error, "message")) return string(_error.message);
			if (is_string(_error)) return _error;
		}
		if (variable_struct_exists(_data, "message")) return string(_data.message);
	}
	if (is_string(_body) && string_length(_body) > 0) return _body;
	return "Purchase failed (HTTP " + string(_http) + ").";
}

function sgc_gateway_purchase_unlockable(_item_id, _amount, _note) {
	sgc_gateway_state_init();
	if (global.sgc_gateway.purchase_pending) {
		return { ok : false, message : "Another purchase is already pending." };
	}
	if (!global.sgc_gateway.ready) {
		return { ok : false, message : "SGC gateway is still connecting." };
	}
	if (!global.sgc_gateway.linked) {
		return { ok : false, message : "Link your SGC account before purchasing." };
	}

	var _balance = sgc_gateway_balance_available();
	if (_balance == undefined) {
		return { ok : false, message : "Balance unavailable. Refresh and try again." };
	}
	if (_balance < _amount) {
		return { ok : false, message : "Not enough SadGirlCoin." };
	}

	global.sgc_gateway.purchase_pending = true;
	global.sgc_gateway.purchase_item_id = string(_item_id);
	sgc_gateway_post_json("/sgc/charge", {
		item_id : string(_item_id),
		amount : max(1, floor(real(_amount))),
		note : string(_note),
	}, "purchase_charge", {
		item_id : string(_item_id),
		amount : max(1, floor(real(_amount))),
	});
	return { ok : true, message : "Purchase submitted." };
}

function sgc_gateway_update() {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) return;

	var _now = current_time;
	if (global.sgc_gateway.linked
		&& !global.sgc_gateway.balance_pending
		&& _now >= global.sgc_gateway.next_balance_poll_ms) {
		global.sgc_gateway.next_balance_poll_ms = _now + 30000;
		sgc_gateway_check_balance();
	}

	if (!global.sgc_gateway.leaderboard_summary_pending
		&& _now >= global.sgc_gateway.next_leaderboard_summary_poll_ms) {
		global.sgc_gateway.next_leaderboard_summary_poll_ms = _now + 15000;
		sgc_gateway_fetch_leaderboard_summary();
	}
}

function sgc_gateway_begin_level_balance_cycle() {
	sgc_gateway_state_init();
	global.sgc_gateway.balance_reset_on_next_fetch = true;
	if (!global.sgc_gateway.ready || !global.sgc_gateway.linked) return;
	sgc_gateway_check_balance();
}

function sgc_gateway_end_level_balance_cycle() {
	sgc_gateway_state_init();
	global.sgc_gateway.balance_reset_on_next_fetch = true;
	if (!global.sgc_gateway.ready || !global.sgc_gateway.linked) return;
	sgc_gateway_check_balance();
}

function sgc_gateway_collectible_roll_amount() {
	var _roll = irandom(99);
	if (_roll < 45) return 1;
	if (_roll < 75) return 3;
	if (_roll < 92) return 5;
	return 10;
}

function sgc_gateway_has_auto_singleplayer_collectibles() {
	if (!instance_exists(obj_SGCCollectible)) return false;
	var _count = instance_number(obj_SGCCollectible);
	for (var _i = 0; _i < _count; _i++) {
		var _pickup = instance_find(obj_SGCCollectible, _i);
		if (!instance_exists(_pickup)) continue;
		if (!variable_instance_exists(_pickup, "collectibleCode")) continue;
		var _code = string(_pickup.collectibleCode);
		if (string_pos("auto:", _code) == 1) return true;
	}
	return false;
}

function sgc_gateway_spawn_singleplayer_collectibles(_avoid_x, _avoid_y) {
	sgc_gateway_state_init();
	if (instance_exists(obj_Server) || instance_exists(obj_Client)) return;
	if (room == rm_Runner) return;
	if (sgc_gateway_has_auto_singleplayer_collectibles()) return;

	var _solid_count = instance_number(objSolid);
	if (_solid_count <= 0) return;

	var _candidates = [];
	var _lower_band_y = room_height * 0.35;
	for (var _i = 0; _i < _solid_count; _i++) {
		var _solid = instance_find(objSolid, _i);
		if (!instance_exists(_solid)) continue;

		var _width = abs(_solid.bbox_right - _solid.bbox_left);
		var _height = abs(_solid.bbox_bottom - _solid.bbox_top);
		if (_width < 48 || _height < 12) continue;
		if (_solid.bbox_top < _lower_band_y) continue;

		var _span = max(1, floor(_width) - 48);
		var _px = _solid.bbox_left + 24 + irandom(_span);
		var _py = _solid.bbox_top - 18;

		if (point_distance(_avoid_x, _avoid_y, _px, _py) < 96) continue;
		if (collision_circle(_px, _py, 22, obj_SGCCollectible, false, true) != noone) continue;

		array_push(_candidates, {
			x : _px,
			y : _py,
			sort_y : _solid.bbox_top,
		});
	}

	var _candidate_count = array_length(_candidates);
	if (_candidate_count <= 0) return;

	for (var _j = 0; _j < _candidate_count; _j++) {
		var _swap = irandom(_candidate_count - 1);
		var _tmp = _candidates[_j];
		_candidates[_j] = _candidates[_swap];
		_candidates[_swap] = _tmp;
	}

	var _spawn_target = clamp(2 + irandom(2), 1, _candidate_count);
	var _spawned = [];
	for (var _k = 0; _k < _candidate_count; _k++) {
		if (array_length(_spawned) >= _spawn_target) break;
		var _candidate = _candidates[_k];
		var _too_close = false;
		for (var _m = 0; _m < array_length(_spawned); _m++) {
			if (point_distance(_candidate.x, _candidate.y, _spawned[_m].x, _spawned[_m].y) < 72) {
				_too_close = true;
				break;
			}
		}
		if (_too_close) continue;

		var _amount = sgc_gateway_collectible_roll_amount();
		var _pickup = instance_create_layer(_candidate.x, _candidate.y, "Instances", obj_SGCCollectible);
		_pickup.sgcAmount = _amount;
		_pickup.collectibleCode = "auto:"
			+ room_get_name(room)
			+ ":" + string(_k)
			+ ":" + string(round(_candidate.x))
			+ ":" + string(round(_candidate.y))
			+ ":" + string(_amount);
		mp_replicate_spawn(_pickup, ENTITY_KIND.COLLECTIBLE);
		array_push(_spawned, _candidate);
	}
}

function sgc_gateway_balance_text() {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) return "SGC ...";
	if (!global.sgc_gateway.linked) return "SGC UNLINKED";
	var _base = global.sgc_gateway.balance_level_base;
	if (_base == undefined) _base = global.sgc_gateway.balance_synced_value;
	if (_base == undefined) return "SGC ...";
	return "SGC " + string(_base + global.sgc_gateway.balance_level_pending);
}

function sgc_gateway_run_total_text() {
	sgc_gateway_state_init();
	return "This Run: " + string(global.sgc_gateway.run_total_earned);
}

function sgc_gateway_draw_holo_text(_x, _y, _text) {
	// Holographic fringe layers
	draw_set_alpha(0.35);
	draw_set_color(make_color_rgb(80, 255, 255));
	draw_text(_x - 2, _y + 1, _text);
	draw_set_color(make_color_rgb(255, 90, 180));
	draw_text(_x + 2, _y - 1, _text);
	draw_set_color(make_color_rgb(255, 160, 160));
	draw_text(_x, _y + 3, _text);

	// Main red face
	draw_set_alpha(1);
	draw_set_color(make_color_rgb(255, 45, 45));
	draw_text(_x, _y, _text);

	// Bright inner pass for a crisp holo-core
	draw_set_alpha(0.6);
	draw_set_color(make_color_rgb(255, 215, 215));
	draw_text(_x, _y, _text);
	draw_set_alpha(1);
}

function sgc_gateway_draw_balance_hud() {
	sgc_gateway_state_init();
	if (!isLocal) return;

	var _balance = sgc_gateway_balance_text();
	var _run = sgc_gateway_run_total_text();
	var _x = display_get_gui_width() * 0.5;
	var _y = 18;

	draw_set_font(fontMenu);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	sgc_gateway_draw_holo_text(_x, _y, _balance);

	draw_set_font(fontMenuSmall);
	sgc_gateway_draw_holo_text(_x, _y + 24, _run);

	draw_set_alpha(1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

function sgc_gateway_match_create() {
	sgc_gateway_state_init();
	if (global.sgc_gateway.singleplayer_mode) {
		if (string_length(global.sgc_gateway.match_id) <= 0) {
			sgc_gateway_begin_singleplayer_match();
		}
		return;
	}
	if (!global.sgc_gateway.ready) {
		global.sgc_gateway.pending_match_create = true;
		sgc_gateway_bootstrap(false);
		return;
	}
	sgc_gateway_post_json("/matches/create", {}, "match_create", undefined);
}

function sgc_gateway_match_join(_match_id) {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) {
		global.sgc_gateway.pending_match_join = string(_match_id);
		sgc_gateway_bootstrap(false);
		return;
	}
	sgc_gateway_post_json("/matches/join", { match_id : _match_id }, "match_join", undefined);
}

function sgc_gateway_match_close() {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) return;
	if (string_length(global.sgc_gateway.match_id) <= 0) return;
	sgc_gateway_post_json("/matches/close",
		{ match_id : global.sgc_gateway.match_id },
		"match_close", undefined);
}

function sgc_gateway_iso_now() {
	var _y = current_year, _m = current_month, _d = current_day;
	var _hh = current_hour, _mm = current_minute, _ss = current_second;
	return string_format(_y, 4, 0) + "-"
		+ string_replace(string_format(_m, 2, 0), " ", "0") + "-"
		+ string_replace(string_format(_d, 2, 0), " ", "0") + "T"
		+ string_replace(string_format(_hh, 2, 0), " ", "0") + ":"
		+ string_replace(string_format(_mm, 2, 0), " ", "0") + ":"
		+ string_replace(string_format(_ss, 2, 0), " ", "0") + "Z";
}

function sgc_gateway_report_event(_event_type, _args) {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) {
		sgc_gateway_log("queueing report before gateway ready: " + string(_event_type));
		sgc_gateway_queue_report(_event_type, _args);
		sgc_gateway_bootstrap(false);
		return;
	}
	if (string_length(global.sgc_gateway.match_id) <= 0) {
		if (global.sgc_gateway.singleplayer_mode) {
			sgc_gateway_begin_singleplayer_match();
		} else {
			sgc_gateway_log("queueing report until match exists: " + string(_event_type));
			sgc_gateway_queue_report(_event_type, _args);
			sgc_gateway_match_create();
			return;
		}
	}
	if (string_length(global.sgc_gateway.match_id) <= 0) {
		sgc_gateway_log("queueing report until match exists: " + string(_event_type));
		sgc_gateway_queue_report(_event_type, _args);
		sgc_gateway_match_create();
		return;
	}
	sgc_gateway_submit_report(_event_type, _args);
}

function sgc_gateway_report_pve_kill(_args)        {
	if (variable_struct_exists(_args, "beneficiary_steam_id")) {
		steam_leaderboards_note_pve_kill(_args.beneficiary_steam_id);
	}
	sgc_gateway_report_event("pve_kill", _args);
}
function sgc_gateway_report_level_complete(_args)  { sgc_gateway_report_event("level_complete",  _args); }
function sgc_gateway_report_pvp_kill(_args)        { sgc_gateway_report_event("pvp_kill",        _args); }
function sgc_gateway_report_collectible(_args)     { sgc_gateway_report_event("collectible_pickup", _args); }

/// @desc Call this from any Async HTTP event (Other -> HTTP).
///       Returns true if the event was handled.
function sgc_gateway_handle_async_http() {
	sgc_gateway_state_init();
	var _id = async_load[? "id"];
	if (_id == undefined) return false;
	if (!ds_map_exists(global.sgc_gateway.http_requests, _id)) return false;

	var _entry  = global.sgc_gateway.http_requests[? _id];
	var _status = async_load[? "status"];
	var _http   = async_load[? "http_status"];
	var _body   = async_load[? "result"];
	ds_map_delete(global.sgc_gateway.http_requests, _id);

	// status: 0 = ok, 1 = in-progress (retry), -1 = failed
	if (_status == 1) return true;

	var _ok = (_status == 0) && (_http >= 200) && (_http < 300);
	var _data = undefined;
	if (is_string(_body) && string_length(_body) > 0) {
		try { _data = json_parse(_body); } catch (_e) { _data = undefined; }
	}

	switch (_entry.kind) {
		case "auth_start":
			if (!_ok || !is_struct(_data)) {
				global.sgc_gateway.bootstrapping = false;
				sgc_gateway_log("auth/start failed: http=" + string(_http) + " body=" + string(_body));
				break;
			}
			global.sgc_gateway.auth_nonce = _data.nonce;
			sgc_gateway_request_steam_ticket();
			// If Steamworks didn't give us a ticket buffer at all, finish now
			// (gateway will only accept this in insecure mode). Otherwise wait
			// for Steam's ticket_response async event to confirm validity.
			if (global.sgc_gateway.ticket_buffer < 0) {
				sgc_gateway_finish_auth();
			}
			break;

		case "auth_finish":
			global.sgc_gateway.bootstrapping = false;
			if (!_ok || !is_struct(_data)) {
				sgc_gateway_log("auth/finish failed: http=" + string(_http) + " body=" + string(_body));
				break;
			}
			global.sgc_gateway.session_token = _data.session_token;
			global.sgc_gateway.ready         = true;
			if (is_struct(_data.player)) {
			global.sgc_gateway.linked = (_data.player.sgc_link_active == true);
			}
			global.sgc_gateway.next_balance_poll_ms = 0;
			global.sgc_gateway.next_leaderboard_summary_poll_ms = 0;
			sgc_gateway_log("session ready for " + global.sgc_gateway.steam_id);
			if (global.sgc_gateway.linked
				&& (global.sgc_gateway.balance_reset_on_next_fetch
					|| global.sgc_gateway.balance_level_base == undefined)) {
				sgc_gateway_check_balance();
			}
			sgc_gateway_fetch_leaderboard_summary();
			if (global.sgc_gateway.pending_link) {
				global.sgc_gateway.pending_link = false;
				sgc_gateway_post_json("/sgc/link/start", {}, "link_start", undefined);
			}
			if (global.sgc_gateway.pending_match_create) {
				global.sgc_gateway.pending_match_create = false;
				sgc_gateway_post_json("/matches/create", {}, "match_create", undefined);
			}
			if (string_length(global.sgc_gateway.pending_match_join) > 0) {
				var _pending_match_id = global.sgc_gateway.pending_match_join;
				global.sgc_gateway.pending_match_join = "";
				sgc_gateway_post_json("/matches/join",
					{ match_id : _pending_match_id },
					"match_join", undefined);
			}
			break;

		case "link_start":
			if (!_ok || !is_struct(_data)) {
				sgc_gateway_log("link/start failed: http=" + string(_http) + " body=" + string(_body));
				break;
			}
			var _url = _data.authorize_url;
			if (is_string(_url) && string_length(_url) > 0) {
				sgc_gateway_log("opening SGC link URL: " + _url);
				// Always hand OAuth off to the OS browser so Discord and other
				// providers use the player's existing signed-in session.
				url_open(_url);
			}
			break;

		case "balance":
			global.sgc_gateway.balance_pending = false;
			if (!_ok) { sgc_gateway_log("balance failed: http=" + string(_http)); break; }
			sgc_gateway_log("balance: " + string(_body));
			global.sgc_gateway_last_balance = _data;
			if (is_struct(_data) && variable_struct_exists(_data, "balance")) {
				sgc_gateway_apply_balance_sync(_data.balance);
				if (global.sgc_gateway.balance_reset_on_next_fetch
					|| global.sgc_gateway.balance_level_base == undefined) {
					global.sgc_gateway.balance_level_base = _data.balance;
					global.sgc_gateway.balance_level_pending = 0;
					global.sgc_gateway.balance_reset_on_next_fetch = false;
				}
			}
			break;

		case "purchase_charge":
			global.sgc_gateway.purchase_pending = false;
			var _purchase_item_id = "";
			if (is_struct(_entry.payload) && variable_struct_exists(_entry.payload, "item_id")) {
				_purchase_item_id = string(_entry.payload.item_id);
			}
			global.sgc_gateway.purchase_item_id = "";
			if (!_ok) {
				unlockables_complete_purchase_failure(
					_purchase_item_id,
					sgc_gateway_extract_error_message(_data, _http, _body)
				);
				sgc_gateway_log("purchase failed: http=" + string(_http) + " body=" + string(_body));
				break;
			}
			var _balance_after = undefined;
			if (is_struct(_data) && variable_struct_exists(_data, "balance")) {
				_balance_after = _data.balance;
			}
			unlockables_complete_purchase_success(_purchase_item_id, _balance_after);
			break;

		case "leaderboard_summary":
			global.sgc_gateway.leaderboard_summary_pending = false;
			if (!_ok) {
				sgc_gateway_log("leaderboard summary failed: http=" + string(_http));
				break;
			}
			if (is_struct(_data) && variable_struct_exists(_data, "verified_mp_kills_total")) {
				global.sgc_gateway.verified_mp_kills_total = _data.verified_mp_kills_total;
				steam_leaderboards_set_verified_mp_kills(_data.verified_mp_kills_total);
			}
			break;

		case "match_create":
			if (!_ok || !is_struct(_data) || !is_struct(_data.match)) {
				sgc_gateway_log("match/create failed: http=" + string(_http));
				break;
			}
			global.sgc_gateway.match_id        = _data.match.match_id;
			global.sgc_gateway.match_token     = _data.match.match_token;
			global.sgc_gateway.server_instance = _data.match.server_instance_id;
			sgc_gateway_log("match created: " + global.sgc_gateway.match_id);
			sgc_gateway_flush_pending_reports();
			break;

		case "match_join":
			if (!_ok || !is_struct(_data) || !is_struct(_data.match)) {
				sgc_gateway_log("match/join failed: http=" + string(_http));
				break;
			}
			global.sgc_gateway.match_id        = _data.match.match_id;
			global.sgc_gateway.match_token     = _data.match.match_token;
			global.sgc_gateway.server_instance = _data.match.server_instance_id;
			sgc_gateway_log("match joined: " + global.sgc_gateway.match_id);
			sgc_gateway_flush_pending_reports();
			break;

		case "match_close":
			global.sgc_gateway.match_id        = "";
			global.sgc_gateway.match_token     = "";
			global.sgc_gateway.server_instance = "";
			break;

		case "report_event":
			if (_ok && is_struct(_data)) {
				var _reward = variable_struct_exists(_data, "reward_event")
					? _data.reward_event : undefined;
				var _statusText = variable_struct_exists(_data, "status")
					? string(_data.status) : "";
				if (is_struct(_reward) && _statusText == "issued") {
					if (variable_struct_exists(_reward, "amount")) {
						var _issued_amount = real(_reward.amount);
						global.sgc_gateway.balance_level_pending += _issued_amount;
						global.sgc_gateway.run_total_earned += _issued_amount;
					}
					if (string(_reward.event_type) == "level_complete") {
						sgc_gateway_end_level_balance_cycle();
					}
				}
				if (is_struct(_reward) && string(_reward.event_type) == "pvp_kill") {
					sgc_gateway_fetch_leaderboard_summary();
				}
			}
			if (!_ok) {
				sgc_gateway_log("report_event failed: http=" + string(_http) + " body=" + string(_body));
			}
			break;
	}
	return true;
}

/// @desc Call from any Async Steam event (Other -> Async Steam). Listens
///       for ticket_response and posts /auth/finish only after Steam has
///       validated the ticket. Returns true if the event was handled.
function sgc_gateway_handle_async_steam() {
	sgc_gateway_state_init();
	var _evt = async_load[? "event_type"];
	if (_evt != "ticket_response") return false;
	var _handle = async_load[? "auth_ticket_handle"];
	if (global.sgc_gateway.ticket_handle >= 0
		&& _handle != global.sgc_gateway.ticket_handle) {
		return false; // not our ticket
	}
	var _success = async_load[? "success"];
	var _result  = async_load[? "result"];
	// Steamworks GM wrapper reports success=true and result=1 (k_EResultOK).
	var _ok = (_success == true) || (_result == 1) || (_result == 1.0);
	if (!_ok) {
		sgc_gateway_log("steam ticket validation failed: success="
			+ string(_success) + " result=" + string(_result));
		global.sgc_gateway.bootstrapping = false;
		return true;
	}
	if (global.sgc_gateway.ticket_validated) return true;
	global.sgc_gateway.ticket_validated = true;
	sgc_gateway_finish_auth();
	return true;
}
