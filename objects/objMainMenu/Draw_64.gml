// Draw Event or Draw GUI Event
var i = 0;
draw_set_font(fontMenu); // Replace with your font asset name
draw_set_halign(fa_center); // Center the text horizontally
draw_set_valign(fa_top);
draw_text(menu_x, menu_y-50, "STICKBOB!");
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

sgc_gateway_state_init();

var _status = "SGC STATUS: CONNECTING";
if (global.sgc_gateway.ready) {
    if (global.sgc_gateway.linked) {
        _status = "SGC STATUS: LOGGED IN";
    } else {
        _status = "SGC STATUS: NOT LINKED";
    }
}

var _balance = sgc_gateway_balance_text();
var _pad = 24;
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();

draw_set_font(fontMenu);
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_color(c_ltgray);
draw_text(_gui_w - _pad, _gui_h - _pad - 40, _status);

if (global.sgc_gateway.ready && global.sgc_gateway.linked) {
    draw_set_color(c_red);
} else {
    draw_set_color(c_ltgray);
}
draw_text(_gui_w - _pad, _gui_h - _pad, _balance);

// Remember to reset draw settings if you draw other elements later
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
