shader_type spatial;
// Alpha-blended soft dust/smoke/foam puff, camera-facing, with a cheap
// procedural lobed edge and top-lit shading so it reads as volume, not a disc.
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled, shadows_disabled, world_vertex_coords;

uniform float opacity = 1.0;
uniform float shade = 0.45;
varying vec4 tint;
varying float seed;

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec2 local = UV - vec2(0.5);
	VERTEX = centre + (INV_VIEW_MATRIX[0].xyz * local.x - INV_VIEW_MATRIX[1].xyz * local.y) * size;
	tint = COLOR;
	seed = fract(dot(centre, vec3(12.9898, 78.233, 37.719)));
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float a = atan(p.y, p.x);
	float lobes = 0.80 + 0.10 * sin(a * 5.0 + seed * 40.0) + 0.06 * sin(a * 9.0 - seed * 23.0);
	float r = length(p) * 2.0 / lobes;
	float body = smoothstep(1.0, 0.45, r);
	// Light from above: upper half brighter, underside shaded.
	float lit = mix(1.0 - shade, 1.0 + shade * 0.35, clamp(0.5 - p.y * 1.4, 0.0, 1.0));
	ALBEDO = tint.rgb * lit;
	ALPHA = body * tint.a * opacity;
}
