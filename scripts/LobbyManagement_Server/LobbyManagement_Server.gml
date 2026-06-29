// Server-side lobby and player management.
// These functions run on the host (obj_Server) and handle spawning new players,
// broadcasting the current player list, and relaying input to all clients.

///@self obj_Server
// Sends the full JSON-encoded player list to a specific client.
// Called when a new player joins so they can populate their local playerList.
function send_player_sync(_steam_id){
	var _b = buffer_create(1, buffer_grow, 1);
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.SYNC_PLAYERS);
	buffer_write(_b, buffer_string, shrink_player_list());  // JSON string of playerList
	steam_net_packet_send(_steam_id, _b)
	buffer_delete(_b);
}

///@self obj_Server
// Handles the full spawn sequence for a newly joining player:
//   1. Looks up the spawn point for this player's lobby slot.
//   2. Sends a SPAWN_SELF packet to the joining player (their own position + slot).
//   3. Creates the server-side player instance at that position.
//   4. Broadcasts a SPAWN_OTHER packet to all other connected clients.
// Packet layout (SPAWN_SELF): u8 type | u16 x | u16 y | u8 slot  → 6 bytes
// Including slot here makes the packet self-contained so the client does not
// need SYNC_PLAYERS to have arrived first (UDP gives no ordering guarantee).
function send_player_spawn(_steam_id, _slot) {
	var _pos = grab_spawn_point(_slot)
	server_player_spawn_at_pos(_steam_id, _pos)   // create authoritative instance before client can send input
	var _b = buffer_create(6, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.SPAWN_SELF);
	buffer_write(_b, buffer_u16, _pos.x);
	buffer_write(_b, buffer_u16, _pos.y);
	buffer_write(_b, buffer_u8,  _slot);  // lobby slot — client uses this as lobbyMemberID
	steam_net_packet_send(_steam_id, _b)
	buffer_delete(_b);
	send_other_player_spawn(_steam_id, _pos);     // tell everyone else about the new arrival
}

///@self obj_Server
// Broadcasts a SPAWN_OTHER packet to every client except the one who just joined.
// This lets existing clients create a ghost/remote instance for the new player.
// Packet layout: u8 type | u16 x | u16 y | u64 steamID | string steamName
function send_other_player_spawn(_steam_id, _pos) {
	var _name = ""
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if playerList[_i].steamID == _steam_id {
			_name = playerList[_i].steamName
			break
		}
	}
	var _b = buffer_create(32, buffer_grow, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.SPAWN_OTHER);
	buffer_write(_b, buffer_u16, _pos.x);
	buffer_write(_b, buffer_u16, _pos.y);
	buffer_write(_b, buffer_u64, _steam_id);
	buffer_write(_b, buffer_string, _name);
	for (var _i = 1; _i < array_length(playerList); _i++){
		if (playerList[_i].steamID != _steam_id
			&& !(variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected)) {
			steam_net_packet_send(playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b);
}

///@self obj_Server
// Serialises the playerList to JSON for transmission in a SYNC_PLAYERS packet.
// Note: the character instance reference is intentionally kept in the JSON
// (it would be noone/undefined on the receiving client, which is harmless).
function shrink_player_list(){
	var _shrunkList = []
	for (var _i = 0; _i < array_length(playerList); _i++) {
		if variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected then continue
		array_push(_shrunkList, {
			steamID      : playerList[_i].steamID,
			steamName    : playerList[_i].steamName,
			startPos     : playerList[_i].startPos,
			lobbyMemberID: playerList[_i].lobbyMemberID,
			maxHealth    : playerList[_i].maxHealth,
			playerHealth : playerList[_i].playerHealth,
			playerColor  : variable_struct_exists(playerList[_i], "playerColor") ? playerList[_i].playerColor : c_white
		})
	}
	return json_stringify(_shrunkList)
}

///@self obj_Server
// Instantiates the player object on the server for the given _steam_id.
// Searches playerList for the matching entry and creates obj_Player at _pos,
// then stores the new instance reference back into the list for position sync.
function server_player_spawn_at_pos(_steam_id, _pos) {
	var _layer = layer_get_id("Instances");
	for (var _i = 0; _i < array_length(playerList); _i++){
		if playerList[_i].steamID == _steam_id {
			if player_entry_has_live_character(playerList[_i]) {
				var _existing = playerList[_i].character
				_existing.x = _pos.x
				_existing.y = _pos.y
				_existing.netX = _pos.x
				_existing.netY = _pos.y
				_existing.hasNetPos = true
				mp_debug_log("player-spawn-reuse", "steam=" + string(_steam_id) + " slot=" + string(_i) + " instance=" + string(_existing))
				return _existing
			}
			var _maxHP = playerList[_i].maxHealth
			if _maxHP == undefined then _maxHP = mode_max_health()
			var _hp = playerList[_i].playerHealth
			if _hp == undefined then _hp = _maxHP
			var _color = variable_struct_exists(playerList[_i], "playerColor") ? playerList[_i].playerColor : c_white
			var _inst = instance_create_layer(_pos.x, _pos.y, _layer, obj_Player, {
								steamName    : playerList[_i].steamName,
								steamID      : _steam_id,
								lobbyMemberID: _i,
								maxHealth    : _maxHP,
								playerHealth : _hp,
								gameMode     : global.gameParams.modeSelection,
								playerColor  : _color
						})
			playerList[_i].playerColor = _color
			playerList[_i].character = _inst
			playerList[_i].maxHealth = _maxHP
			playerList[_i].playerHealth = _hp
			mp_debug_log("player-spawn", "steam=" + string(_steam_id) + " slot=" + string(_i) + " instance=" + string(_inst) + " lobbyMemberID=" + string(_i))
			return _inst
		}
	}
	return undefined
}

///@self obj_Server
// Relays processed input to clients so they can simulate remote characters
// locally between authoritative position updates.
// Packet layout: u8 type | u64 steamID | s8 xInput | s8 yInput | u8 runKey | u8 actionKey | s16 mouseAngle  → 15 bytes
function send_player_input_to_clients(_player_input, _exclude_steam_id=undefined){
	if _player_input == undefined then return
	var _b = buffer_create(17, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.SERVER_PLAYER_INPUT);
	buffer_write(_b, buffer_u64, _player_input.steamID);
	buffer_write(_b, buffer_s8,  _player_input.xInput);
	buffer_write(_b, buffer_s8,  _player_input.yInput);
	buffer_write(_b, buffer_u8,  _player_input.runKey);
	buffer_write(_b, buffer_u8,  _player_input.actionKey);
	buffer_write(_b, buffer_s16, _player_input.mouseAngle);
	buffer_write(_b, buffer_u8,  variable_struct_exists(_player_input, "meleeKeyPressed") ? (_player_input.meleeKeyPressed ? 1 : 0) : 0);
	buffer_write(_b, buffer_u8,  variable_struct_exists(_player_input, "slashKeyPressed") ? (_player_input.slashKeyPressed ? 1 : 0) : 0);
	for (var _i = 0; _i < array_length(obj_Server.playerList); _i++){
		if (obj_Server.playerList[_i].steamID != obj_Server.steamID
			&& (_exclude_steam_id == undefined || obj_Server.playerList[_i].steamID != _exclude_steam_id)
			&& !(variable_struct_exists(obj_Server.playerList[_i], "disconnected") && obj_Server.playerList[_i].disconnected)) {
			steam_net_packet_send(obj_Server.playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b);
}
