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
