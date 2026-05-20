layout_margin = 28;
action_card_x = 34;
action_card_y = 148;
action_card_w = 250;
action_card_h = 38;
action_card_gap = 10;

button[0] = "HOST GAME";
button[1] = "JOIN GAME";
button[2] = "SINGLEPLAYER";
button[3] = "RUNNER";
button[4] = "LEADERBOARDS";
button[5] = "LINK SGC OAUTH";
button[6] = "SADGIRLSCLUB.WTF";
button[7] = "SETTINGS";
button[8] = "STORE";
button[9] = "EXIT";

button_desc[0] = "Spin up a multiplayer lobby and drop straight into the player-count flow.";
button_desc[1] = "Browse open lobbies and connect to the current host feed.";
button_desc[2] = "Boot the singleplayer rooms with SGC reward hooks active.";
button_desc[3] = "Jump into the runner mode and chase score plus kill momentum.";
button_desc[4] = "Open the Steam-fed notice board for global, friends, and around-you ranks.";
button_desc[5] = "Link your Steam identity to SadGirlCoin through the gateway browser flow.";
button_desc[6] = "Open the club homepage in your system browser.";
button_desc[7] = "Adjust resolution, fullscreen, and player color from the existing settings screen.";
button_desc[8] = "Buy unlockable weapons and playlists with SadGirlCoin.";
button_desc[9] = "Close the game client.";

buttons = array_length_1d(button);
menu_index = 0;
last_selected = 0;
last_mouse_x = device_mouse_x_to_gui(0);
last_mouse_y = device_mouse_y_to_gui(0);

sgc_gateway_bootstrap(false);
