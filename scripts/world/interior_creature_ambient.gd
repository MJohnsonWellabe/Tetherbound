extends RefCounted
## F17#6 claude-r1 judge: at 23:00 the companion turned saturated blue-violet
## inside the Crossing Hall. The Hall's own materials carry an ambient-only
## occlusion while WorldLook is dark (crossing_hall.gd _build_interior_ambient)
## because the night sky ambient floods the enclosed rooms blue; a creature's
## materials did not, so it alone kept the full blue sky ambient indoors.
##
## Presentation only. While a deployed creature stands in a declared interior
## at night, each of its lit surfaces wears a per-instance copy of its active
## material carrying the same kind of uniform AO map (ambient only,
## ao_light_affect 0): lanterns and the creature's own emission are untouched,
## and the species' shared material is never modified. Leaving the interior or
## daybreak restores exactly the surfaces that still wear a copy, so a material
## another system set meanwhile is kept. Behind crossing_hall.json
## interior_ambient.creature_night_ambient_enabled (default OFF).

const APPLIED_META := &"interior_creature_ambient_surfaces"
const COPY_SUFFIX := "_interior_ambient"


## A uniform occlusion map of this strength (0..1 of the sky ambient kept).
static func occlusion_texture(strength: float) -> Texture2D:
	var image := Image.create(4, 4, false, Image.FORMAT_L8)
	image.fill(Color.from_hsv(0, 0, clampf(strength, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)


## Applies (`on`) or restores the creature's interior night ambient. Safe to
## call every refresh: a surface already wearing its copy is left alone, and
## one whose material was replaced meanwhile is re-copied from the new one.
static func set_indoors_night(root: Node, on: bool, occlusion: Texture2D) -> void:
	var applied: Array = root.get_meta(APPLIED_META, [])
	if not on:
		for row: Array in applied:
			var mesh := row[0] as MeshInstance3D
			if mesh != null and is_instance_valid(mesh) \
					and mesh.get_surface_override_material(int(row[1])) == row[3]:
				mesh.set_surface_override_material(int(row[1]), row[2])
		if root.has_meta(APPLIED_META):
			root.remove_meta(APPLIED_META)
		return
	var kept: Array = []
	for row: Array in applied:
		var mesh := row[0] as MeshInstance3D
		if mesh != null and is_instance_valid(mesh) \
				and mesh.get_surface_override_material(int(row[1])) == row[3]:
			kept.append(row)
	for mesh: MeshInstance3D in _meshes(root):
		if mesh.mesh == null or mesh.material_override != null:
			continue
		for surface in mesh.mesh.get_surface_count():
			if _row_for(kept, mesh, surface) >= 0:
				continue
			var source := mesh.get_active_material(surface) as BaseMaterial3D
			if source == null or not _takes_ambient(source):
				continue
			var copy := source.duplicate() as BaseMaterial3D
			copy.resource_name = source.resource_name + COPY_SUFFIX
			copy.ao_texture = occlusion
			copy.ao_light_affect = 0.0
			copy.ao_enabled = true
			kept.append([mesh, surface, mesh.get_surface_override_material(surface), copy])
			mesh.set_surface_override_material(surface, copy)
	root.set_meta(APPLIED_META, kept)


static func is_applied(root: Node) -> bool:
	return not (root.get_meta(APPLIED_META, []) as Array).is_empty()


## Lit, opaque-or-not surfaces with no AO of their own; unshaded ones (the
## contact shadow, effects) ignore ambient anyway.
static func _takes_ambient(material: BaseMaterial3D) -> bool:
	return material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED \
		and not material.ao_enabled and material.ao_texture == null


static func _row_for(rows: Array, mesh: MeshInstance3D, surface: int) -> int:
	for index in rows.size():
		if rows[index][0] == mesh and int(rows[index][1]) == surface:
			return index
	return -1


static func _meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		out.append(root as MeshInstance3D)
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		out.append(node as MeshInstance3D)
	return out
