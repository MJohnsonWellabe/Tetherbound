extends RefCounted
## F41#1 root_floor_1104 (OFF until judged; stormheart_presentation.json).
## Judges read the Stormheart hollow as "a dark cylindrical ring with a hole":
## inside the trunk the terrain is the same green meadow texture as outside.
## Inside radius_m of the trunk axis the terrain turns to dark, damp root loam
## with a faint root-grain streak toward the centre. Terrain material only:
## no geometry, collision, route or save change.

const CONFIG_PATH := "res://data/config/stormheart_presentation.json"
const MARKER := "// STORMHEART-ROOT-FLOOR"
const UNIFORM_ANCHOR := "void fragment() {"
const TAIL_ANCHOR := "SPECULAR = 1. - mat.normal_rough.a;"

const UNIFORMS := """
// STORMHEART-ROOT-FLOOR
uniform vec2 rf_centre = vec2(-100.0, 5470.0);
uniform float rf_radius = 40.0;
uniform float rf_feather = 6.0;
uniform vec4 rf_loam : source_color = vec4(0.13, 0.11, 0.09, 1.0);
uniform vec4 rf_root : source_color = vec4(0.24, 0.19, 0.14, 1.0);
uniform float rf_roughness = 0.82;
uniform float rf_strength = 1.0;
uniform float rf_grain_strength = 0.6;
uniform float rf_keep_moss = 0.35;
uniform float rf_specular = 0.08;

"""

const TAIL := """
    // STORMHEART-ROOT-FLOOR: dark root loam inside the trunk hollow.
    {
        vec2 rf_d = v_vertex.xz - rf_centre;
        float rf_r = length(rf_d);
        float rf_w = (1.0 - smoothstep(rf_radius - rf_feather, rf_radius, rf_r)) * rf_strength;
        if (rf_w > 0.0) {
            // r2: blotchy root mottling (no radial spokes) so the floor reads
            // as damp loam with root humps, not a sunburst.
            float rf_n1 = sin(v_vertex.x * 0.31 + sin(v_vertex.z * 0.23) * 2.0) * sin(v_vertex.z * 0.27 + sin(v_vertex.x * 0.19) * 2.0);
            float rf_n2 = sin(v_vertex.x * 1.3 + v_vertex.z * 0.9) * sin(v_vertex.z * 1.1 - v_vertex.x * 0.7);
            // r3: moss survives in large irregular drifts (two incommensurate
            // low-frequency waves), not regular spots.
            float rf_drift = sin(v_vertex.x * 0.083 + sin(v_vertex.z * 0.051) * 3.1) * 0.6
                + sin(v_vertex.z * 0.067 + sin(v_vertex.x * 0.043) * 2.7) * 0.4;
            float rf_root_mask = smoothstep(0.35, 0.75, rf_n1 * 0.5 + 0.5) * rf_grain_strength;
            vec3 rf_col = mix(rf_loam.rgb, rf_root.rgb, rf_root_mask) * (0.9 + rf_n2 * 0.1);
            rf_col = mix(rf_col, ALBEDO * 0.7, rf_keep_moss * smoothstep(0.25, 0.75, rf_drift + rf_n2 * 0.12));
            ALBEDO = mix(ALBEDO, rf_col, rf_w);
            ROUGHNESS = mix(ROUGHNESS, rf_roughness, rf_w);
            SPECULAR = mix(SPECULAR, rf_specular, rf_w);
            METALLIC = mix(METALLIC, 0.0, rf_w);
        }
    }
"""


static func config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var cfg: Variant = (parsed as Dictionary).get("root_floor_1104", {})
	if not cfg is Dictionary or not bool((cfg as Dictionary).get("enabled", false)):
		return {}
	return cfg


## Shader source with the root-floor patch applied (unchanged when anchors are missing).
static func patched_code(code: String) -> String:
	if code.contains(MARKER) or not code.contains(UNIFORM_ANCHOR) or not code.contains(TAIL_ANCHOR):
		return code
	return code.replace(UNIFORM_ANCHOR, UNIFORMS + UNIFORM_ANCHOR) \
		.replace(TAIL_ANCHOR, TAIL_ANCHOR + "\n" + TAIL)


static func install(terrain: Object, cfg: Dictionary = {}) -> void:
	if cfg.is_empty():
		cfg = config()
	if cfg.is_empty():
		return
	var material: Object = terrain.get("material")
	var current: Shader = material.call("get_shader_override")
	if not bool(material.call("is_shader_override_enabled")) or current == null:
		material.call("enable_shader_override", true)
		current = material.call("get_shader_override")
	var code := current.code if current != null else ""
	if not code.contains(MARKER):
		var patched := patched_code(code)
		if patched == code:
			push_error("Stormheart root floor: terrain material anchors unavailable")
			return
		var shader := Shader.new()
		shader.code = patched
		material.call("enable_shader_override", false)
		material.call("set_shader_override", shader)
		material.call("enable_shader_override", true)
	var centre: Array = cfg.get("centre", [-100.0, 5470.0])
	material.call("set_shader_param", "rf_centre", Vector2(float(centre[0]), float(centre[1])))
	material.call("set_shader_param", "rf_radius", float(cfg.get("radius_m", 40.0)))
	material.call("set_shader_param", "rf_feather", float(cfg.get("feather_m", 6.0)))
	material.call("set_shader_param", "rf_loam", Color(str(cfg.get("loam_colour", "#211c17"))))
	material.call("set_shader_param", "rf_root", Color(str(cfg.get("root_colour", "#3d3024"))))
	material.call("set_shader_param", "rf_roughness", float(cfg.get("roughness", 0.82)))
	material.call("set_shader_param", "rf_strength", float(cfg.get("strength", 1.0)))
	material.call("set_shader_param", "rf_grain_strength", float(cfg.get("grain_strength", 0.6)))
	material.call("set_shader_param", "rf_keep_moss", float(cfg.get("keep_moss", 0.35)))
	material.call("set_shader_param", "rf_specular", float(cfg.get("specular", 0.08)))
