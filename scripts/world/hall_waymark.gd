extends RefCounted

## OFF presentation trial: two existing rear cloth surfaces only. No mesh,
## transform, collision, route state, save field or shared material mutation.
static func apply_to(hall: Node3D, cfg: Dictionary) -> bool:
	if not bool(cfg.get("enabled", false)):
		return true
	var shader := load("res://assets/ui/hall_waymark.gdshader") as Shader
	var texture := load(str(cfg.get("texture", ""))) as Texture2D
	if shader == null or texture == null:
		push_error("Hall waymark assets missing")
		return false
	var count := 0
	for id: String in cfg.get("banner_ids", []):
		var banner := hall.find_child(id, true, false)
		if banner == null:
			push_error("Hall waymark banner missing: " + id)
			return false
		for node: Node in banner.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if mi.mesh == null or mi.material_override != null:
				continue
			for surface in mi.mesh.get_surface_count():
				var original := mi.mesh.surface_get_material(surface)
				if original == null or original.resource_name != "MI_Banner":
					continue
				var active := mi.get_active_material(surface)
				if active == null or active.next_pass != null:
					push_error("Hall waymark requires an unlayered cloth material")
					return false
				var arrays := mi.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				if vertices.is_empty():
					return false
				var box := AABB(vertices[0], Vector3.ZERO)
				for v: Vector3 in vertices:
					box = box.expand(v)
				if box.size.x <= 0.0 or box.size.y <= 0.0:
					return false
				var ink := ShaderMaterial.new()
				ink.shader = shader
				ink.set_shader_parameter("waymark", texture)
				ink.set_shader_parameter("cloth_min", Vector2(box.position.x, box.position.y))
				ink.set_shader_parameter("cloth_size", Vector2(box.size.x, box.size.y))
				ink.set_shader_parameter("ink_opacity", float(cfg.get("ink_opacity", 0.85)))
				var own := active.duplicate(true) as Material
				own.next_pass = ink
				mi.set_surface_override_material(surface, own)
				count += 1
	if count != 2:
		push_error("Hall waymark requires exactly two cloth surfaces, found %d" % count)
		return false
	print("HALL_WAYMARK cloth_surfaces=2 mesh_and_transforms_unchanged=true")
	return true
