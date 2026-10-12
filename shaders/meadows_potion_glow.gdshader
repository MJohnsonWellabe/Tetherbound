shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// One named pickup's candidate halo. Opaque geometry still depth-occludes it.
uniform vec4 glow_colour : source_color = vec4(1.0, 0.94, 0.81, 1.0);
uniform float strength = 0.38;
uniform float falloff_power = 2.0;
uniform float behind_m = 0.2;
uniform float foot_y = 0.0;
uniform float ground_feather_m = 0.10;
uniform float far_fade_start_m = 34.0;
uniform float far_fade_end_m = 46.0;
varying float height_above_foot;
varying float distance_fade;

void vertex() {
	vec3 centre = MODEL_MATRIX[3].xyz;
	vec3 right = INV_VIEW_MATRIX[0].xyz;
	vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec3 back = INV_VIEW_MATRIX[2].xyz;
	vec3 world = centre + right * VERTEX.x + up * VERTEX.y - back * behind_m;
	height_above_foot = world.y - foot_y;
	distance_fade = 1.0 - smoothstep(far_fade_start_m, far_fade_end_m, distance(centre, CAMERA_POSITION_WORLD));
	MODELVIEW_MATRIX = mat4(1.0);
	VERTEX = (VIEW_MATRIX * vec4(world, 1.0)).xyz;
}

void fragment() {
	float radius = length(UV - vec2(0.5)) * 2.0;
	float radial = pow(1.0 - smoothstep(0.0, 1.0, radius), falloff_power);
	// Feather before the ordinary ground can make a straight clipped edge.
	float ground_fade = smoothstep(0.0, ground_feather_m, height_above_foot);
	ALBEDO = glow_colour.rgb * strength * radial * ground_fade * distance_fade;
	ALPHA = 1.0;
}
