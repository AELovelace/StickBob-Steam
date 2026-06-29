/// @description Shared visual effects helpers: afterimage trail and bloom.

// ---------------------------------------------------------------------------
// vfx_init_trail()
// Call once in Create. Allocates the ring-buffer variables on the instance.
// ---------------------------------------------------------------------------
function vfx_init_trail() {
    trail_length = 5;
    trail_x   = array_create(trail_length, x);
    trail_y   = array_create(trail_length, y);
    trail_spr = array_create(trail_length, sprite_index);
    trail_frm = array_create(trail_length, 0);
    trail_xsc = array_create(trail_length, image_xscale);
    trail_ysc = array_create(trail_length, image_yscale);
}

// ---------------------------------------------------------------------------
// vfx_update_trail()
// Call every Step (or Step End). Shifts the buffer and records the current
// position / sprite so the draw call has up-to-date data.
// ---------------------------------------------------------------------------
function vfx_update_trail() {
    for (var _t = trail_length - 1; _t > 0; _t--) {
        trail_x[_t]   = trail_x[_t - 1];
        trail_y[_t]   = trail_y[_t - 1];
        trail_spr[_t] = trail_spr[_t - 1];
        trail_frm[_t] = trail_frm[_t - 1];
        trail_xsc[_t] = trail_xsc[_t - 1];
        trail_ysc[_t] = trail_ysc[_t - 1];
    }
    trail_x[0]   = x;
    trail_y[0]   = y;
    trail_spr[0] = sprite_index;
    trail_frm[0] = image_index;
    trail_xsc[0] = image_xscale;
    trail_ysc[0] = image_yscale;
}

// ---------------------------------------------------------------------------
// vfx_draw_afterimage(_tint)
// Call at the START of the Draw event, before draw_self.
// Draws ghost copies of the last trail_length frames behind the sprite.
// ---------------------------------------------------------------------------
function vfx_draw_afterimage(_tint) {
    gpu_set_blendmode(bm_add);
    for (var _t = trail_length - 1; _t >= 0; _t--) {
        var _a = (1.0 - (_t / trail_length)) * 0.18;
        draw_sprite_ext(trail_spr[_t], trail_frm[_t],
            trail_x[_t], trail_y[_t],
            trail_xsc[_t], trail_ysc[_t],
            0, _tint, _a);
    }
    gpu_set_blendmode(bm_normal);
}

// ---------------------------------------------------------------------------
// vfx_draw_bloom(_tint)
// Call at the END of the Draw event, after all other sprites are drawn.
// Redraws the current sprite at small cardinal offsets with additive blending
// to simulate a soft glow around the character.
// ---------------------------------------------------------------------------
function vfx_draw_bloom(_tint) {
    gpu_set_blendmode(bm_add);
    var _offsets = [
        [  2,  0 ], [ -2,  0 ], [  0,  2 ], [  0, -2 ],
        [  3,  0 ], [ -3,  0 ], [  0,  3 ], [  0, -3 ],
    ];
    var _bloom_alpha = 0.07;
    for (var _b = 0; _b < array_length(_offsets); _b++) {
        draw_sprite_ext(sprite_index, image_index,
            x + _offsets[_b][0],
            y + _offsets[_b][1],
            image_xscale, image_yscale,
            0, _tint, _bloom_alpha);
    }
    gpu_set_blendmode(bm_normal);
}
