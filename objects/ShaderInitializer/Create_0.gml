display_reset(8, false);
global.GameState = new GameStateCreate();

room_goto(rm_MainMenu);

#region SHADER
	
	UCRTParams = shader_get_uniform(SHD_CRT, "params");
	CRT = global.GameState.CRT;
	application_surface_draw_enable(false);
	
#endregion