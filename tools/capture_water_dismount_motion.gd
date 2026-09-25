extends SceneTree

## Motion receipt for the rider's state across a real Water dismount (F12,
## ROADMAP Phase 4 step 20), through the production player, Aquaryn mount,
## RidingController, CameraRig and HUD. Rides out from the lesson beach to deep
## water, returns toward the shore (still MOUNTED), dismounts between the human
## exit and entry depths and swims ashore; one frame every 2.5 s into a 4x4
## contact sheet, each labelled with the rider's aquatic mode in the log.
##
## Disclosed fixture: a saddled owned Aquaryn and the personal Swim Stone fact.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/capture_water_dismount_motion.gd -- --sheet=<png>

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INTERVAL_S := 2.5
const FRAMES := 16
const MODES := ["LAND", "HUMAN", "MOUNTED", "PAUSED"]

var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var riding: Node
var frames: Array[Image] = []
var labels: Array[String] = []
var elapsed := 0.0
var next_shot := 0.0
var recording := false


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
	game.local.flags.set_flag("water_swim_stone_earned")
	game.local.flags.set_flag("water_swim_saddle_recipe_taught")
	game.local.inventory.add("swim_saddle", 1)
	game.local.party.add(SPECIES.spawn("water_aquaryn"))
	world = WORLD.instantiate() as Node3D
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
	riding = world.get_node(^"RidingController")
	var director: Node = world.get_node(^"EncounterDirector")
	var config: Dictionary = world.get("config")
	var lesson: Dictionary = config.swim_lesson
	var start: Array = config.anchors.filter(func(row: Dictionary) -> bool:
		return str(row.id) == str(lesson.start_anchor))[0].safe_position
	var shore := Vector3(float(start[0]), 0.0, float(start[2]))
	shore.y = float(world.call("ground_height_at", shore.x, shore.z)) + 0.2
	player.global_position = shore
	for _frame in 30:
		await physics_frame
	director.summon_active_creature()
	for _frame in 30:
		await physics_frame
	riding.call("mount")
	recording = true
	await _ride(_spot_with_depth(4.0), 12.0)
	await _ride(_spot_with_depth(1.25), 11.0)
	riding.call("dismount")
	labels.append("dismount@%.2fm->%s" % [float(world.call("water_depth_at", player.global_position)), MODES[int(player.get("swim_controller").state.mode)]])
	await _swim(shore, 16.0)
	var sheet_path := _arg("sheet")
	var width := frames[0].get_width() / 2
	var height := frames[0].get_height() / 2
	var sheet := Image.create(width * 4, height * 4, false, Image.FORMAT_RGB8)
	for index in frames.size():
		var small := frames[index].duplicate() as Image
		small.resize(width, height, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(small, Rect2i(0, 0, width, height), Vector2i((index % 4) * width, (index / 4) * height))
	var target := sheet_path if sheet_path.begins_with("/") else ProjectSettings.globalize_path(sheet_path)
	sheet.save_png(target)
	print("DISMOUNT MOTION OK frames=%d seconds=%.1f labels=%s" % [frames.size(), elapsed, ",".join(labels)])
	quit(0)


func _ride(target: Vector3, seconds: float) -> void:
	await _steer(func() -> Vector3: return riding.call("mount_body").global_position, target, seconds)


func _swim(target: Vector3, seconds: float) -> void:
	await _steer(func() -> Vector3: return player.global_position, target, seconds)


func _steer(position: Callable, target: Vector3, seconds: float) -> void:
	var spent := 0.0
	while spent < seconds:
		var offset: Vector3 = target - position.call()
		offset.y = 0.0
		if offset.length() <= 0.8:
			_action(false)
		else:
			camera.set("yaw", atan2(-offset.x, -offset.z))
			_action(true)
		await physics_frame
		var step := 1.0 / float(Engine.physics_ticks_per_second)
		spent += step
		elapsed += step
		if recording and elapsed >= next_shot and frames.size() < FRAMES:
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			image.convert(Image.FORMAT_RGB8)
			frames.append(image)
			var mode := int(player.get("swim_controller").state.mode)
			labels.append("%.1fs:%s:%s" % [elapsed, MODES[mode], "riding" if bool(riding.call("is_mounted")) else "on-foot"])
			next_shot += INTERVAL_S
	_action(false)


func _spot_with_depth(target: float) -> Vector3:
	var lesson: Dictionary = world.get("config").swim_lesson
	var start: Array = lesson.surface_polyline[0]
	var from := Vector3(float(start[0]), 0.0, float(start[2]))
	var seaward := Vector3(from.x, 0.0, from.z).normalized()
	for step in 4000:
		var at := from + seaward * (float(step) * 0.05 - 40.0)
		if absf(float(world.call("water_depth_at", at)) - target) < 0.03:
			return at
	return from


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
