if CRT.ShaderOn
{
	shader_set(SHD_CRT);

	// If using shader on GUI layer, set resolution
	// CRT.SetResolution(window_get_width(), window_get_height());

	shader_set_uniform_f_array(UCRTParams, CRT.Params);
	shader_set_uniform_f(UCRTTime, current_time * 0.001);
}

gpu_set_blendenable(false);
draw_surface_ext(application_surface, 0, 0, 1, 1, 0, c_white, 1);
gpu_set_blendenable(true);
shader_reset();

menu_neo_draw_flicker_overlay();