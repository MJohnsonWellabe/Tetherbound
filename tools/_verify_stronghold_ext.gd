extends SceneTree

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/t1arch"
const SETTLE_FRAMES := 90

func _init() -> void:
	_run()

func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)

func _run() -> void:
	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_hide_canvas_layers(root)
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := Vector2(-357.0 + 900.0, 2610.0 + 900.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var stronghold: Node3D = world.get_node_or_null(^"Stronghold") as Node3D
	var outer_z: float = float(stronghold.call("_mouth_outer_z"))
	var torch := OmniLight3D.new()
	torch.visible = false
	world.add_child(torch)

	var ramp_local_eye: Vector3 = stronghold.to_global(Vector3(0.0, 0.0, outer_z - 24.0))
	var rey := float(world.call("ground_height_at", ramp_local_eye.x, ramp_local_eye.z))
	var ramp_eye := Vector3(ramp_local_eye.x, rey + 1.7, ramp_local_eye.z)
	var ramp_target: Vector3 = stronghold.to_global(Vector3(0.0, 4.0, outer_z + 6.0))
	await _shoot(camera, look, ramp_eye, ramp_target, "S-ext-01-approach-ramp-foot")

	var flank_local: Vector3 = stronghold.to_global(Vector3(-40.0, 0.0, outer_z - 10.0))
	var fey := float(world.call("ground_height_at", flank_local.x, flank_local.z))
	var flank_eye := Vector3(flank_local.x, fey + 1.7, flank_local.z)
	var flank_target: Vector3 = stronghold.to_global(Vector3(0.0, 5.0, outer_z + 10.0))
	await _shoot(camera, look, flank_eye, flank_target, "S-ext-02-flank-wide")

	quit(0)

func _shoot(camera: Camera3D, look: Node, eye: Vector3, target: Vector3, name_value: String) -> void:
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	for i in 8:
		await physics_frame
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name_value]
	image.save_png(path)
	print("  %-28s -> %s" % [name_value, path])
