// Draw Event or Draw GUI Event
var i = 0;
draw_set_font(fontMenu); // Replace with your font asset name
draw_set_halign(fa_center); // Center the text horizontally

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