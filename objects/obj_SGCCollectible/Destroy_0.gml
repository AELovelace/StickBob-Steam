/// @description Notify peers when host destroys this collectible (pickup)
if (mp_is_host() && variable_instance_exists(id, "mp_id") && mp_id != 0) {
	mp_replicate_despawn(id, ENTITY_KIND.COLLECTIBLE)
}
