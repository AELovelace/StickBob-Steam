// Let the SGC gateway handle ticket_response events for OAuth linking.
sgc_gateway_handle_async_steam();

switch(async_load[?"event_type"])
{ 
	case "lobby_chat_update":
		var _fromID = async_load[?"user_id"]; //SteamID
		var _fromName = steam_get_user_persona_name_sync(_fromID); //Steam Player Name
		if (async_load[?"change_flags"] & steam_lobby_member_change_entered){
			// Search for any existing entry with this steamID (active or disconnected)
			var _existingSlot = -1;
			var _isDisconnected = false;
			for (var _i = 0; _i < array_length(playerList); _i++) {
				if playerList[_i].steamID == _fromID {
					_existingSlot = _i;
					_isDisconnected = (variable_struct_exists(playerList[_i], "disconnected") && playerList[_i].disconnected);
					break;
				}
			}
			
			// If player is already active in lobby, skip (duplicate join event)
			if (_existingSlot >= 0 && !_isDisconnected) {
				mp_debug_log("lobby-join-ignore", "steam=" + string(_fromID) + " name=" + _fromName + " reason=already_active");
				break;
			}
			
			// Rejoin case: reuse disconnected slot
			if (_existingSlot >= 0 && _isDisconnected) {
				show_debug_message("Player Rejoined: " + _fromName + " (reclaiming slot " + string(_existingSlot) + ")")
				mp_debug_log("lobby-rejoin", "steam=" + string(_fromID) + " name=" + _fromName + " slot=" + string(_existingSlot))
				playerList[_existingSlot].disconnected = false;
				var _slot = _existingSlot;
			} else {
				// New player: create new slot
				show_debug_message("Player Joined: " + _fromName)
				mp_debug_log("lobby-join", "steam=" + string(_fromID) + " name=" + _fromName)
				var _slot = array_length(playerList)
				var _maxHP = mode_max_health()
				array_push(playerList, 
				{
					steamID: _fromID,
					steamName: _fromName,
					character: undefined,
					startPos: grab_spawn_point(_slot),
					lobbyMemberID: _slot,
					maxHealth: _maxHP,
					playerHealth: _maxHP
				})
			}
			send_player_sync(_fromID);
			send_player_spawn(_fromID, _slot);
		}
		if (async_load[?"change_flags"] & (steam_lobby_member_change_left | steam_lobby_member_change_disconnected | steam_lobby_member_change_kicked | steam_lobby_member_change_banned)){
			for (var _j = 0; _j < array_length(playerList); _j++) {
				if playerList[_j].steamID == _fromID {
					if player_entry_has_live_character(playerList[_j]) {
						with (playerList[_j].character) instance_destroy();
					}
					playerList[_j].character = undefined
					playerList[_j].disconnected = true
					show_debug_message("Player Left: " + _fromName)
					mp_debug_log("lobby-leave", "steam=" + string(_fromID) + " name=" + _fromName)
					break
				}
			}
		}
		break
}

