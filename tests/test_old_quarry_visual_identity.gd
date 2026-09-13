extends "res://tests/test_case.gd"

const VEGETATION_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const HEAD_VEGETATION_PATH := "res://data/config/vegetation.json"
const VEGETATION_FIXTURE_PATH := "res://tests/fixtures/band_split_baseline/vegetation.json"
const SPAWNS_PATH := "res://data/config/bands/band2_stone_and_root/spawns.json"
const PROPS_PATH := "res://data/config/bands/band2_stone_and_root/props.json"
const QUARRY_CONFIG_PATH := "res://data/config/old_quarry.json"
const QUARRY := Vector2(400.0, 1800.0)
const SPINE_CORRIDORS := [
	[Vector2(310.0, 1660.0), Vector2(400.0, 1800.0)],
	[Vector2(400.0, 1800.0), Vector2(330.0, 1950.0)],
]
const ARRIVAL_CAMERA_PAIRS := [
	[Vector2(391.0, 1786.0), Vector2(388.0, 1804.0)],
	[Vector2(389.0, 1787.0), Vector2(387.0, 1804.0)],
	[Vector2(395.0, 1792.0), Vector2(389.0, 1804.0)],
]
const CAMERA_CORRIDORS := [
	[Vector2(389.0, 1787.0), Vector2(382.0, 1797.0)],
	[Vector2(389.0, 1787.0), Vector2(382.0, 1798.0)],
	[Vector2(389.0, 1787.0), Vector2(394.0, 1802.0)],
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


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s is invalid JSON" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _piece_chain_gap(pieces: Array[Dictionary], endpoint: Vector2) -> float:
	var largest := 0.0
	var previous: Variant = null
	for piece: Dictionary in pieces:
		var raw_at := piece.get("at", []) as Array
		if raw_at.size() != 2:
			return INF
		var point := Vector2(float(raw_at[0]), float(raw_at[1]))
		if previous != null:
			largest = maxf(largest, (previous as Vector2).distance_to(point))
		previous = point
	if previous == null:
		return INF
	return maxf(largest, (previous as Vector2).distance_to(endpoint))


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


func test_quarry_deadfall_keeps_identity_but_clears_the_worked_hierarchy() -> void:
	var head := _json(HEAD_VEGETATION_PATH)
	var deadfall: Dictionary = (head.get("layers", {}) as Dictionary).get("deadfall", {})
	var anchors: Array = deadfall.get("anchors", [])
	assert_true(not anchors.is_empty() and anchors[0] is Dictionary,
		"dedicated Old Quarry deadfall anchor is missing")
	if anchors.is_empty() or not anchors[0] is Dictionary:
		return
	var quarry_deadfall := anchors[0] as Dictionary
	assert_eq(int(quarry_deadfall.get("count", 0)), 6,
		"hierarchy fix deleted the quarry's six-tree drained-ground identity")
	var models: Array = quarry_deadfall.get("models", [])
	assert_eq(models.size(), 3)
	for model: Variant in models:
		assert_true(str(model).contains("DeadTree_"),
			"quarry deadfall anchor admits non-dead-tree dressing")
	var raw_at: Array = quarry_deadfall.get("at", [])
	assert_eq(raw_at.size(), 2)
	if raw_at.size() != 2:
		return
	var at := Vector2(float(raw_at[0]), float(raw_at[1]))
	var radius := float(quarry_deadfall.get("radius", 0.0))
	assert_true(radius > 0.0 and radius <= 10.0,
		"quarry deadfall is still a broad stand across the worked floor")
	assert_true(at.distance_to(QUARRY) <= 26.0,
		"deadfall was hidden away instead of remaining part of the quarry wound")
	for corridor: Array in CAMERA_CORRIDORS:
		assert_true(_distance_to_segment(at, corridor[0], corridor[1]) >= radius + 6.0,
			"quarry deadfall disc still overlaps an arrival/floor/conduit hero corridor")
	var fixture := _json(VEGETATION_FIXTURE_PATH)
	var fixture_deadfall: Dictionary = (fixture.get("layers", {}) as Dictionary).get("deadfall", {})
	var fixture_anchors: Array = fixture_deadfall.get("anchors", [])
	assert_true(not fixture_anchors.is_empty() and fixture_anchors[0] == quarry_deadfall,
		"band-split vegetation fixture does not mirror the relocated quarry deadfall anchor")


func test_old_quarry_work_wagon_reads_as_extraction_gear_without_blocking_routes() -> void:
	var props := _json(PROPS_PATH)
	var work_wagon: Dictionary = {}
	for raw_cluster: Variant in props.get("clusters", []):
		if not raw_cluster is Dictionary or str((raw_cluster as Dictionary).get("name", "")) != "quarry_station":
			continue
		for raw_prop: Variant in (raw_cluster as Dictionary).get("props", []):
			if raw_prop is Dictionary and str((raw_prop as Dictionary).get("name", "")) == "OldQuarryWorkWagon":
				work_wagon = raw_prop as Dictionary
				break
	assert_false(work_wagon.is_empty(), "Old Quarry has no readable extraction-wagon silhouette")
	if work_wagon.is_empty():
		return
	assert_eq(str(work_wagon.get("model", "")), "Prop_Wagon")
	assert_eq(str(work_wagon.get("dir", "")), "res://assets/buildings/quaternius_medieval")
	var raw_at: Array = work_wagon.get("at", [])
	assert_eq(raw_at.size(), 2)
	if raw_at.size() != 2:
		return
	var at := Vector2(float(raw_at[0]), float(raw_at[1]))
	assert_true(at.distance_to(QUARRY) <= 20.0,
		"work wagon was hidden away from the named quarry instead of dressing it")
	assert_true(float(work_wagon.get("scale", 0.0)) >= 1.0 \
			and float(work_wagon.get("scale", 0.0)) <= 1.25,
		"work wagon is too small to read or too large for the established prop family")
	# A 1.15-scale wagon occupies roughly a 3m half-extent. Six metres leaves
	# a second full player-width beyond that body on each authored camera/route line.
	for corridor: Array in CAMERA_CORRIDORS:
		assert_true(_distance_to_segment(at, corridor[0], corridor[1]) >= 6.0,
			"work wagon blocks an accepted Old Quarry route or hero corridor")


func test_old_quarry_cut_face_adds_tall_stepped_excavation_without_blocking_the_spine() -> void:
	var props := _json(PROPS_PATH)
	var face: Dictionary = {}
	for raw_cluster: Variant in props.get("clusters", []):
		if raw_cluster is Dictionary \
				and str((raw_cluster as Dictionary).get("name", "")) == "old_quarry_cut_face":
			face = raw_cluster as Dictionary
			break
	assert_false(face.is_empty(), "Old Quarry still has no authored cut-face silhouette")
	if face.is_empty():
		return
	assert_eq(int(face.get("order", -1)), 2000, "cut face left Band 2's reserved merge order")
	var pieces: Array = face.get("props", [])
	assert_eq(pieces.size(), 13, "cut face lost its five-piece wall or eight-piece stepped bench")
	var models := {}
	var tones := {}
	var rear_centres: Array[Vector2] = []
	var middle_centres: Array[Vector2] = []
	var bench_centres: Array[Vector2] = []
	for raw_prop: Variant in pieces:
		assert_true(raw_prop is Dictionary, "cut-face entry is not authored prop data")
		if not raw_prop is Dictionary:
			continue
		var prop := raw_prop as Dictionary
		var model := str(prop.get("model", ""))
		models[model] = true
		var role := str(prop.get("role", ""))
		assert_true(model.begins_with("Rock_Medium_"), "cut face escaped the installed rock family")
		assert_eq(str(prop.get("dir", "")), "res://assets/environment/stylized_nature",
			"cut face escaped the Meadows nature family")
		assert_false(prop.has("scale"),
			"%s carries a stale uniform scale that props.gd ignores beside scale_xyz" %
			str(prop.get("name", "piece")))
		var retint := prop.get("retint", {}) as Dictionary
		assert_true(retint.has("Rocks"),
			"%s lacks the authored stratum tone" % str(prop.get("name", "piece")))
		if retint.has("Rocks"):
			tones[str(retint.get("Rocks", ""))] = true
		var raw_at: Array = prop.get("at", [])
		assert_eq(raw_at.size(), 2)
		if raw_at.size() != 2:
			continue
		var at := Vector2(float(raw_at[0]), float(raw_at[1]))
		var scale_xyz := prop.get("scale_xyz", []) as Array
		assert_eq(scale_xyz.size(), 3,
			"%s returned to a uniform freestanding boulder" % str(prop.get("name", "piece")))
		assert_true(at.distance_to(QUARRY) <= 26.0,
			"cut-face piece drifted outside the named worksite")
		for corridor: Array in SPINE_CORRIDORS:
			assert_true(_distance_to_segment(at, corridor[0], corridor[1]) >= 10.5,
				"cut-face mass crowds the live Band 2 route")
		if scale_xyz.size() != 3:
			continue
		var sx := float(scale_xyz[0])
		var sy := float(scale_xyz[1])
		var sz := float(scale_xyz[2])
		assert_true(sx > sy and sx > sz,
			"%s is not compressed into a broad quarry layer" % str(prop.get("name", "piece")))
		if role == "rear_wall":
			rear_centres.append(at)
			assert_eq(int(prop.get("stratum", -1)), 3,
				"rear wall escaped the high exposed stratum")
			assert_true(sx >= 3.60 and sx <= 4.15 and sy >= 3.0 and sy <= 3.5
				and sz >= 1.90 and sz <= 2.12,
				"rear wall is too small to overlap or returned to a frame-filling monolith")
			assert_true(float(prop.get("sink_m", 0.0)) >= 1.60,
				"%s exposes a rounded freestanding foot instead of a buried cut" %
				str(prop.get("name", "rear wall")))
		elif role == "middle_bench":
			middle_centres.append(at)
			assert_eq(int(prop.get("stratum", -1)), 2,
				"middle bench escaped its repeated worked level")
			assert_true(sx >= 2.35 and sx <= 2.65 and sy >= 0.70 and sy <= 0.95
				and sz >= 1.55 and sz <= 1.70,
				"middle bench is too slight to read as the face's first shelf")
		elif role == "lower_bench":
			bench_centres.append(at)
			assert_true(int(prop.get("stratum", -1)) in [0, 1],
				"lower bench has no descending stratum order")
			assert_true(sx >= 1.90 and sx <= 2.15 and sy >= 0.34 and sy <= 0.45
				and sz >= 1.38 and sz <= 1.48,
				"lower bench is too slight to read or too tall to remain a bench")
		else:
			assert_true(false, "%s has no wall/bench role" % str(prop.get("name", "piece")))
	assert_eq(rear_centres.size(), 5, "cut face needs five densely overlapping rear-wall masses")
	assert_eq(middle_centres.size(), 4, "cut face needs four continuous middle shelves")
	assert_eq(bench_centres.size(), 4, "cut face needs four contiguous descending lower ledges")
	assert_eq(models.size(), 3, "cut face repeats one boulder instead of forming a varied wall")
	assert_true(tones.size() >= 4,
		"wall and benches collapse into one flat material value instead of readable strata")
	for index in range(1, rear_centres.size()):
		assert_true(rear_centres[index - 1].distance_to(rear_centres[index]) <= 3.70,
			"rear wall has a freestanding gap between pieces %d and %d" % [index - 1, index])
	for index in range(1, bench_centres.size()):
		assert_true(bench_centres[index - 1].distance_to(bench_centres[index]) <= 3.70,
			"lower bench has a freestanding gap between pieces %d and %d" % [index - 1, index])
	for index in range(1, middle_centres.size()):
		assert_true(middle_centres[index - 1].distance_to(middle_centres[index]) <= 3.70,
			"middle shelf has a freestanding gap between pieces %d and %d" % [index - 1, index])
	assert_true(rear_centres[0].distance_to(middle_centres[0]) <= 3.0,
		"middle strata no longer overlap the rear excavated wall")
	assert_true(middle_centres[0].distance_to(bench_centres[0]) <= 3.0,
		"lower ledge no longer overlaps the middle worked shelf")
	assert_true(bench_centres[3].distance_to(Vector2(392.0, 1798.0)) <= 8.0,
		"descending bench no longer hands the cut face to the retained haul wagon")
	assert_false(JSON.stringify(face).contains("glow"),
		"abandoned quarry face should not invent another unexplained light source")


func test_old_quarry_has_one_bounded_warm_work_practical_off_the_routes() -> void:
	var config := _json(QUARRY_CONFIG_PATH)
	var lights := config.get("work_lights", []) as Array
	assert_eq(lights.size(), 1, "quarry work hierarchy needs one practical, not a light field")
	if lights.size() != 1:
		return
	var light := lights[0] as Dictionary
	var at_raw := light.get("at", []) as Array
	assert_eq(at_raw.size(), 2)
	if at_raw.size() != 2:
		return
	var at := Vector2(float(at_raw[0]), float(at_raw[1]))
	assert_true(at.distance_to(QUARRY) <= 16.0,
		"work practical drifted away from the extraction gear")
	for corridor: Array in CAMERA_CORRIDORS:
		assert_true(_distance_to_segment(at, corridor[0], corridor[1]) >= 6.0,
			"work-lantern post enters an accepted route/camera corridor")
	assert_true(float(light.get("range_m", INF)) <= 11.0
		and float(light.get("energy", INF)) <= 2.4,
		"work practical relights the whole quarry instead of its wagon/face")
	var colour := Color(str(light.get("colour", "#000000")))
	assert_true(colour.r > colour.b and colour.g > colour.b,
		"quarry work light competes with the cyan conduit hierarchy")
	var source := FileAccess.get_file_as_string("res://scripts/world/old_quarry.gd")
	assert_true(source.contains("_build_work_lights")
		and source.contains("VisibleAmberSource")
		and source.contains("WarmWorkPool")
		and source.contains('spec.get("source_emission", 1.35)'),
		"production quarry omits the modeled source or bounded pool")


func test_r27_builds_a_camera_side_concave_cut_with_two_work_handoffs() -> void:
	var config := _json(QUARRY_CONFIG_PATH)
	var cut := config.get("worked_cut", {}) as Dictionary
	assert_eq(str(cut.get("albedo_texture", "")),
		"res://assets/environment/terrain/stylised/rock_scree_Color.png")
	assert_eq(str(cut.get("normal_texture", "")),
		"res://assets/environment/terrain/stylised/rock_scree_NormalGL.png")
	var pieces := cut.get("pieces", []) as Array
	assert_eq(pieces.size(), 15, "R27 worked cut lost a face, ledge, bench or story handoff")
	var role_counts := {"extraction_face": 0, "tool_course": 0,
		"working_bench": 0, "wagon_handoff": 0, "conduit_handoff": 0}
	var faces: Array[Dictionary] = []
	var wagon_aprons: Array[Dictionary] = []
	var conduit_aprons: Array[Dictionary] = []
	for raw_piece: Variant in pieces:
		assert_true(raw_piece is Dictionary, "worked-cut piece is not authored data")
		if not raw_piece is Dictionary:
			continue
		var piece := raw_piece as Dictionary
		var role := str(piece.get("role", ""))
		assert_true(role_counts.has(role), "%s has no extraction role" % str(piece.get("name", "piece")))
		if role_counts.has(role):
			role_counts[role] = int(role_counts[role]) + 1
		if role == "extraction_face":
			faces.append(piece)
		elif role == "wagon_handoff":
			wagon_aprons.append(piece)
		elif role == "conduit_handoff":
			conduit_aprons.append(piece)
		var at_raw := piece.get("at", []) as Array
		var size_raw := piece.get("size", []) as Array
		assert_eq(at_raw.size(), 2)
		assert_eq(size_raw.size(), 3)
		if at_raw.size() == 2:
			var at := Vector2(float(at_raw[0]), float(at_raw[1]))
			assert_true(at.distance_to(QUARRY) <= 25.0,
				"worked-cut piece escaped the quarry worksite")
		if role in ["extraction_face", "tool_course", "working_bench"]:
			assert_eq(str(piece.get("shape", "")), "faceted_wedge",
				"%s regressed to smooth rectangular shell geometry" % str(piece.get("name", "piece")))
			assert_true(float(piece.get("batter_m", 0.0)) >= 0.15,
				"faceted quarry piece lost its grounded batter")
	assert_eq(int(role_counts["extraction_face"]), 4)
	assert_eq(int(role_counts["tool_course"]), 4)
	assert_eq(int(role_counts["working_bench"]), 3)
	assert_eq(int(role_counts["wagon_handoff"]), 2)
	assert_eq(int(role_counts["conduit_handoff"]), 2)
	faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float((a.get("at", []) as Array)[0]) < float((b.get("at", []) as Array)[0]))
	var face_z := []
	var top_scales := []
	var retained_collision_south_z: Array[float] = [1800.0, 1799.0, 1798.0, 1796.5]
	for face_index in faces.size():
		var face: Dictionary = faces[face_index]
		face_z.append(float((face.get("at", []) as Array)[1]))
		top_scales.append(float(face.get("top_left_scale", 1.0)))
		top_scales.append(float(face.get("top_right_scale", 1.0)))
		var size_raw := face.get("size", []) as Array
		var yaw := deg_to_rad(float(face.get("yaw_deg", 0.0)))
		var south_extent := absf(sin(yaw)) * float(size_raw[0]) * 0.5 \
			+ absf(cos(yaw)) * float(size_raw[2]) * 0.5
		var visible_front_z := face_z[-1] - south_extent
		assert_true(visible_front_z <= retained_collision_south_z[face_index] - 1.25,
			"R27 extraction face remains behind the retained collision front")
	assert_true(face_z[1] > face_z[0] + 0.5 and face_z[1] > face_z[3] + 1.0,
		"R27 extraction face does not bow into a concave hillside wound")
	assert_true(float(top_scales.max()) - float(top_scales.min()) >= 0.20,
		"R27 extraction crown is still a level bunker roofline")
	assert_true(_piece_chain_gap(wagon_aprons, Vector2(399.0, 1787.5)) <= 3.8,
		"R27 wagon apron no longer reaches retained haul gear")
	assert_true(_piece_chain_gap(conduit_aprons, Vector2(404.0, 1804.0)) <= 7.8,
		"R27 conduit apron no longer reaches the unchanged conduit head")
	var pylons := config.get("pylons", {}) as Dictionary
	assert_true(float(pylons.get("conduit_radius_scale", 1.0)) <= 0.60
		and float(pylons.get("conduit_emission_scale", 1.0)) <= 0.60,
		"quarry-only conduit still dominates the night work hierarchy")
	var source := FileAccess.get_file_as_string("res://scripts/world/old_quarry.gd")
	assert_true(source.contains("_build_worked_cut")
		and source.contains("OldQuarryWorkedCut")
		and source.contains("_textured_wedge")
		and source.contains("SurfaceTool.new()")
		and source.contains("uv1_triplanar")
		and not source.contains("rock_scree"),
		"production worked cut is absent or hard-codes its material outside config")
	assert_false(source.contains("WorkedCutCollision"),
		"visual cut introduced a second collision authority")
	var lights := config.get("work_lights", []) as Array
	assert_eq(lights.size(), 1, "R27 night hierarchy added another light")
	assert_true(float((lights[0] as Dictionary).get("attenuation", 0.0)) >= 1.0
		and float((lights[0] as Dictionary).get("attenuation", INF)) <= 1.15,
		"R27 night floor escaped the retained bounded local pool")


func test_r19_clears_only_the_stale_arrival_tree_and_finishes_the_foundation_slab() -> void:
	var config := _json(QUARRY_CONFIG_PATH)
	var clearing := config.get("arrival_scatter_clear", {}) as Dictionary
	var at_raw := clearing.get("at", []) as Array
	assert_eq(at_raw.size(), 2, "R19 arrival scatter clearing has no authored centre")
	if at_raw.size() == 2:
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(_distance_to_segment(at, SPINE_CORRIDORS[0][0], SPINE_CORRIDORS[0][1]) <= 5.0,
			"arrival scatter clearing left the real incoming road threshold")
	assert_true(float(clearing.get("radius_m", 0.0)) >= 8.5
		and float(clearing.get("radius_m", INF)) <= 9.0,
		"arrival clearing removes the quarry forest instead of the blocking threshold tree")
	var face_clearing := config.get("cut_face_scatter_clear", {}) as Dictionary
	var face_at := face_clearing.get("at", []) as Array
	assert_eq(face_at.size(), 2, "R27 intersecting cut-face trees have no bounded clearing")
	assert_true(float(face_clearing.get("radius_m", 0.0)) >= 7.5
		and float(face_clearing.get("radius_m", INF)) <= 8.0,
		"R27 face clearing is too small for the ray blockers or broad enough to erase the grove")
	var finishes := config.get("foundation_finish", []) as Array
	assert_eq(finishes.size(), 1, "grey slab needs one restrained supported-end treatment")
	var source := FileAccess.get_file_as_string("res://scripts/world/old_quarry.gd")
	assert_true(source.contains("_clear_arrival_sightline")
		and source.contains('vegetation.call("clear_area"')
		and source.contains("_build_foundation_finish")
		and source.contains("StoneEndCap")
		and source.contains("TimberCribRail"),
		"production quarry omits the bounded scatter clear or supported slab finish")


func test_old_quarry_capture_refuses_solid_camera_seats_and_requires_readable_terrace() -> void:
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_old_quarry_visual_identity.gd")
	assert_true(source.contains("CAPTURE_CHECK.problems")
		and source.contains("refused invalid quarry frame"),
		"quarry harness can still photograph from inside a tree or solid")
	assert_true(source.contains("_readable_terrace_problems")
		and source.contains("_r27_worked_cut_problems")
		and source.contains("_r27_layout_problems")
		and source.contains("_continuous_plan_chain_problems")
		and source.contains("_merged_named_aabb")
		and source.contains("_stratum_visibility_problems")
		and source.contains("_upper_outer_samples")
		and source.contains("connected rear cut face")
		and source.contains("descending worked benches")
		and source.contains("max_height_frac")
		and source.contains('"space": null')
		and source.contains("clear_samples >= required_samples")
		and source.contains("visible_pieces >= 2")
		and source.contains("PhysicsRayQueryParameters3D.create(camera.global_position, target)")
		and source.contains("_collect_collision_rids(cluster, excluded)"),
		"arrival/cut-face frames lack projected-bounds checks plus meaningful live surface visibility")
	for required_name: String in ["WorkedFaceWest", "WorkedFaceMidWest",
			"WorkedFaceMidEast", "WorkedFaceEast",
			"StrataCourseUpperWest", "StrataCourseUpperEast", "StrataCourseLowerWest",
			"StrataCourseLowerEast", "WorkedBenchWest", "WorkedBenchEast",
			"WorkedBenchToe", "HaulApronUpper", "HaulApronLower",
			"ConduitApronInner", "ConduitApronHead"]:
		assert_true(source.contains(required_name),
			"R27 evidence never requires production node %s" % required_name)
	assert_true(source.contains('shot_label in ["01-arrival", "02-worked-floor", "03-conduit-head", "04-cut-face"]')
		and source.contains("R27 concave extraction face and thick strata")
		and source.contains("R27 bench-to-wagon/conduit handoff")
		and source.contains('R27_FACE_NAMES, "R27 faceted extraction faces", true')
		and source.contains('R27_COURSE_NAMES, "R27 thick worked strata", true')
		and source.contains('R27_BENCH_NAMES, "R27 projecting working benches", true')
		and source.contains('R27_WAGON_APRON_NAMES, "R27 floor-to-wagon apron", true')
		and source.contains('R27_CONDUIT_APRON_NAMES, "R27 floor-to-conduit apron", true'),
		"R27 interior/cut frames can pass without projected and live-readable defining repair")
	assert_true(source.contains("OLD-QUARRY-TERRACE-R27")
		and not source.contains("OLD-QUARRY-TERRACE-R22"),
		"fresh R27 composition evidence can overwrite or be confused with R22")
	assert_true(source.contains("REQUIRED_FRAME_LABELS")
		and source.contains("_require_exact_frame_set(records, failures)")
		and source.contains("_worked_cut_receipt(world)")
		and source.contains('geometry_receipt.get("piece_count", 0) != 15')
		and source.contains("_camera_facing_mesh_samples")
		and source.contains("surface_get_arrays(surface_index)")
		and source.contains("arrays[Mesh.ARRAY_VERTEX]")
		and source.contains("arrays[Mesh.ARRAY_INDEX]")
		and source.contains("(a + b + c) / 3.0")
		and source.contains("candidates.sort_custom(_mesh_sample_score_descending)"),
		"R27 capture can pass without exactly 8/8 frames and actual live mesh-surface proof")
	var mesh_sampler := source.get_slice("func _camera_facing_mesh_samples", 1).get_slice(
		"func _mesh_sample_score_descending", 0)
	assert_false(mesh_sampler.contains("get_aabb") or mesh_sampler.contains("_upper_outer_samples"),
		"exact mesh-surface proof must not quietly fall back to an AABB face")
	assert_true(source.contains('get_node_or_null(^"Terrain")')
		and source.contains('terrain.call("set_camera", camera)'),
		"quarry evidence leaves Terrain3D streaming around the gameplay rig")
	assert_true(source.contains("ARRIVAL_CAMERA_CANDIDATES")
		and source.contains('"candidate_id": "late-spine-threshold"')
		and source.contains('"candidate_id": "late-west-threshold"')
		and source.contains('"candidate_id": "late-east-threshold"')
		and source.contains("_select_arrival_camera")
		and source.contains("_readable_terrace_problems(world, camera)")
		and source.contains('"arrival_camera_selection"')
		and source.contains('"rejected_before_selection"')
		and source.contains('"stand": Vector2(391.0, 1786.0)')
		and not source.contains('"stand": Vector2(394.0, 1817.0)'),
		"arrival camera lacks deterministic live-physics selection on the incoming Band 2 road")
	assert_true(source.count('"stand": Vector2(389.0, 1787.0)') >= 4
		and source.contains('"target": Vector2(382.0, 1797.0)')
		and source.contains('"target": Vector2(394.0, 1802.0)')
		and source.contains('"back": 7.0')
		and source.contains('"fov": 105.0')
		and source.contains('"max_height_frac": 0.50'),
		"R24 proof left the grounded production threshold or retained the rejected close-up framing")
	assert_true(source.contains("func _support_surface")
		and source.contains("_collect_collision_rids(player, excluded)")
		and source.contains('"player_on_floor": player_on_floor')
		and source.contains("is_on_floor()"),
		"grounding proof compares the player only to Terrain3D or can self-hit")


func test_r19_arrival_candidates_are_bounded_to_the_real_incoming_road() -> void:
	var source := FileAccess.get_file_as_string(
		"res://tools/capture_old_quarry_visual_identity.gd")
	for pair: Array in ARRIVAL_CAMERA_PAIRS:
		var stand: Vector2 = pair[0]
		var target: Vector2 = pair[1]
		assert_true(_distance_to_segment(stand, SPINE_CORRIDORS[0][0],
			SPINE_CORRIDORS[0][1]) <= 5.0,
			"arrival candidate left the ordinary incoming road/shoulder")
		assert_true(target.distance_to(QUARRY) <= 14.0,
			"arrival candidate no longer aims into the named worked site")
		assert_true(source.contains('"stand": Vector2(%.1f, %.1f)' % [stand.x, stand.y])
			and source.contains('"target": Vector2(%.1f, %.1f)' % [target.x, target.y]),
			"tested arrival candidate is not serialized by the production harness")
	assert_true(source.contains('"back": 22.0')
		and source.contains('"up": 4.0')
		and source.contains('"fov": 100.0')
		and source.contains("const CAMERA_SETTLE_PHYSICS_FRAMES := 36")
		and source.count("for i in CAMERA_SETTLE_PHYSICS_FRAMES") >= 2
		and source.contains("func _place_player_for_shot")
		and source.contains("_place_player_for_shot(world, player, candidate)")
		and source.contains("_place_player_for_shot(world, player, shot)")
		and source.contains("player.global_position = Vector3(stand.x, ground + 0.30, stand.y)")
		and source.contains("player.reset_physics_interpolation()")
		and source.contains('"selection_streaming_anchor": "production Player grounded at candidate stand before settle"')
		and source.contains('"camera_settle_physics_frames": CAMERA_SETTLE_PHYSICS_FRAMES')
		and source.contains("CAPTURE_CHECK.problems(self, camera")
		and source.contains("problems.append_array(_readable_terrace_problems"),
		"candidate choice is not gated by both solid-seat and live subject-occlusion checks")
