extends RefCounted

## Cause lane LANDMARKS (1 Nov): the 1101 Meshy hero landmarks as three
## independent render-only candidates, each OFF until GPU judged
## (data/config/hero_landmarks_1101.json; assets and provenance in
## assets/props/meshy-1101/<id>). None adds or moves a collider, trigger,
## route, gate or terrain sample; each only adds visuals or hides old visuals.
const CONFIG := "res://data/config/hero_landmarks_1101.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const FAR_SHADER := preload("res://shaders/meshy_far_landmark.gdshader")
const GLASS_SINK_NODE := "GlassSinkHero1101"
const VEILFALL_NODE := "VeilfallHero1101"


static func settings() -> Dictionary:
	if not FileAccess.file_exists(CONFIG):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return parsed if parsed is Dictionary else {}


static func section(id: String, config: Dictionary = {}) -> Dictionary:
	var source := config if not config.is_empty() else settings()
	var value: Variant = source.get(id, {})
	return value if value is Dictionary else {}


static func enabled(id: String, config: Dictionary = {}) -> bool:
	return bool(section(id, config).get("enabled", false))


## Crown Arch (P2-041): overlay the hero arch settings, after round 2, with the
## 1101 model keys. OFF returns `cfg` unchanged; ON replaces only declared keys,
## never yaw, slab or passage keys.
static func crown_arch_overlay(cfg: Dictionary, config: Dictionary = {}) -> Dictionary:
	var cand := section("crown_arch", config)
	if not bool(cand.get("enabled", false)):
		return cfg
	var merged := cfg.duplicate(true)
	for key: String in cand:
		if key == "enabled" or key.begins_with("_"):
			continue
		merged[key] = cand[key]
	return merged


## Glass Sink (P2-070): the terraced basin ring set into the sink floor with a
## glass pool in its open centre. `world` needs ground_height_at only for the
## receipt; placement is absolute (centre_xz, rim_top_y, floor_y - bury_m).
static func dress_glass_sink(world: Node3D, sink: Dictionary, config: Dictionary = {}) -> Node3D:
	var cfg := section("glass_sink", config)
	if not bool(cfg.get("enabled", false)) or world == null or world.has_node(GLASS_SINK_NODE):
		return null
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		push_warning("Glass Sink 1101 hero model missing: " + str(cfg.get("model", "")))
		return null
	var floor_y := float(sink.get("floor_y", -65.0))
	var bottom := floor_y - float(cfg.get("bury_m", 6.0))
	var height := float(cfg.get("rim_top_y", 38.0)) - bottom
	var across := float(cfg.get("across_m", 300.0))
	var bounds := BOUNDS.measure(model)
	var plan := across / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	var lift := height / maxf(0.01, bounds.size.y)
	model.scale = Vector3(plan, lift, plan)
	model.position = Vector3(-bounds.get_center().x * plan, -bounds.position.y * lift,
		-bounds.get_center().z * plan)
	if cfg.has("glow_colour"):
		HERO_PROP.glow(model, Color(str(cfg.glow_colour)), float(cfg.get("glow_energy", 1.0)))
	_no_shadow_cost(model)
	var root := Node3D.new()
	root.name = GLASS_SINK_NODE
	var centre: Array = cfg.get("centre_xz", [700.0, 2350.0])
	root.position = Vector3(float(centre[0]), bottom, float(centre[1]))
	root.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	root.add_child(model)
	var pool_cfg: Dictionary = cfg.get("pool", {}) as Dictionary
	if not pool_cfg.is_empty():
		root.add_child(_glass_pool(pool_cfg, across * 0.5, floor_y - bottom))
	world.add_child(root)
	return root


static func _glass_pool(cfg: Dictionary, outer_radius: float, floor_above_bottom: float) -> MeshInstance3D:
	var disc := CylinderMesh.new()
	var radius := outer_radius * float(cfg.get("radius_fraction", 0.6))
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.2
	disc.radial_segments = 64
	disc.rings = 1
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(str(cfg.get("colour", "#151a2c")))
	glass.metallic = float(cfg.get("metallic", 0.25))
	glass.roughness = float(cfg.get("roughness", 0.07))
	glass.metallic_specular = float(cfg.get("specular", 0.8))
	if cfg.has("rim_tint"):
		glass.rim_enabled = true
		glass.rim = float(cfg.get("rim_strength", 0.35))
		glass.rim_tint = 0.0
		glass.albedo_color = glass.albedo_color.lerp(Color(str(cfg.rim_tint)), 0.08)
	disc.material = glass
	var pool := MeshInstance3D.new()
	pool.name = "GlassPool"
	pool.mesh = disc
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pool.position = Vector3(0.0, floor_above_bottom + float(cfg.get("lift_m", 0.6)), 0.0)
	return pool


## Veilfall (P2-010 / F39#4): beyond the far handoff, the Meshy sea-cliff
## mountain replaces the polar-grid cone. `silhouette` is VeilfallFarSilhouette
## (its fog copy feeds the far shader); `falls` is VeilfallWhiteFalls.
static func dress_veilfall(parent: Node3D, silhouette: MeshInstance3D, falls: Node3D,
		config: Dictionary = {}) -> Node3D:
	var cfg := section("veilfall", config)
	if not bool(cfg.get("enabled", false)) or parent == null or parent.has_node(VEILFALL_NODE):
		return null
	var model := HERO_PROP.load_model(str(cfg.get("model", "")))
	if model == null:
		push_warning("Veilfall 1101 hero model missing: " + str(cfg.get("model", "")))
		return null
	var bounds := BOUNDS.measure(model)
	var factor := float(cfg.get("across_m", 800.0)) / maxf(0.01, maxf(bounds.size.x, bounds.size.z))
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-bounds.get_center().x * factor, -bounds.position.y * factor,
		-bounds.get_center().z * factor)
	var centre: Array = cfg.get("centre_xz", [200.0, 4140.0])
	var centre_xz := Vector2(float(centre[0]), float(centre[1]))
	var from_m := float(cfg.get("visible_from_m", 1100.0))
	var margin := float(cfg.get("visible_from_margin_m", 60.0))
	for material: ShaderMaterial in _far_materials(model, cfg.get("shader", {}) as Dictionary, centre_xz):
		if silhouette != null and silhouette.has_method("register_fogged"):
			silhouette.call("register_fogged", material)
	for visual: GeometryInstance3D in _geometry(model):
		visual.visibility_range_begin = from_m
		visual.visibility_range_begin_margin = margin
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual.extra_cull_margin = 80.0
	var root := Node3D.new()
	root.name = VEILFALL_NODE
	root.position = Vector3(centre_xz.x, float(cfg.get("base_y", 0.0)) - float(cfg.get("sink_m", 8.0)), centre_xz.y)
	root.rotation.y = deg_to_rad(float(cfg.get("yaw_deg", 168.0)))
	root.add_child(model)
	parent.add_child(root)
	if silhouette != null:
		# Layer 0 hides only the polar-grid cone itself (its fog poll keeps
		# running for the registered materials); colliders are elsewhere.
		silhouette.layers = 0
		if bool(cfg.get("hide_far_crags", true)):
			for child: Node in silhouette.get_children():
				if child is GeometryInstance3D and str(child.name).begins_with("Far_"):
					(child as GeometryInstance3D).visible = false
	var falls_from := float(cfg.get("old_falls_far_hidden_from_m", 0.0))
	if falls != null and falls_from > 0.0:
		for visual: GeometryInstance3D in _geometry(falls):
			if visual.visibility_range_end <= 0.0 or visual.visibility_range_end > falls_from:
				visual.visibility_range_end = falls_from
	return root


static func _far_materials(model: Node3D, shader_cfg: Dictionary, centre_xz: Vector2) -> Array[ShaderMaterial]:
	var made: Array[ShaderMaterial] = []
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if visual.mesh == null:
			continue
		for surface in visual.mesh.get_surface_count():
			var source := visual.get_active_material(surface) as BaseMaterial3D
			var far := ShaderMaterial.new()
			far.shader = FAR_SHADER
			if source != null and source.albedo_texture != null:
				far.set_shader_parameter("albedo_tex", source.albedo_texture)
			for key: String in shader_cfg:
				if key.begins_with("_"):
					continue
				var value: Variant = shader_cfg[key]
				far.set_shader_parameter(key, Color(str(value)) if value is String else value)
			far.set_shader_parameter("centre_xz", centre_xz)
			visual.set_surface_override_material(surface, far)
			made.append(far)
	return made


static func _geometry(root: Node) -> Array[GeometryInstance3D]:
	var found: Array[GeometryInstance3D] = []
	if root is GeometryInstance3D:
		found.append(root as GeometryInstance3D)
	for child: Node in root.find_children("*", "GeometryInstance3D", true, false):
		found.append(child as GeometryInstance3D)
	return found


static func _no_shadow_cost(model: Node3D) -> void:
	# The basin is seen from 80-500 m below the camera: it receives the sun but
	# casting would only shadow the floor plane the ring already covers.
	for visual: GeometryInstance3D in _geometry(model):
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
