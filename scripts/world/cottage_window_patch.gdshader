shader_type spatial;
// Ashfoot r48: the window's light on the opposite wall. An additive patch in
// the window's pane pattern, its level set per storm phase and lifted by the
// surge flash in cottage_interior.gd (no flashing of its own).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 colour : source_color = vec4(0.85, 0.82, 1.0, 1.0);
uniform float level = 0.0;
uniform vec2 panes = vec2(3.0, 2.0);
uniform float bar = 0.07;

void fragment() {
	vec2 g = fract(UV * panes);
	float pane = smoothstep(bar, bar + 0.04, g.x) * smoothstep(bar, bar + 0.04, 1.0 - g.x)
		* smoothstep(bar, bar + 0.04, g.y) * smoothstep(bar, bar + 0.04, 1.0 - g.y);
	float edge = smoothstep(0.0, 0.18, UV.x) * smoothstep(0.0, 0.18, 1.0 - UV.x)
		* smoothstep(0.0, 0.18, UV.y) * smoothstep(0.0, 0.18, 1.0 - UV.y);
	ALBEDO = colour.rgb * clamp(level, 0.0, 2.0) * pane * edge;
}
