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
	"ironwood-grove": [Vector3(-330.0, 5.0, 5100.0), Vector3(-350.0, 2.0, 5055.0)],
	"ridge-patrol-camp": [Vector3(-244.0, 6.5, 6462.0), Vector3(-235.5, 3.5, 6472.0)],
	"field-camp-clearing": [Vector3(415.0, 3.0, 6000.0), Vector3(400.0, 0.0, 6040.0)],
}


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
		for i in 30:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [SHOTS.size(), OUT])
	quit(0)
