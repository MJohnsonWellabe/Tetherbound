extends SceneTree

## T1-CAMP: measured AABBs for the priority campsite props (§17) not already
## covered by tools/_probe_camp_models.gd, so composition/scale decisions in
## camp.gd are computed rather than guessed. Run and discard.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_t1_camp.gd

const MODELS := [
	["campfire_stone_ring", "res://assets/props/generated_camp"],
	["camp_tent", "res://assets/props/generated_camp"],
	["camp_bed", "res://assets/props/generated_camp"],
	["Workbench", "res://assets/props/quaternius_fantasy"],
	["bedroll", "res://assets/props/kenney_survival"],
	["Bench", "res://assets/props/quaternius_fantasy"],
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
		print("%-24s size=(%.3f, %.3f, %.3f) base_y=%+.3f center_xz=(%.3f,%.3f) long=%s" % [
			model, aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y,
			aabb.position.x + aabb.size.x * 0.5, aabb.position.z + aabb.size.z * 0.5, long_axis])
		for i in meshes.size():
			var mesh_instance: MeshInstance3D = meshes[i]
			for s in mesh_instance.mesh.get_surface_count():
				var mat := mesh_instance.get_active_material(s)
				var std := mat as StandardMaterial3D
				if std != null:
					print("    surf[%d] mat=%s metallic=%.2f metallic_tex=%s roughness=%.2f rough_tex=%s" % [
						s, std.resource_name, std.metallic, std.metallic_texture != null,
						std.roughness, std.roughness_texture != null])
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
