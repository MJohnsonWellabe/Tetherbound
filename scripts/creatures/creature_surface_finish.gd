extends RefCounted

## Presentation-only regional replacements over the installed UV texture.
## Keep the base material for shadows, alpha/rim policy and other next passes.
const DATA := preload("res://scripts/data/redesign_data.gd")
const SHADER := preload("res://shaders/creature_surface_finish.gdshader")
static var _materials: Dictionary = {}
static var _copies_by_source: Dictionary = {}

static func has_finish(species: String, shiny: bool) -> bool:
	var config: Dictionary = DATA.json_view("res://data/config/creature_surface_finishes.json")
	var row: Dictionary = config.get("species", {}).get(species.trim_prefix("water_"), {})
	return config.get("enabled") == true and not row.get("shiny" if shiny else "ordinary", {}).is_empty()

static func apply(model: Node, species: String, shiny: bool) -> void:
	if model == null: return
	var config: Dictionary = DATA.json_view("res://data/config/creature_surface_finishes.json")
	if config.get("enabled") != true: return
	var row: Dictionary = config.get("species", {}).get(species.trim_prefix("water_"), {})
	var mode := "shiny" if shiny else "ordinary"
	var finish: Dictionary = row.get(mode, {})
	if finish.is_empty(): return
	var pending: Array[Node] = [model]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		pending.append_array(node.get_children())
		if not node is MeshInstance3D or node.mesh == null: continue
		for surface in node.mesh.get_surface_count():
			var source: Material = node.get_active_material(surface)
			if not source is BaseMaterial3D or source.albedo_texture == null: continue
			if source.get_meta("regional_surface_finish", "") == species + ":" + mode: continue
			var key := "%d:%s:%s" % [source.get_instance_id(), species, mode]
			if not _materials.has(key):
				var copy := source.duplicate() as BaseMaterial3D
				copy.resource_name = "%s_finish_%s_%s" % [source.resource_name, species, mode]
				var overlay := ShaderMaterial.new()
				overlay.shader = SHADER
				overlay.set_shader_parameter("source_albedo", source.albedo_texture)
				overlay.set_shader_parameter("source_uv_scale", Vector2(source.uv1_scale.x, source.uv1_scale.y))
				overlay.set_shader_parameter("source_uv_offset", Vector2(source.uv1_offset.x, source.uv1_offset.y))
				overlay.set_shader_parameter("has_normal", source.normal_enabled and source.normal_texture != null)
				if source.normal_texture != null: overlay.set_shader_parameter("source_normal", source.normal_texture)
				overlay.set_shader_parameter("normal_strength", source.normal_scale)
				overlay.set_shader_parameter("surface_roughness", source.roughness)
				overlay.set_shader_parameter("surface_metallic", source.metallic)
				overlay.set_shader_parameter("rim_amount", source.rim if source.rim_enabled else 0.0)
				for parameter: String in finish:
					var value: Variant = finish[parameter]
					if parameter in ["accent_source_hue", "body_source_hue"]: value = Vector2(float(value[0]), float(value[1]))
					overlay.set_shader_parameter(parameter, value)
				overlay.next_pass = source.next_pass
				copy.next_pass = overlay
				copy.set_meta("regional_surface_finish", species + ":" + mode)
				sync_lighting(copy)
				var source_id := source.get_instance_id()
				if not _copies_by_source.has(source_id): _copies_by_source[source_id] = []
				_copies_by_source[source_id].append(copy)
				_materials[key] = copy
			node.set_surface_override_material(surface, _materials[key])


## The existing clock updates BaseMaterial3D copies. Their attached finish
## must receive those same values, including after the night-floor wrapper.
static func sync_lighting(material: BaseMaterial3D) -> void:
	for copy: BaseMaterial3D in _copies_by_source.get(material.get_instance_id(), []):
		copy.albedo_color = material.albedo_color
		copy.emission_enabled = material.emission_enabled
		copy.emission_texture = material.emission_texture
		copy.emission = material.emission
		copy.emission_energy_multiplier = material.emission_energy_multiplier
		sync_lighting(copy)
	if not material.has_meta("regional_surface_finish"): return
	var overlay := material.next_pass as ShaderMaterial
	if overlay == null or overlay.shader != SHADER: return
	overlay.set_shader_parameter("source_tint", material.albedo_color)
	overlay.set_shader_parameter("has_emission_texture", material.emission_texture != null)
	if material.emission_texture != null: overlay.set_shader_parameter("source_emission", material.emission_texture)
	var tint := material.emission
	var gain := material.emission_energy_multiplier * maxf(tint.r, maxf(tint.g, tint.b)) if material.emission_enabled else 0.0
	overlay.set_shader_parameter("emission_gain", gain)
