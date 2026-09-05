extends SceneTree

## CL-E10 verification, run once and not committed: the OLD `03-mid-route` eye
## and the NEW one, from ONE boot, same target, same rig. Anything that differs
## between the two frames is the eye, because nothing else had the chance to
## move.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/midroute_ab"

func _init() -> void:
	_run()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("[midroute] needs xvfb")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame
	for layer: Node in _all(world):
		if layer is CanvasLayer:
			(layer as CanvasLayer).visible = false
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 3000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var target := Vector2(0.0, 7560.0)
	for entry: Variant in [["old-eye", Vector2(-20.0, 7250.0)], ["new-eye", Vector2(2.2, 7270.0)]]:
		var shot: Array = entry
		var eye: Vector2 = shot[1]
		var eye_ground: float = field.height_at(eye.x, eye.y)
		var target_ground: float = field.height_at(target.x, target.y)
		var toward := (target - eye).normalized()
		if player != null:
			player.global_position = Vector3(eye.x, eye_ground + 0.4, eye.y)
			for i in 150:
				await physics_frame
		var back: Vector2 = eye - toward * 4.2
		var back_ground: float = field.height_at(back.x, back.y)
		if is_nan(back_ground):
			back_ground = eye_ground
		camera.global_position = Vector3(back.x, back_ground + 2.4, back.y)
		camera.look_at(Vector3(target.x, target_ground + 6.0, target.y), Vector3.UP)
		for i in 12:
			await physics_frame
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("%s/03-mid-route-%s.png" % [OUT_DIR, str(shot[0])])
		print("[midroute] wrote %s at eye (%.1f, %.1f)" % [str(shot[0]), eye.x, eye.y])
	print("[midroute] done")
	quit(0)

func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out
