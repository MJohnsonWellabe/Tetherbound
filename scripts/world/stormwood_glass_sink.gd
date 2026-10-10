extends RefCounted

## Shade the actual baked terrain. A separate polar mesh would intersect the
## square heightfield triangles on the steep inner wall of the Glass Sink.
const CONFIG_PATH := "res://data/config/stormwood_glass_sink.json"
const MARKER := "// STORMWOOD-GLASS-SINK"
const UNIFORM_ANCHOR := "void fragment() {"
const TAIL_ANCHOR := "SPECULAR = 1. - mat.normal_rough.a;"

const UNIFORMS := """
// STORMWOOD-GLASS-SINK: material identity on the existing terrain surface.
uniform vec2 gs_centre = vec2(700.0, 2700.0);
uniform float gs_inner_radius = 238.0;
uniform float gs_outer_radius = 718.0;
uniform float gs_edge_feather_m = 12.0;
uniform vec4 gs_glass_colour : source_color = vec4(0.141, 0.235, 0.251, 1.0);
uniform vec4 gs_facet_colour : source_color = vec4(0.275, 0.384, 0.4, 1.0);
uniform vec4 gs_seam_colour : source_color = vec4(0.451, 0.565, 0.502, 1.0);
uniform float gs_fracture_scale = 0.085;
uniform float gs_seam_width = 0.022;
uniform float gs_roughness = 0.31;
uniform float gs_metallic = 0.18;

vec2 gs_fracture_point(vec2 cell) {
    return fract(sin(vec2(dot(cell, vec2(127.1, 311.7)),
        dot(cell, vec2(269.5, 183.3)))) * 43758.5453);
}

"""

const TAIL := """
    // STORMWOOD-GLASS-SINK: floor and walls; retain the living island crown.
    {
        vec2 gs_point = v_vertex.xz;
        float gs_radius = length(gs_point - gs_centre);
        float gs_noise = sin(gs_point.x * 0.21) * sin(gs_point.y * 0.17) * 2.0;
        float gs_weight = smoothstep(gs_inner_radius, gs_inner_radius + gs_edge_feather_m,
            gs_radius + gs_noise) * (1.0 - smoothstep(gs_outer_radius - gs_edge_feather_m,
            gs_outer_radius, gs_radius + gs_noise));
        if (gs_weight > 0.0) {
            vec2 gs_p = gs_point * gs_fracture_scale;
            vec2 gs_cell = floor(gs_p);
            vec2 gs_offset = fract(gs_p);
            float gs_first = 10.0;
            float gs_second = 10.0;
            vec2 gs_nearest = gs_cell;
            for (int gs_x = -1; gs_x <= 1; gs_x++) {
                for (int gs_y = -1; gs_y <= 1; gs_y++) {
                    vec2 gs_neighbour = vec2(float(gs_x), float(gs_y));
                    vec2 gs_delta = gs_neighbour + gs_fracture_point(gs_cell + gs_neighbour) - gs_offset;
                    float gs_d = dot(gs_delta, gs_delta);
                    if (gs_d < gs_first) {
                        gs_second = gs_first;
                        gs_first = gs_d;
                        gs_nearest = gs_cell + gs_neighbour;
                    } else {
                        gs_second = min(gs_second, gs_d);
                    }
                }
            }
            float gs_edge = sqrt(gs_second) - sqrt(gs_first);
            float gs_line = 1.0 - smoothstep(gs_seam_width,
                gs_seam_width + max(fwidth(gs_edge), 0.005), gs_edge);
            vec2 gs_grain = gs_fracture_point(gs_nearest);
            float gs_cloud = sin(gs_point.x * 0.006 + sin(gs_point.y * 0.012)) * 0.5 + 0.5;
            vec3 gs_body = mix(gs_glass_colour.rgb, gs_facet_colour.rgb,
                (0.25 + gs_grain.x * 0.6) * 0.65 + gs_cloud * 0.12);
            ALBEDO = mix(ALBEDO, mix(gs_body, gs_seam_colour.rgb, gs_line * 0.48), gs_weight);
            ROUGHNESS = mix(ROUGHNESS,
                clamp(gs_roughness + gs_grain.y * 0.18 + gs_line * 0.22, 0.1, 0.9), gs_weight);
            METALLIC = mix(METALLIC, gs_metallic, gs_weight);
            SPECULAR = mix(SPECULAR, 0.55, gs_weight);
            NORMAL_MAP_DEPTH *= 1.0 - gs_weight * 0.8;
        }
    }
"""

## Called after assets and auto_shader have reached their final values, like
## the existing Veilfall regional material. No geometry, physics or state.
static func install(terrain: Object, sink: Dictionary) -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var material: Object = terrain.get("material")
	var current: Shader = material.call("get_shader_override")
	if not bool(material.call("is_shader_override_enabled")) or current == null:
		material.call("enable_shader_override", true)
		current = material.call("get_shader_override")
	var code := current.code if current != null else ""
	if not code.contains(MARKER):
		if not code.contains(UNIFORM_ANCHOR) or not code.contains(TAIL_ANCHOR):
			push_error("Glass Sink terrain material anchors unavailable")
			return
		var shader := Shader.new()
		shader.code = code.replace(UNIFORM_ANCHOR, UNIFORMS + UNIFORM_ANCHOR) \
			.replace(TAIL_ANCHOR, TAIL_ANCHOR + "\n" + TAIL)
		material.call("enable_shader_override", false)
		material.call("set_shader_override", shader)
		material.call("enable_shader_override", true)
	material.call("set_shader_param", "gs_centre", Vector2(float(sink.centre[0]), float(sink.centre[1])))
	material.call("set_shader_param", "gs_inner_radius", float(sink.island_radius) - 12.0)
	material.call("set_shader_param", "gs_outer_radius", float(sink.outer_radius) - 2.0)
	for key: String in ["glass_colour", "facet_colour", "seam_colour"]:
		material.call("set_shader_param", "gs_" + key, Color(str(config[key])))
	for key: String in ["edge_feather_m", "fracture_scale", "seam_width", "roughness", "metallic"]:
		material.call("set_shader_param", "gs_" + key, float(config[key]))
