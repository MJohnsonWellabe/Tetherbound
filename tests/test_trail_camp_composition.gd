extends "res://tests/test_case.gd"

const SPAWNS_PATH := "res://data/config/bands/band1_lower_meadows/spawns.json"
const CAMP_EYE := Vector2(348.0, 919.5)
const CAMP_FIRE := Vector2(344.3, 936.6)


func test_camp_companions_flank_instead_of_blocking_the_named_location() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPAWNS_PATH))
	assert_true(parsed is Dictionary, "Band 1 spawns did not parse")
	if not parsed is Dictionary:
		return
	var found := 0
	for raw: Variant in (parsed as Dictionary).get("spawns", []):
		if not raw is Dictionary:
			continue
		var spawn := raw as Dictionary
		if int(spawn.get("order", -1)) not in [1073, 1074]:
			continue
		found += 1
		var centre_raw: Array = spawn.get("centre", [])
		assert_true(centre_raw.size() >= 3, "Trail Camp companion has no centre")
		if centre_raw.size() < 3:
			continue
		var centre := Vector2(float(centre_raw[0]), float(centre_raw[2]))
		var radius := float(spawn.get("radius", 0.0))
		assert_eq(int(spawn.get("count", 0)), 1,
			"Trail Camp companion cluster became a crowd again")
		assert_true(centre.distance_to(CAMP_FIRE) + radius <= 9.0,
			"Trail Camp companion fell outside the firelight story")
		assert_true(_distance_to_segment(centre, CAMP_EYE, CAMP_FIRE) - radius >= 5.0,
			"Trail Camp companion can block the route-to-fire hero sightline")
	assert_eq(found, 2, "Trail Camp lost one of its paired companion species")


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var along := finish - start
	var t := clampf((point - start).dot(along) / along.length_squared(), 0.0, 1.0)
	return point.distance_to(start + along * t)
