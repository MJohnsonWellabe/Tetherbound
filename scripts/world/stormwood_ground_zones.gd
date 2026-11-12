extends RefCounted

## F41 gap 1 (GPU, 25 Oct: "one grass/moss carpet" at every Stormwood stand).
## Authored ground zones on the actual terrain surface: a world-space zone
## field turns green ground into bare dark loam where it runs low and into
## deep moss where it runs high. The grass field reads the same field
## (`grass_field.gdshader` zone_*), so tufts give way over loam and stand
## short and dark in moss. Paths, rock and the Glass Sink keep their own
## materials (only green ground changes). Presentation only: no geometry,
## physics, scatter or state.
const CONFIG_PATH := "res://data/config/stormwood_ground_finish.json"
const MARKER := "// STORMWOOD-GROUND-ZONES"
const UNIFORM_ANCHOR := "void fragment() {"
const TAIL_ANCHOR := "SPECULAR = 1. - mat.normal_rough.a;"

const UNIFORMS := """
// STORMWOOD-GROUND-ZONES: loam and moss zones on green ground. The noise is
// the grass field's own (same hash, rotation and octaves), so tufts agree.
uniform float sz_strength = 0.0;
uniform float sz_scale = 0.028;
uniform vec2 sz_bare = vec2(0.26, 0.36);
uniform vec2 sz_moss = vec2(0.64, 0.74);
uniform vec4 sz_soil_colour : source_color = vec4(0.17, 0.14, 0.11, 1.0);
uniform vec4 sz_moss_colour : source_color = vec4(0.14, 0.22, 0.12, 1.0);
uniform vec2 sz_pool = vec2(0.0, 0.0);
uniform vec4 sz_pool_colour : source_color = vec4(0.05, 0.06, 0.07, 1.0);
uniform float sz_pool_roughness = 0.38;
uniform float sz_pool_specular = 0.25;

float sz_hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float sz_noise(vec2 q) {
    vec2 p = mat2(vec2(0.857, 0.515), vec2(-0.515, 0.857)) * q;
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(sz_hash12(i), sz_hash12(i + vec2(1.0, 0.0)), f.x),
        mix(sz_hash12(i + vec2(0.0, 1.0)), sz_hash12(i + vec2(1.0, 1.0)), f.x), f.y);
}

float sz_field(vec2 xz) {
    return sz_noise(xz * sz_scale) * 0.7 + sz_noise(xz * sz_scale * 2.7 + vec2(17.3, 5.1)) * 0.3;
}

"""

const TAIL := """
    // STORMWOOD-GROUND-ZONES: bare loam and deep moss on green ground only.
    if (sz_strength > 0.001) {
        // Relative greenness: the teal Stormwood grass and its colour-map
        // darkening still count; brown paths and grey rock do not.
        float sz_green = smoothstep(0.03, 0.12, (ALBEDO.g - max(ALBEDO.r, ALBEDO.b)) / max(ALBEDO.g, 0.02));
        if (sz_green > 0.0) {
            vec2 sz_xz = v_vertex.xz;
            // Out toward the horizon the zones mottled the distance band
            // (r21 preview); they fade between 180 and 300 m from the camera.
            sz_green *= 1.0 - smoothstep(180.0, 300.0, length(v_vertex.xz - _camera_pos.xz));
            float sz_n = sz_field(sz_xz);
            float sz_bare_w = (1.0 - smoothstep(sz_bare.x, sz_bare.y, sz_n)) * sz_green * sz_strength;
            float sz_moss_w = smoothstep(sz_moss.x, sz_moss.y, sz_n) * sz_green * sz_strength;
            float sz_grain = sz_noise(sz_xz * 0.9) * 0.6 + sz_noise(sz_xz * 3.1) * 0.4;
            vec3 sz_soil = sz_soil_colour.rgb * (0.7 + 0.6 * sz_grain);
            vec3 sz_moss_rgb = sz_moss_colour.rgb * (0.75 + 0.5 * sz_grain);
            ALBEDO = mix(ALBEDO, sz_moss_rgb, sz_moss_w * 0.85);
            ALBEDO = mix(ALBEDO, sz_soil, sz_bare_w);
            ROUGHNESS = mix(ROUGHNESS, 0.92, sz_bare_w);
            // Black pools in the lowest part of the loam: dark and wet.
            if (sz_pool.y > sz_pool.x) {
                float sz_pool_w = (1.0 - smoothstep(sz_pool.x, sz_pool.y, sz_n)) * sz_green * sz_strength;
                ALBEDO = mix(ALBEDO, sz_pool_colour.rgb, sz_pool_w);
                // Satin, not mirror: a glossy pool reflected the pale sky as
                // a silver puddle (r21 preview).
                ROUGHNESS = mix(ROUGHNESS, sz_pool_roughness, sz_pool_w);
                SPECULAR = mix(SPECULAR, sz_pool_specular, sz_pool_w);
            }
        }
    }
"""


## The whole ground-finish config with `value_lift_candidate` applied: owner
## priority 1 Nov (batch-1 judges: "crushed near-black uniform carpet; lift
## values, add grove/clearing variation"). OFF by default; when on, its keys
## merge one level deep over the file's own (grass, tiers.<name>,
## terrain_materials.textures.<slot>, ground_zones), so tints rise out of
## near-black and the authored loam/moss/pool zones switch on.
static func finish() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var out: Dictionary = parsed if parsed is Dictionary else {}
	# Each candidate (its own `enabled`) merges its sections in this order.
	# `rock_value_1104` (VIS-STORMWOOD, OFF until judged) darkens the
	# terrain rock slot so cliffs stop reading as pale white walls.
	var copied := false
	for key: String in FINISH_CANDIDATES:
		var cand: Variant = out.get(key, {})
		if not cand is Dictionary or not bool((cand as Dictionary).get("enabled", false)):
			continue
		if not copied:
			out = out.duplicate(true)
			copied = true
		for section: String in (cand as Dictionary):
			if section == "enabled" or section.begins_with("_") or section == "scope":
				continue
			_merge_into(out, section, (cand as Dictionary)[section])
	return out


# `path_loam_1104` (VIS-STORMWOOD, OFF until judged): the pale sand-coloured
# path slot that fills the lower half of every destination close view reads
# darker and cooler, as damp trodden forest earth.
# `grass_patch_1104` (VIS-STORMWOOD, OFF until judged): the grass shader's
# colony mode (full clump contrast, patch thresholds) breaks the even carpet
# into grass colonies with true clearings that show the wet moss floor.
# `wet_earth_1110` (LANE-MESHY, OFF until judged) rides last: it lifts the
# near-black path and pools to banked wet earth.
# `pool_damp_1112` (LANE-THINGS, OFF until judged) rides after it: the pools
# stop being a mirror (they turned into a flat pale slab under the Break sky)
# and read as damp matte earth.
const FINISH_CANDIDATES := ["value_lift_candidate", "rock_value_1104", "path_loam_1104", "grass_patch_1104", "wet_earth_1110", "pool_damp_1112"]


static func _merge_into(target: Dictionary, key: String, value: Variant) -> void:
	if value is Dictionary and target.get(key) is Dictionary:
		var inner: Dictionary = target[key]
		for k: String in (value as Dictionary):
			_merge_into(inner, k, (value as Dictionary)[k])
		return
	target[key] = value


## `stormwood_ground_finish.json ground_zones`, or {} when it is off.
## F41#5 `pool_satin_1104` (OFF until judged): its pool_roughness and
## pool_specular replace the black pools' fixed 0.38 / 0.25 sheen.
static func config() -> Dictionary:
	var finish: Dictionary = finish()
	var zones: Dictionary = finish.get("ground_zones", {})
	if not (bool(finish.get("enabled", false)) and bool(zones.get("enabled", false))):
		return {}
	var satin: Variant = finish.get("pool_satin_1104", {})
	if satin is Dictionary and bool((satin as Dictionary).get("enabled", false)):
		zones = zones.duplicate(true)
		for key: String in ["pool_roughness", "pool_specular"]:
			if (satin as Dictionary).has(key):
				zones[key] = (satin as Dictionary)[key]
	return zones


## The grass field's zone_* keys for the same field (empty when zones are off).
static func grass_keys() -> Dictionary:
	var zones := config()
	if zones.is_empty():
		return {}
	return {
		"zone_strength": float(zones.get("strength", 1.0)),
		"zone_scale": float(zones.get("scale", 0.028)),
		# `grass_bare` (pass 2): tufts thin only where this range runs (the
		# black pools) while the terrain's own loam band is switched off.
		"zone_bare": zones.get("grass_bare", zones.get("bare", [0.26, 0.36])),
		"zone_moss": zones.get("moss", [0.64, 0.74]),
		"zone_moss_shorten": float(zones.get("moss_shorten", 0.6)),
		"zone_moss_tint": str(zones.get("moss_tint", "#b3cca6")),
	}


## Called after assets and auto_shader have reached their final values (after
## the Glass Sink, which shares the same anchors).
static func install(terrain: Object) -> void:
	var zones := config()
	if zones.is_empty():
		return
	var material: Object = terrain.get("material")
	var current: Shader = material.call("get_shader_override")
	if not bool(material.call("is_shader_override_enabled")) or current == null:
		material.call("enable_shader_override", true)
		current = material.call("get_shader_override")
	var code := current.code if current != null else ""
	if not code.contains(MARKER):
		if not code.contains(UNIFORM_ANCHOR) or not code.contains(TAIL_ANCHOR):
			push_error("Stormwood ground zones: terrain material anchors unavailable")
			return
		var shader := Shader.new()
		shader.code = code.replace(UNIFORM_ANCHOR, UNIFORMS + UNIFORM_ANCHOR) \
			.replace(TAIL_ANCHOR, TAIL_ANCHOR + "\n" + TAIL)
		material.call("enable_shader_override", false)
		material.call("set_shader_override", shader)
		material.call("enable_shader_override", true)
	material.call("set_shader_param", "sz_strength", float(zones.get("strength", 1.0)))
	material.call("set_shader_param", "sz_scale", float(zones.get("scale", 0.028)))
	for key: String in ["bare", "moss", "pool"]:
		var pair: Array = zones.get(key, [])
		if pair.size() == 2:
			material.call("set_shader_param", "sz_" + key, Vector2(float(pair[0]), float(pair[1])))
	for key: String in ["soil_colour", "moss_colour", "pool_colour"]:
		if zones.has(key):
			material.call("set_shader_param", "sz_" + key, Color(str(zones[key])))
	for key: String in ["pool_roughness", "pool_specular"]:
		if zones.has(key):
			material.call("set_shader_param", "sz_" + key, float(zones[key]))


## F41#5 `macro_1104` (stormwood_ground_finish.json, OFF until judged). Judges
## read the Stormwood ground as "a flat green grass carpet": the terrain grass
## slot (the wet-moss floor texture) tiles evenly because Stormwood's terrain
## never enables Terrain3D's macro variation. On: two cool moss-tone macro
## colours at long noise scales lay large darker and lighter drifts across it,
## as Meadows does (terrain_playground.json). Shader uniforms only; no bake.
static func macro_variation() -> Dictionary:
	var cand: Variant = finish().get("macro_1104", {})
	return cand if cand is Dictionary and bool((cand as Dictionary).get("enabled", false)) else {}


static func install_macro(terrain: Object) -> void:
	var cfg := macro_variation()
	if cfg.is_empty() or terrain == null:
		return
	var material: Object = terrain.get("material")
	if material == null:
		return
	material.call("set_shader_param", "enable_macro_variation", true)
	for key: String in ["macro_variation1", "macro_variation2"]:
		if cfg.has(key):
			material.call("set_shader_param", key, Color(str(cfg[key])))
	for key: String in ["noise1_scale", "noise2_scale"]:
		if cfg.has(key):
			material.call("set_shader_param", key, float(cfg[key]))
