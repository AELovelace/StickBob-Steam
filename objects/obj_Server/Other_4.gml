/// @description Spawn Players
var _playerLayer = layer_get_id("Instances")
steam_lobby_set_data("Mode", string(global.gameParams.modeSelection));
steam_lobby_set_data("ModeName", (global.gameParams.modeSelection == global.GAME_MODE_HP5) ? "HP5" : "Classic");
for (var _player = 0; _player < array_length(playerList); _player++) {
	var _pos = grab_spawn_point(_player)
	var _maxHP = playerList[_player].maxHealth
	if _maxHP == undefined then _maxHP = mode_max_health()
	var _hp = playerList[_player].playerHealth
	if _hp == undefined then _hp = _maxHP
	var _color = variable_struct_exists(playerList[_player], "playerColor") ? playerList[_player].playerColor : c_white
	var _inst = instance_create_layer(_pos.x,_pos.y,_playerLayer,obj_Player,
								{
									steamName	: playerList[_player].steamName,
									steamID: playerList[_player].steamID,
									lobbyMemberID: playerList[_player].lobbyMemberID,
									maxHealth: _maxHP,
									playerHealth: _hp,
									gameMode: global.gameParams.modeSelection,
									playerColor: _color
								})
	playerList[_player].character = _inst
	playerList[_player].startPos = _pos
	playerList[_player].maxHealth = _maxHP
	playerList[_player].playerHealth = _hp
	if (playerList[_player].steamID == steamID) then character = _inst
}

alarm[0] = 5