extends SceneTree

## MQ1B's own blind-inspection render: the trainer standing on and walking
## up a real sloped patch of the playground, to verify apply_terrain_
## adaptation()'s sign conventions the same way MQ1A's own probe verified
## bone axes before trusting them — a render, not a derivation on paper.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_slope_test.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/slope_test"

## Found by tools/_diag scan (not committed): a real ~27deg uphill patch,
## +z is the uphill direction there, cross-slope under 0.3m over 2m.
const SLOPE_X := 65.0
const SLOPE_Z := 130.0

const SETTLE_FRAMES := 240
const PHYSICS_SETTLE := 90


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		push_error("no Player in scene")
		quit(1)
		return

	var field: RefCounted = HEIGHTFIELD.new()
	var ground := float(field.call("height_at", SLOPE_X, SLOPE_Z))
	player.global_position = Vector3(SLOPE_X, ground + 1.0, SLOPE_Z)
	player.velocity = Vector3.ZERO
	player.rotation.y = 0.0  # faces +z, the uphill direction at this spot

	var camera := Camera3D.new()
	camera.fov = 55.0
	camera.far = 500.0
	world.add_child(camera)
	camera.make_current()

	var written: Array[String] = []
	var failures: Array[String] = []

	# Frame 1: standing still on the slope, facing uphill (+z) -- idle stance
	# adaptation. apply_terrain_adaptation() runs whenever grounded, not only
	# while moving, so a stationary capsule already exercises the sign
	# convention this render exists to check: no simulated input needed, and
	# none attempted -- player_controller.gd's own _physics_process is still
	# running in this scene and would fight any velocity set here by hand.
	for i in PHYSICS_SETTLE:
		await physics_frame
	_shoot(camera, player, "01-slope-idle-uphill", written, failures)

	# Frame 2: the same spot, player turned to face DOWNHILL (yaw 180) --
	# pitch sign must flip (leaning the other way into the same physical
	# slope), which is the clearest single check that pitch tracks facing
	# rather than a fixed world direction.
	player.rotation.y = deg_to_rad(180.0)
	for i in PHYSICS_SETTLE:
		await physics_frame
	_shoot(camera, player, "02-slope-idle-downhill-facing", written, failures)

	# Frame 3: a flat-ground control shot, same character, for comparison —
	# the model must read as neutral (no residual lean) once the slope
	# probes go back to level ground.
	# The village square's own flat pad (R7.9's own probes confirmed it dead
	# flat, 0.900 with zero spread, out to 18m of its centre) -- a verified
	# flat control rather than an assumed one.
	var flat_ground := float(field.call("height_at", 12.0, -8.0))
	player.global_position = Vector3(12.0, flat_ground + 1.0, -8.0)
	player.velocity = Vector3.ZERO
	for i in PHYSICS_SETTLE:
		await physics_frame
	_shoot(camera, player, "03-flat-control", written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _shoot(camera: Camera3D, player: Node3D, name: String, written: Array[String], failures: Array[String]) -> void:
	# Side-on, far enough back to see the whole body and a stretch of ground.
	var side := Vector3(1, 0, 0)
	camera.global_position = player.global_position + side * 3.5 + Vector3(0, 1.3, 0)
	camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	for i in 10:
		await physics_frame
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	var err := image.save_png(path)
	if err != OK:
		failures.append("%s: save_png failed (%d)" % [name, err])
		return
	written.append(path)
	print("  %-24s -> %s" % [name, path])
