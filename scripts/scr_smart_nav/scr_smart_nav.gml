function scr_smart_nav_get_cache() {
    if (!variable_global_exists("smart_nav_cache")) {
        global.smart_nav_cache = {};
    }
    return global.smart_nav_cache;
}

function scr_smart_nav_array_push(_array, _value) {
    var _len = array_length(_array);
    _array[_len] = _value;
    return _array;
}

function scr_smart_nav_profile(_inst) {
    var _cell_w = 16;
    var _cell_h = 16;
    if (instance_exists(O_Grid)) {
        if (variable_instance_exists(O_Grid, "cell_width")) {
            _cell_w = O_Grid.cell_width;
        }
        if (variable_instance_exists(O_Grid, "cell_height")) {
            _cell_h = O_Grid.cell_height;
        }
    }

    return {
        cell_w : _cell_w,
        cell_h : _cell_h,
        max_speed_x : 8,
        max_fall_speed : 15,
        accel : 0.3,
        gravity : 0.4,
        jump_speed : -10,
        climb_height : 8,
        replan_interval : 15,
        replan_move_cells : 2,
        node_snap : 10,
        debug_key : ord("G")
    };
}

function scr_smart_nav_collision_tilemap() {
    var _tilemap = -1;
    if (layer_exists("CollisionLayer")) {
        _tilemap = layer_tilemap_get_id("CollisionLayer");
    }
    return _tilemap;
}

function scr_smart_nav_collision_at(_x, _y, _tilemap) {
    if (place_meeting(_x, _y, objSolid)) {
        return true;
    }
    if (place_meeting(_x, _y, O_Collision)) {
        return true;
    }
    if (_tilemap != -1 && place_meeting(_x, _y, _tilemap)) {
        return true;
    }
    return false;
}

function scr_smart_nav_grounded_at(_x, _y, _tilemap) {
    return scr_smart_nav_collision_at(_x, _y + 1, _tilemap);
}

function scr_smart_nav_can_stand_at(_x, _y, _tilemap) {
    if (scr_smart_nav_collision_at(_x, _y, _tilemap)) {
        return false;
    }
    return scr_smart_nav_grounded_at(_x, _y, _tilemap);
}

function scr_smart_nav_heuristic(_nav, _from_index, _to_index) {
    var _from = _nav.nodes[_from_index];
    var _to = _nav.nodes[_to_index];
    var _dx = abs(_from.cx - _to.cx);
    var _dy = abs(_from.cy - _to.cy);
    return _dx + (_dy * 1.5);
}

function scr_smart_nav_find_node_at_position(_nav, _x, _y, _snap) {
    var _best = -1;
    var _best_dist = 1000000;
    var _cx = round(_x / _nav.cell_w);
    var _cy = round(_y / _nav.cell_h);

    for (var _ix = _cx - 1; _ix <= _cx + 1; _ix += 1) {
        for (var _iy = _cy - 1; _iy <= _cy + 1; _iy += 1) {
            if (_ix < 0 || _ix >= _nav.width || _iy < 0 || _iy >= _nav.height) {
                continue;
            }
            var _node_index = ds_grid_get(_nav.node_grid, _ix, _iy);
            if (_node_index < 0) {
                continue;
            }
            var _node = _nav.nodes[_node_index];
            var _dist = point_distance(_x, _y, _node.x, _node.y);
            if (_dist <= _snap && _dist < _best_dist) {
                _best = _node_index;
                _best_dist = _dist;
            }
        }
    }

    return _best;
}

function scr_smart_nav_find_nearest_node(_nav, _x, _y, _radius_cells) {
    var _best = -1;
    var _best_dist = 1000000;
    var _cx = round(_x / _nav.cell_w);
    var _cy = round(_y / _nav.cell_h);

    for (var _ix = _cx - _radius_cells; _ix <= _cx + _radius_cells; _ix += 1) {
        for (var _iy = _cy - _radius_cells; _iy <= _cy + _radius_cells; _iy += 1) {
            if (_ix < 0 || _ix >= _nav.width || _iy < 0 || _iy >= _nav.height) {
                continue;
            }
            var _node_index = ds_grid_get(_nav.node_grid, _ix, _iy);
            if (_node_index < 0) {
                continue;
            }
            var _node = _nav.nodes[_node_index];
            var _dist = point_distance(_x, _y, _node.x, _node.y);
            if (_dist < _best_dist) {
                _best = _node_index;
                _best_dist = _dist;
            }
        }
    }

    return _best;
}

function scr_smart_nav_build_macros() {
    return [
        { name : "walk_left", action : "walk", input_x : -1, jump_frame : -1, frames : 18, cost_bias : 1.0 },
        { name : "walk_right", action : "walk", input_x : 1, jump_frame : -1, frames : 18, cost_bias : 1.0 },
        { name : "jump_up", action : "jump", input_x : 0, jump_frame : 0, frames : 45, cost_bias : 2.0 },
        { name : "jump_left", action : "jump", input_x : -1, jump_frame : 0, frames : 45, cost_bias : 2.2 },
        { name : "jump_right", action : "jump", input_x : 1, jump_frame : 0, frames : 45, cost_bias : 2.2 },
        { name : "run_jump_left_short", action : "jump", input_x : -1, jump_frame : 4, frames : 55, cost_bias : 2.5 },
        { name : "run_jump_right_short", action : "jump", input_x : 1, jump_frame : 4, frames : 55, cost_bias : 2.5 },
        { name : "run_jump_left_long", action : "jump", input_x : -1, jump_frame : 7, frames : 65, cost_bias : 3.0 },
        { name : "run_jump_right_long", action : "jump", input_x : 1, jump_frame : 7, frames : 65, cost_bias : 3.0 }
    ];
}

function scr_smart_nav_step_state(_state, _input_x, _jump_pressed, _profile, _tilemap) {
    var _accel = _profile.accel;
    var _max_speed_x = _profile.max_speed_x;
    var _grav = _profile.gravity;
    var _max_fall_speed = _profile.max_fall_speed;
    var _climb_height = _profile.climb_height;

    var _on_ground = scr_smart_nav_grounded_at(_state.x, _state.y, _tilemap);

    _state.xSpeed = clamp(_state.xSpeed + (_input_x * _accel), -_max_speed_x, _max_speed_x);
    if (_input_x == 0) {
        if (_state.xSpeed > 0) {
            _state.xSpeed = max(0, _state.xSpeed - _accel);
        } else if (_state.xSpeed < 0) {
            _state.xSpeed = min(0, _state.xSpeed + _accel);
        }
    }

    if (_jump_pressed && _on_ground) {
        _state.ySpeed = _profile.jump_speed;
        _on_ground = false;
    }

    _state.ySpeed = min(_state.ySpeed + _grav, _max_fall_speed);

    if (scr_smart_nav_collision_at(_state.x + _state.xSpeed, _state.y, _tilemap)) {
        while (!scr_smart_nav_collision_at(_state.x + sign(_state.xSpeed), _state.y, _tilemap)) {
            _state.x += sign(_state.xSpeed);
        }

        var _step_up = 0;
        while (scr_smart_nav_collision_at(_state.x + sign(_state.xSpeed), _state.y - _step_up, _tilemap) && _step_up < _climb_height) {
            _step_up += 1;
        }

        if (!scr_smart_nav_collision_at(_state.x + sign(_state.xSpeed), _state.y - _step_up, _tilemap)) {
            _state.y -= _step_up;
        } else {
            _state.xSpeed = 0;
        }
    }

    _state.x += _state.xSpeed;

    if (scr_smart_nav_collision_at(_state.x, _state.y + _state.ySpeed, _tilemap)) {
        while (!scr_smart_nav_collision_at(_state.x, _state.y + sign(_state.ySpeed), _tilemap)) {
            _state.y += sign(_state.ySpeed);
        }
        _state.ySpeed = 0;
    }

    _state.y += _state.ySpeed;
    _state.grounded = scr_smart_nav_grounded_at(_state.x, _state.y, _tilemap);
}

function scr_smart_nav_simulate_macro(_nav, _node_index, _macro, _profile, _tilemap) {
    var _node = _nav.nodes[_node_index];
    var _state = {
        x : _node.x,
        y : _node.y,
        xSpeed : 0,
        ySpeed : 0,
        grounded : true
    };

    var _left_ground = false;
    var _jump_macro = (_macro.jump_frame >= 0);

    for (var _frame = 0; _frame < _macro.frames; _frame += 1) {
        var _jump_now = (_frame == _macro.jump_frame);
        scr_smart_nav_step_state(_state, _macro.input_x, _jump_now, _profile, _tilemap);

        if (!_state.grounded) {
            _left_ground = true;
        }

        var _landed_index = scr_smart_nav_find_node_at_position(_nav, _state.x, _state.y, _profile.node_snap);
        if (_landed_index == -1 || _landed_index == _node_index) {
            continue;
        }

        if (_jump_macro) {
            if (!_left_ground || !_state.grounded) {
                continue;
            }
        } else if (_frame < 2) {
            continue;
        }

        var _landing = _nav.nodes[_landed_index];
        var _action = _macro.action;
        if (!_jump_macro && _landing.cy > _node.cy) {
            _action = "drop";
        } else if (_jump_macro && _landing.cy == _node.cy) {
            _action = "gap_jump";
        }

        var _cost = point_distance(_node.x, _node.y, _landing.x, _landing.y) / _nav.cell_w;
        _cost += _macro.cost_bias;

        return {
            found : true,
            edge : {
                to : _landed_index,
                action : _action,
                input_x : _macro.input_x,
                jump_frame : _macro.jump_frame,
                max_frames : _macro.frames + 12,
                cost : _cost
            }
        };
    }

    return { found : false };
}

function scr_smart_nav_add_edge(_edges, _edge) {
    for (var _i = 0; _i < array_length(_edges); _i += 1) {
        var _existing = _edges[_i];
        if (_existing.to == _edge.to && _existing.action == _edge.action) {
            if (_edge.cost < _existing.cost) {
                _edges[_i] = _edge;
            }
            return _edges;
        }
    }

    return scr_smart_nav_array_push(_edges, _edge);
}

function scr_smart_nav_build_room(_profile) {
    var _cache = scr_smart_nav_get_cache();
    var _key = string(room);
    if (variable_struct_exists(_cache, _key)) {
        return variable_struct_get(_cache, _key);
    }

    var _tilemap = scr_smart_nav_collision_tilemap();
    var _nav = {
        room : room,
        cell_w : _profile.cell_w,
        cell_h : _profile.cell_h,
        width : ceil(room_width / _profile.cell_w),
        height : ceil(room_height / _profile.cell_h),
        node_grid : ds_grid_create(ceil(room_width / _profile.cell_w), ceil(room_height / _profile.cell_h)),
        nodes : [],
        edge_count : 0
    };

    ds_grid_set_region(_nav.node_grid, 0, 0, _nav.width - 1, _nav.height - 1, -1);

    for (var _cx = 1; _cx < _nav.width - 1; _cx += 1) {
        for (var _cy = 1; _cy < _nav.height - 1; _cy += 1) {
            var _x = _cx * _nav.cell_w;
            var _y = _cy * _nav.cell_h;
            if (!scr_smart_nav_can_stand_at(_x, _y, _tilemap)) {
                continue;
            }

            var _node_index = array_length(_nav.nodes);
            _nav.nodes[_node_index] = {
                cx : _cx,
                cy : _cy,
                x : _x,
                y : _y,
                edges : []
            };
            ds_grid_set(_nav.node_grid, _cx, _cy, _node_index);
        }
    }

    var _macros = scr_smart_nav_build_macros();
    for (var _node_i = 0; _node_i < array_length(_nav.nodes); _node_i += 1) {
        var _edges = [];
        for (var _macro_i = 0; _macro_i < array_length(_macros); _macro_i += 1) {
            var _result = scr_smart_nav_simulate_macro(_nav, _node_i, _macros[_macro_i], _profile, _tilemap);
            if (_result.found) {
                _edges = scr_smart_nav_add_edge(_edges, _result.edge);
            }
        }
        _nav.nodes[_node_i].edges = _edges;
        _nav.edge_count += array_length(_edges);
    }

    variable_struct_set(_cache, _key, _nav);
    return _nav;
}

function scr_smart_nav_request_route(_nav, _start_x, _start_y, _goal_x, _goal_y) {
    var _start_index = scr_smart_nav_find_nearest_node(_nav, _start_x, _start_y, 4);
    var _goal_index = scr_smart_nav_find_nearest_node(_nav, _goal_x, _goal_y, 5);

    if (_start_index == -1 || _goal_index == -1) {
        return { found : false, reason : "no_nodes" };
    }

    var _node_count = array_length(_nav.nodes);
    var _open = ds_priority_create();
    var _closed = array_create(_node_count, false);
    var _g = array_create(_node_count, 1000000);
    var _came_from = array_create(_node_count, -1);
    var _came_edge = array_create(_node_count, undefined);

    _g[_start_index] = 0;
    ds_priority_add(_open, _start_index, scr_smart_nav_heuristic(_nav, _start_index, _goal_index));

    while (!ds_priority_empty(_open)) {
        var _current = ds_priority_delete_min(_open);
        if (_closed[_current]) {
            continue;
        }
        _closed[_current] = true;

        if (_current == _goal_index) {
            break;
        }

        var _edges = _nav.nodes[_current].edges;
        for (var _edge_i = 0; _edge_i < array_length(_edges); _edge_i += 1) {
            var _edge = _edges[_edge_i];
            var _next = _edge.to;
            var _tentative = _g[_current] + _edge.cost;
            if (_tentative >= _g[_next]) {
                continue;
            }

            _g[_next] = _tentative;
            _came_from[_next] = _current;
            _came_edge[_next] = _edge;

            var _f = _tentative + scr_smart_nav_heuristic(_nav, _next, _goal_index);
            ds_priority_add(_open, _next, _f);
        }
    }

    ds_priority_destroy(_open);

    if (_came_from[_goal_index] == -1 && _goal_index != _start_index) {
        return {
            found : false,
            reason : "unreachable",
            start_node : _start_index,
            goal_node : _goal_index
        };
    }

    var _reverse_nodes = [];
    var _reverse_edges = [];
    var _walk = _goal_index;
    _reverse_nodes = scr_smart_nav_array_push(_reverse_nodes, _goal_index);

    while (_walk != _start_index) {
        _reverse_edges = scr_smart_nav_array_push(_reverse_edges, _came_edge[_walk]);
        _walk = _came_from[_walk];
        _reverse_nodes = scr_smart_nav_array_push(_reverse_nodes, _walk);
    }

    var _route_nodes = [];
    var _route_edges = [];
    for (var _i = array_length(_reverse_nodes) - 1; _i >= 0; _i -= 1) {
        _route_nodes = scr_smart_nav_array_push(_route_nodes, _reverse_nodes[_i]);
    }
    for (var _j = array_length(_reverse_edges) - 1; _j >= 0; _j -= 1) {
        _route_edges = scr_smart_nav_array_push(_route_edges, _reverse_edges[_j]);
    }

    return {
        found : true,
        start_node : _start_index,
        goal_node : _goal_index,
        nodes : _route_nodes,
        edges : _route_edges
    };
}

function scr_smart_nav_apply_instance_input(_input_x, _jump_pressed, _profile, _tilemap) {
    xInput = _input_x;
    yInput = _jump_pressed ? -1 : 0;

    var _state = {
        x : x,
        y : y,
        xSpeed : xSpeed,
        ySpeed : ySpeed,
        grounded : scr_smart_nav_grounded_at(x, y, _tilemap)
    };

    scr_smart_nav_step_state(_state, _input_x, _jump_pressed, _profile, _tilemap);

    x = _state.x;
    y = _state.y;
    xSpeed = _state.xSpeed;
    ySpeed = _state.ySpeed;
    nav_grounded = _state.grounded;
}

function scr_smart_nav_reset_route(_reason) {
    nav_route = undefined;
    nav_route_edge_index = 0;
    nav_edge_frame = 0;
    nav_plan_cooldown = nav_profile.replan_interval;
    nav_last_reason = _reason;
}

function scr_smart_nav_apply_fallback(_target, _tilemap) {
    var _input_x = 0;
    var _jump = false;

    if (!is_undefined(_target)) {
        if (abs(_target.y - y) <= nav_profile.cell_h * 1.5) {
            _input_x = sign(_target.x - x);
        }
        if (_target.y < y - (nav_profile.cell_h * 1.25) && scr_smart_nav_grounded_at(x, y, _tilemap)) {
            _jump = true;
        }
    }

    scr_smart_nav_apply_instance_input(_input_x, _jump, nav_profile, _tilemap);
}

function scr_smart_nav_update_target_position(_target_x, _target_y, _look_x, _look_y) {
    if (keyboard_check_pressed(nav_profile.debug_key)) {
        global.smart_nav_debug = !global.smart_nav_debug;
    }

    collision_tilemap_id = scr_smart_nav_collision_tilemap();
    var _tilemap = collision_tilemap_id;
    var _nav = scr_smart_nav_build_room(nav_profile);

    if (is_undefined(_target_x) || is_undefined(_target_y)) {
        scr_smart_nav_apply_instance_input(0, false, nav_profile, _tilemap);
        nav_last_reason = "no_target";
        return;
    }

    mouseAngle = point_direction(x, y, _look_x, _look_y);

    if (nav_plan_cooldown > 0) {
        nav_plan_cooldown -= 1;
    }

    var _target_node = scr_smart_nav_find_nearest_node(_nav, _target_x, _target_y, 5);
    var _current_node = scr_smart_nav_find_nearest_node(_nav, x, y, 4);
    var _needs_plan = false;

    if (is_undefined(nav_route)) {
        _needs_plan = true;
    } else if (!nav_route.found) {
        _needs_plan = true;
    } else if (_target_node != nav_target_node) {
        if (_target_node != -1 && nav_target_node != -1) {
            var _target_dx = abs(_nav.nodes[_target_node].cx - _nav.nodes[nav_target_node].cx);
            var _target_dy = abs(_nav.nodes[_target_node].cy - _nav.nodes[nav_target_node].cy);
            if (_target_dx >= nav_profile.replan_move_cells || _target_dy >= 1) {
                _needs_plan = true;
            }
        } else {
            _needs_plan = true;
        }
    } else if (nav_route_edge_index >= array_length(nav_route.edges)) {
        _needs_plan = true;
    }

    if (_needs_plan && nav_plan_cooldown <= 0) {
        nav_route = scr_smart_nav_request_route(_nav, x, y, _target_x, _target_y);
        nav_target_node = _target_node;
        nav_route_edge_index = 0;
        nav_edge_frame = 0;
        nav_plan_cooldown = nav_profile.replan_interval;
        nav_last_reason = nav_route.found ? "planned" : nav_route.reason;
    }

    if (is_undefined(nav_route) || !nav_route.found || nav_route_edge_index >= array_length(nav_route.edges)) {
        var _fallback_target = {
            x : _target_x,
            y : _target_y
        };
        scr_smart_nav_apply_fallback(_fallback_target, _tilemap);
        return;
    }

    var _edge = nav_route.edges[nav_route_edge_index];
    var _jump_now = (_edge.jump_frame == nav_edge_frame);

    scr_smart_nav_apply_instance_input(_edge.input_x, _jump_now, nav_profile, _tilemap);

    nav_edge_frame += 1;
    var _landed_node = scr_smart_nav_find_node_at_position(_nav, x, y, nav_profile.node_snap);
    if (_landed_node == _edge.to && nav_grounded) {
        nav_route_edge_index += 1;
        nav_edge_frame = 0;
        nav_stuck_frames = 0;
        nav_last_reason = "edge_complete:" + _edge.action;
    } else {
        if (point_distance(x, y, nav_last_pos_x, nav_last_pos_y) <= 1) {
            nav_stuck_frames += 1;
        } else {
            nav_stuck_frames = 0;
        }
    }

    nav_last_pos_x = x;
    nav_last_pos_y = y;

    if (nav_edge_frame > _edge.max_frames || nav_stuck_frames > 20) {
        scr_smart_nav_reset_route("replan:" + _edge.action);
    }
}

function scr_smart_nav_update(_target) {
    if (!instance_exists(_target)) {
        scr_smart_nav_update_target_position(undefined, undefined, x, y);
        return;
    }

    scr_smart_nav_update_target_position(_target.x, _target.y, _target.x, _target.y);
}

function scr_smart_nav_update_sprite() {
    if (ySpeed > 0.5) {
        sprite_index = (xSpeed < 0) ? sprPlayerFallingLeft : sprPlayerFalling;
        return;
    }

    if (abs(xSpeed) > 0.1) {
        sprite_index = (xSpeed < 0) ? sprPlayerRunLeft : sprPlayerRun;
        return;
    }

    sprite_index = sprPlayerIdle;
}

function scr_smart_nav_draw_debug() {
    if (!variable_global_exists("smart_nav_debug") || !global.smart_nav_debug) {
        return;
    }

    var _nav = scr_smart_nav_build_room(nav_profile);
    var _current_node = scr_smart_nav_find_nearest_node(_nav, x, y, 4);

    draw_set_alpha(0.45);
    draw_set_color(c_lime);
    for (var _i = 0; _i < array_length(_nav.nodes); _i += 1) {
        var _node = _nav.nodes[_i];
        draw_rectangle(_node.x - 2, _node.y - 2, _node.x + 2, _node.y + 2, false);
    }

    if (_current_node != -1) {
        draw_set_color(c_aqua);
        var _edges = _nav.nodes[_current_node].edges;
        for (var _edge_i = 0; _edge_i < array_length(_edges); _edge_i += 1) {
            var _edge = _edges[_edge_i];
            var _to = _nav.nodes[_edge.to];
            draw_line_width(_nav.nodes[_current_node].x, _nav.nodes[_current_node].y, _to.x, _to.y, 2);
        }
    }

    if (!is_undefined(nav_route) && nav_route.found) {
        draw_set_color(c_yellow);
        for (var _route_i = 0; _route_i < array_length(nav_route.edges); _route_i += 1) {
            var _from_index = nav_route.nodes[_route_i];
            var _to_index = nav_route.edges[_route_i].to;
            var _from = _nav.nodes[_from_index];
            var _to = _nav.nodes[_to_index];
            draw_line_width(_from.x, _from.y, _to.x, _to.y, 3);
        }
    }

    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_font(fontMenuSmall);
    draw_text(x + 12, y - 40, "nav: " + string(nav_last_reason));
}
