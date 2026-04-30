draw_set_color(c_black);

mask_index = sprPlayerIdle;
sprite_index = sprPlayerIdle;

xSpeed = 0;
ySpeed = 0;
xInput = 0;
yInput = 0;
mouseAngle = 0;
nav_grounded = false;
fireCooldown = 60;
currentCooldown = fireCooldown;
playerHealth = 1;
maxHealth = 1;
isDying = false;
bot_owner_steam_id = -1;

nav_profile = scr_smart_nav_profile(id);
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

ds_gridpathfinding = noone;
path_building = noone;
