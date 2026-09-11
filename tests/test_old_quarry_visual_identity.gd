extends "res://tests/test_case.gd"

const VEGETATION_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"


func _config() -> Dictionary:
	var file := FileAccess.open(VEGETATION_PATH, FileAccess.READ)
	assert_true(file != null, "cannot open Old Quarry vegetation config")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "Old Quarry vegetation config is invalid JSON")
	return parsed as Dictionary if parsed is Dictionary else {}


func test_the_worked_floor_and_final_approach_share_a_cleared_sightline() -> void:
	var clearings: Variant = _config().get("clearings", [])
	assert_true(clearings is Array, "Band 2 clearings are missing")
	if not clearings is Array:
		return
	var quarry: Dictionary = {}
	var approach: Dictionary = {}
	for raw: Variant in clearings as Array:
		if not raw is Dictionary:
			continue
		var entry := raw as Dictionary
		if int(entry.get("order", -1)) == 8:
			quarry = entry
		elif int(entry.get("order", -1)) == 2003:
			approach = entry
	assert_true(not quarry.is_empty(), "the Old Quarry worked-floor clearing is missing")
	assert_true(not approach.is_empty(), "the Old Quarry final approach is still closed by mature scatter")
	if quarry.is_empty() or approach.is_empty():
		return
	var quarry_at := Vector2(float(quarry.get("x", 0.0)), float(quarry.get("z", 0.0)))
	var approach_at := Vector2(float(approach.get("x", 0.0)), float(approach.get("z", 0.0)))
	var combined_reach := float(quarry.get("radius", 0.0)) + float(approach.get("radius", 0.0))
	assert_true(quarry_at.distance_to(approach_at) < combined_reach,
		"quarry and approach clearings do not overlap; the sightline still has a tree wall between them")
	assert_true(float(approach.get("radius", 0.0)) <= 12.0,
		"quarry approach clearing is broader than the bounded final-road lens")
