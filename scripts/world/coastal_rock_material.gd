extends RefCounted
## Presentation-only cliff layer over the actual Terrain3D shader. Retains its
## height/control sampling and the separately installed Veilfall treatment.
const MARKER := "// COASTAL-ROCK"
const UNIFORM_ANCHOR := "void fragment() {"
const MATERIAL_ANCHOR := "mat.ao_strength *= weight_inv;"
const UNIFORMS := """
// COASTAL-ROCK: coherent projection over exposed rock and steep faces.
uniform sampler2D coast_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D coast_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float coast_strength = 0.0;
uniform float coast_scale = 0.18;
uniform float coast_normal_depth = 0.38;
uniform vec3 coast_tint : source_color = vec3(0.62, 0.65, 0.64);
uniform float coast_start_y = 0.68;
uniform float coast_full_y = 0.32;
uniform int coast_rock_texture_id = 2;
uniform vec2 coast_exclude_centre = vec2(200.0, 4140.0);
uniform float coast_exclude_radius = 430.0;
"""
const MATERIAL := """
	// COASTAL-ROCK. Evaluate derivatives outside the slope branch.
	vec3 coast_dx = dFdx(v_vertex);
	vec3 coast_dy = dFdy(v_vertex);
	vec3 coast_face = normalize(cross(coast_dy, coast_dx));
	vec4 coast_base = vec4(equal(ivec4(control >> uvec4(27u) & uvec4(31u)), ivec4(coast_rock_texture_id)));
	vec4 coast_over = vec4(equal(ivec4(control >> uvec4(22u) & uvec4(31u)), ivec4(coast_rock_texture_id)));
	vec4 coast_blend = vec4(control >> uvec4(14u) & uvec4(255u)) / 255.0;
	vec4 coast_paint = coast_base * (1.0 - coast_blend) + coast_over * coast_blend;
	float coast_painted = bilerp ? dot(coast_paint, weights) : coast_paint[3];
	float coast_weight = coast_strength * max(coast_painted, 1.0 - smoothstep(coast_full_y, coast_start_y, abs(coast_face.y)));
	coast_weight *= smoothstep(0.2, 1.6, v_vertex.y);
	coast_weight *= smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0, length(v_vertex.xz - coast_exclude_centre));
	if (coast_weight > 0.001) {
		vec2 side = vec2(coast_face.x < 0.0 ? -1.0 : 1.0, coast_face.z < 0.0 ? -1.0 : 1.0);
		vec3 coast_weights = abs(coast_face);
		coast_weights /= max(coast_weights.x + coast_weights.y + coast_weights.z, 0.001);
		vec2 uv_x = vec2(-side.x * v_vertex.z, -v_vertex.y) * coast_scale;
		vec2 uv_z = vec2(side.y * v_vertex.x, -v_vertex.y) * coast_scale;
		vec2 uv_y = v_vertex.xz * coast_scale;
		vec2 dx_x = vec2(-side.x * coast_dx.z, -coast_dx.y) * coast_scale;
		vec2 dy_x = vec2(-side.x * coast_dy.z, -coast_dy.y) * coast_scale;
		vec2 dx_z = vec2(side.y * coast_dx.x, -coast_dx.y) * coast_scale;
		vec2 dy_z = vec2(side.y * coast_dy.x, -coast_dy.y) * coast_scale;
		vec2 dx_y = coast_dx.xz * coast_scale;
		vec2 dy_y = coast_dy.xz * coast_scale;
		vec3 rock = textureGrad(coast_albedo, uv_x, dx_x, dy_x).rgb * coast_weights.x
			+ textureGrad(coast_albedo, uv_y, dx_y, dy_y).rgb * coast_weights.y
			+ textureGrad(coast_albedo, uv_z, dx_z, dy_z).rgb * coast_weights.z;
		vec3 nx = textureGrad(coast_normal, uv_x, dx_x, dy_x).xyz * 2.0 - 1.0;
		vec3 nz = textureGrad(coast_normal, uv_z, dx_z, dy_z).xyz * 2.0 - 1.0;
		vec3 ny = textureGrad(coast_normal, uv_y, dx_y, dy_y).xyz * 2.0 - 1.0;
		// Keep broad rock planes quiet; the normal supplies small relief.
		float value = dot(rock, vec3(0.299, 0.587, 0.114));
		rock = mix(vec3(value), rock, 0.4);
		float warp = sin(v_vertex.x * 0.021 + v_vertex.z * 0.013) * 1.9;
		float bed = fract((v_vertex.y + warp) / 12.0);
		float ledge = smoothstep(0.02, 0.15, bed) * (1.0 - smoothstep(0.55, 0.98, bed));
		rock *= coast_tint * mix(0.90, 1.10, ledge);
		vec3 detail = vec3(0.0, nx.y, -side.x * nx.x) * coast_weights.x
			+ vec3(ny.x, 0.0, -ny.y) * coast_weights.y
			+ vec3(side.y * nz.x, nz.y, 0.0) * coast_weights.z;
		vec3 surface_normal = normalize(mat3(INV_VIEW_MATRIX) * NORMAL);
		detail -= surface_normal * dot(surface_normal, detail);
		float detail_z = dot(vec3(nx.z, ny.z, nz.z), coast_weights);
		vec3 detail_view = mat3(VIEW_MATRIX) * normalize(surface_normal * max(detail_z, 0.01) + detail);
		vec3 mapped = vec3(dot(detail_view, normalize(TANGENT)), dot(detail_view, normalize(NORMAL)), dot(detail_view, normalize(BINORMAL)));
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, rock, coast_weight);
		mat.normal_rough = mix(mat.normal_rough, vec4(mapped, 0.88), coast_weight);
		mat.normal_map_depth = mix(mat.normal_map_depth, coast_normal_depth, coast_weight);
	}
"""

static func install(terrain: Object, config: Dictionary, excluded: Dictionary) -> Dictionary:
	var receipt := {"installed": false, "reason": "disabled"}
	if terrain == null or not bool(config.get("enabled", false)):
		return receipt
	var material: Object = terrain.get("material")
	var current: Shader = material.call("get_shader_override")
	if not bool(material.call("is_shader_override_enabled")) or current == null:
		material.call("enable_shader_override", true)
		current = material.call("get_shader_override")
	var code := current.code if current != null else ""
	if not code.contains(MARKER):
		if not code.contains(UNIFORM_ANCHOR) or not code.contains(MATERIAL_ANCHOR):
			receipt.reason = "Terrain3D material anchors unavailable"
			push_warning(str(receipt.reason))
			return receipt
		var shader := Shader.new()
		shader.code = code.replace(UNIFORM_ANCHOR, UNIFORMS + UNIFORM_ANCHOR).replace(MATERIAL_ANCHOR, MATERIAL_ANCHOR + "\n" + MATERIAL)
		material.call("enable_shader_override", false)
		material.call("set_shader_override", shader)
		material.call("enable_shader_override", true)
	material.call("set_shader_param", "coast_albedo", load("res://assets/environment/terrain/Rock030_Color.jpg"))
	material.call("set_shader_param", "coast_normal", load("res://assets/environment/terrain/Rock030_NormalGL.jpg"))
	for key: String in ["strength", "scale", "normal_depth", "start_y", "full_y"]:
		if config.has(key):
			material.call("set_shader_param", "coast_" + key, float(config[key]))
	if config.has("tint"):
		material.call("set_shader_param", "coast_tint", Color(str(config.tint)))
	var centre: Array = excluded.get("centre_xz", [200.0, 4140.0])
	material.call("set_shader_param", "coast_exclude_centre", Vector2(float(centre[0]), float(centre[1])))
	material.call("set_shader_param", "coast_exclude_radius", float(excluded.get("radius_m", 430.0)))
	var installed: Shader = material.call("get_shader_override")
	receipt.installed = installed != null and installed.code.contains(MARKER)
	receipt.reason = "installed" if receipt.installed else "override was regenerated"
	return receipt
