extends SceneTree

## MAT-BLOCKOUT's own diagnostic capture: point-blank shots of the two
## assets the backlog item names, closer than any of `survey_band2.gd`'s
## eight fixed viewpoints go. Not a replacement for that survey -- the blind
## critique still runs against `survey_band2.gd`'s own comparable frames
## (02a/02b/04/06) -- this is the fast, cheap check for "did the material
## actually change" before spending a critic round on it: at 4-8m the
## rootstone's own texture and the Warrens wall's own texture fill enough
## of the frame that a flat colour vs. a real texture is obvious without a
## critic at all.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_mat_blockout.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/mat_blockout"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const FOV := 70.0
const DEFAULT_HORIZON := 0.30

const VIEWPOINTS := [
	{
		# Old Quarry, rootstone deposit order 12 (band2_stone_and_root/harvest.json,
		# at [394,1797], Rock_Medium_1.gltf @ 1.15) -- the specific instance a blind
		# critic called "a pale mint/seafoam... hatch-patterned surface" at 02b's
		# ~15m. Point-blank here so the retint (harvest_node.gd) is unmissable if it
		# landed and unmissable if it did not.
		"name": "rootstone-closeup-day",
		"eye": Vector2(391.0, 1793.5), "eye_h": 1.4,
		"target": Vector2(394.0, 1797.0), "target_h": 0.5,
		"time": "day", "horizon": 0.42,
	},
	{
		# Same deposit, further back at 02b's own distance/angle, for a direct
		# before/after comparison against archive/reports/docs-reviews-full/band2/round-0*/02b-*.jpg.
		"name": "rootstone-context-day",
		"eye": Vector2(390.0, 1791.0), "eye_h": 1.8,
		"target": Vector2(402.0, 1800.0), "target_h": 1.2,
		"time": "day", "horizon": 0.32,
	},
	{
		# Burrow Warrens mouth wall, walked up close -- 10m along the same
		# eye/target line round-0*/04-warrens-mouth-day.jpg used from ~42m, so
		# the flat colour was already visible at that range; this is the
		# "hand on the rock" distance for judging the texture itself.
		"name": "warrens-wall-closeup-day",
		"eye": Vector2(-412.9, 2462.9), "eye_h": 1.6,
		"target": Vector2(-420.0, 2470.0), "target_h": 2.2,
		"time": "day", "horizon": 0.40,
	},
	{
		# Same framing as round-0*/04-warrens-mouth-day.jpg, for a direct
		# before/after comparison at the review's own distance.
		"name": "warrens-mouth-context-day",
		"eye": Vector2(-390.0, 2440.0), "eye_h": 2.0,
		"target": Vector2(-420.0, 2470.0), "target_h": 2.5,
		"time": "day", "horizon": 0.28,
	},
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
	var field: RefCounted = HEIGHTFIELD.new()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		_pose(camera, field, view)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))
		else:
			failures.append("%s: no WorldLook node, time of day not applied" % name)

		for i in SETTLE_AFTER_MOVE:
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
		print("  %-28s -> %s" % [name, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

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
	var eye_ground: float = field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = field.height_at(target_xz.x, target_xz.y)

	var eye := Vector3(eye_xz.x, eye_ground + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", DEFAULT_HORIZON))),
		camera.rotation.y,
		0.0
	)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
