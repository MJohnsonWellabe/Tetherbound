// W09-VFX (CL-A2). The glow drawn OVER a creature's own meshes for the hit
// flash and the level-up rim: applied per instance through
// GeometryInstance3D.material_overlay by scripts/vfx/body_glow.gd, never by
// editing the creature's materials (those are shared per species and
// colourway -- see creature_body.gd's `_shared_variant_material` -- so an
// albedo edit there would flash every bramblebun on screen at once).
//
// Brightest at the silhouette (a fresnel rim) and lifted by `flat_mix` across
// the whole body, so a hit reads as the body being LIT rather than as a white
// cut-out painted on top of it. MIX blend, not ADD: additive renders at a
// fraction of its strength under the Compatibility renderer the game ships
// (impact_flash.gd's own header), and this has to be judged from a software
// GL frame like every other effect in the fight.
//
// `depth_draw_never`: the creature's opaque pass already wrote the depth this
// overlay tests against, and writing it again from a transparent pass would
// only fight the next transparent thing drawn at the same surface.
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never;

uniform vec4 colour : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float strength : hint_range(0.0, 2.0) = 0.8;
uniform float rim_power : hint_range(0.2, 8.0) = 2.0;
uniform float flat_mix : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, rim_power);
	float a = strength * mix(rim, 1.0, flat_mix);
	ALBEDO = colour.rgb;
	ALPHA = clamp(a, 0.0, 1.0);
}
