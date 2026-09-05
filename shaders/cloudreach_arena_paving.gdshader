shader_type spatial;
render_mode diffuse_burley,specular_disabled;
uniform sampler2D albedo_tex : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 tint : source_color=vec4(0.56,0.54,0.44,1.0);
uniform vec3 origin=vec3(100.0,1160.0,5450.0);
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=world_at.xz-origin.xz;
	float r=length(p);
	vec3 stone=texture(albedo_tex,world_at.xz*0.72).rgb;
	float wear=0.5+0.5*sin(p.x*0.067+sin(p.y*0.093));
	vec3 paving=mix(vec3(0.43),stone,0.66)*tint.rgb;
	// A worked service perimeter, worn central court and narrow radial joints
	// describe the actual arena without competing with timed hazard telegraphs.
	float perimeter=smoothstep(25.0,33.0,r);
	paving*=mix(1.10,0.80,perimeter)*(0.94+0.12*wear);
	float ring=1.0-smoothstep(0.10,0.19,abs(r-25.0));
	float joint=1.0-smoothstep(0.035,0.10,abs(sin(atan(p.y,p.x)*6.0))*max(r,1.0));
	paving=mix(paving,paving*0.52,max(ring,joint*perimeter)*0.42);
	ALBEDO=paving;
	ROUGHNESS=0.98;
}
