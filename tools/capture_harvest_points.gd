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

	# OW7: ASK the gather point where its marker is, rather than replicating the
	# maths that puts it there. This used to recompute the bearing hash and the
	# 1.3m offset itself, so the moment OW7 moved the marker down onto a
	# woodpile the camera carried on aiming a metre and a half above it and
	# photographed the air the glint used to float in. A capture tool that
	# duplicates the thing it photographs drifts out of date exactly when that
	# thing changes, which is the only time the frames matter.
	var marker: Node3D = null
	for child in veg.get_children():
		if not (child is Node3D) or str(child.get("_item_id")) != "wood":
			continue
		if not (child as Node3D).global_position.is_equal_approx(nearest):
			continue
		marker = (child as Node3D).get_node_or_null(^"Woodpile") as Node3D
		if marker == null:
			marker = (child as Node3D).get_node_or_null(^"Glint") as Node3D
		break
	if marker == null:
		push_warning("no Woodpile/Glint under the nearest wood point; framing its trunk instead")
	var focus: Vector3 = marker.global_position if marker != null else nearest + Vector3.UP

	# Pick the bearing to stand on by TESTING it, not by assuming the pile's own
	# offset direction is clear. The first version stood the camera 3m along
	# that direction and put it inside a boulder -- this scatter places rocks
	# up to 2.1 scale and a gather point can easily have one at its shoulder,
	# so a frame aimed through it photographs bark-coloured stone and proves
	# nothing about the pile. The scatter's solid layers all carry collision,
	# so the physics space already knows what is in the way; ask it.
	var space := (world as Node3D).get_world_3d().direct_space_state
	var out_dir := Vector3.FORWARD
	var found_clear := false
	var preferred := focus - nearest
	preferred.y = 0.0
	preferred = preferred.normalized() if preferred.length() > 0.01 else Vector3.FORWARD
	for step in 12:
		# Start at the pile's own bearing off the tree (the composition that
		# gets the tree behind it) and walk around only as far as needed.
		var angle := float(step) * TAU / 12.0
		var candidate := preferred.rotated(Vector3.UP, angle)
		var eye := focus + candidate * 3.0 + Vector3.UP * 1.5
		var query := PhysicsRayQueryParameters3D.create(eye, focus + Vector3.UP * 0.15)
		if space.intersect_ray(query).is_empty():
			out_dir = candidate
			found_clear = true
			break
	if not found_clear:
		push_warning("no clear line of sight to the pile from any bearing; using its own")
		out_dir = preferred
	print("framing marker at %s (tree at %s) from bearing %.0f deg, clear=%s" % [
		focus, nearest, rad_to_deg(preferred.signed_angle_to(out_dir, Vector3.UP)), found_clear])

	# Eye heights are a standing player's, not a hovering camera's: the question
	# this item has to answer is whether someone WALKING UP can name the
	# resource before the prompt tells them what it is.
	var viewpoints := [
		{
			"name": "close-single",
			"eye": focus + out_dir * 3.0 + Vector3.UP * 1.5,
			"target": focus + Vector3.UP * 0.15,
		},
		{
			"name": "wide-among-neighbours",
			"eye": focus + out_dir * 9.0 + Vector3.UP * 2.0,
			"target": nearest + Vector3(0.0, 1.0, 0.0),
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
