extends SceneTree
## T1-CAST scratch: list camp_bed.glb's mesh instances/surfaces/material names
## so a per-surface tint (creature bed vs player bed differentiation) can
## target the right one instead of guessing.
const MESH_PATH := "res://assets/props/generated_camp/camp_bed.glb"


func _init() -> void:
	var scene: PackedScene = load(MESH_PATH)
	var root: Node = scene.instantiate()
	_walk(root, 0)
	quit(0)


func _walk(node: Node, depth: int) -> void:
	var indent := "  ".repeat(depth)
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		print("%s[MeshInstance3D] %s  aabb=%s" % [indent, node.name, str(mesh.get_aabb()) if mesh else "?"])
		if mesh != null:
			for i in mesh.get_surface_count():
				var mat := mesh.surface_get_material(i)
				var surf_name: String = mesh.surface_get_name(i)
				var mat_name := mat.resource_name if mat != null else "?"
				var albedo := "?"
				if mat is BaseMaterial3D:
					albedo = str((mat as BaseMaterial3D).albedo_color)
				print("%s  surface %d: name=%s material=%s albedo=%s" % [indent, i, surf_name, mat_name, albedo])
	else:
		print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_walk(child, depth + 1)
