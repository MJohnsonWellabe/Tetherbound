shader_type spatial;
render_mode blend_mix, depth_draw_never, depth_test_disabled, cull_front, diffuse_burley, specular_disabled;

// A bounded density volume; the box is only a proxy, never a visible surface.
// Original project shader, shaped from the inspected Sky Aviary cloud banks.
uniform vec4 cloud_lit : source_color = vec4(0.83, 0.87, 0.89, 1.0);
uniform vec4 cloud_base : source_color = vec4(0.38, 0.47, 0.53, 1.0);
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform float extinction : hint_range(1.0, 20.0) = 10.0;
varying vec3 local_position;
varying vec3 local_eye;

float ellipsoid(vec3 p, vec3 centre, vec3 radius) {
	return (length((p-centre)/radius)-1.0)*min(radius.x,min(radius.y,radius.z));
}
float soft_union(float a, float b) {
	float h = clamp(0.5+0.5*(b-a)/0.15,0.0,1.0);
	return mix(b,a,h)-0.15*h*(1.0-h);
}
float cloud_density(vec3 p) {
	float d = ellipsoid(p,vec3(0.0,-0.23,0.0),vec3(0.83,0.24,0.62));
	d = soft_union(d,ellipsoid(p,vec3(-0.42,0.08,0.0),vec3(0.32,0.36,0.38)));
	d = soft_union(d,ellipsoid(p,vec3(0.10,0.27,-0.16),vec3(0.34,0.46,0.38)));
	d = soft_union(d,ellipsoid(p,vec3(0.46,0.02,0.18),vec3(0.32,0.34,0.36)));
	d = soft_union(d,ellipsoid(p,vec3(-0.03,-0.02,0.40),vec3(0.45,0.36,0.36)));
	// Gentle boundary breakup; no high-frequency sparkle or hard mesh silhouette.
	d += sin(p.x*17.0+sin(p.z*11.0))*sin(p.y*13.0-p.z*7.0)*0.015;
	// Extinction must reach zero before the proxy boundary on every axis.
	float edge = max(abs(p.x),max(abs(p.y),abs(p.z)));
	return (1.0-smoothstep(-0.05,0.10,d))*(1.0-smoothstep(0.80,0.98,edge));
}
void vertex() {
	local_position = VERTEX;
	local_eye = (inverse(MODEL_MATRIX)*vec4(CAMERA_POSITION_WORLD,1.0)).xyz;
}
void fragment() {
	vec3 ray = normalize(local_position-local_eye);
	vec3 inv_ray = 1.0/(ray+vec3(0.000001));
	vec3 a = (-vec3(1.0)-local_eye)*inv_ray;
	vec3 b = (vec3(1.0)-local_eye)*inv_ray;
	vec3 near_t = min(a,b);
	vec3 far_t = max(a,b);
	float start = max(0.0,max(near_t.x,max(near_t.y,near_t.z)));
	float finish = min(far_t.x,min(far_t.y,far_t.z));
	// The exit face may be behind terrain even when cloud is in front of it.
	// Clip the density integration to opaque scene depth instead of testing
	// the proxy face. Compatibility uses OpenGL's [-1,1] NDC depth range.
	float raw_depth = texture(scene_depth,SCREEN_UV).r;
	vec4 scene_view = INV_PROJECTION_MATRIX*vec4(SCREEN_UV*2.0-1.0,raw_depth*2.0-1.0,1.0);
	if (abs(scene_view.w)>0.00001) {
		float opaque_view_depth = -scene_view.z/scene_view.w;
		float exit_view_depth = max(-VERTEX.z,0.00001);
		float opaque_distance = length(local_position-local_eye)*opaque_view_depth/exit_view_depth;
		finish = min(finish,opaque_distance);
	}
	if (finish<=start) { discard; }
	float step_size = (finish-start)/24.0;
	vec3 colour = vec3(0.0);
	float transmission = 1.0;
	for (int i=0;i<24;i++) {
		vec3 p = local_eye+ray*(start+(float(i)+0.5)*step_size);
		float density = cloud_density(p);
		float opacity = 1.0-exp(-density*step_size*extinction);
		float top_light = smoothstep(-0.42,0.40,p.y);
		float shelter = cloud_density(p+vec3(-0.22,0.28,-0.18));
		top_light = clamp(top_light*0.65+(1.0-shelter)*0.35,0.0,1.0);
		vec3 sample_colour = mix(cloud_base.rgb,cloud_lit.rgb,top_light);
		colour += transmission*opacity*sample_colour;
		transmission *= 1.0-opacity;
		if (transmission<0.015) { break; }
	}
	float opacity = 1.0-transmission;
	if (opacity<0.008) { discard; }
	ALBEDO = colour/max(opacity,0.001);
	NORMAL = normalize((VIEW_MATRIX*vec4(0.0,1.0,0.0,0.0)).xyz);
	ROUGHNESS = 1.0;
	ALPHA = opacity;
}
