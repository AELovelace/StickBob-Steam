/// @description Setup Player
wallJump = 0;
background_map = ds_map_create();
background_map[? layer_get_id("bgClouds")] = 0.3;
background_map[? layer_get_id("bgDistantGround")] = 0.2;
background_map[? layer_get_id("bgNearGround")] = 0.1;
background_map[? layer_get_id("bgGroundPath")] = 0;
background_map[? layer_get_id("bgForeground")] = -0.5;
localSteamID = steam_get_user_steam_id()
lobbyHost = steam_lobby_get_owner_id()
isHost = steam_lobby_is_owner()
isLocal = (localSteamID == steamID)
playerID = id
mask_index = sprPlayerIdle;
collision_tilemap_id = layer_tilemap_get_id("CollisionLayer");
collisionObjects = [objSolid, collision_tilemap_id]
collision = false;
moveSpeed = 1
fireCooldown = 10
currentCooldown = 0
xSpeed = 0; 
ySpeed = 0;
grav = 0.4;
jumpSpeed = -10
canJump = true;
canSlide = false
isCrawling = false;
fallCooldown = 0;
climbHeight = 8;
mouseAngle = 0;
collisionAngle = 0;
releasedJump = false;
netX      = 0
netY      = 0
hasNetPos = false
wallJumpTimer = 20;
cwjt = 0;
init_controls()
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
global.stopShooting = false
if !variable_instance_exists(id, "gameMode") then gameMode = global.gameParams.modeSelection
if !variable_instance_exists(id, "maxHealth") then maxHealth = mode_max_health(gameMode)
if !variable_instance_exists(id, "playerHealth") then playerHealth = maxHealth
respawn_x = x
respawn_y = y
if(isLocal){

    // Local player drives the output viewport dimensions.
    view_enabled = true;
	view_visible[lobbyMemberID] = true;
	view_wport[lobbyMemberID] = vpSizeWidth
	view_hport[lobbyMemberID] = vpSizeLength
	camera_set_view_size(view_camera[lobbyMemberID], 320, 240);
	surface_resize(application_surface, view_wport[lobbyMemberID], view_hport[lobbyMemberID]);
	window_set_size(vpSizeWidth, vpSizeLength);
	window_center();
	camera_set_view_size(view_camera[lobbyMemberID], 320, 240);
	target_instance = playerID
}

if (isLocal) {
	sgc_gateway_begin_level_balance_cycle();
}
