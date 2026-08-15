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
	# SF33: the two rift-dressed spokes. Two frames each — the walk-up (does
	# the pylon row read as infrastructure receding toward the seam?) and the
	# lip (do the two sides read as one severed route: dead pylon and roadbed
	# resuming across, cut conduit dangling, freight stranded both sides?).
	# Eyes ON the road (opposite shoulder from the pylon line, never inside
	# it) — the first pass stood 3m from a pylon and its cable crossed the
	# whole sky as a two-metre ribbon.
	{
		"name": "rift-river-walkup",
		"eye": Vector2(-67.7, 131.7), "eye_h": 2.6,
		"target": Vector2(-99.0, 184.0), "target_h": 2.0,
	},
	{
		"name": "rift-river-at-lip",
		"eye": Vector2(-73.6, 150.9), "eye_h": 2.8,
		"target": Vector2(-102.0, 189.0), "target_h": 2.0,
	},
	{
		"name": "rift-storm-walkup",
		"eye": Vector2(144.3, 40.2), "eye_h": 2.6,
		"target": Vector2(202.0, 51.0), "target_h": 2.0,
	},
	{
		"name": "rift-storm-at-lip",
		"eye": Vector2(164.8, 48.7), "eye_h": 3.2,
		"target": Vector2(209.8, 52.3), "target_h": 3.0,
	},
	# SF33-remainder: the other five spokes. Same discipline — walk-up plus
	# at-blocker, eyes on the road's opposite shoulder from the pylon line,
	# never within ~8m of a pylon.
	{
		# Does the live line read as one route marching INTO the slide, and
		# does the buried terminal read as hit rather than as placed?
		"name": "rift-mountain-walkup",
		"eye": Vector2(-78.6, -80.3), "eye_h": 2.6,
		"target": Vector2(-123.3, -111.1), "target_h": 3.0,
	},
	{
		# The buried pylon itself: dead, leaning with the slide, its cut
		# conduit dangling toward the mountain the line used to climb. Eye
		# further along the road than the walk-up — the first framing stood
		# where a scatter tree owned the right half of the frame.
		"name": "rift-mountain-at-slide",
		"eye": Vector2(-105.7, -100.1), "eye_h": 2.6,
		"target": Vector2(-122.8, -104.3), "target_h": 2.5,
	},
	{
		# high_pass's contrast with mountain_trail: the line is live the whole
		# climb and stops SHORT of the pile — nothing buried, nothing dead.
		"name": "rift-pass-walkup",
		"eye": Vector2(40.8, -150.4), "eye_h": 2.6,
		"target": Vector2(51.4, -191.5), "target_h": 3.5,
	},
	{
		# The terminal pylon at the foot of the fallen pass, still lit, its
		# severed conduit dangling live toward the crest. Eye near the road
		# end: from further back a scatter tree hides the pylon entirely.
		"name": "rift-pass-at-slide",
		"eye": Vector2(45.4, -174.5), "eye_h": 2.6,
		"target": Vector2(54.5, -183.0), "target_h": 2.4,
	},
	{
		# cliff_road runs the full crossing grammar over a 9m notch: does the
		# compressed version still read as one cut route, or as clutter?
		"name": "rift-cliff-walkup",
		"eye": Vector2(60.9, -20.5), "eye_h": 2.6,
		"target": Vector2(110.0, -43.0), "target_h": 2.5,
	},
	{
		# The notch: lean-in dead pylon, both dangles, live far pylon, far
		# kerb rows and gateposts on the shelf beyond. Eye back on the road,
		# not under the flank — from the first framing the frame was all
		# hillside and sky with the break itself below the bottom edge.
		# Eye back on uncarved ground (an eye nearer the lip than v=+9 sinks
		# with the rim — the heightfield is the carved one), aim DOWN INTO the
		# slot: a negative target height is what makes a 9m-deep notch in a
		# steep flank present as a gap instead of as its own far wall.
		"name": "rift-cliff-at-notch",
		"eye": Vector2(89.8, -32.8), "eye_h": 2.8,
		"target": Vector2(103.5, -38.0), "target_h": -5.0,
	},
	{
		# stone_gate, wall composition: a live line running out of road at a
		# sealed arch. Head-on-ish, the framing the spoke was sited for.
		"name": "rift-gate-walkup",
		"eye": Vector2(-158.0, 1.0), "eye_h": 2.6,
		"target": Vector2(-198.0, 0.0), "target_h": 3.5,
	},
	{
		# The last pylon short of the arch and its cut conduit dangling toward
		# the sealed opening the cable used to pass through.
		"name": "rift-gate-at-seal",
		"eye": Vector2(-184.0, 1.6), "eye_h": 2.6,
		"target": Vector2(-197.0, -2.0), "target_h": 2.8,
	},
	{
		# blighted_road, the Team Tether seal: live line walking up to the
		# faction's own wall. Do the oxblood caps and the pylons read as the
		# same author's work?
		"name": "rift-blight-walkup",
		"eye": Vector2(70.8, 147.7), "eye_h": 2.6,
		"target": Vector2(83.7, 180.0), "target_h": 3.0,
	},
	{
		# The terminus: last live pylon against the wall face, stub dangling
		# down the masonry between oxblood piers, checkpoint freight piled at
		# the wall's foot on the road.
		"name": "rift-blight-at-seal",
		"eye": Vector2(76.7, 166.8), "eye_h": 2.6,
		"target": Vector2(86.0, 178.3), "target_h": 2.2,
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
