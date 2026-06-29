/// @description Chat overlay (Phase 6.1)
// Renders the last few chat lines and the active input field when open.

if (!variable_global_exists("chat_log")) exit;
if (!(instance_exists(obj_Server) || instance_exists(obj_Client))) exit;

var _gui_w = display_get_gui_width()
var _gui_h = display_get_gui_height()
var _x     = 16
var _y0    = _gui_h - 200
var _line  = 18

draw_set_alpha(0.85)
draw_set_color(c_white)

var _count = array_length(global.chat_log)
var _max_show = 8
var _start = max(0, _count - _max_show)
var _now = current_time
for (var _i = _start; _i < _count; _i++) {
	var _m = global.chat_log[_i]
	var _age = _now - _m.t
	if (!chat_open && _age > chat_visible_ms) continue
	var _alpha = (!chat_open && _age > chat_visible_ms - 1000) ? clamp((chat_visible_ms - _age) / 1000, 0, 1) : 1
	draw_set_alpha(_alpha)
	draw_text(_x, _y0 + (_i - _start) * _line, "[" + string(_m.name) + "] " + string(_m.text))
}

if (chat_open) {
	draw_set_alpha(0.9)
	draw_set_color(c_black)
	draw_rectangle(_x - 4, _gui_h - 36, _gui_w - _x, _gui_h - 12, false)
	draw_set_color(c_yellow)
	draw_text(_x, _gui_h - 32, "Say: " + chat_input + ((current_time div 500) mod 2 == 0 ? "_" : ""))
}

draw_set_alpha(1)
draw_set_color(c_white)
