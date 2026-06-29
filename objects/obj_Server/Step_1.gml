/// @description Listening for Activity as Server

// Phase 2: heartbeat + timeout detection on a 1s cadence.
if (current_time >= heartbeat_next_time) {
	heartbeat_next_time = current_time + MP_HEARTBEAT_INTERVAL_MS
	send_heartbeat_to_peers()
}
if (current_time >= timeout_next_check) {
	timeout_next_check = current_time + 1000
	var _timed_out = find_timed_out_peers()
	for (var _ti = 0; _ti < array_length(_timed_out); _ti++) {
		var _dead_id = _timed_out[_ti]
		for (var _pi = 0; _pi < array_length(playerList); _pi++) {
			if playerList[_pi].steamID == _dead_id {
				mp_mark_disconnected(playerList[_pi])
				mp_debug_log("server-peer-timeout", "steam=" + string(_dead_id))
				break
			}
		}
	}
	mp_sweep_rejoin_grace()
}

// Receive Packets
while(steam_net_packet_receive()){

	var _sender = steam_net_packet_get_sender_id();
	steam_net_packet_get_data(inbuf);
	buffer_seek(inbuf, buffer_seek_start, 0);
	if (buffer_get_size(inbuf) < 1) continue
	var _type = buffer_read(inbuf, buffer_u8);
	mp_touch_peer(_sender)

	// Phase 1.2: dispatch under try/catch so a malformed packet only drops
	// one message instead of crashing the server.
	try {
		switch _type {
			case NETWORK_PACKETS.HELLO:
				receive_hello(inbuf, _sender)
				break

			case NETWORK_PACKETS.HEARTBEAT:
				// Phase 2: liveness tracked elsewhere via last-packet-time
				break

			case NETWORK_PACKETS.CLIENT_PLAYER_INPUT:
				var _playerInput = receive_player_input(inbuf, _sender)
				send_player_input_to_clients(_playerInput, _sender)
				break

			case NETWORK_PACKETS.CLIENT_SPAWN_RESYNC:
				var _slot = find_player_entry_index_by_steam_id(_sender)
				if (_slot != -1) {
					send_player_sync(_sender)
					send_player_spawn(_sender, _slot)
					mp_debug_log("server-spawn-resync", "steam=" + string(_sender) + " slot=" + string(_slot))
				} else {
					mp_debug_log("server-spawn-resync-miss", "steam=" + string(_sender) + " reason=slot_not_found")
				}
				break

			case NETWORK_PACKETS.PLAYER_COLOR:
				receive_player_color(inbuf, _sender)
				break

			case NETWORK_PACKETS.CLIENT_READY:
				receive_client_ready(inbuf, _sender)
				break

			case NETWORK_PACKETS.MATCH_START_ACK:
				receive_match_start_ack(_sender)
				break

			case NETWORK_PACKETS.REJOIN_REQUEST:
				receive_rejoin_request(inbuf, _sender)
				break

			case NETWORK_PACKETS.CHAT_MESSAGE:
				receive_chat_message(inbuf, _sender)
				break

			case NETWORK_PACKETS.PLAYER_SPECTATOR:
				receive_player_spectator(inbuf, _sender)
				break

			default:
				mp_debug_log("server-packet-unknown", "type=" + string(_type) + " from=" + string(_sender))
				break
		}
	} catch (_ex) {
		mp_debug_log("server-packet-exception",
			"type=" + mp_debug_packet_name(_type)
			+ " sender=" + string(_sender)
			+ " msg=" + mp_exception_message(_ex)
		)
	}
}
