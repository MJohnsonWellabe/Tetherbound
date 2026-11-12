extends MultiMeshInstance3D

## storm_phase_1111 mist layers (GPU judges on five F41 rows: "no fog layering
## between near and far", "single purple treeline card", "purple fog wall
## reads flat"). Low, soft banks of mist stand between the tree layers at mid
## distance, so each rank of trunks reads as a darker silhouette against the
## paler bank behind it. One MultiMesh of Y-billboard quads on a fixed world
## grid around the camera (the storm shafts' scheme): no volumetrics, no scene
## walk. Rules the judged fog arms taught:
## - never over the near ground: banks fade out inside `near_fade_m`;
## - no glare: banks are drawn in the storm horizon colour with ordinary alpha
##   blending, so any number of overlapping banks tends toward that colour
##   and can never be brighter than the sky's own horizon (the Glass Field
##   "white lens blob" came from additive height fog).
## Strength follows the Surge phase row's `fog_layers`. Client presentation only.

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 bank_colour : source_color = vec3(0.48, 0.45, 0.66);
uniform float strength = 0.0;
uniform vec2 near_fade_m = vec2(30.0, 70.0);
uniform vec2 far_fade_m = vec2(240.0, 380.0);
uniform float time = 0.0;
varying float v_seed;
varying float v_alpha;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	v_seed = INSTANCE_CUSTOM.x;
	v_alpha = INSTANCE_CUSTOM.y;
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 fwd = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float u = UV.x;
	// v runs 0 at the bank's top to 1 at its foot.
	float v = UV.y;
	float drift = time * 0.012;
	float wisps = noise(vec2(u * 3.2 + v_seed * 17.0 + drift, v * 1.4 + v_seed * 5.0))
		* 0.65 + noise(vec2(u * 7.5 - drift * 1.7 + v_seed * 3.0, v * 3.0)) * 0.35;
	// A ragged top (the wisps eat into it), a dense body, a soft foot so the
	// terrain cut never shows as a line.
	float top = smoothstep(0.0, 0.5, v - (1.0 - wisps) * 0.28);
	float foot = 1.0 - smoothstep(0.84, 1.0, v);
	float across = smoothstep(0.0, 0.32, u) * (1.0 - smoothstep(0.68, 1.0, u));
	float dist = length(VERTEX);
	float fade = smoothstep(near_fade_m.x, near_fade_m.y, dist) * (1.0 - smoothstep(far_fade_m.x, far_fade_m.y, dist));
	ALBEDO = bank_colour;
	ALPHA = clamp(strength * v_alpha * top * foot * across * mix(0.7, 1.0, wisps) * fade, 0.0, 1.0);
}
"""

var cfg: Dictionary = {}
var _world: Node
var _material: ShaderMaterial
var _cell := Vector2i(2147483647, 2147483647)
var _time := 0.0
var _strength := 0.0


func setup(config: Dictionary, world: Node = null) -> void:
	cfg = config
	_world = world
	name = "StormFogLayers"
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	# After the storm ceiling, before rain and telegraphs.
	_material.render_priority = Material.RENDER_PRIORITY_MIN + 1
	for key: String in ["near_fade_m", "far_fade_m"]:
		var pair: Array = cfg.get(key, [])
		if pair.size() == 2:
			_material.set_shader_parameter(key, Vector2(float(pair[0]), float(pair[1])))
	quad.material = _material
	var ring := int(cfg.get("ring", 5))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = (ring * 2 + 1) * (ring * 2 + 1)
	multimesh = mm
	var reach := float(cfg.get("far_fade_m", [240.0, 380.0])[1]) + 200.0
	custom_aabb = AABB(Vector3(-reach, -400.0, -reach), Vector3(reach * 2.0, 800.0, reach * 2.0))
	visible = false


## Phase strength (the Surge row's `fog_layers`, cross-faded with the rest)
## and the storm horizon colour the banks take. `lift` moves the colour a
## little toward white so a bank is a touch paler than the fogged trunks
## behind it; `max_alpha` caps one bank's cover.
func set_look(value: float, horizon: Color) -> void:
	_strength = clampf(value, 0.0, 1.0) * float(cfg.get("max_alpha", 0.4))
	if _material != null:
		_material.set_shader_parameter("strength", _strength)
		_material.set_shader_parameter("bank_colour", bank_colour(horizon, cfg))
	visible = _strength > 0.0005


## The bank colour for a storm horizon colour (pure; tested): the horizon hue
## lifted by `lift`, never above `max_luminance`.
static func bank_colour(horizon: Color, config: Dictionary) -> Color:
	var out := horizon.lerp(Color.WHITE, clampf(float(config.get("lift", 0.12)), 0.0, 1.0))
	var cap := float(config.get("max_luminance", 0.62))
	var lum := out.get_luminance()
	if lum > cap and lum > 0.0:
		out = Color(out.r * cap / lum, out.g * cap / lum, out.b * cap / lum)
	return out


func _process(delta: float) -> void:
	if not visible or multimesh == null:
		return
	_time = fposmod(_time + delta, 10000.0)
	_material.set_shader_parameter("time", _time)
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var at := camera.global_position
	var size := float(cfg.get("cell_m", 46.0))
	var cell := Vector2i(floori(at.x / size), floori(at.z / size))
	if cell == _cell:
		return
	_cell = cell
	# The custom AABB is centred on this node, so the node rides the camera's
	# cell and the banks are placed relative to it (never culled as a whole).
	var anchor := Vector3((float(cell.x) + 0.5) * size, at.y, (float(cell.y) + 0.5) * size)
	global_position = anchor
	var placed := placements(cell, cfg)
	var sink := float(cfg.get("foot_sink_m", 1.5))
	for i in placed.size():
		var p: Dictionary = placed[i]
		var h := float(p.height)
		var ground := at.y - 2.0
		if _world != null and _world.has_method("ground_height_at"):
			ground = float(_world.call("ground_height_at", float(p.x), float(p.z)))
		var basis := Basis.from_scale(Vector3(float(p.width), h, 1.0))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(float(p.x), ground - sink + h * 0.5, float(p.z)) - anchor))
		multimesh.set_instance_custom_data(i, Color(float(p.seed), float(p.alpha), 0.0, 0.0))


## Deterministic bank layout for the cells around `centre` (pure; tested).
## Each cell holds at most one bank; `chance` of cells carry one.
static func placements(centre: Vector2i, config: Dictionary) -> Array[Dictionary]:
	var ring := int(config.get("ring", 5))
	var size := float(config.get("cell_m", 46.0))
	var chance := float(config.get("chance", 0.6))
	var widths: Array = config.get("width_m", [60.0, 110.0])
	var heights: Array = config.get("height_m", [7.0, 15.0])
	var out: Array[Dictionary] = []
	for dz in range(-ring, ring + 1):
		for dx in range(-ring, ring + 1):
			var c := centre + Vector2i(dx, dz)
			var on := _hash(c, 11) < chance
			out.append({
				"x": (float(c.x) + 0.1 + 0.8 * _hash(c, 12)) * size,
				"z": (float(c.y) + 0.1 + 0.8 * _hash(c, 13)) * size,
				"width": lerpf(float(widths[0]), float(widths[1]), _hash(c, 14)),
				"height": lerpf(float(heights[0]), float(heights[1]), _hash(c, 15)),
				"seed": _hash(c, 16),
				"alpha": (0.6 + 0.4 * _hash(c, 17)) if on else 0.0,
			})
	return out


static func _hash(cell: Vector2i, salt: int) -> float:
	var h := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)
