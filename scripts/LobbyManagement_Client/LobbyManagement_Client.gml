// Client-side lobby management.
// Handles merging server-sent player lists into the client's local state
// and creating player instances for peers that the client doesn't know about yet.

///@self obj_Client
// Merges an incoming player list (from a SYNC_PLAYERS packet) with the
// client's local playerList.
//   - New players (not yet in local list) are spawned immediately.
//   - Existing entries are updated with the latest startPos / lobbyMemberID
//     from the server, and respawned if their character instance is missing.
function sync_players(_new_list) {
	// Build a quick-lookup array of steamIDs already tracked locally
	var _steamIDs = []
	for (var _i = 0; _i < array_length(playerList); _i++){
		array_push(_steamIDs, playerList[_i].steamID)
	}

	for (var _i = 0; _i < array_length(_new_list); _i++){
		var _newSteamID = _new_list[_i].steamID
		if !array_contains(_steamIDs, _newSteamID){
			// Brand-new player — spawn them and add to the local list
			var _inst = client_player_spawn_at_pos(_new_list[_i])
			_new_list[_i].character = _inst
			array_push(playerList, _new_list[_i])
		} else {
			// Already tracked — update positional and lobby metadata
			for (var _k = 0; _k < array_length(playerList); _k++) {
				if playerList[_k].steamID == _newSteamID {
					playerList[_k].startPos     = _new_list[_i].startPos
					playerList[_k].lobbyMemberID = _new_list[_i].lobbyMemberID
					playerList[_k].steamName    = steam_get_persona_name(playerList[_k].steamID)
					// If the instance was lost (e.g. room change) and it isn't the local player, respawn it
					if playerList[_k].character == undefined && playerList[_k].steamID != _newSteamID {
						var _inst = client_player_spawn_at_pos(playerList[_k])
						playerList[_k].character = _inst
					}
				}
			}
		}
	}
}

///@self obj_Client
// Creates an obj_Player instance for a remote player at the position stored
// in _player_info.startPos.  Returns the new instance so the caller can
// store it in playerList[].character.
function client_player_spawn_at_pos(_player_info) {
	var _layer   = layer_get_id("Instances")
	var _name    = steam_get_persona_name(_player_info.steamID)
	var _steamID = _player_info.steamID
	var _num     = _player_info.lobbyMemberID
	var _loc     = _player_info.startPos
	var _inst    = instance_create_layer(_loc.x, _loc.y, _layer, obj_Player, {
		steamName    : _name,
		steamID      : _steamID,
		lobbyMemberID: _num
	})
	return _inst
}
