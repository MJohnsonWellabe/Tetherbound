// One world-space turf family across crowns, path edges and worn yards.
uniform sampler2D grass_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 grass_tint : source_color = vec4(0.55,0.66,0.40,1.0);
uniform float grass_scale = 0.65;
vec3 cloudreach_turf(vec3 at) {
	vec3 fine=texture(grass_texture,at.xz*grass_scale).rgb;
	vec3 turned=texture(grass_texture,mat2(vec2(0.8,0.6),vec2(-0.6,0.8))*at.xz*grass_scale*0.71).rgb;
	vec3 texture_value=mix(fine,turned,0.35);
	// Keep installed texture detail but suppress large lumpy camouflage patches.
	texture_value=mix(vec3(0.51),texture_value,0.52);
	float broad=sin(at.x*0.029+sin(at.z*0.041))*0.045;
	return texture_value*grass_tint.rgb*(1.0+broad);
}
