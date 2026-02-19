
// Network packet type identifiers.
// These values are written as the first byte of every packet so the
// receiver can dispatch to the correct handler.
//
// Flow overview:
//   Client → Server : CLIENT_PLAYER_INPUT  (raw key/mouse data)
//   Server → Client : SERVER_PLAYER_INPUT  (relays host input so clients can simulate the host)
//   Server → Client : PLAYER_POSITION      (authoritative position broadcast each tick)
//   Server → Client : SPAWN_SELF           (tells a joining client where to place their own character)
//   Server → Client : SPAWN_OTHER          (tells existing clients about a newly spawned peer)
//   Server → Client : SYNC_PLAYERS         (JSON snapshot of the full player list on join)
enum NETWORK_PACKETS {
	CLIENT_PLAYER_INPUT = 10,  // client → server: xInput, yInput, runKey, actionKey, mouseAngle
	SERVER_PLAYER_INPUT = 11,  // server → clients: same fields plus steamID of the player
	PLAYER_POSITION     = 12,  // server → clients: steamID + x + y (u16 each)
	SPAWN_OTHER         = 97,  // server → clients: a peer has joined; includes their steamID + start pos
	SPAWN_SELF          = 98,  // server → new client: where the joining player should spawn
	SYNC_PLAYERS        = 99   // server → new client: full JSON player-list snapshot
}
