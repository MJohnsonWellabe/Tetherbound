extends "res://tests/test_case.gd"

const VEGETATION_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const HEAD_VEGETATION_PATH := "res://data/config/vegetation.json"
const VEGETATION_FIXTURE_PATH := "res://tests/fixtures/band_split_baseline/vegetation.json"
const SPAWNS_PATH := "res://data/config/bands/band2_stone_and_root/spawns.json"
const PROPS_PATH := "res://data/config/bands/band2_stone_and_root/props.json"
const QUARRY := Vector2(400.0, 1800.0)
const SPINE_CORRIDORS := [
	[Vector2(310.0, 1660.0), Vector2(400.0, 1800.0)],
	[Vector2(400.0, 1800.0), Vector2(330.0, 1950.0)],
]
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


func test_old_quarry_cut_face_adds_mid_height_excavation_without_blocking_the_spine() -> void:
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
	assert_eq(pieces.size(), 6, "cut face lost its three-block wall or stepped spoil bench")
	var large_count := 0
	var small_count := 0
	var models := {}
	for raw_prop: Variant in pieces:
		assert_true(raw_prop is Dictionary, "cut-face entry is not authored prop data")
		if not raw_prop is Dictionary:
			continue
		var prop := raw_prop as Dictionary
		var model := str(prop.get("model", ""))
		models[model] = true
		assert_true(model.begins_with("Rock_Medium_"), "cut face escaped the installed rock family")
		assert_eq(str(prop.get("dir", "")), "res://assets/environment/stylized_nature",
			"cut face escaped the Meadows nature family")
		var raw_at: Array = prop.get("at", [])
		assert_eq(raw_at.size(), 2)
		if raw_at.size() != 2:
			continue
		var at := Vector2(float(raw_at[0]), float(raw_at[1]))
		var scale := float(prop.get("scale", 0.0))
		assert_true(at.distance_to(QUARRY) <= 26.0,
			"cut-face piece drifted outside the named worksite")
		if scale >= 1.8:
			large_count += 1
			for corridor: Array in SPINE_CORRIDORS:
				assert_true(_distance_to_segment(at, corridor[0], corridor[1]) >= 10.5,
					"large cut-face mass crowds the live Band 2 route")
		else:
			small_count += 1
			assert_true(scale >= 0.55 and scale <= 0.75,
				"spoil bench no longer steps down cleanly from the cut face")
	assert_eq(large_count, 3, "cut face needs exactly three readable mid-height masses")
	assert_eq(small_count, 3, "cut face needs exactly three descending spoil pieces")
	assert_eq(models.size(), 3, "cut face repeats one boulder instead of forming a varied wall")
	assert_false(JSON.stringify(face).contains("glow"),
		"abandoned quarry face should not invent another unexplained light source")
