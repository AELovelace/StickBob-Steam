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
vpSizeWidth = 1280
vpSizeLength = 720
global.stopShooting = false
if(isLocal){

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