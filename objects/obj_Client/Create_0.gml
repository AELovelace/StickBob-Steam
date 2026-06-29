/// @description Init Client Variables

playerList = []
pendingPlayerInputs = []

steamID = steam_get_user_steam_id()
steamName = steam_get_persona_name()
lobbyMemberID = undefined
lobbyHost = steam_lobby_get_owner_id()
character = undefined

inbuf = buffer_create(16, buffer_grow, 1);
spawn_resync_next_time = current_time + 750
spawn_resync_attempts = 0
spawn_resync_active = true
spawn_resync_last_host = lobbyHost

// Phase 1.1: protocol handshake state
hello_sent = false
hello_ack_received = false
hello_next_time = current_time + 200  // small delay so lobby host id is ready

// Phase 2.1: heartbeat schedule
heartbeat_next_time = current_time + MP_HEARTBEAT_INTERVAL_MS
mp_liveness_init()

var _maxHP = mode_max_health()

playerList[0] = {
	steamID		: steamID,
	steamName	: steamName,
	character	: undefined,
	startPos	: grab_spawn_point(0),
	lobbyMemberID : undefined,
	maxHealth	: _maxHP,
	playerHealth	: _maxHP,
	playerColor	: app_settings_current().player_color
	}

mp_debug_log("client-create", "steam=" + string(steamID) + " host=" + string(lobbyHost))

// Establish a gateway session for this client. Match registration is
// driven host-side and gets joined later through gameplay packets.
sgc_gateway_bootstrap(false);
