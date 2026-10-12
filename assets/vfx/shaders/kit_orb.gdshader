shader_type spatial;
// P2-060 catch orb: a lit sphere with depth. Darker body shading, a slowly
// turning inner swirl seen through a glassy shell, and a bright fresnel rim
// so the orb reads as a 3D object beside the creature, not a flat bright disc.
render_mode cull_back, shadows_disabled;

uniform vec4 body : source_color = vec4(0.62, 0.45, 0.12, 1.0);
uniform vec4 swirl : source_color = vec4(1.0, 0.86, 0.45, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.97, 0.86, 1.0);
uniform float swirl_speed = 1.6;
uniform float glow = 1.0;
varying vec3 local_pos;

void vertex() {
	local_pos = normalize(VERTEX);
}

void fragment() {
	vec3 p = local_pos;
	float a = atan(p.z, p.x) + TIME * swirl_speed + p.y * 3.2;
	float bands = 0.5 + 0.5 * sin(a * 3.0 + sin(p.y * 7.0 + TIME) * 1.5);
	float core = smoothstep(0.35, 1.0, bands) * (1.0 - abs(p.y) * 0.6);
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, 2.6);
	ALBEDO = mix(body.rgb, swirl.rgb, core * 0.65);
	ROUGHNESS = 0.18;
	METALLIC = 0.15;
	SPECULAR = 0.8;
	EMISSION = (swirl.rgb * core * 0.55 + rim_colour.rgb * rim * 1.6) * glow;
}
