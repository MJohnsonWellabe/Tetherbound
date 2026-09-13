extends "res://tests/test_case.gd"

## Focused contract for The Rise's production-visible hero composition.
## The destination used to be a terrain mound plus a fingerpost; these checks
## keep the authored tree-and-stone crown tied to the canonical region and out
## of both roads that meet at its foot.

const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const CAPTURE_PATH := "res://tools/capture_the_rise_identity.gd"
const HERO_NAME := "the_rise_rock_crown"
const TRAIL_NAME := "the_rise_cairn_trail"
const OVERLOOK_NAME := "the_rise_overlook"


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


func _trail_cluster() -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == TRAIL_NAME:
			return cluster
	return {}


func _overlook_cluster() -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == OVERLOOK_NAME:
			return cluster
	return {}


func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


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


func test_cairn_tread_connects_the_safe_road_end_to_the_crown_shelf() -> void:
	var cluster := _trail_cluster()
	assert_false(cluster.is_empty(), "The Rise has no authored climb/trail branch")
	assert_eq(int(cluster.get("order", -1)), 1055,
		"the climb remains a separate band-reserved production cluster")
	var props := cluster.get("props", []) as Array
	assert_eq(props.size(), 33,
		"eighteen broad switchback landings, twelve low retaining stones and three bounded waylights")
	var tread_positions := PackedVector2Array()
	var torch_positions := PackedVector2Array()
	var retaining_positions := PackedVector2Array()
	var torch_count := 0
	for raw: Variant in props:
		var prop := raw as Dictionary
		var model := str(prop.get("model", ""))
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		if model.begins_with("RockPath_Round_"):
			tread_positions.append(at)
			var scale_raw := prop.get("scale_xyz", []) as Array
			assert_eq(scale_raw.size(), 3, "%s loses its broad, flattened walking profile" % str(prop.get("name", "tread")))
			if scale_raw.size() == 3:
				assert_true(float(scale_raw[0]) >= 3.0 and float(scale_raw[2]) >= 3.3,
					"%s shrank back into a narrow erosion shelf" % str(prop.get("name", "tread")))
				assert_true(float(scale_raw[1]) <= 0.24,
					"%s grew into a traversal-blocking path slab" % str(prop.get("name", "tread")))
			var tint := (prop.get("retint", {}) as Dictionary).get("PathRocks", {}) as Dictionary
			assert_eq(str(tint.get("color", "")), "#e5ddb5",
				"the low tread loses its day/night value separation")
			assert_eq(str(tint.get("emission", "")), "#6f694e",
				"the tread loses its restrained night fill colour")
			assert_true(float(tint.get("energy", 0.0)) >= 0.20 \
					and float(tint.get("energy", 99.0)) <= 0.24,
				"the tread fill is either absent or bright enough to read as magical glow")
			assert_true(ResourceLoader.exists("%s/%s.gltf" % [str(prop.get("dir", "")), model]),
				"the tread does not use an installed production asset")
		elif str(prop.get("name", "")).ends_with("Torch"):
			torch_count += 1
			torch_positions.append(at)
			assert_eq(model, "Torch_Metal", "the fork uses the established physical torch")
			assert_true(ResourceLoader.exists("res://assets/props/quaternius_fantasy/Torch_Metal.gltf"),
				"the waylight must use the installed fantasy-prop torch")
			assert_eq(str(prop.get("glow", "")), "campfire", "a waylight no longer casts light")
			assert_true(float(prop.get("glow_scale", 99.0)) <= 0.48,
				"a trail waylight became a hillside floodlight")
		elif str(prop.get("name", "")).begins_with("RiseRetaining"):
			retaining_positions.append(at)
			assert_true(model.begins_with("Rock_Medium_"),
				"the retaining edge left the Meadows nature family")
			assert_true(ResourceLoader.exists("%s/%s.gltf" % [str(prop.get("dir", "")), model]),
				"the retaining edge does not use an installed production asset")
			var scale_raw := prop.get("scale_xyz", []) as Array
			assert_eq(scale_raw.size(), 3, "a retaining stone lost its low, elongated profile")
			if scale_raw.size() == 3:
				assert_true(float(scale_raw[0]) >= 1.0 and float(scale_raw[1]) <= 0.7,
					"a retaining stone no longer reads as a low load-bearing edge")
	assert_eq(tread_positions.size(), 18, "the continuous switchback surface survives")
	assert_eq(retaining_positions.size(), 12, "the broad route loses its broken dry-stone retaining rhythm")
	assert_eq(torch_count, 3, "the trail keeps only its start-turn-arrival waylights")
	for torch_at: Vector2 in torch_positions:
		var nearest_tread := INF
		for tread_at: Vector2 in tread_positions:
			nearest_tread = minf(nearest_tread, torch_at.distance_to(tread_at))
		assert_true(nearest_tread >= 2.5 and nearest_tread <= 4.5,
			"a waylight either blocks the walking line or has disconnected from it")
	var road_end := Vector2(74.0, -41.0)
	var hero := Vector2(99.5, -55.0)
	assert_true(tread_positions[0].distance_to(road_end) <= 3.0,
		"the first tread disconnected from the authored safe road end")
	assert_true(tread_positions[tread_positions.size() - 1].distance_to(hero) <= 6.0,
		"the last tread disconnected from the retained crown")
	for index in tread_positions.size() - 1:
		assert_true(tread_positions[index].distance_to(tread_positions[index + 1]) <= 4.8,
			"the cairn sequence has an unreadable gap between %d and %d" % [index, index + 1])
	for retaining_at: Vector2 in retaining_positions:
		var nearest_tread := INF
		for tread_at: Vector2 in tread_positions:
			nearest_tread = minf(nearest_tread, retaining_at.distance_to(tread_at))
		assert_true(nearest_tread >= 1.8 and nearest_tread <= 5.2,
			"a retaining stone either blocks the walking centre or disconnects from the terrace")
	# A real switchback changes travel bearing at the lower terrace instead of
	# drawing one implausible line straight up the impassable west face.
	assert_true(tread_positions[11].y < tread_positions[5].y - 10.0,
		"the route no longer reaches the lower contour before turning uphill")
	assert_true(tread_positions[17].y > tread_positions[11].y + 15.0,
		"the switchback never returns from the lower contour to the crown")


func test_crown_arrival_has_a_real_outward_overlook_payoff() -> void:
	var cluster := _overlook_cluster()
	assert_false(cluster.is_empty(), "The Rise crown has no authored overlook payoff")
	assert_eq(int(cluster.get("order", -1)), 1056, "the overlook keeps its reserved band order")
	var props := cluster.get("props", []) as Array
	assert_eq(props.size(), 5, "the overlook remains one restrained five-piece pause")
	var names := {}
	for raw: Variant in props:
		var prop := raw as Dictionary
		names[str(prop.get("name", ""))] = true
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(at.distance_to(Vector2(99.5, -55.0)) <= 10.0,
			"%s disconnected from the retained crown" % str(prop.get("name", "prop")))
		assert_false(prop.has("glow"), "the summit payoff must not invent another beacon light")
	assert_true(names.has("RiseOverlookBench") and names.has("RiseOverlookCairnLeft") \
		and names.has("RiseOverlookCairnRight"),
		"the outward-facing bench and asymmetric vista frame must survive")
	var bench := props[0] as Dictionary
	assert_eq(str(bench.get("model", "")), "Bench", "the overlook loses its legible pause subject")
	assert_true(float(bench.get("yaw_deg", 0.0)) >= 45.0 and float(bench.get("yaw_deg", 0.0)) <= 70.0,
		"the bench has turned back into the slope instead of facing the village country")


func test_r7_capture_proves_the_broad_switchback_and_outward_overlook_without_injected_light() -> void:
	var source := _source(CAPTURE_PATH)
	assert_true(source.contains("THE-RISE-IDENTITY-R7")
		and source.contains("FRESH_OUTPUT.create_fresh")
		and source.contains("records.size() == VIEWS.size() * 2"),
		"R7 must write a fresh, complete day/night evidence set")
	for frame_name: String in ["01-road-climb-approach", "02-road-end-trailhead",
			"03-full-switchback-climb", "04-crown-overlook"]:
		assert_true(source.contains(frame_name), "R7 lost distinct composition %s" % frame_name)
	assert_true(source.contains("No scene content, light, material, pose or progression is injected")
		and source.contains("the_rise_cairn_trail/RiseTrailForkTorch")
		and source.contains("the_rise_overlook/RiseOverlookBench")
		and source.contains("target_xz\": [20.0, -5.0]")
		and source.contains("composition_role")
		and source.contains("day frame is not brighter than its matched night frame"),
		"the evidence must disclose and receipt production-only night readability")
