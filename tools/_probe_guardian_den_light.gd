extends SceneTree

## T1-LIGHT, JUDGE-3 §1e/§3. Fast single-stand iteration rig for the
## guardian-den lighting closure -- same viewpoint and stand-in torch as
## `tools/capture_warrens_63.gd`'s `06-den-and-guardian` (so this is directly
## comparable to `guardian-den-{BEFORE,AFTER,0830}-full.png`), but only that
## one stand, so a light-tuning loop costs one ~5-8 minute world boot instead
## of the full multi-viewpoint pass every round.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_probe_guardian_den_light.gd
##   python3 tools/_sample_npc_luma.py shots/_diag/guardian-den.png   -- no,
##   use a plain rectangular sample instead (background is not flat here):
##   python3 tools/_sample_castle_wall.py shots/_diag/guardian-den.png <x> <y> <box>

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const EYE := Vector2(0.0, 33.0)
const EYE_H := 1.7
const TARGET_H := 1.2


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed: PackedScene = load(SCENE)
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

	# Stand-in torch, identical to capture_warrens_63.gd's -- the den is
	# always seen with a carried torch in play, and this is the light state
	# every committed guardian-den frame was already judged under.
	var torch := OmniLight3D.new()
	torch.light_energy = 2.6
	torch.omni_range = 12.0
	torch.light_color = Color("#ffd8a0")
	world.add_child(torch)

	var eye_world := warrens.to_global(Vector3(EYE.x, 0.0, EYE.y))
	eye_world.y = float(world.call("ground_height_at", eye_world.x, eye_world.z)) + EYE_H
	camera.global_position = eye_world
	torch.global_position = eye_world + Vector3(0.0, 0.35, 0.0)

	var guardian: Node3D = warrens.call("guardian") as Node3D
	var target := eye_world + Vector3(0, 0, 1)
	if guardian != null and is_instance_valid(guardian):
		target = guardian.global_position + Vector3.UP * 0.6
	camera.look_at(target, Vector3.UP)

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
	var path := "%s/guardian-den.png" % OUT_DIR
	image.save_png(path)
	print("guardian at %s, camera at %s -> %s" % [
		str(guardian.global_position) if guardian != null else "?", str(eye_world), path])
	quit(0)
