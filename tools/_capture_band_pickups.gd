extends SceneTree

## W17-DENSITY-B2-B3. Frames of the authored band pickups in place, at
## normal third-person play distance, for the code-blind judge.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script tools/_capture_band_pickups.gd
##
## Never `--headless` with a rendering driver (AGENT_WORKFLOW.md §7).
##
## Each viewpoint names a `pickups.json` id; the camera aims at the node the
## loader actually stood up (`BandPickup_<id>`), so a placement the loader
## nudged off scatter is framed where it really is, not where the file says.
## Eye 7 m back at 2.1 m up, looking at the pickup's own foot: the distance a
## player sees a find from when deciding whether to walk to it.
##
## The player body stands IN FRAME, 3.4 m ahead of the eye and 1.5 m to one
## side of the sightline, which is roughly where a third-person camera holds
## it. Round 1 parked it beside the EYE, so it fell outside the frustum in all
## six frames, and the judge's report names that as its own defect: "no 1.80 m
## ruler is present in any frame, and the pickups read oversized... a survey
## meant to judge pickup scale needs to put them in shot." The lateral offset
## keeps the body off the pickup rather than in front of it.
##
## Frames go to `res://shots_band_pickups/`; only a contact sheet is ever
## committed (AGENT_WORKFLOW.md §8).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots_band_pickups"

const SETTLE_FRAMES := 240
const SETTLE_AFTER_MOVE := 30
const POSE_FRAMES := 4
const EYE_DISTANCE := 7.0
const EYE_HEIGHT := 2.1
const TARGET_HEIGHT := 0.35
const ACTOR_CLEARANCE := 0.4
## How far ahead of the eye, and how far off the sightline, the player stands.
const ACTOR_AHEAD_M := 3.4
const ACTOR_SIDE_M := 1.5

## name, pickup id, bearing (degrees, world) the eye sits AT relative to the
## pickup, time of day.
const VIEWPOINTS := [
	{"name": "01-good-quarry-floor", "id": "b2_candy_quarry_floor", "bearing": 300.0, "time": "day"},
	{"name": "02-great-quarry-ledge", "id": "b2_candy_quarry_ledge", "bearing": 200.0, "time": "day"},
	{"name": "03-rare-stormtrail", "id": "b3_candy_stormtrail_hardware", "bearing": 40.0, "time": "day"},
	{"name": "04-mushroom-quarry", "id": "b2_mushroom_quarry", "bearing": 250.0, "time": "day"},
	{"name": "05-mushroom-wild-camp", "id": "b3_mushroom_camp_edge", "bearing": 120.0, "time": "day"},
	{"name": "06-great-springhead", "id": "b3_candy_springhead", "bearing": 330.0, "time": "day"},
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

	var failures: Array[String] = []
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)

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
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		var node: Node3D = world.get_node_or_null(NodePath("BandPickup_%s" % str(view["id"]))) as Node3D
		if node == null:
			failures.append("%s: no BandPickup_%s in the world" % [name, str(view["id"])])
			continue
		var target := node.global_position + Vector3.UP * TARGET_HEIGHT
		var bearing := deg_to_rad(float(view["bearing"]))
		var eye_xz := Vector2(node.global_position.x, node.global_position.z) + Vector2(sin(bearing), cos(bearing)) * EYE_DISTANCE
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + EYE_HEIGHT, eye_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		if player != null:
			# Forward is eye -> pickup; right is that turned 90 degrees. The
			# body stands ahead of the eye and to the right, facing the find.
			var forward := (Vector2(node.global_position.x, node.global_position.z) - eye_xz).normalized()
			var right := Vector2(forward.y, -forward.x)
			var park := eye_xz + forward * ACTOR_AHEAD_M + right * ACTOR_SIDE_M
			player.global_position = Vector3(park.x, field.height_at(park.x, park.y) + ACTOR_CLEARANCE, park.y)
			var away := target - player.global_position
			player.rotation = Vector3(0.0, atan2(away.x, away.z), 0.0)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))

		for i in SETTLE_AFTER_MOVE:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % name)
			continue
		print("  %-26s pickup at %s  eye %s -> %s" % [name, str(node.global_position), str(eye), path])

	print("%d viewpoints -> %s" % [VIEWPOINTS.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	for line in failures:
		print("FAIL: %s" % line)
	quit(1 if not failures.is_empty() else 0)
