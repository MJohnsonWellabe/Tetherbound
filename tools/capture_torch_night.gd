extends SceneTree

## Owner playtest report: night is too dark, and the starting torch must
## actually illuminate the environment rather than just glow. This renders
## the SAME viewpoint at night three ways -- no torch, torch on, day for
## reference -- so the blind critic can judge whether the torch changes what
## is actually visible on the ground rather than just adding a bright dot.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_torch_night.gd
##
## Uses the real playground scene, the real Player/CameraRig and the real
## scripts/player/torch.gd -- not a synthetic stand-in -- so the frames prove
## what the shipped game actually does, not what a capture script assumes it
## does.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240

var _world: Node = null
var _player: Node = null
var _rig: Node3D = null
var _hud: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player")
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_hud = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if _player == null or _rig == null:
		printerr("no Player/CameraRig in the scene")
		quit(1)
		return

	# A fixed, repeatable pose near ground clutter (harvest nodes, vegetation)
	# rather than wherever spawn happens to be, so the frames actually show
	# something the torch would need to illuminate.
	var ground_y: float = float(_world.call("ground_height_at", 40.0, -30.0))
	_player.global_position = Vector3(40.0, ground_y + 1.0, -30.0)
	_player.velocity = Vector3.ZERO
	_rig.set("yaw", deg_to_rad(20.0))
	_rig.set("pitch", deg_to_rad(-8.0))
	for i in 20:
		await physics_frame

	var look: Node = get_first_node_in_group(&"day_cycle")
	if look == null:
		printerr("no day_cycle node (world_look.gd) in the scene")
		quit(1)
		return

	look.call("apply_time", "day")
	for i in 10:
		await physics_frame
	await _shoot("torch-00-day-reference")

	look.call("apply_time", "night")
	for i in 10:
		await physics_frame

	var torch: Node = _player.get("torch")
	if torch == null:
		printerr("Player has no torch (scripts/player/torch.gd did not attach)")
		quit(1)
		return

	print("  torch auto-on at night: %s" % str(torch.call("is_on")))
	await _shoot("torch-01-night-auto")

	Input.action_press(&"torch_toggle")
	await process_frame
	Input.action_release(&"torch_toggle")
	for i in 6:
		await process_frame
	print("  torch after manual toggle: %s" % str(torch.call("is_on")))
	await _shoot("torch-02-night-toggled-off")

	Input.action_press(&"torch_toggle")
	await process_frame
	Input.action_release(&"torch_toggle")
	for i in 6:
		await process_frame
	print("  torch after second manual toggle: %s" % str(torch.call("is_on")))
	await _shoot("torch-03-night-manual-on")

	quit(0)


func _shoot(name: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-28s no image" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])

	var height := image.get_height()
	var total := 0.0
	var count := 0
	for y in range(int(height * 0.4), height, 3):
		for x in range(0, image.get_width(), 4):
			var c := image.get_pixel(x, y)
			total += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			count += 1
	print("  %-28s lower-frame luminance %.3f -> %s/%s.png" % [
		name, total / maxf(1.0, float(count)), OUT_DIR, name
	])
