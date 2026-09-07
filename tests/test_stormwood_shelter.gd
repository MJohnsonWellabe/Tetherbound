extends "res://tests/test_case.gd"

const SHELTER := preload("res://scripts/world/stormwood_shelter.gd")

func test_canopy_uses_scaled_live_placements_and_stops_after_chopping() -> void:
	var placements := [{"position": Vector3(100, 10, 200), "scale": 3.0}]
	var batches := [{"model": "res://assets/environment/stylized_nature/TwistedTree_2.gltf", "placements": placements}]
	assert_true(SHELTER.under_canopy(Vector3(120, 10, 200), batches))
	assert_false(SHELTER.under_canopy(Vector3(122, 10, 200), batches))
	assert_false(SHELTER.under_canopy(Vector3(100, 70, 200), batches), "above the leaves is exposed")
	placements.clear()
	assert_false(SHELTER.under_canopy(Vector3(100, 10, 200), batches), "chopped canopy cannot keep sheltering")

func test_deadwood_and_rocks_do_not_claim_leaf_shelter() -> void:
	var rows := [{"model": "DeadTree_3.gltf", "placements": [{"position": Vector3.ZERO, "scale": 10.0}]}]
	assert_false(SHELTER.under_canopy(Vector3.ZERO, rows))
