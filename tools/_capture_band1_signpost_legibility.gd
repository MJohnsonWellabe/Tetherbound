extends SceneTree

## BAND1-DISCOVERY-0903 evidence: close-up reads of Band 1's own signposts at
## the ROG Ally's own 1280x800, for `docs/VISUAL_BIBLE.md` §4 item 8's named
## defect ("signpost text is a `Label3D` resolution smear") and
## `docs/CURRENT_STATE.md`'s open P3 ("objective label truncates at 1280x800"
## / signpost legibility). `signpost.gd`'s `LABEL_FONT_SIZE` (48 -> 144, this
## branch) is a raster-resolution fix that changes no board or letter size in
## the world -- this capture is what proves it actually reads sharper, at the
## exact resolution the open issue names, not inferred from the constant.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_band1_signpost_legibility.gd
##
## Same honest limits as tools/capture_wayfinding.gd: Compatibility renderer,
## software rendering, placeholder geometry.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/wayfinding"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 60.0

const VIEWPOINTS := [
	{
		# The Rise crest trailhead ("Pond Circuit"), moved this branch from
		# (-357.76,401.12) to (-228,331) -- docs/specs/BAND1_COMPOSITION_PLAN.md
		# 5.3/6.1, so this is now the fingerpost standing in the crest window,
		# approached from the road (south-west, the direction the arm's own
		# bearing -- (-360,400)->(-390,460) -- points).
		"name": "crest-trailhead-pond-circuit",
		"eye": Vector2(-235.0, 322.0), "eye_h": 1.7,
		"target": Vector2(-228.0, 331.0), "target_h": 2.2,
	},
	{
		# Same post, three-quarter angle, so a face is caught closer to
		# head-on than the first pose can guarantee (the plank's own bearing
		# is not known a priori from this file, same honest caveat
		# capture_wayfinding.gd's own three-quarter pose carries).
		"name": "crest-trailhead-three-quarter",
		"eye": Vector2(-222.0, 320.0), "eye_h": 1.9,
		"target": Vector2(-228.0, 331.0), "target_h": 2.2,
	},
	{
		# South Bridge trailhead, unmoved this branch -- a second, independent
		# read of the same font-size fix on a sign this branch did not touch.
		"name": "south-bridge-trailhead",
		"eye": Vector2(18.0, 1250.0), "eye_h": 1.7,
		"target": Vector2(14.1, 1256.15), "target_h": 2.2,
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
		print("  %-30s -> %s" % [name, path])

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
