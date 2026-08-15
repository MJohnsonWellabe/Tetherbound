extends SceneTree

## R5.2's own capture harness: one representative viewpoint (survey.gd's
## "01-spawn-outward" eye/target, reused so this is judged against a frame the
## visual-judge rubric already has other frames to compare against) shot once
## per weather preset in data/config/weather.json -- clear, cloudy, fog, rain.
## survey.gd itself is deliberately not extended with a "weather" field: its
## five viewpoints are each keyed to one key-art panel and always shot at
## "clear" weather intentionally (that comparison stays meaningful only if the
## weather axis does not also move), so a purpose-built harness is the same
## choice _capture_grove_closeup.gd already made for the same reason.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_weather.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/weather"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

# Same eye/target as survey.gd's "01-spawn-outward" -- see that file for why
# this framing was chosen (clears the settlement, looks down the wayfinding
# spine toward the pond valley).
const EYE_XZ := Vector2(-9.0, -7.0)
const EYE_H := 2.2
const TARGET_XZ := Vector2(-140.0, 145.0)
const TARGET_H := 8.0
const ACTOR_XZ := Vector2(-15.0, -1.0)

const PRESETS := ["clear", "cloudy", "fog", "rain"]


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

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	var field: RefCounted = HEIGHTFIELD.new()
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D

	if look != null:
		look.call("apply_time", "day")
	# The random weather cycle would otherwise race the explicit set_weather()
	# calls below the moment its own timer fires.
	if weather != null:
		weather.set_process(false)

	if player != null:
		player.global_position = Vector3(ACTOR_XZ.x, field.height_at(ACTOR_XZ.x, ACTOR_XZ.y), ACTOR_XZ.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var eye := Vector3(EYE_XZ.x, field.height_at(EYE_XZ.x, EYE_XZ.y) + EYE_H, EYE_XZ.y)
	var target := Vector3(TARGET_XZ.x, field.height_at(TARGET_XZ.x, TARGET_XZ.y) + TARGET_H, TARGET_XZ.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)

	var written: Array[String] = []
	var failures: Array[String] = []

	for name: String in PRESETS:
		if weather != null:
			weather.call("set_weather", name)
			# The rain box re-centres on the player every _process(), which is
			# off along with the rest of WorldWeather above -- pose it once by
			# hand so a "rain" frame actually has drops around the camera's
			# subject instead of wherever the box last was.
			weather.call("_follow_player")
		else:
			failures.append("%s: no WorldWeather node, so weather is whatever the scene loaded with" % name)

		for i in 10:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue

		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue

		written.append(path)
		print("  %-8s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
