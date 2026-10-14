extends RefCounted

## Called only by Tidewake environment builders, never actors or shared imports.
## The family changes light response/detail, retaining authored albedo/alpha.
const PROFILE := preload("res://scripts/world/tidewake_look_profile.gd")
static var _normals: Dictionary = {}
static var _detail_white: Texture2D


static func family(name: String, supplied: Dictionary = {}) -> Dictionary:
	var profile := supplied if not supplied.is_empty() else PROFILE.settings()
	if not bool(profile.get("enabled", false)):
		return {}
	return profile.get("materials", {}).get(name, {})


static func standard(source: StandardMaterial3D, name: String,
		supplied: Dictionary = {}) -> StandardMaterial3D:
	var cfg := family(name, supplied)
	if source == null or cfg.is_empty():
		return source
	# Keep glass, lantern emission and metal identity out of dielectric tuning.
	if source.emission_enabled or source.metallic > 0.1 \
			or source.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return source
	var result := source.duplicate() as StandardMaterial3D
	result.roughness = clampf(source.roughness, float(cfg.roughness_min), float(cfg.roughness_max))
	result.metallic_specular = float(cfg.specular)
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# Preserve imported UVs and base normals. The second layer is metre-scaled,
	# independent of how an installed plank/rock was resized by its builder.
	if not source.detail_enabled and not source.emission_on_uv2:
		result.detail_enabled = true
		# Mix-mode white would bleach every albedo. Multiplication by white is
		# neutral; its alpha blends detail with (rather than erases) base normals.
		result.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		if _detail_white == null:
			var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
			white.fill(Color(1.0, 1.0, 1.0, 0.35))
			_detail_white = ImageTexture.create_from_image(white)
		result.detail_albedo = _detail_white
		result.detail_normal = detail_normal(cfg)
		result.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
		result.uv2_triplanar = true
		result.uv2_world_triplanar = true
		result.uv2_scale = Vector3.ONE * float(cfg.repeats_per_m)
		result.uv2_triplanar_sharpness = 4.0
	return result


static func detail_normal(cfg: Dictionary) -> Texture2D:
	var key := str(cfg.normal_strength)
	if _normals.has(key):
		return _normals[key]
	var noise := FastNoiseLite.new()
	noise.seed = 3913
	noise.frequency = 0.055
	noise.fractal_octaves = 2
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.generate_mipmaps = true
	texture.as_normal_map = true
	texture.bump_strength = float(cfg.normal_strength)
	_normals[key] = texture
	return texture


static func shader(material: ShaderMaterial, name: String) -> void:
	var cfg := family(name)
	if cfg.is_empty():
		return
	material.set_shader_parameter("tidewake_detail_enabled", true)
	material.set_shader_parameter("tidewake_detail_normal", detail_normal(cfg))
	material.set_shader_parameter("tidewake_detail_scale", float(cfg.repeats_per_m))


static func prop(root: Node3D, name: String, supplied: Dictionary = {}) -> void:
	# Explicit static-prop entry points only; no traversal of a gameplay world.
	var profile := supplied if not supplied.is_empty() else PROFILE.settings()
	if family(name, profile).is_empty():
		return
	if root is MeshInstance3D and root.mesh != null:
		var instance := root as MeshInstance3D
		if instance.material_override is StandardMaterial3D:
			instance.material_override = standard(instance.material_override, name, profile)
		elif instance.material_override == null:
			for surface in instance.mesh.get_surface_count():
				var source := instance.get_active_material(surface) as StandardMaterial3D
				if source != null:
					instance.set_surface_override_material(surface, standard(source, name, profile))
	for child: Node in root.get_children():
		if child is Node3D and not child is Skeleton3D:
			prop(child, name, profile)
