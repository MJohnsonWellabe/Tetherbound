extends SceneTree

## Local, unrotated, unscaled bounds of every model the trail_camp cluster
## uses, so round 3's scales and yaws are computed from measurements rather
## than guessed. Long-axis direction matters for the seats: a bench whose
## length runs radially out of the fire ring reads wrong however its front
## face happens to point.

const MODELS := [
	["Bonfire_Fire", "res://assets/props/quaternius_survival"],
	["Backpack", "res://assets/props/quaternius_survival"],
	["Bench", "res://assets/props/quaternius_fantasy"],
	["Crate_Wooden", "res://assets/props/quaternius_fantasy"],
	["Bag", "res://assets/props/quaternius_fantasy"],
	["Rope_1", "res://assets/props/quaternius_fantasy"],
	["Barrel", "res://assets/props/quaternius_fantasy"],
	["Stool", "res://assets/props/quaternius_furniture"],
	["log", "res://assets/environment/nature"],
	["log_large", "res://assets/environment/nature"],
	["plant_bush", "res://assets/environment/nature"],
	["plant_bushSmall", "res://assets/environment/nature"],
	["plant_bushLarge", "res://assets/environment/nature"],
	["grass_large", "res://assets/environment/nature"],
	["rock_smallA", "res://assets/environment/nature"],
	["rock_smallD", "res://assets/environment/nature"],
	["RockPath_Round_Wide", "res://assets/environment/stylized_nature"],
	["RockPath_Round_Small_1", "res://assets/environment/stylized_nature"],
	["RockPath_Round_Small_2", "res://assets/environment/stylized_nature"],
	["RockPath_Round_Thin", "res://assets/environment/stylized_nature"],
]


func _init() -> void:
	for entry in MODELS:
		var model: String = entry[0]
		var dir: String = entry[1]
		var node := _load(model, dir)
		if node == null:
			print("%-24s MISSING under %s" % [model, dir])
			continue
		root.add_child(node)
		var meshes: Array = []
		_collect(node, meshes)
		if meshes.is_empty():
			print("%-24s no mesh" % model)
			root.remove_child(node)
			node.queue_free()
			continue
		var aabb: AABB = meshes[0].transform * meshes[0].get_aabb()
		for i in range(1, meshes.size()):
			aabb = aabb.merge(meshes[i].transform * meshes[i].get_aabb())
		var long_axis := "x" if aabb.size.x >= aabb.size.z else "z"
		print("%-24s size=(%.2f, %.2f, %.2f) base_y=%+.2f long=%s ratio=%.2f" % [
			model, aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y,
			long_axis, max(aabb.size.x, aabb.size.z) / max(0.001, min(aabb.size.x, aabb.size.z))])
		root.remove_child(node)
		node.queue_free()
	quit(0)


func _load(model: String, dir: String) -> Node3D:
	for ext in ["gltf", "glb"]:
		var p := "%s/%s.%s" % [dir, model, ext]
		if ResourceLoader.exists(p):
			var packed: PackedScene = load(p) as PackedScene
			if packed != null:
				return packed.instantiate()
	var op := "%s/%s.obj" % [dir, model]
	if ResourceLoader.exists(op):
		var mesh: Mesh = load(op) as Mesh
		if mesh != null:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			return mi
	return null


func _collect(node: Node, into: Array) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)
