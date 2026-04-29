/// @description RunnerDirector – Create event
// Manages the infinite chunk streaming, scoring, and fail state.
// All slice/chunk logic lives here; O_Player code is untouched.

// ── Chunk management ───────────────────────────────────────────────────────
chunk_list     = ds_list_create();  // active chunks: structs {x_start, width, instances:[]}
next_spawn_x   = 0;                 // world x where the next slice will be placed

SPAWN_AHEAD    = 1920;              // keep this many px of world loaded ahead of player
DESPAWN_BEHIND = 1280;              // destroy chunks this many px behind player

PLAYER_START_X = 128;               // initial x position of O_Player in this room
KILL_Y         = room_height + 48;  // fall-off kill plane (below room floor)

// ── Slice pool ─────────────────────────────────────────────────────────────
slice_pool  = runner_get_slices();
slice_count = array_length(slice_pool);

// ── Chunk normalization / weighting settings ──────────────────────────────
EDGE_WINDOW     = 32;   // px near left/right edge used for entry/exit probes
MAX_UP_STEP     = 80;   // max upward transition between chunk edges
MAX_DOWN_DROP   = 192;  // soft limit for downward transitions
last_chunk_profile = undefined;
last_chunk_index   = -1;

_is_slope_asset = function(_asset) {
    if (_asset == objSloped) return true;
    if (_asset == objSloped45) return true;
    if (_asset == objSloped45Left) return true;
    if (_asset == objSloped_1) return true;
    if (_asset == objSloped_2) return true;
    if (_asset == objSloped_3) return true;
    if (_asset == objSloped_4) return true;
    return false;
};

_is_enemy_asset = function(_asset) {
    if (_asset == objSlopBot) return true;
    if (_asset == objSlopBotGunner) return true;
    if (_asset == objSlopBotSlacker) return true;
    return false;
};

_is_support_asset = function(_asset) {
    if (_asset == objSolid) return true;
    if (_asset == objSolid1) return true;
    if (_asset == objSolid6) return true;
    if (_asset == objSolidInvisible) return true;
    if (_asset == objBouncyBottom) return true;
    if (_is_slope_asset(_asset)) return true;
    return false;
};

_estimate_edge_y = function(_slice, _right_side) {
    var _width = variable_struct_get(_slice, "width");
    var _edge_start = _right_side ? (_width - EDGE_WINDOW) : 0;
    var _edge_end   = _right_side ? _width : EDGE_WINDOW;

    var _found = false;
    var _best_y = -100000;

    // Platforms (hand-authored runner slices)
    if (variable_struct_exists(_slice, "platforms")) {
        var _platforms = variable_struct_get(_slice, "platforms");
        var _pc = array_length(_platforms);
        for (var _i = 0; _i < _pc; _i++) {
            var _p = _platforms[_i];
            var _start = variable_struct_get(_p, "dx");
            var _end = _start + variable_struct_get(_p, "w");
            if (_end > _edge_start && _start < _edge_end) {
                var _y = variable_struct_get(_p, "dy");
                if (!_found || _y > _best_y) {
                    _best_y = _y;
                    _found = true;
                }
            }
        }
    }

    // Elements (generated World1 chunks and prefab slices)
    if (variable_struct_exists(_slice, "elements")) {
        var _elements = variable_struct_get(_slice, "elements");
        var _ec = array_length(_elements);
        for (var _k = 0; _k < _ec; _k++) {
            var _e = _elements[_k];
            var _obj_asset = variable_struct_get(_e, "object_asset");
            if (!_is_support_asset(_obj_asset)) continue;

            var _sx = variable_struct_get(_e, "scale_x");
            var _w_est = 16 * abs(_sx);
            if (_w_est < 16) _w_est = 16;

            var _start2 = variable_struct_get(_e, "dx");
            var _end2 = _start2 + _w_est;
            if (_end2 > _edge_start && _start2 < _edge_end) {
                var _y2 = variable_struct_get(_e, "dy");
                if (!_found || _y2 > _best_y) {
                    _best_y = _y2;
                    _found = true;
                }
            }
        }
    }

    return _found ? _best_y : -1;
};

_calculate_slice_difficulty = function(_slice) {
    var _difficulty = 1;

    var _hazard_count = 0;
    if (variable_struct_exists(_slice, "hazards")) {
        _hazard_count = array_length(variable_struct_get(_slice, "hazards"));
    }
    _difficulty += min(2, _hazard_count);

    var _enemy_count = 0;
    var _slope_count = 0;
    if (variable_struct_exists(_slice, "elements")) {
        var _elements = variable_struct_get(_slice, "elements");
        var _ec = array_length(_elements);
        for (var _i = 0; _i < _ec; _i++) {
            var _obj_asset = variable_struct_get(_elements[_i], "object_asset");
            if (_is_enemy_asset(_obj_asset)) _enemy_count++;
            if (_is_slope_asset(_obj_asset)) _slope_count++;
        }
    }

    _difficulty += min(3, _enemy_count);
    if (_slope_count >= 4) _difficulty += 1;

    var _entry = _estimate_edge_y(_slice, false);
    var _exit  = _estimate_edge_y(_slice, true);
    if (_entry >= 0 && _exit >= 0) {
        var _delta = abs(_exit - _entry);
        if (_delta > 64) _difficulty += 1;
        if (_delta > 128) _difficulty += 1;
    }

    return clamp(_difficulty, 1, 8);
};

_calculate_slice_base_weight = function(_slice, _idx, _difficulty) {
    var _base = 6;

    if (variable_struct_exists(_slice, "source_room")) {
        var _room = variable_struct_get(_slice, "source_room");
        switch (_room) {
            case "rm_GameRoom": _base = 8; break;
            case "SP1": _base = 7; break;
            case "SP2": _base = 5; break;
            case "SP3": _base = 3.5; break;
            case "SP4": _base = 2.5; break;
            default: _base = 5; break;
        }
    } else {
        if (_idx <= 3) _base = 10;
        else if (_idx <= 9) _base = 8;
        else _base = 6;
    }

    _base -= max(0, _difficulty - 3) * 0.8;
    return max(0.25, _base);
};

_build_slice_profile = function(_slice, _idx) {
    var _entry = _estimate_edge_y(_slice, false);
    var _exit  = _estimate_edge_y(_slice, true);
    var _difficulty = _calculate_slice_difficulty(_slice);
    var _weight = _calculate_slice_base_weight(_slice, _idx, _difficulty);
    var _room = "";
    if (variable_struct_exists(_slice, "source_room")) {
        _room = variable_struct_get(_slice, "source_room");
    }

    return {
        index       : _idx,
        entry_y     : _entry,
        exit_y      : _exit,
        difficulty  : _difficulty,
        base_weight : _weight,
        source_room : _room,
    };
};

slice_profiles = array_create(slice_count);
for (var _sp = 0; _sp < slice_count; _sp++) {
    slice_profiles[_sp] = _build_slice_profile(slice_pool[_sp], _sp);
}

_pick_weighted_slice_index = function() {
    var _weights = array_create(slice_count, 0);
    var _total = 0;

    for (var _i = 0; _i < slice_count; _i++) {
        var _profile = slice_profiles[_i];
        var _w = _profile.base_weight;

        // Avoid immediate repeats.
        if (_i == last_chunk_index) _w *= 0.35;

        // Early-run bias: keep first stretch easier.
        if (next_spawn_x < 2000) {
            if (_profile.difficulty >= 6) _w *= 0.08;
            else if (_profile.difficulty >= 4) _w *= 0.35;
        }

        // Transition normalization using edge heights.
        if (is_struct(last_chunk_profile)) {
            if (last_chunk_profile.exit_y >= 0 && _profile.entry_y >= 0) {
                var _up = last_chunk_profile.exit_y - _profile.entry_y;      // positive = next chunk is higher
                var _down = _profile.entry_y - last_chunk_profile.exit_y;    // positive = next chunk is lower

                if (_up > MAX_UP_STEP) _w = 0;
                else if (_up > 64) _w *= 0.2;
                else if (_up > 40) _w *= 0.55;

                if (_down > MAX_DOWN_DROP) _w *= 0.25;
                else if (_down > 128) _w *= 0.6;
            } else {
                _w *= 0.7;
            }

            // Soften abrupt difficulty spikes.
            var _diff_delta = abs(_profile.difficulty - last_chunk_profile.difficulty);
            if (_diff_delta >= 3) _w *= 0.55;
            if (_profile.difficulty > last_chunk_profile.difficulty + 1) _w *= 0.6;
        }

        if (_w > 0) {
            _weights[_i] = _w;
            _total += _w;
        }
    }

    // Fallback: if everything was filtered out, choose among easier starter slices.
    if (_total <= 0) {
        if (slice_count > 3) return irandom(3);
        return irandom(max(0, slice_count - 1));
    }

    var _roll = random(_total);
    var _acc = 0;
    for (var _k = 0; _k < slice_count; _k++) {
        _acc += _weights[_k];
        if (_roll <= _acc) return _k;
    }

    return 0;
};

// ── Scoring & distance ────────────────────────────────────────────────────
// Conversion: 32 px = 1.75 m  →  1 pt per whole metre
PIXELS_PER_METER  = 32 / 1.75;   // ≈ 18.286 px per metre

runner_px         = 0;    // raw pixel distance travelled this life
runner_meters     = 0.0;  // float metres this life
runner_score      = 0;    // int points this life  (floor of metres)
runner_best_score = 0;    // session-best score

runner_kills      = 0;    // enemies killed this run
runner_best_kills = 0;    // most kills in a single run this session

// Legacy aliases – existing Draw code still reads these
runner_distance   = 0;    // kept in sync with runner_score
runner_best       = 0;    // kept in sync with runner_best_score

_runner_collectible_amount = function() {
    var _roll = irandom(99);
    if (_roll < 45) return 1;
    if (_roll < 75) return 3;
    if (_roll < 92) return 5;
    return 10;
};

// ── Internal: spawn one slice at next_spawn_x ──────────────────────────────
_spawn_chunk = function() {
    // Weighted + normalized selection:
    //   first 480 px → always flat slice 0 for safe open
    //   after that   → weighted random with transition checks
    var _idx;
    if (next_spawn_x < 480) {
        _idx = 0;
    } else {
        _idx = _pick_weighted_slice_index();
    }
    var _s    = slice_pool[_idx];
    var _ox   = next_spawn_x;
    var _inst_arr = [];

    // Platforms ─ one scaled objSolid per platform entry
    // objSolid is 16×16 px; image_xscale widens the collision mask to match.
    var _platforms = variable_struct_get(_s, "platforms");
    var _p_count = array_length(_platforms);
    for (var _i = 0; _i < _p_count; _i++) {
        var _p    = _platforms[_i];
        var _pdx  = variable_struct_get(_p, "dx");
        var _pdy  = variable_struct_get(_p, "dy");
        var _pw   = variable_struct_get(_p, "w");
        var _inst = instance_create_layer(_ox + _pdx, _pdy, "Instances", objSolid);
        _inst.image_xscale = _pw / 16;
        array_push(_inst_arr, _inst);
    }

    if (_p_count > 0 && irandom(99) < 35) {
        var _valid_platforms = [];
        for (var _pc = 0; _pc < _p_count; _pc++) {
            var _plat = _platforms[_pc];
            if (variable_struct_get(_plat, "w") >= 64) {
                array_push(_valid_platforms, _plat);
            }
        }

        if (array_length(_valid_platforms) > 0) {
            var _pickup_platform = _valid_platforms[irandom(array_length(_valid_platforms) - 1)];
            var _pickup_margin = 24;
            var _pickup_width = variable_struct_get(_pickup_platform, "w");
            var _pickup_span = max(1, _pickup_width - (_pickup_margin * 2));
            var _pickup_dx = variable_struct_get(_pickup_platform, "dx")
                + _pickup_margin
                + irandom(_pickup_span);
            var _pickup_dy = variable_struct_get(_pickup_platform, "dy") - 18;
            var _pickup_amount = _runner_collectible_amount();
            var _pickup = instance_create_layer(
                _ox + _pickup_dx,
                _pickup_dy,
                "Instances",
                obj_SGCCollectible
            );
            _pickup.sgcAmount = _pickup_amount;
            _pickup.collectibleCode = "runner:"
                + string(_ox + _pickup_dx)
                + ":" + string(_pickup_dy)
                + ":" + string(_pickup_amount);
            array_push(_inst_arr, _pickup);
        }
    }

    // Hazards ─ individual obj_RunnerHazard instances
    var _hazards = variable_struct_get(_s, "hazards");
    var _h_count = array_length(_hazards);
    for (var _j = 0; _j < _h_count; _j++) {
        var _h    = _hazards[_j];
        var _hdx  = variable_struct_get(_h, "dx");
        var _hdy  = variable_struct_get(_h, "dy");
        var _hinst = instance_create_layer(_ox + _hdx, _hdy, "Instances", obj_RunnerHazard);
        array_push(_inst_arr, _hinst);
    }

    // Generic prefab elements ─ slopes, enemies, pickups, decorations, etc.
    if (variable_struct_exists(_s, "elements")) {
        var _elements = variable_struct_get(_s, "elements");
        var _e_count = array_length(_elements);
        for (var _k = 0; _k < _e_count; _k++) {
            var _e       = _elements[_k];
            var _asset   = variable_struct_get(_e, "object_asset");
            var _edx     = variable_struct_get(_e, "dx");
            var _edy     = variable_struct_get(_e, "dy");
            var _scale_x = variable_struct_get(_e, "scale_x");
            var _scale_y = variable_struct_get(_e, "scale_y");
            var _rot     = variable_struct_get(_e, "rotation");

            var _einst = instance_create_layer(_ox + _edx, _edy, "Instances", _asset);
            _einst.image_xscale = _scale_x;
            _einst.image_yscale = _scale_y;
            _einst.image_angle  = _rot;
            array_push(_inst_arr, _einst);
        }
    }

    // Register this chunk in the active list
    var _chunk_width = variable_struct_get(_s, "width");
    ds_list_add(chunk_list, {
        x_start   : _ox,
        width     : _chunk_width,
        instances : _inst_arr,
        slice_idx : _idx,
    });

    next_spawn_x += _chunk_width;
    last_chunk_profile = slice_profiles[_idx];
    last_chunk_index = _idx;
};

// ── Internal: remove chunks that have scrolled far behind the player ───────
_despawn_old_chunks = function(_player_x) {
    while (ds_list_size(chunk_list) > 0) {
        var _chunk = chunk_list[| 0];
        if (_chunk.x_start + _chunk.width < _player_x - DESPAWN_BEHIND) {
            var _insts = _chunk.instances;
            var _cnt   = array_length(_insts);
            for (var _i = 0; _i < _cnt; _i++) {
                if (instance_exists(_insts[_i])) instance_destroy(_insts[_i]);
            }
            ds_list_delete(chunk_list, 0);
        } else {
            break;
        }
    }
};

// ── Internal: fully remove all active chunks ───────────────────────────────
_clear_all_chunks = function() {
    while (ds_list_size(chunk_list) > 0) {
        var _chunk = chunk_list[| 0];
        var _insts = _chunk.instances;
        var _cnt   = array_length(_insts);
        for (var _i = 0; _i < _cnt; _i++) {
            if (instance_exists(_insts[_i])) instance_destroy(_insts[_i]);
        }
        ds_list_delete(chunk_list, 0);
    }
};

// ── Internal: rebuild stream around a world x position ────────────────────
_reset_stream_at = function(_center_x) {
    _clear_all_chunks();
    last_chunk_profile = undefined;
    last_chunk_index = -1;

    // Keep stream aligned to 16 px grid and allow a little room behind player.
    var _start = floor((_center_x - 256) / 16) * 16;
    if (_start < 0) _start = 0;

    next_spawn_x = _start;
    while (next_spawn_x < _center_x + SPAWN_AHEAD) {
        _spawn_chunk();
    }
};

// ── Boot: generate initial terrain around the player start ────────────────
_reset_stream_at(PLAYER_START_X);
