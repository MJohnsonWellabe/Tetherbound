extends SceneTree

## JUDGE-3 sec1e follow-up: re-render ONLY the den-and-guardian frame that the
## blind pass judged (`guardian-den-0830-full.png` came from
## capture_warrens_63.gd's `06-den-and-guardian` view), so the guardian
## self-light fix can be judged against a comparable frame without paying for
## the full seven-frame warrens pass. Everything scene-side is copied from
## capture_warrens_63.gd unchanged -- same settle, same weather/time freeze,
## same parked player, same carried-torch stand-in, same eye/aim -- because a
## judge can only compare frames whose only difference is the change under
## test.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_guardian_den.gd -- <out_dir>

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/guardian_den"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		push_error("no BurrowWarrens in the scene")
		quit(1)
		return

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
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
		var park := Vector2(-373.0, 2476.0) + Vector2(600.0, 600.0)
		var park_y := float(world.call("ground_height_at", park.x, park.y))
		player.global_position = Vector3(park.x, park_y + 0.2, park.y)
		player.visible = false
		player.set_physics_process(false)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	# The carried-torch stand-in, exactly as capture_warrens_63.gd rides it on
	# interior frames.
	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	world.add_child(torch)

	# View 06-den-and-guardian, verbatim: eye at cave-local (0, 33) at 1.7m,
	# aimed at the guardian's own body.
	var eye: Vector3 = warrens.to_global(Vector3(0.0, 0.0, 33.0))
	eye.y = float(warrens.call("ground_height_at", eye.x, eye.z)) + 1.7
	var target: Vector3 = warrens.to_global(Vector3(1.0, 0.0, 43.0))
	target.y = float(warrens.call("ground_height_at", target.x, target.z)) + 1.2
	var guardian: Node3D = warrens.call("guardian") as Node3D
	if guardian != null and is_instance_valid(guardian):
		target = guardian.global_position + Vector3.UP * 0.6
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	torch.global_position = eye + Vector3(0.0, 0.35, 0.0)

	for i in 20:
		await physics_frame
	if look != null:
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		quit(1)
		return
	var path := "%s/06-den-and-guardian.png" % out_dir
	if image.save_png(path) != OK:
		push_error("save_png failed for %s" % path)
		quit(1)
		return
	print("wrote %s" % path)
	print("Software rendering; composition and value read are trustworthy, fine lighting is not.")
	quit(0)
