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


///@self obj_Client
// Serialises local input into a CLIENT_PLAYER_INPUT packet and sends it to
// the server (_lobby_host).  The server will apply these values to this
// client's player instance and relay them to other clients.
// Packet layout: u8 type | s8 xInput | s8 yInput | u8 runKey | u8 actionKey | s16 mouseAngle  → 7 bytes
function send_player_input(_input, _lobby_host){
	// Convert raw key booleans to signed axis values before transmitting
	var _xInput     = (_input.rightKey - _input.leftKey)
	var _yInput     = (_input.downKey  - _input.upKey)
	var _runKey     = _input.runKey
	var _actionKey  = _input.actionKey
	var _mouseAngle = point_direction(x, y, mouse_x, mouse_y)
	var _b = buffer_create(7, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.CLIENT_PLAYER_INPUT);
	buffer_write(_b, buffer_s8,  _xInput);
	buffer_write(_b, buffer_s8,  _yInput);
	buffer_write(_b, buffer_u8,  _runKey);
	buffer_write(_b, buffer_u8,  _actionKey);
	buffer_write(_b, buffer_s16, _mouseAngle);
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
	if _steam_id == -1 then _steam_id = buffer_read(_b, buffer_u64)
	var _xInput     = buffer_read(_b, buffer_s8)
	var _yInput     = buffer_read(_b, buffer_s8)
	var _runKey     = buffer_read(_b, buffer_u8)
	var _actionKey  = buffer_read(_b, buffer_u8)
	var _mouseAngle = buffer_read(_b, buffer_s16)
	var _player = find_player_by_steam_id(_steam_id)
	if _player == noone return;  // player may not have spawned yet — drop the packet
	_player.xInput     = _xInput
	_player.yInput     = _yInput
	_player.runKey     = _runKey
	_player.actionKey  = _actionKey
	_player.mouseAngle = _mouseAngle

	return {steamID: _steam_id, xInput: _xInput, yInput: _yInput, runKey: _runKey, actionKey: _actionKey, mouseAngle: _mouseAngle}
}

function player_entry_has_live_character(_entry) {
	if !is_struct(_entry) then return false
	if !variable_struct_exists(_entry, "character") then return false
	var _char = _entry.character
	if _char == undefined then return false
	return instance_exists(_char)
}

///@self obj_Client, obj_Server
// Searches playerList for an entry whose character instance has the given
// steamID.  Returns the instance reference, or noone if not found.
function find_player_by_steam_id(_steam_id){
	for (var _i = 0; _i < array_length(playerList); _i++){
		var _player = playerList[_i].character
		if !player_entry_has_live_character(playerList[_i]) continue;
		if _player.steamID == _steam_id return _player;
	}
	return noone;
}

//@self obj_Server
// Sends a PLAYER_POSITION packet for every player to every non-host client.
// Called each tick by the server to keep client positions authoritative.
// Packet layout: u8 type | u64 steamID | u16 x | u16 y  → 13 bytes
function send_player_positions() {
	for (var _i = 0; _i < array_length(playerList); _i++){
		var _player = playerList[_i]
		if variable_struct_exists(_player, "disconnected") && _player.disconnected then continue
		if !player_entry_has_live_character(_player) then continue
		if _player.steamID  == undefined then continue
		var _b = buffer_create(13, buffer_fixed, 1);
		buffer_write(_b, buffer_u8,  NETWORK_PACKETS.PLAYER_POSITION);
		buffer_write(_b, buffer_u64, _player.steamID);
		buffer_write(_b, buffer_u16, _player.character.x);
		buffer_write(_b, buffer_u16, _player.character.y);
		// Broadcast to every non-host client
		for (var _k = 0; _k < array_length(playerList); _k++){
			if ((playerList[_k].steamID != obj_Server.steamID)
				&& !(variable_struct_exists(playerList[_k], "disconnected") && playerList[_k].disconnected)) {
				steam_net_packet_send(playerList[_k].steamID, _b)
			}
		}
		buffer_delete(_b)
	}
}

//@self obj_Client
// Reads a PLAYER_POSITION packet from _b and snaps the matching player
// instance to the server-authoritative coordinates.
function update_player_position(_b) {
	var _steam_id = buffer_read(_b, buffer_u64)
	var _x        = buffer_read(_b, buffer_u16)
	var _y        = buffer_read(_b, buffer_u16)
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
	var _b = buffer_create(11, buffer_fixed, 1);
	buffer_write(_b, buffer_u8, NETWORK_PACKETS.PLAYER_HEALTH)
	buffer_write(_b, buffer_u64, _steam_id)
	buffer_write(_b, buffer_u16, _health)

	for (var _i = 0; _i < array_length(obj_Server.playerList); _i++){
		if (obj_Server.playerList[_i].steamID != obj_Server.steamID
			&& !(variable_struct_exists(obj_Server.playerList[_i], "disconnected") && obj_Server.playerList[_i].disconnected)) {
			steam_net_packet_send(obj_Server.playerList[_i].steamID, _b)
		}
	}

	buffer_delete(_b)
}

//@self obj_Client
// Applies an incoming PLAYER_HEALTH packet.
function receive_player_health(_b){
	var _steam_id = buffer_read(_b, buffer_u64)
	var _health = buffer_read(_b, buffer_u16)
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
	var _color = buffer_read(_b, buffer_u32)
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
	var _steam_id = buffer_read(_b, buffer_u64)
	var _color    = buffer_read(_b, buffer_u32)
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

