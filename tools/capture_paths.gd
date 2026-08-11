extends SceneTree

## Close-up frames of the dirt paths, for EV4's local blind-judge pass.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_paths.gd
##
## Neither the fixed five-viewpoint survey (tools/survey.gd) nor
## capture_wayfinding.gd frames the ground itself at standing height and a
## downward-looking angle the way a player actually sees a path underfoot —
## same reasoning as capture_wayfinding.gd's own header, applied to a
## different authored feature. Viewpoints sit on or beside the authored
## polylines in data/config/terrain_playground.json's `paths.routes`,
## looking a short distance ahead and down, the way `_apply_ground_shader`'s
## comments describe the near field being judged.
##
## Same honest limits as tools/survey.gd: Compatibility renderer (see
## docs/decisions/D06), software rendering, placeholder geometry.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/paths"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const VIEWPOINTS := [
	{
		# The village square, where three of the four routes converge —
		# whether packed dirt reads as one connected place rather than four
		# isolated stripes.
		"name": "square-convergence",
		"eye": Vector2(2.0, -4.0), "eye_h": 1.8,
		"target": Vector2(10.0, -10.0), "target_h": 0.3,
	},
	{
		# Grandpa's House route, first leg, standing on the path looking
		# ahead along it — the closest a frame gets to how the opening's own
		# walk actually sees this ground.
		"name": "grandpas-house-route",
		"eye": Vector2(4.0, -11.0), "eye_h": 1.7,
		"target": Vector2(-4.0, -13.0), "target_h": 0.4,
	},
	{
		# The Rise route, first leg — open meadow rather than the tight
		# square, so the path/grass edge is judged with nothing else in frame.
		"name": "the-rise-route",
		"eye": Vector2(27.0, -15.0), "eye_h": 1.7,
		"target": Vector2(45.0, -22.0), "target_h": 0.4,
	},
	{
		# Standing just off the shoulder, low and close, looking across the
		# path rather than along it — the edge feathering is the whole
		# subject of this frame, not incidental to a wider composition.
		"name": "edge-detail",
		"eye": Vector2(6.2, -13.4), "eye_h": 1.3,
		"target": Vector2(5.8, -11.4), "target_h": 0.05,
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
	# capture_wayfinding.gd does.
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
		print("  %-22s -> %s" % [name, path])

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
