extends "res://tests/test_case.gd"

## Focused contract for The Rise's production-visible hero composition.
## The destination used to be a terrain mound plus a fingerpost; these checks
## keep the authored tree-and-stone crown tied to the canonical region and out
## of both roads that meet at its foot.

const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const HERO_NAME := "the_rise_rock_crown"


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _rise_region() -> Dictionary:
	for raw: Variant in _read_json(LANDMARKS_PATH).get("regions", []):
		var region := raw as Dictionary
		if str(region.get("id", "")) == "the_rise":
			return region
	return {}


func _hero_cluster() -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == HERO_NAME:
			return cluster
	return {}


func _route_named(label: String, key: String = "routes") -> PackedVector2Array:
	var paths := _read_json(TERRAIN_PATH).get("paths", {}) as Dictionary
	for raw: Variant in paths.get(key, []):
		var route := raw as Dictionary
		if str(route.get("label", "")) != label:
			continue
		var result := PackedVector2Array()
		for point: Variant in route.get("points", []):
			result.append(Vector2(float(point[0]), float(point[1])))
		return result
	return PackedVector2Array()


func _distance_to_polyline(point: Vector2, line: PackedVector2Array) -> float:
	var nearest := INF
	for index in line.size() - 1:
		var a := line[index]
		var b := line[index + 1]
		var ab := b - a
		var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * t))
	return nearest


func test_the_rise_keeps_one_distinctive_authored_hero() -> void:
	var cluster := _hero_cluster()
	assert_false(cluster.is_empty(), "The Rise has no authored hero cluster")
	assert_eq(int(cluster.get("order", -1)), 1052, "The Rise hero keeps its band-reserved identity")
	var props := cluster.get("props", []) as Array
	assert_eq(props.size(), 4, "one hero tree and three asymmetrical crown stones")
	var hero_count := 0
	var rock_models := {}
	for raw: Variant in props:
		var prop := raw as Dictionary
		var dir := str(prop.get("dir", ""))
		var model := str(prop.get("model", ""))
		assert_true(ResourceLoader.exists("%s/%s.gltf" % [dir, model]), "%s is an installed production asset" % model)
		if str(prop.get("name", "")) == "RiseHeroTree":
			hero_count += 1
			assert_eq(model, "TwistedTree_3", "the hero keeps its wind-shaped silhouette")
			assert_true(float(prop.get("scale", 0.0)) >= 1.6, "the hero stays readable behind a trainer")
			var leaf := (prop.get("retint", {}) as Dictionary).get("Leaves_TwistedTree", {}) as Dictionary
			assert_eq(str(leaf.get("color", "")), "#e2e4ac", "the controlled warm modulation stays authored")
			assert_eq(str(leaf.get("texture", "")),
				"res://assets/environment/stylized_nature/Leaves_NormalTree_C.png",
				"crimson source leaves are swapped to the Meadows' green leaf sheet")
		elif model.begins_with("Rock_Medium_"):
			rock_models[model] = true
			assert_true(prop.has("scale_xyz"), "%s keeps a deliberately shaped stone fin" % model)
			var scale_raw := prop.get("scale_xyz", []) as Array
			assert_eq(scale_raw.size(), 3, "%s keeps a complete non-uniform scale" % model)
			if scale_raw.size() == 3:
				assert_true(float(scale_raw[0]) <= 1.3 and float(scale_raw[1]) <= 1.6 \
						and float(scale_raw[2]) <= 1.15,
					"%s has regrown into a road-end boulder wall" % model)
	assert_eq(hero_count, 1, "The Rise has one hero tree, not a grove")
	assert_eq(rock_models.size(), 3, "the crown uses three distinct rock silhouettes")


func test_crown_stones_frame_the_tree_instead_of_hiding_it_from_the_road_end() -> void:
	var props := _hero_cluster().get("props", []) as Array
	var hero_at := Vector2.INF
	var rock_positions := PackedVector2Array()
	for raw: Variant in props:
		var prop := raw as Dictionary
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		if str(prop.get("name", "")) == "RiseHeroTree":
			hero_at = at
		elif str(prop.get("model", "")).begins_with("Rock_Medium_"):
			rock_positions.append(at)
	assert_true(hero_at != Vector2.INF, "The Rise hero tree has no authored position")
	assert_eq(rock_positions.size(), 3, "the crown still uses exactly three framing stones")
	var road_end := Vector2(74.0, -41.0)
	for rock_at: Vector2 in rock_positions:
		assert_true(rock_at.distance_to(road_end) >= 23.0,
			"a crown stone has slipped back into the road-end foreground")
		assert_true(rock_at.distance_to(hero_at) <= 8.0,
			"a crown stone no longer reads as part of the tree composition")


func test_every_hero_piece_stays_inside_the_named_region_and_off_both_roads() -> void:
	var region := _rise_region()
	assert_false(region.is_empty(), "map_landmarks.json still publishes The Rise")
	assert_eq(str(region.get("display_name", "")), "The Rise", "player-visible naming stays canonical")
	var centre_raw := region.get("centre", []) as Array
	var centre := Vector2(float(centre_raw[0]), float(centre_raw[1]))
	var radius := float(region.get("radius", 0.0))
	var rise_road := _route_named("The Rise")
	var stronghold_road := _route_named("The Stronghold", "approaches")
	assert_true(rise_road.size() >= 2, "the authored The Rise road still exists")
	assert_true(stronghold_road.size() >= 2, "the Stronghold approach still leaves the same road end")
	for raw: Variant in (_hero_cluster().get("props", []) as Array):
		var prop := raw as Dictionary
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(at.distance_to(centre) < radius, "%s remains inside The Rise region" % str(prop.get("name", "prop")))
		assert_true(_distance_to_polyline(at, rise_road) >= 18.0, "%s stays out of the village road" % str(prop.get("name", "prop")))
		assert_true(_distance_to_polyline(at, stronghold_road) >= 18.0, "%s stays out of the Stronghold approach" % str(prop.get("name", "prop")))


func test_scatter_clearing_is_scoped_to_the_hero_composition() -> void:
	var found := false
	var sightline_found := false
	for raw: Variant in _read_json(VEGETATION_PATH).get("clearings", []):
		var clearing := raw as Dictionary
		if int(clearing.get("order", -1)) == 1915:
			sightline_found = true
			var sightline_centre := Vector2(float(clearing.get("x", INF)),
				float(clearing.get("z", INF)))
			assert_true(sightline_centre.distance_to(Vector2(87.0, -48.0)) <= 0.1,
				"the road-end lens left the actual hero sightline")
			assert_true(float(clearing.get("radius", 0.0)) <= 8.5,
				"the road-end lens balds the broader Rise")
		if int(clearing.get("order", -1)) != 1911:
			continue
		found = true
		var centre := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
		assert_true(centre.distance_to(Vector2(99.0, -53.0)) <= 0.1, "the clearing follows the hero crown")
		assert_true(float(clearing.get("radius", 0.0)) <= 12.0, "the identity pass does not bald the broader hill")
	assert_true(found, "The Rise hero has no protection from random scatter overlap")
	assert_true(sightline_found, "The Rise road end is still screened from its hero crown")
