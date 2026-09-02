shader_type spatial;

// WARRENS-BOULDER-STAIN, EXT-06 -- third exterior pass on the Burrow Warrens
// mound/skirt/entrance rock, reviewer evidence "boulders are one value top to
// bottom" and the pass's own #1 item. `_wear_the_cave_stone()`'s existing
// StandardMaterial3D reads a single flat albedo tint over an entire boulder no
// matter how it sits, so a rock half-sunk in dark ground with a mossed
// shoulder was drawn identically to one standing bare in full sun. This wears
// the SAME triplanar Rock030 photo every wall/floor/boulder in the cave
// already wears (`burrow_warrens.gd::ROCK_ALBEDO` -- no new asset, this is
// hand-rolled triplanar sampling of an installed texture, not a new one) but
// blends a dark warm stain toward each boulder's OWN ground contact and a
// moss tint onto its OWN up-facing surfaces, so the difference reads
// per-boulder instead of being painted as one flat colour across the whole
// outcrop. `render_mode world_vertex_coords` puts VERTEX/NORMAL in true world
// space for both stages, so the stain math below needs no manual
// view-to-world reconstruction.
//
// `base_y_world` is set PER MATERIAL by `burrow_warrens.gd::
// _boulder_stain_material()` from that boulder's own placement height, so the
// band sits at THAT rock's own foot wherever in the mound it stands -- a roof
// boulder and a skirt boulder both stain up from their own base, not from one
// shared cave floor height. `_wear_the_cave_stone()`'s own header explains
// which callers reach this file at all: mound/skirt/entrance rock only, never
// the interior rock pass -- the owner's protected interior bar never touches
// this shader.
render_mode cull_back, diffuse_lambert, specular_disabled, world_vertex_coords;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float uv_scale = 0.46;

uniform vec3 base_tint : source_color = vec3(0.6, 0.55, 0.48);
uniform vec3 stain_colour : source_color = vec3(0.12, 0.09, 0.06);
uniform vec3 moss_colour : source_color = vec3(0.22, 0.27, 0.13);

// Metres above this boulder's OWN base (see header) before the stain has
// fully faded back to the boulder's plain tint, and the softness of that
// fade. Both in world metres, so a big and a small boulder in the same
// config stain the same real distance up from the ground, matching how damp
// actually climbs a rock rather than scaling with the model's own draw size.
uniform float base_y_world = 0.0;
uniform float stain_height = 0.85;
uniform float stain_softness = 0.5;

// Moss grows on what faces the sky. `moss_normal_min` is the world-space
// upward-facing dot product a surface needs before moss starts creeping in;
// `moss_strength` is how far the blend goes once it does.
uniform float moss_normal_min : hint_range(-1.0, 1.0) = 0.5;
uniform float moss_strength : hint_range(0.0, 1.0) = 0.6;

uniform float roughness_value : hint_range(0.0, 1.0) = 0.95;

// Cheap triplanar: three axis-projected samples of the same installed rock
// photo, blended by how much the surface normal faces each axis -- the same
// idea `_material()`'s own `uv1_triplanar` StandardMaterial3D flag already
// applies to every other rock surface in the file, written out by hand here
// so the fragment stage can also read the world normal for the moss blend
// below, which a StandardMaterial3D has no hook to do.
vec3 triplanar(vec3 world_pos, vec3 world_normal) {
	vec3 blend = abs(world_normal);
	blend /= (blend.x + blend.y + blend.z + 0.0001);
	vec3 xc = texture(albedo_tex, world_pos.yz * uv_scale).rgb;
	vec3 yc = texture(albedo_tex, world_pos.xz * uv_scale).rgb;
	vec3 zc = texture(albedo_tex, world_pos.xy * uv_scale).rgb;
	return xc * blend.x + yc * blend.y + zc * blend.z;
}

void fragment() {
	vec3 world_pos = VERTEX;
	vec3 world_normal = normalize(NORMAL);

	vec3 tex_colour = triplanar(world_pos, world_normal);
	// Same 0.75 lerp toward the near-white rock tint `_material()`'s own
	// textured branch already uses (MAT-BLOCKOUT), so a boulder's MID band --
	// above the stain, below the moss -- matches the unstained rock exactly.
	vec3 tinted = mix(base_tint, vec3(1.0, 0.949, 0.878), 0.75);
	vec3 colour = tex_colour * tinted;

	float soft = max(stain_softness, 0.05);
	float height_above_base = world_pos.y - base_y_world;
	float stain_t = 1.0 - smoothstep(stain_height, stain_height + soft, height_above_base);
	colour = mix(colour, stain_colour, stain_t * 0.85);

	float moss_t = smoothstep(moss_normal_min, moss_normal_min + 0.3, world_normal.y);
	colour = mix(colour, moss_colour, moss_t * moss_strength);

	ALBEDO = colour;
	ROUGHNESS = roughness_value;
}
