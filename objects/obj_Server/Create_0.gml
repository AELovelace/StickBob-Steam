/// @description Init Server Variables

playerList = []

steamID = steam_get_user_steam_id()
steamName = steam_get_persona_name()
lobbyMemberID = 0
character = undefined

inbuf = buffer_create(16, buffer_grow, 1);

var _maxHP = mode_max_health()

playerList[0] = {
	steamID			: steamID,
	steamName		: steamName,
	character		: undefined,
	startPos		: grab_spawn_point(0),
	lobbyMemberID	: 0,
	maxHealth		: _maxHP,
	playerHealth	: _maxHP,
	playerColor		: app_settings_current().player_color
	}

// Establish gateway session and (host-only) create a match record so that
// reward events from this lobby can be reported and idempotency-bound.
sgc_gateway_bootstrap(false);
sgc_gateway_match_create();