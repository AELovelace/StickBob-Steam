// Runner slice / chunk definitions.
//
// Each slice describes one hand-authored segment that the RunnerDirector can
// pick and spawn at runtime.  Slices are joined end-to-end to build the
// infinite level.
//
// Slice struct fields:
//   width      – total pixel width of this segment
//   platforms  – array of {dx, dy, w}
//                  dx : pixels from the left edge of the slice
//                  dy : y position in the room (floor surface top)
//                  w  : platform pixel width (spawns one scaled objSolid)
//   hazards    – array of {dx, dy} positions for obj_RunnerHazard (16×16)
//   elements   – array of generic prefab placements created with
//                runner_prefab(...)
//
// Prefab elements are the flexible layer for slopes, enemies, and later
// pickups / decorations / moving hazards.  Example:
//   elements : [
//       runner_prefab(objSloped, 96, FLOOR - 32),
//       runner_prefab(objSlopBot, 224, FLOOR - 16)
//   ]
// ---------------------------------------------------------------------------

function runner_prefab(_object_asset, _dx, _dy) {
    return {
        object_asset : _object_asset,
        dx           : _dx,
        dy           : _dy,
        scale_x      : 1,
        scale_y      : 1,
        rotation     : 0,
    };
}

function runner_prefab_ex(_object_asset, _dx, _dy, _scale_x, _scale_y, _rotation) {
    return {
        object_asset : _object_asset,
        dx           : _dx,
        dy           : _dy,
        scale_x      : _scale_x,
        scale_y      : _scale_y,
        rotation     : _rotation,
    };
}

function runner_get_slices() {
    var FLOOR = 352;   // standard floor y, same as rm_GameRoom
    var TILE  = 16;    // base tile size

    var _slices = [

        // ── 0 : long flat opening ───────────────────────────────────────────
        {
            width     : 640,
            platforms : [ {dx:0, dy:FLOOR, w:640} ],
            hazards   : [],
        },

        // ── 1 : gap (128 px) ────────────────────────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR, w:256},
                {dx:384, dy:FLOOR, w:256},
            ],
            hazards   : [],
        },

        // ── 2 : step up (right side higher) ────────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR,      w:320},
                {dx:320, dy:FLOOR - 48, w:320},
            ],
            hazards   : [],
        },

        // ── 3 : step down (right side lower) ───────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR - 48, w:320},
                {dx:320, dy:FLOOR,      w:320},
            ],
            hazards   : [],
        },

        // ── 4 : wide gap + floating mid-platform to bridge it ───────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR,       w:192},
                {dx:256, dy:FLOOR - 80,  w:128},   // floating step
                {dx:448, dy:FLOOR,       w:192},
            ],
            hazards   : [],
        },

        // ── 5 : flat run with hazard spikes ─────────────────────────────────
        {
            width     : 640,
            platforms : [ {dx:0, dy:FLOOR, w:640} ],
            hazards   : [
                {dx:128, dy:FLOOR - TILE},
                {dx:256, dy:FLOOR - TILE},
                {dx:384, dy:FLOOR - TILE},
                {dx:512, dy:FLOOR - TILE},
            ],
        },

        // ── 6 : stepping-stone run over a pit ───────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR,      w:128},
                {dx:192, dy:FLOOR - 32, w:128},
                {dx:384, dy:FLOOR - 64, w:128},
                {dx:512, dy:FLOOR,      w:128},
            ],
            hazards   : [],
        },

        // ── 7 : raised platform with hazard on top ──────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR,      w:256},
                {dx:256, dy:FLOOR - 96, w:384},
            ],
            hazards   : [
                {dx:352, dy:FLOOR - 96 - TILE},
            ],
        },

        // ── 8 : flat medium stretch ─────────────────────────────────────────
        {
            width     : 640,
            platforms : [ {dx:0, dy:FLOOR, w:640} ],
            hazards   : [],
        },

        // ── 9 : alternating heights with gaps ───────────────────────────────
        {
            width     : 768,
            platforms : [
                {dx:0,   dy:FLOOR,      w:176},
                {dx:256, dy:FLOOR - 48, w:144},
                {dx:512, dy:FLOOR,      w:144},
                {dx:608, dy:FLOOR - 32, w:160},
            ],
            hazards   : [],
        },

        // ── 10 : hazard gauntlet (dense) ────────────────────────────────────
        {
            width     : 640,
            platforms : [ {dx:0, dy:FLOOR, w:640} ],
            hazards   : [
                {dx:96,  dy:FLOOR - TILE},
                {dx:192, dy:FLOOR - TILE},
                {dx:288, dy:FLOOR - TILE},
                {dx:384, dy:FLOOR - TILE},
                {dx:480, dy:FLOOR - TILE},
            ],
        },

        // ── 11 : double-jump island chain ───────────────────────────────────
        {
            width     : 768,
            platforms : [
                {dx:0,   dy:FLOOR,       w:128},
                {dx:176, dy:FLOOR - 64,  w:128},
                {dx:352, dy:FLOOR - 128, w:128},
                {dx:528, dy:FLOOR - 64,  w:128},
                {dx:672, dy:FLOOR,       w:96},
            ],
            hazards   : [],
        },

        // ── 12 : slope-up to raised runway ─────────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR,      w:192},
                {dx:224, dy:FLOOR - 16, w:416},
            ],
            hazards   : [],
            elements  : [
                runner_prefab(objSloped, 192, FLOOR - 32),
            ],
        },

        // ── 13 : slope-down back to ground ─────────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR - 16, w:464},
                {dx:496, dy:FLOOR,      w:144},
            ],
            hazards   : [],
            elements  : [
                runner_prefab(objSloped45Left, 464, FLOOR - 32),
            ],
        },

        // ── 14 : flat patrol enemy slice ───────────────────────────────────
        {
            width     : 640,
            platforms : [ {dx:0, dy:FLOOR, w:640} ],
            hazards   : [],
            elements  : [
                runner_prefab(objSlopBot, 320, FLOOR - 16),
            ],
        },

        // ── 15 : raised enemy after a slope ────────────────────────────────
        {
            width     : 640,
            platforms : [
                {dx:0,   dy:FLOOR,      w:144},
                {dx:176, dy:FLOOR - 16, w:464},
            ],
            hazards   : [],
            elements  : [
                runner_prefab(objSloped, 144, FLOOR - 32),
                runner_prefab(objSlopBot, 320, FLOOR - 32),
            ],
        },

    ];

    // Pull in auto-generated chunks extracted from authored World 1 rooms.
    // Generated by: tools/generate_runner_world1_chunks.ps1
    var _world1_chunks = scr_runner_world1_chunks();
    var _wc_count = array_length(_world1_chunks);
    for (var _i = 0; _i < _wc_count; _i++) {
        array_push(_slices, _world1_chunks[_i]);
    }

    return _slices;
}
