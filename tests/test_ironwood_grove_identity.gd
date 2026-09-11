extends "res://tests/test_case.gd"

const HARVEST_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/harvest.json"


func test_named_ironwood_grove_has_a_varied_old_growth_canopy() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HARVEST_PATH))
	assert_true(parsed is Dictionary, "Band 4 harvest data did not parse")
	if not parsed is Dictionary:
		return
	var scales: Array[float] = []
	var positions: Array[Vector2] = []
	for raw: Variant in (parsed as Dictionary).get("nodes", []):
		if not raw is Dictionary:
			continue
		var node := raw as Dictionary
		var order := int(node.get("order", -1))
		if order < 4000 or order > 4004:
			continue
		scales.append(float(node.get("model_scale", 0.0)))
		var at: Array = node.get("at", [])
		if at.size() >= 2:
			positions.append(Vector2(float(at[0]), float(at[1])))
	assert_eq(scales.size(), 5, "the named grove lost one of its five ironwoods")
	if scales.size() != 5:
		return
	var mature := scales.filter(func(value: float) -> bool: return value >= 0.60)
	assert_true(mature.size() >= 3,
		"Ironwood Grove no longer has a three-crown old-growth mass")
	assert_true(scales.min() <= 0.40 and scales.max() >= 0.80,
		"Ironwood Grove lost its young-to-elder scale story")
	for point in positions:
		assert_true(point.distance_to(Vector2(-345.0, 5060.0)) <= 32.0,
			"an authored grove tree drifted out of the named composition")
