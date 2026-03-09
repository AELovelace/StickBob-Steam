draw_set_font(fontMenuSmall)
draw_set_color(c_yellow)
if ds_exists(global.ds_grid_pathfinding, ds_type_grid) {
    // Only draw cells visible in the current camera view
    var _cx = camera_get_view_x(view_camera[0]);
    var _cy = camera_get_view_y(view_camera[0]);
    var _cw = camera_get_view_width(view_camera[0]);
    var _ch = camera_get_view_height(view_camera[0]);
    var _i_start = max(0, floor(_cx / cell_width));
    var _i_end   = min(ds_grid_width(global.ds_grid_pathfinding) - 1, ceil((_cx + _cw) / cell_width));
    var _j_start = max(0, floor(_cy / cell_height));
    var _j_end   = min(ds_grid_height(global.ds_grid_pathfinding) - 1, ceil((_cy + _ch) / cell_height));
    for (var i = _i_start; i <= _i_end; i++) {
        for (var j = _j_start; j <= _j_end; j++) {
            var value = ds_grid_get(global.ds_grid_pathfinding, i, j);
            draw_text_transformed(i * cell_width, j * cell_height, string(value), 0.5, 0.5, 0);
        }
    }
}
draw_set_color(c_white)