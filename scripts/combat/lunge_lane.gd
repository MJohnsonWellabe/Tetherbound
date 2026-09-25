extends Node3D

## F04: the path telegraph for a named CHARGER's travelling lunge.
##
## BOSSES §2 gives CHARGER "lunge 7 m ... distance is part of the cue". The
## ring at the feet (`telegraph_glow.gd`) says *when*; this says *where and how
## far*: a lane on the ground from the charger's nose, exactly as long as the
## configured lunge and as wide as the contact rule, so a player can see the
## line to step off before the body runs down it.
##
## Owned by `wild_creature.gd`, which aims it every frame the heading still
## tracks, locks it when the heading locks (the fill firms up: "committed"),
## and releases it when the charge starts (it lingers under the running body,
## then fades). Top-level so a body running down it does not drag it along.
##
## Same drawing rules `telegraph_glow.gd` already paid for: mesh-based,
## unshaded, MIX blend, depth-tested and lifted a hair off the ground so a body
## standing on the near end still occludes it the right way, vertices seated
## on the real ground height so it lies on slopes instead of cutting through.

const GROUND_LIFT := 0.09
## Lane is sampled every STEP metres along its length so it follows terrain.
const STEP := 0.5
const CHEVRONS := 3
const CHEVRON_PERIOD := 0.6
## A body standing on a built deck far above the terrain query is not a
## rendering offset to copy along the lane; cap what is carried.
const MAX_SURFACE_BIAS := 0.6

var _body: Node3D = null
var _origin := Vector3.ZERO
var _heading := Vector3.FORWARD
var _start := 0.0
var _length := 7.0
var _half_width := 1.0
var _colour := Color("#ff40e6")
var _fill_alpha := 0.22
var _locked_fill_alpha := 0.42
var _edge_alpha := 0.9
var _edge_width := 0.14
var _end_depth := 0.35
var _fade := 0.35
var _depth_pull := 0.45

var _locked := false
var _released := false
var _fade_left := 0.0
var _life := 0.0
var _mesh: ImmediateMesh = null
var _instance: MeshInstance3D = null
## Ground heights for the fixed lane samples, keyed by (along, across). Cleared
## whenever the lane is re-aimed, so a locked lane queries the ground once
## rather than every frame.
var _heights := {}
## How far the surface the body actually stands on sits above the ground
## source's answer at its feet. The relay capture (F04 charger-lunge) showed
## the lane vanishing on ground where the rendered floor sits above the height
## query: a mark seated on the query was drawn under the visible floor and
## lost the depth test. The body's own feet are the one height known to be on
## the visible, walked surface, so the lane keeps that offset along its length.
var _surface_bias := 0.0


## `start` is where the visible lane begins, measured from the body's centre
## along the heading (its nose); the lane runs `length` metres beyond it.
static func begin(body: Node3D, start: float, length: float, half_width: float,
		cfg: Dictionary) -> Node3D:
	var lane := new()
	lane.name = "LungeLane"
	lane._body = body
	lane._start = maxf(0.0, start)
	lane._length = maxf(0.1, length)
	lane._half_width = maxf(0.1, half_width)
	lane._colour = Color(str(cfg.get("lane_colour", "#ff40e6")))
	lane._fill_alpha = float(cfg.get("lane_fill_alpha", lane._fill_alpha))
	lane._locked_fill_alpha = float(cfg.get("lane_locked_fill_alpha", lane._locked_fill_alpha))
	lane._edge_alpha = float(cfg.get("lane_edge_alpha", lane._edge_alpha))
	lane._edge_width = float(cfg.get("lane_edge_width", lane._edge_width))
	lane._end_depth = float(cfg.get("lane_end_depth", lane._end_depth))
	lane._fade = maxf(0.01, float(cfg.get("lane_fade", lane._fade)))
	lane._depth_pull = maxf(0.0, float(cfg.get("lane_depth_pull", lane._depth_pull)))
	lane.top_level = true
	body.add_child(lane)
	return lane


func _ready() -> void:
	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.material_override = _material()
	_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_instance)
	_refresh_aabb()


## Pulled toward the camera in view space by `depth_pull` metres, the same
## ground-telegraph technique `stormwood_lightning.gd` uses. The first relay
## capture drew the lane (and the feet ring) as scattered fragments: the
## rendered terrain between height samples sits a few centimetres above the
## sampled heights, so a depth-tested mark lifted a hair off those samples lost
## to the ground in patches and read as litter. The pull wins against the
## ground while a creature body standing in front of the lane (more than the
## pull nearer the camera) still occludes it -- which is why this is not
## `no_depth_test`, the defect `telegraph_glow.gd` records (a mark painted
## through the ally's back).
const LANE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled, depth_draw_never;
uniform float depth_pull = 0.45;
varying vec4 tint;
void vertex() {
	tint = COLOR;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float dist = length(view.xyz);
	view.xyz *= max(0.2, 1.0 - depth_pull / max(dist, 0.001));
	POSITION = PROJECTION_MATRIX * view;
}
void fragment() {
	ALBEDO = tint.rgb;
	ALPHA = tint.a;
}
"""


func _material() -> Material:
	var shader := Shader.new()
	shader.code = LANE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("depth_pull", _depth_pull)
	return material


## Point the lane from `origin` (the body's feet) along `heading`.
func aim(origin: Vector3, heading: Vector3) -> void:
	var flat := Vector3(heading.x, 0.0, heading.z)
	if flat.length_squared() < 0.0001:
		return
	var heading_now := flat.normalized()
	if not origin.is_equal_approx(_origin) or not heading_now.is_equal_approx(_heading):
		_heights.clear()
		_surface_bias = 0.0
		if is_instance_valid(_body) and _body.has_method("_ground_height"):
			var under := float(_body.call("_ground_height", origin.x, origin.z))
			if is_finite(under):
				_surface_bias = clampf(origin.y - under, 0.0, MAX_SURFACE_BIAS)
	_origin = origin
	_heading = heading_now
	if is_inside_tree():
		global_position = origin
	else:
		position = origin
	_draw()


func lock() -> void:
	_locked = true


func is_locked() -> bool:
	return _locked


## The charge has started: the lane stays where it was drawn while the body
## runs down it, then fades away.
func release() -> void:
	if _released:
		return
	_released = true
	_fade_left = _fade


func lane_length() -> float:
	return _length


func lane_half_width() -> float:
	return _half_width


func _physics_process(delta: float) -> void:
	_life += delta
	if _released:
		_fade_left -= delta
		if _fade_left <= 0.0:
			queue_free()
			return
	_draw()


func _refresh_aabb() -> void:
	if _instance == null:
		return
	var reach := _start + _length + _half_width + 1.0
	_instance.custom_aabb = AABB(Vector3(-reach, -4.0, -reach), Vector3(reach * 2.0, 8.0, reach * 2.0))


## World offset from the lane origin for a point `along` the heading and
## `across` to its right, seated on the ground.
func _point(along: float, across: float, cache: bool = true) -> Vector3:
	var right := _heading.cross(Vector3.UP).normalized()
	var offset := _heading * along + right * across
	offset.y = GROUND_LIFT
	var key := Vector2(along, across)
	if cache and _heights.has(key):
		offset.y = float(_heights[key])
		return offset
	if is_instance_valid(_body) and _body.has_method("_ground_height"):
		var height := float(_body.call("_ground_height", _origin.x + offset.x, _origin.z + offset.z))
		if is_finite(height):
			offset.y = height + _surface_bias + GROUND_LIFT - _origin.y
	if cache:
		_heights[key] = offset.y
	return offset


func _quad(a0: float, a1: float, c0: float, c1: float, colour: Color) -> void:
	var p00 := _point(a0, c0)
	var p01 := _point(a0, c1)
	var p10 := _point(a1, c0)
	var p11 := _point(a1, c1)
	for p: Vector3 in [p00, p10, p11, p00, p11, p01]:
		_mesh.surface_set_color(colour)
		_mesh.surface_add_vertex(p)


func _strip(c0: float, c1: float, colour: Color) -> void:
	var from := _start
	var to := _start + _length
	var along := from
	while along < to - 0.001:
		var next := minf(to, along + STEP)
		_quad(along, next, c0, c1, colour)
		along = next


func _draw() -> void:
	if _mesh == null:
		return
	_mesh.clear_surfaces()
	var fade := 1.0
	if _released:
		fade = clampf(_fade_left / _fade, 0.0, 1.0)
	var fill := _locked_fill_alpha if _locked else _fill_alpha
	var base := Color(_colour.r, _colour.g, _colour.b, 1.0)
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# Body of the lane.
	_strip(-_half_width, _half_width, Color(base, fill * fade))
	# Edges: the lane's width, which is the contact rule's width.
	var edge := Color(base, _edge_alpha * fade)
	_strip(-_half_width, -_half_width + _edge_width, edge)
	_strip(_half_width - _edge_width, _half_width, edge)
	# End bar: exactly where the charge stops if nothing is in the way.
	var end := _start + _length
	_quad(end - _end_depth, end, -_half_width, _half_width, edge)
	# Chevrons running toward the end give the direction at a glance.
	var arm := _half_width * 0.55
	for i in CHEVRONS:
		var phase := fmod(_life / CHEVRON_PERIOD + float(i) / float(CHEVRONS), 1.0)
		var tip := _start + 0.6 + phase * maxf(0.1, _length - 1.2)
		var chevron_alpha := _edge_alpha * fade * sin(phase * PI)
		var colour := Color(base, chevron_alpha)
		_chevron(tip, arm, colour)
	_mesh.surface_end()


## A "V" pointing along the heading, tip at `tip`. It moves every frame, so it
## is seated on one uncached ground sample at its tip rather than four.
func _chevron(tip: float, arm: float, colour: Color) -> void:
	var thickness := _edge_width * 1.6
	var lift := _point(tip, 0.0, false).y
	var right := _heading.cross(Vector3.UP).normalized()
	var flat := func(along: float, across: float) -> Vector3:
		var p := _heading * along + right * across
		p.y = lift
		return p
	for side: float in [-1.0, 1.0]:
		var a: Vector3 = flat.call(tip - arm, side * arm)
		var b: Vector3 = flat.call(tip, 0.0)
		var a2: Vector3 = flat.call(tip - arm - thickness, side * arm)
		var b2: Vector3 = flat.call(tip - thickness, 0.0)
		for p: Vector3 in [a, b, b2, a, b2, a2]:
			_mesh.surface_set_color(colour)
			_mesh.surface_add_vertex(p)
