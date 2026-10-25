shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float elapsed = 0.0;
uniform int phase = 0;
uniform vec3 origin = vec3(100.0,1160.0,5450.0);
uniform vec3 wind_offsets = vec3(-19.0,0.0,19.0);
uniform float wind_half_width = 3.2;
uniform float wind_rotation = 8.0;
uniform vec3 wind_cycle = vec3(6.0,1.4,1.5);
uniform vec3 arc_cycle = vec3(5.0,1.6,1.4);
uniform float arc_rotation = -14.0;
uniform vec3 arc_shape = vec3(14.0,33.0,18.0);
uniform vec3 lee0 = vec3(-20.0,-12.0,5.5);
uniform vec3 lee1 = vec3(0.0,24.0,5.5);
uniform vec3 lee2 = vec3(20.0,-12.0,5.5);
// F22#4 Veyra readability (OFF by default: today's look).
uniform float lane_alpha = 0.21;
uniform float rim_alpha = 0.0;
uniform float rim_width = 0.35;
// Owner 24 Oct (no outlined attack areas): wind streaks drifting down each lane
// with soft edges, instead of a filled plane. 0 = off (today's look).
uniform float streak_alpha = 0.0;
uniform float streak_speed = 9.0;
varying vec2 point;
void vertex() { point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xz - origin.xz; }
float stage(vec3 cycle) { float t=mod(elapsed,cycle.x); return t<cycle.y ? 1.0 : (t>=cycle.x-cycle.z ? 0.0 : 2.0); }
void fragment() {
	float radius=length(point);
	float wind=0.0;
	float arc=0.0;
	float wa=radians(elapsed*wind_rotation);
	float cross_lane=dot(point,vec2(cos(wa),sin(wa)));
	float rim=0.0;
	float streak=0.0;
	float along=dot(point,vec2(-sin(wa),cos(wa)));
	for(int i=0;i<3;i++){
		float signed_across=cross_lane-wind_offsets[i];
		float across=abs(signed_across);
		wind=max(wind,1.0-step(wind_half_width,across));
		rim=max(rim,(1.0-step(wind_half_width,across))*step(wind_half_width-rim_width,across));
		// Soft wisps in 0.8 m rows across the lane, each broken into drifting
		// dashes with its own phase; soft toward the lane edges, no line.
		float row=floor(signed_across/0.8);
		float seed=fract(sin(row*12.9898+float(i)*78.233)*43758.5453);
		float wisp=1.0-smoothstep(0.04,0.3,abs(fract(signed_across/0.8)-0.5));
		float dash=smoothstep(0.55,0.95,sin(along*0.22+seed*6.2831853-elapsed*streak_speed*0.22));
		float soft_edge=1.0-smoothstep(wind_half_width*0.55,wind_half_width,across);
		streak=max(streak,wisp*dash*soft_edge*(0.55+0.45*seed));
	}
	float ar=radians(elapsed*arc_rotation);
	for(int i=0;i<3;i++){
		float d=mod(atan(point.y,point.x)-ar-float(i)*6.2831853/3.0+3.14159265,6.2831853)-3.14159265;
		arc=max(arc,1.0-step(radians(arc_shape.z),abs(d)));
	}
	arc*=step(arc_shape.x,radius)*(1.0-step(arc_shape.y,radius));
	float sheltered=1.0-step(lee0.z,distance(point,lee0.xy));
	sheltered=max(sheltered,1.0-step(lee1.z,distance(point,lee1.xy)));
	sheltered=max(sheltered,1.0-step(lee2.z,distance(point,lee2.xy)));
	float ws=stage(wind_cycle),as_=stage(arc_cycle);
	wind*=step(0.5,ws)*float(phase>0);
	rim*=step(0.5,ws)*float(phase>0);
	streak*=step(0.5,ws)*float(phase>0);
	arc*=step(0.5,as_)*float(phase>1);
	vec3 color=mix(vec3(0.93,0.70,0.28),vec3(0.56,0.86,0.97),step(1.5,ws));
	color=mix(color,mix(vec3(0.97,0.60,0.18),vec3(0.90,0.23,0.26),step(1.5,as_)),arc);
	// The rim lifts toward white before ALBEDO is written (it was mixed after,
	// so the readability rim never showed its highlight).
	color=mix(color,vec3(1.0),rim*step(0.01,rim_alpha)*0.6);
	color=mix(color,vec3(0.94,0.97,1.0),streak*step(0.01,streak_alpha));
	ALBEDO=color;
	ALPHA=max(max(max(wind,arc)*lane_alpha,rim*rim_alpha),streak*streak_alpha)*(1.0-sheltered)*(1.0-step(36.0,radius));
}
