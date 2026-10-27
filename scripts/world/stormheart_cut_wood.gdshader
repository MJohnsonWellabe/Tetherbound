shader_type spatial;
render_mode cull_disabled;

// The upper wood strip of the installed village atlas, not its stone/endgrain
// rows. Metre-based deck UVs give the existing floors a human plank scale.
uniform sampler2D wood_atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 wood_tint : source_color = vec4(0.77,0.67,0.53,1.0);
// 0 keeps the atlas's own orange grain; 1 is fully grey. A multiply tint alone
// cannot take that orange to aged timber without crushing the value.
uniform float weathering : hint_range(0.0, 1.0) = 0.0;
// Metres per UV unit, for meshes whose UVs run 0-1 across their whole size
// (a PlaneMesh floor). The Stormheart decks already carry metre UVs: 1, 1.
uniform vec2 uv_metres = vec2(1.0, 1.0);
// Board width and length in metres; plank-to-plank tone variation.
uniform vec2 board_m = vec2(0.36, 3.2);
uniform float board_variation = 0.08;

void fragment() {
	vec2 board = vec2(UV.x * uv_metres.x / board_m.x, UV.y * uv_metres.y / board_m.y);
	float row = floor(board.x);
	board.y += mod(row, 3.0) / 3.0;
	vec2 local = fract(board);
	vec2 atlas_uv = vec2(local.y, 0.025 + local.x * 0.24);
	vec3 grain = texture(wood_atlas, atlas_uv).rgb;
	grain = mix(grain, vec3(dot(grain, vec3(0.299, 0.587, 0.114))), weathering);
	float seam = smoothstep(0.0, 0.025, min(local.x, 1.0-local.x));
	seam *= smoothstep(0.0, 0.006, min(local.y, 1.0-local.y));
	float variation = 1.0 - board_variation + board_variation*sin(row*2.17 + floor(board.y)*1.31);
	ALBEDO = grain * wood_tint.rgb * mix(0.45,1.0,seam) * variation;
	ROUGHNESS = 0.86;
	SPECULAR = 0.25;
}
