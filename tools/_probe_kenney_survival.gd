extends SceneTree

## Scale and material check for the candidate Kenney Survival Kit props
## staged under assets/props/kenney_survival. The ASSET_LEDGER's own rule for
## a sourced asset is "test scale/materials in-engine" before it is used, and
## BAND1-D1 has already been bitten once this session by a pack whose
## materials carry no albedo texture (environment/nature). Same check, run
## before placing anything.

const CANDIDATES := ["bedroll", "bedroll-frame", "tent", "tent-canvas", "campfire-pit"]
const DIR := "res://assets/props/kenney_survival"


func _init() -> void:
	for model in CANDIDATES:
		var path := "%s/%s.glb" % [DIR, model]
		if not ResourceLoader.exists(path):
			print("%-16s MISSING at %s" % [model, path])
			continue
		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			print("%-16s did not load as a scene" % model)
			continue
		var node: Node3D = packed.instantiate()
		root.add_child(node)
		var meshes: Array = []
		_collect(node, meshes)
		var aabb := AABB()
		var first := true
		var mats := ""
		for mi: MeshInstance3D in meshes:
			var box: AABB = mi.transform * mi.get_aabb()
			aabb = box if first else aabb.merge(box)
			first = false
			var mesh: Mesh = mi.mesh
			for i in mesh.get_surface_count():
				var mat := mesh.surface_get_material(i) as StandardMaterial3D
				if mat == null:
					mats += " [surface %d: no StandardMaterial3D]" % i
					continue
				mats += " [%s tex=%s albedo=(%.2f,%.2f,%.2f)]" % [
					mat.resource_name, "yes" if mat.albedo_texture != null else "NO",
					mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b]
		print("%-16s size=(%.2f, %.2f, %.2f) base_y=%+.2f meshes=%d%s" % [
			model, aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y, meshes.size(), mats])
		root.remove_child(node)
		node.queue_free()
	quit(0)


func _collect(node: Node, into: Array) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)
