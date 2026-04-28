// Draw Event or Draw GUI Event
var i = 0;
draw_set_font(fontMenu); // Replace with your font asset name
draw_set_halign(fa_center); // Center the text horizontally
draw_text(320, 100, "STICKBOB!");
repeat(buttons) {
    // Set color based on selection status
    if (menu_index == i) {
        draw_set_color(c_red); // Highlighted color
    } else {
        draw_set_color(c_ltgray); // Normal color
    }
    
    // Draw the text option
    draw_text(menu_x, menu_y + button_h * i, button[i]);
    
    i++;
}

// Remember to reset draw settings if you draw other elements later
draw_set_halign(fa_left);
draw_set_color(c_white);

// --- Color picker ---
var _cx = colorPickerX
var _cw = colorPickerW
var _ch = colorPickerH

// Header label
draw_set_font(fontMenuSmall)
draw_set_halign(fa_center)
draw_set_color(c_white)
draw_text(_cx + _cw / 2, menu_y - 36, "Change StickBob Color")

// Slider rows: R at menu_y, G at menu_y+40, B at menu_y+80
var _labels = ["R", "G", "B"]
var _vals   = [sliderR, sliderG, sliderB]
var _cols   = [make_color_rgb(200, 40, 40), make_color_rgb(40, 180, 40), make_color_rgb(40, 80, 220)]
var _rowY   = [menu_y, menu_y + 40, menu_y + 80]

draw_set_halign(fa_left)
for (var _s = 0; _s < 3; _s++) {
    var _sy = _rowY[_s]
    var _t  = _vals[_s] / 255

    // Track background
    draw_set_color(make_color_rgb(50, 50, 50))
    draw_rectangle(_cx, _sy - _ch, _cx + _cw, _sy + _ch, false)

    // Filled (coloured) portion
    draw_set_color(_cols[_s])
    draw_rectangle(_cx, _sy - _ch, _cx + _cw * _t, _sy + _ch, false)

    // Drag knob
    var _kx = _cx + _cw * _t
    draw_set_color(c_white)
    draw_circle(_kx, _sy, _ch + 3, false)

    // Label to the left, numeric value to the right
    draw_set_color(c_ltgray)
    draw_set_halign(fa_right)
    draw_text(_cx - 8, _sy - 8, _labels[_s])
    draw_set_halign(fa_left)
    draw_text(_cx + _cw + 8, _sy - 8, string(_vals[_s]))
}

// Colour preview swatch
var _previewY = menu_y + 110
var _previewColor = make_color_rgb(sliderR, sliderG, sliderB)
draw_set_color(c_white)
draw_rectangle(_cx, _previewY, _cx + _cw, _previewY + 28, true)
draw_set_color(_previewColor)
draw_rectangle(_cx + 2, _previewY + 2, _cx + _cw - 2, _previewY + 26, false)

// Reset
draw_set_halign(fa_left)
draw_set_color(c_white)