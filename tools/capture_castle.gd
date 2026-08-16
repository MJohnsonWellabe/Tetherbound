extends SceneTree

## The re-massed castle, from the distances a player actually sees it.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/capture_castle.gd
##
## `capture_wayfinding.gd`'s two silhouette vantages were framed against the
## OF4-rebuild castle -- 23x17m with 3.9m walls -- at 26m and 70m. The
## 2026-08-16 re-mass makes the fortress 36x40m with 10m curtains and a ~29m
## keep, and at 26m the camera is standing INSIDE the gate passage. Those
## frames stay as they are (they answer a wayfinding question about the
## approach road); this file answers the scale question, from far enough out
## that the whole mass is in frame.
##
## Day and dusk, because the owner's brief asks for a silhouette that reads
## "unmistakably hostile/occupied" and the two lighting conditions fail
## differently: flat noon hides massing, low sun exaggerates it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/castle"
const SITE := Vector3(229.8, 0.0, -144.4)
const SETTLE_FRAMES := 200
const POSE_FRAMES := 12

## Where the camera stands, as an offset from the castle site, and what it
## aims at. South-west is the approach side (the gate faces south, and the
## stronghold route comes from the west), so both angles look at that corner.
## NORTH and EAST offsets, deliberately. The stronghold complex occupies
## x[129.8,246] z[-227.4,-169.4] -- the whole southern approach -- so a camera
## south of the castle is standing inside the Outer Works looking at a chamber
## wall, which is what the first run of this file produced.
const VIEWS := [
	{"name": "castle-north-day", "offset": Vector3(6.0, 26.0, 74.0), "look_at_y": 12.0, "time": "day"},
	{"name": "castle-north-dusk", "offset": Vector3(6.0, 26.0, 74.0), "look_at_y": 12.0, "time": "dusk"},
	{"name": "castle-corner-day", "offset": Vector3(46.0, 18.0, 46.0), "look_at_y": 10.0, "time": "day"},
	{"name": "castle-gate-day", "offset": Vector3(2.0, 6.0, -34.0), "look_at_y": 7.0, "time": "day"},
	{"name": "castle-top-down", "offset": Vector3(2.0, 120.0, 12.0), "look_at_y": 0.0, "time": "day"},
]


func _init() -> void:
	_run()


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# The HUD lives inside the world scene, not under root -- hiding only
	# root's own children left the hotbar, minimap and objective text over
	# every frame of the first run.
	_hide_canvas_layers(root)

	var camera := Camera3D.new()
	camera.fov = 65.0
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var ground: float = float(world.call("ground_height_at", SITE.x, SITE.z))
	if is_nan(ground):
		ground = 0.0
	print("castle site ground: %.2f" % ground)

	for entry: Variant in VIEWS:
		var view: Dictionary = entry
		var offset: Vector3 = view["offset"]
		camera.global_position = Vector3(SITE.x, ground, SITE.z) + offset
		var target := Vector3(SITE.x, ground + float(view["look_at_y"]), SITE.z)
		var up := Vector3.UP if absf(camera.global_position.x - target.x) + absf(camera.global_position.z - target.z) > 1.0 else Vector3.FORWARD
		camera.look_at(target, up)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))
		for i in POSE_FRAMES:
			await process_frame
		var image := get_root().get_texture().get_image()
		var path := "%s/%s.png" % [OUT_DIR, str(view["name"])]
		image.save_png(ProjectSettings.globalize_path(path))
		print("  %-22s -> %s" % [str(view["name"]), path])

	quit()
