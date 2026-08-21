extends SceneTree

## Gate A environment evidence: the pond mill, footbridge and ranger station.
## Anchors come from village.json and vertical placement comes from the current
## heightfield, so OW5D-style relocations cannot leave this harness rendering an
## empty historical site. Same honesty rule as tools/survey.sh: real frames,
## no touch-ups.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_mill_crossing.gd
##
## Do not use --headless: the Dummy renderer does not produce evidence frames.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const VILLAGE_CONFIG := "res://data/config/village.json"
const OUT_DIR := "res://shots/gate_a/mill_crossing"
const READY_TIMEOUT_FRAMES := 240
const SETTLE_AFTER_MOVE := 4
const POSE_FRAMES := 4
const DOOR_SETTLE_FRAMES := 40


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_clear_pngs(OUT_DIR)

	var village_config := _load_json(VILLAGE_CONFIG)
	var mill_spec := _placement(village_config, "mill")
	var bridge_spec := _placement(village_config, "footbridge")
	var ranger_spec := _placement(village_config, "ranger_station")
	if mill_spec.is_empty() or bridge_spec.is_empty() or ranger_spec.is_empty():
		push_error("village.json must place mill, footbridge, and ranger_station")
		quit(1)
		return

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	var door: Node3D = await _wait_for_door(world, _at(mill_spec))
	if door == null or not door.has_method("force_open"):
		push_error("current mill placement has no runtime Door; Gate A doorway evidence cannot be captured")
		quit(1)
		return

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_hide_canvas_layers(world)

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	var field: RefCounted = HEIGHTFIELD.new()
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var park := _at(mill_spec)
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	# The live village owns several generic nodes named Door. Select the one
	# nearest the mill's authored placement; this avoids depending on either a
	# generated placement index or PrefabTemplates traversal order.
	var mill_node: Node3D = door.get_parent() as Node3D
	var views := _site_views(_at(mill_spec), _at(bridge_spec), _at(ranger_spec))
	views.append_array(_door_views())

	var failures: Array[String] = []
	var written: Array[String] = []
	for entry: Variant in views:
		var view: Dictionary = entry
		var name := str(view["name"])
		if view.has("door_state"):
			var should_open := str(view["door_state"]) == "open"
			door.call("force_open", should_open)
			await _settle_door(door)

		var eye: Vector3
		var target: Vector3
		if bool(view.get("mill_local", false)):
			eye = mill_node.to_global(view["eye"] as Vector3)
			target = mill_node.to_global(view["target"] as Vector3)
		else:
			var eye_xz: Vector2 = view["eye"]
			var target_xz: Vector2 = view["target"]
			eye = Vector3(eye_xz.x,
				field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
			target = Vector3(target_xz.x,
				field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)

		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		for i in SETTLE_AFTER_MOVE:
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
	print("%d fresh frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## Composition offsets remain authored, but the anchors are the live placements
## from village.json. Heights are sampled instead of retaining the old pad's
## absolute y=-20.7 assumption.
func _site_views(mill: Vector2, bridge: Vector2, ranger: Vector2) -> Array[Dictionary]:
	return [
		{
			"name": "01-mill-and-crossing",
			"eye": mill + Vector2(10.0, -8.0), "eye_h": 2.2,
			"target": bridge + Vector2(1.8, -3.0), "target_h": 2.7,
		},
		{
			"name": "02-mill-wheel-over-stream",
			"eye": mill + Vector2(-11.0, 10.0), "eye_h": 2.2,
			"target": mill + Vector2(-2.0, 0.5), "target_h": 3.0,
		},
		{
			"name": "03-bridge-deck",
			"eye": bridge + Vector2(5.8, 0.5), "eye_h": 1.7,
			"target": bridge + Vector2(-3.7, -0.5), "target_h": 1.1,
		},
		{
			"name": "04-ranger-station",
			"eye": ranger + Vector2(8.0, 3.0), "eye_h": 1.7,
			"target": ranger + Vector2(-0.5, -0.5), "target_h": 2.4,
		},
		{
			"name": "05-mill-from-route",
			"eye": mill + Vector2(50.0, -19.0), "eye_h": 3.0,
			"target": mill, "target_h": 4.5,
		},
	]


## When the mill recipe owns village_door.gd, preserve three honest states:
## the closed affordance, the open affordance, and an inside-out view through
## the same centreline a player traverses. These are derived from the mill's
## local frame, so moving or yawing the whole building cannot stale them.
func _door_views() -> Array[Dictionary]:
	return [
		{
			"name": "06-mill-door-closed", "door_state": "closed", "mill_local": true,
			"eye": Vector3(0.0, 1.65, 9.0), "target": Vector3(0.0, 1.45, 3.0),
		},
		{
			"name": "07-mill-door-open", "door_state": "open", "mill_local": true,
			"eye": Vector3(0.0, 1.65, 9.0), "target": Vector3(0.0, 1.45, 3.0),
		},
		{
			"name": "08-mill-door-through", "door_state": "open", "mill_local": true,
			"eye": Vector3(0.0, 1.65, -1.8), "target": Vector3(0.0, 1.45, 7.0),
		},
	]


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _placement(config: Dictionary, prefab: String) -> Dictionary:
	for entry: Variant in config.get("structures", []):
		if entry is Dictionary and str((entry as Dictionary).get("prefab", "")) == prefab:
			return entry as Dictionary
	return {}


func _at(spec: Dictionary) -> Vector2:
	var value: Array = spec.get("at", [0.0, 0.0])
	return Vector2(float(value[0]), float(value[1]))


func _find_door_near(node: Node, at: Vector2) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	if node is Node3D and str(node.name) == "Door":
		var spot := Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z)
		best = node as Node3D
		best_distance = spot.distance_to(at)
	for child in node.get_children():
		var found := _find_door_near(child, at)
		if found == null:
			continue
		var spot := Vector2(found.global_position.x, found.global_position.z)
		var distance := spot.distance_to(at)
		if distance < best_distance:
			best = found
			best_distance = distance
	return best if best_distance <= 12.0 else null


func _wait_for_door(world: Node, at: Vector2) -> Node3D:
	for i in READY_TIMEOUT_FRAMES:
		var door := _find_door_near(world, at)
		if door != null:
			return door
		await physics_frame
	return null


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


## village_door.gd's authored swing lasts 0.45s. Wait for the actual leaf,
## capped at forty frames, instead of assuming either wall time or frame rate.
func _settle_door(door: Node) -> void:
	var leaf: Node3D = door.get("_leaf") as Node3D
	if leaf == null:
		return
	for i in DOOR_SETTLE_FRAMES:
		var target := float(door.get("_open_yaw")) if bool(door.call("is_open")) else float(door.get("_closed_yaw"))
		if absf(angle_difference(leaf.rotation.y, target)) < 0.01:
			return
		await process_frame


## An evidence run must never silently inherit frames from an older layout.
## This removes only PNG products inside this harness's dedicated directory.
func _clear_pngs(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".png"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s" % [path, entry]))
		entry = dir.get_next()
	dir.list_dir_end()
