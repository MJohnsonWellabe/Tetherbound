extends Node3D

## P2-060 catch presentation (shipping OFF in data/config/catch_kit.json).
## One short-lived node per catch beat, played alongside the existing flash:
##   strike   -> a soft, edge-lit tether-hue ring around the hanging orb (no
##               filled disc) and capture motes drawn from the creature into it;
##   caught   -> a clear success burst: gold core, rising sparkles, violet ring;
##   breakout -> a sharper burst: pale crystal shards flung out, white flash.
## Presentation only: it reads positions and never touches catch timing,
## chance, verdict or any catching.json value.
const PARTICLES := preload("res://scripts/vfx/kit_particles.gd")
const GLOW_SHADER := preload("res://assets/vfx/shaders/kit_glow.gdshader")
const STREAK_SHADER := preload("res://assets/vfx/shaders/kit_streak.gdshader")
const ORB_SHADER := preload("res://assets/vfx/shaders/kit_orb.gdshader")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const CONFIG_PATH := "res://data/config/catch_kit.json"

static var _config: Dictionary = {}

var _key := ""
var _at := Vector3.ZERO
var _source: Node3D = null
var _cfg: Dictionary = {}
var _glow: Node = null
var _streaks: Node = null
var _shards: Node = null
var _age := 0.0
var _life := 1.0
var _carry := {}
var _rng := RandomNumberGenerator.new()

static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if raw is Dictionary: _config = raw
	return _config

static func enabled() -> bool:
	return bool(config().get("enabled", false))

## The orb's lit, rim-lit, swirling body (keeps the palette's gold family).
static func orb_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ORB_SHADER
	return material

static func play(host: Node, key: String, at: Vector3, source: Node3D = null) -> Node3D:
	if host == null or not enabled() or key not in ["strike", "caught", "breakout"]: return null
	var node := (load("res://scripts/vfx/catch_kit.gd") as Script).new() as Node3D
	node.set("_key", key)
	node.set("_at", at)
	node.set("_source", source)
	host.add_child(node)
	return node

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_cfg = config()
	_rng.seed = hash(_key)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var glow_material := ShaderMaterial.new()
	glow_material.shader = GLOW_SHADER
	_glow = PARTICLES.new()
	_glow.setup(96, quad, glow_material, PARTICLES.Mode.BILLBOARD, _at)
	add_child(_glow)
	var streak_material := ShaderMaterial.new()
	streak_material.shader = STREAK_SHADER
	_streaks = PARTICLES.new()
	_streaks.setup(24, quad, streak_material, PARTICLES.Mode.STREAK, _at)
	add_child(_streaks)
	match _key:
		"strike":
			_life = 0.75
			_ring(float(_cfg.get("ring_radius_m", 0.9)), 0.7)
		"caught":
			_life = 1.1
			_success()
		"breakout":
			_life = 0.9
			_breakout()

func _process(delta: float) -> void:
	var step := minf(delta, 0.1)
	_age += step
	if _key == "strike" and _age < 0.45: _draw_in(step)
	_glow.call("step", step)
	_streaks.call("step", step)
	if _shards != null: _shards.call("step", step)
	if _age >= _life: queue_free()

func _rate(rate: float, step: float, key: String) -> int:
	var carry := float(_carry.get(key, 0.0)) + rate * step
	var n := int(carry)
	_carry[key] = carry - float(n)
	return n

func _camera_basis() -> Basis:
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	return camera.global_basis if camera != null else Basis.IDENTITY

## A soft, edge-lit ring around the orb in the plane facing the viewer: motes
## brightest on the rim and nothing inside it, never a filled disc.
func _ring(radius: float, life: float) -> void:
	var view := _camera_basis()
	var count := int(_cfg.get("ring_motes", 44))
	var colour := Color(str(_cfg.get("ring_colour", "#7a64ff")))
	var core := Color(str(_cfg.get("ring_core", "#d8d0ff")))
	for i in count:
		var a := TAU * float(i) / float(count)
		var dir := view.x * cos(a) + view.y * sin(a)
		var tint := core if i % 3 == 0 else colour
		_glow.call("emit", _at + dir * radius * 0.6, dir * radius * 1.1, {"life": life, "size0": 0.22, "size1": 0.12,
			"colour": tint, "fade_in": 0.05, "drag": 3.5})

## Capture motes spiral in from the creature's whole body into the orb.
func _draw_in(step: float) -> void:
	if _source == null or not is_instance_valid(_source) or not _source.is_inside_tree(): return
	var pivot := _source.call("model_pivot") as Node3D if _source.has_method("model_pivot") else _source
	if pivot == null: return
	var box := pivot.global_transform * RENDER_BOUNDS.measure(pivot)
	if not box.size.is_finite() or box.size.x <= 0.0: return
	var colour := Color(str(_cfg.get("draw_colour", "#a898ff")))
	for k in _rate(float(_cfg.get("draw_motes", 36)) / 0.45, step, "draw"):
		var at := box.position + box.size * Vector3(_rng.randf(), _rng.randf_range(0.15, 0.95), _rng.randf())
		var to := _at - at
		var flight := 0.32
		var swirl := to.cross(Vector3.UP).normalized() * 1.2
		_glow.call("emit", at, to / flight + swirl, {"life": flight, "size0": 0.2, "size1": 0.08,
			"colour": colour, "fade_in": 0.04})

func _success() -> void:
	var gold := Color(str(_cfg.get("success_colour", "#ffd76a")))
	var accent := Color(str(_cfg.get("success_accent", "#b9a8ff")))
	_glow.call("emit", _at, Vector3.ZERO, {"life": 0.35, "size0": 0.5, "size1": 1.1, "colour": Color.WHITE.lerp(gold, 0.3), "fade_in": 0.0})
	_ring(1.0, 0.8)
	for i in 28:
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.2, 1.0), _rng.randf_range(-1, 1)).normalized()
		_glow.call("emit", _at, dir * _rng.randf_range(1.2, 2.6) + Vector3.UP * 0.8, {"life": _rng.randf_range(0.7, 1.05),
			"size0": 0.2, "size1": 0.05, "colour": gold if i % 2 == 0 else accent, "gravity": -0.4, "drag": 1.6, "fade_in": 0.0})
	for i in 10:
		var a := TAU * float(i) / 10.0
		var dir := (_camera_basis().x * cos(a) + _camera_basis().y * sin(a)).normalized()
		_streaks.call("emit", _at, dir * 6.0, {"life": 0.3, "size0": 0.08, "size1": 0.03, "colour": gold, "drag": 4.0, "stretch": 0.07, "fade_in": 0.0})

func _breakout() -> void:
	var pale := Color(str(_cfg.get("breakout_colour", "#e8e4ff")))
	_glow.call("emit", _at, Vector3.ZERO, {"life": 0.25, "size0": 0.7, "size1": 1.3, "colour": Color.WHITE, "fade_in": 0.0})
	var prism := PrismMesh.new()
	prism.size = Vector3(0.35, 1.0, 0.35)
	var shard_material := StandardMaterial3D.new()
	shard_material.albedo_color = pale
	shard_material.emission_enabled = true
	shard_material.emission = pale
	shard_material.emission_energy_multiplier = 0.8
	shard_material.vertex_color_use_as_albedo = true
	_shards = PARTICLES.new()
	_shards.setup(int(_cfg.get("breakout_shards", 12)), prism, shard_material, PARTICLES.Mode.SOLID, _at)
	add_child(_shards)
	for i in int(_cfg.get("breakout_shards", 12)):
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(0.1, 1.0), _rng.randf_range(-1, 1)).normalized()
		_shards.call("emit", _at, dir * _rng.randf_range(3.0, 5.0), {"life": 0.8, "size0": 0.16, "size1": 0.12,
			"colour": Color.WHITE, "gravity": 9.0, "drag": 0.5, "spin": Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * 12.0})
	for i in 14:
		var dir := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.2, 1.0), _rng.randf_range(-1, 1)).normalized()
		_streaks.call("emit", _at, dir * 8.0, {"life": 0.25, "size0": 0.07, "size1": 0.03, "colour": pale, "drag": 5.0, "stretch": 0.06, "fade_in": 0.0})
