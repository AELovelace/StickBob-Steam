if (isDying) {
    if (instance_exists(other)) instance_destroy(other);
    exit;
}

if (instance_exists(other)) instance_destroy(other);

playerHealth = max(0, playerHealth - 1);
if (playerHealth <= 0) {
    isDying = true;
    xSpeed = 0;
    ySpeed = 0;
    image_speed = 1;
    image_index = 0;
    sprite_index = sprPlayerDie;
}
