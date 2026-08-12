extends SceneTree

## Very close frames of the well curb's own RockTrim material — closer than
## tools/capture_buildings.gd's "05-well-close" gets, which frames the whole
## well-and-canopy group rather than the curb stone itself.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_well.gd
##
## WHY THIS EXISTS. EV6-remainder's own "small named leftovers" list: the
## well's RockTrim dressing still reads cool in shadow after a round-1 warm
## multiply (building_prefabs.json's retint on MI_RockTrim). Judging that
## needs the curb filling the frame from more than one bearing, since the
## post/canopy overhead only shades part of it and which part depends on
## which side the camera stands. Four bearings around WELL_AT, close enough
## that the curb's stone reads as texture, not silhouette, plus one overhead
## sanity frame — the overhead frame is what first caught EV6-remainder-well-
## rocktrim's real finding: the whole village was rendering invisible
## (building_prefabs.gd's instantiate() was returning a hidden duplicate; see
## its own fix comment), so this file doubles as the fastest way to confirm a
## structure is actually drawing before trusting anything about its colour.
##
## Same honest limits as every other tools/capture_*.gd: Compatibility
## renderer (D06), software rendering — colour and shading relationships are
## trustworthy, fine specular/AO judgements are not.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/well"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 55.0

## Kept in sync by hand with data/config/village.json, the same convention
## capture_buildings.gd already uses.
const WELL_AT := Vector2(10.0, -10.0)
const WELL_H := 0.9 ## roughly mid-height on the curb, a "metre-high stone block" per its own recipe comment

const VIEWPOINTS := [
	{"name": "00-well-overhead", "bearing_deg": 0.0, "overhead": true},
	{"name": "01-well-north", "bearing_deg": 0.0},
	{"name": "02-well-east", "bearing_deg": 90.0},
	{"name": "03-well-south", "bearing_deg": 180.0},
	{"name": "04-well-west", "bearing_deg": 270.0},
]

## Clear of the curb's own local AABB (radius ~2.7m on each axis, confirmed
## with tools/_probe_prefabs.gd — the first version of this tool used 2.5m
## and stood inside the mesh on every bearing).
const STAND_OFF := 6.0


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
	camera.far = 500.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	if look != null:
		look.call("apply_time", "day")

	if player != null:
		player.global_position = Vector3(WELL_AT.x, field.height_at(WELL_AT.x, WELL_AT.y) - 500.0, WELL_AT.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var ground_y: float = field.height_at(WELL_AT.x, WELL_AT.y)
	var target := Vector3(WELL_AT.x, ground_y + WELL_H, WELL_AT.y)

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		var eye: Vector3
		if view.get("overhead", false):
			eye = Vector3(WELL_AT.x, ground_y + 12.0, WELL_AT.y + 0.01)
		else:
			var bearing: float = deg_to_rad(float(view["bearing_deg"]))
			var offset := Vector3(sin(bearing), 0.0, cos(bearing)) * STAND_OFF
			eye = Vector3(WELL_AT.x, ground_y + 1.5, WELL_AT.y) + offset

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
