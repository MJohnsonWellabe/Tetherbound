extends SceneTree
const MODELS := [
	"res://assets/props/generated_camp/camp_tent.glb",
	"res://assets/props/generated_camp/camp_bed.glb",
	"res://assets/props/generated_camp/campfire_stone_ring.glb",
]
func _init() -> void:
	for path in MODELS:
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			print("%-50s FAILED TO LOAD" % path)
			continue
		var node: Node3D = packed.instantiate()
		root.add_child(node)
		var meshes: Array = []
		_collect(node, meshes)
		var aabb := AABB()
		var first := true
		for mi: MeshInstance3D in meshes:
			var box: AABB = mi.transform * mi.get_aabb()
			aabb = box if first else aabb.merge(box)
			first = false
		print("%-50s size=(%.2f,%.2f,%.2f) base_y=%+.2f meshes=%d" % [
			path, aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y, meshes.size()])
		root.remove_child(node); node.queue_free()
	quit(0)
func _collect(node, into):
	if node is MeshInstance3D: into.append(node)
	for c in node.get_children(): _collect(c, into)
