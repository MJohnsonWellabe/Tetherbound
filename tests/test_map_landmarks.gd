extends "res://tests/test_case.gd"

## data/config/map_landmarks.json, D33's map database file.
##
## Every failure this guards is silent at runtime: a duplicate id that makes
## `landmarks()` return two entries a UI cannot tell apart, a position that
## has drifted outside the ±256m playground and will never be walked to, a
## discover_radius of zero that can never actually trigger. None of these
## crash; they just leave a landmark the player can never see marked, or two
## landmarks silently colliding.

const LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const WORLD_HALF := 256.0

var _valid_categories: Array[String] = ["major", "minor"]


func _config() -> Dictionary:
	var file := FileAccess.open(LANDMARKS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _landmarks() -> Array:
	return _config().get("landmarks", []) as Array


func test_the_file_parses_as_an_object() -> void:
	assert_false(_config().is_empty(), "map_landmarks.json failed to parse or is empty")


func test_reveal_radius_is_a_sane_positive_distance() -> void:
	var radius := float(_config().get("reveal_radius", 0.0))
	assert_true(radius > 0.0, "reveal_radius must be positive or fog never clears")
	assert_true(radius < WORLD_HALF * 2.0,
		"reveal_radius of %.1f would reveal more than the whole playground in one step" % radius)


func test_minimap_span_is_a_sane_positive_distance() -> void:
	var span := float(_config().get("minimap_span_m", 0.0))
	assert_true(span > 0.0, "minimap_span_m must be positive or the minimap shows nothing")
	assert_true(span < WORLD_HALF * 2.0,
		"minimap_span_m of %.1f is wider than the whole playground" % span)


func test_the_table_is_not_empty() -> void:
	assert_false(_landmarks().is_empty(), "map_landmarks.json has no landmarks")


func test_every_landmark_has_a_unique_id() -> void:
	var seen: Array[String] = []
	for entry: Variant in _landmarks():
		var id := str((entry as Dictionary).get("id", ""))
		assert_false(id.is_empty(), "a landmark entry has no id")
		assert_false(seen.has(id), "id '%s' appears more than once" % id)
		seen.append(id)


func test_every_landmark_has_a_display_name_and_icon() -> void:
	for entry: Variant in _landmarks():
		var d := entry as Dictionary
		var id := str(d.get("id", "?"))
		assert_false(str(d.get("display_name", "")).is_empty(),
			"'%s' has no display_name" % id)
		assert_false(str(d.get("icon", "")).is_empty(),
			"'%s' has no icon" % id)


func test_every_position_is_a_2d_point_inside_the_playground() -> void:
	for entry: Variant in _landmarks():
		var d := entry as Dictionary
		var id := str(d.get("id", "?"))
		var pos: Variant = d.get("position", [])
		assert_true(pos is Array, "'%s' position is not an array" % id)
		if not (pos is Array):
			continue
		var arr := pos as Array
		assert_eq(arr.size(), 2, "'%s' position must be a 2-element [x, z] pair" % id)
		if arr.size() != 2:
			continue
		for axis in arr:
			assert_true(typeof(axis) == TYPE_FLOAT or typeof(axis) == TYPE_INT,
				"'%s' position has a non-numeric coordinate" % id)
		var x := float(arr[0])
		var z := float(arr[1])
		assert_true(absf(x) <= WORLD_HALF,
			"'%s' x=%.1f is outside the ±%.0fm playground" % [id, x, WORLD_HALF])
		assert_true(absf(z) <= WORLD_HALF,
			"'%s' z=%.1f is outside the ±%.0fm playground" % [id, z, WORLD_HALF])


func test_every_discover_radius_is_positive() -> void:
	for entry: Variant in _landmarks():
		var d := entry as Dictionary
		var id := str(d.get("id", "?"))
		var radius := float(d.get("discover_radius", 0.0))
		assert_true(radius > 0.0,
			"'%s' has discover_radius %.1f; it could never be auto-discovered" % [id, radius])


func test_every_category_is_recognised() -> void:
	for entry: Variant in _landmarks():
		var d := entry as Dictionary
		var id := str(d.get("id", "?"))
		var category := str(d.get("category", ""))
		assert_true(_valid_categories.has(category),
			"'%s' has category '%s', not one of %s" % [id, category, _valid_categories])
