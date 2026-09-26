extends RefCounted

## Veilfall-only terrain material pass (F13#5). The mountain is the shared
## Water Terrain3D heightfield, so its rock cannot get its own material slot
## without a rebake. Instead this appends one masked block to the terrain's own
## generated shader: inside the Veilfall island radius, steep faces become dark
## wet rock with vertical runnels, and the whole island is toned toward an
## aerial blue with camera distance so its silhouette separates from the sky.
## Every other island keeps the stock Terrain3D result (the mask is zero there)
## and no geometry or draw call is added. Tunables: water_veilfall.json::rock_material.
##
## The generated code is read back at runtime rather than committed as a copy
## so it always matches this Terrain3D build and the Water material settings.
## If either anchor is missing, the pass is skipped with a warning and the
## terrain keeps its stock shader.
const MARKER := "// VEILFALL-MATERIAL"
const UNIFORM_ANCHOR := "void fragment() {"
const TAIL_ANCHOR := "SPECULAR = 1. - mat.normal_rough.a;"

const UNIFORMS := """
// VEILFALL-MATERIAL: scripts/world/water_veilfall_rock.gd (masked to Veilfall).
uniform vec2 vf_centre_xz = vec2(200.0, 4140.0);
uniform float vf_radius_m = 430.0;
uniform float vf_feather_m = 40.0;
uniform float vf_min_height_m = 6.0;
uniform float vf_slope_lo = 0.55;
uniform float vf_slope_hi = 0.88;
uniform vec3 vf_rock_colour : source_color = vec3(0.24, 0.27, 0.28);
uniform vec3 vf_streak_colour : source_color = vec3(0.13, 0.15, 0.16);
uniform float vf_detail = 0.6;
uniform float vf_streak_width_m = 3.5;
uniform float vf_streak_length_m = 38.0;
uniform float vf_strata_m = 9.0;
uniform float vf_strata_lift = 0.35;
uniform float vf_wet_roughness = 0.3;
uniform float vf_dry_roughness = 0.62;
uniform float vf_wet_specular = 0.55;
uniform vec3 vf_tone_colour : source_color = vec3(0.40, 0.50, 0.58);
uniform float vf_tone_start_m = 700.0;
uniform float vf_tone_end_m = 3800.0;
uniform float vf_tone_strength = 0.6;

float vf_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vf_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(vf_hash(cell), vf_hash(cell + vec2(1.0, 0.0)), f.x),
		mix(vf_hash(cell + vec2(0.0, 1.0)), vf_hash(cell + vec2(1.0)), f.x), f.y);
}

"""

const TAIL := """
	// VEILFALL-MATERIAL tail: dark wet rock and distance tone, Veilfall only.
	{
		float vf_r = length(v_vertex.xz - vf_centre_xz);
		float vf_in = 1.0 - smoothstep(vf_radius_m - vf_feather_m, vf_radius_m, vf_r);
		if (vf_in > 0.0) {
			float vf_rock = vf_in * smoothstep(vf_min_height_m, vf_min_height_m + 8.0, v_vertex.y)
				* (1.0 - smoothstep(vf_slope_lo, vf_slope_hi, w_normal.y));
			// Runnels follow the fall line: a planar pair of stretched noises
			// blended by facing, so there is no angular seam around the peak.
			vec2 vf_dir = abs(normalize(v_vertex.xz - vf_centre_xz + vec2(0.001)));
			float vf_wx = vf_dir.y / (vf_dir.x + vf_dir.y);
			vec2 vf_a = vec2(v_vertex.x / vf_streak_width_m, v_vertex.y / vf_streak_length_m);
			vec2 vf_b = vec2(v_vertex.z / vf_streak_width_m, v_vertex.y / vf_streak_length_m + 17.0);
			float vf_n = mix(vf_noise(vf_b), vf_noise(vf_a), vf_wx) * 0.65
				+ mix(vf_noise(vf_b * 2.3 + 5.1), vf_noise(vf_a * 2.3 + 3.7), vf_wx) * 0.35;
			float vf_streak = smoothstep(0.35, 0.72, vf_n);
			// Thin pale bedding ledges, warped so they never read as ruled lines.
			float vf_bed = fract(v_vertex.y / vf_strata_m + mix(vf_noise(vf_b * 0.35), vf_noise(vf_a * 0.35), vf_wx) * 0.8);
			float vf_ledge = smoothstep(0.86, 0.97, vf_bed) * (1.0 - vf_streak);
			float vf_luma = dot(ALBEDO, vec3(0.299, 0.587, 0.114));
			vec3 vf_wet = mix(vf_rock_colour, vf_streak_colour, vf_streak)
				* clamp(1.0 + (vf_luma - 0.5) * 2.0 * vf_detail, 0.45, 1.6) * (1.0 + vf_ledge * vf_strata_lift);
			ALBEDO = mix(ALBEDO, vf_wet, vf_rock);
			ROUGHNESS = mix(ROUGHNESS, mix(vf_dry_roughness, vf_wet_roughness, vf_streak), vf_rock);
			SPECULAR = mix(SPECULAR, vf_wet_specular, vf_rock);
			float vf_far = vf_in * vf_tone_strength
				* smoothstep(vf_tone_start_m, vf_tone_end_m, length(v_vertex - _camera_pos));
			ALBEDO = mix(ALBEDO, vf_tone_colour, vf_far);
			ROUGHNESS = mix(ROUGHNESS, 1.0, vf_far);
			SPECULAR = mix(SPECULAR, 0.2, vf_far);
		}
	}
"""


## Returns a receipt; "installed" is false when the pass was skipped.
static func install(terrain: Object, config: Dictionary) -> Dictionary:
	var receipt := {"installed": false, "reason": ""}
	if terrain == null or config.is_empty() or not bool(config.get("enabled", true)):
		receipt.reason = "disabled"
		return receipt
	var material: Object = terrain.get("material")
	if material == null or not material.has_method("enable_shader_override") \
			or not material.has_method("get_shader_override") or not material.has_method("set_shader_override"):
		receipt.reason = "terrain material has no shader override"
		push_warning("Veilfall rock pass skipped: " + str(receipt.reason))
		return receipt
	var code := ""
	var current: Shader = material.call("get_shader_override")
	if bool(material.call("is_shader_override_enabled")) and current != null:
		code = current.code
	else:
		material.call("enable_shader_override", true)
		current = material.call("get_shader_override")
		code = current.code if current != null else ""
	if not code.contains(MARKER):
		if not code.contains(UNIFORM_ANCHOR) or not code.contains(TAIL_ANCHOR):
			receipt.reason = "generated terrain shader anchors not found"
			push_warning("Veilfall rock pass skipped: " + str(receipt.reason))
			return receipt
		code = code.replace(UNIFORM_ANCHOR, UNIFORMS + UNIFORM_ANCHOR)
		code = code.replace(TAIL_ANCHOR, TAIL_ANCHOR + "\n" + TAIL)
		var shader := Shader.new()
		shader.code = code
		material.call("enable_shader_override", false)
		material.call("set_shader_override", shader)
		material.call("enable_shader_override", true)
	var installed: Shader = material.call("get_shader_override")
	if installed == null or not installed.code.contains(MARKER):
		receipt.reason = "override was regenerated after install"
		push_warning("Veilfall rock pass skipped: " + str(receipt.reason))
		return receipt
	for key: String in config:
		if key.begins_with("_") or key == "enabled":
			continue
		var value: Variant = config[key]
		if value is String:
			value = Color(str(value))
		elif value is Array and (value as Array).size() == 2:
			value = Vector2(float(value[0]), float(value[1]))
		material.call("set_shader_param", "vf_" + key, value)
	receipt.installed = true
	# A real renderer echoes a known uniform; the dummy (headless) one does not.
	if DisplayServer.get_name() != "headless" and material.call("get_shader_param", "vf_radius_m") == null:
		push_warning("Veilfall rock pass installed but its uniforms were not accepted")
		receipt.installed = false
		receipt.reason = "uniforms not accepted"
	return receipt
