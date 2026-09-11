extends "res://tests/test_case.gd"

## Contract for The Highfield's south-to-north hero read: Meadowhart herd and
## bull, then the open drove gate beside a compact occupied stock camp. The
## existing encounters and functional rest camp remain where gameplay authored
## them; this test pins the visual composition around the named location.

const PROPS_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/props.json"
const SPAWNS_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/spawns.json"
const VEGETATION_PATH := "res://data/config/bands/band4_upper_meadows_ironwood/vegetation.json"
const GLOBAL_VEGETATION_PATH := "res://data/config/vegetation.json"
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const HERO_CAMP := "highfield_drove_camp_hero"
const DROVE_GATE := "highfield_drove_gate"
const HIGHFIELD := Vector2(400.0, 5900.0)


func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _cluster_named(wanted: String) -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == wanted:
			return cluster
	return {}


func _spawn_order(wanted: int) -> Dictionary:
	for raw: Variant in _read_json(SPAWNS_PATH).get("spawns", []):
		var spawn := raw as Dictionary
		if int(spawn.get("order", -1)) == wanted:
			return spawn
	return {}


func _band4_spine() -> PackedVector2Array:
	var trail := _read_json(TERRAIN_PATH).get("trail", {}) as Dictionary
	var line := PackedVector2Array()
	for raw: Variant in trail.get("bands", []):
		var band := raw as Dictionary
		if str(band.get("id", "")) != "band4_upper_meadows_ironwood":
			continue
		for point: Variant in band.get("points", []):
			line.append(Vector2(float(point[0]), float(point[1])))
	return line


func _distance_to_polyline(point: Vector2, line: PackedVector2Array) -> float:
	var nearest := INF
	for index in line.size() - 1:
		var a := line[index]
		var b := line[index + 1]
		var ab := b - a
		var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * t))
	return nearest


func _asset_exists(prop: Dictionary) -> bool:
	var dir := str(prop.get("dir", "res://assets/props/quaternius_fantasy"))
	var model := str(prop.get("model", ""))
	for extension in ["gltf", "glb", "obj"]:
		if ResourceLoader.exists("%s/%s.%s" % [dir, model, extension]):
			return true
	return false


func test_hero_camp_is_a_complete_stock_story_inside_the_named_highfield() -> void:
	var camp := _cluster_named(HERO_CAMP)
	assert_false(camp.is_empty(), "Highfield has no visual stock-camp endpoint")
	assert_eq(int(camp.get("order", -1)), 4006, "hero camp uses Band 4's reserved order range")
	var models := {}
	var names := {}
	for raw: Variant in camp.get("props", []):
		var prop := raw as Dictionary
		models[str(prop.get("model", ""))] = true
		names[str(prop.get("name", ""))] = prop
		assert_true(_asset_exists(prop), "%s resolves to an installed production asset" % str(prop.get("name", "prop")))
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(at.distance_to(HIGHFIELD) <= 28.0, "%s stays inside the named hero composition" % str(prop.get("name", "prop")))
	assert_true(models.has("camp_tent"), "stock camp has no seasonal shelter")
	assert_true(models.has("Bonfire_Fire"), "stock camp has no night landmark")
	assert_true(models.has("FarmCrate_Apple"), "stock camp reads generic rather than as a feeding station")
	var fire := names.get("HighfieldHeroFire", {}) as Dictionary
	assert_eq(str(fire.get("glow", "")), "campfire", "the camp fire uses the shared warm treatment")
	assert_true(float(fire.get("glow_scale", 0.0)) >= 1.25, "night occupation remains readable beyond arm's length")
	assert_false(JSON.stringify(camp).contains("#7a2430"), "friendly Highfield camp leaked Team Tether oxblood")


func test_herd_gate_and_camp_form_one_compact_south_to_north_read() -> void:
	var ordinary := _spawn_order(4064)
	var bull := _spawn_order(4101)
	var ordinary_at := ordinary.get("centre", []) as Array
	var bull_at := bull.get("centre", []) as Array
	assert_almost_eq(float(ordinary_at[0]), 377.5, 0.01, "ordinary Meadowhart herd x was not moved for composition")
	assert_almost_eq(float(ordinary_at[2]), 5855.3, 0.01, "ordinary Meadowhart herd z was not moved for composition")
	assert_almost_eq(float(bull_at[0]), 425.0, 0.01, "Highfield bull x was not moved for composition")
	assert_almost_eq(float(bull_at[2]), 5844.0, 0.01, "Highfield bull z was not moved for composition")
	assert_eq(str(ordinary.get("species", "")), "meadowhart", "ordinary foreground remains the riding herd")
	assert_eq(str(bull.get("species", "")), "meadowhart", "bull foreground remains the riding temptation")
	assert_true(Vector2(377.5, 5855.3).x < HIGHFIELD.x and Vector2(425.0, 5844.0).x > HIGHFIELD.x,
		"the two herd reads no longer bracket the hero axis")
	assert_false(_cluster_named(DROVE_GATE).is_empty(), "the open drove gate remains the middle plane")
	var gate := _cluster_named(DROVE_GATE)
	var wagon := {}
	for raw: Variant in gate.get("props", []):
		var prop := raw as Dictionary
		if str(prop.get("name", "")) == "HighfieldDroverWagon":
			wagon = prop
	assert_false(wagon.is_empty(), "drove gate lost its readable working-stock silhouette")
	assert_false(JSON.stringify(gate).contains("#7a2430"), "friendly Highfield threshold leaked Team Tether oxblood")
	assert_false(JSON.stringify(gate).contains("HighfieldGatePennant"),
		"failed arrow-like R2 pennants returned to the rural threshold")
	var wagon_at := wagon.get("at", []) as Array
	assert_true(float(wagon_at[0]) > 407.5 and float(wagon_at[1]) < 5897.5,
		"wagon no longer bridges the east gate wing to the south-side visual camp")
	assert_true(float(wagon.get("scale", 0.0)) >= 1.3, "wagon is too small to carry the Highfield's day read")
	var camp_centre := Vector2(417.2, 5891.8)
	assert_true(camp_centre.distance_to(HIGHFIELD) < 24.0, "visual stock camp drifted away from the gate")
	assert_true(camp_centre.x > HIGHFIELD.x and absf(camp_centre.y - HIGHFIELD.y) < 12.0,
		"stock camp no longer sits beside the open gate's east wing")


func test_visual_camp_preserves_the_spine_and_encounter_space() -> void:
	var spine := _band4_spine()
	assert_true(spine.size() >= 2, "production Band 4 spine is missing")
	for raw: Variant in _cluster_named(HERO_CAMP).get("props", []):
		var prop := raw as Dictionary
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(_distance_to_polyline(at, spine) >= 8.0,
			"%s crowds the production route" % str(prop.get("name", "prop")))
		assert_true(at.distance_to(Vector2(377.5, 5855.3)) >= 35.0,
			"%s crowds the ordinary herd ring" % str(prop.get("name", "prop")))
		assert_true(at.distance_to(Vector2(425.0, 5844.0)) >= 35.0,
			"%s crowds the bull encounter" % str(prop.get("name", "prop")))


func test_shelter_and_working_kit_are_composed_as_one_readable_group() -> void:
	var named := {}
	for raw: Variant in _cluster_named(HERO_CAMP).get("props", []):
		var prop := raw as Dictionary
		named[str(prop.get("name", ""))] = prop
	var tent := named.get("HighfieldHeroTent", {}) as Dictionary
	var fire := named.get("HighfieldHeroFire", {}) as Dictionary
	var feed := named.get("HighfieldHeroFeed", {}) as Dictionary
	assert_true(float(tent.get("scale", 0.0)) >= 1.4, "seasonal shelter still dissolves into the pasture")
	var tent_at_raw := tent.get("at", []) as Array
	var fire_at_raw := fire.get("at", []) as Array
	var feed_at_raw := feed.get("at", []) as Array
	var tent_at := Vector2(float(tent_at_raw[0]), float(tent_at_raw[1]))
	var fire_at := Vector2(float(fire_at_raw[0]), float(fire_at_raw[1]))
	var feed_at := Vector2(float(feed_at_raw[0]), float(feed_at_raw[1]))
	assert_true(tent_at.distance_to(fire_at) <= 5.0, "tent and fire split into separate pasture dots")
	assert_true(feed_at.distance_to(fire_at) <= 3.5, "fodder no longer connects the camp to the herd story")
	assert_true(tent_at.y > fire_at.y, "shelter should backstop the fire from the southern hero approach")


func test_hero_camp_has_one_scoped_canopy_clearing() -> void:
	var found := false
	for raw: Variant in _read_json(VEGETATION_PATH).get("clearings", []):
		var clearing := raw as Dictionary
		if int(clearing.get("order", -1)) != 4004:
			continue
		found = true
		assert_almost_eq(float(clearing.get("x", INF)), 420.0, 0.01, "clearing follows the hero camp")
		assert_almost_eq(float(clearing.get("z", INF)), 5891.0, 0.01, "clearing follows the hero camp")
		assert_true(float(clearing.get("radius", INF)) <= 12.0, "Highfield composition did not bald the pasture")
	assert_true(found, "visual camp can be randomly buried by canopy scatter")
	var region := {}
	for raw: Variant in _read_json(LANDMARKS_PATH).get("regions", []):
		if str((raw as Dictionary).get("id", "")) == "the_highfield":
			region = raw
	assert_eq(str(region.get("display_name", "")), "The Highfield", "canonical named-place identity changed")


func test_highfield_sightline_lens_has_a_bounded_footprint_and_preserves_ground_cover() -> void:
	var band_vegetation := _read_json(VEGETATION_PATH)
	var lens := {}
	var camp_clearing := {}
	for raw: Variant in band_vegetation.get("clearings", []):
		var clearing := raw as Dictionary
		if int(clearing.get("order", -1)) == 4005:
			lens = clearing
		elif int(clearing.get("order", -1)) == 4004:
			camp_clearing = clearing
	assert_false(lens.is_empty(), "fresh Highfield tree wall has no served canopy/trunk lens")
	assert_false(camp_clearing.is_empty(), "Highfield visual camp lost its local clearing")
	var centre := Vector2(float(lens.get("x", INF)), float(lens.get("z", INF)))
	var radius := float(lens.get("radius", INF))
	assert_eq(centre, Vector2(407.0, 5877.0), "Highfield lens drifted off the herd-to-gate middle plane")
	assert_eq(radius, 25.0, "Highfield lens expanded beyond the measured tree wall")
	var camp_centre := Vector2(float(camp_clearing.get("x", INF)), float(camp_clearing.get("z", INF)))
	var camp_radius := float(camp_clearing.get("radius", 0.0))
	var radial_overlap := radius + camp_radius - centre.distance_to(camp_centre)
	assert_almost_eq(radial_overlap, 17.895, 0.002,
		"lens no longer overlaps the camp clearing as one continuous sightline")
	assert_true(centre.distance_to(Vector2(377.5, 5855.3)) - radius >= 11.5,
		"lens strips the ordinary Meadowhart herd ground instead of the middle-plane tree wall")
	assert_true(centre.distance_to(Vector2(425.0, 5844.0)) - radius >= 12.5,
		"lens strips the bull encounter ground instead of the middle-plane tree wall")
	for raw: Variant in band_vegetation.get("footprints", []):
		var footprint := raw as Dictionary
		var footprint_centre := Vector2(float(footprint.get("x", INF)), float(footprint.get("z", INF)))
		assert_true(footprint_centre.distance_to(HIGHFIELD) > 60.0,
			"Highfield lens became a ground-cover footprint and balded the pasture")

	var layers := _read_json(GLOBAL_VEGETATION_PATH).get("layers", {}) as Dictionary
	for layer_name: String in ["grass", "drygrass", "flowers", "path_stones"]:
		var layer := layers.get(layer_name, {}) as Dictionary
		assert_false(layer.is_empty(), "%s ground-cover layer is missing" % layer_name)
		assert_false(bool(layer.get("cleared_by_clearings", true)),
			"%s no longer survives authored canopy clearings" % layer_name)
	for blocking_name: String in ["trees", "rocks", "bushes", "saplings"]:
		var blocking_layer := layers.get(blocking_name, {}) as Dictionary
		assert_false(blocking_layer.is_empty(), "%s blocking layer is missing" % blocking_name)
		assert_true(bool(blocking_layer.get("cleared_by_clearings", true)),
			"Highfield lens cannot remove the %s wall" % blocking_name)
