extends SceneTree

## Frames of the two EV7 prop clusters (work_area, farmhouse_yard) for the
## mandatory local blind-judge pass (conventions.md) — bible sec2 P3's test is
## "does this imply a purpose", which needs a close look at the cluster itself
## AND a wider look at it next to the landmark it belongs beside, so both are
## shot for each cluster.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_prop_clusters.gd
##
## Same shape and same honest limits as capture_buildings.gd: Compatibility
## renderer (D06), software rendering — composition and silhouette are
## trustworthy, fine lighting judgements are not.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/prop_clusters"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Kept in sync by hand with data/config/props.json and village.json, the same
## way capture_buildings.gd does — a survey tool has no business importing
## gameplay scripts' private state.
const WORK_AREA_CENTRE := Vector2(-5.0, -2.8)
const BARN_AT := Vector2(2.0, 2.0)
const FARMHOUSE_YARD_CENTRE := Vector2(-24.0, -25.4)
const HOUSE_AT := Vector2(-22.0, -16.0)

const VIEWPOINTS := [
	{
		# The work area close, at the distance you'd stop to look at it.
		# South-west of the cluster and clear of the Barn's own ~4-5m
		# footprint radius (measured: Barn.obj is 7.7x8.2m raw, 1.1 scale --
		# an earlier eye at (-0.5, 3.0) landed inside its walls).
		"name": "01-work-area-close",
		"eye": Vector2(-9.0, -6.0), "eye_h": 1.7,
		"target": WORK_AREA_CENTRE, "target_h": 1.0,
	},
	{
		# The work area next to the Barn it belongs beside — does it read as
		# one place's workshop, or a prop drop unrelated to anything nearby?
		# Round 1's eye at (6,-8) looked at the Barn's unlit far side and the
		# whole cluster crushed to near-black; this approaches from the same
		# south-west side as the close shot, which round 1 confirmed is lit.
		"name": "02-work-area-with-barn",
		"eye": Vector2(-14.0, -11.0), "eye_h": 2.0,
		"target": Vector2(-1.6, -0.4), "target_h": 2.5,
	},
	{
		# The farmhouse yard close.
		"name": "03-farmhouse-yard-close",
		"eye": Vector2(-24.0, -30.0), "eye_h": 1.7,
		"target": FARMHOUSE_YARD_CENTRE, "target_h": 0.8,
	},
	{
		# The farmhouse yard with the house itself in frame.
		"name": "04-farmhouse-yard-with-house",
		"eye": Vector2(-14.0, -30.0), "eye_h": 2.2,
		"target": Vector2(-22.0, -21.0), "target_h": 2.0,
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
