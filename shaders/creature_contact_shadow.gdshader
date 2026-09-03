shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

// CREATURE-LEGIBILITY-0903. The Compatibility renderer this project ships
// with has no SSAO (tools/survey.sh's own header names this explicitly), so a
// creature standing in grass has nothing pinning its feet to the ground --
// the owner's "sitting IN the grass, not on it" complaint is partly this, not
// only colour. A soft dark ellipse under the model's own origin (which
// `creature_body.gd::_fit()` already puts at the model's feet) gives every
// body the grounding cue a real-time shadow would, at the cost of one quad.
//
// Unshaded and alpha-blended on purpose: this is a paint-on contact mark, not
// a light interaction, so it reads the same at noon, dusk or under the
// Warrens' torches instead of vanishing wherever the ambient term is already
// dark.

uniform vec4 shadow_colour : source_color = vec4(0.0, 0.0, 0.0, 0.45);
// Fraction of the radius held at full strength before the edge fades out --
// a soft-edged oval, not a hard-edged disc that reads as a decal.
uniform float core_fraction = 0.35;
uniform float edge_power = 1.6;

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = clamp(length(d) * 2.0, 0.0, 1.0);
	float falloff = pow(1.0 - smoothstep(core_fraction, 1.0, r), edge_power);
	ALBEDO = shadow_colour.rgb;
	ALPHA = shadow_colour.a * falloff;
}
