extends SceneTree

## Forward+ production-scene foundation survey for Stormwood.
##
## Run through tools/survey.sh --stormwood <godot-binary>. This captures the
## real Stormwood scene after its own `_ready_complete` signal, with the real
## Terrain3D and installed-family forest scatter. The fixture flags only make
## the authored route reachable for a foundation view; this is not traversal
## or collision evidence.

const SCENE := "res://scenes/world/stormwood.tscn"
const DEFAULT_OUT_DIR := "res://shots/stormwood-foundation"
const SETTLE_FRAMES := 36
const POSE_FRAMES := 8

const VIEWS := [
	{"name": "01-entry", "eye": Vector2(-300.0, 220.0), "target": Vector3(-320.0, 36.0, 240.0)},
	{"name": "02-struck-sentinel", "eye": Vector2(-520.0, 350.0), "target": Vector3(-320.0, 38.0, 240.0)},
	{"name": "03-glowmoss", "eye": Vector2(-500.0, 1450.0), "target": Vector3(-380.0, 42.0, 1400.0)},
	{"name": "04-conductor", "eye": Vector2(-700.0, 2300.0), "target": Vector3(-1080.0, 105.0, 3020.0)},
	{"name": "05-crown-overlook", "eye": Vector2(160.0, 1980.0), "target": Vector3(700.0, 92.0, 2700.0)},
	{"name": "06-deepwood", "eye": Vector2(-450.0, 3960.0), "target": Vector3(-150.0, 88.0, 4460.0)},
	{"name": "07-stormheart-approach", "eye": Vector2(-310.0, 5050.0), "target": Vector3(-100.0, 145.0, 5350.0), "target_above_ground": 100.0},
	{"name": "08-treebase", "eye": Vector2(-100.0, 5300.0), "target": Vector3(-100.0, 205.0, 5470.0), "target_above_ground": 150.0},
]


func _init() -> void:
	_run.call_deferred()


func _output_dir() -> String:
	var environment_dir := OS.get_environment("STORMWOOD_SURVEY_OUT")
	if not environment_dir.is_empty():
		return environment_dir
	var args := OS.get_cmdline_args()
	for index in args.size():
		var arg := str(args[index])
		if arg.begins_with("--output="):
			return arg.trim_prefix("--output=")
		if arg == "--output" and index + 1 < args.size():
			return str(args[index + 1])
	return DEFAULT_OUT_DIR


func _run() -> void:
	var out_dir := _output_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("Stormwood survey: Game autoload is missing")
		quit(1)
		return
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	game.set("current_realm", "stormwood")
	var flags: Object = game.get("progression")
	if flags != null and flags.has_method("set_flag"):
		flags.call("set_flag", "realm_key_stormwood")
		flags.call("set_flag", "stormwood:rootgate_released")

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("Stormwood survey: could not load %s" % SCENE)
		quit(1)
		return
	var world := packed.instantiate()
	root.add_child(world)
	current_scene = world
	var ready_deadline := 900
	while ready_deadline > 0 and not bool(world.call("shell_build_complete")):
		await process_frame
		ready_deadline -= 1
	if not bool(world.call("shell_build_complete")):
		push_error("Stormwood survey: world._ready_complete did not arrive")
		quit(1)
		return

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var production_camera := world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var rig := world.get_node_or_null(^"CameraRig")
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or production_camera == null:
		push_error("Stormwood survey: production player/camera shell is missing")
		quit(1)
		return
	if hud != null:
		hud.visible = false
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	production_camera.current = false

	var camera := Camera3D.new()
	camera.name = "StormwoodSurveyCamera"
	camera.fov = production_camera.fov
	camera.near = 0.1
	camera.far = production_camera.far
	world.add_child(camera)
	camera.make_current()
	var terrain := world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var failures: Array[String] = []
	for raw_view: Variant in VIEWS:
		var view := raw_view as Dictionary
		var eye_xz: Vector2 = view["eye"]
		var target: Vector3 = view["target"]
		var ground := float(world.call("ground_height_at", eye_xz.x, eye_xz.y))
		if is_nan(ground):
			failures.append("%s: no terrain height" % view.name)
			continue
		var eye := Vector3(eye_xz.x, ground + 2.2, eye_xz.y)
		var forward := Vector3(target.x-eye.x,0,target.z-eye.z).normalized()
		var target_ground := float(world.call("ground_height_at", target.x, target.z))
		if is_nan(target_ground):
			failures.append("%s: no terrain height at target" % view.name)
			continue
		# Keep the authored horizontal framing while deriving the look height from
		# the production terrain. This prevents stale hand-authored Y values from
		# aiming above a newly composed slope or underground.
		target.y = target_ground + float(view.get("target_above_ground", 3.0))
		forward = Vector3(target.x-eye.x, target.y-eye.y, target.z-eye.z).normalized()
		var player_at := eye + forward*7.0
		player_at.y = float(world.call("ground_height_at",player_at.x,player_at.z))+0.1
		player.global_position = player_at
		player.velocity = Vector3.ZERO
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		camera.reset_physics_interpolation()
		player.reset_physics_interpolation()
		for _frame in SETTLE_FRAMES:
			await process_frame
		for _frame in POSE_FRAMES:
			await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/%s.png" % [out_dir, str(view.name)]
		if image == null or image.save_png(path) != OK:
			failures.append("%s: viewport capture failed" % view.name)
		else:
			print("STORMWOOD CAPTURE %s -> %s" % [view.name, path])

	if not failures.is_empty():
		for failure in failures:
			push_error("Stormwood survey: %s" % failure)
		quit(1)
		return
	print("STORMWOOD CAPTURE OK %d frames; Forward+ production scene; foundation views only" % VIEWS.size())
	quit(0)
