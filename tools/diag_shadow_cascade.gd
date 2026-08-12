extends SceneTree

## `EV4-textures-lighting-remainder-3`: is the unmotivated dark patch a PSSM
## (parallel-split shadow map) cascade-boundary artifact rather than any real
## object's shadow?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diag_shadow_cascade.gd
##
## `diag_control_texture.gd` (this item's own prior round) ruled out the
## control map: the patch is a soft diagonal shape in the LIT render that has
## no matching region at all in the flat, unlit `show_control_texture` debug
## view -- confirmed pure shading, not terrain data. Combined with an older
## finding already on record (`data/config/art.json`'s own EV4 comment):
## toggling `sun.shadow_enabled` off removes the patch cleanly, and a second,
## independent, much older observation (`EV4-textures-lighting-remainder`'s
## own `DONE.md` history) that the patch sits in roughly the SAME apparent
## position relative to the camera across totally different world locations
## -- which a world-space object's shadow does not naturally explain, but a
## depth/view-space rendering artifact does.
##
## `world_look.gd::_apply_sun()` sets `directional_shadow_mode =
## SHADOW_PARALLEL_4_SPLITS` unconditionally -- PSSM's own cascade transition
## bands are a known real-world source of exactly this kind of soft,
## depth-anchored dark seam under simpler (non-Forward+) shadow filtering.
## This renders the SAME square-convergence viewpoint under three different
## cascade configurations. If the patch is a split-boundary artifact, its
## on-screen shape/position should visibly change (or vanish under
## SHADOW_ORTHOGONAL, which has no splits to seam). If it stays pixel-
## identical across all three, this rules the cascade hypothesis out too.

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

const MODES := [
	{"name": "cascade-4split-dist220", "mode": DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "dist": 220.0},
	{"name": "cascade-4split-dist60", "mode": DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "dist": 60.0},
	{"name": "cascade-orthogonal", "mode": DirectionalLight3D.SHADOW_ORTHOGONAL, "dist": 220.0},
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

	var sun: DirectionalLight3D = world.get_node_or_null(^"WorldLook/Sun") as DirectionalLight3D
	if sun == null:
		sun = _find_directional_light(world)
	if sun == null:
		push_error("no DirectionalLight3D found; cannot vary cascade mode")
		quit(1)
		return

	var eye := Vector3(EYE.x, field.height_at(EYE.x, EYE.y) + EYE_H, EYE.y)
	var target := Vector3(TARGET.x, field.height_at(TARGET.x, TARGET.y) + TARGET_H, TARGET.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in MODES:
		var cfg: Dictionary = entry
		sun.directional_shadow_mode = int(cfg["mode"])
		sun.directional_shadow_max_distance = float(cfg["dist"])
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
