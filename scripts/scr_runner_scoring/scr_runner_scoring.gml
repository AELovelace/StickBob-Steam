/// @description Runner scoring helpers

// ─────────────────────────────────────────────────────────────────────────────
// runner_add_kill()
//   Call this from any enemy's death event (e.g. Collision_obj_Bullet) to
//   register a kill against the current run.
//   Safe to call even when the director doesn't exist – it no-ops.
// ─────────────────────────────────────────────────────────────────────────────
function runner_add_kill() {
    if (!instance_exists(obj_RunnerDirector)) exit;
    var _dir = instance_find(obj_RunnerDirector, 0);
    _dir.runner_kills++;
    if (_dir.runner_kills > _dir.runner_best_kills) {
        _dir.runner_best_kills = _dir.runner_kills;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// runner_pixels_to_meters(_px)
//   Utility: convert a raw pixel distance to metres.
//   32 px = 1.75 m
// ─────────────────────────────────────────────────────────────────────────────
function runner_pixels_to_meters(_px) {
    return _px * (1.75 / 32);
}

// ─────────────────────────────────────────────────────────────────────────────
// runner_get_score()
// runner_get_best_score()
// runner_get_kills()
// runner_get_best_kills()
//   Convenience read accessors – return 0 if the director is absent.
// ─────────────────────────────────────────────────────────────────────────────
function runner_get_score() {
    if (!instance_exists(obj_RunnerDirector)) return 0;
    return instance_find(obj_RunnerDirector, 0).runner_score;
}

function runner_get_best_score() {
    if (!instance_exists(obj_RunnerDirector)) return 0;
    return instance_find(obj_RunnerDirector, 0).runner_best_score;
}

function runner_get_kills() {
    if (!instance_exists(obj_RunnerDirector)) return 0;
    return instance_find(obj_RunnerDirector, 0).runner_kills;
}

function runner_get_best_kills() {
    if (!instance_exists(obj_RunnerDirector)) return 0;
    return instance_find(obj_RunnerDirector, 0).runner_best_kills;
}
