extends MeshInstance3D

## The installed stylized water shader samples the offline height texture.
## Currents use the same shared field as traversal; flow markers are separate.
func build(config: Dictionary, visual: Dictionary) -> void:
	var bounds: Dictionary = config.world_bounds
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(bounds.max_x) - float(bounds.min_x), float(bounds.max_z) - float(bounds.min_z))
	mesh = plane
	position = Vector3((float(bounds.min_x) + float(bounds.max_x)) * 0.5, float(config.terrain.sea_level_m), (float(bounds.min_z) + float(bounds.max_z)) * 0.5)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/water.gdshader")
	material.set_shader_parameter("region", Vector4(float(bounds.min_x), float(bounds.min_z), plane.size.x, plane.size.y))
	var image: Image = load("res://data/terrain/water/surface_height.res")
	if image == null:
		push_error("Missing baked Water surface height image")
		return
	material.set_shader_parameter("terrain_height", ImageTexture.create_from_image(image))
	material.set_shader_parameter("height_min", float(bounds.min_y))
	material.set_shader_parameter("height_max", float(bounds.max_y))
	for key: String in visual.water:
		if key.ends_with("colour"):
			material.set_shader_parameter(key, Color(str(visual.water[key])))
		elif not key.begins_with("_") and key != "height_texture_spacing_m":
			material.set_shader_parameter(key, visual.water[key])
	material.set_shader_parameter("wave_normal_a", _noise(11, 0.05, true))
	material.set_shader_parameter("wave_normal_b", _noise(12, 0.09, true))
	material.set_shader_parameter("foam_noise", _noise(13, 0.11, false))
	material_override = material


func _noise(seed_value: int, frequency: float, normal: bool) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_octaves = 3
	noise.frequency = frequency
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.seamless = true
	texture.width = 256
	texture.height = 256
	texture.as_normal_map = normal
	texture.bump_strength = 6.0
	return texture
