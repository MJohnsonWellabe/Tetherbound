// OWNER-0912 Tier 2 #4. The imported Banner_1 cloth atlas is teal/black in
// the UV island used by the hanging panel. Multiplying that texture by the
// Team Tether oxblood retint removes the red channel and produces a black
// rectangle. This profile keeps the installed pole, bar and cloth mesh, but
// treats the atlas as value detail instead of a colour multiplier. The 73
// authored cloth vertices are also displaced from their top edge downward,
// so an oblique view sees real fold relief rather than a planar cutout.

shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform vec4 cloth_colour : source_color = vec4(0.48, 0.14, 0.19, 1.0);
uniform vec2 cloth_min = vec2(-0.5, -1.0);
uniform vec2 cloth_size = vec2(1.0, 2.0);
uniform float relief_m : hint_range(0.0, 0.12) = 0.055;
uniform float emission_floor : hint_range(0.0, 0.12) = 0.035;

varying vec2 cloth_local;
varying float fold_slope;

float cloth_wave(vec2 point) {
	float width = max(cloth_size.x, 0.001);
	float height = max(cloth_size.y, 0.001);
	float nx = (point.x - cloth_min.x) / width - 0.5;
	float drop = clamp((cloth_min.y + height - point.y) / height, 0.0, 1.0);
	float anchored = pow(drop, 1.35);
	return relief_m * anchored * (
		0.78 * sin(nx * 9.4248 + drop * 1.35)
		+ 0.28 * sin(nx * 18.8496 - drop * 2.1));
}

void vertex() {
	cloth_local = VERTEX.xy;
	VERTEX.z += cloth_wave(cloth_local);
	const float EPSILON = 0.025;
	float dx = (cloth_wave(cloth_local + vec2(EPSILON, 0.0))
		- cloth_wave(cloth_local - vec2(EPSILON, 0.0))) / (2.0 * EPSILON);
	float dy = (cloth_wave(cloth_local + vec2(0.0, EPSILON))
		- cloth_wave(cloth_local - vec2(0.0, EPSILON))) / (2.0 * EPSILON);
	float facing = NORMAL.z < 0.0 ? -1.0 : 1.0;
	NORMAL = normalize(vec3(-dx, -dy, facing));
	fold_slope = dx * 0.7 + dy * 0.3;
}

void fragment() {
	vec3 source = texture(source_texture, UV).rgb;
	float source_value = dot(source, vec3(0.2126, 0.7152, 0.0722));
	// A bounded value remap retains broad atlas variation without allowing its
	// black/cyan hue to annihilate the oxblood red channel.
	float atlas_detail = mix(0.82, 1.16, source_value);
	float warp = sin(UV.x * 920.0 + UV.y * 31.0);
	float weft = sin(UV.y * 760.0 - UV.x * 23.0);
	float weave = 1.0 + 0.035 * warp * weft;
	float fold_light = clamp(1.0 + fold_slope * 0.24, 0.78, 1.22);
	vec3 base = cloth_colour.rgb * atlas_detail * weave * fold_light;
	ALBEDO = base;
	ROUGHNESS = 0.94;
	// This is only a colour-retention floor. Local lamps and world lighting
	// still supply the readable modelling; the panel never reads self-lit.
	EMISSION = cloth_colour.rgb * emission_floor * weave;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
