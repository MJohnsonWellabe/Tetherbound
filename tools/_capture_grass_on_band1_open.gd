extends SceneTree

## OWNER-0902-GRASS-ON. Player-eye-level evidence that flipping
## `grass_field.json`'s `enabled` flag to true (per the owner's direct
## 2026-09-02 directive) still reads as real grass, at the same
## `band1_open` site `tools/perf_render_stats.gd` measures. Not a new
## capture rig: same site coordinates as `perf_render_stats.gd`'s
## `band1_open` view, dropped from that tool's elevated LOD-survey height
## (24m) to a standing eye height (1.7m, the project's usual EYE_HEIGHT
## convention -- see tools/_capture_night_ecology.gd and siblings), because
## an elevated survey shot cannot answer "does it look like grass at a
## glance" the way OWNER-0902-GRASS-RENDER's own screenshot did.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_grass_on_band1_open.gd
##
## NEVER `--headless` with a real rendering driver (ralph/conventions.md).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://ralph/reports/OWNER-0902-GRASS-ON/shots"
const SETTLE_FRAMES := 240
const PER_SHOT_SETTLE := 60
const EYE_HEIGHT := 1.7
const SITE_X := 0.0
const SITE_Z := 700.0


func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await physics_frame

	var camera: Camera3D = world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if camera == null:
		print("CAPTURE FAIL: no CameraRig/Camera3D")
		quit(1)
		return
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var ground := 0.0
	if world.has_method("ground_height_at"):
		ground = float(world.call("ground_height_at", SITE_X, SITE_Z))
	if is_nan(ground):
		ground = 0.0

	var eye := Vector3(SITE_X, ground + EYE_HEIGHT, SITE_Z)
	if player != null:
		player.global_position = Vector3(SITE_X, ground + 1.5, SITE_Z)
	camera.global_position = eye
	camera.global_rotation = Vector3(deg_to_rad(-8.0), 0.0, 0.0)
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	for _i in PER_SHOT_SETTLE:
		await physics_frame
	await RenderingServer.frame_post_draw

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var image := root.get_texture().get_image()
	if image != null:
		var path := "%s/band1_eye_level_grass_on.png" % OUT
		image.save_png(path)
		print("wrote %s" % path)
	quit(0)
