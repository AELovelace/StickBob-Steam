/// @description Set direction based on side
moveSpeed = 10
owner_id = 0;
owner_steam_id = 0;
collision_tilemap_id = layer_tilemap_get_id("CollisionLayer");
direction = x > room_width / 2 ? 180 : 0

image_xscale = x > room_width / 2 ? -image_xscale : image_xscale