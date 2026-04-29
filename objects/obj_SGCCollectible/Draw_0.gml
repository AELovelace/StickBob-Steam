var _pulse = 0.85 + 0.15 * sin((current_time + collectiblePulseSeed) / 120);
var _radius = 7 * _pulse;
var _outer = _radius + 4;
var _inner = max(2, _radius - 2);

draw_set_alpha(0.18);
draw_set_color(make_color_rgb(90, 255, 255));
draw_circle(x - 1, y + 1, _outer, false);
draw_set_color(make_color_rgb(255, 90, 180));
draw_circle(x + 1, y - 1, _outer - 1, false);

draw_set_alpha(0.95);
draw_set_color(make_color_rgb(255, 40, 40));
draw_circle(x, y, _radius, false);

draw_set_alpha(0.55);
draw_set_color(make_color_rgb(255, 220, 220));
draw_circle(x, y, _inner, false);

draw_set_font(fontMenuSmall);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_alpha(1);
draw_set_color(c_white);
draw_text(x, y, "+" + string(sgcAmount));

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
