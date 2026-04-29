if (!variable_global_exists("gameParams") || !global.gameParams.practiceMode) {
    instance_destroy();
    exit;
}

if (instance_number(obj_SpawnPoint) <= 0) {
    exit;
}

if (!bootstrapped) {
    route_points = scr_practice_spawn_route_points();
    var _player = scr_practice_spawn_local_player(0);
    scr_practice_spawn_partner(route_points, _player);
    scr_practice_spawn_enemy_bots(route_points, _player);
    bootstrapped = true;
    exit;
}

var _player = noone;
if (instance_exists(obj_Player)) {
    _player = instance_find(obj_Player, 0);
}

if (_player == noone) {
    _player = scr_practice_spawn_local_player(0);
}

var _need_partner = !instance_exists(objSlopBotPartner);
var _need_enemies = (instance_number(objSlopBotPatrol) <= 0);

for (var _partner_i = 0; _partner_i < instance_number(objSlopBotPartner); _partner_i += 1) {
    var _partner = instance_find(objSlopBotPartner, _partner_i);
    if (_partner != noone) {
        _partner.player_target = _player;
    }
}

for (var _enemy_i = 0; _enemy_i < instance_number(objSlopBotPatrol); _enemy_i += 1) {
    var _enemy = instance_find(objSlopBotPatrol, _enemy_i);
    if (_enemy != noone) {
        _enemy.player_target = _player;
    }
}

if (_need_partner || _need_enemies) {
    if (respawn_cooldown <= 0) {
        respawn_cooldown = 90;
    } else {
        respawn_cooldown -= 1;
        if (respawn_cooldown <= 0) {
            if (_need_partner) {
                scr_practice_spawn_partner(route_points, _player);
            }
            if (_need_enemies) {
                scr_practice_spawn_enemy_bots(route_points, _player);
            }
        }
    }
} else {
    respawn_cooldown = 0;
}
