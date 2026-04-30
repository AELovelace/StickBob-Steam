/// @description Setup Player
variableInitAll()
variableInitSP()
parallaxDefinition()
init_controls()
global.isPaused = false;
mask_index = sprPlayerIdle;
xSpeed = 0; 
ySpeed = 0;
speedBar = 0;
playerHealth = 5;
zoomDelay = 0;
camLookAhead = 0;
selectedWeaponSlot = 1;
machinegunFireCooldown = 3;
//screen init
// Pull current resolution from persisted app settings.
var _settings = app_settings_defaults()
if variable_global_exists("appSettings") then _settings = variable_global_get("appSettings")
if !is_struct(_settings) then _settings = app_settings_defaults()
var _fullscreen = false
if variable_struct_exists(_settings, "fullscreen") then _fullscreen = (variable_struct_get(_settings, "fullscreen") == true)
vpSizeWidth = max(320, real(variable_struct_get(_settings, "resolution_width")))
vpSizeLength = max(240, real(variable_struct_get(_settings, "resolution_height")))
if _fullscreen {
	// Fullscreen should use the current display size, not the windowed preset.
	vpSizeWidth = display_get_width()
	vpSizeLength = display_get_height()
}
global.baseW = noone
global.baseH = noone
if(isLocal){

    view_enabled = true;
	view_visible[1] = true;
	view_wport[1] = vpSizeWidth
	view_hport[1] = vpSizeLength
	camera_set_view_size(view_camera[1], 320, 240);
	surface_resize(application_surface, view_wport[1], view_hport[1]);
	window_set_size(vpSizeWidth, vpSizeLength);
	window_center();
	camera_set_view_size(view_camera[1], 320, 240);
	target_instance = playerID
}
display_set_gui_size(global.baseW, global.baseH);  // lock the GUI layer to design resolution

// --- HTML5: fill the browser window, accounting for browser chrome ---
if (os_browser != browser_not_a_browser) {
    var _bar_h = (os_browser == browser_opera) ? 50 : 0;  // Opera GX has a ~50px game bar at the bottom
    var _bw = browser_width  - 10;                        // viewport width minus a small safety margin
    var _bh = browser_height - 10 - _bar_h;               // viewport height minus margin and any browser bar
    window_set_size(_bw, _bh);                            // resize the game canvas to fit the usable area
}

// Singleplayer rooms do not spawn obj_Server/obj_Client, so the local player
// owns the gateway lifecycle and creates a reward match for kill payouts.
if (isLocal && !instance_exists(obj_Server) && !instance_exists(obj_Client)) {
	sgc_gateway_begin_singleplayer_match();
	sgc_gateway_bootstrap(false);
	sgc_gateway_spawn_singleplayer_collectibles(x, y);
}

if (isLocal) {
	sgc_gateway_begin_level_balance_cycle();
}
