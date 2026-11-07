extends "res://tests/test_case.gd"

## VIS-STORMWOOD (5 Nov 2026), F39#7: combat.json trainer_aside.realm_1104
## stands the Tidewake (realm `water`) trainer further aside in fights. Ships
## OFF; ON it changes only the water realm and only the lateral offset.

const COMBAT := preload("res://scripts/combat/combat_manager.gd")


func _aside() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json")).trainer_aside


func test_realm_aside_ships_off() -> void:
	var aside := _aside()
	assert_false(bool(aside.realm_1104.get("enabled", true)), "ships OFF until judged")
	assert_eq(COMBAT.trainer_aside_for(aside, "water"), aside, "OFF leaves the shared offsets")


func test_realm_aside_on_moves_only_the_water_trainer_further_aside() -> void:
	var aside := _aside()
	aside.realm_1104["enabled"] = true
	var water := COMBAT.trainer_aside_for(aside, "water")
	assert_true(float(water.side_m) > float(aside.side_m), "Tidewake trainer stands further aside")
	assert_eq(float(water.forward_m), float(aside.forward_m), "same depth")
	for realm: String in ["meadows", "sky", "storm", ""]:
		assert_eq(COMBAT.trainer_aside_for(aside, realm), aside, "%s unchanged" % realm)
