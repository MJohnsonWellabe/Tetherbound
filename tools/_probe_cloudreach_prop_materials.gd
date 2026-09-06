extends SceneTree
## CLOUDREACH-DRESS: which props placed by `cloudreach_world.gd` import as
## METAL. `imported_materials.gd`'s header is the long version: glTF's default
## for an absent `metallicFactor` is 1.0, a metal has no diffuse term, and the
## result is a black silhouette in full daylight -- the judges' "black blobs".
## This lists the offenders per scene so a fix can be aimed rather than sprayed.

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const IMPORTED := preload("res://scripts/world/imported_materials.gd")


func _count(node: Node, out: Array) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null:
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(i) as BaseMaterial3D
			if mat == null:
				continue
			var metallic := mat.metallic
			var has_tex := mat.get_texture(BaseMaterial3D.TEXTURE_METALLIC) != null
			var albedo_tex := mat.get_texture(BaseMaterial3D.TEXTURE_ALBEDO) != null
			if metallic > 0.0 and not has_tex:
				out.append("%s surface %d: metallic=%.2f, no metallic texture, albedo_texture=%s"
					% [mesh.name, i, metallic, str(albedo_tex)])
	for child in node.get_children():
		_count(child, out)


func _initialize() -> void:
	var bad := 0
	for key: String in WORLD.ROUTE_DETAIL_SCENES.keys():
		var packed: PackedScene = WORLD.ROUTE_DETAIL_SCENES[key]
		var node := packed.instantiate()
		var out: Array = []
		_count(node, out)
		if out.is_empty():
			print("  ok      %-10s %s" % [key, packed.resource_path.get_file()])
		else:
			bad += 1
			print("  METAL   %-10s %s" % [key, packed.resource_path.get_file()])
			for line: String in out:
				print("            %s" % line)
			print("            make_dielectric would correct %d surface(s)"
				% IMPORTED.make_dielectric(node))
		node.free()
	print("\n%d of %d route-detail scenes import as metal" % [bad, WORLD.ROUTE_DETAIL_SCENES.size()])
	quit(0)
