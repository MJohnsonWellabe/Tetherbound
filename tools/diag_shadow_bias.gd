extends SceneTree

## `EV4-textures-lighting-remainder-3`: is the unmotivated dark patch
## self-shadowing acne/Peter-panning from the terrain's own heightmap
## normals, driven by `shadow_normal_bias`/`shadow_bias`?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diag_shadow_bias.gd
##
## `diag_control_texture.gd` ruled out the control map; `diag_shadow_cascade.gd`
## ruled out PSSM split-boundary artifacts (the patch was pixel-identical
## across SHADOW_PARALLEL_4_SPLITS at two different max_distance values AND
## SHADOW_ORTHOGONAL, which has no splits at all). Both rule-outs are
## real, direct, rendered-frame evidence, not inspection.
##
## `world_look.gd::_apply_sun()`'s own comment on `shadow_normal_bias`:
## "fights the acne a heightmap terrain produces at grazing angles. Raise it
## if the ground looks striped." A bias raised to fight acne is a well-known
## cause of the opposite failure -- Peter-panning / false self-shadow blobs
## on relatively flat ground near the camera, especially where per-vertex
## normal reconstruction on a heightmap is imprecise. Nobody in this item's
## long history has isolated bias from blur (`shadow_blur` was tried; bias
## was not). This drops `shadow_normal_bias`/`shadow_bias` toward zero and
## compares against the current config values, holding everything else
## (camera, sun angle, cascade mode) fixed.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const EYE := Vector2(2.0, -4.0)
const EYE_H := 1.8
const TARGET := Vector2(10.0, -10.0)
const TARGET_H := 0.3

const CONFIGS := [
	{"name": "bias-current-1.4-0.06", "normal_bias": 1.4, "bias": 0.06},
	{"name": "bias-near-zero-0.05-0.01", "normal_bias": 0.05, "bias": 0.01},
	{"name": "bias-doubled-2.8-0.12", "normal_bias": 2.8, "bias": 0.12},
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
		player.global_position = Vector3(EYE.x, field.height_at(EYE.x, EYE.y) - 500.0, EYE.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var sun: DirectionalLight3D = _find_directional_light(world)
	if sun == null:
		push_error("no DirectionalLight3D found; cannot vary shadow bias")
		quit(1)
		return

	var eye := Vector3(EYE.x, field.height_at(EYE.x, EYE.y) + EYE_H, EYE.y)
	var target := Vector3(TARGET.x, field.height_at(TARGET.x, TARGET.y) + TARGET_H, TARGET.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in CONFIGS:
		var cfg: Dictionary = entry
		sun.shadow_normal_bias = float(cfg["normal_bias"])
		sun.shadow_bias = float(cfg["bias"])
		for i in 20:
			await physics_frame
		await _shoot(str(cfg["name"]), written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _find_directional_light(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for child in node.get_children():
		var found := _find_directional_light(child)
		if found != null:
			return found
	return null


func _shoot(name: String, written: Array[String], failures: Array[String]) -> void:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		failures.append("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		failures.append("%s: save_png failed" % name)
		return
	written.append(path)
	print("  %-30s -> %s" % [name, path])
