extends SceneTree

## Diagnostic only: map the face-bearing side of ambiguous production bodies.
## Instantiates the real CreatureBody and changes only the body's world yaw.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const DEFAULT_SPECIES := ["bramblebun", "skyrill", "torrentoad", "mudsnout"]
const ANGLES := [0, 90, 180, 270]
const OUT := "res://.artifacts/broad-visual-0910/creature-orientation01/shots"


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var species_ids: Array[String] = []
	var requested := OS.get_cmdline_user_args()
	for value: String in (requested if not requested.is_empty() else DEFAULT_SPECIES):
		species_ids.append(value)
	DirAccess.make_dir_recursive_absolute(OUT)
	var world := Node3D.new()
	root.add_child(world)

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

	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()

	for species_id: String in species_ids:
		var body: Node3D = CREATURE_SCENE.instantiate()
		body.name = "Orientation_%s" % species_id
		body.set_script(BODY)
		world.add_child(body)
		body.call("setup", species_id, false)
		body.set_physics_process(false)
		var model: Node3D = body.call("model_pivot") as Node3D
		var art := model.get_child(0) as Node3D
		var bounds: AABB = RENDER_BOUNDS.measure(art)
		var material_receipts := _material_receipts(art)
		_freeze_animations(art)
		for _settle in 30:
			await process_frame

		for degrees: int in ANGLES:
			body.rotation.y = deg_to_rad(float(degrees))
			_fit_camera(camera, art, bounds)
			for _settle in 8:
				await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_viewport().get_texture().get_image()
			if image == null:
				push_error("orientation probe could not read %s at %d degrees" % [species_id, degrees])
				quit(1)
				return
			var output := "%s/%s-yaw-%03d.png" % [OUT, species_id, degrees]
			var save_error := image.save_png(output)
			if save_error != OK:
				push_error("orientation probe could not save %s: %s" % [output, error_string(save_error)])
				quit(1)
				return
			print("CREATURE_ORIENTATION species=%s body_yaw=%d body_forward=%s model_basis=%s bounds=%s materials=%s output=%s" % [
				species_id, degrees, body.global_basis.z.normalized(), model.global_basis,
				bounds, JSON.stringify(material_receipts), output])

		body.queue_free()
		await process_frame

	print("CREATURE_ORIENTATION_RESULT images=%d species=%d" % [species_ids.size() * ANGLES.size(), species_ids.size()])
	quit(0)


## Keep one three-quarter viewing direction for all orientations. A bounding
## sphere around the transformed render AABB is conservative under perspective
## and cannot crop long bodies or wings when the narrow vertical FOV is fitted.
func _fit_camera(camera: Camera3D, art: Node3D, local_bounds: AABB) -> void:
	var corners: Array[Vector3] = []
	for x in 2:
		for y in 2:
			for z in 2:
				var local_corner := local_bounds.position + Vector3(
					local_bounds.size.x * float(x),
					local_bounds.size.y * float(y),
					local_bounds.size.z * float(z))
				corners.append(art.to_global(local_corner))
	var centre := Vector3.ZERO
	for corner: Vector3 in corners:
		centre += corner
	centre /= float(corners.size())
	var radius := 0.0
	for corner: Vector3 in corners:
		radius = maxf(radius, centre.distance_to(corner))
	var half_vertical_fov := deg_to_rad(camera.fov * 0.5)
	var distance := maxf(2.0, radius / sin(half_vertical_fov) * 1.12)
	var view_direction := Vector3(0.36, 0.20, 0.93).normalized()
	camera.global_position = centre + view_direction * distance
	camera.look_at(centre, Vector3.UP)


func _freeze_animations(node: Node) -> void:
	for player: Node in node.find_children("*", "AnimationPlayer", true, false):
		var animation_player := player as AnimationPlayer
		animation_player.stop(true)
		animation_player.active = false


func _material_receipts(node: Node) -> Array[Dictionary]:
	var receipts: Array[Dictionary] = []
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		for child: Node in current.get_children():
			pending.append(child)
		if not current is MeshInstance3D:
			continue
		var instance := current as MeshInstance3D
		if instance.mesh == null or not instance.visible:
			continue
		for surface in instance.mesh.get_surface_count():
			var material := instance.get_active_material(surface) as StandardMaterial3D
			var texture_path := ""
			var albedo := Color.WHITE
			if material != null:
				albedo = material.albedo_color
				if material.albedo_texture != null:
					texture_path = material.albedo_texture.resource_path
			receipts.append({
				"mesh": str(instance.get_path()),
				"surface": surface,
				"material_id": material.get_instance_id() if material != null else 0,
				"material_name": material.resource_name if material != null else "",
				"albedo_linear": [albedo.r, albedo.g, albedo.b, albedo.a],
				"texture": texture_path,
			})
	return receipts
