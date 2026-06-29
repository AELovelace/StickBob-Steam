/// @description Draw bullet with speed trail

// Stretch trail from last position to current
draw_set_alpha(0.3);
draw_set_color(c_yellow);
draw_line_width(xprevious, yprevious - 1, x, y - 1, 2);

draw_set_alpha(1);
draw_set_color(c_white);
draw_self();
