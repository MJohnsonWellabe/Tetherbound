extends RefCounted

## Material-only visibility for installed cutout leaves that overlap the trainer
## corridor. Distance alone removed unrelated peripheral plants in native review.
const CONFIG_PATH := "res://data/config/foliage_camera_visibility.json"
const LEAF_SHADER := preload("res://scripts/world/foliage_camera_visibility.gdshader")
static var _config: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if parsed is Dictionary:
			_config = parsed
	return _config

static func apply(mesh: Mesh, model_path: String, layer: Dictionary) -> Mesh:
	var cfg := config()
	if mesh == null or not bool(cfg.get("enabled", false)) or bool(layer.get("collides", true)) \
			or not model_path in cfg.get("models", []):
		return mesh
	var near_m := maxf(0.0, float(cfg.get("invisible_below_m", 5.8)))
	var far_m := maxf(near_m + 0.1, float(cfg.get("opaque_above_m", 8.0)))
	# Keep the imported geometry/LOD chain and leave cached tint materials alone.
	var result := mesh.duplicate(false) as Mesh
	for surface in result.get_surface_count():
		var source := mesh.surface_get_material(surface) as BaseMaterial3D
		if source == null:
			continue
		# These three installed models plus vegetation._tint_for define the
		# material contract; this is not a general StandardMaterial converter.
		# Normal, emissive and metal variants stay on the original material.
		if source.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR \
				or source.normal_enabled or source.emission_enabled or source.metallic > 0.0 \
				or source.cull_mode != BaseMaterial3D.CULL_DISABLED:
			continue
		var material := ShaderMaterial.new()
		material.shader = LEAF_SHADER
		material.set_meta("foliage_unfaded_material",source)
		material.set_shader_parameter("leaf_texture",source.albedo_texture)
		material.set_shader_parameter("leaf_tint",source.albedo_color)
		material.set_shader_parameter("leaf_backlight",source.backlight if source.backlight_enabled else Color.BLACK)
		material.set_shader_parameter("use_vertex_tint",source.vertex_color_use_as_albedo)
		material.set_shader_parameter("leaf_roughness",source.roughness)
		material.set_shader_parameter("alpha_cutoff",source.alpha_scissor_threshold)
		material.set_shader_parameter("alpha_edge",source.alpha_antialiasing_edge)
		material.set_shader_parameter("bounds_center",mesh.get_aabb().get_center())
		material.set_shader_parameter("bounds_half_size",mesh.get_aabb().size * 0.5)
		material.set_shader_parameter("clear_distance",near_m)
		material.set_shader_parameter("opaque_distance",far_m)
		var rect: Array = cfg.get("trainer_rect",[0.455,0.49,0.545,0.73])
		material.set_shader_parameter("trainer_rect",Vector4(rect[0],rect[1],rect[2],rect[3]))
		material.set_shader_parameter("edge_feather",float(cfg.get("edge_feather",0.025)))
		result.surface_set_material(surface, material)
	return result


## F10#2 (coordinator decision, 13 Oct): the fight camera's lens entered
## Stormwood bark and canopy that reach past their trunk colliders (black and
## green frames at Conductor Run and Deepwood). Every surface of a listed tree
## model dithers out near the lens (StandardMaterial3D distance fade, pixel
## dither): fully gone inside `invisible_below_m`, solid beyond `opaque_above_m`.
## Presentation only; placements, colliders and the scatter bake are unchanged.
static func near_lens_fade(mesh: Mesh, model_path: String, realm: String) -> Mesh:
	var cfg: Dictionary = config().get("near_lens_fade", {})
	if mesh == null or not bool(cfg.get("enabled", false)) or not realm in cfg.get("realms", []) \
			or not model_path in cfg.get("models", []):
		return mesh
	var near_m := maxf(0.0, float(cfg.get("invisible_below_m", 1.0)))
	var far_m := maxf(near_m + 0.1, float(cfg.get("opaque_above_m", 3.0)))
	var result := mesh.duplicate(false) as Mesh
	for surface in result.get_surface_count():
		var source := result.surface_get_material(surface) as BaseMaterial3D
		if source == null:
			continue
		var faded := source.duplicate() as BaseMaterial3D
		faded.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		faded.distance_fade_min_distance = near_m
		faded.distance_fade_max_distance = far_m
		result.surface_set_material(surface, faded)
	return result
