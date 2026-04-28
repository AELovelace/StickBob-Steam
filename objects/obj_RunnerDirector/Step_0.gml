/// @description RunnerDirector – Step event
// Drives chunk streaming, fall detection, and distance tracking every frame.

if (!instance_exists(O_Player)) exit;
var _pl = instance_find(O_Player, 0);

// ── Kill plane: player fell off the bottom ─────────────────────────────────
if (_pl.y > KILL_Y && _pl.sprite_index != sprPlayerDie) {
    with (O_Player) {
        sprite_index = sprPlayerDie;
        image_speed  = 1;
    }
    global.stopShooting = true;
    if (audio_is_playing(i_fucked_ur_mum) == false) {
        audio_play_sound(i_fucked_ur_mum, 10, false);
    }
}

// ── Distance & score tracking ─────────────────────────────────────────────
// 32 px = 1.75 m; award 1 point per whole metre.
if (_pl.sprite_index != sprPlayerDie) {
    var _px = max(0, _pl.x - PLAYER_START_X);
    if (_px > runner_px) {
        runner_px     = _px;
        runner_meters = runner_px / PIXELS_PER_METER;
        runner_score  = floor(runner_meters);
        if (runner_score > runner_best_score) runner_best_score = runner_score;
        // keep legacy aliases current
        runner_distance = runner_score;
        runner_best     = runner_best_score;
    }
} else {
    // Player just died – freeze score, reset for next life
    runner_px       = 0;
    runner_meters   = 0.0;
    runner_score    = 0;
    runner_distance = 0;
    runner_kills    = 0;
}

// If player has respawned behind all loaded chunks, rebuild terrain at player.
if (ds_list_size(chunk_list) == 0) {
    _reset_stream_at(_pl.x);
} else {
    var _first_chunk = chunk_list[| 0];
    if (_pl.x + 64 < _first_chunk.x_start) {
        _reset_stream_at(_pl.x);
    }
}

// ── Chunk streaming ────────────────────────────────────────────────────────
// Spawn slices until we have SPAWN_AHEAD px of world ahead of the player.
while (next_spawn_x < _pl.x + SPAWN_AHEAD) {
    _spawn_chunk();
}

// Remove chunks that have scrolled too far behind.
_despawn_old_chunks(_pl.x);
