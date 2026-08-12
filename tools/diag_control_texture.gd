extends SceneTree

## `EV4-textures-lighting-remainder-2`: does the unmotivated dark patch
## survive Terrain3D's `show_control_texture` debug view?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diag_control_texture.gd
##
## `show_colormap` already ruled out the baked VERTEX COLOUR map (EV4-
## textures-lighting-remainder's own DONE.md entry). This is the other half
## of "how does this cell decide what texture to show": `show_control_texture`
## renders pure per-cell texture-ID/blend-weight data with zero PBR shading,
## zero normal maps, zero lighting. If the patch is a bad CONTROL MAP value
## (a genuine data bug in the bake), it shows here too. If it's a SHADING
## artifact (normal/AO/lighting reading a boundary wrong), this view is flat
## and even and the patch disappears -- same diagnostic logic `show_colormap`
## already used successfully, one layer over.
##
## Same two viewpoints EV4-textures-lighting-remainder's own investigation
## named (square-convergence, the-rise-route), copied from
## tools/capture_paths.gd rather than re-deriving them.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const VIEWPOINTS := [
	{
		"name": "square-convergence",
		"eye": Vector2(2.0, -4.0), "eye_h": 1.8,
		"target": Vector2(10.0, -10.0), "target_h": 0.3,
	},
	{
		"name": "the-rise-route",
		"eye": Vector2(27.0, -15.0), "eye_h": 1.7,
		"target": Vector2(45.0, -22.0), "target_h": 0.4,
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

	var terrain: Node = world.get_node_or_null(^"Terrain")
	var material: Object = terrain.get("material") if terrain != null else null
	if material == null:
		push_error("no Terrain3D material; cannot toggle show_control_texture")
		quit(1)
		return

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

		material.set("show_control_texture", true)
		for i in 20:
			await physics_frame
		await _shoot("%s-control-texture" % name, written, failures)

		material.set("show_control_texture", false)
		for i in 20:
			await physics_frame
		await _shoot("%s-normal" % name, written, failures)

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


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
