/// @description Insert description here
// You can write your code in this editor

// Inherit the parent event
event_inherited();

image_xscale = 5
image_yscale = .75

selectAction = function () {
	global.client = instance_create_depth(0,0,0,obj_Client)
	var _lobbyIndex = 0
	if variable_instance_exists(id, "lobby_index") then _lobbyIndex = variable_instance_get(id, "lobby_index")
	steam_lobby_list_join(_lobbyIndex)
	if variable_instance_exists(id, "lobby_mode") {
		var _rawMode = string(variable_instance_get(id, "lobby_mode"))
		if string_length(_rawMode) > 0 {
			global.gameParams.modeSelection = real(_rawMode)
		} else {
			global.gameParams.modeSelection = global.GAME_MODE_CLASSIC
		}
	} else {
		global.gameParams.modeSelection = global.GAME_MODE_CLASSIC
	}
	var _lobbyMap = ""
	if variable_instance_exists(id, "lobby_map") then _lobbyMap = string(variable_instance_get(id, "lobby_map"))
	targetRoom = string_delete(_lobbyMap,1,9)
	show_debug_message("mapReceived: " + targetRoom)
	if(targetRoom == "MPB1"){
		room_goto(MPB1)
	} else if (targetRoom == "MPB3") {
		room_goto(MPB3)
	} else {
		room_goto(MPB2)
	}
}