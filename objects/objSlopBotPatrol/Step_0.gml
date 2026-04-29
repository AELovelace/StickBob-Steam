if (global.isPaused) {
    exit;
}

var _target_player = noone;
if (instance_exists(player_target)) {
    _target_player = player_target;
} else if (instance_exists(obj_Player)) {
    _target_player = instance_find(obj_Player, 0);
    player_target = _target_player;
}
var _player_exists = instance_exists(_target_player);
var _player_distance = _player_exists ? point_distance(x, y, _target_player.x, _target_player.y) : 1000000;

if (_player_exists && _player_distance <= aggro_range) {
    is_alerted = true;
} else if (!_player_exists || _player_distance >= lose_aggro_range) {
    is_alerted = false;
}

if (is_alerted != was_alerted) {
    if (is_alerted) {
        nav_profile.max_speed_x = nav_chase_speed;
        scr_smart_nav_reset_route("alerted");
    } else {
        nav_profile.max_speed_x = nav_patrol_speed;
        patrol_index = 0;
        var _best_patrol_dist = 1000000;
        for (var _patrol_i = 0; _patrol_i < array_length(patrol_points); _patrol_i += 1) {
            var _patrol_point = patrol_points[_patrol_i];
            var _patrol_dist = point_distance(x, y, _patrol_point.x, _patrol_point.y);
            if (_patrol_dist < _best_patrol_dist) {
                _best_patrol_dist = _patrol_dist;
                patrol_index = _patrol_i;
            }
        }
        patrol_wait = 0;
        scr_smart_nav_reset_route("return_to_patrol");
    }
    was_alerted = is_alerted;
}

if (!patrol_initialized) {
    if (!patrol_has_custom_route || array_length(patrol_points) <= 1) {
        var _nav = scr_smart_nav_build_room(nav_profile);
        var _origin_node = scr_smart_nav_find_nearest_node(_nav, patrol_anchor_x, patrol_anchor_y, 4);
        if (_origin_node != -1) {
            var _origin = _nav.nodes[_origin_node];
            var _left_target_x = patrol_anchor_x - patrol_radius;
            var _right_target_x = patrol_anchor_x + patrol_radius;
            var _left_node = _origin_node;
            var _right_node = _origin_node;
            var _left_score = 1000000;
            var _right_score = 1000000;

            for (var _i = 0; _i < array_length(_nav.nodes); _i += 1) {
                var _node = _nav.nodes[_i];
                if (abs(_node.cy - _origin.cy) > 2) {
                    continue;
                }

                if (_node.x <= _origin.x) {
                    var _left_delta = abs(_node.x - _left_target_x) + abs(_node.y - patrol_anchor_y);
                    if (_left_delta < _left_score) {
                        _left_score = _left_delta;
                        _left_node = _i;
                    }
                }

                if (_node.x >= _origin.x) {
                    var _right_delta = abs(_node.x - _right_target_x) + abs(_node.y - patrol_anchor_y);
                    if (_right_delta < _right_score) {
                        _right_score = _right_delta;
                        _right_node = _i;
                    }
                }
            }

            patrol_points = [
                { x : _nav.nodes[_left_node].x, y : _nav.nodes[_left_node].y },
                { x : _nav.nodes[_right_node].x, y : _nav.nodes[_right_node].y }
            ];
        }
    }
    nav_profile.max_speed_x = nav_patrol_speed;
    patrol_initialized = true;
}

if (is_alerted && _player_exists) {
    patrol_wait = 0;
    scr_smart_nav_update(_target_player);
    scr_smart_nav_update_sprite();
} else if (patrol_wait > 0) {
    patrol_wait -= 1;
    scr_smart_nav_apply_instance_input(0, false, nav_profile, scr_smart_nav_collision_tilemap());
    scr_smart_nav_update_sprite();
} else {
    var _target = patrol_points[patrol_index];
    scr_smart_nav_update_target_position(_target.x, _target.y, _target.x, _target.y);
    scr_smart_nav_update_sprite();

    if (point_distance(x, y, _target.x, _target.y) <= nav_profile.cell_w * 1.25) {
        patrol_index = (patrol_index + 1) mod array_length(patrol_points);
        patrol_wait = 20;
        scr_smart_nav_reset_route("patrol_turn");
    }
}

if (_player_exists) {
    mouseAngle = point_direction(x, y, _target_player.x, _target_player.y);
}

var _distance = 48;
var _gun_distance = 20;
if currentCooldown > 0 then --currentCooldown;
if (is_alerted && _player_exists && currentCooldown <= 0 && _player_distance < shoot_range) {
    var _bullet_x = x + lengthdir_x(_distance, mouseAngle);
    var _bullet_y = y + lengthdir_y(_distance, mouseAngle);
    var _bullet = instance_create_layer(_bullet_x, _bullet_y, "Instances", obj_Bullet);
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
