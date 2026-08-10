extends SceneTree

## Close-up frames of the signpost and the stronghold silhouette, for R7.1-visual.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_wayfinding.gd
##
## Neither of these two features is what the fixed five-viewpoint survey
## (tools/survey.gd) exists to judge — it frames exploration and composition,
## not a specific authored prop. R7.1-found already caught 03-rise-overlook
## sitting 14m from the towers by coincidence, filling the frame with one
## tower instead of showing the landmark; these viewpoints are chosen on
## purpose, at a range that lets a critic actually see the thing being asked
## about.
##
## Same honest limits as tools/survey.gd: Compatibility renderer (see
## docs/decisions/D06), software rendering, placeholder geometry.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/wayfinding"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

## Same coordinates the scripts themselves use (playground_world.gd,
## signpost.gd, landmark.gd) — kept in sync by hand since a survey tool has
## no business importing gameplay scripts' private constants.
const SIGNPOST_AT := Vector2(13.5, -7.0)
const TOWER_AT := Vector2(134.0, -82.0)

const VIEWPOINTS := [
	{
		# Straight on to the arm stack, close enough to read the labels.
		"name": "signpost-front",
		"eye": Vector2(9.0, -9.5), "eye_h": 1.7,
		"target": Vector2(13.5, -7.0), "target_h": 2.2,
	},
	{
		# Off-axis, so the arms are seen fanned out rather than end-on.
		"name": "signpost-three-quarter",
		"eye": Vector2(17.5, -3.0), "eye_h": 1.6,
		"target": Vector2(13.5, -7.0), "target_h": 2.0,
	},
	{
		# From the village square, the natural vantage a player has while
		# standing near Grandpa's door — the distance the landmark actually
		# has to read a shape at, not a coincidence.
		"name": "silhouette-from-square",
		"eye": Vector2(-2.0, -4.0), "eye_h": 2.0,
		"target": TOWER_AT, "target_h": 15.0,
	},
	{
		# From "The Rise" path's own endpoint (118, -72), the last authored
		# waypoint before the climb — roughly the point a player following
		# the signpost's own arm would be standing.
		"name": "silhouette-from-path-end",
		"eye": Vector2(118.0, -72.0), "eye_h": 2.0,
		"target": TOWER_AT, "target_h": 15.0,
	},
	{
		# Close enough to judge the tower shapes themselves, far enough not
		# to repeat R7.1-found's point-blank mistake (14m put one tower
		# edge-to-edge across the frame).
		"name": "silhouette-close",
		"eye": Vector2(134.0, -122.0), "eye_h": 6.0,
		"target": TOWER_AT, "target_h": 12.0,
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

	# Park the player well clear of every eye in this file, the same way
	# survey.gd does — straight down from the first eye's XZ keeps it inside
	# the region Terrain3D is already streaming, instead of the old fixed
	# (9000, 200, 9000) that broke mesh streaming for the whole scene.
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
		var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
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
