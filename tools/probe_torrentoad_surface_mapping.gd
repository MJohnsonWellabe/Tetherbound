extends SceneTree

## Read-only geometry payload for CPU front-surface ray mapping. This remains
## separate from the tested face/contact probe and does not capture or edit images.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUTPUT := "res://.artifacts/torrentoad-surface-mapping-0909/surface-map.json"
const SIZE := Vector2i(1280, 800)
const EXPECTED_ALBEDO := "res://assets/creatures/tetherbound/torrentoad/models/torrentoad_extracted_base_color_vivid.png"
const MODEL_SOURCE := "res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb"
const ATLAS_SOURCE := "res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0_Image_0.jpg"

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_build_stage()
	var body := CREATURE_SCENE.instantiate() as CharacterBody3D
	if body == null:
		_failures.append("creature scene did not instantiate")
		await _finish({})
		return
	body.set_script(BODY)
	_world.add_child(body)
	body.set_physics_process(false)
	body.call("setup", "water_torrentoad", false)
	body.rotation.y = deg_to_rad(25.0)
	var players: Array[Node] = body.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		_failures.append("installed AnimationPlayer unavailable")
		await _finish({})
		return
	var player := players[0] as AnimationPlayer
	player.play("idle")
	player.seek(0.0, true)
	player.pause()
	await process_frame
	await RenderingServer.frame_post_draw
	var payload := _bake_payload(body)
	payload["species"] = "water_torrentoad"
	payload["animation"] = player.assigned_animation
	payload["animation_position"] = player.current_animation_position
	payload["viewport"] = [SIZE.x, SIZE.y]
	payload["camera"] = _camera_payload()
	payload["source_hashes"] = {
		MODEL_SOURCE: FileAccess.get_sha256(MODEL_SOURCE),
		ATLAS_SOURCE: FileAccess.get_sha256(ATLAS_SOURCE),
		EXPECTED_ALBEDO: FileAccess.get_sha256(EXPECTED_ALBEDO),
	}
	await _finish(payload)


func _bake_payload(body: CharacterBody3D) -> Dictionary:
	var model := body.get_node_or_null("Model") as Node3D
	if model == null:
		_failures.append("Model node unavailable")
		return {}
	var surfaces: Array[Dictionary] = []
	for child: Node in model.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
			continue
		var qualifying: Array[int] = []
		for surface: int in instance.mesh.get_surface_count():
			var active := instance.get_active_material(surface) as BaseMaterial3D
			if active != null and active.albedo_texture != null and active.albedo_texture.resource_path == EXPECTED_ALBEDO:
				qualifying.append(surface)
		if qualifying.is_empty():
			continue
		var baked := instance.bake_mesh_from_current_skeleton_pose()
		if baked == null:
			_failures.append("%s pose bake failed" % model.get_path_to(instance))
			continue
		for surface: int in qualifying:
			if surface >= baked.get_surface_count():
				_failures.append("%s baked surface %s unavailable" % [model.get_path_to(instance), surface])
				continue
			var arrays := baked.surface_get_arrays(surface)
			var positions := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var uvs := arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array
			var source_indices := arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			if positions.is_empty() or uvs.size() != positions.size():
				_failures.append("%s surface %s lacks position/UV parity" % [model.get_path_to(instance), surface])
				continue
			var world_positions: Array = []
			var uv_values: Array = []
			for index: int in positions.size():
				var world := instance.global_transform * positions[index]
				world_positions.append([world.x, world.y, world.z])
				uv_values.append([uvs[index].x, uvs[index].y])
			var indices: Array[int] = []
			if source_indices.is_empty():
				for index: int in positions.size():
					indices.append(index)
			else:
				for index: int in source_indices:
					indices.append(index)
			surfaces.append({
				"node": str(model.get_path_to(instance)),
				"surface": surface,
				"primitive": int(baked.surface_get_primitive_type(surface)),
				"active_albedo": EXPECTED_ALBEDO,
				"world_positions": world_positions,
				"uv": uv_values,
				"indices": indices,
			})
	if surfaces.size() != 1:
		_failures.append("expected one installed Torrentoad textured surface; got %s" % surfaces.size())
	return {"surfaces":surfaces}


func _camera_payload() -> Dictionary:
	var transform := _camera.global_transform
	return {
		"projection": int(_camera.projection),
		"fov": _camera.fov,
		"near": _camera.near,
		"far": _camera.far,
		"keep_aspect": int(_camera.keep_aspect),
		"basis_rows": [
			[transform.basis.x.x, transform.basis.y.x, transform.basis.z.x],
			[transform.basis.x.y, transform.basis.y.y, transform.basis.z.y],
			[transform.basis.x.z, transform.basis.y.z, transform.basis.z.z],
		],
		"origin": [transform.origin.x, transform.origin.y, transform.origin.z],
	}


func _build_stage() -> void:
	_viewport = SubViewport.new()
	_viewport.size = SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	_camera = Camera3D.new()
	_camera.position = Vector3(3.0, 3.4, 10.0)
	_camera.fov = 42.0
	_world.add_child(_camera)
	_camera.look_at(Vector3(0.0, 1.8, 0.0), Vector3.UP)
	_camera.make_current()


func _finish(payload: Dictionary) -> void:
	payload["complete"] = _failures.is_empty()
	payload["failures"] = _failures
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT), FileAccess.WRITE)
	if file == null:
		push_error("cannot write surface-map payload")
		_viewport.queue_free()
		await process_frame
		quit(1)
		return
	file.store_string(JSON.stringify(payload) + "\n")
	print("TORRENTOAD_SURFACE_MAPPING=%s" % JSON.stringify({"complete":payload.complete, "surfaces":(payload.get("surfaces", []) as Array).size(), "failures":_failures}))
	_viewport.queue_free()
	await process_frame
	quit(0 if payload.complete else 1)
