extends Node3D

## P2-063 fight-tell timing cue (presentation only, shipping OFF in
## data/config/tell_timing_cue.json). Two reads the soft feet outline lacks:
##   (a) "landing now": during the wind-up, a soft front of glowing motes runs
##       along the ground from the attacker towards the creature it is aiming
##       at and arrives exactly as the strike lands. It stops at the edge of the
##       target's footprint, so it never washes over the creature.
##   (b) "opening": while the foe is staggered or in the recovery after its
##       swing (the punish window), a rim of soft motes pulses around its whole
##       body, so the HUD text is not the only signal.
## It reads combat state and never writes it: no timings, damage, AI or
## transactions are touched. One instance per engaged foe.
const PARTICLES := preload("res://scripts/vfx/kit_particles.gd")
const GLOW_SHADER := preload("res://assets/vfx/shaders/kit_glow.gdshader")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const CONFIG_PATH := "res://data/config/tell_timing_cue.json"

static var _config: Dictionary = {}

var _manager: Node = null
var _wild: Node3D = null
var _cfg: Dictionary = {}
var _front: Node = null
var _rim: Node = null
var _tell_left := -1.0
var _tell_total := 0.0
var _arrived := false
var _carry := {}
var _rng := RandomNumberGenerator.new()
var _last_intent := -1
var _opening_left := 0.0
var _clock := 0.0

static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if raw is Dictionary: _config = raw
	return _config

static func enabled() -> bool:
	return bool(config().get("enabled", false))

## Idempotent per foe: a second engage of the same body reuses its cue.
static func attach(host: Node, manager: Node, wild: Node3D) -> Node3D:
	if host == null or wild == null or not enabled(): return null
	var existing: Variant = wild.get_meta(&"tell_timing_cue") if wild.has_meta(&"tell_timing_cue") else null
	if existing is Node3D and is_instance_valid(existing) and not (existing as Node).is_queued_for_deletion():
		return existing
	var cue := (load("res://scripts/vfx/tell_timing_cue.gd") as Script).new() as Node3D
	cue.set("_manager", manager)
	cue.set("_wild", wild)
	host.add_child(cue)
	wild.set_meta(&"tell_timing_cue", cue)
	return cue

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_cfg = config()
	_rng.seed = 2063
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_front = _make_pool(int(_cfg.get("front_motes", 40)), quad)
	_rim = _make_pool(int(_cfg.get("rim_motes", 36)), quad)
	if _wild != null and _wild.has_signal("telegraph_started"):
		_wild.connect("telegraph_started", _on_telegraph)

func _make_pool(count: int, mesh: Mesh) -> Node:
	var material := ShaderMaterial.new()
	material.shader = GLOW_SHADER
	material.set_shader_parameter("opacity", 1.0)
	var pool := PARTICLES.new()
	pool.setup(count, mesh, material, PARTICLES.Mode.BILLBOARD, Vector3.ZERO)
	add_child(pool)
	return pool

func _on_telegraph(seconds: float) -> void:
	_tell_total = maxf(0.05, seconds)
	_tell_left = _tell_total
	_arrived = false

func _process(delta: float) -> void:
	if _wild == null or not is_instance_valid(_wild) or not _wild.is_inside_tree() \
			or _manager == null or not is_instance_valid(_manager):
		queue_free()
		return
	_clock += delta
	var step := minf(delta, 0.1)
	_update_front(step)
	_update_rim(step)
	_front.call("step", step)
	_rim.call("step", step)

func _rate(rate: float, step: float, key: String) -> int:
	var carry := float(_carry.get(key, 0.0)) + rate * step
	var n := int(carry)
	_carry[key] = carry - float(n)
	return n

func _jitter(amount: float) -> Vector3:
	return Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * amount

## The creature the foe is swinging at: the manager's active ally body.
func _target() -> Node3D:
	var ally: Variant = _manager.get("_ally_body")
	return ally if ally is Node3D and is_instance_valid(ally) and (ally as Node3D).is_inside_tree() else null

## World-space visual bounds of a creature (its posed model), or a small box.
func _box(body: Node3D) -> AABB:
	var pivot := body.call("model_pivot") as Node3D if body.has_method("model_pivot") else body
	if pivot != null:
		var box := pivot.global_transform * RENDER_BOUNDS.measure(pivot)
		if box.size.is_finite() and box.size.x > 0.0: return box
	return AABB(body.global_position - Vector3(0.5, 0, 0.5), Vector3(1, 1, 1))

## Horizontal reach of a box from its centre along a flat direction.
static func _reach(box: AABB, dir: Vector3) -> float:
	return absf(dir.x) * box.size.x * 0.5 + absf(dir.z) * box.size.z * 0.5

func _update_front(step: float) -> void:
	if _tell_left < 0.0: return
	_tell_left -= step
	var target := _target()
	if target == null: return
	var from := _wild.global_position
	var to := target.global_position
	var flat := Vector3(to.x - from.x, 0, to.z - from.z)
	if flat.length() < 0.2: return
	var dir := flat.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	# Starts just ahead of the attacker, stops at the edge of the target's footprint.
	var wild_box := _box(_wild)
	var target_box := _box(target)
	var wc := wild_box.get_center()
	var tc := target_box.get_center()
	var start := Vector3(wc.x, from.y, wc.z) + dir * _reach(wild_box, dir)
	var stop := Vector3(tc.x, to.y, tc.z) - dir * (_reach(target_box, dir) + float(_cfg.get("stop_clearance_m", 0.35)))
	# Sized to the fighters: a big foe's lane is wide and its motes large enough to read.
	var scale := clampf(maxf(wild_box.size.x, wild_box.size.z) / 2.0, 1.0, 2.0)
	# The lane narrows onto the target, never wider than its own footprint plus a margin.
	var target_width := maxf(target_box.size.x, target_box.size.z) + 0.6
	if (stop - from).dot(dir) < (start - from).dot(dir): stop = start
	var u := clampf(1.0 - _tell_left / _tell_total, 0.0, 1.0)
	# Eases in: slow to leave, quickening into the strike so the arrival lands on the hit.
	var head := start.lerp(stop, u * u * (3.0 - 2.0 * u))
	var colour := Color(str(_cfg.get("front_colour", "#ff66ee")))
	var width := lerpf(float(_cfg.get("front_width_m", 1.1)) * scale, target_width, u)
	var lift := float(_cfg.get("lift_m", 0.18))
	if _tell_left > 0.0:
		for k in _rate(float(_cfg.get("front_rate", 140.0)), step, "front"):
			var across := _rng.randf_range(-1.0, 1.0)
			# A shallow chevron pointing at the target: the centre leads the wings.
			var at := head + side * across * width * 0.5 - dir * absf(across) * width * 0.35
			at.y = from.y + lift
			_front.call("emit", at + _jitter(0.04), dir * 0.6, {"life": 0.22, "size0": float(_cfg.get("front_mote_m", 0.32)) * scale,
				"size1": float(_cfg.get("front_mote_m", 0.32)) * scale * 0.4, "colour": colour.lerp(Color.WHITE, u * 0.5), "fade_in": 0.0})
	elif not _arrived:
		_arrived = true
		# Arrival: a short bright spray on the ground at the footprint edge.
		for k in int(_cfg.get("arrival_motes", 14)):
			var a := TAU * float(k) / float(_cfg.get("arrival_motes", 14))
			var spray := (dir * cos(a) * 0.6 + side * sin(a)).normalized()
			var at := stop
			at.y = from.y + lift
			_front.call("emit", at, spray * 2.4 + Vector3.UP * 0.4, {"life": 0.32, "size0": 0.4, "size1": 0.12,
				"colour": Color.WHITE.lerp(colour, 0.35), "fade_in": 0.0, "drag": 3.0})
		_tell_left = -1.0

func _update_rim(step: float) -> void:
	var intent := int(_wild.call("intent")) if _wild.has_method("intent") else -1
	var staggered := bool(_manager.call("enemy_is_staggered")) if _manager.has_method("enemy_is_staggered") else false
	# The punish window: recovery right after a wind-up, or a stagger.
	if intent == AI.Intent.RECOVER and _last_intent == AI.Intent.TELEGRAPH:
		_opening_left = float(_cfg.get("opening_hold_s", 1.2))
	if intent != AI.Intent.RECOVER and not staggered: _opening_left = minf(_opening_left, 0.0)
	_last_intent = intent
	_opening_left -= step
	if _opening_left <= 0.0 and not staggered: return
	var box := _box(_wild)
	var body_scale := clampf(box.size.length() / 2.5, 1.0, 4.0)
	var centre := box.get_center()
	var pulse := 0.65 + 0.35 * sin(_clock * TAU * float(_cfg.get("rim_pulse_hz", 3.0)))
	var colour := Color(str(_cfg.get("rim_colour", "#70ddff")))
	for k in _rate(float(_cfg.get("rim_rate", 120.0)), step, "rim"):
		# A point on the surface of the body's ellipsoid: a rim around the whole body.
		var d := _jitter(1.0).normalized()
		var at := centre + Vector3(d.x * box.size.x, d.y * box.size.y, d.z * box.size.z) * 0.52
		_rim.call("emit", at, d * 0.35 + Vector3.UP * 0.25, {"life": 0.3, "size0": float(_cfg.get("rim_mote_m", 0.3)) * body_scale * pulse,
			"size1": 0.08, "colour": Color(colour, pulse), "fade_in": 0.0})
