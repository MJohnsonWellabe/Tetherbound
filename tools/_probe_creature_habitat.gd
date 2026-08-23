extends SceneTree

## CREATURE-PRESENTATION. Two in-habitat frames of wild creatures where the
## player actually meets them: the Band 1 practice-meadow cluster and the
## village pond shore.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_probe_creature_habitat.gd
##
## NONSHIPPING probe, kept for the next presentation pass rather than deleted,
## because the tools that already frame these places settle for 90 frames and
## then 40 more per shot: on a box shared with several rendering lanes that is
## over an hour of software rendering for five viewpoints, and this pass needed
## two. Same pinning discipline as capture_band3_region.gd (time forced to day
## and world_look's processing switched OFF, or a long settle drifts the frame
## into dusk), same eye-height discipline (heights come off the analytic
## heightfield and are only used to sit a camera above open ground).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/creature_presentation/habitat"
const SETTLE_FRAMES := 24
const PER_SHOT_SETTLE := 10


func _init() -> void:
	_run()


func _run() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	var pond_spec: Array = config.get("water", {}).get("pond_centre", [])
	var pond := Vector2(float(pond_spec[0]), float(pond_spec[1]))
	var field: RefCounted = HEIGHTFIELD.new(config)

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for _i in SETTLE_FRAMES:
		await process_frame

	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)

	var camera := Camera3D.new()
	camera.fov = 60.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	# The practice meadow's own Bramblebun cluster, centre (30, -40) radius 15
	# (data/config/bands/band1_lower_meadows/spawns.json, order 0), seen from
	# the road side at standing eye height -- the frame the owner's own
	# wild-cluster shot was taken at.
	var shots: Dictionary = {
		"practice-meadow-cluster": [
			Vector3(30.0, field.height_at(30.0, -8.0) + 1.7, -8.0),
			Vector3(30.0, field.height_at(30.0, -40.0) + 0.6, -40.0),
		],
		"pond-shoreline": [
			Vector3(pond.x + 40.0, field.height_at(pond.x + 40.0, pond.y - 30.0) + 2.2, pond.y - 30.0),
			Vector3(pond.x, field.height_at(pond.x, pond.y) - 1.0, pond.y),
		],
	}

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in shots.keys():
		var spec: Array = shots[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1], Vector3.UP)
		if look != null:
			look.call("apply_time", "day")
		for _i in PER_SHOT_SETTLE:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image != null:
			image.save_png("%s/%s.png" % [OUT, name])
			print("wrote %s/%s.png" % [OUT, name])
	quit(0)
