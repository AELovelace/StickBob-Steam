
// Network packet type identifiers.
// These values are written as the first byte of every packet so the
// receiver can dispatch to the correct handler.
//
// Flow overview:
//   Client → Server : CLIENT_PLAYER_INPUT  (raw key/mouse data)
//   Server → Client : SERVER_PLAYER_INPUT  (relays host input so clients can simulate the host)
//   Server → Client : PLAYER_POSITION      (authoritative position broadcast each tick)
//   Server → Client : SPAWN_SELF           (tells a joining client where to place their own character)
//   Server → Client : SPAWN_OTHER          (tells existing clients about a newly spawned peer)
//   Server → Client : SYNC_PLAYERS         (JSON snapshot of the full player list on join)
//
// Protocol version: bump NET_PROTOCOL_VERSION on ANY change to packet layout
// or semantics. Hosts refuse joins from clients with a mismatched version
// (KICK_VERSION). Stored on first byte of HELLO/HELLO_ACK/KICK_VERSION.
#macro NET_PROTOCOL_VERSION 1
enum NETWORK_PACKETS {
	// Protocol handshake / liveness (low IDs reserved)
	HELLO               = 1,   // client → host: u32 protocol_version | u32 build_tag
	HELLO_ACK           = 2,   // host → client: u32 protocol_version
	KICK_VERSION        = 3,   // host → client: u32 server_version | u32 server_build (refused)
	HEARTBEAT           = 4,   // both directions: keep-alive ping; no payload
	// Gameplay
	CLIENT_PLAYER_INPUT = 10,  // client → server: xInput, yInput, runKey, actionKey, mouseAngle
	SERVER_PLAYER_INPUT = 11,  // server → clients: same fields plus steamID of the player
	PLAYER_POSITION     = 12,  // server → clients: u16 seq | u64 steamID | u16 x | u16 y
	PLAYER_HEALTH       = 13,  // server → clients: steamID + current health
	PLAYER_COLOR        = 14,  // client → server (u32 color); server → clients (u64 steamID + u32 color)
	CLIENT_SPAWN_RESYNC = 15,  // client → server: request SYNC_PLAYERS + SPAWN_SELF replay
	// Match lifecycle
	MATCH_START         = 16,  // host → clients: mode | map | seed | tick0
	MATCH_START_ACK     = 17,  // client → host: ack of MATCH_START
	MATCH_END           = 18,  // host → clients: u8 reason | string results_json
	ROOM_CHANGE         = 19,  // host → clients: u32 room_asset_index
	CLIENT_READY        = 20,  // client → host: u8 ready
	LOBBY_STATE         = 21,  // host → clients: JSON of {steamID, ready} list
	WORLD_SNAPSHOT      = 22,  // host → new client: JSON snapshot of world entities
	// Entity replication
	HAZARD_SPAWN        = 30,
	HAZARD_DESPAWN      = 31,
	BULLET_SPAWN        = 32,
	BULLET_DESPAWN      = 33,
	COLLECTIBLE_SPAWN   = 34,
	COLLECTIBLE_PICKUP  = 35,
	WORLD_TICK          = 36,  // host → clients: u32 director_tick for deterministic spawns
	// Reconnect / chat / spectator
	REJOIN_REQUEST      = 40,  // client → host: u64 steamID
	CHAT_MESSAGE        = 50,  // both directions: u64 sender | string text
	PLAYER_SPECTATOR    = 51,  // host → clients: u64 steamID | u8 is_spectator
	// Legacy spawn IDs (kept for back-compat in this protocol version)
	SPAWN_OTHER         = 97,  // server → clients: a peer has joined; includes their steamID + start pos
	SPAWN_SELF          = 98,  // server → new client: where the joining player should spawn
	SYNC_PLAYERS        = 99   // server → new client: full JSON player-list snapshot
}

// Match-end reason codes used by MATCH_END payloads.
enum MATCH_END_REASON {
	COMPLETE  = 0,   // normal end (results valid, reward report allowed)
	HOST_LEFT = 1,   // host crashed / left mid-match
	TIMEOUT   = 2,   // connection timeout
	ABORT     = 3    // user-cancelled or error
}

// Build tag — used in HELLO; any client value that differs from host's
// triggers a soft warning (logged) but does not refuse the join (the
// protocol version is the hard gate).
#macro NET_BUILD_TAG 20260520
function mp_debug_log_path() {
	var _file_name = "mp_multiplayer_debug.log"
	var _base_path = ""

	if (variable_global_exists("working_directory")) {
		_base_path = variable_global_get("working_directory")
	} else if (variable_global_exists("save_directory")) {
		_base_path = variable_global_get("save_directory")
	}

	if (is_string(_base_path) && string_length(_base_path) > 0) {
		var _last_char = string_char_at(_base_path, string_length(_base_path))
		if ((_last_char != "/") && (_last_char != "\\")) {
			_base_path = _base_path + "/"
		}
		return _base_path + _file_name
	}

	return _file_name
}

function mp_debug_init(_enabled=true) {
	global.mp_debug = {
		enabled : (_enabled == true),
		path    : mp_debug_log_path(),
		seq     : 0
	}

	var _f = file_text_open_write(global.mp_debug.path)
	file_text_write_string(_f, "=== mp debug session start ===")
	file_text_writeln(_f)
	file_text_close(_f)

	show_debug_message("[mp-debug] log path: " + global.mp_debug.path)
}

function mp_debug_log(_tag, _msg) {
	if !variable_global_exists("mp_debug") then return
	if !is_struct(global.mp_debug) then return
	if global.mp_debug.enabled != true then return

	global.mp_debug.seq = global.mp_debug.seq + 1
	var _room_name = room_get_name(room)
	var _line = string(global.mp_debug.seq)
		+ "|" + string(current_time)
		+ "|" + _room_name
		+ "|" + string(_tag)
		+ "|" + string(_msg)

	show_debug_message("[mp-debug] " + _line)

	var _f = file_text_open_append(global.mp_debug.path)
	file_text_write_string(_f, _line)
	file_text_writeln(_f)
	file_text_close(_f)
}

function crash_log_path() {
	var _file_name = "runtime_crash.log"
	var _base_path = ""

	if (variable_global_exists("working_directory")) {
		_base_path = variable_global_get("working_directory")
	} else if (variable_global_exists("save_directory")) {
		_base_path = variable_global_get("save_directory")
	}

	if (is_string(_base_path) && string_length(_base_path) > 0) {
		var _last_char = string_char_at(_base_path, string_length(_base_path))
		if ((_last_char != "/") && (_last_char != "\\")) {
			_base_path = _base_path + "/"
		}
		return _base_path + _file_name
	}

	return _file_name
}

function crash_log_timestamp() {
	return string(current_year) + "-"
		+ string_replace(string_format(current_month, 2, 0), " ", "0") + "-"
		+ string_replace(string_format(current_day, 2, 0), " ", "0") + " "
		+ string_replace(string_format(current_hour, 2, 0), " ", "0") + ":"
		+ string_replace(string_format(current_minute, 2, 0), " ", "0") + ":"
		+ string_replace(string_format(current_second, 2, 0), " ", "0")
}

function crash_log_write_line(_file, _line) {
	file_text_write_string(_file, string(_line))
	file_text_writeln(_file)
}

function crash_log_unhandled_exception(_ex) {
	var _path = crash_log_path()
	var _f = file_text_open_append(_path)

	crash_log_write_line(_f, "=== unhandled exception ===")
	crash_log_write_line(_f, "timestamp: " + crash_log_timestamp())
	crash_log_write_line(_f, "room: " + room_get_name(room))

	if (variable_global_exists("mp_debug") && is_struct(global.mp_debug)) {
		crash_log_write_line(_f, "mp_log_path: " + string(global.mp_debug.path))
		crash_log_write_line(_f, "mp_log_seq: " + string(global.mp_debug.seq))
	}

	if (is_struct(_ex)) {
		if (variable_struct_exists(_ex, "message")) {
			crash_log_write_line(_f, "message: " + string(_ex.message))
		}
		if (variable_struct_exists(_ex, "longMessage")) {
			crash_log_write_line(_f, "longMessage: " + string(_ex.longMessage))
		}
		if (variable_struct_exists(_ex, "script")) {
			crash_log_write_line(_f, "script: " + string(_ex.script))
		}
		if (variable_struct_exists(_ex, "line")) {
			crash_log_write_line(_f, "line: " + string(_ex.line))
		}
		if (variable_struct_exists(_ex, "stacktrace") && is_array(_ex.stacktrace)) {
			crash_log_write_line(_f, "stacktrace:")
			for (var _i = 0; _i < array_length(_ex.stacktrace); _i++) {
				crash_log_write_line(_f, "  [" + string(_i) + "] " + string(_ex.stacktrace[_i]))
			}
		}
	} else {
		crash_log_write_line(_f, "exception: " + string(_ex))
	}

	crash_log_write_line(_f, "")
	file_text_close(_f)

	show_debug_message("[crash-log] wrote unhandled exception to " + _path)
	return 1
}

function crash_log_install() {
	global.crash_log_path = crash_log_path()
	global.previous_exception_handler = exception_unhandled_handler(crash_log_unhandled_exception)
	show_debug_message("[crash-log] installed unhandled exception handler at " + global.crash_log_path)
}

function mp_debug_packet_name(_type) {
	switch (_type) {
		case NETWORK_PACKETS.HELLO:               return "HELLO"
		case NETWORK_PACKETS.HELLO_ACK:           return "HELLO_ACK"
		case NETWORK_PACKETS.KICK_VERSION:        return "KICK_VERSION"
		case NETWORK_PACKETS.HEARTBEAT:           return "HEARTBEAT"
		case NETWORK_PACKETS.CLIENT_PLAYER_INPUT: return "CLIENT_PLAYER_INPUT"
		case NETWORK_PACKETS.SERVER_PLAYER_INPUT: return "SERVER_PLAYER_INPUT"
		case NETWORK_PACKETS.PLAYER_POSITION:     return "PLAYER_POSITION"
		case NETWORK_PACKETS.PLAYER_HEALTH:       return "PLAYER_HEALTH"
		case NETWORK_PACKETS.PLAYER_COLOR:        return "PLAYER_COLOR"
		case NETWORK_PACKETS.CLIENT_SPAWN_RESYNC: return "CLIENT_SPAWN_RESYNC"
		case NETWORK_PACKETS.MATCH_START:         return "MATCH_START"
		case NETWORK_PACKETS.MATCH_START_ACK:     return "MATCH_START_ACK"
		case NETWORK_PACKETS.MATCH_END:           return "MATCH_END"
		case NETWORK_PACKETS.ROOM_CHANGE:         return "ROOM_CHANGE"
		case NETWORK_PACKETS.CLIENT_READY:        return "CLIENT_READY"
		case NETWORK_PACKETS.LOBBY_STATE:         return "LOBBY_STATE"
		case NETWORK_PACKETS.WORLD_SNAPSHOT:      return "WORLD_SNAPSHOT"
		case NETWORK_PACKETS.HAZARD_SPAWN:        return "HAZARD_SPAWN"
		case NETWORK_PACKETS.HAZARD_DESPAWN:      return "HAZARD_DESPAWN"
		case NETWORK_PACKETS.BULLET_SPAWN:        return "BULLET_SPAWN"
		case NETWORK_PACKETS.BULLET_DESPAWN:      return "BULLET_DESPAWN"
		case NETWORK_PACKETS.COLLECTIBLE_SPAWN:   return "COLLECTIBLE_SPAWN"
		case NETWORK_PACKETS.COLLECTIBLE_PICKUP:  return "COLLECTIBLE_PICKUP"
		case NETWORK_PACKETS.WORLD_TICK:          return "WORLD_TICK"
		case NETWORK_PACKETS.REJOIN_REQUEST:      return "REJOIN_REQUEST"
		case NETWORK_PACKETS.CHAT_MESSAGE:        return "CHAT_MESSAGE"
		case NETWORK_PACKETS.PLAYER_SPECTATOR:    return "PLAYER_SPECTATOR"
		case NETWORK_PACKETS.SPAWN_OTHER:         return "SPAWN_OTHER"
		case NETWORK_PACKETS.SPAWN_SELF:          return "SPAWN_SELF"
		case NETWORK_PACKETS.SYNC_PLAYERS:        return "SYNC_PLAYERS"
	}
	return "UNKNOWN_" + string(_type)
}

// ---------------------------------------------------------------------------
// Buffer safe-read helpers (Phase 1.2)
// ---------------------------------------------------------------------------
// Returns the size in bytes of a buffer_* type constant. Mirrors GameMaker's
// internal sizes; used by mp_buffer_safe_read to validate remaining bytes
// before attempting a read.
function mp_buffer_type_size(_type) {
	switch (_type) {
		case buffer_u8:  case buffer_s8:  case buffer_bool: return 1
		case buffer_u16: case buffer_s16: case buffer_f16:  return 2
		case buffer_u32: case buffer_s32: case buffer_f32:  return 4
		case buffer_u64: case buffer_f64:                   return 8
	}
	return 0   // strings / unknown → caller must use try-catch
}

// Safely extracts a printable message from a caught exception struct.
function mp_exception_message(_ex) {
	if (is_struct(_ex) && variable_struct_exists(_ex, "message")) {
		return string(_ex[$ "message"])
	}
	return string(_ex)
}

// Reads a value from _buf if at least _required bytes remain; otherwise
// returns _default and logs the underrun. Returns the typed value on success.
function mp_buffer_safe_read(_buf, _type, _default=undefined) {
	if !buffer_exists(_buf) then return _default
	var _need = mp_buffer_type_size(_type)
	if (_need > 0) {
		var _have = buffer_get_size(_buf) - buffer_tell(_buf)
		if (_have < _need) {
			mp_debug_log("packet-underrun", "type=" + string(_type) + " need=" + string(_need) + " have=" + string(_have))
			return _default
		}
	}
	try {
		return buffer_read(_buf, _type)
	} catch (_ex) {
		mp_debug_log("packet-read-exception", "type=" + string(_type) + " msg=" + mp_exception_message(_ex))
		return _default
	}
}

// Wraps a packet-handler callback in a try/catch and drops the packet
// (logging) on any exception. Use from packet dispatchers.
function mp_safe_dispatch(_packet_type, _sender, _handler) {
	try {
		_handler()
	} catch (_ex) {
		mp_debug_log("packet-dispatch-exception",
			"type=" + mp_debug_packet_name(_packet_type)
			+ " sender=" + string(_sender)
			+ " msg=" + mp_exception_message(_ex)
		)
	}
}

// ---------------------------------------------------------------------------
// Sequence numbers for high-frequency state packets (Phase 1.3)
// ---------------------------------------------------------------------------
// Per-recipient outgoing sequence counter (server-side).
//   global.mp_seq_out[recipient_steam_id] -> int
// Per-sender incoming sequence high-water mark per packet type (client-side).
//   global.mp_seq_in[sender_steam_id][packet_type] -> int
function mp_seq_init() {
	if !variable_global_exists("mp_seq_out") then global.mp_seq_out = {}
	if !variable_global_exists("mp_seq_in")  then global.mp_seq_in  = {}
}

function mp_seq_next(_recipient_steam_id) {
	mp_seq_init()
	var _key = string(_recipient_steam_id)
	var _cur = variable_struct_exists(global.mp_seq_out, _key) ? global.mp_seq_out[$ _key] : 0
	_cur = (_cur + 1) & 0xFFFF
	global.mp_seq_out[$ _key] = _cur
	return _cur
}

// Returns true if _seq is newer than the last seen for (sender, packet_type),
// allowing for u16 wraparound. Updates the high-water mark on accept.
function mp_seq_accept(_sender_steam_id, _packet_type, _seq) {
	mp_seq_init()
	var _sk = string(_sender_steam_id)
	if !variable_struct_exists(global.mp_seq_in, _sk) {
		global.mp_seq_in[$ _sk] = {}
	}
	var _per = global.mp_seq_in[$ _sk]
	var _tk = string(_packet_type)
	if !variable_struct_exists(_per, _tk) {
		_per[$ _tk] = _seq
		return true
	}
	var _last = _per[$ _tk]
	// Wraparound-aware: accept if (_seq - _last) mod 65536 is in (0, 32768).
	var _delta = (_seq - _last) & 0xFFFF
	if (_delta == 0) return false   // duplicate
	if (_delta > 32768) {
		// Out-of-order older packet — drop.
		mp_debug_log("packet-stale", "type=" + string(_packet_type) + " sender=" + string(_sender_steam_id) + " seq=" + string(_seq) + " last=" + string(_last))
		return false
	}
	_per[$ _tk] = _seq
	return true
}

// Clears all sequence state — call on lobby leave / new match.
function mp_seq_reset() {
	global.mp_seq_out = {}
	global.mp_seq_in  = {}
}
