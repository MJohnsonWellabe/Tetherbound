extends "res://tools/catalogue_survey.gd"
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const STAGE := Vector2(8.0, 28.0)
const LEGACY_TEXTURE := preload("res://assets/creatures/tetherbound/bramblebun/models/bramblebun_extracted_base_color_vivid.png")
var _wild: Node3D
var _bindings: Array[Dictionary] = []
func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("bramblebun world A/B requires a rendering display")
		quit(1)
		return
	_biome_id = "meadows"
	_times.assign(["day", "night"])
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output_dir = arg.trim_prefix("--output=").strip_edges()
	if _output_dir.is_empty():
		push_error("bramblebun world A/B requires a unique --output=res://... directory")
		quit(1)
		return
	for time_name: String in _times:
		for treatment: String in ["current", "legacy_control"]:
			_planned.append({"frame_id": "bramblebun__%s__%s" % [time_name, treatment],
				"time": time_name, "treatment": treatment})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	_manifest["fixture_disclosure"] = "Production Meadows world, Terrain3D, grass, WorldLook and CameraRig/Camera3D. Audit-spawned production Bramblebun on open authored terrain; movement/animation frozen. HUD hidden. Day/night clock pinned. Legacy control changes only duplicated runtime material albedo/emission textures. No gameplay/progression claim."
	_manifest["stage_xz"] = [STAGE.x, STAGE.y]
	_manifest["legacy_texture"] = LEGACY_TEXTURE.resource_path
	_write_manifest()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_finish(false)
		return
	_hide_hud()
	if not await _prepare_subject():
		_finish(false)
		return
	for row: Dictionary in _planned:
		await _capture(row)
	_restore_materials()
	_finish(_failures.is_empty() and _records.size() == _planned.size())
func _prepare_subject() -> bool:
	var director := _world.get_node_or_null(^"EncounterDirector")
	var ground := float(_world.call("ground_height_at", STAGE.x, STAGE.y))
	if director == null or is_nan(ground):
		_failures.append("production director or terrain ground is unavailable")
		return false
	_wild = director.call("spawn_wild", "bramblebun", Vector3(STAGE.x, ground, STAGE.y),
		{"name": "BramblebunWorldAB", "wander_radius": 0.0}) as Node3D
	if _wild == null:
		_failures.append("production EncounterDirector.spawn_wild returned null")
		return false
	for _frame in 8:
		await process_frame
	_wild.set_physics_process(false)
	if _wild is CharacterBody3D:
		(_wild as CharacterBody3D).velocity = Vector3.ZERO
	var anim := _animation_player(_wild)
	if anim != null:
		var clip: String = "idle" if anim.has_animation("idle") else str(anim.current_animation)
		if not clip.is_empty():
			anim.play(clip)
			anim.seek(0.2, true)
		anim.pause()
	if not _collect_materials():
		return false
	_rig.set_process(false)
	_rig.set_physics_process(false)
	# Native SpringArm child placement continues beyond script processing.
	# Detach this same camera before giving the diagnostic a fixed world pose.
	_camera.reparent(_world, true)
	_camera.top_level = true
	_camera.fov = 50.0
	var height := float(_wild.call("body_height"))
	var standoff := maxf(4.5, height * 2.6)
	var offset := Vector3(-0.68, 0.0, 0.73).normalized() * standoff
	var eye_xz := Vector2(_wild.global_position.x + offset.x, _wild.global_position.z + offset.z)
	var eye_ground := float(_world.call("ground_height_at", eye_xz.x, eye_xz.y))
	if is_nan(eye_ground):
		_failures.append("production ground is unavailable under the capture camera")
		return false
	_camera.global_position = Vector3(eye_xz.x, eye_ground + maxf(1.6, height * 0.72), eye_xz.y)
	_camera.look_at(_wild.global_position + Vector3(0.0, height * 0.48, 0.0), Vector3.UP)
	_wild.rotation.y = atan2(offset.x, offset.z)
	_camera.make_current()
	_camera.reset_physics_interpolation()
	for _frame in 24:
		await physics_frame
	_manifest["subject"] = {"path": str(_world.get_path_to(_wild)),
		"species_id": str(_wild.get("species_id")), "position": _vec3(_wild.global_position),
		"body_height_m": height, "ordinary_colourway_species": str(_wild.get("_ordinary_colourway_species"))}
	_manifest["capture_camera"] = {"source": "original production Camera3D reparented to world for fixed diagnostic framing",
		"instance_id": _camera.get_instance_id(), "fov": _camera.fov,
		"transform": _transform(_camera.global_transform)}
	_manifest["materials_current"] = _material_records()
	_manifest["lights"] = _light_records()
	_manifest["grass"] = _grass_record()
	_write_manifest()
	return true
func _collect_materials() -> bool:
	var model := _wild.get("_model") as Node
	if model == null:
		_failures.append("production Bramblebun model is missing")
		return false
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null or not mesh.is_visible_in_tree():
			continue
		for surface in mesh.mesh.get_surface_count():
			var actual := mesh.get_active_material(surface) as BaseMaterial3D
			if actual == null or actual.albedo_texture == null:
				continue
			_bindings.append({"mesh": mesh, "surface": surface,
				"original_override": mesh.get_surface_override_material(surface)})
	if _bindings.is_empty():
		_failures.append("no visible textured BaseMaterial3D was bound to Bramblebun")
		return false
	return true
func _capture(row: Dictionary) -> void:
	_restore_materials()
	var observed_clock := await _pin_time(str(row.time))
	if observed_clock.is_empty():
		return
	var legacy := str(row.treatment) == "legacy_control"
	if legacy:
		for binding: Dictionary in _bindings:
			var mesh := binding.mesh as MeshInstance3D
			var actual := mesh.get_active_material(int(binding.surface)) as BaseMaterial3D
			var control := actual.duplicate() as BaseMaterial3D
			control.albedo_texture = LEGACY_TEXTURE
			control.emission_texture = LEGACY_TEXTURE
			mesh.set_surface_override_material(int(binding.surface), control)
	for _frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var problems := CAPTURE_CHECK.problems(self, _camera, "clear", _wild)
	CAPTURE_CHECK.require(self, _camera, "clear", _wild)
	if not problems.is_empty():
		_failures.append("%s capture check: %s" % [str(row.frame_id), "; ".join(problems)])
		_restore_materials()
		return
	var path := "%s/%s.png" % [_output_dir, str(row.frame_id)]
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(path) != OK:
		_failures.append("%s image capture/save failed" % str(row.frame_id))
	else:
		var record := row.duplicate(true)
		record["file"] = path
		record["observed_clock"] = observed_clock
		record["camera_transform"] = _transform(_camera.global_transform)
		record["subject_transform"] = _transform(_wild.global_transform)
		record["bound_materials"] = _material_records()
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_records.append(record)
		print("BRAMBLEBUN WORLD A/B %s -> %s" % [str(row.frame_id), path])
	_restore_materials()
	_write_manifest()
func _restore_materials() -> void:
	for binding: Dictionary in _bindings:
		var mesh := binding.mesh as MeshInstance3D
		if mesh != null and is_instance_valid(mesh):
			mesh.set_surface_override_material(int(binding.surface), binding.original_override)
func _material_records() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for binding: Dictionary in _bindings:
		var mesh := binding.mesh as MeshInstance3D
		var material := mesh.get_active_material(int(binding.surface)) as BaseMaterial3D
		out.append({"mesh": str(_wild.get_path_to(mesh)), "surface": int(binding.surface),
			"material_id": material.get_instance_id(), "material_name": material.resource_name,
			"albedo_texture": material.albedo_texture.resource_path if material.albedo_texture != null else "",
			"emission_texture": material.emission_texture.resource_path if material.emission_texture != null else "",
			"albedo_rgba": [material.albedo_color.r, material.albedo_color.g,
				material.albedo_color.b, material.albedo_color.a], "roughness": material.roughness,
			"metallic": material.metallic, "emission_enabled": material.emission_enabled,
			"emission_energy": material.emission_energy_multiplier})
	return out
func _light_records() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for child in _world.find_children("*", "DirectionalLight3D", true, false):
		var light := child as DirectionalLight3D
		out.append({"path": str(_world.get_path_to(light)), "visible": light.is_visible_in_tree(),
			"energy": light.light_energy, "color": light.light_color.to_html(true)})
	return out
func _grass_record() -> Dictionary:
	var grass := _world.get_node_or_null(^"GrassField")
	return {"present": grass != null, "instance_id": grass.get_instance_id() if grass != null else 0,
		"ring_instances": int(grass.get("_ring_instances")) if grass != null else 0,
		"camera_id": (grass.get("_camera") as Node).get_instance_id() if grass != null and grass.get("_camera") is Node else 0}
func _hide_hud() -> void:
	var hidden: Array[String] = []
	for child in _world.find_children("*", "CanvasLayer", true, false):
		(child as CanvasLayer).visible = false
		hidden.append(str(_world.get_path_to(child)))
	_manifest["hidden_canvas_layers"] = hidden
func _animation_player(node: Node) -> AnimationPlayer:
	var found := node.find_children("*", "AnimationPlayer", true, false)
	return null if found.is_empty() else found[0] as AnimationPlayer
