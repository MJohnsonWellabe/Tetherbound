extends "res://tests/test_case.gd"

const VEGETATION_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const SPAWNS_PATH := "res://data/config/bands/band2_stone_and_root/spawns.json"
const QUARRY := Vector2(400.0, 1800.0)
const CAMERA_CORRIDORS := [
	[Vector2(380.0, 1820.0), Vector2(400.0, 1800.0)],
	[Vector2(400.0, 1803.0), Vector2(418.0, 1764.0)],
	[Vector2(392.0, 1812.0), Vector2(404.0, 1804.0)],
]


func _config() -> Dictionary:
	var file := FileAccess.open(VEGETATION_PATH, FileAccess.READ)
	assert_true(file != null, "cannot open Old Quarry vegetation config")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "Old Quarry vegetation config is invalid JSON")
	return parsed as Dictionary if parsed is Dictionary else {}


func _spawn_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPAWNS_PATH))
	assert_true(parsed is Dictionary, "Old Quarry spawn config is invalid JSON")
	return parsed as Dictionary if parsed is Dictionary else {}


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


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


func test_the_roadside_burrowback_pair_stays_near_quarry_but_clears_hero_sightlines() -> void:
	var pair: Dictionary = {}
	for raw: Variant in _spawn_config().get("spawns", []):
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == 2912:
			pair = raw as Dictionary
			break
	assert_false(pair.is_empty(), "authored Old Quarry roadside pair is missing")
	if pair.is_empty():
		return
	assert_eq(str(pair.get("species", "")), "burrowback")
	assert_eq(str(pair.get("habitat", "")), "roadside_sightline")
	assert_eq(int(pair.get("count", 0)), 2, "sightline fix must not delete a roadside member")
	var raw_centre: Array = pair.get("centre", [])
	assert_eq(raw_centre.size(), 3)
	if raw_centre.size() != 3:
		return
	var centre := Vector2(float(raw_centre[0]), float(raw_centre[2]))
	var radius := float(pair.get("radius", 0.0))
	assert_true(centre.distance_to(QUARRY) <= 45.0,
		"roadside pair was hidden too far from the named quarry instead of composed beside it")
	# The authored disc is not the whole live footprint: default idle wander is
	# 7m and a post-scale Burrowback needs a conservative 1.6m body allowance.
	var occupied_reach := radius + 7.0 + 1.6
	for corridor: Array in CAMERA_CORRIDORS:
		assert_true(_distance_to_segment(centre, corridor[0], corridor[1]) >= occupied_reach,
			"roadside pair's spawn/wander reach still intersects an Old Quarry hero corridor")
