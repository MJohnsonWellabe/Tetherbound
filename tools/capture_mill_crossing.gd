extends SceneTree

## EV6-remainder: frames of the mill, its crossing, and the ranger station —
## the three bible §12 building types the EV6 rebuild deliberately left until
## EV5's water existed. Same honesty rule as tools/survey.sh: real frames, no
## touch-ups.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_mill_crossing.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/mill_crossing"
const SETTLE_FRAMES := 50

## name -> [camera position, look-at]. World coordinates; the site sits on the
## mill-crossing flat at height -20.7 (terrain_playground.json), so eye level
## there is around y=-19.
const SHOTS := {
	# The cluster from the south-east: tower, wheel side, bridge behind.
	"mill-and-crossing": [Vector3(-122.0, -16.5, 99.0), Vector3(-134.5, -17.5, 110.0)],
	# From the north-west across the stream: wheel over the water, bridge deck.
	"mill-wheel-over-stream": [Vector3(-143.0, -18.5, 117.0), Vector3(-134.0, -17.0, 107.5)],
	# Standing on the bridge's east approach, looking across the deck.
	"bridge-deck": [Vector3(-130.5, -19.2, 113.5), Vector3(-140.0, -20.3, 112.5)],
	# The ranger station from the pond route, door side.
	"ranger-station": [Vector3(-92.0, -15.8, 103.0), Vector3(-100.5, -16.8, 99.5)],
	# The landmark question: does the mill read from the route the way the
	# windmill used to read from the square? Shot from the pond route's bend.
	"mill-from-route": [Vector3(-82.0, -13.0, 88.0), Vector3(-132.0, -14.0, 108.0)],
}


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	# No UI in these frames (same reason as capture_site_shots.gd).
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasLayer:
			(node as CanvasLayer).visible = false
		stack.append_array(node.get_children())

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in SHOTS.keys():
		if FileAccess.file_exists("%s/%s.png" % [OUT, name]):
			print("skip -> %s.png (already captured)" % name)
			continue
		var spec: Array = SHOTS[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1])
		for i in 25:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [SHOTS.size(), OUT])
	quit(0)
