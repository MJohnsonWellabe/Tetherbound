extends SceneTree

## SA4: the severed spokes, seen from the roads they sever.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_severed_spokes.gd
##
## Seven spokes, four blocker mechanisms. These viewpoints cover one of each
## mechanism plus the one composition question two spokes raise together:
##
##   a carve  -> river_gorge      (trench where the road crossed)
##   a pile   -> mountain_trail   (rockslide off the mountain's foot)
##   a build  -> stone_gate       (sealed arch, road runs through it)
##   a saddle -> high_pass        (does the pass read as a pass?)
##   a pair   -> cliff_road blocker beside the Rise road's trailhead, ~25m
##               apart and pointing into each other's space; SA4 stage 1
##               flagged the risk and no frame had ever been taken of both.
##
## Every eye sits ON the severed road, a walk short of the blocker, at
## roughly player eye height — the question is whether the blocker reads as a
## severed old road rather than as an arbitrary wall, and that is only
## answerable from where a player would meet it. Camera placement is
## `height_at` plus an offset, never a raycast (see playground_world.gd).
##
## Same honest limits as tools/survey.gd: Compatibility renderer, software
## rendering.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/severed-spokes"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const VIEWPOINTS := [
	{
		# river_gorge. On the River Road ~30m short of the trench, so the
		# spoke's own fingerpost (at [-84.5,166]) stands in the near-middle
		# of the frame and the far lip's broken roadbed is across the gap.
		"name": "gorge-from-river-road",
		"eye": Vector2(-80.6, 149.7), "eye_h": 2.6,
		"target": Vector2(-99.2, 187.4), "target_h": 1.0,
	},
	{
		# mountain_trail. The rockslide at the foot of rises.peaks[1], from
		# the trail, 26m out. Pile height is 5.6m so the aim sits mid-pile.
		"name": "rockslide-from-mountain-road",
		"eye": Vector2(-102.3, -95.8), "eye_h": 2.6,
		"target": Vector2(-123.3, -111.1), "target_h": 3.0,
	},
	{
		# stone_gate. Head-on down the Gate Road at the sealed arch, which is
		# the composition the spoke was sited for (level ground, straight
		# approach, nothing behind it).
		"name": "gate-from-gate-road",
		"eye": Vector2(-164.0, -1.3), "eye_h": 2.6,
		"target": Vector2(-198.0, 0.0), "target_h": 3.5,
	},
	{
		# high_pass. Up the road into the saddle between the two shoulders
		# added at [78.4,-184.2] and [24.4,-198.8]. Does it read as a pass,
		# and does anything about it read as ice?
		"name": "high-pass-saddle",
		"eye": Vector2(45.8, -162.0), "eye_h": 2.6,
		"target": Vector2(51.4, -191.5), "target_h": 3.0,
	},
	{
		# The pair. cliff_road's fallen roadbed at [102,-37.2] and the Rise
		# road's trailhead fingerpost at [75.4,-38.9] in one frame, from
		# north-west of both and slightly raised so neither hides the other.
		"name": "cliff-road-and-rise-trailhead",
		"eye": Vector2(56.0, -12.0), "eye_h": 4.0,
		"target": Vector2(100.0, -38.0), "target_h": 1.0,
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

	# No UI in these frames: the HUD is mid-rewrite elsewhere and is not the
	# subject here (same reason as tools/capture_site_shots.gd).
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

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

	# Park the player under the first viewpoint: an out-of-bounds player
	# breaks Terrain3D's region streaming for the whole run.
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
			target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
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
		print("  %-30s -> %s  (eye y=%.1f)" % [name, path, eye.y])

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
