shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

// P2-056 (Stormwood uniformed characters lost against the dark ground, "no rim
// light"): a cool backlight edge drawn as a material overlay on a character
// body. Fresnel only, so faces and uniform fronts keep their own shading.
uniform vec3 rim_colour : source_color = vec3(0.72, 0.78, 1.0);
uniform float rim_energy = 0.45;
uniform float rim_power = 3.0;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	ALBEDO = rim_colour * rim_energy * pow(1.0 - facing, rim_power);
}
