/// @description RunnerDirector – Draw GUI event
// Overlays distance and best-distance HUD alongside the existing health bar.

draw_set_font(fontMenu);
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_color(c_red);

// Keep clear of the top-center SGC HUD and the top-right MP3 player.
var _x = display_get_gui_width() - 12;
var _y = display_get_gui_height() - 12;
draw_text(_x, _y - 40, "Score: " + string(runner_score) + " m");
draw_text(_x, _y - 20, "Best:  " + string(runner_best_score) + " m");
draw_text(_x, _y,      "Kills: " + string(runner_kills));

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
