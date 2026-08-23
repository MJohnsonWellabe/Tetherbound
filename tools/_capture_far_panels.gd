extends SceneTree

## GATE-E-STRONGHOLD-ART (scratch): just the two `far-panels-*` viewpoints from
## `tools/_capture_band4_sites.gd`, same coordinates and same 22-degree lens,
## so the frames the 2026-08-23 assessment actually named can be re-shot
## without paying for the other five. The full seven-shot tool is the one to
## keep; delete this once the ghost-box finding is closed.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_far_panels.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/band4"
const SETTLE_FRAMES := 240

const SHOTS := {
	"far-panels-east": [Vector3(-244.0, 6.5, 6462.0), Vector3(-100.0, 18.0, 6520.0), 22.0],
	"far-panels-north": [Vector3(415.0, 3.0, 6000.0), Vector3(300.0, 30.0, 6900.0), 22.0],
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
		camera.fov = float(spec[2])
		for i in 30:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [SHOTS.size(), OUT])
	quit(0)
