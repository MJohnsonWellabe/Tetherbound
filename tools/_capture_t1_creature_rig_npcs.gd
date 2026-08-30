extends SceneTree

## T1-CREATURE-RIG evidence render. Real playground world (the same scene
## survey.gd loads), real village_npcs.json/trainers.json placer code, real
## terrain -- not a neutral-backdrop lineup. Confirms the 15 newly-placed
## civilian/trail NPCs actually stand on the ground, clear of every wall,
## where tools/_probe_civilian_placement.gd said they would.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_creature_rig_npcs.gd
##
## Scratch/evidence tool, not wired into any test.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://ralph/reports/T1-CREATURE-RIG/shots"

const SETTLE_FRAMES := 30
const STREAM_SETTLE_FRAMES := 20
const POSE_FRAMES := 3

const VIEWS := [
	{
		"name": "01-square-inn-side",
		"eye": Vector2(-14.0, 2.0), "eye_h": 2.1,
		"target": Vector2(-2.0, -10.0), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Wilhelm/Nessa (inn), Ada (workshop yard), Old Perrin (crossroads) in one frame.",
	},
	{
		"name": "02-square-pens-side",
		"eye": Vector2(30.0, 3.0), "eye_h": 2.1,
		"target": Vector2(15.0, -18.0), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Fenn (pens), Garrick (fields), Lark, Ren (past cottage_b) in one frame.",
	},
	{
		"name": "03-trader-workshop",
		"eye": Vector2(14.0, -4.0), "eye_h": 2.0,
		"target": Vector2(9.0, 4.0), "target_h": 1.0,
		"horizon": 0.32,
		"_why": "Corin, beside the wagon.",
	},
	{
		"name": "04-young-trainer-north-field",
		"eye": Vector2(2.0, 22.0), "eye_h": 2.0,
		"target": Vector2(5.0, 15.0), "target_h": 1.0,
		"horizon": 0.32,
		"_why": "Kip, north field, clear of Bryn/Halda's own arenas.",
	},
	{
		"name": "05-rival-trainer-practice-meadow",
		"eye": Vector2(35.0, -25.0), "eye_h": 2.2,
		"target": Vector2(27.2, -29.6), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Talon, beside the Practice Meadow route.",
	},
	{
		"name": "06-wandering-trainer-pond-route",
		"eye": Vector2(-32.0, 48.0), "eye_h": 2.2,
		"target": Vector2(-38.0, 40.0), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Faye, off the Pond route.",
	},
	{
		"name": "07-lost-traveler-the-rise",
		"eye": Vector2(86.0, -28.0), "eye_h": 2.2,
		"target": Vector2(80.0, -33.0), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Tobin, past The Rise trailhead's dead end.",
	},
	{
		"name": "08-field-researcher-ranger-station",
		"eye": Vector2(-336.0, 495.0), "eye_h": 2.2,
		"target": Vector2(-343.0, 501.0), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Maren, at the empty ranger station.",
	},
	{
		"name": "09-alpha-tracker-mill-crossing",
		"eye": Vector2(-398.0, 530.0), "eye_h": 2.2,
		"target": Vector2(-390.0, 524.0), "target_h": 1.0,
		"horizon": 0.30,
		"_why": "Sorrel, by the mill crossing.",
	},
]


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

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

	var village_npcs: Node = world.get_node_or_null(^"VillageNPCs")
	var trainer_npcs: Node = world.get_node_or_null(^"Trainers")
	print("villagers placed: %s" % (str(village_npcs.call("placed")) if village_npcs != null else "NODE NOT FOUND"))
	print("trainers placed: %s" % (str(trainer_npcs.call("placed")) if trainer_npcs != null else "NODE NOT FOUND"))

	var camera := Camera3D.new()
	camera.fov = 60.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var field: RefCounted = HEIGHTFIELD.new()
	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWS:
		var view: Dictionary = entry
		var vname: String = str(view["name"])
		_pose(camera, field, view)

		for i in STREAM_SETTLE_FRAMES:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % vname)
			continue
		var flat := _flatness(image)
		var path := "%s/%s.png" % [OUT_DIR, vname]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [vname, error])
			continue
		written.append(path)
		if flat < 0.01:
			failures.append("%s: frame is almost a single flat colour (spread %.4f); nothing rendered" % [vname, flat])
		print("  %-32s spread %.3f  -> %s" % [vname, flat, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering (llvmpipe under xvfb). Frame times are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye_ground: float = field.call("height_at", eye_xz.x, eye_xz.y)
	var target_ground: float = field.call("height_at", target_xz.x, target_xz.y)
	var eye := Vector3(eye_xz.x, eye_ground + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", 0.30))),
		camera.rotation.y,
		0.0
	)


## Same formula survey.gd uses: vertical FOV 60deg here (this tool's own
## camera.fov), horizon fraction of frame height from the top.
func _pitch_for_horizon(horizon_fraction: float) -> float:
	var half_fov := deg_to_rad(60.0) * 0.5
	var offset := (0.5 - horizon_fraction) * 2.0 * half_fov
	return offset


func _flatness(image: Image) -> float:
	var w := image.get_width()
	var h := image.get_height()
	if w == 0 or h == 0:
		return 0.0
	var min_v := 1.0
	var max_v := 0.0
	var step := maxi(1, w * h / 4000)
	var count := 0
	for i in range(0, w * h, step):
		var x := i % w
		var y := i / w
		var c := image.get_pixel(x, y)
		var v := (c.r + c.g + c.b) / 3.0
		min_v = minf(min_v, v)
		max_v = maxf(max_v, v)
		count += 1
	return max_v - min_v
