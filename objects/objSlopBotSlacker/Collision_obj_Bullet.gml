if (isDying) {
    if (instance_exists(other)) instance_destroy(other);
    exit;
}

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

if (instance_exists(other)) instance_destroy(other);

playerHealth = max(0, playerHealth - 1);
if (playerHealth <= 0) {
    sgc_gateway_report_pve_kill({
        enemy_spawn_id : object_get_name(object_index) + ":" + string(id),
        beneficiary_steam_id : _beneficiary,
    });
    runner_add_kill();
    isDying = true;
    state = "dead";
    xSpeed = 0;
    ySpeed = 0;
    image_speed = 1;
    image_index = 0;
    sprite_index = sprPlayerDie;
}
