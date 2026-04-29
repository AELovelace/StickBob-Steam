if !isLocal exit;

draw_set_color(c_red);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(fontMenu)

var _modeName = "Classic"
if global.gameParams.modeSelection == global.GAME_MODE_HP5 then _modeName = "HP5"

draw_text(10, 10, "Mode: " + _modeName)
draw_text(10, 25, "Health: " + string(playerHealth) + "/" + string(maxHealth))

var _hpPercent = 0
if maxHealth > 0 then _hpPercent = (playerHealth / maxHealth) * 100
draw_healthbar(10,45,120,58,_hpPercent,c_black,c_red,c_green,0,true,true)
sgc_gateway_draw_balance_hud();
