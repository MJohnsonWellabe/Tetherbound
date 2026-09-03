extends SceneTree

## GATE-D3. Frames of Band 3 -- the river, the Old Mill Crossing, and the
## Tether Relay -- for the blind visual pass `docs/AGENT_WORKFLOW.md` requires of
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
## WHAT THIS SHOOTS, AND WHY THESE NINE.
##
## Prompt 64's acceptance is about a REGION, not about a prop: "river feels
## like a major regional landmark", "Team Tether presence builds before the
## captain", "relay is a memorable compact assault, not four NPCs standing
## together". None of those can be judged from a close-up of a crate. So the
## set walks the region in the order a player does -- approach road, picket,
## relay, gorge, crossing, exit -- and deliberately includes the region's own
## longest empty stretch, because a critic who is only shown the good spots is
## being asked a different question than the one that matters. It also includes
## a wild cluster: the first round shot none, and a set with no creature in it
## cannot be asked the scale question at all.
##
## TWO CAPTURE BUGS THIS TOOL DOES NOT HAVE, and every other capture tool does.
##
## 1. The day/weather clock races a multi-viewpoint pass. `world_look.gd` and
##    `world_weather.gd` both advance in `_process`, and a settle loop plus
##    nine framed shots is minutes of game time: `apply_time("day")` called
##    once before the settle wears off, and the later frames come back in a red
##    dusk wash under whatever weather rolled (rounds 3-6 of the previous pass
##    did exactly that). The time is pinned and BOTH
##    nodes' processing is switched off before anything is framed, and the time
##    is re-applied after -- pinning has to survive the settle, not precede it.
##
## 2. Eye heights are measured against the ground the PLAYER stands on, not
##    against `playground_heightfield.gd`.
##
##    The analytic heightfield and the collision terrain do not agree. Standing
##    the real body at (-152, 4195) rests it at +0.90 where the heightfield
##    says -2.00 -- the collision surface is nearly three metres higher, and
##    near the river channel the disagreement reaches 22m (see
##    `ralph/GATE_D3_EVIDENCE_2026-08-22.md` 1.2). Seating a 1.7m eye on the
##    analytic value therefore buries the camera INSIDE the terrain wherever
##    the real ground is higher, and what comes back is a flat dead-coloured
##    plane across the lower frame with the world ending in mid-air above it --
##    the underside of the ground, which reads exactly like a water plane or a
##    hole and was reported as one by a critic who had no way to know better.
##
##    Every eye and target is raycast onto the real collision surface instead,
##    with the analytic height kept only as the fallback when the ray misses.
##
## 3. Parking the camera rig's player underground trips the water hazard.
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
		#
		# Round 2 shot it from 20m and the critic reported the site occupying
		# about 3% of the frame with the lower half of the image empty grass --
		# the same mistake as the checkpoint frame, and the same fix. This kit's
		# props are sub-metre; a camp has to be framed from inside walking
		# distance or the frame is mostly field.
		"name": "02-riverwatch-rest",
		"eye": Vector2(204.5, 3705.5), "eye_h": 1.7,
		"target": Vector2(211.6, 3699.6), "target_h": 0.9,
	},
	{
		# The checkpoint barricade and Hess behind it, from where a player
		# actually meets them.
		#
		# Rounds 1 and 2 shot this from (214, 3668), 27m short of the
		# barricade, and the blind critic reported no checkpoint at all --
		# "the road runs through unimpeded". The props are there and correctly
		# seated (verified against the heightfield, all nine of them), but this
		# kit's crates and barrels are under a metre tall, so at 27m the whole
		# barricade is thirty pixels of speck. A player walks THROUGH this
		# checkpoint; framing it from across a field asks the critic a question
		# no player is ever asked. The eye now stands 9m short of the gap, on
		# the road, at eye height.
		# eye_h 3.0 rather than eye height, and that is a diagnostic as much as
		# a framing choice: at 1.7m from this spot the lower two thirds of the
		# frame comes back as a flat dead-coloured plane with the world ending
		# in mid-air above it, while the same 1.7m eye 19m further back is
		# clean. It is not the camera being underground (the collision raycast
		# returns the analytic height here, unchanged) and it is not water
		# (global level -17, river -9, both far below a -2 eye). Unexplained,
		# reproducible, and recorded in the evidence file rather than guessed
		# at again.
		"name": "03-picket-hess-on-the-road",
		"eye": Vector2(232.5, 3672.0), "eye_h": 3.0,
		"target": Vector2(248.0, 3683.5), "target_h": 1.4,
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
		# The gorge, from ON the south rim looking obliquely along the cut.
		#
		# Round 1 shot this from (60, 4150) at +14m, 200m back, and the blind
		# critic's verdict was "there is no gorge". Round 2 moved onto the rim
		# and it STILL did not show one. The terrain is not the problem -- a
		# heightfield transect at x=-120 falls from -2.0m at z=4194 to -16.6m
		# at z=4200, a 14.6m wall in six metres, and climbs back out by z=4218.
		# The camera was.
		#
		# `target_h` is added to the GROUND height at the target, and the
		# ground at the target is the channel floor, 25m down. Asking for -7
		# aimed the camera at y=-32: a steep pitch into the near grass, which
		# is exactly what came back. Aim at the floor itself (target_h 0) from
		# the south rim, 44m short of it, and the near lip sits in the
		# foreground with the cut receding west behind it.
		"name": "06-river-gorge-along-the-course",
		"eye": Vector2(-98.0, 4192.0), "eye_h": 2.0,
		"target": Vector2(-140.0, 4204.0), "target_h": 0.0,
	},
	{
		# The Old Mill Crossing from the south landing, standing where the
		# player stops at a shut gate.
		#
		# Round 1 stood 50m back at (-152, 4152) and the crossing itself never
		# reached the frame -- the near rim hid the cut and the shot became a
		# house alone on a hill. From the landing the trench, the gate, the
		# mill and the crossing gear are one composition, which is what the
		# region's main gate should look like.
		"name": "07-old-mill-crossing",
		"eye": Vector2(-152.0, 4181.0), "eye_h": 2.2,
		"target": Vector2(-149.0, 4212.0), "target_h": 1.2,
	},
	{
		# The region's own longest measured empty stretch, on the way out into
		# Band 4. Included on purpose: if the region reads bare anywhere, it
		# reads bare here, and the critic should be shown it.
		"name": "08-north-exit-dead-stretch",
		"eye": Vector2(110.0, 4670.0), "eye_h": 2.5,
		"target": Vector2(20.0, 4750.0), "target_h": 2.0,
	},
	{
		# Wild creatures, because round 1 had none in any frame and the critic
		# said so first and loudest: eight frames of a creature-training game
		# with no creature in them cannot answer the scale question at all.
		#
		# That was a capture choice, not an empty region -- 155 wild bodies
		# stand in this band. This is `spawns.json` order 3017, four bramblebun
		# on an 16m radius sitting exactly on the spine at (-19, 3542), shot
		# from 29m: far enough to hold the cluster, close enough that the
		# bodies are more than dots.
		"name": "09-wild-cluster-on-the-road",
		"eye": Vector2(-42.0, 3524.0), "eye_h": 1.8,
		"target": Vector2(-19.0, 3542.0), "target_h": 0.8,
	},
]


func _init() -> void:
	_run()


## The height of the ground a body would actually stand on at (x, z).
##
## Bug 2 above: `playground_heightfield.gd` is analytic and the collision
## terrain does not match it. A ray down the world's own physics space is what
## the player's capsule meets, so it is what a camera should be seated on. The
## analytic value stays as the fallback for a ray that hits nothing, which
## happens where Terrain3D has not streamed collision -- the camera has been
## sitting at that viewpoint for the settle frames by then, so in practice it
## has.
func _surface(world: Node, field: RefCounted, at: Vector2) -> float:
	var analytic: float = field.height_at(at.x, at.y)
	var space: PhysicsDirectSpaceState3D = (world as Node3D).get_world_3d().direct_space_state
	if space == null:
		return analytic
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, analytic + 400.0, at.y), Vector3(at.x, analytic - 400.0, at.y))
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		# Say so. A silent fallback here cost a whole round: the checkpoint
		# frame's dark band was diagnosed as "not the camera underground"
		# BECAUSE this function returned the analytic height unchanged -- which
		# looked like the ray agreeing with the heightfield and was actually
		# the ray hitting nothing at all. Raising that eye from 1.7m to 3.0m
		# cleared the artefact completely, which is what an eye climbing out of
		# the ground looks like.
		push_warning("no collision under (%.1f, %.1f); "
			% [at.x, at.y]
			+ "seating the camera on the analytic height %.2f, which may be "
			% analytic
			+ "under the real surface -- Terrain3D may not have streamed here yet")
		print("  WARN no collision under (%.1f, %.1f), falling back to analytic %.2f" % [
			at.x, at.y, analytic])
		return analytic
	return float((hit["position"] as Vector3).y)


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

	# Bug 3: above the terrain, not 500m under it.
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

	# THE ONE THAT MATTERS. `playground_world.gd` hands Terrain3D the PLAYER's
	# camera (`_terrain.set_camera(_camera)`, line 225) so it can decide which
	# regions to keep resident and where to build collision. Every capture tool
	# in this repo parks the player out of frame and renders from a camera of
	# its own -- which means Terrain3D has been keeping detail and collision
	# resident around a point up to a kilometre from the shot, and the frames
	# are of whatever coarse LOD happened to reach the viewpoint.
	#
	# Measured: with the terrain still following the parked player, 16 of this
	# tool's 18 ground raycasts hit NOTHING at all -- there was no collision
	# under any viewpoint. Handing Terrain3D the capture camera is what makes
	# the frames be of the world the player would actually see.
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		print("WARN no Terrain node with set_camera(); frames will render "
			+ "whatever LOD reaches the viewpoint from the parked player")

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var shot_name: String = str(view["name"])

		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		# Two passes, and the order is the whole point. Terrain3D streams
		# collision around the CAMERA, so there is nothing to raycast against
		# until the camera is already standing there. Move to the analytic
		# guess first, let collision arrive, and only then ask the physics
		# space where the ground really is and re-seat on it.
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(
			target_xz.x,
			field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]),
			target_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)

		# A jump of a kilometre between viewpoints needs frames to resolve
		# before the shot is of the world rather than of the world arriving.
		for i in 40:
			await physics_frame

		eye.y = _surface(world, field, eye_xz) + float(view["eye_h"])
		target.y = _surface(world, field, target_xz) + float(view["target_h"])
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		for i in 20:
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
