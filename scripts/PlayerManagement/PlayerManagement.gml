// Shared player management utilities used by both obj_Server and obj_Client.
// Covers spawn-point lookup, network packet serialisation / deserialisation,
// player search, and position broadcasting.

// Returns the world-space {x, y} of the spawn point assigned to _player
// (the spawn point instance index, matching the player's lobby slot).
// Falls back to {x:0, y:0} if no matching spawn point exists in the room.
function grab_spawn_point(_player) {
	var _spawnPoint = instance_find(obj_SpawnPoint, _player)
	if _spawnPoint == noone return {x:0, y:0};
	return {x:_spawnPoint.x, y:_spawnPoint.y}
}

// Leaves any active Steam lobby and tears down multiplayer objects/UI.
// Call this before transitioning to menus or exiting the game.
function shutdown_multiplayer(_reason="manual") {
	mp_debug_log("lobby-leave", "reason=" + string(_reason))

	// Phase 3.3: if we're the host and a match is active, give peers a clean
	// MATCH_END before tearing down so they can show a results screen instead
	// of timing out into "Host left".
	mp_match_state_init()
	if (instance_exists(obj_Server) && global.mp_match.active) {
		var _end_reason = (_reason == "match_complete") ? MATCH_END_REASON.COMPLETE : MATCH_END_REASON.HOST_LEFT
		with (obj_Server) send_match_end(_end_reason)
	}

	steam_lobby_leave()

	if instance_exists(obj_Client) {
		with (obj_Client) instance_destroy()
	}

	if instance_exists(obj_Server) {
		with (obj_Server) instance_destroy()
	}

	if instance_exists(obj_Player) {
		with (obj_Player) instance_destroy()
	}

	if instance_exists(obj_LobbyItem) {
		with (obj_LobbyItem) instance_destroy()
	}

	if instance_exists(obj_LobbyList) {
		with (obj_LobbyList) instance_destroy()
	}

	mp_seq_reset()
	global.isPaused = false
}

// ---------------------------------------------------------------------------
// Protocol handshake (Phase 1.1)
// ---------------------------------------------------------------------------

///@self obj_Client
// Sends a HELLO packet to the host with this client's protocol version and
// build tag. Host replies with HELLO_ACK or KICK_VERSION.
// Packet layout: u8 type | u32 protocol_version | u32 build_tag → 9 bytes
function send_hello(_host_steam_id) {
	if (_host_steam_id == undefined || _host_steam_id <= 0) return
	var _b = buffer_create(9, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.HELLO)
	buffer_write(_b, buffer_u32, NET_PROTOCOL_VERSION)
	buffer_write(_b, buffer_u32, NET_BUILD_TAG)
	steam_net_packet_send(_host_steam_id, _b)
	buffer_delete(_b)
	mp_debug_log("hello-send", "host=" + string(_host_steam_id) + " proto=" + string(NET_PROTOCOL_VERSION) + " build=" + string(NET_BUILD_TAG))
}

///@self obj_Server
// Reads a HELLO packet, validates the client's protocol version, and replies
// with HELLO_ACK on success or KICK_VERSION on mismatch.
function receive_hello(_b, _sender) {
	var _client_proto = mp_buffer_safe_read(_b, buffer_u32, 0)
	var _client_build = mp_buffer_safe_read(_b, buffer_u32, 0)
	if (_client_proto != NET_PROTOCOL_VERSION) {
		mp_debug_log("hello-reject", "sender=" + string(_sender) + " client_proto=" + string(_client_proto) + " server_proto=" + string(NET_PROTOCOL_VERSION))
		var _k = buffer_create(9, buffer_fixed, 1)
		buffer_write(_k, buffer_u8,  NETWORK_PACKETS.KICK_VERSION)
		buffer_write(_k, buffer_u32, NET_PROTOCOL_VERSION)
		buffer_write(_k, buffer_u32, NET_BUILD_TAG)
		steam_net_packet_send(_sender, _k)
		buffer_delete(_k)
		return false
	}
	if (_client_build != NET_BUILD_TAG) {
		mp_debug_log("hello-build-mismatch", "sender=" + string(_sender) + " client=" + string(_client_build) + " server=" + string(NET_BUILD_TAG))
	}
	var _a = buffer_create(5, buffer_fixed, 1)
	buffer_write(_a, buffer_u8,  NETWORK_PACKETS.HELLO_ACK)
	buffer_write(_a, buffer_u32, NET_PROTOCOL_VERSION)
	steam_net_packet_send(_sender, _a)
	buffer_delete(_a)
	mp_debug_log("hello-ack", "sender=" + string(_sender))
	return true
}

///@self obj_Client
// Reads a KICK_VERSION packet and stores the mismatch reason for UI display.
// Triggers shutdown_multiplayer so the user lands back at the main menu.
function receive_kick_version(_b) {
	var _server_proto = mp_buffer_safe_read(_b, buffer_u32, 0)
	var _server_build = mp_buffer_safe_read(_b, buffer_u32, 0)
	global.mp_last_kick_reason = {
		kind          : "version_mismatch",
		server_proto  : _server_proto,
		server_build  : _server_build,
		client_proto  : NET_PROTOCOL_VERSION,
		client_build  : NET_BUILD_TAG
	}
	mp_debug_log("kick-version", "server_proto=" + string(_server_proto) + " client_proto=" + string(NET_PROTOCOL_VERSION))
	shutdown_multiplayer("kick_version")
}

// ---------------------------------------------------------------------------
// Phase 2: Liveness / heartbeat / timeout
// ---------------------------------------------------------------------------
// `global.mp_last_seen[steam_id]` -> current_time of last packet from that
// peer. Updated on every received packet (any type) via mp_touch_peer.
#macro MP_HEARTBEAT_INTERVAL_MS 2000
#macro MP_PEER_TIMEOUT_MS       10000
#macro MP_SPAWN_RESYNC_MAX_ATTEMPTS 15
// Phase 5: window during which a disconnected slot is reserved for the same
// steamID to rejoin and have its position/health restored. After expiry the
// entry is removed and the player gets a fresh slot on next join.
#macro MP_REJOIN_GRACE_MS       30000
// Phase 7.1: position delta compression. Skip a PLAYER_POSITION broadcast if
// the player has moved less than MP_POS_MIN_DELTA_PX since their last sent
// position, unless MP_POS_FORCE_MS has elapsed (keep-alive for late joiners).
#macro MP_POS_MIN_DELTA_PX 2
#macro MP_POS_FORCE_MS     500

function mp_liveness_init() {
	if !variable_global_exists("mp_last_seen") then global.mp_last_seen = {}
}

function mp_touch_peer(_steam_id) {
	if (_steam_id == undefined || _steam_id <= 0) return
	mp_liveness_init()
	global.mp_last_seen[$ string(_steam_id)] = current_time
}

function mp_last_seen_ms(_steam_id) {
	mp_liveness_init()
	var _k = string(_steam_id)
	if !variable_struct_exists(global.mp_last_seen, _k) return undefined
	return global.mp_last_seen[$ _k]
}

function mp_peer_timed_out(_steam_id) {
	var _t = mp_last_seen_ms(_steam_id)
	if (_t == undefined) return false   // never seen → caller decides
	return (current_time - _t) > MP_PEER_TIMEOUT_MS
}

// Sends a 1-byte HEARTBEAT packet to _steam_id.
function send_heartbeat(_steam_id) {
	if (_steam_id == undefined || _steam_id <= 0) return
	var _b = buffer_create(1, buffer_fixed, 1)
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.HEARTBEAT)
	steam_net_packet_send(_steam_id, _b)
	buffer_delete(_b)
}

///@self obj_Server
// Sends a heartbeat to every connected (non-host, non-disconnected) peer.
function send_heartbeat_to_peers() {
	for (var _i = 0; _i < array_length(playerList); _i++) {
		var _p = playerList[_i]
		if _p.steamID == steamID then continue
		if variable_struct_exists(_p, "disconnected") && _p.disconnected then continue
		send_heartbeat(_p.steamID)
	}
}

///@self obj_Server
// Scans peers for timeout; returns array of steam IDs that have gone silent.
function find_timed_out_peers() {
	var _out = []
	for (var _i = 0; _i < array_length(playerList); _i++) {
		var _p = playerList[_i]
		if _p.steamID == steamID then continue
		if variable_struct_exists(_p, "disconnected") && _p.disconnected then continue
		if mp_peer_timed_out(_p.steamID) then array_push(_out, _p.steamID)
	}
	return _out
}

// ---------------------------------------------------------------------------
// Phase 3: Match lifecycle (ready / start / end / room transition)
// ---------------------------------------------------------------------------
#macro MP_MATCH_START_ACK_TIMEOUT_MS 5000

function mp_match_state_init() {
	if !variable_global_exists("mp_match") {
		global.mp_match = {
			active        : false,
			seed          : 0,
			tick          : 0,
			mode          : 0,
			room_index    : -1,
			start_time    : 0,
			start_acked   : {},
			waiting_acks  : false,
			ack_deadline  : 0
		}
	}
}

///@self obj_Client
// Tells the host whether this client is ready to start.
// Packet: u8 type | u8 ready  → 2 bytes
function send_client_ready(_ready) {
	if (lobbyHost <= 0) return
	var _b = buffer_create(2, buffer_fixed, 1)
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.CLIENT_READY)
	buffer_write(_b, buffer_u8, _ready ? 1 : 0)
	steam_net_packet_send(lobbyHost, _b)
	buffer_delete(_b)
	mp_debug_log("client-ready-send", "ready=" + string(_ready))
}

///@self obj_Server
function receive_client_ready(_b, _sender) {
	var _ready = mp_buffer_safe_read(_b, buffer_u8, 0)
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == _sender {
			playerList[_i].ready = (_ready == 1)
			break
		}
	}
	send_lobby_state()
}

///@self obj_Server
// Broadcasts a LOBBY_STATE packet (JSON list of {steamID, ready, steamName}).
// Packet: u8 type | string json
function send_lobby_state() {
	var _list = []
	for (var _i = 0; _i < array_length(playerList); _i++) {
		array_push(_list, {
			steamID  : playerList[_i].steamID,
			steamName: playerList[_i].steamName,
			ready    : variable_struct_exists(playerList[_i], "ready") ? playerList[_i].ready : false
		})
	}
	var _json = json_stringify(_list)
	var _b = buffer_create(1, buffer_grow, 1)
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.LOBBY_STATE)
	buffer_write(_b, buffer_string, _json)
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == steamID then continue
		if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
		steam_net_packet_send(playerList[_i].steamID, _b)
	}
	buffer_delete(_b)
}

///@self obj_Client
function receive_lobby_state(_b) {
	var _json = buffer_read(_b, buffer_string)
	global.mp_lobby_state = json_parse(_json)
	mp_debug_log("client-lobby-state", "count=" + string(array_length(global.mp_lobby_state)))
}

///@self obj_Server
// Returns true if every non-host non-disconnected player is ready.
function lobby_all_ready() {
	var _any = false
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == steamID then continue
		if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
		_any = true
		if !(variable_struct_exists(playerList[_i], "ready") && playerList[_i].ready) return false
	}
	return _any   // false when there are no other peers at all
}

///@self obj_Server
// Broadcasts MATCH_START with mode, map (room name), and director seed.
// Packet: u8 type | u32 mode | u32 seed | u32 tick0 | string map_name
function send_match_start(_mode, _map_name, _seed) {
	mp_match_state_init()
	global.mp_match.active        = true
	global.mp_match.seed          = _seed
	global.mp_match.tick          = 0
	global.mp_match.mode          = _mode
	global.mp_match.start_time    = current_time
	global.mp_match.start_acked   = {}
	global.mp_match.waiting_acks  = true
	global.mp_match.ack_deadline  = current_time + MP_MATCH_START_ACK_TIMEOUT_MS
	var _b = buffer_create(64, buffer_grow, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.MATCH_START)
	buffer_write(_b, buffer_u32, _mode)
	buffer_write(_b, buffer_u32, _seed)
	buffer_write(_b, buffer_u32, 0)               // tick0
	buffer_write(_b, buffer_string, _map_name)
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == steamID then continue
		if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
		steam_net_packet_send(playerList[_i].steamID, _b)
	}
	buffer_delete(_b)
	mp_debug_log("server-match-start", "mode=" + string(_mode) + " seed=" + string(_seed) + " map=" + string(_map_name))
}

///@self obj_Client
function receive_match_start(_b) {
	mp_match_state_init()
	var _mode = mp_buffer_safe_read(_b, buffer_u32, 0)
	var _seed = mp_buffer_safe_read(_b, buffer_u32, 0)
	var _tick = mp_buffer_safe_read(_b, buffer_u32, 0)
	var _map  = ""
	try { _map = buffer_read(_b, buffer_string) } catch (_e) { _map = "" }
	global.mp_match.active     = true
	global.mp_match.seed       = _seed
	global.mp_match.tick       = _tick
	global.mp_match.mode       = _mode
	global.mp_match.start_time = current_time
	random_set_seed(_seed)
	mp_debug_log("client-match-start", "mode=" + string(_mode) + " seed=" + string(_seed) + " map=" + _map)
	// Ack back so the host knows we're live.
	if (lobbyHost > 0) {
		var _a = buffer_create(1, buffer_fixed, 1)
		buffer_write(_a, buffer_u8, NETWORK_PACKETS.MATCH_START_ACK)
		steam_net_packet_send(lobbyHost, _a)
		buffer_delete(_a)
	}
}

///@self obj_Server
function receive_match_start_ack(_sender) {
	mp_match_state_init()
	global.mp_match.start_acked[$ string(_sender)] = current_time
	mp_debug_log("server-match-start-ack", "from=" + string(_sender))
}

///@self obj_Server
// Sends MATCH_END to every peer.
// Packet: u8 type | u8 reason | string results_json
function send_match_end(_reason, _results=undefined) {
	mp_match_state_init()
	var _results_json = (_results == undefined) ? "{}" : json_stringify(_results)
	var _b = buffer_create(1, buffer_grow, 1)
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.MATCH_END)
	buffer_write(_b, buffer_u8, _reason)
	buffer_write(_b, buffer_string, _results_json)
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == steamID then continue
		if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
		steam_net_packet_send(playerList[_i].steamID, _b)
	}
	buffer_delete(_b)
	global.mp_match.active = false
	// Only report match-complete to the SGC backend on a clean COMPLETE end.
	if (_reason == MATCH_END_REASON.COMPLETE) {
		try { sgc_gateway_match_close() } catch (_ex) { mp_debug_log("sgc-close-failed", mp_exception_message(_ex)) }
	}
	mp_debug_log("server-match-end", "reason=" + string(_reason))
}

///@self obj_Client
function receive_match_end(_b) {
	mp_match_state_init()
	var _reason = mp_buffer_safe_read(_b, buffer_u8, MATCH_END_REASON.ABORT)
	var _json   = ""
	try { _json = buffer_read(_b, buffer_string) } catch (_e) { _json = "{}" }
	var _results = undefined
	try { _results = json_parse(_json) } catch (_e) { _results = undefined }
	global.mp_match.active = false
	global.mp_last_match_end = { reason: _reason, results: _results }
	mp_debug_log("client-match-end", "reason=" + string(_reason))
}

///@self obj_Server
// Broadcasts a ROOM_CHANGE packet so all clients follow the host's room.
// Packet: u8 type | u32 room_asset_index
function send_room_change(_room_index) {
	var _b = buffer_create(5, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.ROOM_CHANGE)
	buffer_write(_b, buffer_u32, _room_index)
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == steamID then continue
		if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
		steam_net_packet_send(playerList[_i].steamID, _b)
	}
	buffer_delete(_b)
	mp_debug_log("server-room-change", "room=" + string(_room_index))
}

///@self obj_Client
function receive_room_change(_b) {
	var _room_index = mp_buffer_safe_read(_b, buffer_u32, -1)
	if (_room_index < 0) return
	if (room != _room_index) {
		mp_debug_log("client-room-change", "from=" + string(room) + " to=" + string(_room_index))
		room_goto(_room_index)
	}
}

// ---------------------------------------------------------------------------
// Phase 4: Entity replication (bullets / hazards / collectibles / world tick)
// ---------------------------------------------------------------------------
// Each replicated entity carries an `mp_id` instance var (u32). On the host
// this is assigned at spawn and broadcast in a SPAWN packet; clients spawn
// the matching instance with the same id. On host destroy, a DESPAWN packet
// removes the matching instance on every client.
enum ENTITY_KIND {
	HAZARD      = 1,
	BULLET      = 2,
	COLLECTIBLE = 3
}

function mp_entities_init() {
	if !variable_global_exists("mp_entity_next_id") then global.mp_entity_next_id = 1
	if !variable_global_exists("mp_entity_map")     then global.mp_entity_map = {}
}

// Returns true when this peer is the host (authoritative spawn point).
function mp_is_host() {
	return instance_exists(obj_Server)
}

// Returns true if multiplayer is active (either role).
function mp_is_active() {
	return instance_exists(obj_Server) || instance_exists(obj_Client)
}

// Allocates a fresh u32 entity id (host-only).
function mp_alloc_entity_id() {
	mp_entities_init()
	var _id = global.mp_entity_next_id
	global.mp_entity_next_id = (_id + 1) & 0xFFFFFFFF
	if (global.mp_entity_next_id == 0) global.mp_entity_next_id = 1
	return _id
}

function mp_register_entity(_mp_id, _inst) {
	mp_entities_init()
	global.mp_entity_map[$ string(_mp_id)] = _inst
}

function mp_lookup_entity(_mp_id) {
	mp_entities_init()
	var _k = string(_mp_id)
	if !variable_struct_exists(global.mp_entity_map, _k) return noone
	var _i = global.mp_entity_map[$ _k]
	if !instance_exists(_i) {
		variable_struct_remove(global.mp_entity_map, _k)
		return noone
	}
	return _i
}

function mp_unregister_entity(_mp_id) {
	mp_entities_init()
	variable_struct_remove(global.mp_entity_map, string(_mp_id))
}

// ---- Hazard ---------------------------------------------------------------
// Packet HAZARD_SPAWN: u8 type | u32 mp_id | s32 x | s32 y
function mp_send_hazard_spawn(_inst) {
	if !mp_is_host() return
	var _b = buffer_create(13, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.HAZARD_SPAWN)
	buffer_write(_b, buffer_u32, _inst.mp_id)
	buffer_write(_b, buffer_s32, _inst.x)
	buffer_write(_b, buffer_s32, _inst.y)
	with (obj_Server) {
		for (var _i = 0; _i < array_length(playerList); _i++) {
			if playerList[_i].steamID == steamID then continue
			if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
			steam_net_packet_send(playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b)
}

function mp_receive_hazard_spawn(_b) {
	var _id = mp_buffer_safe_read(_b, buffer_u32)
	var _x  = mp_buffer_safe_read(_b, buffer_s32)
	var _y  = mp_buffer_safe_read(_b, buffer_s32)
	if (_id == undefined) return
	if (mp_lookup_entity(_id) != noone) return  // duplicate
	var _inst = instance_create_layer(_x, _y, "Instances", obj_RunnerHazard)
	_inst.mp_id = _id
	mp_register_entity(_id, _inst)
}

// ---- Bullet ---------------------------------------------------------------
// Packet BULLET_SPAWN: u8 type | u32 mp_id | s32 x | s32 y | s16 direction | u64 owner_steam_id
function mp_send_bullet_spawn(_inst) {
	if !mp_is_host() return
	var _b = buffer_create(21, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.BULLET_SPAWN)
	buffer_write(_b, buffer_u32, _inst.mp_id)
	buffer_write(_b, buffer_s32, _inst.x)
	buffer_write(_b, buffer_s32, _inst.y)
	buffer_write(_b, buffer_s16, _inst.direction)
	buffer_write(_b, buffer_u64, variable_instance_exists(_inst, "owner_steam_id") ? _inst.owner_steam_id : 0)
	with (obj_Server) {
		for (var _i = 0; _i < array_length(playerList); _i++) {
			if playerList[_i].steamID == steamID then continue
			if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
			steam_net_packet_send(playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b)
}

function mp_receive_bullet_spawn(_b) {
	var _id  = mp_buffer_safe_read(_b, buffer_u32)
	var _x   = mp_buffer_safe_read(_b, buffer_s32)
	var _y   = mp_buffer_safe_read(_b, buffer_s32)
	var _dir = mp_buffer_safe_read(_b, buffer_s16)
	var _own = mp_buffer_safe_read(_b, buffer_u64)
	if (_id == undefined) return
	if (mp_lookup_entity(_id) != noone) return
	var _inst = instance_create_layer(_x, _y, "Instances", obj_Bullet)
	_inst.mp_id          = _id
	_inst.direction      = _dir
	_inst.image_angle    = _dir
	_inst.owner_steam_id = _own
	mp_register_entity(_id, _inst)
}

// ---- Collectible ----------------------------------------------------------
// Packet COLLECTIBLE_SPAWN: u8 type | u32 mp_id | s32 x | s32 y | u32 sgcAmount | string code
function mp_send_collectible_spawn(_inst) {
	if !mp_is_host() return
	var _code = variable_instance_exists(_inst, "collectibleCode") ? string(_inst.collectibleCode) : ""
	var _b = buffer_create(64, buffer_grow, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.COLLECTIBLE_SPAWN)
	buffer_write(_b, buffer_u32, _inst.mp_id)
	buffer_write(_b, buffer_s32, _inst.x)
	buffer_write(_b, buffer_s32, _inst.y)
	buffer_write(_b, buffer_u32, _inst.sgcAmount)
	buffer_write(_b, buffer_string, _code)
	with (obj_Server) {
		for (var _i = 0; _i < array_length(playerList); _i++) {
			if playerList[_i].steamID == steamID then continue
			if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
			steam_net_packet_send(playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b)
}

function mp_receive_collectible_spawn(_b) {
	var _id  = mp_buffer_safe_read(_b, buffer_u32)
	var _x   = mp_buffer_safe_read(_b, buffer_s32)
	var _y   = mp_buffer_safe_read(_b, buffer_s32)
	var _amt = mp_buffer_safe_read(_b, buffer_u32, 1)
	var _code = ""
	try { _code = buffer_read(_b, buffer_string) } catch (_e) { _code = "" }
	if (_id == undefined) return
	if (mp_lookup_entity(_id) != noone) return
	var _inst = instance_create_layer(_x, _y, "Instances", obj_SGCCollectible)
	_inst.mp_id           = _id
	_inst.sgcAmount       = _amt
	_inst.collectibleCode = _code
	mp_register_entity(_id, _inst)
}

// ---- Despawn (works for any kind) -----------------------------------------
// Packet HAZARD_DESPAWN / BULLET_DESPAWN / COLLECTIBLE_PICKUP: u8 type | u32 mp_id
function mp_send_entity_despawn(_packet_type, _mp_id) {
	var _b = buffer_create(5, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  _packet_type)
	buffer_write(_b, buffer_u32, _mp_id)
	with (obj_Server) {
		for (var _i = 0; _i < array_length(playerList); _i++) {
			if playerList[_i].steamID == steamID then continue
			if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
			steam_net_packet_send(playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b)
}

function mp_receive_entity_despawn(_b) {
	var _id = mp_buffer_safe_read(_b, buffer_u32)
	if (_id == undefined) return
	var _inst = mp_lookup_entity(_id)
	if (_inst != noone && instance_exists(_inst)) {
		with (_inst) instance_destroy()
	}
	mp_unregister_entity(_id)
}

// ---- Authoritative-spawn wrapper ------------------------------------------
// Call this AFTER instance_create_layer when the host has just spawned a
// replicated entity. Sets mp_id, registers the instance, and broadcasts.
// On clients (non-host) this is a no-op so the same call site can be reused.
function mp_replicate_spawn(_inst, _kind) {
	if (_inst == noone) return
	// Always tag with an mp_id field so destroy hooks can find it locally,
	// even in single-player.
	if !variable_instance_exists(_inst, "mp_id") then _inst.mp_id = 0
	if !mp_is_host() return
	_inst.mp_id = mp_alloc_entity_id()
	mp_register_entity(_inst.mp_id, _inst)
	switch (_kind) {
		case ENTITY_KIND.HAZARD:      mp_send_hazard_spawn(_inst); break
		case ENTITY_KIND.BULLET:      mp_send_bullet_spawn(_inst); break
		case ENTITY_KIND.COLLECTIBLE: mp_send_collectible_spawn(_inst); break
	}
}

// Call this in the destroy event of a replicated entity, on the host, so all
// clients also destroy their copy.
function mp_replicate_despawn(_inst, _kind) {
	if !mp_is_host() return
	if !variable_instance_exists(_inst, "mp_id") return
	if (_inst.mp_id == 0) return
	var _packet = NETWORK_PACKETS.HAZARD_DESPAWN
	switch (_kind) {
		case ENTITY_KIND.HAZARD:      _packet = NETWORK_PACKETS.HAZARD_DESPAWN; break
		case ENTITY_KIND.BULLET:      _packet = NETWORK_PACKETS.BULLET_DESPAWN; break
		case ENTITY_KIND.COLLECTIBLE: _packet = NETWORK_PACKETS.COLLECTIBLE_PICKUP; break
	}
	mp_send_entity_despawn(_packet, _inst.mp_id)
	mp_unregister_entity(_inst.mp_id)
}

// ---- World tick (deterministic spawn pacing) ------------------------------
// Packet WORLD_TICK: u8 type | u32 director_tick
function mp_send_world_tick(_tick) {
	if !mp_is_host() return
	var _b = buffer_create(5, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.WORLD_TICK)
	buffer_write(_b, buffer_u32, _tick)
	with (obj_Server) {
		for (var _i = 0; _i < array_length(playerList); _i++) {
			if playerList[_i].steamID == steamID then continue
			if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
			steam_net_packet_send(playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b)
}

function mp_receive_world_tick(_b) {
	var _tick = mp_buffer_safe_read(_b, buffer_u32, 0)
	mp_match_state_init()
	global.mp_match.tick = _tick
}

// ---- World snapshot (Phase 4.5: late-join state) --------------------------
// Packet WORLD_SNAPSHOT: u8 type | string json
// JSON: { tick, room_index, hazards:[{id,x,y}], bullets:[{...}], collectibles:[{...}] }
function mp_collect_world_snapshot() {
	mp_match_state_init()
	var _hazards = []
	with (obj_RunnerHazard) {
		if !variable_instance_exists(id, "mp_id") || mp_id == 0 then continue
		array_push(_hazards, { id: mp_id, x: x, y: y })
	}
	var _bullets = []
	with (obj_Bullet) {
		if !variable_instance_exists(id, "mp_id") || mp_id == 0 then continue
		array_push(_bullets, { id: mp_id, x: x, y: y, dir: direction, own: variable_instance_exists(id, "owner_steam_id") ? owner_steam_id : 0 })
	}
	var _collectibles = []
	with (obj_SGCCollectible) {
		if !variable_instance_exists(id, "mp_id") || mp_id == 0 then continue
		array_push(_collectibles, { id: mp_id, x: x, y: y, amt: sgcAmount, code: variable_instance_exists(id, "collectibleCode") ? string(collectibleCode) : "" })
	}
	return {
		tick        : global.mp_match.tick,
		room_index  : room,
		hazards     : _hazards,
		bullets     : _bullets,
		collectibles: _collectibles
	}
}

///@self obj_Server
function send_world_snapshot(_steam_id) {
	var _snap = mp_collect_world_snapshot()
	var _json = json_stringify(_snap)
	var _b = buffer_create(1, buffer_grow, 1)
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.WORLD_SNAPSHOT)
	buffer_write(_b, buffer_string, _json)
	steam_net_packet_send(_steam_id, _b)
	buffer_delete(_b)
	mp_debug_log("server-world-snapshot", "to=" + string(_steam_id)
		+ " hazards=" + string(array_length(_snap.hazards))
		+ " bullets=" + string(array_length(_snap.bullets))
		+ " collectibles=" + string(array_length(_snap.collectibles)))
}

///@self obj_Client
function receive_world_snapshot(_b) {
	var _json = ""
	try { _json = buffer_read(_b, buffer_string) } catch (_e) { return }
	var _snap = undefined
	try { _snap = json_parse(_json) } catch (_e) { return }
	if (_snap == undefined) return
	mp_match_state_init()
	if variable_struct_exists(_snap, "tick") then global.mp_match.tick = _snap.tick
	// Apply hazards
	if variable_struct_exists(_snap, "hazards") {
		for (var _i = 0; _i < array_length(_snap.hazards); _i++) {
			var _h = _snap.hazards[_i]
			if (mp_lookup_entity(_h.id) != noone) continue
			var _inst = instance_create_layer(_h.x, _h.y, "Instances", obj_RunnerHazard)
			_inst.mp_id = _h.id
			mp_register_entity(_h.id, _inst)
		}
	}
	if variable_struct_exists(_snap, "bullets") {
		for (var _i = 0; _i < array_length(_snap.bullets); _i++) {
			var _bul = _snap.bullets[_i]
			if (mp_lookup_entity(_bul.id) != noone) continue
			var _inst = instance_create_layer(_bul.x, _bul.y, "Instances", obj_Bullet)
			_inst.mp_id          = _bul.id
			_inst.direction      = _bul.dir
			_inst.image_angle    = _bul.dir
			_inst.owner_steam_id = _bul.own
			mp_register_entity(_bul.id, _inst)
		}
	}
	if variable_struct_exists(_snap, "collectibles") {
		for (var _i = 0; _i < array_length(_snap.collectibles); _i++) {
			var _c = _snap.collectibles[_i]
			if (mp_lookup_entity(_c.id) != noone) continue
			var _inst = instance_create_layer(_c.x, _c.y, "Instances", obj_SGCCollectible)
			_inst.mp_id           = _c.id
			_inst.sgcAmount       = _c.amt
			_inst.collectibleCode = _c.code
			mp_register_entity(_c.id, _inst)
		}
	}
	mp_debug_log("client-world-snapshot-apply", "tick=" + string(variable_struct_exists(_snap, "tick") ? _snap.tick : -1))
}

// ---------------------------------------------------------------------------
// Phase 5: Reconnect grace window
// ---------------------------------------------------------------------------
// When a peer disconnects (lobby member-left / heartbeat timeout) we keep the
// playerList entry around for MP_REJOIN_GRACE_MS so the same steamID can
// reclaim its slot with restored position + health. Outside the window the
// slot is freed (entry removed) and the next join is treated as a fresh
// player.

///@self obj_Server
// Marks a playerList entry as disconnected, captures last known state, and
// stamps the grace window timestamp. Safe to call even if character was
// already torn down.
function mp_mark_disconnected(_entry) {
	if (!is_struct(_entry)) return
	var _last_x = (variable_struct_exists(_entry, "last_x") ? _entry.last_x : undefined)
	var _last_y = (variable_struct_exists(_entry, "last_y") ? _entry.last_y : undefined)
	if (player_entry_has_live_character(_entry)) {
		_last_x = _entry.character.x
		_last_y = _entry.character.y
		with (_entry.character) instance_destroy()
	}
	_entry.last_x = _last_x
	_entry.last_y = _last_y
	_entry.disconnected     = true
	_entry.disconnected_at  = current_time
	_entry.character        = undefined
}

///@self obj_Server
// Returns true if the disconnected entry is still inside the grace window.
function mp_rejoin_within_grace(_entry) {
	if (!is_struct(_entry)) return false
	if (!variable_struct_exists(_entry, "disconnected") || !_entry.disconnected) return false
	if (!variable_struct_exists(_entry, "disconnected_at")) return false
	return (current_time - _entry.disconnected_at) <= MP_REJOIN_GRACE_MS
}

///@self obj_Server
// Restores host-side character state after a within-grace rejoin. Must be
// called AFTER send_player_spawn has created the character instance.
function mp_apply_rejoin_state(_slot) {
	if (_slot < 0 || _slot >= array_length(playerList)) return
	var _entry = playerList[_slot]
	if (!player_entry_has_live_character(_entry)) return
	var _has_x = variable_struct_exists(_entry, "last_x") && _entry.last_x != undefined
	var _has_y = variable_struct_exists(_entry, "last_y") && _entry.last_y != undefined
	if (_has_x && _has_y) {
		_entry.character.x = _entry.last_x
		_entry.character.y = _entry.last_y
	}
	// playerHealth on the entry is preserved across disconnect; push it back
	// onto the freshly-spawned character if the character exposes a health var.
	if (variable_instance_exists(_entry.character, "playerHealth")) {
		_entry.character.playerHealth = _entry.playerHealth
	}
	mp_debug_log("server-rejoin-restore",
		"steam=" + string(_entry.steamID)
		+ " x=" + string(_has_x ? _entry.last_x : -1)
		+ " y=" + string(_has_y ? _entry.last_y : -1)
		+ " hp=" + string(_entry.playerHealth))
}

///@self obj_Server
// Scans playerList for disconnected entries whose grace window has expired
// and removes them. Called periodically from obj_Server/Step_1.gml.
function mp_sweep_rejoin_grace() {
	if (!variable_instance_exists(id, "playerList")) return
	var _i = array_length(playerList) - 1
	while (_i >= 1) {  // never touch host slot 0
		var _e = playerList[_i]
		if (is_struct(_e)
			&& variable_struct_exists(_e, "disconnected") && _e.disconnected
			&& variable_struct_exists(_e, "disconnected_at")
			&& (current_time - _e.disconnected_at) > MP_REJOIN_GRACE_MS) {
			mp_debug_log("server-rejoin-expire",
				"steam=" + string(_e.steamID)
				+ " age_ms=" + string(current_time - _e.disconnected_at))
			array_delete(playerList, _i, 1)
		}
		_i--
	}
}

///@self obj_Client
// Sent by client after HELLO_ACK to ask the host to restore prior state.
// Layout: u8 type | u64 steamID
function send_rejoin_request(_lobby_host) {
	if (_lobby_host == undefined || _lobby_host <= 0) return
	var _b = buffer_create(9, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.REJOIN_REQUEST)
	buffer_write(_b, buffer_u64, steam_get_user_steam_id())
	steam_net_packet_send(_lobby_host, _b)
	buffer_delete(_b)
	mp_debug_log("client-rejoin-request", "host=" + string(_lobby_host))
}

///@self obj_Server
// Server-side handler. If we have a within-grace disconnected entry for the
// claiming steamID, re-spawn them and restore state. Otherwise it's a no-op
// (lobby_chat_update will have created the fresh slot already).
function receive_rejoin_request(_b, _sender) {
	var _claim_id = mp_buffer_safe_read(_b, buffer_u64)
	if (_claim_id == undefined || _claim_id != _sender) {
		mp_debug_log("server-rejoin-reject", "claim=" + string(_claim_id) + " sender=" + string(_sender))
		return
	}
	for (var _i = 0; _i < array_length(playerList); _i++) {
		var _e = playerList[_i]
		if (!is_struct(_e) || _e.steamID != _sender) continue
		if (mp_rejoin_within_grace(_e)) {
			_e.disconnected = false
			send_player_sync(_sender)
			send_player_spawn(_sender, _i)
			send_world_snapshot(_sender)
			mp_apply_rejoin_state(_i)
			mp_debug_log("server-rejoin-accept", "steam=" + string(_sender) + " slot=" + string(_i))
		}
		return
	}
}

// ---------------------------------------------------------------------------
// Phase 6.1: Chat
// ---------------------------------------------------------------------------
#macro MP_CHAT_MAX_LEN          240
#macro MP_CHAT_RATE_LIMIT_MS    500
#macro MP_CHAT_LOG_MAX          16

function mp_chat_init() {
	if !variable_global_exists("chat_log") then global.chat_log = []
	if !variable_global_exists("chat_last_send_ms") then global.chat_last_send_ms = {}
}

// Pushes a message struct {steamID, name, text, t} onto the bounded log.
function mp_chat_push(_steam_id, _name, _text) {
	mp_chat_init()
	array_push(global.chat_log, {
		steamID: _steam_id,
		name:    _name,
		text:    _text,
		t:       current_time
	})
	while (array_length(global.chat_log) > MP_CHAT_LOG_MAX) {
		array_delete(global.chat_log, 0, 1)
	}
}

// Returns true if _steam_id is currently rate-limited (host-side check).
function mp_chat_rate_limited(_steam_id) {
	mp_chat_init()
	var _k = string(_steam_id)
	if !variable_struct_exists(global.chat_last_send_ms, _k) return false
	return (current_time - global.chat_last_send_ms[$ _k]) < MP_CHAT_RATE_LIMIT_MS
}

function mp_chat_mark_sent(_steam_id) {
	mp_chat_init()
	global.chat_last_send_ms[$ string(_steam_id)] = current_time
}

// Client/host call this with user-typed text. Sender writes to local log
// immediately for snappy UX; host broadcasts authoritative copy to all peers.
function send_chat_message(_text) {
	if (!is_string(_text)) return
	_text = string_copy(_text, 1, MP_CHAT_MAX_LEN)
	if (string_length(string_trim(_text)) == 0) return
	var _my_id   = steam_get_user_steam_id()
	var _my_name = steam_get_persona_name()
	mp_chat_push(_my_id, _my_name, _text)  // local echo
	var _b = buffer_create(1, buffer_grow, 1)
	buffer_write(_b, buffer_u8,     NETWORK_PACKETS.CHAT_MESSAGE)
	buffer_write(_b, buffer_u64,    _my_id)
	buffer_write(_b, buffer_string, _my_name)
	buffer_write(_b, buffer_string, _text)
	if (instance_exists(obj_Server)) {
		// Host broadcasts to every other peer.
		mp_chat_mark_sent(_my_id)
		with (obj_Server) {
			for (var _i = 1; _i < array_length(playerList); _i++) {
				var _pe = playerList[_i]
				if (!is_struct(_pe)) continue
				if (variable_struct_exists(_pe, "disconnected") && _pe.disconnected) continue
				steam_net_packet_send(_pe.steamID, _b)
			}
		}
	} else if (instance_exists(obj_Client)) {
		steam_net_packet_send(obj_Client.lobbyHost, _b)
	}
	buffer_delete(_b)
	mp_debug_log("chat-send", "len=" + string(string_length(_text)))
}

///@self obj_Server or obj_Client
// Host: validates + rate-limits + rebroadcasts. Client: writes to local log.
function receive_chat_message(_b, _sender) {
	var _claim_id = mp_buffer_safe_read(_b, buffer_u64)
	var _name     = ""
	var _text     = ""
	try { _name = buffer_read(_b, buffer_string) } catch (_e) { return }
	try { _text = buffer_read(_b, buffer_string) } catch (_e) { return }
	if (instance_exists(obj_Server)) {
		// Host-side checks
		if (_claim_id != _sender) {
			mp_debug_log("chat-spoof-drop", "claim=" + string(_claim_id) + " sender=" + string(_sender))
			return
		}
		if (mp_chat_rate_limited(_sender)) {
			mp_debug_log("chat-rate-drop", "sender=" + string(_sender))
			return
		}
		_text = string_copy(_text, 1, MP_CHAT_MAX_LEN)
		if (string_length(string_trim(_text)) == 0) return
		mp_chat_mark_sent(_sender)
		mp_chat_push(_claim_id, _name, _text)
		// Rebroadcast authoritative copy
		var _ob = buffer_create(1, buffer_grow, 1)
		buffer_write(_ob, buffer_u8,     NETWORK_PACKETS.CHAT_MESSAGE)
		buffer_write(_ob, buffer_u64,    _claim_id)
		buffer_write(_ob, buffer_string, _name)
		buffer_write(_ob, buffer_string, _text)
		with (obj_Server) {
			for (var _i = 1; _i < array_length(playerList); _i++) {
				var _pe = playerList[_i]
				if (!is_struct(_pe)) continue
				if (_pe.steamID == _sender) continue  // already echoed locally on sender
				if (variable_struct_exists(_pe, "disconnected") && _pe.disconnected) continue
				steam_net_packet_send(_pe.steamID, _ob)
			}
		}
		buffer_delete(_ob)
	} else {
		// Client: trust the host-authoritative message.
		mp_chat_push(_claim_id, _name, _text)
	}
}

// ---------------------------------------------------------------------------
// Phase 6.2: Spectator
// ---------------------------------------------------------------------------

function mp_set_spectator_local(_steam_id, _is_spectator) {
	if (instance_exists(obj_Server)) {
		for (var _i = 0; _i < array_length(obj_Server.playerList); _i++) {
			var _e = obj_Server.playerList[_i]
			if (is_struct(_e) && _e.steamID == _steam_id) {
				_e.is_spectator = _is_spectator
				break
			}
		}
	}
	var _ch = find_player_by_steam_id(_steam_id)
	if (_ch != noone) {
		_ch.is_spectator = _is_spectator
		// Hide / re-show sprite for visual feedback. Movement systems should
		// gate on is_spectator independently.
		_ch.visible = !_is_spectator
	}
}

// Broadcasts the spectator flag for _steam_id. Host should call this when a
// player elects spectator or their lobby ready packet requested it.
function send_player_spectator(_steam_id, _is_spectator) {
	var _b = buffer_create(10, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.PLAYER_SPECTATOR)
	buffer_write(_b, buffer_u64, _steam_id)
	buffer_write(_b, buffer_u8,  _is_spectator ? 1 : 0)
	if (instance_exists(obj_Server)) {
		mp_set_spectator_local(_steam_id, _is_spectator)
		with (obj_Server) {
			for (var _i = 1; _i < array_length(playerList); _i++) {
				var _pe = playerList[_i]
				if (!is_struct(_pe)) continue
				if (variable_struct_exists(_pe, "disconnected") && _pe.disconnected) continue
				steam_net_packet_send(_pe.steamID, _b)
			}
		}
	} else if (instance_exists(obj_Client)) {
		steam_net_packet_send(obj_Client.lobbyHost, _b)
	}
	buffer_delete(_b)
	mp_debug_log("spectator-broadcast", "steam=" + string(_steam_id) + " on=" + string(_is_spectator))
}

function receive_player_spectator(_b, _sender) {
	var _target = mp_buffer_safe_read(_b, buffer_u64)
	var _flag   = mp_buffer_safe_read(_b, buffer_u8, 0)
	if (_target == undefined) return
	if (instance_exists(obj_Server)) {
		// Only the targeted player can request their own spectator transition.
		if (_target != _sender) {
			mp_debug_log("spectator-spoof-drop", "claim=" + string(_target) + " sender=" + string(_sender))
			return
		}
		send_player_spectator(_target, _flag != 0)
	} else {
		mp_set_spectator_local(_target, _flag != 0)
	}
}

///@self obj_Client
// Serialises local input into a CLIENT_PLAYER_INPUT packet and sends it to
// the server (_lobby_host).  The server will apply these values to this
// client's player instance and relay them to other clients.
// Packet layout: u8 type | s8 xInput | s8 yInput | u8 runKey | u8 actionKey | s16 mouseAngle  → 7 bytes
function send_player_input(_input, _lobby_host){
	// Convert raw key booleans to signed axis values before transmitting
	var _xInput          = (_input.rightKey - _input.leftKey)
	var _yInput          = (_input.downKey  - _input.upKey)
	var _runKey          = _input.runKey
	var _actionKey       = _input.actionKey
	var _mouseAngle      = point_direction(x, y, mouse_x, mouse_y)
	var _meleeKeyPressed = variable_struct_exists(_input, "meleeKeyPressed") ? (_input.meleeKeyPressed ? 1 : 0) : 0
	var _slashKeyPressed = variable_struct_exists(_input, "slashKeyPressed") ? (_input.slashKeyPressed ? 1 : 0) : 0
	var _b = buffer_create(9, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.CLIENT_PLAYER_INPUT);
	buffer_write(_b, buffer_s8,  _xInput);
	buffer_write(_b, buffer_s8,  _yInput);
	buffer_write(_b, buffer_u8,  _runKey);
	buffer_write(_b, buffer_u8,  _actionKey);
	buffer_write(_b, buffer_s16, _mouseAngle);
	buffer_write(_b, buffer_u8,  _meleeKeyPressed);
	buffer_write(_b, buffer_u8,  _slashKeyPressed);
	steam_net_packet_send(_lobby_host, _b)
	//show_debug_message(string(_mouseAngle))
	buffer_delete(_b)
}

///@description Player Input Packet Reading for server/client
// Deserialises an input packet from buffer _b and applies the values to the
// matching player instance.
//   _steam_id  – pass -1 when reading a CLIENT_PLAYER_INPUT (steamID is in
//                the buffer); pass an explicit ID when reading
//                SERVER_PLAYER_INPUT (steamID was already consumed).
// Returns a struct with all parsed fields, or nothing if the player is not found.
function receive_player_input(_b, _steam_id=-1){
	if _steam_id == -1 {
		_steam_id = mp_buffer_safe_read(_b, buffer_u64)
		if _steam_id == undefined then return
	}
	var _xInput     = mp_buffer_safe_read(_b, buffer_s8, 0)
	var _yInput     = mp_buffer_safe_read(_b, buffer_s8, 0)
	var _runKey     = mp_buffer_safe_read(_b, buffer_u8, 0)
	var _actionKey  = mp_buffer_safe_read(_b, buffer_u8, 0)
	var _mouseAngle      = mp_buffer_safe_read(_b, buffer_s16, 0)
	var _meleeKeyPressed = mp_buffer_safe_read(_b, buffer_u8, 0)
	var _slashKeyPressed = mp_buffer_safe_read(_b, buffer_u8, 0)
	var _input = {steamID: _steam_id, xInput: _xInput, yInput: _yInput, runKey: _runKey, actionKey: _actionKey, mouseAngle: _mouseAngle, meleeKeyPressed: _meleeKeyPressed, slashKeyPressed: _slashKeyPressed}
	var _player = find_player_by_steam_id(_steam_id)
	if _player == noone {
		if instance_exists(obj_Client) {
			queue_pending_player_input(_input)
			mp_debug_log("input-deferred", "steam=" + string(_steam_id) + " reason=player_not_ready")
			return _input;
		}
		mp_debug_log("input-dropped", "steam=" + string(_steam_id) + " reason=player_not_found")
		return;  // player may not have spawned yet — drop the packet
	}
	_player.xInput          = _xInput
	_player.yInput          = _yInput
	_player.runKey          = _runKey
	_player.actionKey       = _actionKey
	_player.mouseAngle      = _mouseAngle
	_player.meleeKeyPressed = _meleeKeyPressed != 0
	_player.slashKeyPressed = _slashKeyPressed != 0

	return _input
}

function player_entry_has_live_character(_entry) {
	if !is_struct(_entry) then return false
	if !variable_struct_exists(_entry, "character") then return false
	var _char = _entry.character
	if _char == undefined then return false
	return instance_exists(_char)
}

function find_player_entry_index_by_steam_id(_steam_id){
	for (var _i = 0; _i < array_length(playerList); _i++){
		if playerList[_i].steamID == _steam_id return _i;
	}
	return -1;
}

function queue_pending_player_input(_player_input) {
	if !instance_exists(obj_Client) then return
	var _pending = obj_Client.pendingPlayerInputs
	if !is_array(_pending) then _pending = []
	var _pendingIndex = -1
	for (var _i = 0; _i < array_length(_pending); _i++) {
		if _pending[_i].steamID == _player_input.steamID {
			_pendingIndex = _i
			break
		}
	}
	if _pendingIndex == -1 {
		array_push(_pending, _player_input)
	} else {
		_pending[_pendingIndex] = _player_input
	}
	obj_Client.pendingPlayerInputs = _pending
}

function apply_pending_player_input(_steam_id) {
	if !instance_exists(obj_Client) then return false
	var _pending = obj_Client.pendingPlayerInputs
	if !is_array(_pending) then return false
	var _pendingIndex = -1
	for (var _i = 0; _i < array_length(_pending); _i++) {
		if _pending[_i].steamID == _steam_id {
			_pendingIndex = _i
			break
		}
	}
	if _pendingIndex == -1 then return false
	var _player = find_player_by_steam_id(_steam_id)
	if _player == noone then return false
	var _input = _pending[_pendingIndex]
	_player.xInput     = _input.xInput
	_player.yInput     = _input.yInput
	_player.runKey     = _input.runKey
	_player.actionKey  = _input.actionKey
	_player.mouseAngle = _input.mouseAngle
	obj_Client.pendingPlayerInputs = array_delete(_pending, _pendingIndex, 1)
	mp_debug_log("input-buffer-applied", "steam=" + string(_steam_id) + " x=" + string(_input.xInput) + " y=" + string(_input.yInput))
	return true
}

///@self obj_Client, obj_Server
// Searches playerList for an entry whose character instance has the given
// steamID.  Returns the instance reference, or noone if not found.
function find_player_by_steam_id(_steam_id){
	for (var _i = 0; _i < array_length(playerList); _i++){
		var _player = playerList[_i].character
		if !player_entry_has_live_character(playerList[_i]) continue;
		if _player.steamID == _steam_id {
			return _player;
		}
	}
	return noone;
}

//@self obj_Server
// Sends a PLAYER_POSITION packet for every player to every non-host client.
// Called each tick by the server to keep client positions authoritative.
// Packet layout: u8 type | u16 seq | u64 steamID | u16 x | u16 y  → 15 bytes
// The per-recipient sequence number lets clients drop stale/reordered packets.
function send_player_positions() {
	// Phase 7.1: skip broadcasts for players that haven't moved >=2px since
	// their last sent position AND were sent within MP_POS_IDLE_MS. Force a
	// keep-alive every MP_POS_FORCE_MS regardless so newly joined observers
	// converge quickly.
	for (var _i = 0; _i < array_length(playerList); _i++){
		var _player = playerList[_i]
		if variable_struct_exists(_player, "disconnected") && _player.disconnected then continue
		if !player_entry_has_live_character(_player) then continue
		if _player.steamID  == undefined then continue
		var _cx = _player.character.x
		var _cy = _player.character.y
		var _now = current_time
		var _last_x  = variable_struct_exists(_player, "mp_sent_x")  ? _player.mp_sent_x  : -99999
		var _last_y  = variable_struct_exists(_player, "mp_sent_y")  ? _player.mp_sent_y  : -99999
		var _last_t  = variable_struct_exists(_player, "mp_sent_at") ? _player.mp_sent_at : 0
		var _moved   = (abs(_cx - _last_x) >= MP_POS_MIN_DELTA_PX) || (abs(_cy - _last_y) >= MP_POS_MIN_DELTA_PX)
		var _force   = (_now - _last_t) >= MP_POS_FORCE_MS
		if (!_moved && !_force) continue
		_player.mp_sent_x  = _cx
		_player.mp_sent_y  = _cy
		_player.mp_sent_at = _now
		// Broadcast to every non-host client EXCEPT the player whose position this is.
		// Clients manage their own position via client-side prediction; sending their
		// own authoritative position back would cause the reconciler to snap them.
		for (var _k = 0; _k < array_length(playerList); _k++){
			if ((playerList[_k].steamID != obj_Server.steamID)
				&& (playerList[_k].steamID != playerList[_i].steamID)
				&& !(variable_struct_exists(playerList[_k], "disconnected") && playerList[_k].disconnected)) {
				var _b = buffer_create(15, buffer_fixed, 1)
				buffer_write(_b, buffer_u8,  NETWORK_PACKETS.PLAYER_POSITION)
				buffer_write(_b, buffer_u16, mp_seq_next(playerList[_k].steamID))
				buffer_write(_b, buffer_u64, _player.steamID)
				buffer_write(_b, buffer_u16, _cx)
				buffer_write(_b, buffer_u16, _cy)
				steam_net_packet_send(playerList[_k].steamID, _b)
				buffer_delete(_b)
			}
		}
	}
}

//@self obj_Client
// Reads a PLAYER_POSITION packet from _b and snaps the matching player
// instance to the server-authoritative coordinates. Drops stale packets
// (older sequence number) silently.
function update_player_position(_b, _sender_steam_id=undefined) {
	var _seq      = mp_buffer_safe_read(_b, buffer_u16)
	var _steam_id = mp_buffer_safe_read(_b, buffer_u64)
	var _x        = mp_buffer_safe_read(_b, buffer_u16)
	var _y        = mp_buffer_safe_read(_b, buffer_u16)
	if (_seq == undefined || _steam_id == undefined || _x == undefined || _y == undefined) return
	if (_sender_steam_id != undefined) {
		if !mp_seq_accept(_sender_steam_id, NETWORK_PACKETS.PLAYER_POSITION, _seq) return
	}
	for (var _i = 0; _i < array_length(playerList); _i++){
		if (_steam_id == playerList[_i].steamID) {
			if !player_entry_has_live_character(playerList[_i]) then continue
			playerList[_i].character.netX = _x
			playerList[_i].character.netY = _y
			playerList[_i].character.hasNetPos = true
		}
	}
}

// Returns max health for the active game mode.
function mode_max_health(_mode=undefined){
	var _selectedMode = _mode
	if _selectedMode == undefined {
		if variable_global_exists("gameParams") {
			_selectedMode = global.gameParams.modeSelection
		} else {
			_selectedMode = 0
		}
	}
	if _selectedMode == global.GAME_MODE_HP5 then return 5
	return 1
}

// Applies player health to both playerList and spawned character instances.
function set_player_health(_steam_id, _health){
	var _playerList
	var _listOwner = 0

	if variable_instance_exists(id, "playerList") {
		_playerList = playerList
		_listOwner = 1
	} else if instance_exists(obj_Server) {
		_playerList = obj_Server.playerList
		_listOwner = 2
	} else if instance_exists(obj_Client) {
		_playerList = obj_Client.playerList
		_listOwner = 3
	} else {
		return
	}

	for (var _i = 0; _i < array_length(_playerList); _i++){
		if _playerList[_i].steamID != _steam_id then continue

		if _playerList[_i].maxHealth == undefined then _playerList[_i].maxHealth = max(1, _health)
		_playerList[_i].playerHealth = _health

		if player_entry_has_live_character(_playerList[_i]) {
			var _char = _playerList[_i].character
			_char.maxHealth = _playerList[_i].maxHealth
			_char.playerHealth = _health

			if (_health <= 0 && _char.sprite_index != sprPlayerDie) {
				_char.image_speed = 1
				_char.sprite_index = sprPlayerDie
			}

			if (_health > 0 && _char.sprite_index == sprPlayerDie) {
				_char.sprite_index = sprPlayerIdle
			}
		}

		break
	}

	switch _listOwner {
		case 1:
			playerList = _playerList
			break
		case 2:
			obj_Server.playerList = _playerList
			break
		case 3:
			obj_Client.playerList = _playerList
			break
	}
}

//@self obj_Server
// Broadcasts a player's current health to all non-host clients.
function send_player_health_to_clients(_steam_id, _health){
	mp_debug_log("health-send-begin",
		"steam=" + string(_steam_id)
		+ " health=" + string(_health)
		+ " recipients=" + string(array_length(obj_Server.playerList) - 1)
	)
	var _b = buffer_create(11, buffer_fixed, 1);
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.PLAYER_HEALTH)
	buffer_write(_b, buffer_u64, _steam_id)
	buffer_write(_b, buffer_u16, _health)

	for (var _i = 0; _i < array_length(obj_Server.playerList); _i++){
		if (obj_Server.playerList[_i].steamID != obj_Server.steamID
			&& !(variable_struct_exists(obj_Server.playerList[_i], "disconnected") && obj_Server.playerList[_i].disconnected)) {
			mp_debug_log("health-send-peer",
				"steam=" + string(_steam_id)
				+ " health=" + string(_health)
				+ " to=" + string(obj_Server.playerList[_i].steamID)
			)
			steam_net_packet_send(obj_Server.playerList[_i].steamID, _b)
		}
	}

	buffer_delete(_b)
	mp_debug_log("health-send-end",
		"steam=" + string(_steam_id)
		+ " health=" + string(_health)
	)
}

//@self obj_Client
// Applies an incoming PLAYER_HEALTH packet.
function receive_player_health(_b){
	var _steam_id = mp_buffer_safe_read(_b, buffer_u64)
	var _health   = mp_buffer_safe_read(_b, buffer_u16)
	if (_steam_id == undefined || _health == undefined) return
	mp_debug_log("health-receive",
		"steam=" + string(_steam_id)
		+ " health=" + string(_health)
	)
	set_player_health(_steam_id, _health)
}

// ---------------------------------------------------------------------------
// Player colour sync
// ---------------------------------------------------------------------------

///@self obj_Client
// Sends a PLAYER_COLOR packet to the server with this client's chosen colour.
// Packet layout (client → server): u8 type | u32 color  → 5 bytes
function send_player_color(_color) {
	var _b = buffer_create(5, buffer_fixed, 1)
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.PLAYER_COLOR)
	buffer_write(_b, buffer_u32, _color)
	steam_net_packet_send(steam_lobby_get_owner_id(), _b)
	buffer_delete(_b)
}

///@self obj_Server
// Reads a PLAYER_COLOR packet from a client, updates the server playerList and
// the live character instance, then broadcasts the new colour to all other clients.
// Broadcast layout (server → clients): u8 type | u64 steamID | u32 color  → 13 bytes
function receive_player_color(_b, _steam_id) {
	var _color = mp_buffer_safe_read(_b, buffer_u32)
	if _color == undefined then return
	for (var _i = 0; _i < array_length(obj_Server.playerList); _i++) {
		if obj_Server.playerList[_i].steamID == _steam_id {
			obj_Server.playerList[_i].playerColor = _color
			if player_entry_has_live_character(obj_Server.playerList[_i]) {
				obj_Server.playerList[_i].character.playerColor = _color
			}
			break
		}
	}
	var _bcast = buffer_create(13, buffer_fixed, 1)
	buffer_write(_bcast, buffer_u8,  NETWORK_PACKETS.PLAYER_COLOR)
	buffer_write(_bcast, buffer_u64, _steam_id)
	buffer_write(_bcast, buffer_u32, _color)
	for (var _i = 0; _i < array_length(obj_Server.playerList); _i++) {
		if obj_Server.playerList[_i].steamID != obj_Server.steamID
			&& !(variable_struct_exists(obj_Server.playerList[_i], "disconnected") && obj_Server.playerList[_i].disconnected) {
			steam_net_packet_send(obj_Server.playerList[_i].steamID, _bcast)
		}
	}
	buffer_delete(_bcast)
}

///@self obj_Client
// Applies a broadcasted PLAYER_COLOR packet received from the server.
// Packet layout (after type byte): u64 steamID | u32 color
function apply_player_color(_b) {
	var _steam_id = mp_buffer_safe_read(_b, buffer_u64)
	var _color    = mp_buffer_safe_read(_b, buffer_u32)
	if (_steam_id == undefined || _color == undefined) return
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == _steam_id {
			playerList[_i].playerColor = _color
			if player_entry_has_live_character(playerList[_i]) {
				playerList[_i].character.playerColor = _color
			}
			break
		}
	}
}

