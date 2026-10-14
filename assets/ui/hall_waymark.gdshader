shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D waymark : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 cloth_min;
uniform vec2 cloth_size;
uniform float ink_opacity : hint_range(0.0, 1.0) = 0.85;
varying vec2 cloth_uv;

void vertex() {
	vec2 local_uv = (VERTEX.xy - cloth_min) / cloth_size;
	cloth_uv = vec2(local_uv.x, 1.0 - local_uv.y);
}

void fragment() {
	vec4 ink = texture(waymark, cloth_uv);
	if (ink.a < 0.01) { discard; }
	ALBEDO = ink.rgb;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	ALPHA = ink.a * ink_opacity;
}
