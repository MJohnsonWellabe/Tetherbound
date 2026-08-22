extends SceneTree

## Quick single-frame capture to confirm the STRONGHOLD-MAT fix
## (scripts/world/stronghold.gd::_material textured=true) actually renders
## textured stone rather than flat colour. A trimmed clone of
## tools/_probe_storm_pass.gd's own machinery, viewpoint 01, with far fewer
## settle frames -- this is a throwaway confirmation shot, not the full pass.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/storm_pass"

func _init() -> void:
	_run()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var eye := Vector2(-30.0, 7455.0)
	var target := Vector2(-34.0, 7540.0)
	var eye_ground: float = field.height_at(eye.x, eye.y)
	var target_ground: float = field.height_at(target.x, target.y)
	camera.global_position = Vector3(eye.x, eye_ground + 1.8, eye.y)
	camera.look_at(Vector3(target.x, target_ground + 1.0, target.y), Vector3.UP)
	if player != null:
		player.global_position = Vector3(eye.x, eye_ground + 0.4, eye.y)
	for i in 20:
		await physics_frame
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "%s/01-road-approach-postfix.png" % OUT_DIR
	image.save_png(path)
	print("wrote %s" % path)
	quit(0)
