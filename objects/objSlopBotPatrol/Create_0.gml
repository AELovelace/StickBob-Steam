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
bot_owner_steam_id = -1;
player_target = noone;

nav_profile = scr_smart_nav_profile(id);
nav_chase_speed = nav_profile.max_speed_x;
nav_patrol_speed = max(2, nav_chase_speed * 0.5);
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

patrol_anchor_x = x;
patrol_anchor_y = y;
patrol_radius = 160;
patrol_index = 0;
patrol_wait = 0;
patrol_initialized = false;
patrol_has_custom_route = false;
aggro_range = 360;
lose_aggro_range = 460;
shoot_range = 220;
is_alerted = false;
was_alerted = false;
patrol_points = [
    { x : patrol_anchor_x - patrol_radius, y : patrol_anchor_y },
    { x : patrol_anchor_x + patrol_radius, y : patrol_anchor_y }
];

ds_gridpathfinding = noone;
path_building = noone;
