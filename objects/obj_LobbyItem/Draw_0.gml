/// @description Insert description here
// You can write your code in this editor
draw_self()
draw_set_halign(fa_left)
draw_set_valign(fa_top)

var _hasLobbyID = variable_instance_exists(id, "lobby_id")
var _lobbyID = -1
if _hasLobbyID then _lobbyID = variable_instance_get(id, "lobby_id")

if _lobbyID != -1 {
	var _mode_label = "Classic"
	if variable_instance_exists(id, "lobby_mode_name") {
		var _rawModeName = string(variable_instance_get(id, "lobby_mode_name"))
		if string_length(_rawModeName) > 0 then _mode_label = _rawModeName
	}
	var _creator = "Unknown"
	if variable_instance_exists(id, "lobby_creator") then _creator = string(variable_instance_get(id, "lobby_creator"))
	var _mapName = "Unknown"
	if variable_instance_exists(id, "lobby_map") then _mapName = string(variable_instance_get(id, "lobby_map"))

	draw_text_transformed(bbox_left+10,y-20,"LobbyID: " + string(_lobbyID),.5,.5,0)
	draw_text_transformed(bbox_left+10,y-10,"Creator: " + _creator,.5,.5,0)
	draw_text_transformed(bbox_left+10,y,"MapName: " + _mapName,.5,.5,0)
	draw_text_transformed(bbox_left+10,y+10,"Mode: " + _mode_label,.5,.5,0)
} else {
	draw_text(bbox_left+10,y,"Searching...")
}