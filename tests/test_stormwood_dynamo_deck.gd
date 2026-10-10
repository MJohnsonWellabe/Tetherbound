extends "res://tests/test_case.gd"

## The Dynamo deck the Marrow fight and the Break stand on
## (tests/smoke_stormwood_marrow_press.gd found each of these live).
const DYNAMO := preload("res://scripts/world/stormwood_dynamo.gd")
const TRAINERS := preload("res://scripts/world/stormwood_trainers.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")


func test_the_deck_floor_is_solid_only_where_the_ring_and_infill_are() -> void:
	assert_false(DYNAMO.deck_solid_at(Vector2(0, 5)), "the 9 m core hole is not floor")
	assert_false(DYNAMO.deck_solid_at(Vector2(0, 50)), "beyond the deck edge is not floor")
	assert_true(DYNAMO.deck_solid_at(Vector2(10, -20)), "Captain Marrow's seat is on solid deck")
	for bank in 4:
		var at := Vector2.RIGHT.rotated(TAU * bank / 4.0) * 35.0
		assert_true(DYNAMO.deck_solid_at(at), "conduit %d stands on solid deck" % bank)
	var gap_mid := deg_to_rad(256.0)
	assert_false(DYNAMO.deck_solid_at(Vector2.RIGHT.rotated(gap_mid) * 26.0),
		"the ascent's open band in the ring gap is not floor")
	assert_true(DYNAMO.deck_solid_at(Vector2.RIGHT.rotated(gap_mid) * 38.0), "the infill outside the band is floor")
	assert_true(DYNAMO.deck_solid_at(Vector2.RIGHT.rotated(gap_mid) * 15.0), "the infill inside the band is floor")


func test_marrow_seats_left_the_core_hole() -> void:
	for path: String in ["res://data/config/stormwood_trainers.json", "res://data/config/stormwood_npcs.json"]:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for row: Dictionary in parsed.get("trainers", parsed.get("characters", [])):
			if str(row.get("surface_id", "")) != "dynamo_core":
				continue
			var local := Vector2(float(row.position[0]) - DYNAMO.CORE_POSITION.x, float(row.position[2]) - DYNAMO.CORE_POSITION.z)
			assert_true(DYNAMO.deck_solid_at(local), "%s stands on solid Dynamo deck" % str(row.id))


func test_the_marrow_challenge_wins_its_seat_until_beaten() -> void:
	var spec := {"id": "captain_marrow_dynamo_core", "defeat_flag": "stormwood:trainer:captain_marrow_dynamo_core:defeated",
		"rechallenge": false}
	var flags := PROGRESSION_STATE.new()
	assert_eq(TRAINERS.stormwood_prompt_priority(spec, flags), 1, "the open challenge outranks the same-person NPC's greeting")
	flags.set_flag(str(spec.defeat_flag))
	assert_true(TRAINERS.stormwood_prompt_priority(spec, flags) < 0, "once beaten the NPC's own lines win the press")
	assert_eq(TRAINERS.stormwood_prompt_priority({"id": "officer_nysa_deepwood_rod",
		"defeat_flag": "stormwood:trainer:officer_nysa_deepwood_rod:defeated"}, PROGRESSION_STATE.new()), 0,
		"an ordinary trainer keeps the base priority")


var _discharge_world: Node3D
var _discharge_tree: Node3D
var _discharge_controller: Node3D
var _discharge_arena: Node3D


func _setup_discharge_fixture() -> void:
	# Called only by the deferred initialized child, after SceneTree.root exists.
	var field: RefCounted = preload("res://scripts/world/stormwood_heightfield.gd").new()
	_discharge_world = Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_discharge_world)
	assert_true(_discharge_world.is_inside_tree(), "world entered before setup")
	_discharge_tree = preload("res://scripts/world/stormheart_tree.gd").new()
	_discharge_tree.name = "StormheartTree"
	_discharge_tree.set("simulation_only", true)
	_discharge_tree.position = Vector3(DYNAMO.CORE_POSITION.x,
		float(field.call("height_at", DYNAMO.CORE_POSITION.x, DYNAMO.CORE_POSITION.z)), DYNAMO.CORE_POSITION.z)
	_discharge_world.add_child(_discharge_tree)
	assert_true(_discharge_tree.is_inside_tree(), "physical tree entered before build")
	_discharge_tree.call("build")
	_discharge_controller = DYNAMO.new()
	_discharge_world.add_child(_discharge_controller)
	_discharge_controller.set_process(false)
	assert_true(_discharge_controller.is_inside_tree(), "controller entered before global pose setup")
	_discharge_controller.set("world", _discharge_world)
	_discharge_controller.global_position = DYNAMO.CORE_POSITION
	_discharge_arena = preload("res://scripts/world/stormwood_dynamo_arena.gd").new()
	_discharge_controller.add_child(_discharge_arena)
	assert_true(_discharge_arena.is_inside_tree(), "arena entered before production build")
	var policy: RefCounted = preload("res://scripts/world/stormwood_dynamo_rules.gd").new()
	_discharge_arena.call("build", policy, false)


func _case_discharge_overlay_on_actual_physics_floor() -> void:
	# Preserve original production mesh/provider and warning invariants. The
	# initialized child also waits two physics frames before the real ray below.
	var tree: Node3D = _discharge_tree
	var controller: Node3D = _discharge_controller
	var arena: Node3D = _discharge_arena
	var physical_floor: float = controller.call("deck_height")
	var floor_shape: CollisionShape3D = null
	for child: Node in tree.get_node("DynamoCore").get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			floor_shape = child as CollisionShape3D
			break
	assert_true(floor_shape != null, "production DynamoCore physical surface is present")
	if floor_shape == null:
		return
	var highest_vertex := -INF
	for vertex: Vector3 in (floor_shape.shape as ConcavePolygonShape3D).get_faces():
		highest_vertex = maxf(highest_vertex, (floor_shape.global_transform * vertex).y)
	assert_almost_eq(physical_floor, highest_vertex, 0.0001,
		"controller height must be the actual mounted DynamoCore top faces")
	var ray_at := Vector3(DYNAMO.CORE_POSITION.x, physical_floor, DYNAMO.CORE_POSITION.z + 25.0)
	var query := PhysicsRayQueryParameters3D.create(ray_at + Vector3.UP * 2.0, ray_at - Vector3.UP * 2.0, 1)
	query.hit_back_faces = true
	var hit: Dictionary = _discharge_world.get_world_3d().direct_space_state.intersect_ray(query)
	assert_false(hit.is_empty(), "actual initialized physics world must hit the deck")
	if hit.is_empty():
		return
	assert_eq(hit.collider, tree.get_node("DynamoCore"), "independent ray hits the production core collider")
	var hit_position: Vector3 = hit.position
	assert_almost_eq(hit_position.y, physical_floor, 0.0001, "physics floor agrees with provider/top faces")
	var rows: Array = arena.get("_banks")
	var before: Array[Dictionary] = []
	for row: Dictionary in rows:
		var lane: MeshInstance3D = row.lane
		before.append({"position": lane.global_position, "rotation": lane.rotation,
			"size": (lane.mesh as PlaneMesh).size, "material": lane.material_override})
	arena.call("seat_discharge_lanes", physical_floor)
	assert_eq(rows.size(), 4, "all four production warnings remain present")
	for i in rows.size():
		var lane: MeshInstance3D = rows[i].lane
		assert_almost_eq(lane.global_position.y, highest_vertex + 0.09, 0.0001,
			"warning retains its existing clearance above the actual physical floor")
		assert_true(lane.global_position.y < DYNAMO.CORE_POSITION.y,
			"warning must lie below the fitted captive's existing zero-height contact line")
		assert_eq(Vector2(lane.global_position.x, lane.global_position.z),
			Vector2(before[i].position.x, before[i].position.z), "warning horizontal seat unchanged")
		assert_eq(lane.rotation, before[i].rotation, "bank direction unchanged")
		assert_eq((lane.mesh as PlaneMesh).size, before[i].size, "warning footprint unchanged")
		assert_eq(lane.material_override, before[i].material, "warning material and palette unchanged")
	assert_eq(controller.global_position, DYNAMO.CORE_POSITION, "authored actor/fight anchor unchanged")


func _free_discharge_fixture() -> void:
	if is_instance_valid(_discharge_world):
		_discharge_world.free()


func test_discharge_overlay_seats_on_actual_tree_floor_below_captive_origin() -> void:
	# Same entered-child pattern as test_vegetation_camera_canopy: the ordinary
	# unit runner calls synchronously from _init(), before root initialization.
	var runner_path := "user://stormwood-discharge-floor-child.gd"
	var runner := FileAccess.open(runner_path, FileAccess.WRITE)
	assert_true(runner != null, "initialized child runner is writable")
	if runner == null:
		return
	runner.store_string("""extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var test: RefCounted = load("res://tests/test_stormwood_dynamo_deck.gd").new()
	test.call("_setup_discharge_fixture")
	await physics_frame
	await physics_frame
	test.call("_case_discharge_overlay_on_actual_physics_floor")
	test.call("_case_grounded_plates_have_authored_metal_finish_and_unchanged_footprint")
	test.call("_free_discharge_fixture")
	print("DISCHARGE_FLOOR_RESULT=" + JSON.stringify({"assertions":test.get("assertion_count"), "failures":test.get("failures")}))
	quit(0 if (test.get("failures") as Array).is_empty() else 1)
""")
	runner.close()
	var output: Array = []
	var log_path := ProjectSettings.globalize_path("user://stormwood-discharge-floor-child.log")
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(runner_path), "--log-file", log_path], output, true)
	var output_text := "\n".join(output)
	var text := output_text
	if FileAccess.file_exists(log_path):
		text += "\n" + FileAccess.get_file_as_string(log_path)
	assert_eq(code, 0, "initialized child exits cleanly: " + text.right(600))
	assert_false(text.contains("ERROR:"), "raw engine/script ERROR rejects child proof: " + text.right(600))
	var marker := output_text.find("DISCHARGE_FLOOR_RESULT=")
	assert_true(marker >= 0, "child must report its completed floor receipt: " + text.right(600))
	if marker < 0:
		return
	var parsed: Variant = JSON.parse_string(output_text.substr(marker + "DISCHARGE_FLOOR_RESULT=".length()).get_slice("\n", 0))
	var result: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	assert_eq(result.get("failures", ["unparsed"]), [], "every entered production floor/overlay assertion passes")
	assert_true(int(result.get("assertions", 0)) >= 110, "child reached physics, all four warning checks and all three actual plate finish checks")


func _case_grounded_plates_have_authored_metal_finish_and_unchanged_footprint() -> void:
	var arena: Node3D = _discharge_arena
	var policy: RefCounted = arena.get("rules")
	var installed: Node3D = (load("res://assets/props/quaternius_fantasy/Bucket_Metal.gltf") as PackedScene).instantiate()
	var candidates: Array[Node] = installed.find_children("*", "MeshInstance3D", true, false)
	if installed is MeshInstance3D:
		candidates.push_front(installed)
	var authored_cap: Array[Vector2] = []
	for candidate: Node in candidates:
		var visual := candidate as MeshInstance3D
		for surface in visual.mesh.get_surface_count():
			var authored: Array = visual.mesh.surface_get_arrays(surface)
			var authored_normals: PackedVector3Array = authored[Mesh.ARRAY_NORMAL]
			var authored_uv: PackedVector2Array = authored[Mesh.ARRAY_TEX_UV]
			for vertex in authored_normals.size():
				if authored_normals[vertex].y > 0.9999 and not authored_cap.has(authored_uv[vertex]):
					authored_cap.append(authored_uv[vertex])
	assert_eq(authored_cap.size(), 12, "source cap is the actual installed twelve-sided metal UV island")
	authored_cap.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return (a - Vector2(0.8671874454, 0.8603515526)).angle() < (b - Vector2(0.8671874454, 0.8603515526)).angle())
	var authored_polygon := PackedVector2Array(authored_cap)
	installed.free()
	var plates: Array = arena.get("_plates")
	assert_eq(plates.size(), 3, "all three actual production safe plates are finished")
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = float(policy.config.plate_radius_m)
	cylinder.bottom_radius = cylinder.top_radius
	cylinder.height = 0.12
	var original: Array = cylinder.surface_get_arrays(0)
	for i in plates.size():
		var plate: MeshInstance3D = plates[i]
		var raw: Array = policy.config.plates[i]
		assert_eq(plate.position, Vector3(float(raw[0]), 0.14, float(raw[1])), "authoritative safe plate seat unchanged")
		var actual: Array = plate.mesh.surface_get_arrays(0)
		for channel: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_INDEX]:
			assert_eq(actual[channel], original[channel], "plate geometry and topology remain the original cylinder")
		var vertices: PackedVector3Array = actual[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = actual[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = actual[Mesh.ARRAY_TEX_UV]
		var cap_checked := false
		var trim_checked := false
		for j in vertices.size():
			if absf(normals[j].y) > 0.5:
				cap_checked = true
				assert_true(Geometry2D.is_point_in_polygon(uv[j], authored_polygon),
					"every cap UV stays inside the actual installed mesh's authored metal island")
			else:
				trim_checked = true
				assert_true(uv[j].y >= 0.0070266 and uv[j].y <= 0.0476038, "side UV remains in authored lip trim")
		assert_true(cap_checked and trim_checked, "both physical cap and side finish checked")
		var metal := plate.material_override as StandardMaterial3D
		assert_eq(metal.albedo_texture.resource_path, "res://assets/props/quaternius_fantasy/T_Trim_Metal_BaseColor.png")
		assert_eq(metal.normal_texture.resource_path, "res://assets/props/quaternius_fantasy/T_Trim_Metal_Normal.png")
		assert_eq(metal.roughness_texture.resource_path, "res://assets/props/quaternius_fantasy/T_Trim_Metal_ORM.png")
		assert_eq(metal.roughness_texture_channel, BaseMaterial3D.TEXTURE_CHANNEL_GREEN)
		assert_eq(metal.metallic_texture_channel, BaseMaterial3D.TEXTURE_CHANNEL_BLUE)
		assert_eq(metal.albedo_color, Color(str(policy.config.presentation.plate_surface_colour)), "warm configured finish, not a navy tint")
		assert_true(metal.normal_enabled and metal.ao_enabled, "authored PBR detail is bound")
		assert_eq(metal.ao_texture, metal.roughness_texture)
		assert_eq(metal.ao_texture_channel, BaseMaterial3D.TEXTURE_CHANNEL_RED)
		assert_almost_eq(metal.metallic, float(policy.config.presentation.plate_metallic), 0.0001)
		assert_true(metal.metallic < 0.5, "low metal still reads lit without interior reflections")
		assert_almost_eq(metal.roughness, float(policy.config.presentation.plate_roughness), 0.0001)
		var rim := plate.get_node("GroundedPlateRim") as MeshInstance3D
		var ring := TorusMesh.new()
		ring.inner_radius = cylinder.top_radius - float(policy.config.presentation.plate_rim_width_m)
		ring.outer_radius = cylinder.top_radius
		ring.rings = 48
		ring.ring_segments = 8
		var rim_arrays: Array = rim.mesh.surface_get_arrays(0)
		var original_rim: Array = ring.surface_get_arrays(0)
		assert_eq(rim_arrays[Mesh.ARRAY_VERTEX], original_rim[Mesh.ARRAY_VERTEX], "safe cue rim geometry unchanged")
		assert_eq(rim_arrays[Mesh.ARRAY_INDEX], original_rim[Mesh.ARRAY_INDEX], "safe cue rim topology unchanged")
		var cue := rim.material_override as StandardMaterial3D
		assert_eq(cue.shading_mode, BaseMaterial3D.SHADING_MODE_PER_PIXEL, "rim reads as finished metal under the existing cue")
		assert_eq(cue.albedo_texture, metal.albedo_texture)
		assert_eq(cue.albedo_color, Color("63d4b0"), "safe-ground mint palette preserved")
		assert_true(cue.emission_enabled, "safe-ground cue remains visible under every existing theme")
		assert_eq(cue.emission, Color("63d4b0"), "safe-ground emission hue preserved")
		assert_almost_eq(cue.emission_energy_multiplier, float(policy.config.presentation.plate_rim_emission), 0.0001, "safe-ground emission energy from config")
		assert_true(cue.emission_energy_multiplier > 0.0, "safe-ground cue keeps its glow")
		assert_almost_eq(cue.metallic, metal.metallic, 0.0001, "rim is the same lit metal as its plate")
