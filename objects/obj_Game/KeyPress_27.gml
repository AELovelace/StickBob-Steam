/// @description Exit
// Don't toggle pause while the chat input box is open — ESC closes chat first.
if (variable_instance_exists(id, "chat_open") && chat_open) exit;
if(global.isPaused == false){
	global.isPaused = true
} else{
		global.isPaused = false;	
}