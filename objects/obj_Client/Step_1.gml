/// @description Listening for Activity as Client

// Send HELLO once on join so the host can validate our protocol version.
// We defer the spawn-resync loop until HELLO_ACK arrives so that a refused
// (KICK_VERSION) client never sees a spawn cycle.
if (!hello_sent) {
	if (lobbyHost <= 0) lobbyHost = steam_lobby_get_owner_id()
	if (lobbyHost > 0 && current_time >= hello_next_time) {
		send_hello(lobbyHost)
		hello_sent = true
		hello_next_time = current_time + 1500
	}
}

// Phase 2.1: heartbeat to host every 2s so the host can detect timeouts.
if (hello_ack_received && current_time >= heartbeat_next_time) {
	heartbeat_next_time = current_time + MP_HEARTBEAT_INTERVAL_MS
	if (lobbyHost > 0) send_heartbeat(lobbyHost)
}

// Phase 2.3: host-leave detection. If we've heard from the host once but
// nothing recent, assume the lobby is dead and tear down cleanly.
if (hello_ack_received && lobbyHost > 0) {
	var _seen = mp_last_seen_ms(lobbyHost)
	if (_seen != undefined && (current_time - _seen) > MP_PEER_TIMEOUT_MS) {
		mp_debug_log("client-host-timeout", "host=" + string(lobbyHost) + " silent_ms=" + string(current_time - _seen))
		global.mp_last_kick_reason = { kind: "host_left", host: lobbyHost }
		shutdown_multiplayer("host_left")
		exit
	}
}

if (spawn_resync_active && hello_ack_received) {
	var _hasLocalCharacter = (character != undefined) && instance_exists(character)
	if (!_hasLocalCharacter && current_time >= spawn_resync_next_time) {
		if (spawn_resync_attempts >= MP_SPAWN_RESYNC_MAX_ATTEMPTS) {
			mp_debug_log("client-spawn-resync-giveup", "attempts=" + string(spawn_resync_attempts))
			global.mp_last_kick_reason = { kind: "spawn_failed", host: lobbyHost }
			shutdown_multiplayer("spawn_resync_giveup")
			exit
		}
		if (lobbyHost <= 0) {
			lobbyHost = steam_lobby_get_owner_id()
		}
		if (lobbyHost > 0) {
			var _resync = buffer_create(1, buffer_fixed, 1)
			buffer_write(_resync, buffer_u8, NETWORK_PACKETS.CLIENT_SPAWN_RESYNC)
			steam_net_packet_send(lobbyHost, _resync)
			buffer_delete(_resync)
			spawn_resync_attempts += 1
			spawn_resync_last_host = lobbyHost
			mp_debug_log("client-spawn-resync", "attempt=" + string(spawn_resync_attempts) + " host=" + string(lobbyHost) + " room=" + room_get_name(room))
		}
		spawn_resync_next_time = current_time + 700
	}
}

// Receive Packets
while(steam_net_packet_receive()){

	var _sender = steam_net_packet_get_sender_id();
	steam_net_packet_get_data(inbuf);
	buffer_seek(inbuf, buffer_seek_start, 0);
	if (buffer_get_size(inbuf) < 1) continue
	var _type = buffer_read(inbuf, buffer_u8);
	mp_touch_peer(_sender)

	try {
	switch _type{
		case NETWORK_PACKETS.HELLO_ACK:
			var _server_proto = mp_buffer_safe_read(inbuf, buffer_u32, 0)
			hello_ack_received = true
			mp_debug_log("client-hello-ack", "server_proto=" + string(_server_proto))
			// Phase 5.2: ask host to restore prior session if it still has us in
			// the grace window. No-op for fresh joins (host will simply ignore).
			send_rejoin_request(lobbyHost)
			break

		case NETWORK_PACKETS.KICK_VERSION:
			receive_kick_version(inbuf)
			exit  // shutdown_multiplayer destroyed us
			break

		case NETWORK_PACKETS.HEARTBEAT:
			// Phase 2: liveness tracked elsewhere
			break

		case NETWORK_PACKETS.SYNC_PLAYERS:
			var _playerList = buffer_read(inbuf, buffer_string);
			_playerList = json_parse(_playerList)
			mp_debug_log("client-packet", "received " + mp_debug_packet_name(_type) + " from=" + string(_sender) + " count=" + string(array_length(_playerList)))
			sync_players(_playerList)
			break
		case NETWORK_PACKETS.SPAWN_OTHER:
			var _layer = layer_get_id("Instances");
			var _x = buffer_read(inbuf, buffer_u16)
			var _y = buffer_read(inbuf, buffer_u16)
			var _steamID = buffer_read(inbuf, buffer_u64)
			var _packetName = buffer_read(inbuf, buffer_string)
			mp_debug_log("client-packet", "received SPAWN_OTHER from=" + string(_sender) + " steam=" + string(_steamID) + " pos=(" + string(_x) + "," + string(_y) + ")")
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
			var _inst = undefined
			if (_existingIndex != -1) && player_entry_has_live_character(playerList[_existingIndex]) {
				_inst = playerList[_existingIndex].character
				with (_inst) {
					x = _x
					y = _y
					netX = _x
					netY = _y
					hasNetPos = true
				}
			} else {
				_inst = instance_create_layer(_x,_y,_layer,obj_Player,{
								steamName : _spawnedName,
								steamID : _steamID,
								lobbyMemberID : _num,
								maxHealth : _maxHP,
								playerHealth : _maxHP,
								gameMode : global.gameParams.modeSelection,
								playerColor : _spawnedColor
								})
			}
			if (_existingIndex != -1) {
				playerList[_existingIndex].character = _inst
				playerList[_existingIndex].startPos = {x:_x, y:_y}
				playerList[_existingIndex].lobbyMemberID = _num
				playerList[_existingIndex].steamName = _spawnedName
				playerList[_existingIndex].maxHealth = _maxHP
				playerList[_existingIndex].playerHealth = _maxHP
				playerList[_existingIndex].playerColor = _spawnedColor
				apply_pending_player_input(_steamID)
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
				apply_pending_player_input(_steamID)
			}
			break
			
		case NETWORK_PACKETS.SPAWN_SELF:
			var _layer = layer_get_id("Instances");
			var _x = buffer_read(inbuf, buffer_u16)
			var _y = buffer_read(inbuf, buffer_u16)
			// Slot is now authoritative from the server — no longer depends on
			// SYNC_PLAYERS having arrived first (fixes the UDP reorder freeze bug).
			var _slot = buffer_read(inbuf, buffer_u8)
			mp_debug_log("client-packet", "received SPAWN_SELF from=" + string(_sender) + " slot=" + string(_slot) + " pos=(" + string(_x) + "," + string(_y) + ")")
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
			// Force the server address from the packet sender so it's correct even
			// if steam_lobby_get_owner_id() returned 0 at Create_0 time.
			variable_instance_set(_inst, "lobbyHost", _sender)
			mp_debug_log("client-lobbyhost-set", "steam=" + string(steamID) + " host=" + string(_sender))
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
			spawn_resync_active = false
			break

		case NETWORK_PACKETS.SERVER_PLAYER_INPUT:
			receive_player_input(inbuf)
			break
			
		case NETWORK_PACKETS.PLAYER_POSITION:
			update_player_position(inbuf, _sender)
			break

			case NETWORK_PACKETS.PLAYER_HEALTH:
				receive_player_health(inbuf)
				break
			
		case NETWORK_PACKETS.PLAYER_COLOR:
			apply_player_color(inbuf)
			break

		case NETWORK_PACKETS.LOBBY_STATE:
			receive_lobby_state(inbuf)
			break

		case NETWORK_PACKETS.MATCH_START:
			receive_match_start(inbuf)
			break

		case NETWORK_PACKETS.MATCH_END:
			receive_match_end(inbuf)
			break

		case NETWORK_PACKETS.ROOM_CHANGE:
			receive_room_change(inbuf)
			break

		case NETWORK_PACKETS.HAZARD_SPAWN:
			mp_receive_hazard_spawn(inbuf)
			break

		case NETWORK_PACKETS.HAZARD_DESPAWN:
		case NETWORK_PACKETS.BULLET_DESPAWN:
		case NETWORK_PACKETS.COLLECTIBLE_PICKUP:
			mp_receive_entity_despawn(inbuf)
			break

		case NETWORK_PACKETS.BULLET_SPAWN:
			mp_receive_bullet_spawn(inbuf)
			break

		case NETWORK_PACKETS.COLLECTIBLE_SPAWN:
			mp_receive_collectible_spawn(inbuf)
			break

		case NETWORK_PACKETS.WORLD_TICK:
			mp_receive_world_tick(inbuf)
			break

		case NETWORK_PACKETS.WORLD_SNAPSHOT:
			receive_world_snapshot(inbuf)
			break

		case NETWORK_PACKETS.CHAT_MESSAGE:
			receive_chat_message(inbuf, _sender)
			break

		case NETWORK_PACKETS.PLAYER_SPECTATOR:
			receive_player_spectator(inbuf, _sender)
			break

		default:
			show_debug_message("Unknown packet received: "+string(_type))
			mp_debug_log("client-packet", "unknown packet type=" + string(_type) + " from=" + string(_sender))
			break
	}
	} catch (_ex) {
		mp_debug_log("client-packet-exception",
			"type=" + mp_debug_packet_name(_type)
			+ " sender=" + string(_sender)
			+ " msg=" + mp_exception_message(_ex)
		)
	}
}
