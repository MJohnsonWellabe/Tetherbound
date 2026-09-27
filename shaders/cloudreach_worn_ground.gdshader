shader_type spatial;
render_mode blend_mix, depth_draw_never, diffuse_burley, specular_disabled;
uniform sampler2D soil_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 soil_tint : source_color=vec4(0.61,0.50,0.37,1.0);
uniform vec3 patch_centre=vec3(0.0);
uniform float radius=16.5;
uniform vec2 footprint_half=vec2(0.0);
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 offset=world_at.xz-patch_centre.xz;
	float angle=atan(offset.y,offset.x);
	float edge=radius*(0.70+0.065*sin(angle*3.0)+0.04*cos(angle*7.0));
	float dirt=1.0-smoothstep(edge-3.0,edge+1.8,length(offset));
	// Optional local footprint keeps the blend inside the actual polygon;
	// otherwise a nonzero alpha at its edge exposes a straight triangle cut.
	if (footprint_half.x > 0.0 && footprint_half.y > 0.0) {
		float border=length(offset/footprint_half);
		dirt*=1.0-smoothstep(0.46,0.72,border);
	}
	// Fade soil over the actual crown or paving beneath this overlay. A turf
	// replacement would paint grass onto cobble and mismatch high battle yards.
	if(dirt<=0.001){discard;}
	vec3 soil=texture(soil_tex,world_at.xz*0.48).rgb*soil_tint.rgb;
	ALBEDO=soil;
	ALPHA=dirt;
	ROUGHNESS=0.98;
}
