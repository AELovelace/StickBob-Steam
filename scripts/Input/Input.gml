// Input handling for both multiplayer and singleplayer.
//
// In multiplayer the host reads input locally and immediately broadcasts it
// to connected clients (so everyone can simulate the host's character).
// A non-host client reads its own input and sends it to the server; the
// server applies it and relays positions back.

// Reads raw input for the current frame and routes it over the network.
//   _is_host  – true if this player is the lobby owner / server
//   _is_local – true if this instance belongs to the local machine
//     (false for remote player objects that are controlled by packets)
function get_controls(_is_host, _is_local)
{
	if (_is_host && _is_local) {
		// --- Host reads local hardware ---
		rightKey = keyboard_check(vk_right) ||keyboard_check(ord("D")) || gamepad_button_check( 0, gp_padr );
		leftKey  = keyboard_check(vk_left) || keyboard_check(ord("A")) || gamepad_button_check( 0, gp_padl );
		downKey  = keyboard_check(vk_down) || keyboard_check(ord("S")) || gamepad_button_check( 0, gp_padd );
		upKey  = keyboard_check(vk_up) || keyboard_check(ord("W")) || gamepad_button_check( 0, gp_padu );
		allDir = rightKey+leftKey+downKey+upKey
		// Collapse directional keys into signed axis values (-1, 0, 1)
		xInput = (rightKey - leftKey)
		yInput = (downKey - upKey)

		runKey    = keyboard_check(vk_shift) || gamepad_button_check( 0, gp_face3 );
		actionKey = keyboard_check(vk_space) || mouse_check_button(mb_left) || gamepad_button_check( 0, gp_face2 );
		mouseAngle = point_direction(x, y, mouse_x, mouse_y);

		// Broadcast the host's input to all clients so they can simulate the host character
		var _input = {steamID: lobbyHost, xInput:xInput, yInput:yInput, runKey:runKey, actionKey:actionKey, mouseAngle:mouseAngle}
		send_player_input_to_clients(_input)
	}

	if (!_is_host && _is_local) {
		// --- Client reads local hardware ---
		// Use locals so we don't overwrite the instance vars that are
		// set by incoming SERVER_PLAYER_INPUT packets for remote players.
		var _rightKey = keyboard_check(vk_right) ||keyboard_check(ord("D")) || gamepad_button_check( 0, gp_padr );
		var _leftKey  = keyboard_check(vk_left) || keyboard_check(ord("A")) || gamepad_button_check( 0, gp_padl );
		var _downKey  = keyboard_check(vk_down) || keyboard_check(ord("S")) || gamepad_button_check( 0, gp_padd );
		var _upKey  = keyboard_check(vk_up) || keyboard_check(ord("W")) || gamepad_button_check( 0, gp_padu );

		var _runKey    = keyboard_check(vk_shift) || gamepad_button_check( 0, gp_face3 );
		var _actionKey = keyboard_check(vk_space) || mouse_check_button(mb_left) || gamepad_button_check( 0, gp_face2 );
		var _mouseAngle = point_direction(x, y, mouse_x, mouse_y);

		// Send raw key state to the server; the server converts to axis values
		var _input = {rightKey:_rightKey, leftKey:_leftKey, downKey:_downKey, upKey:_upKey, runKey:_runKey, actionKey:_actionKey, mouseAngle:_mouseAngle}
		send_player_input(_input, lobbyHost);
	}
}

// Zeroes out all input variables. Call on player creation before the first
// get_controls() tick so no undefined reads occur.
function init_controls(){
	rightKey	= 0
	leftKey		= 0
	downKey		= 0
	upKey		= 0

	// Signed axis values derived from directional keys
	xInput = 0
	yInput = 0

	runKey		= 0
	actionKey	= 0
	mouseAngle  = 0;
}

// Singleplayer input: reads hardware directly into instance vars each frame.
// No networking required — there is no server to send to.
function getSPControls(){
	rightKey = keyboard_check(vk_right) ||keyboard_check(ord("D")) || gamepad_button_check( 0, gp_padr );
	leftKey  = keyboard_check(vk_left) || keyboard_check(ord("A")) || gamepad_button_check( 0, gp_padl );
	downKey  = keyboard_check(vk_down) || keyboard_check(ord("S")) || gamepad_button_check( 0, gp_padd );
	// Released check is needed for the slide-cancel logic in paddle_movement
	downKeyReleased  = keyboard_check_released(vk_down) || keyboard_check_released(ord("S")) || gamepad_button_check_released( 0, gp_padd );
	upKey  = keyboard_check(vk_up) || keyboard_check(ord("W")) || gamepad_button_check( 0, gp_padu );
	allDir = rightKey+leftKey+downKey+upKey
	xInput = (rightKey - leftKey)
	yInput = (downKey - upKey)

	runKey    = keyboard_check(vk_shift) || gamepad_button_check( 0, gp_face3 );
	actionKey = keyboard_check(vk_space) || mouse_check_button(mb_left) || gamepad_button_check( 0, gp_face2 );
	mouseAngle = point_direction(x, y, mouse_x, mouse_y);
}
