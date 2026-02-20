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