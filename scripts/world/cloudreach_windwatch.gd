extends RefCounted

## Installed castle-kit lookout, seated on the settlement's masonry tower.
## Source mesh is unchanged. Clip the scaffold below its gallery deck in a
## derived mesh; burying the full splayed legs leaves them outside the shaft.
const LOOKOUT := preload("res://assets/buildings/quaternius_castle/WatchTowerWRoof.obj")

static func build(parent: Node3D, at: Vector3, stone_height: float,
		cfg: Dictionary, timber: Material, roof: Material) -> MeshInstance3D:
	var model := MeshInstance3D.new()
	model.name = "WindwatchRoofedGallery"
	var bounds := LOOKOUT.get_aabb()
	var width := float(cfg.get("gallery_width_m", 10.5))
	var vertical_scale := float(cfg.get("gallery_vertical_scale", 2.9))
	model.scale = Vector3(width / bounds.size.x, vertical_scale, width / bounds.size.z)
	# Authored floor height in WatchTowerWRoof.obj, measured from its vertices.
	# Seat the clipped floor directly on the crown with a small overlap.
	var floor_y := float(cfg.get("source_gallery_floor_y", 2.012))
	model.mesh = _gallery_mesh(floor_y)
	model.position = at + Vector3.UP * (stone_height + float(cfg.get("deck_clearance_m", 0.28)) - floor_y * vertical_scale)
	for surface in LOOKOUT.get_surface_count():
		var source_material := LOOKOUT.surface_get_material(surface)
		var is_roof := source_material != null and source_material.resource_name == "Celing"
		model.set_surface_override_material(surface, roof if is_roof else timber)
	parent.add_child(model)
	return model


static func _gallery_mesh(floor_y: float) -> ArrayMesh:
	var result := ArrayMesh.new()
	for surface in LOOKOUT.get_surface_count():
		var arrays := LOOKOUT.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for triangle in range(0, indices.size(), 3):
			var polygon: Array[Dictionary] = []
			for corner in 3:
				var index := indices[triangle + corner]
				polygon.append({"p": positions[index], "n": normals[index]})
			var clipped: Array[Dictionary] = []
			for corner in 3:
				var a: Dictionary = polygon[corner]
				var b: Dictionary = polygon[(corner + 1) % 3]
				var a_inside: bool = a.p.y >= floor_y
				var b_inside: bool = b.p.y >= floor_y
				if a_inside:
					clipped.append(a)
				if a_inside != b_inside:
					var weight: float = (floor_y - a.p.y) / (b.p.y - a.p.y)
					clipped.append({"p": (a.p as Vector3).lerp(b.p, weight),
						"n": (a.n as Vector3).lerp(b.n, weight).normalized()})
			for corner in range(1, clipped.size() - 1):
				var edge_a: Vector3 = clipped[corner].p - clipped[0].p
				var edge_b: Vector3 = clipped[corner + 1].p - clipped[0].p
				# A source vertex on the clipping plane can be emitted twice.
				if edge_a.cross(edge_b).length_squared() < 0.000000000001:
					continue
				for vertex: Dictionary in [clipped[0], clipped[corner], clipped[corner + 1]]:
					builder.set_normal(vertex.n)
					builder.add_vertex(vertex.p)
		# Both material surfaces survive this fixed source-deck cut. Triplanar
		# materials need no source UVs; preserve the authored face normals.
		builder.commit(result)
	return result
