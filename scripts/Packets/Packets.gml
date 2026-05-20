
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
enum NETWORK_PACKETS {
	CLIENT_PLAYER_INPUT = 10,  // client → server: xInput, yInput, runKey, actionKey, mouseAngle
	SERVER_PLAYER_INPUT = 11,  // server → clients: same fields plus steamID of the player
	PLAYER_POSITION     = 12,  // server → clients: steamID + x + y (u16 each)
	PLAYER_HEALTH       = 13,  // server → clients: steamID + current health
	PLAYER_COLOR        = 14,  // client → server (u32 color); server → clients (u64 steamID + u32 color)
	CLIENT_SPAWN_RESYNC = 15,  // client → server: request SYNC_PLAYERS + SPAWN_SELF replay
	SPAWN_OTHER         = 97,  // server → clients: a peer has joined; includes their steamID + start pos
	SPAWN_SELF          = 98,  // server → new client: where the joining player should spawn
	SYNC_PLAYERS        = 99   // server → new client: full JSON player-list snapshot
}
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
		case NETWORK_PACKETS.CLIENT_PLAYER_INPUT: return "CLIENT_PLAYER_INPUT"
		case NETWORK_PACKETS.SERVER_PLAYER_INPUT: return "SERVER_PLAYER_INPUT"
		case NETWORK_PACKETS.PLAYER_POSITION:     return "PLAYER_POSITION"
		case NETWORK_PACKETS.PLAYER_HEALTH:       return "PLAYER_HEALTH"
		case NETWORK_PACKETS.PLAYER_COLOR:        return "PLAYER_COLOR"
			case NETWORK_PACKETS.CLIENT_SPAWN_RESYNC: return "CLIENT_SPAWN_RESYNC"
		case NETWORK_PACKETS.SPAWN_OTHER:         return "SPAWN_OTHER"
		case NETWORK_PACKETS.SPAWN_SELF:          return "SPAWN_SELF"
		case NETWORK_PACKETS.SYNC_PLAYERS:        return "SYNC_PLAYERS"
	}
	return "UNKNOWN_" + string(_type)
}
