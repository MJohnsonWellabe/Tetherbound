extends "res://tests/test_case.gd"

## F40#17 `rim_pickup_seat_1114` (LANE-LAND-CS): OFF until judged. On, it is the
## first override read, and only the stamina find moves (back from the lip).


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_physical_runtime.json"))


func test_ships_off_and_moves_only_the_stamina_find() -> void:
	var cfg := _cfg()
	var block: Dictionary = cfg.rim_pickup_seat_1114
	assert_false(bool(block.get("enabled", true)), "rim_pickup_seat_1114 ships OFF until judged")
	assert_eq((block.pickup_overrides as Dictionary).keys(), ["cr_recovery_high_roost_flight_stamina_01"], "only the stamina find moves")
	var seat: Array = block.pickup_overrides.cr_recovery_high_roost_flight_stamina_01
	var old: Array = cfg.rim_pickup_cluster.pickup_overrides.cr_recovery_high_roost_flight_stamina_01
	var centre := Vector2(900.0, 2700.0)
	assert_true(Vector2(float(seat[0]), float(seat[2])).distance_to(centre) < Vector2(float(old[0]), float(old[2])).distance_to(centre) - 0.8,
		"the stamina find sits closer to the crown centre than on the rim")


func test_seat_is_read_before_the_shipped_cluster() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_physical_runtime.gd")
	assert_true(source.contains('["rim_pickup_seat_1114", "rim_pickup_cluster", "rim_pickup_in_view", "rim_pickup_inset"]'), "the seat flag wins when on")
