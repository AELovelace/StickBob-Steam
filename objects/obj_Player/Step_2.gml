// Only the locally owned player should drive camera and parallax.
if !isLocal exit;
if lobbyMemberID == undefined exit;

var _cam = view_camera[lobbyMemberID];
if _cam == undefined || _cam < 0 exit;
//view_set_visible(0, false)
var _maxZoomFactor = 1.5;
var _zoomSpeed = 0.05;
var _isMoving = (abs(xSpeed) > 3);

// 1. Calculate the Target Size
var _targetW, _targetH;
var _currentW = camera_get_view_width(_cam);
var _currentH = camera_get_view_height(_cam);

if (_isMoving) {
    var _speedRatio = clamp(abs(xSpeed) / 8, 0, 1);
    var _newCamW = 320 * (1 + (_speedRatio * (_maxZoomFactor - 1)));
    var _newCamH = 240 * (1 + (_speedRatio * (_maxZoomFactor - 1)));
    
    _targetW = lerp(_currentW, _newCamW, _zoomSpeed);
    _targetH = lerp(_currentH, _newCamH, _zoomSpeed);
    
    zoomDelay = 30; // Reset timer while moving
} else {
    if (zoomDelay > 0) {
        zoomDelay -= 1; // Correct countdown
        _targetW = _currentW; // Hold current size
        _targetH = _currentH;
    } else {
        // Return to base size (320x240)
        _targetW = lerp(_currentW, 320, _zoomSpeed);
        _targetH = lerp(_currentH, 240, _zoomSpeed);
    }
}

camera_set_view_size(_cam, _targetW, _targetH);

// 2. Position the Camera
// Use the updated width/height for centering
var _camX = x - (_targetW / 2);
var _camY = y - (_targetH / 2);

// Apply horizontal look-ahead based on speed
var _targetLookAhead = 0;
if (abs(xSpeed) > 1) {
    _targetLookAhead = sign(xSpeed) * 120;
}
camLookAhead = lerp(camLookAhead, _targetLookAhead, 0.12);
var _finalX = _camX + camLookAhead;
_finalX = clamp(_finalX, 0, room_width - _targetW);
_camY = clamp(_camY, 0, room_height - _targetH);
camera_set_view_pos(_cam, _finalX, _camY);

// 3. Parallax Backgrounds
var _cx = camera_get_view_x(_cam);
var _b = ds_map_find_first(background_map);
repeat(ds_map_size(background_map)) {
    layer_x(_b, background_map[? _b] * _cx);
    _b = ds_map_find_next(background_map, _b);
}

//check for death
