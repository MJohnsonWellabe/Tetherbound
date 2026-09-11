extends "res://tests/test_case.gd"

const HARVEST_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/harvest.json"
const VEGETATION_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/vegetation.json"


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

	var vegetation: Variant = JSON.parse_string(FileAccess.get_file_as_string(VEGETATION_PATH))
	assert_true(vegetation is Dictionary, "Band 4 vegetation data did not parse")
	if not vegetation is Dictionary:
		return
	var identity_glade: Dictionary = {}
	for raw: Variant in (vegetation as Dictionary).get("clearings", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 4003:
			identity_glade = raw as Dictionary
			break
	assert_false(identity_glade.is_empty(), "Ironwood Grove lost its bounded identity glade")
	if identity_glade.is_empty():
		return
	assert_true(Vector2(float(identity_glade.get("x", 0.0)), float(identity_glade.get("z", 0.0))).distance_to(Vector2(-344.0, 5075.0)) <= 1.0,
		"Ironwood identity glade drifted off the authored crown cluster")
	assert_true(float(identity_glade.get("radius", 0.0)) >= 16.0 and float(identity_glade.get("radius", 0.0)) <= 20.0,
		"Ironwood identity glade no longer isolates the crown without stripping the corridor")
