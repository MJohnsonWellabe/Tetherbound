extends RefCounted

## P2-046 candidate confined to the existing Voltcap harvest visual.
const CONFIG_PATH := "res://data/config/stormwood_voltcap_finish.json"
const SURFACE := preload("res://shaders/stormwood_voltcap_finish.gdshader")
static var capture_preview := false


static func read_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		return {}
	if capture_preview:
		parsed["enabled"] = true
	return parsed


static func apply(visual: Node3D, profile: Dictionary) -> int:
	if visual == null or not bool(profile.get("enabled", false)):
		return 0
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
	if visual is MeshInstance3D:
		meshes.push_front(visual)
	var variants: Dictionary = {}
	var count := 0
	for child: Node in meshes:
		var mesh_node := child as MeshInstance3D
		if mesh_node.mesh == null or mesh_node.material_override != null:
			continue
		for surface in mesh_node.mesh.get_surface_count():
			var source := mesh_node.get_active_material(surface) as StandardMaterial3D
			# Refuse unrecognized effects/materials rather than flattening them.
			if source == null or source.albedo_texture == null or source.normal_enabled \
					or source.emission_enabled or source.metallic > 0.0 \
					or source.detail_enabled or source.uv1_scale != Vector3.ONE \
					or source.uv1_offset != Vector3.ZERO \
					or source.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
					or source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
					or source.cull_mode != BaseMaterial3D.CULL_DISABLED:
				continue
			var key := source.get_instance_id()
			if not variants.has(key):
				var material := ShaderMaterial.new()
				material.shader = SURFACE
				material.set_shader_parameter("source_texture", source.albedo_texture)
				material.set_shader_parameter("source_tint", source.albedo_color)
				material.set_shader_parameter("use_vertex_colour", source.vertex_color_use_as_albedo)
				for field: String in ["cap_shadow", "cap_light", "gill_shadow", "gill_light", "rim_colour"]:
					material.set_shader_parameter(field, Color(str(profile[field])))
				for field: String in ["rim_energy", "cap_roughness", "gill_roughness", "cap_normal_low", "cap_normal_high", "rim_value_low", "rim_value_high", "rim_saturation_max"]:
					material.set_shader_parameter(field, float(profile[field]))
				variants[key] = material
			mesh_node.set_surface_override_material(surface, variants[key])
			count += 1
	return count
