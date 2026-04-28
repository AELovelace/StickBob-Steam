runner_add_kill();
sgc_gateway_report_pve_kill({
    enemy_spawn_id : object_get_name(object_index) + ":" + string(id),
    beneficiary_steam_id : (instance_exists(other) && variable_instance_exists(other, "owner_steam_id")) ? string(other.owner_steam_id) : "",
});
instance_destroy(self);