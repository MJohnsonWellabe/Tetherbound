extends SceneTree

## Frames of EV7-remainder's two new prop clusters (trainer_camp,
## bridge_repair_site) for the mandatory local blind-judge pass
## (conventions.md) — same shape as tools/capture_prop_clusters.gd (EV7's
## own two clusters): a close shot and an in-context-with-landmark shot for
## each, since bible sec2 P3's test is "does this imply a purpose."
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_ev7r_props.gd
##
## Same honest limits as capture_prop_clusters.gd: Compatibility renderer
## (D06), software rendering -- composition and silhouette are trustworthy,
## fine lighting judgements are not.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/ev7r_props"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Kept in sync by hand with data/config/props.json, same reasoning
## capture_prop_clusters.gd gives for not importing gameplay scripts' state.
const TRAINER_CAMP_CENTRE := Vector2(26.0, -28.0)
const BRIDGE_REPAIR_CENTRE := Vector2(-142.5, 115.5)
const FOOTBRIDGE_AT := Vector2(-136.3, 113.0)

const VIEWPOINTS := [
	{
		"name": "01-trainer-camp-close",
		"eye": Vector2(23.5, -30.0), "eye_h": 1.7,
		"target": TRAINER_CAMP_CENTRE, "target_h": 0.8,
	},
	{
		# The camp with the practice-meadow path/arena in frame -- does it
		# read as a waypoint on the way in, or clutter dropped at random?
		"name": "02-trainer-camp-with-meadow",
		"eye": Vector2(19.0, -22.0), "eye_h": 2.0,
		"target": Vector2(29.0, -34.0), "target_h": 1.0,
	},
	{
		"name": "03-bridge-repair-close",
		"eye": Vector2(-145.5, 114.5), "eye_h": 1.7,
		"target": BRIDGE_REPAIR_CENTRE, "target_h": 0.8,
	},
	{
		# The repair pile with the footbridge itself in frame -- does it
		# read as work happening beside the crossing?
		"name": "04-bridge-repair-with-bridge",
		"eye": Vector2(-146.0, 118.0), "eye_h": 2.2,
		"target": FOOTBRIDGE_AT, "target_h": 1.5,
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
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	if look != null:
		look.call("apply_time", "day")

	if player != null:
		var park: Vector2 = VIEWPOINTS[0]["eye"]
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(
			target_xz.x,
			field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]),
			target_xz.y)

		camera.global_position = eye
		camera.look_at(target, Vector3.UP)

		for i in 20:
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
		print("  %-26s -> %s" % [name, path])

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
