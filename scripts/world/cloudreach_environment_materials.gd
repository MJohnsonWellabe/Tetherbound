extends RefCounted

## The existing Hall/village material family at Cloudreach's architectural scale.
const HALL:=preload("res://assets/environment/team_tether/hall/hall_stone.gdshader")
const CLOTH:=preload("res://assets/environment/team_tether/hall/banner_cloth.gdshader")
const SIGIL:=preload("res://scripts/world/tether_sigil.gd")

## One texture, palette and metre-scale relief policy for all natural stone.
## The caller owns the OFF gate; this factory also reproduces baseline cliffs.
static func geology(config: Dictionary) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/cloudreach_cliff.gdshader")
	material.set_shader_parameter("rock_texture", load(str(config.get("albedo",
		"res://assets/environment/terrain/Rock030_Color.jpg"))))
	material.set_shader_parameter("rock_normal", load(str(config.get("normal",
		"res://assets/environment/terrain/Rock030_NormalGL.jpg"))))
	for key: String in ["stone_light", "stone_dark", "strata_ochre_tint", "ledge_moss_tint"]:
		if config.has(key):
			var colour := Color(str(config[key]))
			material.set_shader_parameter(key, Vector3(colour.r, colour.g, colour.b))
	for key: String in ["texture_scale", "normal_scale", "strata_period_m", "strata_strength",
			"strata_ochre_strength", "ledge_moss_strength", "ledge_lighten",
			"ledge_normal_threshold", "crevice_strength", "crevice_scale"]:
		if config.has(key):
			material.set_shader_parameter(key, float(config[key]))
	return material


static func masonry(trim: bool=false) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=HALL
	material.set_shader_parameter("albedo_tex",preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png"))
	material.set_shader_parameter("normal_tex",preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png"))
	material.set_shader_parameter("rough_tex",preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png"))
	material.set_shader_parameter("tint",Color("#b7b19e") if trim else Color("#8d927f"))
	material.set_shader_parameter("tile",0.28)
	material.set_shader_parameter("moss_amount",0.43)
	material.set_shader_parameter("up_moss",0.35)
	material.set_shader_parameter("streak_strength",0.24)
	# Shared by architecture on six altitudes; do not treat lower realms as
	# submerged beneath the summit's damp band.
	material.set_shader_parameter("damp_strength",0.0)
	return material

## Same installed stone family, with exposed highland stone separated from
## the darker occupied route wings. Config owns the visual tuning.
static func aviary_masonry(trim: bool, surface: Dictionary) -> ShaderMaterial:
	var material := masonry(trim)
	var tint_key := "trim_tint" if trim else "stone_tint"
	material.set_shader_parameter("tint", Color(str(surface.get(tint_key, "#b9b8aa"))))
	for key: String in ["moss_amount", "up_moss", "streak_strength", "macro_strength", "tile"]:
		if surface.has(key):
			material.set_shader_parameter(key, float(surface[key]))
	return material


static func banner(size: Vector2, phase: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=CLOTH
	# CLOUDREACH-DRESS-0906 / C6. The blind judge on the final arena: "The
	# banners are a pinkish crimson, not the board's oxblood -- they read as
	# festival bunting rather than a threat." #66362c is a mid brown-red, and
	# under this realm's noon key plus the ACES shoulder a mid red rides up
	# into pink; the cloth shader then multiplies it by a fold shade that
	# reaches 1.15, which lifts the lit side further. Dropped to a genuinely
	# dark oxblood so the LIT value lands where #66362c was only ever the
	# unlit value. The Hall keeps its own BANNER_COLOUR; this factory is
	# Cloudreach-only.
	material.set_shader_parameter("colour",Color("#4a2018"))
	material.set_shader_parameter("selvage_colour",Color("#2c1310"))
	material.set_shader_parameter("device_colour",Color("#e8ddc4"))
	material.set_shader_parameter("device_tex",SIGIL.texture())
	material.set_shader_parameter("size",size)
	material.set_shader_parameter("sway",0.28)
	material.set_shader_parameter("speed",0.65)
	material.set_shader_parameter("phase",phase)
	return material

## data/config/cloudreach_ground_cluster.json when enabled (or previewed with
## --cloudreach-cluster-candidate), else {}.
static func ground_cluster() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_ground_cluster.json"))
	if not parsed is Dictionary:
		return {}
	if not bool((parsed as Dictionary).get("enabled", false)) and not OS.get_cmdline_user_args().has("--cloudreach-cluster-candidate"):
		return {}
	return parsed


## The same field as cloudreach_turf.gdshaderinc's cloudreach_turf_patch.
static func turf_patch_field(x: float, z: float, frequency: float) -> float:
	var px := x * frequency
	var pz := z * frequency
	var a := sin(px + sin(pz * 1.37) * 1.7) * sin(pz * 0.91 + sin(px * 1.13) * 1.3)
	var b := sin(px * 2.31 + 1.9 + sin(pz * 2.7) * 1.1) * sin(pz * 2.07 + 0.7 + sin(px * 1.9) * 1.2)
	return a * 0.72 + b * 0.28


static func turf_parameters(material: ShaderMaterial,dry: bool) -> void:
	preload("res://scripts/world/cloudreach_biome_look.gd").material_detail(material, "turf")
	material.set_shader_parameter("grass_texture",preload("res://assets/environment/terrain/stylised/verge_grass_Color.png") if dry else preload("res://assets/environment/terrain/stylised/meadow_grass_Color.png"))
	# An F40 items candidate may retint the turf (blades match it via turf_match).
	var turf: Dictionary = preload("res://scripts/world/cloudreach_settlement_life.gd").items_config().get("turf", {})
	material.set_shader_parameter("grass_tint",Color(str(turf.get("dry_grass_tint", "#a2ad78"))) if dry \
		else Color(str(turf.get("grass_tint", "#8ca867"))))
	material.set_shader_parameter("grass_scale",0.65)
	# tb/vis-water-sky group 2 (flag-off): dry/lush turf patches.
	var cluster := ground_cluster()
	if not cluster.is_empty():
		material.set_shader_parameter("turf_patch_strength", float(cluster.get("strength", 0.75)))
		material.set_shader_parameter("turf_patch_freq", float(cluster.get("frequency", 0.035)))
		material.set_shader_parameter("turf_dry_tint", Color(str(cluster.get("dry_tint", "#c9bd7c"))))
		material.set_shader_parameter("turf_lush_tint", Color(str(cluster.get("lush_tint", "#5f8343"))))
		var dry_band: Array = cluster.get("dry_band", [0.35, 0.6])
		var lush_band: Array = cluster.get("lush_band", [0.3, 0.55])
		material.set_shader_parameter("turf_dry_band", Vector2(float(dry_band[0]), float(dry_band[1])))
		material.set_shader_parameter("turf_lush_band", Vector2(float(lush_band[0]), float(lush_band[1])))

static func ground_cover_parameters(material: ShaderMaterial, dry: bool, config: Dictionary) -> void:
	turf_parameters(material, dry)
	material.set_shader_parameter("turf_match", float(config.get("turf_match", 0.85)))
	material.set_shader_parameter("turf_root_gain", float(config.get("turf_root_gain", 0.8)))
	material.set_shader_parameter("turf_tip_gain", float(config.get("turf_tip_gain", 1.5)))

static func ground(dry: bool, geology: ShaderMaterial = null, bank: Dictionary = {}) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/cloudreach_surface.gdshader")
	turf_parameters(material,dry)
	# Copy the built realm's actual geology parameters, including its installed
	# textures. Crown banks and cliff walls must remain one material family.
	if geology != null:
		for uniform: Dictionary in geology.shader.get_shader_uniform_list():
			var key := str(uniform.name)
			var value: Variant = geology.get_shader_parameter(key)
			if value != null:
				material.set_shader_parameter(key, value)
	material.set_shader_parameter("grass_slope_cos", cos(deg_to_rad(float(bank.get("grass_slope_degrees", 34.0)))))
	material.set_shader_parameter("rock_slope_cos", cos(deg_to_rad(float(bank.get("rock_slope_degrees", 56.0)))))
	material.set_shader_parameter("edge_breakup", float(bank.get("edge_breakup", 0.055)))
	return material

static func worn_ground(centre: Vector3,radius: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/cloudreach_worn_ground.gdshader")
	preload("res://scripts/world/cloudreach_biome_look.gd").material_detail(material, "soil")
	# Soil is an overlay on turf or paving. Draw it before live hazard tells.
	material.render_priority=-1
	material.set_shader_parameter("soil_tex",preload("res://assets/environment/terrain/stylised/dirt_path_Color.png"))
	material.set_shader_parameter("soil_tint",Color("#9b805f"))
	material.set_shader_parameter("patch_centre",centre)
	material.set_shader_parameter("radius",radius)
	return material
