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
		ready            : false,
		bootstrapping    : false,
		session_token    : "",
		steam_id         : "",
		persona_name     : "",
		auth_nonce       : "",
		ticket_handle    : -1,
		linked           : false,
		pending_link     : false,
		match_id         : "",
		match_token      : "",
		server_instance  : "",
		http_requests    : ds_map_create(),
	};
}

function sgc_gateway_log(_msg) {
	show_debug_message("[sgc-gateway] " + string(_msg));
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

/// @desc Acquire a fresh Steam auth-session ticket and return it as hex.
///       Returns "" if the Steamworks extension isn't available; the
///       gateway will accept that only when ALLOW_INSECURE_STEAM_AUTH=true.
function sgc_gateway_get_steam_ticket_hex() {
	if (!script_exists(asset_get_index("steam_user_get_auth_session_ticket"))) {
		return "";
	}
	try {
		var _ticket = steam_user_get_auth_session_ticket();
		if (!is_struct(_ticket)) return "";
		var _buf = variable_struct_exists(_ticket, "buffer") ? _ticket.buffer : -1;
		var _hex = sgc_gateway_ticket_to_hex(_buf);
		if (_buf >= 0) buffer_delete(_buf);
		return _hex;
	} catch (_e) {
		return "";
	}
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
	sgc_gateway_get("/sgc/balance", "balance", undefined);
}

function sgc_gateway_match_create() {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) return;
	sgc_gateway_post_json("/matches/create", {}, "match_create", undefined);
}

function sgc_gateway_match_join(_match_id) {
	sgc_gateway_state_init();
	if (!global.sgc_gateway.ready) return;
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
	if (!global.sgc_gateway.ready) return;
	if (string_length(global.sgc_gateway.match_id) <= 0) return;

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

	sgc_gateway_post_json("/matches/report-event", _body, "report_event", _body);
}

function sgc_gateway_report_pve_kill(_args)        { sgc_gateway_report_event("pve_kill",        _args); }
function sgc_gateway_report_level_complete(_args)  { sgc_gateway_report_event("level_complete",  _args); }
function sgc_gateway_report_pvp_kill(_args)        { sgc_gateway_report_event("pvp_kill",        _args); }

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
			var _ticket_hex = sgc_gateway_get_steam_ticket_hex();
			sgc_gateway_post_json("/auth/steam/finish", {
				steam_id     : global.sgc_gateway.steam_id,
				persona_name : global.sgc_gateway.persona_name,
				nonce        : global.sgc_gateway.auth_nonce,
				ticket_hex   : _ticket_hex,
			}, "auth_finish", undefined);
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
			sgc_gateway_log("session ready for " + global.sgc_gateway.steam_id);
			if (global.sgc_gateway.pending_link) {
				global.sgc_gateway.pending_link = false;
				sgc_gateway_post_json("/sgc/link/start", {}, "link_start", undefined);
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
				if (steam_is_overlay_enabled()) {
					steam_activate_overlay_browser(_url);
				} else {
					url_open(_url);
				}
			}
			break;

		case "balance":
			if (!_ok) { sgc_gateway_log("balance failed: http=" + string(_http)); break; }
			sgc_gateway_log("balance: " + string(_body));
			global.sgc_gateway_last_balance = _data;
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
			break;

		case "match_close":
			global.sgc_gateway.match_id        = "";
			global.sgc_gateway.match_token     = "";
			global.sgc_gateway.server_instance = "";
			break;

		case "report_event":
			if (!_ok) {
				sgc_gateway_log("report_event failed: http=" + string(_http) + " body=" + string(_body));
			}
			break;
	}
	return true;
}

/// @desc Stub for Async Steam events – reserved for future ticket-based auth.
function sgc_gateway_handle_async_steam() {
	return false;
}
