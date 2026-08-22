extends SceneTree

## Why do environment/nature's bushes, grass tufts and small rocks render as
## flat teal shards when props.gd places them, while the same folder's log
## and log_large look right? Prints each candidate's bounds plus, per
## surface, whether it carries an albedo TEXTURE or only a flat albedo
## colour -- an untextured model tinted by whatever the pack's palette
## expects is exactly what a flat shard looks like.

const CANDIDATES := [
	["plant_bush", "res://assets/environment/nature"],
	["grass_large", "res://assets/environment/nature"],
	["rock_smallA", "res://assets/environment/nature"],
	["log", "res://assets/environment/nature"],
	["Bush_Common", "res://assets/environment/stylized_nature"],
	["Bush_Common_Flowers", "res://assets/environment/stylized_nature"],
	["Fern_1", "res://assets/environment/stylized_nature"],
	["Grass_Wide_Tall", "res://assets/environment/stylized_nature"],
	["Clover_1", "res://assets/environment/stylized_nature"],
	["Rock_Medium_1", "res://assets/environment/stylized_nature"],
	["Rock_Medium_2", "res://assets/environment/stylized_nature"],
	["Rock_Medium_3", "res://assets/environment/stylized_nature"],
	["RockPath_Round_Wide", "res://assets/environment/stylized_nature"],
]


func _init() -> void:
	for entry in CANDIDATES:
		var model: String = entry[0]
		var node := _load(model, entry[1])
		if node == null:
			print("%-22s MISSING" % model)
			continue
		root.add_child(node)
		var meshes: Array = []
		_collect(node, meshes)
		var aabb := AABB()
		var first := true
		var report := ""
		for mi: MeshInstance3D in meshes:
			var box: AABB = mi.transform * mi.get_aabb()
			aabb = box if first else aabb.merge(box)
			first = false
			var mesh: Mesh = mi.mesh
			if mesh == null:
				continue
			for i in mesh.get_surface_count():
				var mat := mesh.surface_get_material(i) as StandardMaterial3D
				if mat == null:
					report += " [surface %d: no StandardMaterial3D]" % i
					continue
				var tex: Texture2D = mat.albedo_texture
				report += " [%s tex=%s albedo=(%.2f,%.2f,%.2f)]" % [
					mat.resource_name, "yes" if tex != null else "NO",
					mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b]
		print("%-22s size=(%.2f, %.2f, %.2f)%s" % [model, aabb.size.x, aabb.size.y, aabb.size.z, report])
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
	return null


func _collect(node: Node, into: Array) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)
