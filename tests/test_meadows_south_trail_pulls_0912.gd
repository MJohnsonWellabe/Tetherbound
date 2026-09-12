extends "res://tests/test_case.gd"

## Owner playtest 2026-09-12: the south dirt trail goes quiet before the
## first Trail Camp, and the Long Field offers no glowing, rewarded reason to
## leave it. These are source contracts for the authored correction. A full
## road walk and production capture still decide whether the groups and signal
## are actually visible through the live terrain and vegetation.

const SPAWNS_PATH := "res://data/config/bands/band1_lower_meadows/spawns.json"
const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const PICKUPS_PATH := "res://data/config/bands/band1_lower_meadows/pickups.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"

const SOUTH_TRAIL_ORDERS: Array[int] = [1913, 1914]
const WAYFARER_HERD_ORDER := 1915
const WAYFARER_SITE := Vector2(160.0, 710.0)


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s could not be opened" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _by_order() -> Dictionary:
	var out := {}
	for entry: Variant in (_read(SPAWNS_PATH).get("spawns", []) as Array):
		var spec := entry as Dictionary
		out[int(spec.get("order", -1))] = spec
	return out


func _cluster(name: String) -> Dictionary:
	for entry: Variant in (_read(PROPS_PATH).get("clusters", []) as Array):
		var spec := entry as Dictionary
		if str(spec.get("name", "")) == name:
			return spec
	return {}


func _pickup(id: String) -> Dictionary:
	for entry: Variant in (_read(PICKUPS_PATH).get("pickups", []) as Array):
		var spec := entry as Dictionary
		if str(spec.get("id", "")) == id:
			return spec
	return {}


func _point(raw: Variant) -> Vector2:
	var values := raw as Array
	return Vector2(float(values[0]), float(values[1]))


func _spawn_point(spec: Dictionary) -> Vector2:
	var values := spec.get("centre", []) as Array
	return Vector2(float(values[0]), float(values[2]))


func _lower_meadows_spine() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var trail := _read(TERRAIN_PATH).get("trail", {}) as Dictionary
	for entry: Variant in (trail.get("bands", []) as Array):
		var band := entry as Dictionary
		if str(band.get("id", "")) != "band1_lower_meadows":
			continue
		for raw: Variant in (band.get("points", []) as Array):
			out.append(_point(raw))
	return out


func _distance_to_spine(point: Vector2) -> float:
	var points := _lower_meadows_spine()
	var nearest := INF
	for index in range(points.size() - 1):
		var a := points[index]
		var b := points[index + 1]
		var ab := b - a
		var t := clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * t))
	return nearest


func test_pre_camp_sightline_groups_are_fixed_peaceful_shoulders() -> void:
	var spawns := _by_order()
	for order in SOUTH_TRAIL_ORDERS:
		assert_true(spawns.has(order), "south-trail sightline cluster %d is missing" % order)
		if not spawns.has(order):
			continue
		var spec := spawns[order] as Dictionary
		assert_true(["trailpup", "bramblebun"].has(str(spec.get("species", ""))),
			"the pre-camp visibility fix must stay a peaceful Lower Meadows species")
		assert_true(int(spec.get("count", 0)) >= 3,
			"a lone body is not the creature-group cadence the owner asked for")
		assert_true(float(spec.get("radius", INF)) <= 3.0,
			"the fixed sightline group can scatter out of the road picture")
		assert_eq(str(spec.get("habitat", "")), "roadside_sightline")
		for gate in ["table", "time", "weather", "wander_radius"]:
			assert_false(spec.has(gate),
				"cluster %d carries '%s', which can remove it from the authored sightline" % [order, gate])
		assert_true(_distance_to_spine(_spawn_point(spec)) <= 14.0,
			"cluster %d is not on the south-trail shoulder" % order)


func test_wayfarer_signal_is_one_restrained_off_path_practical() -> void:
	var signal_cluster := _cluster("long_field_wayfarer_signal")
	assert_false(signal_cluster.is_empty(), "the Long Field wayfarer signal is missing")
	assert_false(signal_cluster.has("rest"), "the small signal must not promise a second usable camp")
	var props := signal_cluster.get("props", []) as Array
	assert_eq(props.size(), 5, "the peripheral pull must stay a small five-piece vignette")
	var glow_count := 0
	var fire_count := 0
	for entry: Variant in props:
		var spec := entry as Dictionary
		if str(spec.get("glow", "")) != "":
			glow_count += 1
		if str(spec.get("name", "")) == "WayfarerSignalFire":
			fire_count += 1
			assert_true(_point(spec.get("at", [])).distance_to(WAYFARER_SITE) < 0.1)
	assert_eq(fire_count, 1, "the signal needs exactly one authored fire")
	assert_eq(glow_count, 1, "the restrained site must add exactly one practical glow")
	assert_true(_distance_to_spine(WAYFARER_SITE) >= 60.0,
		"the wayfarer signal is no longer a deliberate off-path discovery")


func test_the_signal_pays_the_detour_and_has_a_distinct_living_subject() -> void:
	var candy := _pickup("b1_candy_wayfarer_signal")
	var potion := _pickup("b1_potion_wayfarer_signal")
	assert_false(candy.is_empty(), "the wayfarer signal's Great Candy is missing")
	assert_false(potion.is_empty(), "the wayfarer signal's potion is missing")
	assert_eq(str(candy.get("item", "")), "great_candy")
	assert_eq(str(candy.get("tier", "")), "detour")
	assert_eq(str(potion.get("item", "")), "potion_small")
	assert_eq(str(potion.get("tier", "")), "detour")
	var candy_at := _point(candy.get("pos", []))
	var potion_at := _point(potion.get("pos", []))
	assert_true(candy_at.distance_to(WAYFARER_SITE) <= 7.0)
	assert_true(potion_at.distance_to(WAYFARER_SITE) <= 7.0)
	assert_true(candy_at.distance_to(potion_at) >= 4.5,
		"the two pickup prompts contest one another")

	var herd := _by_order().get(WAYFARER_HERD_ORDER, {}) as Dictionary
	assert_false(herd.is_empty(), "the wayfarer signal has no creature subject")
	assert_eq(str(herd.get("species", "")), "meadowhart")
	assert_eq(int(herd.get("count", 0)), 3)
	assert_true(_spawn_point(herd).distance_to(WAYFARER_SITE) <= 20.0)
	assert_true(_distance_to_spine(_spawn_point(herd)) >= 60.0,
		"the discovery herd has drifted back onto the main trail")
	for gate in ["table", "time", "weather"]:
		assert_false(herd.has(gate),
			"the authored discovery herd can disappear because it carries '%s'" % gate)
