extends SceneTree
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
func _init() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 200: await physics_frame
	var camp: Node = _find(world, "trail_camp")
	var field: RefCounted = HEIGHTFIELD.new()
	for child in camp.get_children():
		if str(child.name) in ["camp_bed", "camp_tent", "Bench", "Stool", "camp_firewood", "camp_flame"]:
			var n3 := child as Node3D
			var ground: float = field.height_at(n3.global_position.x, n3.global_position.z)
			var meshes: Array = []
			_collect(n3, meshes)
			var aabb: AABB = (meshes[0] as MeshInstance3D).global_transform * (meshes[0] as MeshInstance3D).get_aabb()
			for i in range(1, meshes.size()):
				var mi := meshes[i] as MeshInstance3D
				aabb = aabb.merge(mi.global_transform * mi.get_aabb())
			print("%-12s node.y=%.3f ground=%.3f mesh_bottom_world_y=%.3f gap_above_ground=%.3f" % [
				child.name, n3.global_position.y, ground, aabb.position.y, aabb.position.y - ground])
	quit(0)
func _find(node, wanted):
	if node.name == wanted: return node
	for c in node.get_children():
		var h = _find(c, wanted)
		if h != null: return h
	return null
func _collect(node, into):
	if node is MeshInstance3D: into.append(node)
	for c in node.get_children(): _collect(c, into)
