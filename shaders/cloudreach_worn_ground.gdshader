shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 grass_tint : source_color=vec4(0.67,0.78,0.62,1.0);
uniform vec4 soil_tint : source_color=vec4(0.61,0.50,0.37,1.0);
uniform vec3 patch_centre=vec3(0.0);
uniform float radius=16.5;
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 offset=world_at.xz-patch_centre.xz;
	float angle=atan(offset.y,offset.x);
	float edge=radius*(0.70+0.065*sin(angle*3.0)+0.04*cos(angle*7.0));
	float dirt=1.0-smoothstep(edge-3.0,edge+1.8,length(offset));
	vec3 turf=texture(grass_tex,world_at.xz*0.27).rgb*grass_tint.rgb;
	vec3 soil=texture(soil_tex,world_at.xz*0.25).rgb*soil_tint.rgb;
	ALBEDO=mix(turf,soil,dirt);
	ROUGHNESS=0.98;
}
