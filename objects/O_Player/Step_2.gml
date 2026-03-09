camera_set_view_target(view_camera[1], O_Player);
var _cam = view_camera[1];
var _camW = camera_get_view_width(_cam);
var _camH = camera_get_view_height(_cam);

// Center on player (assuming player origin is top-left)
var _camX = x - (_camW/2);
var _camY = y - _camH/2;
var _newCamX = lerp(_camX,(_camX+(xSpeed*150)), 0.05)
camera_set_view_pos(_cam, _newCamX, _camY);

var _cx = camera_get_view_x(view_camera[1]);
var _xspd = 3 * (keyboard_check(vk_right) - keyboard_check(vk_left));
_cx += _xspd
camera_set_view_pos(view_camera[0], _cx, 0);

var _b = ds_map_find_first(background_map);
repeat(ds_map_size(background_map))
    {
    layer_x(_b, background_map[? _b] * _cx);
    _b = ds_map_find_next(background_map, _b);
	}
//  0. HTML5 DYNAMIC RESIZE - keep canvas filling browser viewport
if (os_browser != browser_not_a_browser) {
    var _bw = browser_width  - 10;  // browser viewport width minus 10px padding
    var _bh = browser_height - 10;  // browser viewport height minus 10px padding
    if (_bw != window_get_width() || _bh != window_get_height()) {  // only resize when the browser actually changed
        window_set_size(_bw, _bh);  // resize game canvas to match new browser size
    }
}