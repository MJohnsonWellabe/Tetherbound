shader_type spatial;
// Additive velocity-aligned spark streak. Instance basis X is the streak
// axis and length; basis Y length is its width. Bright head, tapered tail.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled, world_vertex_coords;

uniform float opacity = 1.0;
// 1 = bright head/tapered tail (sparks); 0 = uniform along (bolt segments).
uniform float taper = 1.0;
varying vec4 tint;

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	vec3 axis = MODEL_MATRIX[0].xyz;
	float width = length(MODEL_MATRIX[1].xyz);
	vec3 to_camera = normalize(INV_VIEW_MATRIX[3].xyz - centre);
	vec3 side = cross(axis, to_camera);
	side = length(side) > 0.0001 ? normalize(side) : INV_VIEW_MATRIX[1].xyz;
	vec2 local = UV - vec2(0.5);
	VERTEX = centre + axis * local.x + side * local.y * width;
	tint = COLOR;
}

void fragment() {
	float along = UV.x;               // 0 tail, 1 head
	float across = abs(UV.y - 0.5) * 2.0;
	float ends = mix(smoothstep(0.0, 0.08, along) * smoothstep(1.0, 0.92, along), smoothstep(0.0, 0.7, along) * smoothstep(1.0, 0.85, along), taper);
	float body = pow(clamp(1.0 - across, 0.0, 1.0), 1.5) * ends;
	vec3 colour = mix(tint.rgb, vec3(1.0), smoothstep(0.55, 0.0, across) * 0.6);
	ALBEDO = colour * body * tint.a * opacity * 1.8;
}
