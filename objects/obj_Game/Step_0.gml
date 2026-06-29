// Global hotkey: toggle fullscreen/windowed and persist choice.
if keyboard_check_pressed(vk_f11) {
	app_settings_toggle_fullscreen()
}

if keyboard_check_pressed(vk_f10) {
	show_debug_log(true)
	mp_debug_log("debug", "opened debug overlay log")
}

if keyboard_check_pressed(vk_f9) {
	mp_debug_init(true)
	mp_debug_log("debug", "reset multiplayer debug log")
}

// ── Phase 6.1: Chat input (only active when in a networked match) ────────
var _in_mp = instance_exists(obj_Server) || instance_exists(obj_Client)
if (_in_mp) {
	if (!chat_open && keyboard_check_pressed(ord("T"))) {
		chat_open  = true
		chat_input = ""
		keyboard_string = ""
	} else if (chat_open) {
		// Live-bind keyboard_string while open
		chat_input = string_copy(keyboard_string, 1, MP_CHAT_MAX_LEN)
		if (keyboard_check_pressed(vk_enter)) {
			if (string_length(string_trim(chat_input)) > 0) send_chat_message(chat_input)
			chat_open = false
			chat_input = ""
			keyboard_string = ""
		} else if (keyboard_check_pressed(vk_escape)) {
			chat_open = false
			chat_input = ""
			keyboard_string = ""
		}
	}
}
