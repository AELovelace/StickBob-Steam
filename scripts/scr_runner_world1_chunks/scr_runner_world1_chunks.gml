// Runner chunk loader backed by included JSON files in datafiles/infiniteRunner.
// The companion tool at tools/generate_runner_world1_chunks.ps1 exports:
//   - datafiles/infiniteRunner/chunks_manifest.json
//   - datafiles/infiniteRunner/world1_chunks.json

function runner_chunk_data_candidates(_file_name) {
    var _paths = [
        "infiniteRunner/" + _file_name,
        "datafiles/infiniteRunner/" + _file_name,
    ];

    if (variable_global_exists("working_directory")) {
        var _base = variable_global_get("working_directory");
        if (is_string(_base) && string_length(_base) > 0) {
            var _last = string_char_at(_base, string_length(_base));
            if ((_last != "/") && (_last != "\\")) {
                _base += "/";
            }

            array_push(_paths, _base + "infiniteRunner/" + _file_name);
            array_push(_paths, _base + "datafiles/infiniteRunner/" + _file_name);
        }
    }

    return _paths;
}

function runner_chunk_read_json(_file_name) {
    var _candidates = runner_chunk_data_candidates(_file_name);
    var _count = array_length(_candidates);

    for (var _i = 0; _i < _count; _i++) {
        var _path = _candidates[_i];
        if (!file_exists(_path)) continue;

        var _f = -1;
        try {
            _f = file_text_open_read(_path);

            var _json = "";
            while (!file_text_eof(_f)) {
                _json += file_text_read_string(_f);
                if (!file_text_eof(_f)) {
                    file_text_readln(_f);
                    _json += "\n";
                }
            }

            file_text_close(_f);
            _f = -1;

            if (string_byte_at(_json, 1) == 65279) {
                _json = string_delete(_json, 1, 1);
            }

            if (string_length(_json) <= 0) return undefined;
            return json_parse(_json);
        } catch (_error) {
            if (_f != -1) file_text_close(_f);
            show_debug_message("[runner-chunks] failed to read " + string(_path));
            return undefined;
        }
    }

    show_debug_message("[runner-chunks] missing chunk data file: " + string(_file_name));
    return undefined;
}

function runner_chunk_decode_platform(_raw) {
    return {
        dx : real(variable_struct_get(_raw, "dx")),
        dy : real(variable_struct_get(_raw, "dy")),
        w  : real(variable_struct_get(_raw, "w")),
    };
}

function runner_chunk_decode_hazard(_raw) {
    return {
        dx : real(variable_struct_get(_raw, "dx")),
        dy : real(variable_struct_get(_raw, "dy")),
    };
}

function runner_chunk_decode_element(_raw) {
    var _object_name = string(variable_struct_get(_raw, "object_name"));
    var _asset = asset_get_index(_object_name);
    if (_asset == -1) {
        show_debug_message("[runner-chunks] unknown object asset: " + _object_name);
        return undefined;
    }

    return {
        object_asset : _asset,
        dx           : real(variable_struct_get(_raw, "dx")),
        dy           : real(variable_struct_get(_raw, "dy")),
        scale_x      : real(variable_struct_get(_raw, "scale_x")),
        scale_y      : real(variable_struct_get(_raw, "scale_y")),
        rotation     : real(variable_struct_get(_raw, "rotation")),
    };
}

function runner_chunk_decode_array(_raw_array, _decode_fn) {
    if (!is_array(_raw_array)) return [];

    var _decoded = [];
    var _count = array_length(_raw_array);
    for (var _i = 0; _i < _count; _i++) {
        var _entry = _decode_fn(_raw_array[_i]);
        if (is_struct(_entry)) array_push(_decoded, _entry);
    }

    return _decoded;
}

function runner_chunk_decode_chunk(_raw_chunk) {
    if (!is_struct(_raw_chunk)) return undefined;
    if (!variable_struct_exists(_raw_chunk, "width")) return undefined;

    var _chunk = {
        width     : real(variable_struct_get(_raw_chunk, "width")),
        platforms : [],
        hazards   : [],
        elements  : [],
    };

    if (variable_struct_exists(_raw_chunk, "platforms")) {
        _chunk.platforms = runner_chunk_decode_array(
            variable_struct_get(_raw_chunk, "platforms"),
            runner_chunk_decode_platform
        );
    }

    if (variable_struct_exists(_raw_chunk, "hazards")) {
        _chunk.hazards = runner_chunk_decode_array(
            variable_struct_get(_raw_chunk, "hazards"),
            runner_chunk_decode_hazard
        );
    }

    if (variable_struct_exists(_raw_chunk, "elements")) {
        _chunk.elements = runner_chunk_decode_array(
            variable_struct_get(_raw_chunk, "elements"),
            runner_chunk_decode_element
        );
    }

    if (variable_struct_exists(_raw_chunk, "source_room")) {
        _chunk.source_room = string(variable_struct_get(_raw_chunk, "source_room"));
    }
    if (variable_struct_exists(_raw_chunk, "source_start")) {
        _chunk.source_start = real(variable_struct_get(_raw_chunk, "source_start"));
    }

    return _chunk;
}

function runner_chunk_load_file(_file_name) {
    var _doc = runner_chunk_read_json(_file_name);
    if (!is_struct(_doc)) return [];
    if (!variable_struct_exists(_doc, "chunks")) return [];

    var _raw_chunks = variable_struct_get(_doc, "chunks");
    if (!is_array(_raw_chunks)) return [];

    var _chunks = [];
    var _count = array_length(_raw_chunks);
    for (var _i = 0; _i < _count; _i++) {
        var _chunk = runner_chunk_decode_chunk(_raw_chunks[_i]);
        if (is_struct(_chunk)) array_push(_chunks, _chunk);
    }

    return _chunks;
}

function scr_runner_world1_chunks() {
    var _manifest = runner_chunk_read_json("chunks_manifest.json");
    if (!is_struct(_manifest)) return [];
    if (!variable_struct_exists(_manifest, "files")) return [];

    var _files = variable_struct_get(_manifest, "files");
    if (!is_array(_files)) return [];

    var _chunks = [];
    var _file_count = array_length(_files);
    for (var _i = 0; _i < _file_count; _i++) {
        var _file_name = string(_files[_i]);
        var _loaded = runner_chunk_load_file(_file_name);
        var _loaded_count = array_length(_loaded);
        for (var _j = 0; _j < _loaded_count; _j++) {
            array_push(_chunks, _loaded[_j]);
        }
    }

    return _chunks;
}
