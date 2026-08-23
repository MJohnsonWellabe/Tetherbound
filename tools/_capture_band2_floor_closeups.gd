extends SceneTree

## BAND2-FLOOR scratch capture: close (~8-10m) player-eye shots of the five
## forest-floor anchor sites, to verify the deadfall (mushroom)/bushes (fern)
## anchors actually placed visible instances rather than trusting the config
## alone -- mushrooms and ferns are small enough to be sub-pixel at
## tools/survey_band2.gd's normal framing distances. Same camera-posing
## pattern as survey_band2.gd, pointed straight down at each anchor centre
## instead of along a sightline. Not committed -- verification only.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_band2_floor_closeups.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/band2_closeup"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const FOV := 70.0

const SITES := [
	{"name": "A-early-forest", "at": Vector2(142.0, 1550.0), "eye_offset": Vector2(-8.0, -6.0)},
	{"name": "B1-quarry-ridge", "at": Vector2(168.0, 2038.0), "eye_offset": Vector2(-8.0, -6.0)},
	{"name": "B2-mid-ridge", "at": Vector2(28.0, 2118.0), "eye_offset": Vector2(-8.0, -6.0)},
	{"name": "C-warrens-approach", "at": Vector2(-408.0, 2443.0), "eye_offset": Vector2(-8.0, -6.0)},
	{"name": "D-late-ridge", "at": Vector2(72.0, 2969.0), "eye_offset": Vector2(-8.0, -6.0)},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
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
	camera.far = 500.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.global_position = Vector3(5000.0, -500.0, 5000.0)
	var field: RefCounted = HEIGHTFIELD.new()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	if look != null:
		look.call("apply_time", "day")

	var written: Array[String] = []
	for entry: Variant in SITES:
		var site: Dictionary = entry
		var name: String = str(site["name"])
		var at: Vector2 = site["at"]
		var eye_xz: Vector2 = at + (site["eye_offset"] as Vector2)
		var eye_ground: float = field.height_at(eye_xz.x, eye_xz.y)
		var target_ground: float = field.height_at(at.x, at.y)
		camera.global_position = Vector3(eye_xz.x, eye_ground + 1.6, eye_xz.y)
		camera.look_at(Vector3(at.x, target_ground + 0.4, at.y), Vector3.UP)

		for i in SETTLE_AFTER_MOVE:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		var path := "%s/%s.png" % [OUT_DIR, name]
		image.save_png(path)
		written.append(path)
		print("captured %s -> %s" % [name, path])

	print("%d frames -> %s" % [written.size(), OUT_DIR])
	quit(0)
