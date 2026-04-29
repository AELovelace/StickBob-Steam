if variable_instance_exists(other.id, "isLocal") && !other.isLocal exit;

var _collectible_id = string(collectibleCode);
if string_length(_collectible_id) <= 0 {
	_collectible_id = room_get_name(room)
		+ ":" + string(round(x))
		+ ":" + string(round(y))
		+ ":" + string(sgcAmount);
}

sgc_gateway_report_collectible({
	amount         : sgcAmount,
	collectible_id : _collectible_id,
});

instance_destroy();
