extends SceneTree
## Which meshes stand tall right behind the mouth's brow? Lists every
## MeshInstance3D under the warrens whose world AABB intersects a box over
## the throat's outer end and reaches above 3m -- the "dark spikes above the
## arch" in the round-5 03 frame.
const BURROW_WARRENS := preload("res://scripts/world/burrow_warrens.gd")
class FlatWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var world := FlatWorld.new()
	root.add_child(world)
	await process_frame
	var warrens: Node3D = BURROW_WARRENS.new()
	world.add_child(warrens)
	warrens.call("build", world)
	await physics_frame
	var probe := AABB(Vector3(-12.0, 2.0, -12.0), Vector3(24.0, 20.0, 16.0))
	print("PROBE meshes: %d" % warrens.find_children("*", "MeshInstance3D", true, false).size())
	for mi: Node in warrens.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var box: AABB = m.global_transform * m.mesh.get_aabb()
		if box.intersects(probe) and box.end.y > 2.5 and box.size.y > 1.5 and box.size.x < 3.0:
			print("SPIKE? %s size=%s pos=%s top=%.1f" % [str(m.get_path()).replace("/root/@FlatWorld@", ""), str(box.size), str(box.position), box.end.y])
	quit(0)
