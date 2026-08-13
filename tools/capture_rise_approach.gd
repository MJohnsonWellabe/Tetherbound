extends SceneTree

## The road's own arrival at the rocky rise, for OF10's look-quality half.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_rise_approach.gd
##
## tools/capture_hillside.gd frames `rises.peaks[0]` from due east and due
## north, at heights chosen to fill the frame with slope MATERIAL. None of its
## three viewpoints contains `paths.routes["The Rise"]` at all, so nothing in
## the existing harness can answer OF10's actual question — how the approach
## reads from the road, walking toward the hill the road climbs toward.
##
## These three sit on and beside that route (village square -> (45,-22) ->
## (74,-41), which OF10a truncated to stop at the true foot of the rise), at
## roughly third-person camera height, looking the way a player walking it
## would be looking. Camera placement is `ground_height_at` plus an offset,
## never a raycast — Terrain3D heightmap raycasts are unreliable here, see
## playground_world.gd's own note.
##
## Same honest limits as tools/survey.gd: Compatibility renderer, software
## rendering, placeholder geometry.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/rise-approach"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const VIEWPOINTS := [
	{
		# OF4-remainder-mound. The village-square vantage, added because that
		# item is judged at TWO named viewpoints (the square and the Rise
		# path) and this file only ever carried the road ones. Same eye as
		# capture_wayfinding.gd's `silhouette-from-square` (standing near
		# Grandpa's door) but aimed at the rise itself rather than at the
		# stronghold 271m beyond it — OF13 moved the structure onto the far
		# shoulder, so from here the rise is the whole subject and nothing
		# is built on it.
		"name": "square-to-rise",
		"eye": Vector2(-2.0, -4.0), "eye_h": 2.0,
		"target": Vector2(140.0, -90.0), "target_h": 8.0,
	},
	{
		# Halfway along the route, third-person camera height, looking down
		# the road at the rise it is aimed at. This is the framing the
		# complaint is about: what the hill looks like while walking toward
		# it. Round 1 aimed 26m ABOVE the ground 100m away, which pitched the
		# camera up far enough that the road left the bottom of the frame
		# entirely and the blind critic — correctly — reported it could not
		# find a road in a shot named for one. Aim at the road's own last
		# point instead and let the rise fill the distance behind it.
		"name": "road-approach",
		"eye": Vector2(26.0, -14.0), "eye_h": 3.2,
		"target": Vector2(74.0, -41.0), "target_h": 2.0,
	},
	{
		# Standing where the road stops. OF10a ended it at (74,-41), just
		# outside the rise's 78m footprint, so this is the view up the flank
		# from the last walkable step — pitched to keep the road's end in the
		# bottom of the frame rather than only sky and slope.
		"name": "road-end-lookup",
		"eye": Vector2(62.0, -33.0), "eye_h": 3.0,
		"target": Vector2(100.0, -58.0), "target_h": 8.0,
	},
	{
		# Off the road to the north, so the road, its stopping point and the
		# rise's flank are all in one frame — whether the approach reads as
		# arriving somewhere, or as a track that gives up in a field.
		"name": "road-foot-three-quarter",
		"eye": Vector2(34.0, -78.0), "eye_h": 18.0,
		"target": Vector2(88.0, -48.0), "target_h": 4.0,
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

	# Park the player under the first viewpoint, same reason capture_hillside.gd
	# does: an out-of-bounds player breaks Terrain3D's region streaming for the
	# whole run, not just one frame.
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
		print("  %-24s -> %s" % [name, path])

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
