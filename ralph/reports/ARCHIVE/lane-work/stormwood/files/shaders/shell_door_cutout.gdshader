shader_type spatial;
// Ashfoot r42: the Meshy ranger-shelter shell with an open doorway. The shell
// is one closed mesh; the prefab's door stays open (players walk through it
// and the interior catalogue camera looks in through it), so fragments inside
// the doorway box (shelter-local metres, `cut_frame_inv` maps world to the
// shelter frame) are discarded. Back faces are culled so from inside the
// lined room the shell never shows.
render_mode cull_back;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D orm_tex : filter_linear_mipmap, repeat_enable;
uniform float albedo_gain = 1.0;
uniform mat4 cut_frame_inv;
uniform vec3 cut_min = vec3(0.2, -1.0, 2.4);
uniform vec3 cut_max = vec3(1.8, 2.3, 5.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 local = (cut_frame_inv * vec4(world_pos, 1.0)).xyz;
	if (all(greaterThan(local, cut_min)) && all(lessThan(local, cut_max))) {
		discard;
	}
	ALBEDO = texture(albedo_tex, UV).rgb * albedo_gain;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	vec3 orm = texture(orm_tex, UV).rgb;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
}
