extends RefCounted

## The existing Hall/village material family at Cloudreach's architectural scale.
const HALL:=preload("res://assets/environment/team_tether/hall/hall_stone.gdshader")
const CLOTH:=preload("res://assets/environment/team_tether/hall/banner_cloth.gdshader")
const SIGIL:=preload("res://scripts/world/tether_sigil.gd")

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

static func turf_parameters(material: ShaderMaterial,dry: bool) -> void:
	material.set_shader_parameter("grass_texture",preload("res://assets/environment/terrain/stylised/verge_grass_Color.png") if dry else preload("res://assets/environment/terrain/stylised/meadow_grass_Color.png"))
	material.set_shader_parameter("grass_tint",Color("#a2ad78") if dry else Color("#8ca867"))
	material.set_shader_parameter("grass_scale",0.65)

static func ground(dry: bool) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/cloudreach_surface.gdshader")
	turf_parameters(material,dry)
	return material

static func worn_ground(centre: Vector3,radius: float) -> ShaderMaterial:
	var material:=ShaderMaterial.new()
	material.shader=preload("res://shaders/cloudreach_worn_ground.gdshader")
	turf_parameters(material,centre.y>=700.0)
	material.set_shader_parameter("soil_tex",preload("res://assets/environment/terrain/stylised/dirt_path_Color.png"))
	material.set_shader_parameter("soil_tint",Color("#9b805f"))
	material.set_shader_parameter("patch_centre",centre)
	material.set_shader_parameter("radius",radius)
	return material
