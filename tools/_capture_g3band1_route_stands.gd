extends SceneTree

## G3-BAND1-FINISH-0904 evidence: re-render the SAME 16 stands
## GATE2-EVIDENCE-0903's blind judge stood on (ralph/reports/GATE2-EVIDENCE-0903/
## JUDGE.md), so the before/after comparison in this lane's own report is honest.
##
## The original capture lane's raw telemetry (route.csv) is git-ignored payload
## and is gone from this checkout; its own generated step-script
## (ralph/reports/GATE2-EVIDENCE-0903/run/G2C.json, COMMITTED) and its shot
## manifest (run/G2C/shots/manifest.json, COMMITTED) between them still carry
## every stand's recorded position, heading and id, which is what VIEWPOINTS
## below is built from -- not re-guessed.
##
## Same free-camera pattern tools/survey.gd and tools/_capture_*.gd already use
## (Compatibility renderer, HUD off, rig disabled): this is a WORLD-content
## comparison, not a HUD one (the HUD is a different lane's file). `look_at`
## direction is derived from `yaw_deg` with the exact convention
## `tools/gate_f/operator_harness.gd::_step_face` uses (`want =
## atan2(-dx,-dz)`), so a stand faces the same way the played route recorded it
## facing, not a guess.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/g3band1"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 6
const FOV := 70.0
const EYE_H := 1.65
const LOOK_DISTANCE := 15.0

# id, at:[x,z], yaw_deg -- from run/G2C.json's teleport/face pairs and
# run/G2C/shots/manifest.json's recorded `pos`.
const VIEWPOINTS := [
	{"name": "G2-S04-0000-region-change", "at": Vector2(0.0, 0.0), "yaw_deg": -49.0},
	{"name": "G2-S04-0206-dialogue", "at": Vector2(27.97, 7.99), "yaw_deg": -49.0},
	{"name": "G2-S04-0249-fight-starts", "at": Vector2(30.03, 6.14), "yaw_deg": -49.0},
	{"name": "G2-S04-0361-route", "at": Vector2(30.44, 6.24), "yaw_deg": -49.0},
	{"name": "G2-S04-0400-dialogue", "at": Vector2(20.25, 12.35), "yaw_deg": -49.0},
	{"name": "G2-S05-0180-route", "at": Vector2(20.25, 12.35), "yaw_deg": -49.0},
	{"name": "G2-S05-0271-route", "at": Vector2(-235.89, 295.19), "yaw_deg": -49.0},
	{"name": "G2-S05-0335-region-change", "at": Vector2(-296.76, 537.95), "yaw_deg": 0.0},
	{"name": "G2-S05-0451-route", "at": Vector2(104.15, 857.07), "yaw_deg": 0.0},
	{"name": "G2-S05-0502-fight-starts", "at": Vector2(191.08, 897.16), "yaw_deg": 0.0},
	{"name": "G2-S05-0522-level-up", "at": Vector2(191.08, 897.16), "yaw_deg": 0.0},
	{"name": "G2-S05-0578-landmark", "at": Vector2(324.41, 920.69), "yaw_deg": 0.0},
	{"name": "G2-S05-0670-landmark", "at": Vector2(14.34, 1302.1), "yaw_deg": 0.0},
	{"name": "G2-S05-0722-route", "at": Vector2(20.19, 1307.78), "yaw_deg": 0.0},
	{"name": "G2-S05-0755-objective", "at": Vector2(9.66, 1319.38), "yaw_deg": 0.0},
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
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		# The original 16 judged frames all landed at ~08:30 (pin_clock was
		# refused in that run) -- matching that hour keeps this comparison on
		# the same footing rather than introducing a lighting difference of
		# its own.
		look.call("apply_time", "day")

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	var terrain: Node = world.get_node_or_null(^"Terrain")

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		var at: Vector2 = view["at"]
		var yaw_deg: float = float(view["yaw_deg"])
		var yaw := deg_to_rad(yaw_deg)

		var ground: float = float(field.call("height_at", at.x, at.y))
		var eye := Vector3(at.x, ground + EYE_H, at.y)
		# Same convention operator_harness.gd::_step_face inverts (`want =
		# atan2(-dx,-dz)`): forward = (-sin(yaw), -cos(yaw)).
		var forward := Vector2(-sin(yaw), -cos(yaw))
		var look_xz := at + forward * LOOK_DISTANCE
		var target := Vector3(look_xz.x, ground + EYE_H, look_xz.y)

		if player != null:
			player.global_position = Vector3(at.x, ground + 0.1, at.y)
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
			if player.has_method("set_facing_yaw"):
				player.call("set_facing_yaw", yaw)
			else:
				player.rotation.y = yaw

		camera.global_position = eye
		camera.look_at(target, Vector3.UP)

		if terrain != null and terrain.has_method("set_camera"):
			terrain.call("set_camera", camera)

		for i in 30:
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
		print("  %-30s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering (Compatibility/llvmpipe). Free camera at the recorded")
	print("position/heading, HUD off, CameraRig disabled -- a world-content comparison,")
	print("not a reproduction of the original third-person gameplay camera framing.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
