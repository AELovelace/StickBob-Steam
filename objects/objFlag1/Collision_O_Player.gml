instance_destroy(other)
// Local player completed the level – report it before the room transition
// so the gateway can credit a single 10 SGC mint per (run, level, player).
sgc_gateway_report_level_complete({
    level_id : room_get_name(room),
    run_id   : "default",
});
sgc_gateway_end_level_balance_cycle();
room_goto_next()
