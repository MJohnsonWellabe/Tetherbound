extends MeshInstance3D

## The installed stylized water shader samples the offline height texture.
## Currents use the same shared field as traversal; flow markers are separate.
func build(config: Dictionary, visual: Dictionary) -> void:
	var bounds: Dictionary = config.world_bounds
	var plane := PlaneMesh.new()
	var region_size := Vector2(float(bounds.max_x) - float(bounds.min_x),
			float(bounds.max_z) - float(bounds.min_z))
	# Continue each edge beyond the shipping camera far clip. This derives from
	# the existing authored view contract, so it does not invalidate terrain
	# bake provenance for a render-only setting.
	var extension_margin := maxf(0.0, float(visual.view.camera_far_m) + 500.0)
	plane.size = region_size + Vector2.ONE * extension_margin * 2.0
	mesh = plane
	position = Vector3((float(bounds.min_x) + float(bounds.max_x)) * 0.5, float(config.terrain.sea_level_m), (float(bounds.min_z) + float(bounds.max_z)) * 0.5)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/water.gdshader")
	# Height sampling remains constrained to the authored terrain rectangle;
	# the larger plane is only a horizon-safe visual continuation.
	material.set_shader_parameter("region", Vector4(float(bounds.min_x), float(bounds.min_z),
			region_size.x, region_size.y))
	var image: Image = load("res://data/terrain/water/surface_height.res")
	if image == null:
		push_error("Missing baked Water surface height image")
		return
	material.set_shader_parameter("terrain_height", ImageTexture.create_from_image(image))
	material.set_shader_parameter("height_min", float(bounds.min_y))
	material.set_shader_parameter("height_max", float(bounds.max_y))
	material.set_shader_parameter("outside_region_deep_water", true)
	for key: String in visual.water:
		if key.ends_with("colour"):
			material.set_shader_parameter(key, Color(str(visual.water[key])))
		elif not key.begins_with("_") and key not in ["height_texture_spacing_m", "roughness", "night_dim_max", "night_dim_rate"]:
			material.set_shader_parameter(key, visual.water[key])
	material.set_shader_parameter("roughness_value", float(visual.water.get("roughness", 0.12)))
	material.set_shader_parameter("wave_normal_a", _noise(11, 0.05, true))
	material.set_shader_parameter("wave_normal_b", _noise(12, 0.09, true))
	material.set_shader_parameter("foam_noise", _noise(13, 0.11, false))
	material_override = preload("res://scripts/world/water_offshore_material.gd").apply(material)
	# tb/vis-tidewake-1104: optional night dim. Absent `night_dim_max` keeps the
	# water exactly as before and never processes.
	_night_dim_max = clampf(float(visual.water.get("night_dim_max", 0.0)), 0.0, 1.0)
	_night_dim_rate = maxf(0.01, float(visual.water.get("night_dim_rate", 0.5)))
	set_process(_night_dim_max > 0.0)


var _night_dim_max := 0.0
var _night_dim_rate := 0.5
var _night_dim := -1.0


## Eases the water's night dim toward the day cycle's dark state. Presentation
## only: one shader parameter, no physics, save or authority state.
func _process(delta: float) -> void:
	var cycle := get_tree().get_first_node_in_group("day_cycle")
	var target := _night_dim_max if cycle != null and bool(cycle.call("is_dark")) else 0.0
	_night_dim = target if _night_dim < 0.0 else move_toward(_night_dim, target, _night_dim_rate * delta)
	var water := material_override as ShaderMaterial
	if water != null:
		water.set_shader_parameter("night_dim", _night_dim)


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
