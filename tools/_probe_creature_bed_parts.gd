extends SceneTree

## Creature-bed differentiation pass: measured AABBs for every in-family
## (generated_camp) piece that could compose a nest silhouette, plus the
## already-tried candidates, so the composition in creature_bed.gd is
## computed rather than guessed. Run and discard.
##
##   godot --headless --path . --script tools/_probe_creature_bed_parts.gd

const MODELS := [
	["camp_bed", "res://assets/props/generated_camp"],
	["camp_firewood", "res://assets/props/generated_camp"],
	["campfire_stone_ring", "res://assets/props/generated_camp"],
	["camp_tent", "res://assets/props/generated_camp"],
	["bedroll", "res://assets/props/kenney_survival"],
	["bedroll-frame", "res://assets/props/kenney_survival"],
	["bedroll-packed", "res://assets/props/kenney_survival"],
	["Bed_Twin1", "res://assets/props/quaternius_fantasy"],
]


func _init() -> void:
	for entry in MODELS:
		var model: String = entry[0]
		var dir: String = entry[1]
		var path := ""
		for ext in ["gltf", "glb"]:
			var p := "%s/%s.%s" % [dir, model, ext]
			if ResourceLoader.exists(p):
				path = p
				break
		if path == "":
			print("%-24s MISSING" % model)
			continue
		var packed: PackedScene = load(path) as PackedScene
		var node := packed.instantiate() as Node3D
		root.add_child(node)
		var meshes: Array = []
		_collect(node, meshes)
		if meshes.is_empty():
			print("%-24s no mesh" % model)
			continue
		var aabb: AABB = meshes[0].transform * meshes[0].get_aabb()
		for i in range(1, meshes.size()):
			aabb = aabb.merge(meshes[i].transform * meshes[i].get_aabb())
		print("%-24s size=(%.3f, %.3f, %.3f) base_y=%+.3f top_y=%+.3f center_xz=(%.3f,%.3f) meshes=%d" % [
			model, aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y,
			aabb.position.y + aabb.size.y,
			aabb.position.x + aabb.size.x * 0.5, aabb.position.z + aabb.size.z * 0.5,
			meshes.size()])
		root.remove_child(node)
		node.queue_free()
	quit(0)


func _collect(node: Node, into: Array) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)
