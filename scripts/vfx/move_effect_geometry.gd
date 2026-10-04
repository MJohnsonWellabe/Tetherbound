extends RefCounted

const FIRE_SHADER := preload("res://assets/vfx/shaders/fire_body.gdshader")
const FIRE_CORE_SHADER := preload("res://assets/vfx/shaders/fire_core.gdshader")
const ION_SHADER := preload("res://assets/vfx/shaders/ion_filament.gdshader")
const STONE_SHADER := preload("res://assets/vfx/shaders/stone_body.gdshader")
const STONE_TEXTURE := preload("res://assets/environment/terrain/stylised/rock_scree_Color.png")
const FLUID := preload("res://scripts/vfx/fluid_effect_geometry.gd")
const FLOW_SHADER := preload("res://assets/vfx/shaders/flowing_water.gdshader")
const ICE_SHADER := preload("res://assets/vfx/shaders/ice_crystal.gdshader")
const DUST_SHADER := preload("res://assets/vfx/shaders/dust_plume.gdshader")
const AUTHORED := preload("res://scripts/vfx/authored_effect_geometry.gd")
const TONGUE_SHADER := preload("res://assets/vfx/shaders/flame_tongue.gdshader")
const TONGUE_TEXTURE := preload("res://assets/vfx/textures/flame_tongue_v2.png")
const EXPLOSION_SHADER := preload("res://assets/vfx/shaders/fire_explosion.gdshader")
const WIND_SHADER := preload("res://assets/vfx/shaders/wind_surface.gdshader")
const BUBBLE_SHADER := preload("res://assets/vfx/shaders/bubble_surface.gdshader")
const SHADOW_SHADER := preload("res://assets/vfx/shaders/shadow_surface.gdshader")
const ROOT_STONE_SHADER := preload("res://assets/vfx/shaders/root_stone_surface.gdshader")
const ORGANIC := preload("res://scripts/vfx/organic_effect_geometry.gd")

## All bodies are real depth-tested meshes on Compatibility as well as
## Forward+. No screen-space distortion or GPU particles are required.
static func material(colour: Color, opacity: float = 1.0, lit: bool = false) -> StandardMaterial3D:
	var out := StandardMaterial3D.new()
	out.albedo_color = Color(colour.r, colour.g, colour.b, opacity)
	out.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL if lit else BaseMaterial3D.SHADING_MODE_UNSHADED
	out.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if opacity < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	out.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	out.cull_mode = BaseMaterial3D.CULL_DISABLED
	out.roughness = 0.8
	out.vertex_color_use_as_albedo = true
	out.no_depth_test = false
	return out

static func shape(kind: String, size: float, profile: Dictionary = {}) -> Mesh:
	if kind == "ring" and profile.has("rib_style"): return ORGANIC.ribs(size, profile)
	if kind == "crescent" and bool(profile.get("authored_slash", false)): return ORGANIC.slash(size, profile)
	if kind == "spike" and bool(profile.get("authored_root", false)): return ORGANIC.root_spire(size, profile)
	match kind:
		"flame_tongue":
			return AUTHORED.flame_tongue(size, profile)
		"contact_burst":
			return AUTHORED.contact_burst(size, profile)
		"electrical_splash":
			return AUTHORED.electrical_splash(size, profile)
		"water_stream", "flame_volume", "mist_cone":
			return FLUID.water_stream(size, profile)
		"rolling_wave":
			return FLUID.rolling_wave(size, profile)
		"ice_crystal":
			return FLUID.ice_crystal(size, profile)
		"stone":
			return stone(size, profile)
		"flame_orb", "fire_bloom", "fire_explosion", "soft_dust", "soft_ember", "soft_foam":
			var card := QuadMesh.new()
			card.size = Vector2.ONE * size * float(profile.get("card_extent_scale", 3.2))
			return card
		"orb", "bubble", "burning_core":
			var sphere := SphereMesh.new()
			sphere.radius = size
			sphere.height = size * 2.0
			sphere.radial_segments = int(profile.get("segments", 8 if kind == "stone" else 16))
			sphere.rings = int(profile.get("rings", 4 if kind == "stone" else 8))
			return sphere
		"rock_splash", "lightning_crack":
			return impact_rays(size, profile, kind == "lightning_crack")
		"shard", "spike", "cone", "stream":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = size * float(profile.get("tip_ratio", 0.0 if kind != "stream" else 0.7))
			cylinder.bottom_radius = size
			cylinder.height = size * float(profile.get("height_ratio", 3.0))
			cylinder.radial_segments = int(profile.get("segments", 5 if kind in ["shard", "spike"] else 12))
			return cylinder
		"ring", "crescent":
			return band(size, float(profile.get("width", 0.16)), float(profile.get("arc_degrees", 150.0 if kind == "crescent" else 360.0)), int(profile.get("segments", 24)))
		"sigil":
			return sigil(size, profile)
		"glint":
			return glint(size, profile)
		"wave":
			return wave(size, profile)
		"vortex":
			return vortex(size, profile)
		"beam":
			return ribbon([Vector3.ZERO, Vector3.UP * size], float(profile.get("width", 0.09)), Color.WHITE)
	push_error("Unknown effect geometry %s" % kind)
	return null

static func authored_material(kind: String, profile: Dictionary, colour: Color) -> Material:
	var out := ShaderMaterial.new()
	if kind == "bubble":
		out.shader = BUBBLE_SHADER
		out.set_shader_parameter("water_colour", colour)
		out.set_shader_parameter("rim_colour", Color(str(profile.get("rim_colour", "#dcfaff"))))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.72)))
		out.set_shader_parameter("rim_power", float(profile.get("rim_power", 2.6)))
		out.set_shader_parameter("film_strength", float(profile.get("film_strength", 0.1)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 0.7)))
		out.set_shader_parameter("center_opacity", float(profile.get("center_opacity", 0.045)))
		out.set_shader_parameter("surface_roughness", float(profile.get("surface_roughness", 0.14)))
		return out
	if kind == "root_stone_surface":
		out.shader = ROOT_STONE_SHADER
		out.set_shader_parameter("surface_texture", STONE_TEXTURE)
		out.set_shader_parameter("stone_colour", Color(str(profile.get("stone_colour", "#706451"))))
		out.set_shader_parameter("mineral_colour", Color(str(profile.get("mineral_colour", "#b3a68a"))))
		out.set_shader_parameter("surface_scale", float(profile.get("surface_scale", 1.2)))
		out.set_shader_parameter("texture_blend", float(profile.get("texture_blend", 0.42)))
		out.set_shader_parameter("surface_roughness", float(profile.get("surface_roughness", 0.9)))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 1.0)))
		return out
	if kind == "shadow_surface":
		out.shader = SHADOW_SHADER
		out.set_shader_parameter("shadow_colour", Color(str(profile.get("shadow_colour", "#261f3b"))))
		out.set_shader_parameter("wisp_colour", Color(str(profile.get("wisp_colour", "#927ab8"))))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.82)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 1.6)))
		out.set_shader_parameter("surface_scale", float(profile.get("surface_scale", 3.4)))
		out.set_shader_parameter("porosity", float(profile.get("porosity", 0.35)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.07)))
		return out
	if kind == "wind_surface":
		out.shader = WIND_SHADER
		out.set_shader_parameter("air_colour", colour)
		out.set_shader_parameter("crest_colour", Color(str(profile.get("crest_colour", "#f2fff9"))))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.72)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 3.1)))
		out.set_shader_parameter("strand_frequency", float(profile.get("strand_frequency", 5.0)))
		out.set_shader_parameter("breakup", float(profile.get("breakup", 0.38)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.04)))
		return out
	if kind == "fire_explosion":
		out.shader = EXPLOSION_SHADER
		out.set_shader_parameter("hot_colour", Color(str(profile.get("hot_colour", "#fff0a8"))))
		out.set_shader_parameter("flame_colour", colour)
		out.set_shader_parameter("ember_colour", Color(str(profile.get("ember_colour", "#85250a"))))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.95)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 3.2)))
		out.set_shader_parameter("edge_breakup", float(profile.get("edge_breakup", 0.19)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.45)))
		out.set_shader_parameter("porosity", float(profile.get("porosity", 0.62)))
		out.set_shader_parameter("curl_scale", float(profile.get("curl_scale", 6.0)))
		out.set_shader_parameter("heat_warp", float(profile.get("heat_warp", 0.22)))
		out.set_shader_parameter("afterburn_strength", float(profile.get("afterburn_strength", 0.0)))
		out.set_shader_parameter("afterburn_start", float(profile.get("afterburn_start", 0.04)))
		out.set_shader_parameter("afterburn_end", float(profile.get("afterburn_end", 0.32)))
		out.set_shader_parameter("afterburn_colour", Color(str(profile.get("afterburn_colour", "#574c40"))))
		out.set_shader_parameter("emission_fade_power", float(profile.get("emission_fade_power", 2.2)))
		out.set_shader_parameter("afterburn_porosity", float(profile.get("afterburn_porosity", 0.55)))
		return out
	if kind == "flame_tongue" or (kind == "soft_trail" and str(profile.get("style", "")) == "painted_flame"):
		out.shader = TONGUE_SHADER
		out.set_shader_parameter("flame_texture", TONGUE_TEXTURE)
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.9)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 3.2)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.45)))
		out.set_shader_parameter("billboard", bool(profile.get("billboard", false)))
		out.set_shader_parameter("sprite_angle", deg_to_rad(float(profile.get("sprite_angle_deg", 0.0))))
		out.set_shader_parameter("flame_colour", colour)
		out.set_shader_parameter("hot_colour", Color(str(profile.get("hot_colour", "#fff0a8"))))
		out.set_shader_parameter("trail", kind == "soft_trail")
		out.set_shader_parameter("breakup_strength", float(profile.get("breakup_strength", 0.0)))
		return out
	if kind == "soft_dust" or (kind == "soft_trail" and str(profile.get("style", "")) == "dust"):
		out.shader = DUST_SHADER
		out.set_shader_parameter("dust_colour", Color(str(profile.dust_colour)) if profile.has("dust_colour") else colour)
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.58)))
		out.set_shader_parameter("billboard", kind == "soft_dust")
		out.set_shader_parameter("trail", kind == "soft_trail")
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 2.1)))
		return out
	if kind in ["water_stream", "rolling_wave"]:
		out.shader = FLOW_SHADER
		out.set_shader_parameter("water_colour", colour)
		out.set_shader_parameter("foam_colour", Color(str(profile.get("foam_colour", "#d1edf2"))))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.76)))
		out.set_shader_parameter("wave", kind == "rolling_wave")
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 3.0)))
		return out
	if kind == "ice_crystal":
		out.shader = ICE_SHADER
		out.set_shader_parameter("ice_colour", colour)
		out.set_shader_parameter("frost_colour", Color(str(profile.get("frost_colour", "#d6f0f5"))))
		out.set_shader_parameter("edge_width", float(profile.get("edge_width", 0.055)))
		out.set_shader_parameter("frost_strength", float(profile.get("frost_strength", 0.36)))
		out.set_shader_parameter("facet_variation", float(profile.get("facet_variation", 0.16)))
		out.set_shader_parameter("surface_roughness", float(profile.get("surface_roughness", 0.22)))
		out.set_shader_parameter("specular_strength", float(profile.get("specular_strength", 0.55)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.015)))
		return out
	if kind in ["ion_filament", "electrical_splash"]:
		out.shader = ION_SHADER
		out.set_shader_parameter("ion_colour", colour)
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.95)))
		out.set_shader_parameter("pulse_strength", float(profile.get("pulse_strength", 0.08)))
		out.set_shader_parameter("core_width", float(profile.get("core_width", 0.12)))
		out.set_shader_parameter("corona_width", float(profile.get("corona_width", 0.72)))
		out.set_shader_parameter("corona_opacity", float(profile.get("corona_opacity", 0.5)))
		out.set_shader_parameter("emission_floor", float(profile.get("emission_floor", 0.2)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.4)))
		out.set_shader_parameter("filament_sway", float(profile.get("filament_sway", 0.06)))
		out.set_shader_parameter("corona_sway", float(profile.get("corona_sway", 0.12)))
		out.set_shader_parameter("corona_power", float(profile.get("corona_power", 1.55)))
		out.set_shader_parameter("vein_strength", float(profile.get("vein_strength", 1.0)))
		return out
	if kind == "burning_core":
		out.shader = FIRE_CORE_SHADER
		out.set_shader_parameter("hot_colour", Color(str(profile.get("hot_colour", "#fff2b2"))))
		out.set_shader_parameter("flame_colour", colour)
		out.set_shader_parameter("opacity", float(profile.get("opacity", 0.86)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 3.8)))
		out.set_shader_parameter("surface_scale", float(profile.get("surface_scale", 4.8)))
		out.set_shader_parameter("deformation", float(profile.get("deformation", 0.22)))
		out.set_shader_parameter("edge_softness", float(profile.get("edge_softness", 0.42)))
		out.set_shader_parameter("emission_strength", float(profile.get("emission_strength", 0.9)))
		return out
	if kind in ["flame_orb", "fire_bloom", "soft_dust", "soft_ember", "soft_trail", "soft_foam", "flame_volume", "mist_cone"]:
		out.shader = FIRE_SHADER
		out.set_shader_parameter("hot_colour", Color(str(profile.get("hot_colour", "#fff3a6"))))
		out.set_shader_parameter("flame_colour", colour)
		out.set_shader_parameter("ember_colour", Color(str(profile.get("ember_colour", "#7b4106"))))
		out.set_shader_parameter("opacity", float(profile.get("opacity", 1.0)))
		out.set_shader_parameter("billboard", kind not in ["soft_trail", "flame_volume", "mist_cone"])
		out.set_shader_parameter("dust", kind in ["soft_dust", "soft_foam", "mist_cone"] or bool(profile.get("dust", false)))
		out.set_shader_parameter("effect_mode", 1 if kind in ["soft_trail", "flame_volume", "mist_cone"] else (2 if kind in ["fire_bloom", "soft_dust", "soft_foam"] else (3 if kind == "soft_ember" else 0)))
		out.set_shader_parameter("flow_speed", float(profile.get("flow_speed", 2.4)))
		out.set_shader_parameter("brightness", float(profile.get("brightness", 1.0)))
		return out
	if kind == "stone":
		out.shader = STONE_SHADER
		out.set_shader_parameter("stone_colour", Color(str(profile.get("stone_colour", "#71614b"))))
		out.set_shader_parameter("mineral_colour", Color(str(profile.get("mineral_colour", "#bca67d"))))
		out.set_shader_parameter("surface_texture", STONE_TEXTURE)
		out.set_shader_parameter("authored_surface", bool(profile.get("authored_surface", false)))
		out.set_shader_parameter("surface_scale", float(profile.get("surface_scale", 1.35)))
		out.set_shader_parameter("texture_blend", float(profile.get("texture_blend", 0.52)))
		out.set_shader_parameter("surface_roughness", float(profile.get("surface_roughness", 0.88)))
		return out
	return material(colour, float(profile.get("opacity", 1.0)), bool(profile.get("lit", false)))

## One continuous camera-facing strip with a smooth centerline and global UVs.
static func flowing_ribbon(points: Array[Vector3], width: float, camera_position: Vector3) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	if points.size() < 2 or width <= 0.0: return mesh
	var smooth: Array[Vector3] = []
	for i in points.size() - 1:
		var a := points[maxi(0, i - 1)]
		var b := points[i]
		var c := points[i + 1]
		var d := points[mini(points.size() - 1, i + 2)]
		for step in 4:
			var t := float(step) / 4.0
			smooth.append(0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t))
	smooth.append(points.back())
	var edges: Array[Vector3] = []
	for i in smooth.size():
		var tangent := (smooth[mini(i + 1, smooth.size() - 1)] - smooth[maxi(0, i - 1)]).normalized()
		var across := tangent.cross((camera_position - smooth[i]).normalized()).normalized()
		if across.length_squared() < 0.001: across = Vector3.UP
		edges.append(across * width)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in smooth.size() - 1:
		var v0 := float(i) / float(smooth.size() - 1)
		var v1 := float(i + 1) / float(smooth.size() - 1)
		_uv_quad(mesh, smooth[i] - edges[i], smooth[i] + edges[i], smooth[i + 1] + edges[i + 1], smooth[i + 1] - edges[i + 1], v0, v1)
	mesh.surface_end()
	return mesh

static func _uv_quad(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3, v0: float, v1: float) -> void:
	var points: Array[Vector3] = [a, b, c, a, c, d]
	var uvs: Array[Vector2] = [Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v0), Vector2(1, v1), Vector2(0, v1)]
	for i in 6:
		mesh.surface_set_uv(uvs[i])
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(points[i])

## Irregular geological chunks with face normals, not smoothly shaded balls.
static func stone(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	var segments := int(profile.get("segments", 12))
	var rings := int(profile.get("rings", 7))
	# 0 keeps one flat normal per facet; higher values blend each vertex
	# normal toward the radial direction so shading and the triplanar
	# surface flow across facets instead of banding facet by facet.
	var smoothing := clampf(float(profile.get("stone_smoothing", 0.0)), 0.0, 1.0)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in rings:
		for x in segments:
			var a := _stone_point(x, y, segments, rings, size)
			var b := _stone_point(x + 1, y, segments, rings, size)
			var c := _stone_point(x + 1, y + 1, segments, rings, size)
			var d := _stone_point(x, y + 1, segments, rings, size)
			if smoothing > 0.0:
				_stone_triangle(mesh, a, b, c, smoothing)
				_stone_triangle(mesh, a, c, d, smoothing)
			else:
				_triangle(mesh, a, b, c)
				_triangle(mesh, a, c, d)
	mesh.surface_end()
	return mesh

static func _stone_triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, smoothing: float) -> void:
	var face := (b - a).cross(c - a)
	if face.length_squared() < 0.000001: return
	if face.dot(a + b + c) < 0.0:
		var swap := b; b = c; c = swap
		face = -face
	face = face.normalized()
	for point: Vector3 in [a, b, c]:
		mesh.surface_set_normal(face.lerp(point.normalized(), smoothing).normalized())
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(point)

static func _stone_point(x: int, y: int, segments: int, rings: int, size: float) -> Vector3:
	var latitude := PI * float(y) / float(rings)
	var longitude := TAU * float(x % segments) / float(segments)
	var p := Vector3(sin(latitude) * cos(longitude), cos(latitude), sin(latitude) * sin(longitude))
	var ridge := 1.0 + 0.12 * sin(p.x * 8.0 + p.z * 4.3) + 0.085 * sin(p.y * 9.0 - p.z * 7.0)
	return p * size * ridge

static func _triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.000001: return
	if normal.dot(a + b + c) < 0.0:
		var swap := b; b = c; c = swap
		normal = -normal
	mesh.surface_set_normal(normal.normalized())
	for point: Vector3 in [a, b, c]:
		mesh.surface_set_color(Color.WHITE)
		mesh.surface_add_vertex(point)

static func impact_rays(size: float, profile: Dictionary, lightning: bool) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := int(profile.get("rays", 9))
	for i in count:
		var angle := TAU * float(i) / float(count)
		var ray := Vector3(cos(angle), 0.0, sin(angle))
		var reach := size * (1.25 + 0.3 * sin(float(i) * 3.7))
		var end := ray * reach + Vector3.UP * size * (0.06 if lightning else 0.65)
		var side := ray.cross(Vector3.UP) * size * float(profile.get("ray_width_ratio", 0.08))
		quad(mesh, side, -side, end - side * 0.15, end + side * 0.15, Color.WHITE, Color(0.5, 0.55, 0.65))
	mesh.surface_end()
	return mesh

## A closed, tapered flame volume stays readable from oblique player cameras.
static func plume(points: Array[Vector3], width: float, colour: Color, phase: float) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	if points.size() < 2 or width <= 0.0: return mesh
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var tangent := (points[i + 1] - points[i]).normalized()
		if tangent.length_squared() < 0.001: continue
		var side := tangent.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.001: side = Vector3.RIGHT
		var up := tangent.cross(side).normalized()
		var f0 := float(i) / float(points.size() - 1)
		var f1 := float(i + 1) / float(points.size() - 1)
		var tail := Color("#9f2608").lerp(colour, f0)
		var head := colour.lerp(Color("#fff1a3"), f1 * 0.75)
		for radial in 8:
			var a := TAU * float(radial) / 8.0
			var b := TAU * float(radial + 1) / 8.0
			var r0 := width * pow(f0, 0.6) * (0.8 + 0.18 * sin(a * 3.0 + phase + f0 * 12.0))
			var r1 := width * pow(f1, 0.6) * (0.8 + 0.18 * sin(b * 3.0 + phase + f1 * 12.0))
			quad(mesh, points[i] + (side * cos(a) + up * sin(a)) * r0,
				points[i] + (side * cos(b) + up * sin(b)) * r0,
				points[i + 1] + (side * cos(b) + up * sin(b)) * r1,
				points[i + 1] + (side * cos(a) + up * sin(a)) * r1, tail, head)
	mesh.surface_end()
	return mesh

static func bolt(points: Array[Vector3], width: float, colour: Color, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	if points.size() < 2: return mesh
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		_bolt_segment(mesh, points[i], points[i + 1], width, colour)
	var branches := clampi(int(profile.get("branch_count", 4)), 0, 12) if points.size() > 2 else 0
	for i in branches:
		var point := points[clampi(1 + floori(float(i + 1) * float(points.size() - 2) / float(branches + 1)), 1, points.size() - 2)]
		var reach := float(profile.get("branch_length_m", 0.8)) * (0.7 + 0.3 * absf(sin(float(i) * 2.71)))
		var angle := float(i) * 2.399963
		var direction := Vector3(cos(angle), -float(profile.get("branch_down_ratio", 0.5)), sin(angle)).normalized()
		var elbow := point + direction * reach * 0.45 + Vector3.UP * reach * 0.18
		var fork := point + direction * reach
		_bolt_segment(mesh, point, elbow, width * 0.52, colour)
		_bolt_segment(mesh, elbow, fork, width * 0.25, colour)
		if i % 2 == 0:
			var twig := elbow + Vector3(-direction.z, -0.65, direction.x).normalized() * reach * 0.4
			_bolt_segment(mesh, elbow, twig, width * 0.15, colour)
	mesh.surface_end()
	return mesh

static func _bolt_segment(mesh: ImmediateMesh, from: Vector3, to: Vector3, width: float, _colour: Color) -> void:
	var tangent := (to - from).normalized()
	if tangent.length_squared() < 0.001: return
	var side := tangent.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.001: side = Vector3.RIGHT
	var other := tangent.cross(side).normalized()
	for axis: Vector3 in [side, other]:
		# Continuous soft corona and white core come from UV across the actual
		# depth-tested filament, not a hard opaque golden rectangular strip.
		_uv_quad(mesh, from - axis * width, from + axis * width, to + axis * width * 0.58, to - axis * width * 0.58, 0.0, 1.0)

static func sigil(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := clampi(int(profile.get("glyph_sides", 6)), 3, 12)
	var width := float(profile.get("width", 0.08))
	for i in sides:
		var a := TAU * float(i) / float(sides)
		var b := TAU * float(i + 1) / float(sides)
		var start := Vector3(cos(a), 0.0, sin(a)) * size
		var finish := Vector3(cos(b), 0.0, sin(b)) * size
		var across := (finish - start).normalized().cross(Vector3.UP) * width
		quad(mesh, start - across, start + across, finish + across, finish - across, Color.WHITE, Color.WHITE)
		# Inward broken strokes distinguish the glyph from a plain circle.
		if i % 2 == 0:
			var inward := start * 0.55
			quad(mesh, start - across, start + across, inward + across, inward - across, Color.WHITE, Color.WHITE)
	mesh.surface_end()
	return mesh

static func glint(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var width := size * float(profile.get("ray_width_ratio", 0.12))
	for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
		var side := axis.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.001: side = Vector3.RIGHT
		quad(mesh, -axis * size, side * width, axis * size, -side * width, Color.WHITE, Color.WHITE)
		var other := axis.cross(side).normalized()
		quad(mesh, -axis * size, other * width, axis * size, -other * width, Color.WHITE, Color.WHITE)
	mesh.surface_end()
	return mesh

static func band(radius: float, width: float, arc_degrees: float, segments: int) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var arc := deg_to_rad(arc_degrees)
	for i in segments:
		var a := arc * float(i) / float(segments)
		var b := arc * float(i + 1) / float(segments)
		quad(mesh, Vector3(cos(a), 0.0, sin(a)) * radius,
			Vector3(cos(b), 0.0, sin(b)) * radius,
			Vector3(cos(b), 0.0, sin(b)) * (radius + width),
			Vector3(cos(a), 0.0, sin(a)) * (radius + width), Color.WHITE, Color.WHITE)
	mesh.surface_end()
	return mesh

static func wave(size: float, profile: Dictionary) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := int(profile.get("segments", 16))
	var width := size * float(profile.get("width_ratio", 3.2))
	for i in segments:
		var x0 := lerpf(-width, width, float(i) / float(segments))
		var x1 := lerpf(-width, width, float(i + 1) / float(segments))
		var y0 := size * (0.75 + 0.35 * cos(x0 / maxf(width, 0.01) * PI))
		var y1 := size * (0.75 + 0.35 * cos(x1 / maxf(width, 0.01) * PI))
		quad(mesh, Vector3(x0, 0.0, size * 0.3), Vector3(x1, 0.0, size * 0.3),
			Vector3(x1, y1, -size * 0.25), Vector3(x0, y0, -size * 0.25), Color(0.3, 0.7, 0.95), Color(0.9, 0.98, 1.0))
		quad(mesh, Vector3(x0, y0, -size * 0.25), Vector3(x1, y1, -size * 0.25),
			Vector3(x1, y1 * 0.9, -size * 0.5), Vector3(x0, y0 * 0.9, -size * 0.5), Color.WHITE, Color(0.6, 0.85, 1.0))
	mesh.surface_end()
	return mesh

static func vortex(size: float, profile: Dictionary) -> ImmediateMesh:
	var points: Array[Vector3] = []
	var segments := int(profile.get("segments", 36))
	var turns := float(profile.get("turns", 3.0))
	for i in segments + 1:
		var t := float(i) / float(segments)
		var angle := t * turns * TAU
		var radius := size * lerpf(0.2, 1.0, t)
		points.append(Vector3(cos(angle) * radius, t * size * 3.0, sin(angle) * radius))
	return ribbon(points, size * float(profile.get("ribbon_ratio", 0.13)), Color.WHITE)

static func ribbon(points: Array[Vector3], width: float, colour: Color) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	if points.size() < 2 or width <= 0.0: return mesh
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var tangent := (points[i + 1] - points[i]).normalized()
		var side := tangent.cross(Vector3.UP).normalized()
		if side.length_squared() < 0.001: side = Vector3.RIGHT
		var other := tangent.cross(side).normalized()
		var thickness := width * lerpf(0.25, 1.0, float(i + 1) / float(points.size() - 1))
		var tail := colour.lerp(Color(0.08, 0.1, 0.15), 0.45)
		for axis: Vector3 in [side, other]:
			quad(mesh, points[i] - axis * thickness, points[i] + axis * thickness,
				points[i + 1] + axis * thickness, points[i + 1] - axis * thickness, tail, colour)
	mesh.surface_end()
	return mesh

static func quad(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		near_colour: Color, far_colour: Color) -> void:
	# RGB gradient only; opacity belongs to material alpha on Compatibility.
	for pair: Array in [[a, near_colour], [b, near_colour], [c, far_colour], [a, near_colour], [c, far_colour], [d, far_colour]]:
		var colour: Color = pair[1]
		mesh.surface_set_color(Color(colour.r, colour.g, colour.b, 1.0))
		mesh.surface_add_vertex(pair[0])
