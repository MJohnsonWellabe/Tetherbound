extends SceneTree

## Frames of the BAND1-D1 `trail_camp` prop cluster (data/config/bands/
## band1_lower_meadows/props.json order 1000) for the mandatory blind-judge
## pass (docs/AGENT_WORKFLOW.md) -- a new prop cluster is visual-affecting.
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
const CAMP_CENTRE := Vector2(344.0, 935.0)

## Round 3 reframing. The round-2 critic's sixth finding was that the trail is
## in neither frame -- "beside the trail is this location's entire premise" --
## and its reading of frame 02 was a 60%-empty grass slope. Both were true of
## the old viewpoints: 02's eye sat on the SPINE at (361,908), 14m away, while
## the road the camp actually stands beside is the loop leg
## (300,880)-(370,950), which passes 7.8m from the new camp centre. All three
## eyes below now sit on or beside that leg.
##
## The third frame is new and is the acceptance the other two cannot show: a
## camp beside a road has to be findable FROM the road before you can see
## what it is. At 23m the props are barely readable and the smoke column is
## the whole test.
const VIEWPOINTS := [
	{
		# On the camp's own approach line, just outside the two stepping
		# stones, looking across the fire at the bench and gear beyond it.
		# 3.9m out, at roughly a sitting-down eye height. The first cut of
		# this frame stood 6.6m back and at FOV 70 that put the whole camp in
		# the middle third of the image with 0.9m props reading ~50px tall --
		# which is not a close look, it is a second wide. The close frame's
		# job is the first bar question ("does this imply someone stopped
		# here"), and that needs the fire ring, the seats and the gear
		# readable as objects.
		"name": "01-camp-close",
		"eye": Vector2(346.9, 932.4), "eye_h": 1.45,
		"target": Vector2(343.6, 935.5), "target_h": 0.55,
	},
	{
		# Standing ON the loop trail 11m down-road, aimed between the road
		# ahead and the camp, so the trail runs out of the lower-left of the
		# frame and the camp sits centre-right -- the walking-past read.
		"name": "02-camp-from-spine",
		"eye": Vector2(341.7, 921.7), "eye_h": 1.6,
		"target": Vector2(346.5, 933.5), "target_h": 0.8,
	},
	{
		# 23m back down the same trail, aimed at the middle of the smoke
		# column rather than at the ground: can a player on the road tell
		# there is a camp here at all?
		"name": "03-camp-from-road",
		"eye": Vector2(334.6, 914.6), "eye_h": 1.7,
		"target": CAMP_CENTRE, "target_h": 2.5,
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

	# Freeze the day cycle, do not merely set it. `world_look.gd::_process`
	# advances a ten-minute day/night cycle in REAL time and deliberately
	# never pauses (its own comment: a clock that stops when a menu opens
	# would make every menu a free way to hold off dusk). Under xvfb software
	# GL this capture takes a minute or more of wall clock, so a single
	# apply_time() before the loop drifts across presets between viewpoints --
	# round 2 shot frame 01 in blue hour and this run shot frame 03 in
	# outright sunset, which is where the round-2 critic's "the sky says day,
	# the scene says dusk" and its whole heavy-blue-wash finding came from.
	# It named that "the largest single-lever visual gap ... and it is a
	# WorldEnvironment setting, not art". It is neither: it is this tool.
	# The D3 lane found and fixed the same class of bug in its own capture
	# tools and noted the convention was likely wrong elsewhere too. It was.
	if look != null:
		look.set_process(false)
		look.call("apply_time", "day")

	# Park the player far away ACROSS the meadow, not 500m under it. Sinking
	# the player underground is the convention these capture tools inherited
	# and it puts them below `water.gd`'s water level, which makes
	# `is_fully_submerged` true and ramps the OP21-20 full-submersion hazard
	# for the whole run. That hazard draws a full-rect red ColorRect on its
	# own CanvasLayer ("SubmersionOverlay", layer 11) which hiding
	# PlaygroundHUD does not touch, and it ESCALATES with time submerged --
	# so the later a frame is captured, the redder it is. That, not the sky,
	# is why round 3's first frame 03 came out drenched in sunset pink while
	# frame 01 looked merely cool. Belt and braces: the overlay is hidden
	# below as well, since a future viewpoint could be sited over water.
	if player != null:
		var park := Vector2(-1800.0, -1800.0)
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) + 0.5, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var submersion: CanvasLayer = world.get_node_or_null(^"Water/SubmersionOverlay") as CanvasLayer
	if submersion == null:
		submersion = _find_overlay(world)
	if submersion != null:
		submersion.visible = false

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

		# Re-asserted per viewpoint, not just once above: anything else in the
		# scene that reaches WorldLook by its group (camp rest calls
		# reset_to_morning() that way) would otherwise move the light between
		# two frames that are meant to be comparable.
		if look != null:
			look.call("apply_time", "day")

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


## The overlay is built in code by `water.gd::_build_hazard_overlay`, so its
## parent depends on where the Water node sits in whichever scene this is
## pointed at. Found by name rather than by a hard-coded path.
func _find_overlay(node: Node) -> CanvasLayer:
	if node.name == "SubmersionOverlay" and node is CanvasLayer:
		return node as CanvasLayer
	for child in node.get_children():
		var hit := _find_overlay(child)
		if hit != null:
			return hit
	return null
