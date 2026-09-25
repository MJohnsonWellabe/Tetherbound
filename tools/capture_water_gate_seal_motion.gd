extends SceneTree

## Motion receipt for the closed Tidal Cradle gate (F12, WORLD §6.1) through
## the production player, swim controller, CameraRig and HUD. The trainer walks
## round the closed barrier, swims the open-water flank and steers at the
## first rest shoal with real input for about 35 s; one frame every 2.5 s goes
## into a 4x4 contact sheet. The same tool runs on main (before) and on the
## sealed branch (after); only the result differs.
##
## Disclosed fixture: the four earlier Water dock facts are set directly and
## the trainer starts on the Cradle departure anchor.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_gate_seal_motion.gd -- \
##     --sheet=<png> [--frames-dir=<dir>]

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const EARLIER := [
	"water_swim_lesson_complete",
	"water_dock_reedhaven_repaired",
	"water_dock_brine_steps_trial_won",
	"water_dock_shellwatch_residents_freed_and_pump_disabled",
]
const FLANK_BEACH := Vector3(540.0, 0.0, 1722.7)
const FLANK_WATER := Vector3(500.68, 0.0, 1750.3)
const SHOAL := Vector3(474.539, 0.0, 1795.468)
const INTERVAL_S := 2.5
const FRAMES := 16

var player: CharacterBody3D
var camera: Node3D
var frames: Array[Image] = []
var labels: Array[String] = []
var elapsed := 0.0
var next_shot := 0.0
var closest := INF


func _init() -> void:
	_run.call_deferred()


func _arg(name: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return ""


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("motion capture requires a rendering display")
		quit(1)
		return
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	for flag: String in EARLIER:
		game.world.flags.call("set_flag", flag, true)
	var world := WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
	player = world.get_node(^"Player") as CharacterBody3D
	camera = world.get_node(^"CameraRig") as Node3D
	var departure := Vector3(560.542, 0.0, 1727.776)
	departure.y = float(world.call("ground_height_at", departure.x, departure.z)) + 0.15
	player.global_position = departure
	player.velocity = Vector3.ZERO
	for _frame in 45:
		await physics_frame
	await _steer(FLANK_BEACH, 1.5, 12.0)
	await _steer(FLANK_WATER, 1.5, 20.0)
	# The recorded part: from the open-water flank toward the shoal.
	elapsed = 0.0
	next_shot = 0.0
	await _steer(SHOAL, 0.5, INTERVAL_S * float(FRAMES) + 0.5, true)
	_action(false)
	var sheet_path := _arg("sheet")
	if frames.is_empty() or sheet_path.is_empty():
		push_error("no frames or no --sheet")
		quit(1)
		return
	var width := frames[0].get_width() / 2
	var height := frames[0].get_height() / 2
	var sheet := Image.create(width * 4, height * 4, false, Image.FORMAT_RGB8)
	for index in frames.size():
		var small := frames[index].duplicate() as Image
		small.resize(width, height, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(small, Rect2i(0, 0, width, height), Vector2i((index % 4) * width, (index / 4) * height))
	var target := sheet_path if sheet_path.begins_with("/") else ProjectSettings.globalize_path(sheet_path)
	if sheet.save_png(target) != OK:
		push_error("sheet save failed: " + target)
		quit(1)
		return
	print("GATE SEAL MOTION OK frames=%d seconds=%.1f closest_to_shoal_centre_m=%.2f final=%s labels=%s" % [
		frames.size(), elapsed, closest, player.global_position, ",".join(labels)])
	quit(0)


func _steer(target: Vector3, tolerance: float, seconds: float, record := false) -> void:
	var limit := seconds
	var spent := 0.0
	while spent < limit:
		var offset := target - player.global_position
		offset.y = 0.0
		closest = minf(closest, offset.length()) if record else closest
		if offset.length() <= tolerance and not record:
			break
		camera.set("yaw", atan2(-offset.x, -offset.z))
		_action(offset.length() > tolerance)
		await physics_frame
		var step := 1.0 / float(Engine.physics_ticks_per_second)
		spent += step
		if record:
			elapsed += step
			if elapsed >= next_shot and frames.size() < FRAMES:
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				image.convert(Image.FORMAT_RGB8)
				frames.append(image)
				labels.append("%.1fs@%.1fm" % [elapsed, offset.length()])
				var dir := _arg("frames-dir")
				if not dir.is_empty():
					DirAccess.make_dir_recursive_absolute(dir)
					image.save_png("%s/motion_%02d.png" % [dir, frames.size()])
				next_shot += INTERVAL_S


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
