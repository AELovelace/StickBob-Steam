/// @description Listening for Activity as Client

// Receive Packets
while(steam_net_packet_receive()){
	
	var _sender = steam_net_packet_get_sender_id();
	steam_net_packet_get_data(inbuf);
	buffer_seek(inbuf, buffer_seek_start, 0);
	var _type = buffer_read(inbuf, buffer_u8);
	
	switch _type{
		case NETWORK_PACKETS.SYNC_PLAYERS:
			var _playerList = buffer_read(inbuf, buffer_string);
			_playerList = json_parse(_playerList)
			sync_players(_playerList)
			break
		case NETWORK_PACKETS.SPAWN_OTHER:
			var _layer = layer_get_id("Instances");
			var _x = buffer_read(inbuf, buffer_u16)
			var _y = buffer_read(inbuf, buffer_u16)
			var _steamID = buffer_read(inbuf, buffer_u64)
			var _packetName = buffer_read(inbuf, buffer_string)
			var _num = array_length(playerList)
			var _maxHP = mode_max_health()
			// Look up playerColor from list if already synced via SYNC_PLAYERS
			var _spawnedColor = c_white
			var _spawnedName = _packetName
			if !is_string(_spawnedName) || string_length(_spawnedName) <= 0 {
				_spawnedName = steam_get_user_persona_name(_steamID)
			}
			var _existingIndex = -1
			for (var _ci = 0; _ci < array_length(playerList); _ci++) {
				if playerList[_ci].steamID == _steamID {
					_existingIndex = _ci
					_spawnedColor = variable_struct_exists(playerList[_ci], "playerColor") ? playerList[_ci].playerColor : c_white
					if variable_struct_exists(playerList[_ci], "steamName") && is_string(playerList[_ci].steamName) {
						_spawnedName = playerList[_ci].steamName
					}
					if variable_struct_exists(playerList[_ci], "lobbyMemberID") && playerList[_ci].lobbyMemberID != undefined {
						_num = playerList[_ci].lobbyMemberID
					}
					break
				}
			}
			var _inst = instance_create_layer(_x,_y,_layer,obj_Player,{
							steamName : _spawnedName,
							steamID : _steamID,
							lobbyMemberID : _num,
							maxHealth : _maxHP,
							playerHealth : _maxHP,
							gameMode : global.gameParams.modeSelection,
							playerColor : _spawnedColor
							})
			if (_existingIndex != -1) {
				playerList[_existingIndex].character = _inst
				playerList[_existingIndex].startPos = {x:_x, y:_y}
				playerList[_existingIndex].lobbyMemberID = _num
				playerList[_existingIndex].steamName = _spawnedName
				playerList[_existingIndex].maxHealth = _maxHP
				playerList[_existingIndex].playerHealth = _maxHP
				playerList[_existingIndex].playerColor = _spawnedColor
			} else {
				array_push(playerList, {
					steamID	 : _steamID,
					steamName: _spawnedName,
					character: _inst,
					lobbyMemberID : _num,
					startPos: {x:_x, y:_y},
					maxHealth: _maxHP,
					playerHealth: _maxHP,
					playerColor: _spawnedColor
				})
			}
			break
			
		case NETWORK_PACKETS.SPAWN_SELF:
			var _layer = layer_get_id("Instances");
			var _x = buffer_read(inbuf, buffer_u16)
			var _y = buffer_read(inbuf, buffer_u16)
			// Slot is now authoritative from the server — no longer depends on
			// SYNC_PLAYERS having arrived first (fixes the UDP reorder freeze bug).
			var _slot = buffer_read(inbuf, buffer_u8)
			lobbyMemberID = _slot
			var _maxHP = mode_max_health()
			var _localColor = app_settings_current().player_color
			var _inst = instance_create_layer(_x,_y,_layer,obj_Player,{
							steamName	: steamName,
							steamID: steamID,
							lobbyMemberID: _slot,
							maxHealth : _maxHP,
							playerHealth : _maxHP,
							gameMode : global.gameParams.modeSelection,
							playerColor : _localColor
						})
			// Find our own entry in playerList rather than always assuming index 0
			var _myIdx = 0
			for (var _ci = 0; _ci < array_length(playerList); _ci++) {
				if playerList[_ci].steamID == steamID { _myIdx = _ci; break }
			}
			playerList[_myIdx].character = _inst
			playerList[_myIdx].maxHealth = _maxHP
			playerList[_myIdx].playerHealth = _maxHP
			playerList[_myIdx].lobbyMemberID = _slot
			character = _inst
			// Local player — mirror chosen color in the local player list
			playerList[_myIdx].playerColor = _localColor
			break

		case NETWORK_PACKETS.SERVER_PLAYER_INPUT:
			receive_player_input(inbuf)
			break
			
		case NETWORK_PACKETS.PLAYER_POSITION:
			update_player_position(inbuf)
			break

			case NETWORK_PACKETS.PLAYER_HEALTH:
				receive_player_health(inbuf)
				break
			
		case NETWORK_PACKETS.PLAYER_COLOR:
			apply_player_color(inbuf)
			break

		default:
			show_debug_message("Unknown packet received: "+string(_type))
			break
	}
}