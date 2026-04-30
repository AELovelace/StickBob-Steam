if (global.isPaused) {
    exit;
}

if (isDying) {
    xSpeed = 0;
    ySpeed = 0;
    exit;
}

if (!route_initialized) {
    route_points = scr_practice_spawn_route_points();
    route_initialized = true;
}

var _player_exists = instance_exists(player_target);
var _player_distance = _player_exists ? point_distance(x, y, player_target.x, player_target.y) : 1000000;
var _route_count = array_length(route_points);

if (_player_exists && _player_distance >= regroup_range) {
    nav_profile.max_speed_x = nav_chase_speed;
    scr_smart_nav_update_target_position(player_target.x, player_target.y, player_target.x, player_target.y);
} else if (_route_count > 0) {
    nav_profile.max_speed_x = nav_route_speed;
    var _route_target = route_points[route_index];
    scr_smart_nav_update_target_position(_route_target.x, _route_target.y, _route_target.x, _route_target.y);
    if (point_distance(x, y, _route_target.x, _route_target.y) <= nav_profile.cell_w * 1.5) {
        route_index = (route_index + 1) mod array_length(route_points);
        scr_smart_nav_reset_route("route_turn");
    }
} else if (_player_exists && _player_distance > escort_range) {
    nav_profile.max_speed_x = nav_chase_speed;
    scr_smart_nav_update_target_position(player_target.x, player_target.y, player_target.x, player_target.y);
}

scr_smart_nav_update_sprite();

var _enemy = noone;
var _enemy_dist = 1000000;
for (var _i = 0; _i < instance_number(obj_Player); _i += 1) {
    var _candidate = instance_find(obj_Player, _i);
    if (_candidate == noone) {
        continue;
    }
    var _dist = point_distance(x, y, _candidate.x, _candidate.y);
    if (_dist < shoot_range && _dist < _enemy_dist) {
        _enemy = _candidate;
        _enemy_dist = _dist;
    }
}

if (_enemy != noone) {
    mouseAngle = point_direction(x, y, _enemy.x, _enemy.y);
}

var _distance = 48;
var _gun_distance = 20;
if currentCooldown > 0 then --currentCooldown;
if (_enemy != noone && currentCooldown <= 0 && global.stopShooting == false) {
    var _bullet_x = x + lengthdir_x(_distance, mouseAngle);
    var _bullet_y = y + lengthdir_y(_distance, mouseAngle);
    var _bullet = instance_create_layer(_bullet_x, _bullet_y, "Instances", obj_Bullet_simple);
    _bullet.direction = mouseAngle;
    _bullet.image_angle = _bullet.direction;
    _bullet.owner_id = id;
    _bullet.owner_steam_id = bot_owner_steam_id;
    audio_play_sound(wob_wob_2, 10, 0);

    var _fx = x + lengthdir_x(_gun_distance, mouseAngle);
    var _fy = y + lengthdir_y(_gun_distance, mouseAngle);
    effect_create_above(ef_smokeup, _fx, _fy, .05, c_ltgray);
    effect_create_above(ef_smoke, _fx, _fy, .05, c_grey);
    effect_create_above(ef_spark, _fx, _fy, .05, c_orange);
    currentCooldown = fireCooldown;
}
