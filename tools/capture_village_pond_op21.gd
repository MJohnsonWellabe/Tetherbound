extends SceneTree

## NONSHIPPING evidence capture for OP21-17/18/19 (ralph/VILLAGE-POND).
##
## Lighter than capture_pond_day_readability.gd's own preflight harness --
## no luma/consecutive-good-frame gate, no spawned wild, no live-environment
## readback assertion -- because this box is shared with several other
## lanes' own render jobs right now and that harness's own strict gate was
## timing out under the contention. Same settle-then-snapshot shape as
## tools/capture_site_shots.gd, which already ships this way.
##
##   godot --headless --path . --script tools/capture_village_pond_op21.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/gate_a/village_pond_op21"
const SETTLE_FRAMES := 90
const PER_SHOT_SETTLE := 40


func _init() -> void:
	_run()


func _run() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	var pond_spec: Array = config.get("water", {}).get("pond_centre", [])
	var pond := Vector2(float(pond_spec[0]), float(pond_spec[1]))
	var field: RefCounted = HEIGHTFIELD.new(config)

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var camera := Camera3D.new()
	camera.fov = 65.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)
	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	# Shots keyed by pond centre / village square so they stay correct if
	# either moves again -- the same reason capture_pond_day_readability.gd
	# derives its own eye/target from `pond_centre` instead of hardcoding.
	var shots: Dictionary = {
		"pond-shoreline": [
			Vector3(pond.x + 40.0, field.height_at(pond.x + 40.0, pond.y - 30.0) + 2.2, pond.y - 30.0),
			Vector3(pond.x, field.height_at(pond.x, pond.y) - 1.0, pond.y),
		],
		"pond-lush-pocket": [
			# Second fix. (-70,-20) was dry but pointed at the WRONG side of the
			# pond -- a placement-count probe (RULES.all_placements, bucketed
			# into 8 compass sectors around pond_centre) found the actual tree/
			# bush density concentrated S/SE of the pond (215 of ~340 nearby
			# placements), toward the mill/ranger cluster, not the far shore
			# this offset framed. Eye now sits east of that measured density
			# peak (~pond+(15,-71)) on dry ground (probed h=-12.13 vs
			# water_level -17.0), looking back across it toward the water.
			Vector3(pond.x + 60.0, field.height_at(pond.x + 60.0, pond.y - 70.6) + 2.2, pond.y - 70.6),
			Vector3(pond.x + 7.0, field.height_at(pond.x + 7.0, pond.y - 45.0), pond.y - 45.0),
		],
		"mill-crossing": [
			Vector3(-405.0, field.height_at(-405.0, 500.0) + 2.2, 500.0),
			Vector3(-384.0, field.height_at(-384.0, 517.0), 517.0),
		],
		"village-square-overview": [
			Vector3(-10.0, 16.0, 22.0),
			Vector3(10.0, 2.0, -10.0),
		],
		"road-sign-shoulder": [
			# Tightened: the first framing put the sign too far off to read at
			# this resolution and was not included in the reviewed batch.
			# Eye sits ~20m back along the Pond Circuit trailhead's own road
			# bearing (points[0]->points[1]) looking straight at the sign's
			# corrected position (~2.5m off the centreline, OP21-18's fix).
			Vector3(-351.0, field.height_at(-351.0, 382.0) + 2.0, 382.0),
			Vector3(-357.76, field.height_at(-357.76, 401.12), 401.12),
		],
	}

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in shots.keys():
		var spec: Array = shots[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1])
		for i in PER_SHOT_SETTLE:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [shots.size(), OUT])
	quit(0)
