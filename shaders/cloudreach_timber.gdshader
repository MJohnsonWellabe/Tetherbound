shader_type spatial;
render_mode diffuse_burley,specular_disabled;
uniform vec4 tint : source_color=vec4(0.43,0.32,0.21,1.0);
varying vec3 local_at;
void vertex(){local_at=VERTEX;}
void fragment(){
	float grain=sin(local_at.x*117.0+sin(local_at.z*63.0)+sin(local_at.y*0.6)*0.3);
	float worn=sin(local_at.x*4.3+local_at.z*7.1+local_at.y*0.13)*0.5+0.5;
	ALBEDO=tint.rgb*(0.84+grain*0.055+worn*0.18);
	ROUGHNESS=0.9;
}
