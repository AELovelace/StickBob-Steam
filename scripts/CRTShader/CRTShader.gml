// CRT shader configuration and global utility functions.
// The CRT effect simulates a cathode-ray-tube monitor: scanlines, pixel
// sharpness, screen curvature (warp), and colour-space correction.

// Holds all parameters sent to the CRT shader as a flat array (Params[]).
// ECRT enum maps readable names to array indices so the shader uniforms can
// be uploaded in order without magic numbers.
function CRTParameters() constructor
{
	enum ECRT
	{
		ResX,       // output resolution width  (pixels)
		ResY,       // output resolution height (pixels)
		ResScale,   // integer scale factor applied to the internal render
		HardScan,   // scanline darkness  (more negative = harder/darker lines)
		HardPixel,  // pixel sharpness    (more negative = sharper edges)
		WarpX,      // horizontal screen-edge curvature
		WarpY,      // vertical screen-edge curvature
		MaskDark,   // shadow mask dark-channel brightness
		MaskLight,  // shadow mask light-channel brightness
		SRGB,       // enable sRGB gamma correction (1 = on)
		Last        // sentinel — number of parameters
	}

	//                                       Scale  Scan  Pixel  WarpX  WarpY  Dark  Light  SRGB
	Params = [window_get_width(), window_get_height(), 1, -2.0, -1.0, 32.0, 32.0, 0.5, 1.5, 1];
	ShaderOn = true;  // master toggle; set false to bypass the CRT effect

	// Overwrites all parameters at once.  Values are clamped to safe ranges
	// to prevent the shader from producing degenerate output.
	function Set(_resX, _resY, _resScale, _scan, _pixel, _warpX, _warpY, _dark, _light, _srgb)
	{
		Params =
		[
			_resX,
			_resY,
			clamp(_resScale, 2,   6),
			clamp(_scan,    -8, -16),
			clamp(_pixel,   -2,  -4),
			clamp(_warpX,    0,  32),
			clamp(_warpY,    0,  24),
			clamp(_dark,   0.2,   2),
			clamp(_light,  0.2,   2),
			_srgb
		];
	}

	// Updates only the resolution parameters (e.g. on window resize).
	function SetResolution(_resX, _resY)
	{
		Params[ECRT.ResX] = _resX;
		Params[ECRT.ResY] = _resY;
	}
}

// Top-level game-state container created once during shader initialisation.
// Stores the CRT parameters and version info for the ShaderInitializer object.
function GameStateCreate() constructor
{
	Name    = "CRT Shader";
	Version = "0.0.0.1";

	CRT = new CRTParameters();
}

// Inverse-lerp: maps _val from the range [_min, _max] to [0, 1].
// Useful for normalising shader input values before uploading them as uniforms.
function InvLerp(_min, _max, _val)
{
	return (_val - _min) / (_max - _min);
}

// Variadic debug logger. Accepts any number of arguments (strings or values)
// and prints them space-separated to the debug console.
function Log()
{
	var _msg = "LOG: ", _arg;
	for (var _i = 0; _i < argument_count; _i++)
	{
		_arg = argument[_i];
		if is_string(_arg) { _msg += _arg + " "; continue; }
	    _msg += string(_arg) + " ";
	}
	show_debug_message(_msg);
}

#region MACROS
	// --- Input shortcuts (used in the shader preview / editor tool) ---
	#macro INPUT_HOR (keyboard_check(ord("D")) - keyboard_check(ord("A")))  // horizontal axis: -1/0/1
	#macro INPUT_VER (keyboard_check(ord("S")) - keyboard_check(ord("W")))  // vertical axis:   -1/0/1
	#macro MOUSE_WHEEL (mouse_wheel_down() - mouse_wheel_up())              // scroll axis:     -1/0/1

	// --- Camera / view shortcuts ---
	#macro VIEW       view_camera[0]  // primary camera handle
	#macro VIEW_WIDTH 160             // internal render width (pixels)
	#macro ZOOM_MIN   0.4
	#macro ZOOM_MAX   4
	#macro ZOOM_SPEED 0.1

	// --- Text-rendering helper macros ---
	// Usage pattern:
	//   TX 10  TY 20  TEXT "hello"  ENDLINE
	// Expands to a draw_text call and advances _textY by one line height.
	#macro TX      var _textH = string_height("H") var _textX =
	#macro TY      var _textY =
	#macro TEXT    draw_text(_textX, _textY,
	#macro ENDLINE ); _textY += _textH
	#macro NEWLINE _textY += _textH
#endregion
