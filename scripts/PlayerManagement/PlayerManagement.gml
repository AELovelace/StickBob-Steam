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

///@self obj_Client, obj_Server
// Searches playerList for an entry whose character instance has the given
// steamID.  Returns the instance reference, or noone if not found.
function find_player_by_steam_id(_steam_id){
	for (var _i = 0; _i < array_length(playerList); _i++){
		var _player = playerList[_i].character
		if _player == undefined continue;
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
		if _player.character == undefined then continue
		if _player.steamID  == undefined then continue
		var _b = buffer_create(13, buffer_fixed, 1);
		buffer_write(_b, buffer_u8,  NETWORK_PACKETS.PLAYER_POSITION);
		buffer_write(_b, buffer_u64, _player.steamID);
		buffer_write(_b, buffer_u16, _player.character.x);
		buffer_write(_b, buffer_u16, _player.character.y);
		// Broadcast to every non-host client
		for (var _k = 0; _k < array_length(playerList); _k++){
			if (playerList[_k].steamID != obj_Server.steamID) {
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
			if playerList[_i].character == undefined then continue
			playerList[_i].character.netX = _x
			playerList[_i].character.netY = _y
			playerList[_i].character.hasNetPos = true
		}
	}
}
