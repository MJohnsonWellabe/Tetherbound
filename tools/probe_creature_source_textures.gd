extends SceneTree

## Diagnostic only. Compare the active authored vivid repaint with the current
## installed GLB's own source texture on the exact same production body.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const IDS := ["skyrill", "torrentoad"]
const OUT := "res://.artifacts/broad-visual-0910/creature-source-control01/shots"


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(OUT)
	var world := Node3D.new()
	root.add_child(world)
	_add_lighting(world)
	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()

	for species_id: String in IDS:
		var source_scene := load("res://assets/creatures/tetherbound/%s/models/creature_%s_lod0.glb" % [species_id, species_id]) as PackedScene
		if source_scene == null:
			_fail("could not load installed source GLB for %s" % species_id)
			return
		var source_art := source_scene.instantiate() as Node3D
		world.add_child(source_art)
		source_art.visible = false
		var source_surfaces: Array[Dictionary] = _surfaces(source_art)
		if source_surfaces.size() != 1:
			_fail("%s source expected one textured surface, got %d" % [species_id, source_surfaces.size()])
			return
		var source_material := source_surfaces[0].material as BaseMaterial3D

		var body := CREATURE_SCENE.instantiate() as Node3D
		body.name = "SourceControl_%s" % species_id
		body.set_script(BODY)
		world.add_child(body)
		body.call("setup", species_id, false)
		body.set_physics_process(false)
		body.rotation.y = deg_to_rad(25.0)
		var model := body.call("model_pivot") as Node3D
		_freeze_animations(model)
		for _settle in 12:
			await process_frame
		var active_surfaces: Array[Dictionary] = _surfaces(model)
		if active_surfaces.size() != 1:
			_fail("%s body expected one textured surface, got %d" % [species_id, active_surfaces.size()])
			return
		var instance := active_surfaces[0].node as MeshInstance3D
		var surface := int(active_surfaces[0].surface)
		var active := active_surfaces[0].material as BaseMaterial3D
		var bounds: AABB = RENDER_BOUNDS.measure(model)
		var fit: Dictionary = _camera_fit(model, bounds, camera.fov)

		print("CREATURE_SOURCE_CONTROL species=%s source_albedo_id=%d source_albedo=%s source_emission_id=%d source_emission=%s active_albedo_id=%d active_albedo=%s active_emission_id=%d active_emission=%s active_emission_enabled=%s active_energy=%.6f active_albedo_linear=%s" % [
			species_id,
			_texture_id(source_material.albedo_texture), _texture_path(source_material.albedo_texture),
			_texture_id(source_material.emission_texture), _texture_path(source_material.emission_texture),
			_texture_id(active.albedo_texture), _texture_path(active.albedo_texture),
			_texture_id(active.emission_texture), _texture_path(active.emission_texture),
			active.emission_enabled, active.emission_energy_multiplier,
			[active.albedo_color.r, active.albedo_color.g, active.albedo_color.b, active.albedo_color.a]])

		await _capture_pair(camera, fit, species_id, "A-current")
		var candidate := active.duplicate() as BaseMaterial3D
		candidate.resource_name = "%s_source_control" % active.resource_name
		candidate.albedo_texture = source_material.albedo_texture
		if candidate.emission_enabled:
			candidate.emission_texture = source_material.emission_texture \
				if source_material.emission_texture != null else source_material.albedo_texture
		instance.set_surface_override_material(surface, candidate)
		print("CREATURE_SOURCE_CANDIDATE species=%s albedo_id=%d albedo=%s emission_id=%d emission=%s emission_enabled=%s energy=%.6f albedo_linear=%s" % [
			species_id, _texture_id(candidate.albedo_texture), _texture_path(candidate.albedo_texture),
			_texture_id(candidate.emission_texture), _texture_path(candidate.emission_texture),
			candidate.emission_enabled, candidate.emission_energy_multiplier,
			[candidate.albedo_color.r, candidate.albedo_color.g, candidate.albedo_color.b, candidate.albedo_color.a]])
		await _capture_pair(camera, fit, species_id, "B-source")

		body.queue_free()
		source_art.queue_free()
		await process_frame

	print("CREATURE_SOURCE_CONTROL_RESULT images=%d species=%d" % [IDS.size() * 4, IDS.size()])
	quit(0)


func _capture_pair(camera: Camera3D, fit: Dictionary, species_id: String, lane: String) -> void:
	var centre := fit.centre as Vector3
	var direction := fit.direction as Vector3
	var close_distance := float(fit.distance)
	for framing: String in ["close", "distant"]:
		var distance := close_distance if framing == "close" else close_distance * 2.7
		camera.global_position = centre + direction * distance
		camera.look_at(centre, Vector3.UP)
		for _settle in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_viewport().get_texture().get_image()
		if image == null:
			_fail("no image for %s %s %s" % [species_id, lane, framing])
			return
		var path := "%s/%s-%s-%s.png" % [OUT, species_id, lane, framing]
		var error := image.save_png(path)
		if error != OK:
			_fail("save failed for %s: %s" % [path, error_string(error)])
			return
		print("CREATURE_SOURCE_FRAME species=%s lane=%s framing=%s output=%s" % [species_id, lane, framing, path])


func _camera_fit(model: Node3D, bounds: AABB, vertical_fov: float) -> Dictionary:
	var centre := model.to_global(bounds.get_center())
	var scale := model.global_basis.get_scale().abs()
	var radius := bounds.size.length() * 0.5 * maxf(scale.x, maxf(scale.y, scale.z))
	var distance := maxf(2.0, radius / sin(deg_to_rad(vertical_fov * 0.5)) * 1.12)
	return {"centre": centre, "direction": Vector3(0.36, 0.20, 0.93).normalized(), "distance": distance}


func _surfaces(node: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		for child: Node in current.get_children():
			pending.append(child)
		if not current is MeshInstance3D:
			continue
		var instance := current as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_active_material(surface) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				found.append({"node": instance, "surface": surface, "material": material})
	return found


func _freeze_animations(node: Node) -> void:
	for found: Node in node.find_children("*", "AnimationPlayer", true, false):
		var player := found as AnimationPlayer
		player.stop(true)
		player.active = false


func _texture_id(texture: Texture2D) -> int:
	return texture.get_instance_id() if texture != null else 0


func _texture_path(texture: Texture2D) -> String:
	return texture.resource_path if texture != null else ""


func _add_lighting(world: Node3D) -> void:
	var environment := WorldEnvironment.new()
	var look := Environment.new()
	look.background_mode = Environment.BG_COLOR
	look.background_color = Color(0.42, 0.60, 0.74)
	look.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	look.ambient_light_color = Color(0.55, 0.62, 0.74)
	look.ambient_light_energy = 0.55
	look.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.environment = look
	world.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-35.0), 0.0)
	key.light_energy = 1.3
	key.light_color = Color(1.0, 0.97, 0.90)
	world.add_child(key)


func _fail(message: String) -> void:
	push_error("CREATURE_SOURCE_CONTROL failed: %s" % message)
	quit(1)
