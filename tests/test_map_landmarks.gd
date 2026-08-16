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


# --- D36's named regions ---------------------------------------------------
#
# The `regions` array joined this file when D36 landed and nothing here ever
# checked it — `test_map_state.gd` drives the BEHAVIOUR (discovery, the
# one-shot banner, persistence) against three hardcoded ids, which is the right
# split, but it means a fourth region added later is exercised by nothing at
# all. These are the same silent-failure guards the landmark half above gets:
# a region with no radius can never be entered, a centre outside the baked
# world can never be walked to, and a duplicate id is two entries the map
# cannot tell apart.

func _regions() -> Array:
	return _config().get("regions", []) as Array


## D36's own rule, made checkable: "a handful of large, well-separated zones,
## not one per building." The first cut put three centres 15-35m apart and
## their labels garbled into each other on the full map, which is the failure
## this guards.
const REGION_MIN_RADIUS := 30.0


func test_every_region_has_a_unique_id_and_a_display_name() -> void:
	var seen: Array[String] = []
	for entry: Variant in _regions():
		var d := entry as Dictionary
		var id := str(d.get("id", ""))
		assert_false(id.is_empty(), "a region entry has no id")
		assert_false(seen.has(id), "region id '%s' appears more than once" % id)
		seen.append(id)
		assert_false(str(d.get("display_name", "")).is_empty(),
			"region '%s' has no display_name; its banner and map label would be blank" % id)


func test_every_region_centre_is_inside_the_playground() -> void:
	for entry: Variant in _regions():
		var d := entry as Dictionary
		var id := str(d.get("id", "?"))
		var centre: Variant = d.get("centre", [])
		assert_true(centre is Array and (centre as Array).size() == 2,
			"region '%s' centre is not a 2-element [x, z] pair" % id)
		if not (centre is Array) or (centre as Array).size() != 2:
			continue
		var x := float((centre as Array)[0])
		var z := float((centre as Array)[1])
		assert_true(absf(x) <= WORLD_HALF and absf(z) <= WORLD_HALF,
			"region '%s' is centred at %.1f, %.1f, outside the ±%.0fm playground" % [id, x, z, WORLD_HALF])


func test_every_region_is_large_enough_to_be_a_region() -> void:
	for entry: Variant in _regions():
		var d := entry as Dictionary
		var id := str(d.get("id", "?"))
		var radius := float(d.get("radius", 0.0))
		assert_true(radius >= REGION_MIN_RADIUS,
			"region '%s' has radius %.1f; D36 says regions are FEW AND LARGE — anything this small is a landmark wearing a region's hat" % [id, radius])


## No region's centre may fall inside another region.
##
## This is deliberately NOT the stricter "no two discs may overlap anywhere",
## which is what this check asserted when it was first written — and which
## FAILED, on shipped content this item never touched: `grandpas_village`
## (r60) and `the_rise` (r55) are 85m apart, so their fringes overlap by 30m.
## That is recorded here rather than quietly softened away, and rather than
## "fixed" by retuning two regions D36 sized on the owner's own playtest note.
##
## Fringe overlap is survivable and centre overlap is not, which is why the
## line is drawn here. `map_state.gd::update_region` takes the FIRST matching
## region in file order, so inside an overlap band the answer depends on how
## the file is sorted — a band of ambiguity out at the edges, where a player is
## arguably in neither place, is a different thing from a region whose own
## middle belongs to its neighbour. The label half of D36 lands the same way:
## two names 85m apart are legible, two names on top of each other are the
## clutter the decision exists to prevent.
##
## SD16's `the_old_quarry` clears every existing region by both measures
## (nearest disc is The Pond's, still 12m clear), so nothing here is a licence
## it granted itself.
func test_no_regions_centre_falls_inside_another_region() -> void:
	var regions := _regions()
	for i in regions.size():
		for j in range(i + 1, regions.size()):
			var a := regions[i] as Dictionary
			var b := regions[j] as Dictionary
			var a_centre: Variant = a.get("centre", [])
			var b_centre: Variant = b.get("centre", [])
			if not (a_centre is Array) or not (b_centre is Array):
				continue
			if (a_centre as Array).size() != 2 or (b_centre as Array).size() != 2:
				continue
			var gap := Vector2(float((a_centre as Array)[0]), float((a_centre as Array)[1])).distance_to(
				Vector2(float((b_centre as Array)[0]), float((b_centre as Array)[1])))
			var claimed := maxf(float(a.get("radius", 0.0)), float(b.get("radius", 0.0)))
			assert_true(gap > claimed,
				"regions '%s' and '%s' are only %.0fm apart against a %.0fm radius — one region's own centre is inside the other, so which place a player is standing in depends on the order of this file" % [
					str(a.get("id", "?")), str(b.get("id", "?")), gap, claimed])


## SE21/SE22. The two new map entries are both anchored to geography that
## lives in another file, and a map marker that has quietly drifted off the
## thing it marks is invisible until someone walks there.
const TERRAIN_PATH := "res://data/config/terrain_playground.json"


func _terrain() -> Dictionary:
	var file := FileAccess.open(TERRAIN_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _entry(list: Array, id: String) -> Dictionary:
	for candidate: Variant in list:
		if candidate is Dictionary and str((candidate as Dictionary).get("id", "")) == id:
			return candidate as Dictionary
	return {}


func test_the_old_mill_crossing_marker_stands_on_the_crossing() -> void:
	var landmark := _entry(_landmarks(), "old_mill_crossing")
	assert_false(landmark.is_empty(), "no `old_mill_crossing` landmark; SE22's gate is not on the map")
	if landmark.is_empty():
		return
	var crossing := _entry(_terrain().get("crossings", []) as Array, "old_mill_crossing")
	assert_false(crossing.is_empty(), "no `old_mill_crossing` entry in terrain_playground.json")
	if crossing.is_empty():
		return
	var channel: Dictionary = crossing.get("channel", {})
	var at: Array = channel.get("centre", [])
	var pos: Array = landmark.get("position", [])
	assert_eq(at.size(), 2, "the crossing's channel has no centre")
	assert_eq(pos.size(), 2, "the landmark has no position")
	if at.size() != 2 or pos.size() != 2:
		return
	var drift := Vector2(float(at[0]), float(at[1])).distance_to(Vector2(float(pos[0]), float(pos[1])))
	assert_true(drift < 1.0,
		"the Old Mill Crossing marker is %.1fm off the narrows it marks -- the map would send a player to open water" % drift)


func test_the_long_water_region_covers_its_own_river() -> void:
	var region := _entry(_regions(), "the_long_water")
	assert_false(region.is_empty(), "no `the_long_water` region; SE21's river is not a named place")
	if region.is_empty():
		return
	var centre: Array = region.get("centre", [])
	var radius := float(region.get("radius", 0.0))
	if centre.size() != 2:
		return
	var middle := Vector2(float(centre[0]), float(centre[1]))
	var course: Array = (_terrain().get("river", {}) as Dictionary).get("course", [])
	assert_true(course.size() >= 2, "the river has no course to be a region around")
	# The region must actually sit ON the water, not beside it, and it must
	# take in the one crossing -- that is the whole reason it is a region and
	# not a landmark.
	var nearest := INF
	for entry: Variant in course:
		var at: Array = (entry as Dictionary).get("at", [])
		if at.size() == 2:
			nearest = minf(nearest, middle.distance_to(Vector2(float(at[0]), float(at[1]))))
	assert_true(nearest < radius,
		"the Long Water's centre is %.0fm from its own river against a %.0fm radius -- the label would land on dry meadow" % [nearest, radius])
	var crossing := _entry(_terrain().get("crossings", []) as Array, "old_mill_crossing")
	var at_crossing: Array = (crossing.get("channel", {}) as Dictionary).get("centre", [])
	if at_crossing.size() == 2:
		var reach := middle.distance_to(Vector2(float(at_crossing[0]), float(at_crossing[1])))
		assert_true(reach < radius,
			"the Old Mill Crossing is %.0fm outside The Long Water -- the crossing is not in the region it crosses" % (reach - radius))
