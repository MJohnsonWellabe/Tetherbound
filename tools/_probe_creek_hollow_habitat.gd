extends SceneTree

## CREATURE-PRESENTATION / §15+§7. Every habitat-tagged spawn cluster in Creek
## Hollow (data/config/bands/band1_lower_meadows/spawns.json orders 6-8 and
## 1018-1045), each shot from a plausible approach angle at standing eye
## height, so the claim in that file's own `_comment_creek_hollow` -- "the
## existing pond, mill, footbridge, ranger station, reed arcs, grove scatter
## and west-bank hollow provide the water edge, open bank, rocky/mill
## shoulder, grove and overhang equivalents" -- can be judged against a real
## render instead of taken on file comments alone.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_probe_creek_hollow_habitat.gd
##
## Same pinning discipline as _probe_creature_habitat.gd: time forced to day
## and world_look's processing switched off before any shot is taken.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/creature_presentation/habitat"
const SETTLE_FRAMES := 30
const PER_SHOT_SETTLE := 12


func _init() -> void:
	_run()


func _run() -> void:
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

	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	# Each entry: [habitat tag from spawns.json, look-at centre, eye position
	# a player walking the basin loop would actually stand at]. Eye offsets
	# are a few metres back from centre, toward the mill/footbridge approach
	# side, not directly overhead -- the frame a player sees on arrival.
	var shots: Dictionary = {
		"creekhollow-creek_edge": [Vector2(-370.0, 537.0), Vector2(-358.0, 520.0)],
		"creekhollow-rock_overhang": [Vector2(-380.0, 552.0), Vector2(-368.0, 535.0)],
		"creekhollow-water_edge": [Vector2(-360.0, 522.0), Vector2(-348.0, 505.0)],
		"creekhollow-open_basin": [Vector2(-432.2, 485.5), Vector2(-418.0, 470.0)],
		"creekhollow-rocky_shoulder": [Vector2(-345.0, 595.0), Vector2(-333.0, 580.0)],
		"creekhollow-grove": [Vector2(-383.7, 597.0), Vector2(-370.0, 583.0)],
		"creekhollow-far_water_edge": [Vector2(-420.0, 610.0), Vector2(-405.0, 595.0)],
	}

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for shot_name: String in shots.keys():
		var spec: Array = shots[shot_name]
		var look_at: Vector2 = spec[0]
		var eye: Vector2 = spec[1]
		camera.global_position = Vector3(eye.x, field.height_at(eye.x, eye.y) + 1.7, eye.y)
		camera.look_at(Vector3(look_at.x, field.height_at(look_at.x, look_at.y) + 0.5, look_at.y), Vector3.UP)
		if look != null:
			look.call("apply_time", "day")
		for _i in PER_SHOT_SETTLE:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image != null:
			image.save_png("%s/%s.png" % [OUT, shot_name])
			print("wrote %s/%s.png" % [OUT, shot_name])
	quit(0)
