extends "res://tests/test_case.gd"

const SITE := preload("res://scripts/world/cloudreach_windscar_beacon_site.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CLOUDREACH_WORLD := preload("res://scripts/world/cloudreach_world.gd")
const CLOUDREACH_VISUAL_CONFIG := "res://data/config/cloudreach_visual.json"


class GroundFixture extends Node3D:
	func ground_height_at(x: float, z: float, _preferred_y: float = NAN) -> float:
		return 500.0 + (x + 260.0) * 0.018 + (z - 2680.0) * 0.012


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SITE.CONFIG_PATH))


func test_open_beacon_fits_canonical_view_and_preserves_measured_passage() -> void:
	var cfg := _config()
	assert_eq(str(cfg.landmark_id), "windscar_beacon")
	assert_eq(cfg.anchor_xz, [-260.0, 2680.0])
	assert_true(ResourceLoader.exists(str(cfg.arch_scene)))
	assert_true(ResourceLoader.exists(str(cfg.brace_scene)))
	assert_true(ResourceLoader.exists(str(cfg.signal_scene)))
	assert_almost_eq(SITE.passage_width(cfg), 8.0, 0.001)
	assert_almost_eq(SITE.passage_minimum_height(cfg), 5.8747616, 0.001)
	assert_almost_eq(float(cfg.forward_offset_m), 15.0, 0.001)
	assert_almost_eq(float((cfg.arch_scale as Array)[1]) * 3.0, 9.6, 0.001,
		"the replacement crown must fit the retained near-base gameplay view")
	var arch := (load(str(cfg.arch_scene)) as PackedScene).instantiate() as Node3D
	var bounds := RENDER_BOUNDS.measure(arch)
	assert_almost_eq(bounds.position.x, -1.0, 0.0001)
	assert_almost_eq(bounds.position.y, -0.00000011920929, 0.0001)
	assert_almost_eq(bounds.position.z, -0.0000000372529, 0.0001)
	assert_almost_eq(bounds.size.x, 2.0, 0.0001)
	assert_almost_eq(bounds.size.y, 3.0, 0.0001)
	assert_almost_eq(bounds.size.z, 0.064045727, 0.0001)
	arch.free()


func test_windscar_tree_exclusion_removes_only_the_aperture_obstruction() -> void:
	var visual_cfg: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(CLOUDREACH_VISUAL_CONFIG))
	assert_true(visual_cfg is Dictionary)
	if not visual_cfg is Dictionary:
		return
	var world := CLOUDREACH_WORLD.new()
	world.set("_visual_config", visual_cfg)
	# Runtime measurement identifies RouteTree000_4_0 at this exact position,
	# 2.867m from the beacon centre and directly inside the camera aperture.
	assert_true(bool(world.call("_inside_nature_tree_exclusion",
		Vector3(-249.3687, 497.2246, 2687.029))))
	# The next-nearest measured landmark tree is 19.07m away and must remain.
	assert_false(bool(world.call("_inside_nature_tree_exclusion",
		Vector3(-265.5821, 488.0, 2698.573))))
	var exclusions := (visual_cfg as Dictionary).get("nature", {}).get("tree_exclusions", []) as Array
	assert_eq(exclusions.size(), 1)
	assert_almost_eq(float((exclusions[0] as Dictionary).radius_m), 7.0, 0.001)
	world.free()


func test_built_beacon_grounds_four_feet_matches_solids_and_keeps_anchor_open() -> void:
	# `run_one_test.gd` discovers tests from SceneTree._init, before nodes can
	# enter the tree. Spawn one initialized child so global support contact and
	# transforms are actual engine values rather than local-transform mirrors.
	var run_id := "%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	var path := "user://windscar-beacon-child-%s.gd" % run_id
	var log_path := ProjectSettings.globalize_path("user://windscar-beacon-child-%s.log" % run_id)
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null, "initialized child runner can be written")
	if file == null:
		return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_cloudreach_windscar_beacon_site.gd").new()\n\tvar evidence = test._case_built_beacon_in_initialized_tree()\n\tprint("WINDSCAR_BEACON_RESULT=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures,"evidence":evidence}))\n\tquit(0 if test.failures.is_empty() else 1)\n')
	file.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script", ProjectSettings.globalize_path(path),
		"--log-file", log_path], output, true)
	var result: Variant = null
	var engine_errors: Array[String] = []
	var result_lines := FileAccess.get_file_as_string(log_path).split("\n") \
		if FileAccess.file_exists(log_path) else PackedStringArray()
	for line: String in result_lines:
		var clean := line.strip_edges()
		if clean.begins_with("ERROR:") or clean.begins_with("SCRIPT ERROR:"):
			engine_errors.append(clean)
		if line.begins_with("WINDSCAR_BEACON_RESULT="):
			result = JSON.parse_string(line.trim_prefix("WINDSCAR_BEACON_RESULT="))
	assert_eq(engine_errors, [], "initialized beacon child emits no engine errors")
	assert_eq(code, 0, "initialized beacon child exits cleanly")
	assert_true(result is Dictionary, "initialized beacon child returns structured evidence")
	if result is Dictionary:
		assert_eq(result.get("failures", []), [], "initialized beacon assertions pass")
		print("WINDSCAR BEACON EVIDENCE " + JSON.stringify(result.get("evidence", {})))


func _case_built_beacon_in_initialized_tree() -> Dictionary:
	var world := GroundFixture.new()
	var landmark := Node3D.new()
	landmark.position = Vector3(-260.0, 500.0, 2680.0)
	(Engine.get_main_loop() as SceneTree).root.add_child(world)
	world.add_child(landmark)
	var site := SITE.new()
	landmark.add_child(site)
	var masonry := StandardMaterial3D.new()
	site.build(world, masonry, landmark.position)
	assert_true(is_finite(site.frame_base_y()))
	var frames := 0
	var feet := 0
	var solids := 0
	var flame := 0
	var anchor := Vector3.ZERO + Vector3.UP
	var max_foot_delta := 0.0
	for child: Node in site.get_children():
		var role := str(child.get_meta("beacon_role", ""))
		if role == "arch_frame":
			frames += 1
		elif role == "terrain_foundation":
			feet += 1
			var mesh := child as MeshInstance3D
			var bottom := mesh.global_position.y - (mesh.mesh as BoxMesh).size.y * 0.5
			max_foot_delta = maxf(max_foot_delta,
				absf(bottom - (float(mesh.get_meta("sampled_ground_y")) - 0.35)))
			assert_almost_eq(bottom, float(mesh.get_meta("sampled_ground_y")) - 0.35, 0.001)
		elif role in ["arch_solid", "foundation_collision"]:
			solids += 1
			var body := child as StaticBody3D
			var shape := (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
			var local_anchor := body.transform.affine_inverse() * anchor
			assert_true(absf(local_anchor.x) > shape.size.x * 0.5 \
				or absf(local_anchor.y) > shape.size.y * 0.5 \
				or absf(local_anchor.z) > shape.size.z * 0.5,
				"a visible solid collider intrudes into the authored passage anchor")
		elif role == "signal_flame":
			flame += 1
	assert_eq(frames, 2)
	assert_eq(feet, 4)
	assert_eq(solids, 10)
	assert_eq(flame, 1)
	var cfg := _config()
	var minimum_pickup_clearance := INF
	for pickup_raw: Variant in cfg.pickup_ring_xz:
		var pickup := SITE._v2(pickup_raw) - SITE._v2(cfg.anchor_xz)
		var nearest := INF
		for child: Node in site.get_children():
			if child is not StaticBody3D or str(child.name).contains("Header"):
				continue
			var body := child as StaticBody3D
			var shape := (body.get_child(0) as CollisionShape3D).shape as BoxShape3D
			var local := body.transform.affine_inverse() * Vector3(pickup.x, body.position.y, pickup.y)
			var outside := Vector2(maxf(absf(local.x) - shape.size.x * 0.5, 0.0),
				maxf(absf(local.z) - shape.size.z * 0.5, 0.0))
			nearest = minf(nearest, outside.length())
		minimum_pickup_clearance = minf(minimum_pickup_clearance, nearest)
		assert_true(nearest > float(cfg.minimum_pickup_clearance_m),
			"an authored pickup is too close to a ground-level beacon solid")
	world.free()
	return {"frames": frames, "feet": feet, "solid_colliders": solids,
		"passage_width_m": SITE.passage_width(cfg),
		"passage_minimum_height_m": SITE.passage_minimum_height(cfg),
		"minimum_pickup_to_ground_solid_m": minimum_pickup_clearance,
		"maximum_support_contact_delta_m": max_foot_delta}
