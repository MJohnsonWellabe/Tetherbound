extends MultiMeshInstance3D

## storm_sky_1101 light shafts (owner 1 Nov cause lane; judges: "no shafts or
## lightning drama"): a few tall, soft, additive light columns where storm
## light breaks through the canopy. Cheap on the ROG Ally: one MultiMesh of
## Y-billboard quads, no volumetrics, no scene walk. Shafts sit on a fixed
## world grid around the camera, so they stay put as the camera moves; the
## grid is re-seeded only when the camera crosses a cell. Strength follows the
## Surge phase row's `shafts` value. Client presentation only.

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 shaft_colour : source_color = vec3(0.8, 0.78, 0.94);
uniform float strength = 0.0;
uniform float slant = 0.15;
uniform vec2 near_fade_m = vec2(18.0, 40.0);
uniform vec2 far_fade_m = vec2(260.0, 420.0);
uniform float time = 0.0;
varying float v_seed;
varying float v_alpha;
void vertex() {
	v_seed = INSTANCE_CUSTOM.x;
	v_alpha = INSTANCE_CUSTOM.y;
	// Lean the column (top offset) before facing it to the camera about Y.
	VERTEX.x += (VERTEX.y + 0.5) * slant;
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz));
	vec3 fwd = normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0)));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right, 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(fwd, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float u = UV.x;
	float v = UV.y;
	float across = smoothstep(0.0, 0.4, u) * (1.0 - smoothstep(0.6, 1.0, u));
	float streaks = 0.62 + 0.38 * sin(u * 17.0 + v_seed * 31.0) * sin(u * 6.3 + v_seed * 11.0);
	float down = smoothstep(0.0, 0.18, v) * (1.0 - smoothstep(0.82, 1.0, v)) * mix(1.0, 0.45, v);
	float dist = length(VERTEX);
	float fade = smoothstep(near_fade_m.x, near_fade_m.y, dist) * (1.0 - smoothstep(far_fade_m.x, far_fade_m.y, dist));
	float breathe = 0.85 + 0.15 * sin(time * 0.35 + v_seed * 6.2831);
	ALBEDO = shaft_colour;
	ALPHA = clamp(strength * v_alpha * across * streaks * down * fade * breathe, 0.0, 1.0);
}
"""

var cfg: Dictionary = {}
var _material: ShaderMaterial
var _cell := Vector2i(2147483647, 2147483647)
var _time := 0.0
var _strength := 0.0


func setup(config: Dictionary) -> void:
	cfg = config
	name = "StormShafts"
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("shaft_colour", Color(str(cfg.get("colour", "#cdc6ee"))))
	_material.set_shader_parameter("slant", float(cfg.get("slant", 0.15)))
	for key: String in ["near_fade_m", "far_fade_m"]:
		var pair: Array = cfg.get(key, [])
		if pair.size() == 2:
			_material.set_shader_parameter(key, Vector2(float(pair[0]), float(pair[1])))
	quad.material = _material
	var ring := int(cfg.get("ring", 3))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = (ring * 2 + 1) * (ring * 2 + 1)
	multimesh = mm
	var reach := float(cfg.get("far_fade_m", [260.0, 420.0])[1]) + 200.0
	custom_aabb = AABB(Vector3(-reach, -200.0, -reach), Vector3(reach * 2.0, 600.0, reach * 2.0))
	visible = false


## Phase strength (the Surge row's `shafts`, cross-faded with the rest).
func set_strength(value: float) -> void:
	_strength = maxf(0.0, value) * float(cfg.get("intensity", 0.14))
	if _material != null:
		_material.set_shader_parameter("strength", _strength)
	visible = _strength > 0.0005


func _process(delta: float) -> void:
	if not visible or multimesh == null:
		return
	_time = fposmod(_time + delta, 10000.0)
	_material.set_shader_parameter("time", _time)
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var at := camera.global_position
	var size := float(cfg.get("cell_m", 70.0))
	var cell := Vector2i(floori(at.x / size), floori(at.z / size))
	if cell == _cell:
		return
	_cell = cell
	var placed := placements(cell, cfg)
	for i in placed.size():
		var p: Dictionary = placed[i]
		var h := float(p.height)
		var basis := Basis.from_scale(Vector3(float(p.width), h, 1.0))
		# Foot buried below the camera's ground so terrain hides the base.
		var origin := Vector3(float(p.x), at.y - float(cfg.get("foot_below_camera_m", 24.0)) + h * 0.5, float(p.z))
		multimesh.set_instance_transform(i, Transform3D(basis, origin))
		multimesh.set_instance_custom_data(i, Color(float(p.seed), float(p.alpha), 0.0, 0.0))


## Deterministic shaft layout for the cells around `centre` (pure; tested).
## Each cell holds at most one shaft; `chance` of cells carry one.
static func placements(centre: Vector2i, config: Dictionary) -> Array[Dictionary]:
	var ring := int(config.get("ring", 3))
	var size := float(config.get("cell_m", 70.0))
	var chance := float(config.get("chance", 0.35))
	var widths: Array = config.get("width_m", [8.0, 18.0])
	var heights: Array = config.get("height_m", [90.0, 140.0])
	var out: Array[Dictionary] = []
	for dz in range(-ring, ring + 1):
		for dx in range(-ring, ring + 1):
			var c := centre + Vector2i(dx, dz)
			var r0 := _hash(c, 1)
			var lit := r0 < chance
			out.append({
				"x": (float(c.x) + 0.15 + 0.7 * _hash(c, 2)) * size,
				"z": (float(c.y) + 0.15 + 0.7 * _hash(c, 3)) * size,
				"width": lerpf(float(widths[0]), float(widths[1]), _hash(c, 4)),
				"height": lerpf(float(heights[0]), float(heights[1]), _hash(c, 5)),
				"seed": _hash(c, 6),
				"alpha": (0.55 + 0.45 * _hash(c, 7)) if lit else 0.0,
			})
	return out


static func _hash(cell: Vector2i, salt: int) -> float:
	var h := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)
