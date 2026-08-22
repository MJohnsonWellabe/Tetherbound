extends SceneTree

## Frames of the BAND1-D1 `trail_camp` prop cluster (data/config/bands/
## band1_lower_meadows/props.json order 1000) for the mandatory blind-judge
## pass (ralph/conventions.md) -- a new prop cluster is visual-affecting.
## Same shape as tools/capture_prop_clusters.gd: a close look ("does this
## imply a purpose") and a wider look with the spine's own bend in frame, so
## the camp reads as sited beside a real place, not dropped in open field.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_trail_camp.gd
##
## Compatibility renderer, software rendering -- composition and silhouette
## are trustworthy, fine lighting judgements are not.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/trail_camp"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Kept in sync by hand with data/config/bands/band1_lower_meadows/props.json,
## the same way capture_prop_clusters.gd does.
const CAMP_CENTRE := Vector2(348.0, 919.0)

const VIEWPOINTS := [
	{
		"name": "01-camp-close",
		"eye": Vector2(343.0, 913.0), "eye_h": 1.7,
		"target": CAMP_CENTRE, "target_h": 0.8,
	},
	{
		# From the spine itself (near the (360,910) bend), looking at the
		# camp the way a player walking the road actually would. target_h
		# lowered from 1.0 -- the first cut's shallow look angle put a lot of
		# open sky (and the sun) in frame and washed the shot out; aiming
		# lower keeps more ground/camp in frame and off the sun.
		"name": "02-camp-from-spine",
		"eye": Vector2(361.0, 908.0), "eye_h": 1.6,
		"target": CAMP_CENTRE, "target_h": 0.4,
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
			failures.append(name)
			continue

		var out_path := "%s/%s.png" % [OUT_DIR, name]
		var err := image.save_png(out_path)
		if err != OK:
			failures.append(name)
			continue
		written.append(out_path)

	for path in written:
		print("wrote %s" % path)
	for name in failures:
		push_error("failed to capture %s" % name)

	quit(0 if failures.is_empty() else 1)
