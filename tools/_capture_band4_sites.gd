extends SceneTree

## GATE-D4/prompt 65: fixed frames of the new Band 4 content for the blind
## visual pass (ralph/conventions.md "Visual-affecting work needs a blind
## pass"). Same shape as tools/capture_site_shots.gd -- real frames, no HUD,
## no touch-ups.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_band4_sites.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/band4"
const SETTLE_FRAMES := 240

const SHOTS := {
	"ironwood-grove": [Vector3(-316.0, 4.5, 5046.0), Vector3(-343.0, 1.5, 5078.0)],
	"ridge-patrol-camp": [Vector3(-244.0, 6.5, 6462.0), Vector3(-235.5, 3.5, 6472.0)],
	"field-camp-clearing": [Vector3(415.0, 3.0, 6000.0), Vector3(400.0, 0.0, 6040.0)],
	"watchtower-spur": [Vector3(-205.0, 12.0, 6430.0), Vector3(-262.0, 4.0, 6482.0)],
	"ironwood-camp-pad": [Vector3(-310.0, 5.0, 5115.0), Vector3(-334.0, 1.0, 5085.0)],
	"far-panels-east": [Vector3(-244.0, 6.5, 6462.0), Vector3(-100.0, 18.0, 6520.0), 22.0],
	"far-panels-north": [Vector3(415.0, 3.0, 6000.0), Vector3(300.0, 30.0, 6900.0), 22.0],
}

## GATE-D4b added the last two. `watchtower-spur` is the wide read of the ruin
## and its garrison from the approach -- the composition the close
## `ridge-patrol-camp` frame cannot show, and the one the region's "ruined
## watch / occupation traces" identity actually rests on. `ironwood-camp-pad`
## is clearings[4002], looking across the new pad into the ironwood stand
## behind it, because a pad that reads as a bald circle in the grass is a
## defect a close frame of the trees alone would never catch.


func _init() -> void:
	_run()


func _run() -> void:
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
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in SHOTS.keys():
		var spec: Array = SHOTS[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1])
		# Optional third element: field of view. A 22-degree lens is not a
		# prettier frame, it is a MEASUREMENT -- round 1's blind critic called
		# the pale panels over the horizon "unlit or untextured billboard quads
		# that failed to resolve", in three frames, and at 62 degrees they are
		# forty pixels wide. Naming what they actually are needs the reach.
		camera.fov = float(spec[2]) if spec.size() > 2 else 62.0
		for i in 30:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [SHOTS.size(), OUT])
	quit(0)
