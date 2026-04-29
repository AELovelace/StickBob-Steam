function scr_practice_spawn_local_player(_spawn_index) {
    if (instance_exists(obj_Player)) {
        return instance_find(obj_Player, 0);
    }

    var _pos = grab_spawn_point(_spawn_index);
    var _max_hp = mode_max_health();
    return instance_create_layer(_pos.x, _pos.y, "Instances", obj_Player, {
        steamName : steam_get_persona_name(),
        steamID : steam_get_user_steam_id(),
        lobbyMemberID : _spawn_index,
        maxHealth : _max_hp,
        playerHealth : _max_hp,
        gameMode : global.gameParams.modeSelection,
        playerColor : app_settings_current().player_color
    });
}

function scr_practice_spawn_route_points() {
    var _points = [];
    for (var _i = 0; _i < instance_number(obj_SpawnPoint); _i += 1) {
        var _spawn = instance_find(obj_SpawnPoint, _i);
        if (_spawn == noone) {
            continue;
        }
        _points[array_length(_points)] = { x : _spawn.x, y : _spawn.y };
    }

    if (array_length(_points) <= 2) {
        return _points;
    }

    var _start_index = 0;
    for (var _j = 1; _j < array_length(_points); _j += 1) {
        if (_points[_j].x < _points[_start_index].x) {
            _start_index = _j;
        }
    }

    var _ordered = [];
    var _used = array_create(array_length(_points), false);
    var _current_index = _start_index;

    for (var _step = 0; _step < array_length(_points); _step += 1) {
        _ordered[array_length(_ordered)] = _points[_current_index];
        _used[_current_index] = true;

        var _next_index = -1;
        var _next_score = 1000000;
        for (var _candidate = 0; _candidate < array_length(_points); _candidate += 1) {
            if (_used[_candidate]) {
                continue;
            }

            var _score = point_distance(
                _points[_current_index].x,
                _points[_current_index].y,
                _points[_candidate].x,
                _points[_candidate].y
            );

            if (_score < _next_score) {
                _next_score = _score;
                _next_index = _candidate;
            }
        }

        if (_next_index == -1) {
            break;
        }

        _current_index = _next_index;
    }

    return _ordered;
}

function scr_practice_build_patrol_loops(_route_points) {
    var _loops = [];
    var _count = array_length(_route_points);

    if (_count <= 1) {
        return _loops;
    }

    var _min_x = _route_points[0].x;
    var _max_x = _route_points[0].x;
    for (var _i = 1; _i < _count; _i += 1) {
        _min_x = min(_min_x, _route_points[_i].x);
        _max_x = max(_max_x, _route_points[_i].x);
    }

    var _width = max(1, _max_x - _min_x);
    var _bands = [[], [], []];
    for (var _j = 0; _j < _count; _j += 1) {
        var _point = _route_points[_j];
        var _band = clamp(floor(((_point.x - _min_x) / _width) * 3), 0, 2);
        _bands[_band][array_length(_bands[_band])] = _point;
    }

    for (var _band_i = 0; _band_i < array_length(_bands); _band_i += 1) {
        var _band_points = _bands[_band_i];
        if (array_length(_band_points) <= 1) {
            continue;
        }

        for (var _a = 0; _a < array_length(_band_points); _a += 1) {
            for (var _b = _a + 1; _b < array_length(_band_points); _b += 1) {
                var _swap_needed = false;
                if (_band_points[_b].y < _band_points[_a].y) {
                    _swap_needed = true;
                } else if (_band_points[_b].y == _band_points[_a].y && _band_points[_b].x < _band_points[_a].x) {
                    _swap_needed = true;
                }

                if (_swap_needed) {
                    var _swap = _band_points[_a];
                    _band_points[_a] = _band_points[_b];
                    _band_points[_b] = _swap;
                }
            }
        }

        _loops[array_length(_loops)] = _band_points;

        var _reverse = [];
        for (var _r = array_length(_band_points) - 1; _r >= 0; _r -= 1) {
            _reverse[array_length(_reverse)] = _band_points[_r];
        }
        _loops[array_length(_loops)] = _reverse;
    }

    if (array_length(_loops) <= 0) {
        _loops[0] = _route_points;
    }

    return _loops;
}

function scr_practice_spawn_partner(_route_points, _player) {
    if (array_length(_route_points) <= 1) {
        return noone;
    }

    var _start = _route_points[1];
    var _bot = instance_create_layer(_start.x, _start.y, "Instances", objSlopBotPartner);
    _bot.route_points = _route_points;
    _bot.route_index = 1;
    _bot.route_initialized = true;
    _bot.partner_steam_id = _player.steamID;
    _bot.bot_owner_steam_id = _player.steamID;
    _bot.player_target = _player;
    return _bot;
}

function scr_practice_spawn_enemy_bots(_route_points, _player) {
    var _loops = scr_practice_build_patrol_loops(_route_points);
    if (array_length(_loops) <= 0) {
        return;
    }

    var _enemy_id_seed = -1000;
    var _enemy_count = max(2, min(array_length(_route_points) - 1, array_length(_loops) * 2));
    for (var _i = 0; _i < _enemy_count; _i += 1) {
        var _loop = _loops[_i mod array_length(_loops)];
        if (array_length(_loop) <= 0) {
            continue;
        }

        var _start_index = _i mod array_length(_loop);
        var _start = _loop[_start_index];
        var _bot = instance_create_layer(_start.x, _start.y, "Instances", objSlopBotPatrol);
        _bot.bot_owner_steam_id = _enemy_id_seed - _i;
        _bot.player_target = _player;
        _bot.aggro_range = 320;
        _bot.lose_aggro_range = 420;
        _bot.shoot_range = 180;
        _bot.patrol_points = _loop;
        _bot.patrol_index = (_start_index + 1) mod array_length(_loop);
        _bot.patrol_has_custom_route = true;
        _bot.patrol_initialized = false;
    }
}
