extends RefCounted
## Presentation-only cliff layer over the actual Terrain3D shader. Retains its
## height/control sampling and the separately installed Veilfall treatment.
const MARKER := "// COASTAL-ROCK"
const UNIFORM_ANCHOR := "void fragment() {"
const MATERIAL_ANCHOR := "mat.ao_strength *= weight_inv;"
const SHORE_CONFIG := "res://data/config/water_shore_presentation.json"
const DUNE_CONFIG := "res://data/config/water_dune_terrain.json"
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
uniform bool coast_weathering_enabled = false;
uniform float coast_weathering_scale = 0.11;
uniform vec3 coast_moss_colour : source_color = vec3(0.32, 0.42, 0.24);
uniform float coast_moss_amount = 0.65;
uniform vec3 coast_sediment_colour : source_color = vec3(0.71, 0.61, 0.45);
uniform float coast_sediment_height_m = 4.8;
uniform vec3 coast_wet_colour : source_color = vec3(0.22, 0.29, 0.27);
uniform float coast_wet_height_m = 1.6;
uniform float coast_rock_detail = 0.45;
uniform bool coast_dunes_enabled = false;
uniform vec3 coast_dune_sand_colour : source_color = vec3(0.78, 0.71, 0.59);
uniform vec3 coast_dune_wet_colour : source_color = vec3(0.51, 0.47, 0.40);
uniform vec3 coast_dune_bluff_colour : source_color = vec3(0.62, 0.60, 0.54);
uniform float coast_dune_patch_scale = 0.022;
uniform float coast_dune_ripple_scale = 16.0;
uniform float coast_dune_ripple_strength = 0.025;

float coast_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float coast_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(coast_hash(i), coast_hash(i + vec2(1.0, 0.0)), f.x),
		mix(coast_hash(i + vec2(0.0, 1.0)), coast_hash(i + vec2(1.0)), f.x), f.y);
}
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
		if (coast_weathering_enabled) {
			// Broad mineral planes, with irregular vegetation tongues at the
			// slope transition; the real surface and its silhouette stay intact.
			float patch = coast_noise(v_vertex.xz * coast_weathering_scale);
			float grain = coast_noise(v_vertex.xz * coast_weathering_scale * 3.7);
			rock = mix(coast_tint * 0.42, rock, coast_rock_detail);
			rock *= mix(0.78, 1.15, patch);
			float moss = smoothstep(0.48, 0.91, abs(coast_face.y) + (patch - 0.5) * 0.32);
			moss *= smoothstep(1.8, 5.0, v_vertex.y) * coast_moss_amount;
			rock = mix(rock, coast_moss_colour * mix(0.65, 1.05, grain), moss);
		}
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
	if (coast_weathering_enabled) {
		// Sand and wet mineral stains soften the waterline without painting
		// new walkable terrain or touching Veilfall's separate treatment.
		float patch = coast_noise(v_vertex.xz * coast_weathering_scale);
		float grain = coast_noise(v_vertex.xz * coast_weathering_scale * 3.7);
		float outside = smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0, length(v_vertex.xz - coast_exclude_centre));
		float strand = 1.0 - smoothstep(coast_sediment_height_m * 0.35, coast_sediment_height_m, v_vertex.y + (patch - 0.5) * 2.8);
		strand *= smoothstep(0.25, 0.85, abs(coast_face.y)) * outside;
		vec3 sediment = coast_sediment_colour * mix(0.70, 0.96, grain);
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, sediment, strand * 0.8);
		float wet = (1.0 - smoothstep(0.05, coast_wet_height_m, v_vertex.y + (patch - 0.5) * 0.6)) * outside;
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, coast_wet_colour * mix(0.65, 1.0, grain), wet * 0.65);
		mat.normal_rough.a = mix(mat.normal_rough.a, 0.55, wet);
	}
	if (coast_dunes_enabled) {
		// Owner-directed Great Lakes dune palette. This is surface colour and
		// roughness only: the baked heights, controls and collision stay intact.
		float outside = smoothstep(coast_exclude_radius, coast_exclude_radius + 30.0, length(v_vertex.xz - coast_exclude_centre));
		float patch = coast_noise(v_vertex.xz * coast_dune_patch_scale);
		// Use Terrain3D's interpolated height normal, not raster triangle
		// derivatives: slope tint must not outline every terrain triangle.
		vec3 dune_normal = normalize(w_normal);
		vec3 dune_weights = abs(dune_normal);
		dune_weights /= max(dot(dune_weights, vec3(1.0)), 0.001);
		float grain = coast_noise(v_vertex.zy * 3.4) * dune_weights.x
			+ coast_noise(v_vertex.xz * 3.4) * dune_weights.y
			+ coast_noise(v_vertex.xy * 3.4) * dune_weights.z;
		float phase = dot(v_vertex.xz, vec2(0.63, 0.77)) * coast_dune_ripple_scale + patch * 5.0;
		// Close, gentle ground only. Projecting periodic ripples down cliffs
		// produced long regular stripes instead of windblown sand.
		float ripple = sin(phase) * (1.0 - smoothstep(0.3, 0.9, fwidth(phase)))
			* smoothstep(0.8, 0.98, abs(dune_normal.y));
		vec3 sand = coast_dune_sand_colour * (mix(0.70, 0.88, patch) + (grain - 0.5) * 0.065 + ripple * coast_dune_ripple_strength);
		float bluff = 1.0 - smoothstep(0.15, 0.72, abs(dune_normal.y));
		sand = mix(sand, coast_dune_bluff_colour * mix(0.71, 0.87, patch), bluff * 0.24);
		float wet = 1.0 - smoothstep(0.15, 1.25, v_vertex.y + (patch - 0.5) * 0.4);
		sand = mix(sand, coast_dune_wet_colour * mix(0.92, 1.02, grain), wet * 0.8);
		mat.albedo_height.rgb = mix(mat.albedo_height.rgb, sand, outside);
		mat.normal_rough.rgb = mix(mat.normal_rough.rgb, vec3(0.0, 1.0, 0.0), outside);
		mat.normal_rough.a = mix(mat.normal_rough.a, mix(0.94, 0.73, wet), outside);
		mat.normal_map_depth = mix(mat.normal_map_depth, 0.0, outside);
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
	var shore: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHORE_CONFIG))
	if shore is Dictionary:
		material.call("set_shader_param", "coast_weathering_enabled", bool(shore.get("enabled", false)))
		for key: String in shore:
			if key.begins_with("_") or key == "enabled":
				continue
			var value: Variant = shore[key]
			material.call("set_shader_param", "coast_" + key, Color(str(value)) if key.ends_with("colour") else float(value))
	var dune: Variant = JSON.parse_string(FileAccess.get_file_as_string(DUNE_CONFIG))
	if dune is Dictionary:
		material.call("set_shader_param", "coast_dunes_enabled", bool(dune.get("enabled", false)))
		for key: String in ["sand_colour", "wet_colour", "bluff_colour", "patch_scale", "ripple_scale", "ripple_strength"]:
			if dune.has(key):
				var value: Variant = dune[key]
				material.call("set_shader_param", "coast_dune_" + key, Color(str(value)) if key.ends_with("colour") else float(value))
	var installed: Shader = material.call("get_shader_override")
	receipt.installed = installed != null and installed.code.contains(MARKER)
	receipt.reason = "installed" if receipt.installed else "override was regenerated"
	return receipt
