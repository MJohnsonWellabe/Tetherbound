extends SceneTree

## GATE-D3. Frames of Band 3 -- the river, the Old Mill Crossing, and the
## Tether Relay -- for the blind visual pass `ralph/conventions.md` requires of
## any visually load-bearing regional work.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_band3_region.gd
##
## Same shape and the same honest limits as `capture_prop_clusters.gd` and
## `capture_buildings.gd`: Compatibility renderer (D06), software rendering.
## Composition, density and silhouette are trustworthy here; fine lighting
## judgements are not, and frame times from this harness are not a performance
## measurement.
##
## WHAT THIS SHOOTS, AND WHY THESE EIGHT.
##
## Prompt 64's acceptance is about a REGION, not about a prop: "river feels
## like a major regional landmark", "Team Tether presence builds before the
## captain", "relay is a memorable compact assault, not four NPCs standing
## together". None of those can be judged from a close-up of a crate. So the
## set walks the region in the order a player does -- approach road, picket,
## relay, gorge, crossing, exit -- and deliberately includes the region's own
## longest empty stretch, because a critic who is only shown the good spots is
## being asked a different question than the one that matters.
##
## TWO CAPTURE BUGS THIS TOOL DOES NOT HAVE, and every other capture tool does.
##
## 1. The day/weather clock races a multi-viewpoint pass. `world_look.gd` and
##    `world_weather.gd` both advance in `_process`, and a settle loop plus
##    eight framed shots is minutes of game time: `apply_time("day")` called
##    once before the settle wears off, and the later frames come back in a red
##    dusk wash under whatever weather rolled. The time is pinned and BOTH
##    nodes' processing is switched off before anything is framed, and the time
##    is re-applied after -- pinning has to survive the settle, not precede it.
##
## 2. Parking the camera rig's player underground trips the water hazard.
##    `capture_prop_clusters.gd`'s convention is to drop the Player 500m below
##    the terrain to get it out of frame. `water.gd` reads a body that far
##    under as fully submerged and ramps a red drowning vignette over its grace
##    period across the whole screen. The player is parked ABOVE the terrain,
##    far off to the side of every eye in the list instead.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/band3"

const SETTLE_FRAMES := 300
const POSE_FRAMES := 4
const FOV := 70.0

## Where the Player is parked so it is out of every frame and still above
## ground. Far west of the corridor, at the region's own z.
const PLAYER_PARK := Vector2(-900.0, 3400.0)

const VIEWPOINTS := [
	{
		# The road into the region, before any of it. The question this frame
		# asks is prompt 64's transition one: does open river country read as
		# somewhere with a purpose, or as corridor between two better places?
		"name": "01-approach-road-south",
		"eye": Vector2(-60.0, 3520.0), "eye_h": 2.0,
		"target": Vector2(90.0, 3600.0), "target_h": 1.5,
	},
	{
		# `riverwatch_rest` (props.json 3000): the staging spot before Team
		# Tether ground. Does it read as a place a traveller already used?
		"name": "02-riverwatch-rest",
		"eye": Vector2(196.0, 3712.0), "eye_h": 1.7,
		"target": Vector2(211.6, 3699.2), "target_h": 1.0,
	},
	{
		# Hess on the spine road, 140m short of the site, with the checkpoint
		# crates behind him. This is the "presence builds before the captain"
		# frame -- the one the picket redesign exists for.
		"name": "03-picket-hess-on-the-road",
		"eye": Vector2(214.0, 3668.0), "eye_h": 1.8,
		"target": Vector2(252.0, 3686.0), "target_h": 1.2,
	},
	{
		# The relay from the approach: industrial intrusion arriving in a
		# natural region. Wide enough to hold the site against the country
		# around it, which is what "increasing toward the relay" has to read as.
		"name": "04-relay-from-the-approach",
		"eye": Vector2(276.0, 3706.0), "eye_h": 4.0,
		"target": Vector2(352.0, 3762.0), "target_h": 3.0,
	},
	{
		# Inside the compound, where Dell, Vance and the captive stand. Prompt
		# 64: a memorable compact assault, not four NPCs on a lawn.
		"name": "05-relay-yard",
		"eye": Vector2(330.0, 3735.0), "eye_h": 2.4,
		"target": Vector2(356.0, 3757.0), "target_h": 1.6,
	},
	{
		# The gorge, looked at ALONG its course rather than across it, because
		# a 15m trench photographed head-on reads as a ditch and its depth is
		# the whole reason it blocks the region.
		"name": "06-river-gorge-along-the-course",
		"eye": Vector2(60.0, 4150.0), "eye_h": 14.0,
		"target": Vector2(-140.0, 4204.0), "target_h": -6.0,
	},
	{
		# The Old Mill Crossing on the near bank, standing where the player
		# stops. The narrows are 3.6m of half-width here and the mill is the
		# region's one piece of village-family architecture.
		"name": "07-old-mill-crossing",
		"eye": Vector2(-152.0, 4152.0), "eye_h": 2.2,
		"target": Vector2(-152.0, 4210.0), "target_h": 1.0,
	},
	{
		# The region's own longest measured empty stretch, on the way out into
		# Band 4. Included on purpose: if the region reads bare anywhere, it
		# reads bare here, and the critic should be shown it.
		"name": "08-north-exit-dead-stretch",
		"eye": Vector2(110.0, 4670.0), "eye_h": 2.5,
		"target": Vector2(20.0, 4750.0), "target_h": 2.0,
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
	var combat_hud: CanvasLayer = world.get_node_or_null(^"CombatHUD") as CanvasLayer
	if combat_hud != null:
		combat_hud.visible = false

	# Bug 1, and the order matters: pin AFTER the settle, then stop both clocks
	# so nothing moves between frame 01 and frame 08.
	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
		look.set_physics_process(false)

	var field: RefCounted = HEIGHTFIELD.new()

	# Bug 2: above the terrain, not 500m under it.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.global_position = Vector3(
			PLAYER_PARK.x, field.height_at(PLAYER_PARK.x, PLAYER_PARK.y) + 1.0, PLAYER_PARK.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 4000.0
	world.add_child(camera)
	camera.make_current()

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var shot_name: String = str(view["name"])

		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(
			target_xz.x,
			field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]),
			target_xz.y)

		camera.global_position = eye
		camera.look_at(target, Vector3.UP)

		# Terrain3D streams collision and detail around the CAMERA, so a jump
		# of a kilometre between viewpoints needs frames to resolve before the
		# shot is of the world rather than of the world arriving.
		for i in 40:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % shot_name)
			continue

		var path := "%s/%s.png" % [OUT_DIR, shot_name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [shot_name, error])
			continue

		written.append(path)
		print("  %-34s eye(%.0f, %.0f, %.0f) -> %s" % [shot_name, eye.x, eye.y, eye.z, path])

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
