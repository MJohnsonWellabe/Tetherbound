extends Node3D

## One host-owned fan/field cast. Keeps the original geometry and finite
## lifetime across the body's recovery/reposition. Resolver rechecks actual
## target positions and accepted actor identity at contact. No local reward.
const PROJECTILE := preload("res://scripts/combat/move_projectile.gd")
const CUE := preload("res://scripts/combat/enemy_pattern_telegraph.gd")
var _owner: Node
var _profile: Dictionary
var _geometry: Dictionary
var _resolve: Callable
var _left := 0.0
var _flight_left := 0.0
var _field := false
var _finished := false
var _connected := false
var _cue: Node3D


static func begin(owner: Node, profile: Dictionary, geometry: Dictionary,
		move: Dictionary, resolve: Callable, cfg: Dictionary) -> Node3D:
	if not is_instance_valid(owner) or not resolve.is_valid():
		return null
	var cast := new()
	cast.name = "EnemyPatternCast"
	cast.set_meta(&"enemy_pattern_cast", true)
	cast._owner = owner
	cast._profile = profile.duplicate(true)
	cast._geometry = geometry.duplicate(true)
	cast._resolve = resolve
	cast._field = str(profile.get("telegraph_shape", "")) == "field"
	cast._left = float(profile.get("field_duration_s", 0.0)) if cast._field else float(cfg.get("casts", {}).get("fan_travel_s", 0.3))
	cast._flight_left = 0.0 if cast._field else cast._left
	owner.add_child(cast)
	if cast._field:
		var body: Node3D = geometry.get("body") as Node3D
		if body == null or not is_instance_valid(body):
			cast.queue_free()
			return null
		cast._cue = CUE.begin(body, profile, geometry.origin, geometry.heading,
			geometry.marker, cfg.get("presentation", {}), Color(str(cfg.get("colour", "#ff40e6"))))
	else:
		var count := maxi(1, int(profile.get("projectile_count", 1)))
		var separation := deg_to_rad(float(profile.get("projectile_spacing_degrees", 20.0)))
		var origin: Vector3 = geometry.origin
		var heading: Vector3 = geometry.heading
		for index: int in count:
			var angle := (float(index) - float(count - 1) * 0.5) * separation
			var end := origin + heading.rotated(Vector3.UP, angle) * float(profile.get("range", 8.0))
			var visual: Dictionary = move.get("vfx", {}).duplicate(true)
			visual["kind"] = "projectile"
			visual["speed"] = float(profile.get("range", 8.0)) / maxf(0.001, cast._flight_left)
			PROJECTILE.launch(cast, origin, end, visual)
	return cast


func _physics_process(delta: float) -> void:
	if _finished or not is_instance_valid(_owner) or not _resolve.is_valid():
		queue_free()
		return
	_left -= delta
	_flight_left = maxf(0.0, _flight_left - delta)
	if _flight_left > 0.0:
		return
	# Resolver returns true only for an accepted actual contact. The existing
	# manager's "handled" boolean also includes misses and cannot be used here.
	# After one accepted hit the field stays visible for its authored lifetime.
	if not _connected:
		var result: Variant = _resolve.call(_profile.duplicate(true), _geometry.duplicate(true))
		_connected = result is bool and result == true
	if not _field or _left <= 0.0:
		_finished = true
	if _finished:
		queue_free()


func _exit_tree() -> void:
	if is_instance_valid(_cue):
		_cue.queue_free()
