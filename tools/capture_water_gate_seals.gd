extends SceneTree

## Production-scene receipt for the closed-gate tide races (F12, WORLD §6.1).
## Fixture: the four earlier Water dock facts are set directly; the shared
## Aquaryn fact starts missing, then is set for the open control frame.
## Writes one contact sheet to the WATER-HUMAN-ROUTE report.
## Run with a real Compatibility renderer (never --headless):
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_water_gate_seals.gd

const SCENE := "res://scenes/world/water_archipelago.tscn"
const SHEET := "res://ralph/reports/WATER-HUMAN-ROUTE/_sheet_gate_seals.png"
const EARLIER := [
	"water_swim_lesson_complete",
	"water_dock_reedhaven_repaired",
	"water_dock_brine_steps_trial_won",
	"water_dock_shellwatch_residents_freed_and_pump_disabled",
]
const GATE := "water_aquaryn_resolved"
const DEPARTURE := Vector2(548.0, 1740.0)
const SHOAL := Vector2(474.539, 1795.468)
const VIEWS := [
	{"name": "closed-day", "eye": DEPARTURE, "eye_up": 3.2, "target": SHOAL, "aim_up": 0.0, "time": "day", "open": false},
	{"name": "closed-night", "eye": DEPARTURE, "eye_up": 3.2, "target": SHOAL, "aim_up": 0.0, "time": "night", "open": false},
	{"name": "closed-overview", "eye": Vector2(560.0, 1700.0), "eye_up": 70.0, "target": Vector2(440.0, 1820.0), "aim_up": 0.0, "time": "day", "open": false},
	{"name": "open-day", "eye": DEPARTURE, "eye_up": 3.2, "target": SHOAL, "aim_up": 0.0, "time": "day", "open": true},
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("gate seal capture requires a rendering display")
		quit(1)
		return
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	for flag: String in EARLIER:
		game.world.flags.call("set_flag", flag, true)
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	if not bool(world.call("shell_build_complete")):
		push_error("production Water scene did not finish building")
		quit(1)
		return
	var player := world.get_node(^"Player") as Node3D
	var look := world.get_node_or_null(^"WorldLook")
	var rig := world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	player.set_process(false)
	player.set_physics_process(false)
	for path: String in ["PlaygroundHUD"]:
		var node := world.get_node_or_null(NodePath(path))
		if node is CanvasItem:
			(node as CanvasItem).visible = false
	# Stand the player on the departure beach as the foreground scale cue.
	var stand_y := float(world.call("ground_height_at", 556.0, 1733.0))
	player.global_position = Vector3(556.0, stand_y + 0.1, 1733.0)
	var camera := Camera3D.new()
	camera.fov = 64.0
	camera.far = 2400.0
	world.add_child(camera)
	camera.make_current()
	var frames: Array[Image] = []
	for raw: Variant in VIEWS:
		var view := raw as Dictionary
		if bool(view.open):
			game.world.flags.call("set_flag", GATE, true)
		if look != null:
			look.call("apply_time", str(view.time))
			if look.has_method("set_clock_frozen"):
				look.call("set_clock_frozen", true)
			look.set_process(false)
		var eye: Vector2 = view.eye
		var target: Vector2 = view.target
		var ground := maxf(0.0, float(world.call("ground_height_at", eye.x, eye.y)))
		camera.global_position = Vector3(eye.x, ground + float(view.eye_up), eye.y)
		camera.look_at(Vector3(target.x, float(view.aim_up), target.y), Vector3.UP)
		for _frame in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			push_error("capture failed: " + str(view.name))
			quit(1)
			return
		image.convert(Image.FORMAT_RGB8)
		frames.append(image)
		print("GATE SEAL FRAME %s race_visible=%s" % [view.name,
			world.get_node("WaterGateTideRaces").call("is_race_visible", "tidal_cradle_to_salt_crown_rest_01")])
	var width := frames[0].get_width()
	var height := frames[0].get_height()
	var sheet := Image.create(width * 2, height * 2, false, Image.FORMAT_RGB8)
	for index in frames.size():
		sheet.blit_rect(frames[index], Rect2i(0, 0, width, height), Vector2i((index % 2) * width, (index / 2) * height))
	sheet.resize(width, height, Image.INTERPOLATE_LANCZOS)
	if sheet.save_png(ProjectSettings.globalize_path(SHEET)) != OK:
		push_error("sheet save failed")
		quit(1)
		return
	print("GATE SEAL CAPTURE OK frames=%d sheet=%s" % [frames.size(), SHEET])
	quit(0)
