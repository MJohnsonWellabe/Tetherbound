extends SceneTree

## Close-up frames of R2.3's new gather points on the world's own scattered
## trees and rocks, for the required local blind-judge pass.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_harvest_points.gd
##
## Positions aren't fixed coordinates the way capture_paths.gd's are --
## `_mark_harvestable` picks a deterministic stride through each layer's own
## RNG-seeded draw order, so this loads the real scene first, finds the
## Vegetation node's own spawned VegetationHarvestPoint children (real world
## positions, not guessed), and frames the two nearest to spawn: one close on
## a single gather point (is the tint visible, does it read as marking a real
## tree rather than floating paint), one wider showing several trees at once
## (does a marked one stand out from its unmarked neighbours without looking
## like a bug).
##
## Same honest limits as every other capture tool here: Compatibility
## renderer, software rendering, placeholder geometry (D06).

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/harvest_points"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0


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

	var veg: Node = world.get_node_or_null(^"Vegetation")
	if veg == null:
		push_error("no Vegetation node in the scene")
		quit(1)
		return

	# Pebble_Round is one of "rocks"' six models and is genuinely tiny --
	# small enough that a "nearest by distance" pick can land on one and
	# frame nothing legible. Trees are large, unambiguous, and every
	# CommonTree model is roughly the same size, so filtering to
	# harvest_item == "wood" guarantees a frame with something actually worth
	# judging.
	var points: Array[Vector3] = []
	for child in veg.get_children():
		if child.has_method("setup") and child is Node3D and str(child.get("_item_id")) == "wood":
			points.append((child as Node3D).global_position)

	print("found %d wood harvest points" % points.size())
	if points.is_empty():
		push_error("no wood harvest points found; nothing to capture")
		quit(1)
		return

	points.sort_custom(func(a, b): return a.length() < b.length())
	for p in points.slice(0, 5):
		print("  %s  dist=%.1f" % [p, p.length()])

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var nearest: Vector3 = points[0]
	if player != null:
		player.global_position = nearest + Vector3(0.0, -500.0, 0.0)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	# Replicates vegetation_harvest_point.gd's own bearing math so the camera
	# can be aimed AT the glint's actual offset position -- a fixed diagonal
	# guess put the glint behind the trunk from that specific angle on the
	# first few attempts (confirmed via an isolated render that the glint
	# mesh itself draws fine; the miss was framing, not the marker).
	var bearing := float(hash(nearest) & 0xFFFFFF) / float(0xFFFFFF) * TAU
	var glint_offset := Vector3(sin(bearing) * 1.3, 1.5, cos(bearing) * 1.3)
	var glint_pos := nearest + glint_offset

	var viewpoints := [
		{
			"name": "close-single",
			"eye": glint_pos + Vector3(sin(bearing) * 4.0, 1.0, cos(bearing) * 4.0),
			"target": glint_pos,
		},
		{
			"name": "wide-among-neighbours",
			"eye": glint_pos + Vector3(sin(bearing) * 10.0, 2.5, cos(bearing) * 10.0),
			"target": nearest + Vector3(0.0, 1.5, 0.0),
		},
	]

	var written: Array[String] = []
	for entry: Variant in viewpoints:
		var view: Dictionary = entry
		camera.global_position = view["eye"]
		camera.look_at(view["target"], Vector3.UP)

		for i in 20:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			push_error("%s: viewport returned no image" % str(view["name"]))
			continue
		var path := "%s/%s.png" % [OUT_DIR, view["name"]]
		image.save_png(path)
		written.append(path)
		print("  %-22s -> %s" % [str(view["name"]), path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	quit(0)
