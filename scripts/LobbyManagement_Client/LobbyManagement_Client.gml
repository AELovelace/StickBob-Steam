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
		var _incomingName = variable_struct_exists(_new_list[_i], "steamName") ? _new_list[_i].steamName : steam_get_user_persona_name(_newSteamID)
		if _new_list[_i].maxHealth == undefined then _new_list[_i].maxHealth = mode_max_health()
		if _new_list[_i].playerHealth == undefined then _new_list[_i].playerHealth = _new_list[_i].maxHealth
		var _incomingColor = variable_struct_exists(_new_list[_i], "playerColor") ? _new_list[_i].playerColor : c_white
		_new_list[_i].steamName = _incomingName
		if !array_contains(_steamIDs, _newSteamID){
			// Brand-new player — spawn them and add to the local list
			_new_list[_i].playerColor = _incomingColor
			var _inst = client_player_spawn_at_pos(_new_list[_i])
			_new_list[_i].character = _inst
			array_push(playerList, _new_list[_i])
		} else {
			// Already tracked — update positional and lobby metadata
			for (var _k = 0; _k < array_length(playerList); _k++) {
				if playerList[_k].steamID == _newSteamID {
					playerList[_k].startPos     = _new_list[_i].startPos
					playerList[_k].lobbyMemberID = _new_list[_i].lobbyMemberID
					playerList[_k].steamName    = _incomingName
					playerList[_k].maxHealth    = _new_list[_i].maxHealth
					playerList[_k].playerHealth = _new_list[_i].playerHealth
					playerList[_k].playerColor  = _incomingColor
					// If the instance was lost (e.g. room change) and it isn't the local player, respawn it
					if !player_entry_has_live_character(playerList[_k]) && playerList[_k].steamID != steam_get_user_steam_id() {
						var _inst = client_player_spawn_at_pos(playerList[_k])
						playerList[_k].character = _inst
					} else if player_entry_has_live_character(playerList[_k]) {
						playerList[_k].character.maxHealth    = playerList[_k].maxHealth
						playerList[_k].character.playerHealth = playerList[_k].playerHealth
						playerList[_k].character.playerColor  = _incomingColor
						playerList[_k].character.steamName    = _incomingName
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
	var _name    = variable_struct_exists(_player_info, "steamName") ? _player_info.steamName : steam_get_user_persona_name(_player_info.steamID)
	var _steamID = _player_info.steamID
	var _num     = _player_info.lobbyMemberID
	var _loc     = _player_info.startPos
	var _maxHP = _player_info.maxHealth
	if _maxHP == undefined then _maxHP = mode_max_health()
	var _hp = _player_info.playerHealth
	if _hp == undefined then _hp = _maxHP
	var _color = variable_struct_exists(_player_info, "playerColor") ? _player_info.playerColor : c_white
	var _inst    = instance_create_layer(_loc.x, _loc.y, _layer, obj_Player, {
		steamName    : _name,
		steamID      : _steamID,
		lobbyMemberID: _num,
		maxHealth    : _maxHP,
		playerHealth : _hp,
		gameMode     : global.gameParams.modeSelection,
		playerColor  : _color
	})
	return _inst
}
