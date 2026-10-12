shader_type spatial;
// Additive soft mote, camera-facing. Per-instance MultiMesh colour carries hue
// and fade; the quad's UV gives a procedural radial falloff (no outline).
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, world_vertex_coords;

uniform float opacity = 1.0;
uniform float core = 0.35;
uniform float hot = 0.55;
uniform vec4 tint_mul : source_color = vec4(1.0);
varying vec4 tint;

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec2 local = UV - vec2(0.5);
	VERTEX = centre + (INV_VIEW_MATRIX[0].xyz * local.x - INV_VIEW_MATRIX[1].xyz * local.y) * size;
	tint = COLOR * tint_mul;
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float falloff = pow(clamp(1.0 - r, 0.0, 1.0), 1.6);
	float centre_hot = smoothstep(core, 0.0, r);
	vec3 colour = mix(tint.rgb, vec3(1.0), centre_hot * hot);
	ALBEDO = colour * falloff * tint.a * opacity * 1.6;
}
