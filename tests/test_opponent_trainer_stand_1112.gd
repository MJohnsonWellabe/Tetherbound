extends "res://tests/test_case.gd"

## combat.json arena.opponent_trainer_stand_1112 (LANE-THINGS, 12 Nov 2026;
## F38#3): the opposing trainer stands behind their own creature for a fight.

const COMBAT := preload("res://scripts/combat/combat_manager.gd")


func test_spot_is_behind_and_to_one_side_of_the_opposing_creature() -> void:
	var cfg := {"behind_m": 3.0, "side_m": 1.6}
	var wild := Vector3(10, 2, 5)
	var forward := Vector3(0, 0, 1)
	var spot: Vector3 = COMBAT.opponent_trainer_stand_spot(cfg, wild, forward)
	assert_almost_eq(spot.z - wild.z, 3.0, 0.001, "behind the creature along the fight's heading")
	assert_almost_eq(absf(spot.x - wild.x), 1.6, 0.001, "and to one side of it")
	assert_almost_eq(spot.y, wild.y, 0.001, "height is re-read from the ground by the caller")


func test_flag_is_declared_with_its_scope() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json"))
	var block: Dictionary = (doc.get("arena", {}) as Dictionary).get("opponent_trainer_stand_1112", {})
	assert_true(block.has("enabled"), "flag declared")
	assert_eq(str(block.get("scope", "")), "client_presentation")
