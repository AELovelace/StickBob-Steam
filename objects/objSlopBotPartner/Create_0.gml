draw_set_color(c_black);

mask_index = sprPlayerIdle;
sprite_index = sprPlayerIdle;

xSpeed = 0;
ySpeed = 0;
xInput = 0;
yInput = 0;
mouseAngle = 0;
nav_grounded = false;
fireCooldown = 15;
currentCooldown = fireCooldown;
bot_owner_steam_id = steam_get_user_steam_id();
partner_steam_id = bot_owner_steam_id;
player_target = noone;

nav_profile = scr_smart_nav_profile(id);
nav_route_speed = max(3, nav_profile.max_speed_x * 0.65);
nav_chase_speed = nav_profile.max_speed_x;
collision_tilemap_id = scr_smart_nav_collision_tilemap();
nav_route = undefined;
nav_target_node = -1;
nav_route_edge_index = 0;
nav_edge_frame = 0;
nav_plan_cooldown = 0;
nav_last_reason = "idle";
nav_stuck_frames = 0;
nav_last_pos_x = x;
nav_last_pos_y = y;

route_points = [];
route_index = 0;
route_initialized = false;
regroup_range = 640;
escort_range = 192;
shoot_range = 260;

ds_gridpathfinding = noone;
path_building = noone;
