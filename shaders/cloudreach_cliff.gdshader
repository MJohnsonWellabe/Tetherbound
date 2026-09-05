shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D rock_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 stone_light : source_color = vec3(0.70, 0.65, 0.53);
uniform vec3 stone_dark : source_color = vec3(0.38, 0.39, 0.33);
uniform float texture_scale = 0.055;
varying vec3 world_position;
varying vec3 world_normal;
float noise3(vec3 p) { return sin(p.x * 0.83 + sin(p.z * 0.67)) * 0.5 + sin(p.z * 0.49 + p.y * 0.37) * 0.5; }
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 weight = pow(abs(world_normal), vec3(4.0));
	weight /= max(weight.x + weight.y + weight.z, 0.001);
	vec3 tex = texture(rock_texture, world_position.zy * texture_scale).rgb * weight.x;
	tex += texture(rock_texture, world_position.xz * texture_scale).rgb * weight.y;
	tex += texture(rock_texture, world_position.xy * texture_scale).rgb * weight.z;
	float bend = noise3(world_position * 0.027) * 8.0;
	float bed_phase=fract((world_position.y+bend)*0.11);
	float strata=smoothstep(0.02,0.20,bed_phase)*(1.0-smoothstep(0.72,0.96,bed_phase));
	float macro = noise3(world_position * 0.043) * 0.5 + 0.5;
	vec3 stone = mix(stone_dark, stone_light, clamp(0.18 + macro * 0.45 + strata * 0.23, 0.0, 1.0));
	ALBEDO = stone * mix(vec3(0.78),tex*2.0,0.80);
	// Rock-family normals are projected on the same world-space faces. Strong
	// strata remain metre-scale; normal relief supplies readable close stone.
	vec3 nx=texture(rock_normal,world_position.zy*texture_scale).xyz*2.0-1.0;
	vec3 ny=texture(rock_normal,world_position.xz*texture_scale).xyz*2.0-1.0;
	vec3 nz=texture(rock_normal,world_position.xy*texture_scale).xyz*2.0-1.0;
	vec3 detail=vec3(nx.z*sign(world_normal.x),nx.y,nx.x)*weight.x;
	detail+=vec3(ny.x,ny.z*sign(world_normal.y),ny.y)*weight.y;
	detail+=vec3(nz.x,nz.y,nz.z*sign(world_normal.z))*weight.z;
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(mix(world_normal,detail,0.38)),0.0)).xyz);
	ROUGHNESS = 0.96;
}
