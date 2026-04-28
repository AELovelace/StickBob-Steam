instance_destroy(other)
// Local player completed the level – report it before the room transition
// so the gateway can credit a single 10 SGC mint per (run, level, player).
sgc_gateway_report_level_complete({
    level_id : room_get_name(room),
    run_id   : "default",
});
room_goto_next()
