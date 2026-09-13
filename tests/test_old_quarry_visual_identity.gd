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


func test_r23_builds_one_exposed_continuous_cut_ahead_of_retained_collision() -> void:
	var config := _json(QUARRY_CONFIG_PATH)
	var cut := config.get("worked_cut", {}) as Dictionary
	assert_eq(str(cut.get("albedo_texture", "")),
		"res://assets/environment/terrain/stylised/rock_scree_Color.png")
	assert_eq(str(cut.get("normal_texture", "")),
		"res://assets/environment/terrain/stylised/rock_scree_NormalGL.png")
	var pieces := cut.get("pieces", []) as Array
	assert_eq(pieces.size(), 13, "worked cut lost a face, course, bench or apron piece")
	var role_counts := {"extraction_face": 0, "tool_course": 0,
		"working_bench": 0, "floor_handoff": 0}
	var faces: Array[Dictionary] = []
	var benches: Array[Dictionary] = []
	var aprons: Array[Dictionary] = []
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
		elif role == "working_bench":
			benches.append(piece)
		elif role == "floor_handoff":
			aprons.append(piece)
		var at_raw := piece.get("at", []) as Array
		var size_raw := piece.get("size", []) as Array
		assert_eq(at_raw.size(), 2)
		assert_eq(size_raw.size(), 3)
		if at_raw.size() == 2:
			var at := Vector2(float(at_raw[0]), float(at_raw[1]))
			assert_true(at.distance_to(QUARRY) <= 25.0,
				"worked-cut piece escaped the quarry worksite")
	assert_eq(int(role_counts["extraction_face"]), 4)
	assert_eq(int(role_counts["tool_course"]), 4)
	assert_eq(int(role_counts["working_bench"]), 3)
	assert_eq(int(role_counts["floor_handoff"]), 2)
	faces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float((a.get("at", []) as Array)[0]) < float((b.get("at", []) as Array)[0]))
	# R22 incorrectly certified the most-southerly rotated corner, although the
	# live verifier aims at the centre and insets of the camera-facing local -Z
	# plane. Reconstruct the production colliders from the same glTF POSITION
	# bounds, scale_xyz and yaw that props.gd uses, then pin every sampled plane
	# ahead of the nearest retained collision rather than another hand-copied OBB.
	var retained_front_z := INF
	var props := _json(PROPS_PATH)
	for raw_cluster: Variant in props.get("clusters", []):
		var cluster := raw_cluster as Dictionary
		if str(cluster.get("name", "")) != "old_quarry_cut_face":
			continue
		for raw_prop: Variant in cluster.get("props", []):
			var retained := raw_prop as Dictionary
			if str(retained.get("role", "")) != "rear_wall":
				continue
			var model_name := str(retained.get("model", ""))
			var gltf := _json("res://assets/environment/stylized_nature/%s.gltf" % model_name)
			var position_accessor := (gltf.get("accessors", []) as Array)[0] as Dictionary
			var minimum := position_accessor.get("min", []) as Array
			var maximum := position_accessor.get("max", []) as Array
			var scale := retained.get("scale_xyz", []) as Array
			var retained_at := retained.get("at", []) as Array
			var retained_yaw := deg_to_rad(float(retained.get("yaw_deg", 0.0)))
			for local_x: float in [float(minimum[0]) * float(scale[0]),
					float(maximum[0]) * float(scale[0])]:
				for local_z: float in [float(minimum[2]) * float(scale[2]),
						float(maximum[2]) * float(scale[2])]:
					var world_z := float(retained_at[1]) - sin(retained_yaw) * local_x \
						+ cos(retained_yaw) * local_z
					retained_front_z = minf(retained_front_z, world_z)
	assert_true(retained_front_z < INF,
		"focused geometry test could not reconstruct retained quarry collision")
	for index in range(faces.size()):
		var face := faces[index]
		var face_at := face.get("at", []) as Array
		var face_size := face.get("size", []) as Array
		assert_true(float(face_size[1]) >= 4.5,
			"R23 face bay is too low to replace the smooth mound silhouette")
		assert_true(float(face.get("lift_m", INF)) <= float(face_size[1]) * 0.5 - 0.25,
			"R23 face bay exposes a freestanding box foot instead of a buried cut")
		var yaw := deg_to_rad(float(face.get("yaw_deg", 99.0)))
		var camera_face_z := float(face_at[1]) - cos(yaw) * float(face_size[2]) * 0.5
		assert_true(float(face.get("yaw_deg", 0.0)) >= 14.0
			and float(face.get("yaw_deg", 0.0)) <= 20.0,
			"R23 face bay does not follow the retained collider envelope")
		assert_true(camera_face_z <= retained_front_z - 0.25,
			"R23 camera-facing plane remains behind retained-rock collision")
		if index > 0:
			var previous := faces[index - 1]
			var previous_at := previous.get("at", []) as Array
			var previous_size := previous.get("size", []) as Array
			var centre_gap := float(face_at[0]) - float(previous_at[0])
			var shared_half_width := (float(face_size[0]) + float(previous_size[0])) * 0.5
			assert_true(centre_gap <= shared_half_width - 0.35,
				"R23 extraction bays have a visible freestanding gap instead of one face")
	assert_true(float((benches[0].get("at", []) as Array)[1]) < 1794.0
		and float((benches[1].get("at", []) as Array)[1]) < 1792.0
		and float((benches[2].get("at", []) as Array)[1]) < 1790.0,
		"R23 benches do not project in repeated steps from face to floor")
	var last_apron_at := aprons[1].get("at", []) as Array
	var last_apron_size := aprons[1].get("size", []) as Array
	var last_apron_yaw := deg_to_rad(float(aprons[1].get("yaw_deg", 0.0)))
	var wagon_at := Vector2.INF
	for raw_cluster: Variant in props.get("clusters", []):
		for raw_prop: Variant in (raw_cluster as Dictionary).get("props", []):
			var prop := raw_prop as Dictionary
			if str(prop.get("name", "")) == "OldQuarryWorkWagon":
				var raw_wagon_at := prop.get("at", []) as Array
				wagon_at = Vector2(float(raw_wagon_at[0]), float(raw_wagon_at[1]))
	var apron_to_wagon := wagon_at - Vector2(float(last_apron_at[0]), float(last_apron_at[1]))
	var wagon_local := Vector2(cos(last_apron_yaw) * apron_to_wagon.x \
		- sin(last_apron_yaw) * apron_to_wagon.y,
		sin(last_apron_yaw) * apron_to_wagon.x + cos(last_apron_yaw) * apron_to_wagon.y)
	assert_true(wagon_at != Vector2.INF
		and absf(wagon_local.x) <= float(last_apron_size[0]) * 0.5 + 0.5
		and absf(wagon_local.y) <= float(last_apron_size[2]) * 0.5 + 0.75,
		"R23 apron no longer physically reaches the retained wagon")
	var pylons := config.get("pylons", {}) as Dictionary
	assert_true(float(pylons.get("conduit_radius_scale", 1.0)) <= 0.60
		and float(pylons.get("conduit_emission_scale", 1.0)) <= 0.60,
		"quarry-only conduit still dominates the night work hierarchy")
	var source := FileAccess.get_file_as_string("res://scripts/world/old_quarry.gd")
	assert_true(source.contains("_build_worked_cut")
		and source.contains("OldQuarryWorkedCut")
		and source.contains("uv1_triplanar")
		and not source.contains("rock_scree"),
		"production worked cut is absent or hard-codes its material outside config")
	assert_false(source.contains("WorkedCutCollision"),
		"visual cut introduced a second collision authority")
	var lights := config.get("work_lights", []) as Array
	assert_eq(lights.size(), 1, "R23 night floor repair added another light")
	assert_true(float((lights[0] as Dictionary).get("attenuation", 0.0)) >= 1.0
		and float((lights[0] as Dictionary).get("attenuation", INF)) <= 1.15,
		"R23 night floor is still crushed by hard falloff or escaped the bounded local pool")


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
		and source.contains("_r23_worked_cut_problems")
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
			"WorkedBenchToe", "HaulApronUpper", "HaulApronLower"]:
		assert_true(source.contains(required_name),
			"R23 evidence never requires production node %s" % required_name)
	assert_true(source.contains('shot_label in ["02-worked-floor", "03-conduit-head", "04-cut-face"]')
		and source.contains("R23 planar extraction face and strata")
		and source.contains("R23 bench-to-haul-floor handoff")
		and source.contains('R23_FACE_NAMES, "R23 planar extraction faces", true')
		and source.contains('R23_COURSE_NAMES, "R23 repeated tool courses", true')
		and source.contains('R23_BENCH_NAMES, "R23 projecting working benches", true')
		and source.contains('R23_APRON_NAMES, "R23 floor-to-wagon apron", true'),
		"R23 interior/cut frames can pass without projected and live-readable defining repair")
	assert_true(source.contains("OLD-QUARRY-TERRACE-R25")
		and not source.contains("OLD-QUARRY-TERRACE-R22"),
		"fresh R25 composition evidence can overwrite or be confused with R22")
	assert_true(source.contains("REQUIRED_FRAME_LABELS")
		and source.contains("_require_exact_frame_set(records, failures)")
		and source.contains("_worked_cut_receipt(world)")
		and source.contains('geometry_receipt.get("piece_count", 0)')
		and source.contains("_camera_facing_mesh_samples")
		and source.contains("mesh_instance.to_local(camera.global_position)")
		and source.contains("mesh_instance.to_global(local_point + toward_camera)"),
		"R23 capture can pass without exactly 8/8 frames and actual live mesh-surface proof")
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
	assert_true(source.contains('"back": 3.75')
		and source.contains('"up": 3.4')
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
