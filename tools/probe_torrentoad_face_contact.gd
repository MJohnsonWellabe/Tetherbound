extends SceneTree

## Attribution-only Torrentoad fixture. It freezes the installed attack clip at
## the already-reviewed low pose and captures matched appearance and UV evidence.
## It does not alter the model, animation, texture, import or production material.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUTPUT := "res://.artifacts/torrentoad-face-contact-0909/captures"
const SIZE := Vector2i(1280, 800)
const LOW_POSE_SECONDS := 0.3125
const FACE_FRACTION := Rect2(0.17, 0.07, 0.66, 0.43)
const GROUND_EPSILON := 0.001
const EXPECTED_ALBEDO := "res://assets/creatures/tetherbound/torrentoad/models/torrentoad_extracted_base_color_vivid.png"

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _body: CharacterBody3D
var _player: AnimationPlayer
var _records: Array[Dictionary] = []
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_build_stage()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	_body = CREATURE_SCENE.instantiate() as CharacterBody3D
	if _body == null:
		_failures.append("creature scene did not instantiate as CharacterBody3D")
		await _finish()
		return
	_body.set_script(BODY)
	_world.add_child(_body)
	_body.set_physics_process(false)
	_body.call("setup", "water_torrentoad", false)
	_body.rotation.y = deg_to_rad(25.0)
	var identity := _active_model_identity()
	if not bool(identity.get("valid", false)):
		_failures.append("water_torrentoad did not resolve the installed textured Torrentoad model: %s" % identity)
		await _finish()
		return
	_player = _animation_player(_body)
	if _player == null or not _player.has_animation("attack"):
		_failures.append("installed Torrentoad attack animation unavailable")
		await _finish()
		return

	_player.play("idle")
	_player.seek(0.0, true)
	_player.pause()
	await _capture("rest-appearance.png", "rest_appearance")
	await RenderingServer.frame_post_draw
	_records[-1]["deformed_pose"] = _measure_deformed_pose()

	_player.play("attack")
	_player.seek(LOW_POSE_SECONDS, true)
	_player.pause()
	await _capture("low-appearance.png", "low_appearance")
	await RenderingServer.frame_post_draw
	_records[-1]["deformed_pose"] = _measure_deformed_pose()
	await _finish()


func _active_model_identity() -> Dictionary:
	var model := _body.get_node_or_null("Model") as Node3D
	if model == null:
		return {"valid":false, "reason":"Model node unavailable"}
	var surfaces: Array[Dictionary] = []
	for child: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in instance.mesh.get_surface_count():
			var active := instance.get_active_material(surface) as BaseMaterial3D
			if active != null and active.albedo_texture != null:
				surfaces.append({"node":str(model.get_path_to(instance)), "surface":surface, "albedo":active.albedo_texture.resource_path})
	var matching := surfaces.filter(func(fact: Dictionary) -> bool: return fact.albedo == EXPECTED_ALBEDO)
	return {"valid":not matching.is_empty(), "expected_albedo":EXPECTED_ALBEDO, "textured_surfaces":surfaces}


func _capture(filename: String, kind: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := _viewport.get_texture().get_image()
	var error: Error = OK
	if image == null or image.is_empty():
		error = ERR_CANT_ACQUIRE_RESOURCE
		_failures.append("%s returned no image" % filename)
	elif image.get_size() != SIZE:
		error = ERR_INVALID_DATA
		_failures.append("%s expected %s; got %s" % [filename, SIZE, image.get_size()])
	else:
		error = image.save_png(ProjectSettings.globalize_path(OUTPUT.path_join(filename)))
		if error != OK:
			_failures.append("%s save error %s" % [filename, error])
	_records.append({
		"kind": kind,
		"file": filename,
		"save_error": error,
		"body_root_y": _body.global_position.y,
		"model_root_y": (_body.get_node("Model") as Node3D).global_position.y,
		"animation": _player.assigned_animation,
		"animation_position": _player.current_animation_position,
	})


func _measure_deformed_pose() -> Dictionary:
	var vertices: Array[Dictionary] = []
	var surfaces: Array[Dictionary] = []
	var model := _body.get_node("Model") as Node3D
	for child: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
			continue
		var qualifying_surfaces: Array[int] = []
		for source_surface: int in instance.mesh.get_surface_count():
			var source_material := instance.get_active_material(source_surface) as BaseMaterial3D
			if source_material != null and source_material.albedo_texture != null:
				qualifying_surfaces.append(source_surface)
		if qualifying_surfaces.is_empty():
			continue
		var baked := instance.bake_mesh_from_current_skeleton_pose()
		if baked == null:
			_failures.append("%s could not bake current skeleton pose" % model.get_path_to(instance))
			continue
		for surface: int in qualifying_surfaces:
			if surface >= baked.get_surface_count():
				_failures.append("%s baked surface %s unavailable" % [model.get_path_to(instance), surface])
				continue
			var active := instance.get_active_material(surface) as BaseMaterial3D
			var arrays := baked.surface_get_arrays(surface)
			var positions := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
			if positions.is_empty() or uvs.size() != positions.size():
				_failures.append("%s surface %s lacks one UV per baked vertex" % [model.get_path_to(instance), surface])
				continue
			surfaces.append({
				"node": str(model.get_path_to(instance)),
				"surface": surface,
				"source_albedo": active.albedo_texture.resource_path,
				"source_filter": int(active.texture_filter),
				"vertices": positions.size(),
				"source_blend_shape_count": instance.mesh.get_blend_shape_count(),
				"skin_available": instance.skin != null,
				"skeleton_path": str(instance.skeleton),
				"skeleton_resolved": instance.get_node_or_null(instance.skeleton) is Skeleton3D,
			})
			for index: int in positions.size():
				var world_position := instance.global_transform * positions[index]
				vertices.append({"world":world_position, "uv":uvs[index], "screen":_camera.unproject_position(world_position)})
	if vertices.is_empty():
		_failures.append("no textured model vertices were baked")
		return {"available":false, "surfaces":surfaces}
	var screen_min := Vector2(INF, INF)
	var screen_max := Vector2(-INF, -INF)
	for vertex: Dictionary in vertices:
		screen_min = screen_min.min(vertex.screen)
		screen_max = screen_max.max(vertex.screen)
	var body_rect := Rect2(screen_min, screen_max - screen_min)
	var face_rect := Rect2(body_rect.position + body_rect.size * FACE_FRACTION.position, body_rect.size * FACE_FRACTION.size)
	var face_cells: Dictionary = {}
	var below_ground := 0
	vertices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a.world as Vector3).y < (b.world as Vector3).y)
	for vertex: Dictionary in vertices:
		var world_position := vertex.world as Vector3
		if world_position.y < -GROUND_EPSILON:
			below_ground += 1
		if face_rect.has_point(vertex.screen as Vector2):
			var uv := vertex.uv as Vector2
			face_cells["%02d,%02d" % [clampi(int(floor(uv.x * 64.0)), 0, 63), clampi(int(floor(uv.y * 64.0)), 0, 63)]] = true
	var lowest: Array[Dictionary] = []
	for index: int in mini(64, vertices.size()):
		var vertex := vertices[index]
		var world_position := vertex.world as Vector3
		var uv := vertex.uv as Vector2
		lowest.append({"world":[world_position.x, world_position.y, world_position.z], "uv":[uv.x, uv.y]})
	return {
		"available": true,
		"surfaces": surfaces,
		"vertex_count": vertices.size(),
		"minimum_world_y": (vertices[0].world as Vector3).y,
		"below_ground_epsilon": GROUND_EPSILON,
		"below_ground_vertex_count": below_ground,
		"lowest_vertices": lowest,
		"projected_body_rect":[body_rect.position.x, body_rect.position.y, body_rect.size.x, body_rect.size.y],
		"projected_face_rect":[face_rect.position.x, face_rect.position.y, face_rect.size.x, face_rect.size.y],
		"face_uv_cells_64x64": face_cells.keys(),
	}


func _animation_player(node: Node) -> AnimationPlayer:
	var players: Array[Node] = node.find_children("*", "AnimationPlayer", true, false)
	return null if players.is_empty() else players[0] as AnimationPlayer


func _build_stage() -> void:
	_viewport = SubViewport.new()
	_viewport.size = SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("30373b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.80)
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment_node.environment = environment
	_world.add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(-28.0), 0.0)
	sun.light_energy = 0.72
	sun.shadow_enabled = true
	_world.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 12.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("657069")
	floor.material_override = floor_material
	_world.add_child(floor)
	_camera = Camera3D.new()
	_camera.position = Vector3(3.0, 3.4, 10.0)
	_camera.fov = 42.0
	_world.add_child(_camera)
	_camera.look_at(Vector3(0.0, 1.8, 0.0), Vector3.UP)
	_camera.make_current()


func _finish() -> void:
	var manifest := {
		"complete": _failures.is_empty(),
		"species": "water_torrentoad",
		"viewport": [SIZE.x, SIZE.y],
		"low_pose_seconds": LOW_POSE_SECONDS,
		"records": _records,
		"failures": _failures,
		"limits": "Baked vertices quantify the frozen skinned pose and narrow projected-face UV cells; face-cell membership does not prove visibility or semantic eye identity.",
	}
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT.path_join("manifest.json")), FileAccess.WRITE)
	if file == null:
		push_error("cannot write Torrentoad attribution manifest")
		_viewport.queue_free()
		await process_frame
		quit(1)
		return
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("TORRENTOAD_FACE_CONTACT=%s" % JSON.stringify({"complete":manifest.complete, "records":_records.size(), "failures":_failures}))
	_viewport.queue_free()
	await process_frame
	quit(0 if manifest.complete else 1)
