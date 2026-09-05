shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D dirt_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(0.69, 0.57, 0.39);
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float edge = smoothstep(0.0, 0.17, min(UV.x, 1.0 - UV.x));
	float edge_wander=sin(world_position.x*1.8+sin(world_position.z*0.83))*0.025;
	edge=smoothstep(0.025,0.23,min(UV.x,1.0-UV.x)+edge_wander);
	vec3 soil=texture(dirt_texture,world_position.xz*0.24).rgb*tint;
	vec3 grass=texture(grass_texture,world_position.xz*0.27).rgb*vec3(0.53,0.67,0.43);
	ALBEDO=mix(grass,soil,edge);
	ROUGHNESS = 0.98;
}
