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
//   2. Sends a SPAWN_SELF packet to the joining player (their own position).
//   3. Creates the server-side player instance at that position.
//   4. Broadcasts a SPAWN_OTHER packet to all other connected clients.
// Packet layout (SPAWN_SELF): u8 type | u16 x | u16 y  → 5 bytes
function send_player_spawn(_steam_id, _slot) {
	var _pos = grab_spawn_point(_slot)
	var _b = buffer_create(5, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.SPAWN_SELF);
	buffer_write(_b, buffer_u16, _pos.x);
	buffer_write(_b, buffer_u16, _pos.y);
	steam_net_packet_send(_steam_id, _b)
	buffer_delete(_b);
	server_player_spawn_at_pos(_steam_id, _pos)   // create instance on the server
	send_other_player_spawn(_steam_id, _pos);     // tell everyone else about the new arrival
}

///@self obj_Server
// Broadcasts a SPAWN_OTHER packet to every client except the one who just joined.
// This lets existing clients create a ghost/remote instance for the new player.
// Packet layout: u8 type | u16 x | u16 y | u64 steamID  → 13 bytes
function send_other_player_spawn(_steam_id, _pos) {
	var _b = buffer_create(13, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.SPAWN_OTHER);
	buffer_write(_b, buffer_u16, _pos.x);
	buffer_write(_b, buffer_u16, _pos.y);
	buffer_write(_b, buffer_u64, _steam_id);
	for (var _i = 1; _i < array_length(playerList); _i++){
		if (playerList[_i].steamID != _steam_id) {
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
	//var _shrunkList = playerList
	//for (var _i = 0; _i < array_length(_shrunkList); _i++) {
	//	//_shrunkList[_i].character = undefined
	//}
	return json_stringify(playerList)
}

///@self obj_Server
// Instantiates the player object on the server for the given _steam_id.
// Searches playerList for the matching entry and creates obj_Player at _pos,
// then stores the new instance reference back into the list for position sync.
function server_player_spawn_at_pos(_steam_id, _pos) {
	var _layer = layer_get_id("Instances");
	for (var _i = 0; _i < array_length(playerList); _i++){
		if playerList[_i].steamID == _steam_id {
			var _inst = instance_create_layer(_pos.x, _pos.y, _layer, obj_Player, {
								steamName    : playerList[_i].steamName,
								steamID      : _steam_id,
								lobbyMemberID: _i
						})
			playerList[_i].character = _inst
		}
	}
}

///@self obj_Server
// Relays the host's processed input to every non-host client so they can
// simulate the host's character locally.
// Packet layout: u8 type | u64 steamID | s8 xInput | s8 yInput | u8 runKey | u8 actionKey | s16 mouseAngle  → 15 bytes
function send_player_input_to_clients(_player_input){
	if _player_input == undefined then return
	var _b = buffer_create(15, buffer_fixed, 1);
	buffer_write(_b, buffer_u8,  NETWORK_PACKETS.SERVER_PLAYER_INPUT);
	buffer_write(_b, buffer_u64, _player_input.steamID);
	buffer_write(_b, buffer_s8,  _player_input.xInput);
	buffer_write(_b, buffer_s8,  _player_input.yInput);
	buffer_write(_b, buffer_u8,  _player_input.runKey);
	buffer_write(_b, buffer_u8,  _player_input.actionKey);
	buffer_write(_b, buffer_s16, _player_input.mouseAngle);
	for (var _i = 0; _i < array_length(obj_Server.playerList); _i++){
		if (obj_Server.playerList[_i].steamID != obj_Server.steamID) {
			steam_net_packet_send(obj_Server.playerList[_i].steamID, _b)
		}
	}
	buffer_delete(_b);
}
