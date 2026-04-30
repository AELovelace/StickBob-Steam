function app_settings_defaults() {
    return {
        resolution_width: 1366,
        resolution_height: 768,
        fullscreen: false,
        master_volume: 25,
        music_volume: 100,
        player_color: 16777215,
        unlockables: unlockables_default_state()
    }
}

function app_settings_path() {
    var _file_name = "app_settings.json"
    var _base_path = ""

    // Prefer persistent save location when available.
    if (variable_global_exists("save_directory")) {
        _base_path = variable_global_get("save_directory")
    } else if (variable_global_exists("working_directory")) {
        // Fallback for platforms/runtimes where save_directory is not exposed.
        _base_path = variable_global_get("working_directory")
    }

    if (is_string(_base_path) && (string_length(_base_path) > 0)) {
        var _last_char = string_char_at(_base_path, string_length(_base_path))
        if ((_last_char != "/") && (_last_char != "\\")) {
            _base_path += "/"
        }
        return _base_path + _file_name
    }

    return _file_name
}

function app_settings_load() {
    var _settings = app_settings_defaults()
    var _path = app_settings_path()

    // First boot: write defaults so the file always exists after startup.
    if (!file_exists(_path)) {
        app_settings_save(_settings)
        return _settings
    }

    var _f = -1
    try {
        _f = file_text_open_read(_path)

        var _json = ""
        while (!file_text_eof(_f)) {
            _json += file_text_read_string(_f)
            if (!file_text_eof(_f)) {
                file_text_readln(_f)
                _json += "\n"
            }
        }

        file_text_close(_f)
        _f = -1

        if (string_length(_json) <= 0) {
            app_settings_save(_settings)
            return _settings
        }

        var _loaded = json_parse(_json)
        if (!is_struct(_loaded)) {
            app_settings_save(_settings)
            return _settings
        }

        if (variable_struct_exists(_loaded, "resolution_width")) {
            _settings.resolution_width = max(320, real(_loaded.resolution_width))
        }
        if (variable_struct_exists(_loaded, "resolution_height")) {
            _settings.resolution_height = max(240, real(_loaded.resolution_height))
        }
        if (variable_struct_exists(_loaded, "fullscreen")) {
            var _fullscreen = _loaded.fullscreen
            if (is_bool(_fullscreen)) {
                _settings.fullscreen = _fullscreen
            } else if (is_real(_fullscreen)) {
                _settings.fullscreen = (_fullscreen != 0)
            } else if (is_string(_fullscreen)) {
                var _fullscreen_text = string_lower(_fullscreen)
                if ((_fullscreen_text == "true") || (_fullscreen_text == "1") || (_fullscreen_text == "yes") || (_fullscreen_text == "on")) {
                    _settings.fullscreen = true
                } else if ((_fullscreen_text == "false") || (_fullscreen_text == "0") || (_fullscreen_text == "no") || (_fullscreen_text == "off")) {
                    _settings.fullscreen = false
                }
            }
        }

        if (variable_struct_exists(_loaded, "master_volume")) {
            _settings.master_volume = clamp(real(_loaded.master_volume), 0, 100)
        }
        if (variable_struct_exists(_loaded, "music_volume")) {
            _settings.music_volume = clamp(real(_loaded.music_volume), 0, 100)
        }
        if (variable_struct_exists(_loaded, "player_color")) {
            var _pc = real(_loaded.player_color)
            _settings.player_color = (_pc >= 0 && _pc <= 16777215) ? _pc : 16777215
        }
        if (variable_struct_exists(_loaded, "unlockables")) {
            _settings.unlockables = unlockables_normalize_state(_loaded.unlockables)
        }

        _settings.resolution_width = max(320, real(_settings.resolution_width))
        _settings.resolution_height = max(240, real(_settings.resolution_height))
        _settings.master_volume = clamp(real(_settings.master_volume), 0, 100)
        _settings.music_volume = clamp(real(_settings.music_volume), 0, 100)
        _settings.unlockables = unlockables_normalize_state(_settings.unlockables)

        return _settings
    } catch (_error) {
        if (_f != -1) {
            file_text_close(_f)
        }
        app_settings_save(_settings)
        return _settings
    }
}

function app_settings_save(_settings) {
    var _path = app_settings_path()
    var _json = json_stringify(_settings)
    var _f = -1

    try {
        _f = file_text_open_write(_path)
        file_text_write_string(_f, _json)
        file_text_close(_f)
        return true
    } catch (_error) {
        if (_f != -1) {
            file_text_close(_f)
        }
        return false
    }
}

function app_settings_current() {
    var _settings = app_settings_defaults()

    if variable_global_exists("appSettings") then _settings = variable_global_get("appSettings")
    if !is_struct(_settings) then _settings = app_settings_defaults()
    if !variable_struct_exists(_settings, "unlockables") then _settings.unlockables = unlockables_default_state()
    _settings.unlockables = unlockables_normalize_state(_settings.unlockables)

    variable_global_set("appSettings", _settings)
    return _settings
}

function app_settings_apply_choice(_resolution_option, _fullscreen_value) {
    var _settings = app_settings_current()
    var _selectedW = variable_struct_get(_resolution_option, "w")
    var _selectedH = variable_struct_get(_resolution_option, "h")

    variable_struct_set(_settings, "resolution_width", _selectedW)
    variable_struct_set(_settings, "resolution_height", _selectedH)
    variable_struct_set(_settings, "fullscreen", _fullscreen_value)
    variable_global_set("appSettings", _settings)

    app_settings_save(_settings)
    app_settings_apply(_settings)
}

function app_settings_toggle_fullscreen() {
    // Flip the fullscreen flag while preserving the current windowed resolution.
    var _settings = app_settings_current()
    var _fullscreen = false
    if variable_struct_exists(_settings, "fullscreen") then _fullscreen = (variable_struct_get(_settings, "fullscreen") == true)

    _fullscreen = !_fullscreen
    variable_struct_set(_settings, "fullscreen", _fullscreen)
    variable_global_set("appSettings", _settings)

    // Persist and apply immediately so menu/game stay in sync.
    app_settings_save(_settings)
    app_settings_apply(_settings)
}

function app_settings_apply(_settings) {
    // Normalize incoming settings before applying to runtime/window state.
    var _w = max(320, _settings.resolution_width)
    var _h = max(240, _settings.resolution_height)
    var _fs = (_settings.fullscreen == true)

    window_set_fullscreen(_fs)

    if (!_fs) {
        // Windowed mode respects configured resolution.
        window_set_size(_w, _h)
        window_center()
    } else {
        // Fullscreen should fill the available display area.
        _w = display_get_width()
        _h = display_get_height()
    }

    // Keep active viewports in sync with the chosen output size.
    if view_enabled {
        for (var _view = 0; _view < 8; _view++) {
            if view_visible[_view] {
                view_wport[_view] = _w
                view_hport[_view] = _h
            }
        }
    }

    // Resize the application surface so drawn content fills the output.
    surface_resize(application_surface, _w, _h)

    app_settings_apply_audio(_settings)
}

function app_settings_apply_audio(_settings) {
    var _defaults = app_settings_defaults()
    var _mv = variable_struct_exists(_settings, "master_volume") ? real(_settings.master_volume) : _defaults.master_volume
    var _mw = variable_struct_exists(_settings, "music_volume")  ? real(_settings.music_volume)  : _defaults.music_volume
    _mv = clamp(_mv, 0, 100)
    _mw = clamp(_mw, 0, 100)

    global.masterVolume = _mv
    global.musicVolume  = _mw

    var _master_gain = (_mv <= 0) ? 0 : power(10, ((_mv / 100) - 1) * 2)
    var _music_gain  = (_mw <= 0) ? 0 : power(10, ((_mw / 100) - 1) * 2)

    global.masterGain = _master_gain
    audio_master_gain(_master_gain)

    var _sfx_group = asset_get_index("SFX")
    if (_sfx_group != -1) try { audio_group_set_gain(_sfx_group, _master_gain, 0) } catch (_e) {}
    var _music_group = asset_get_index("SADP3")
    if (_music_group != -1) try { audio_group_set_gain(_music_group, _music_gain / 8, 0) } catch (_e) {}
}

function app_settings_set_master_volume(_master_volume) {
    // Clamp, persist, and let objMasterSliderMenu Step_2 apply the gain each frame.
    var _v = clamp(real(_master_volume), 0, 100)
    var _settings = app_settings_current()
    var _prev = variable_struct_exists(_settings, "master_volume") ? real(_settings.master_volume) : -1
    _settings.master_volume = _v
    variable_global_set("appSettings", _settings)
    if (_v != _prev) {
        app_settings_save(_settings)
    }
    // NOTE: do NOT call app_settings_apply_audio here - it would overwrite global.musicVolume
    // from the saved JSON, snapping the music slider back to the last-saved value.
}

function app_settings_set_music_volume(_music_volume) {
    // Clamp, persist, and let SadP3Player Step_2 apply the gain each frame.
    var _v = clamp(real(_music_volume), 0, 100)
    var _settings = app_settings_current()
    var _prev = variable_struct_exists(_settings, "music_volume") ? real(_settings.music_volume) : -1
    _settings.music_volume = _v
    variable_global_set("appSettings", _settings)
    if (_v != _prev) {
        app_settings_save(_settings)
    }
    // NOTE: do NOT call app_settings_apply_audio here - it would overwrite global.masterVolume
    // from the saved JSON, snapping the master slider back to the last-saved value.
}
