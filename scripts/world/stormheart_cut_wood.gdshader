shader_type spatial;
render_mode cull_disabled;

// The upper wood strip of the installed village atlas, not its stone/endgrain
// rows. Metre-based deck UVs give the existing floors a human plank scale.
uniform sampler2D wood_atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 wood_tint : source_color = vec4(0.77,0.67,0.53,1.0);

void fragment() {
	vec2 board = vec2(UV.x / 0.36, UV.y / 3.2);
	float row = floor(board.x);
	board.y += mod(row, 3.0) / 3.0;
	vec2 local = fract(board);
	vec2 atlas_uv = vec2(local.y, 0.025 + local.x * 0.24);
	vec3 grain = texture(wood_atlas, atlas_uv).rgb;
	float seam = smoothstep(0.0, 0.025, min(local.x, 1.0-local.x));
	seam *= smoothstep(0.0, 0.006, min(local.y, 1.0-local.y));
	float variation = 0.92 + 0.08*sin(row*2.17 + floor(board.y)*1.31);
	ALBEDO = grain * wood_tint.rgb * mix(0.45,1.0,seam) * variation;
	ROUGHNESS = 0.86;
	SPECULAR = 0.25;
}
