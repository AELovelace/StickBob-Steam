/// @description Listening for Activity as Server

// Receive Packets
while(steam_net_packet_receive()){
	
	var _sender = steam_net_packet_get_sender_id();
	steam_net_packet_get_data(inbuf);
	buffer_seek(inbuf, buffer_seek_start, 0);
	var _type = buffer_read(inbuf, buffer_u8);
	
	switch _type{
		case NETWORK_PACKETS.CLIENT_PLAYER_INPUT:
			var _playerInput = receive_player_input(inbuf, _sender);
			send_player_input_to_clients(_playerInput);
			break

		case NETWORK_PACKETS.PLAYER_COLOR:
			receive_player_color(inbuf, _sender)
			break
			
		default:
			show_debug_message("Unknown packet received: "+string(_type))
			break
	}
	
}