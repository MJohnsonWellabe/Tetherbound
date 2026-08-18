extends SceneTree

## NIGHT-LIGHT: does night actually render a scene, or crush to near-black.
##
## Three consecutive blind critic rounds (docs/reviews/band2/round-01..03)
## ranked night's near-total-black frames in their top three findings, and
## round 2 confirmed by moving the camera from ~85m to ~10m that it is not a
## framing problem -- the SAME viewpoints tools/survey_band2.gd already shoots
## (06-quarry-overlook-night, 07-ranger-camp-close-night) are reused here
## verbatim for direct before/after comparability with that evidence.
##
## Adds two things survey_band2.gd's own night frames cannot answer:
##   - a day frame at the SAME viewpoint, for a same-scene day/night contrast
##     tools/frame_stats.py can compare directly.
##   - a close viewpoint with the player standing in frame, torch equipped
##     and lit, to separate "the world is too dark" from "the torch isn't
##     working" -- survey_band2.gd always parks the player 5000m off camera,
##     so its own night frames say nothing about the torch either way.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_night_light.gd
##   python3 tools/frame_stats.py shots/night_light/*.png
##
## HONEST LIMITS: Compatibility renderer, software rendering (D06/D01) --
## frame times mean nothing, and this is the renderer used for every judged
## capture on this project, not necessarily what the Forward+ shipped build
## does with the same Environment values.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/night_light"

const SETTLE_FRAMES := 240
const SETTLE_AFTER_MOVE := 20
const POSE_FRAMES := 4
const FOV := 70.0

# Identical to survey_band2.gd's 02a/06 and 03/07 entries -- same eye/target/
# horizon, so a frame from here overlays the existing evidence pixel-for-pixel
# modulo whatever this pass changes in art.json.
const VIEWPOINTS := [
	{"name": "01-quarry-overlook", "eye": Vector2(350.0, 1720.0), "eye_h": 2.0,
		"target": Vector2(400.0, 1800.0), "target_h": 2.0, "horizon": 0.26},
	{"name": "02-ranger-camp-close", "eye": Vector2(-250.0, 2266.0), "eye_h": 1.8,
		"target": Vector2(-258.0, 2258.0), "target_h": 0.9, "horizon": 0.32},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

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

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	if look == null:
		push_error("no WorldLook node; cannot drive time of day")
		quit(1)
		return

	var written: Array[String] = []

	# Same viewpoint, day then night -- the direct comparison band2's own
	# evidence cannot make, since its day and night frames are different
	# places in the world.
	for view: Dictionary in VIEWPOINTS:
		_park_player(player, view)
		_pose(camera, field, view)
		for t in ["day", "night"]:
			look.call("apply_time", t)
			for i in SETTLE_AFTER_MOVE:
				await physics_frame
			for i in POSE_FRAMES:
				await process_frame
			await RenderingServer.frame_post_draw
			written.append(await _shoot("%s-%s" % [view["name"], t]))

	# The torch scenario: player in frame, night, torch equipped and forced
	# on, at the close ground-clutter pose tools/capture_torch_night.gd
	# already uses. Answers "is the torch actually lit here" independently
	# of whether the surrounding ambient is legible.
	written.append_array(await _shoot_torch_scenario(world, player, camera, field))

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering (D06/D01). Run tools/frame_stats.py on the output for numbers.")
	quit(0)


func _park_player(player: Node3D, view: Dictionary) -> void:
	if player == null:
		return
	var eye_xz: Vector2 = view["eye"]
	var far_xz := eye_xz + Vector2(5000.0, 5000.0)
	player.global_position = Vector3(far_xz.x, -500.0, far_xz.y)


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye_ground: float = field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = field.height_at(target_xz.x, target_xz.y)

	var eye := Vector3(eye_xz.x, eye_ground + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", 0.30))),
		camera.rotation.y,
		0.0
	)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _shoot_torch_scenario(world: Node, player: Node3D, camera: Camera3D, field: RefCounted) -> Array[String]:
	var out: Array[String] = []
	if player == null:
		printerr("no Player node; skipping the torch scenario")
		return out

	var look: Node = world.get_node_or_null(^"WorldLook")
	var ground_y: float = field.height_at(40.0, -30.0)
	player.global_position = Vector3(40.0, ground_y + 1.0, -30.0)
	player.velocity = Vector3.ZERO
	camera.global_position = player.global_position + Vector3(-2.0, 1.6, -2.0)
	camera.look_at(player.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	for i in SETTLE_AFTER_MOVE:
		await physics_frame

	look.call("apply_time", "night")
	for i in SETTLE_AFTER_MOVE:
		await physics_frame

	var torch: Node = player.get("torch")
	var game: Node = world.get_node_or_null(^"/root/Game")
	if torch == null or game == null:
		printerr("no torch or Game autoload; skipping the torch scenario")
		return out

	var inventory: RefCounted = game.get("inventory")
	if inventory != null:
		inventory.call("add", "torch", 1)
	game.set("equipped_tool", "torch")
	for attempt in 2:
		if bool(torch.call("is_on")):
			break
		Input.action_press(&"torch_toggle")
		await physics_frame
		await physics_frame
		Input.action_release(&"torch_toggle")
		for i in 6:
			await physics_frame

	print("  torch scenario: is_on=%s  equipped_tool=%s" %
		[str(torch.call("is_on")), str(game.get("equipped_tool"))])

	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	out.append(await _shoot("03-torch-scenario-night"))
	return out


func _shoot(name: String) -> String:
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-32s no image" % name)
		return ""
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		print("  %-32s save_png failed (%d)" % [name, error])
		return ""
	print("  %-32s -> %s" % [name, path])
	return path
