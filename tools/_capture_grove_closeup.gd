extends SceneTree

## One-off close-up capture for EV2-landmark-ceiling's verification: the
## standard 5-viewpoint survey (tools/survey.gd) never lands near a `grove`
## clump (tools/_probe_grove.gd confirmed none of its 21 instances sit close
## to any of survey.gd's fixed cameras), so a first blind pass against that
## survey couldn't fairly judge CherryBlossom_3's hero-tree silhouette at
## all -- "no hero tree named" is as consistent with "not in frame" as with
## "still doesn't read as one". This frames one CherryBlossom_3 instance
## directly, with the trainer parked nearby as the 1.8m scale reference the
## visual-judge rubric asks for.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_grove_closeup.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/grove"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 60.0

# CherryBlossom_3 instance from tools/_probe_grove.gd's dump, scale 0.73 --
# middle of the seeded range (0.51-0.83), not the biggest or smallest.
const TREE_XZ := Vector2(-52.6, -10.1)

const EYE_XZ := Vector2(-35.0, -28.0)
const EYE_H := 1.8
const TARGET_H_ABOVE := 8.0 ## aim partway up the canopy, not the trunk base

const PLAYER_XZ := Vector2(-45.0, -17.0) ## between eye and tree, for scale


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

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	var field: RefCounted = HEIGHTFIELD.new()

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.global_position = Vector3(
			PLAYER_XZ.x, field.height_at(PLAYER_XZ.x, PLAYER_XZ.y), PLAYER_XZ.y
		)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 500.0
	world.add_child(camera)
	camera.make_current()

	var eye := Vector3(EYE_XZ.x, field.height_at(EYE_XZ.x, EYE_XZ.y) + EYE_H, EYE_XZ.y)
	var target := Vector3(
		TREE_XZ.x, field.height_at(TREE_XZ.x, TREE_XZ.y) + TARGET_H_ABOVE, TREE_XZ.y
	)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)

	for i in 20:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		quit(1)
		return

	var path := "%s/cherryblossom-closeup.png" % OUT_DIR
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed (%d)" % error)
		quit(1)
		return

	print("-> %s" % path)
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	quit(0)
