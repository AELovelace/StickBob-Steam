/// @description RunnerDirector – Draw GUI event
// Overlays distance and best-distance HUD alongside the existing health bar.

draw_set_font(fontMenu);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_red);

// Draw GUI coordinates are screen-space; use display_get_gui_width() not room_width.
var _x = display_get_gui_width() / 2;
draw_text(_x,  10, "Score: " + string(runner_score) + " m");
draw_text(_x,  30, "Best:  " + string(runner_best_score) + " m");
draw_text(_x,  50, "Kills: " + string(runner_kills));

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
