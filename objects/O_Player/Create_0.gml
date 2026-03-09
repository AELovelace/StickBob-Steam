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
//screen init
vpSizeWidth = 1280
vpSizeLength = 720
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