runner_add_kill();
var _beneficiary = "";
if (instance_exists(other)) {
    if (variable_instance_exists(other, "owner_steam_id")) {
        _beneficiary = string(other.owner_steam_id);
    } else if (variable_instance_exists(other, "owner_id")
        && instance_exists(other.owner_id)
        && variable_instance_exists(other.owner_id, "steamID")) {
        _beneficiary = string(other.owner_id.steamID);
    }
}
if (instance_exists(other)) {
    instance_destroy(other);
}
sgc_gateway_report_pve_kill({
    enemy_spawn_id : object_get_name(object_index) + ":" + string(id),
    beneficiary_steam_id : _beneficiary,
});
instance_destroy(self);
