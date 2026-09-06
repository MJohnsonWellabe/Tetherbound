extends Node3D

## OP-0905-22 (docs/owner/OWNER_PLAYTEST_2026-09-05.md): "when you fall off the
## world you just fall forever" -- Cloudreach Cliffs. A small, reusable below-
## the-world failsafe: a kill-plane Area3D sized to authored XZ bounds, plus
## tracking of the last position a body was genuinely, stably standing on real
## ground, so a trigger can be corrected locally instead of resetting to some
## remote checkpoint.
##
## Deliberately standalone rather than a refactor of `world_perimeter.gd`,
## which already builds an equivalent kill volume for the Meadows corridor
## (`_build_kill_volume`/`_on_kill_volume_entered`, ~1529-1621). That file's
## version is entangled with corridor-only constants (WORLD_X_WEST/EAST/
## WORLD_Z_NORTH/SOUTH), a `LAST_SAFE_MAX_AGE_S` fix carrying its own multi-
## paragraph regression history (a stale reading from an unrelated earlier
## check cascading into a second bad teleport), and a `_spawn` fallback wired
## through the rest of that 1600-line file's own state. Pulling the mechanism
## out into something both files share would touch all of that for a same-
## week bug fix; CLAUDE.md's "smallest coherent change" says duplicate the
## small, well-understood half instead. `world_perimeter.gd` is untouched.
##
## This node knows nothing about riding, followers, camps or the finale
## hazard current -- it only detects a fall and hands off to whichever
## Callable its owner supplied, so each caller can recover exactly the way
## that world already knows how to (see `cloudreach_world_runtime.gd` for the
## Cloudreach caller).

signal recovered(body: CharacterBody3D, used_last_safe: bool)

const KILL_PLANE_THICKNESS := 40.0
const LAST_SAFE_MAX_AGE_S := 3.0

## Sentinel handed to the recovery callback when there is no fresh last-safe
## reading to correct to locally.
const NO_LAST_SAFE := Vector3.INF

var _player_getter: Callable
var _kill_plane_y: float = -100000.0
var _min_x: float = 0.0
var _max_x: float = 0.0
var _min_z: float = 0.0
var _max_z: float = 0.0

## recovery_callback.call(body, last_safe_or_NO_LAST_SAFE). If left unset, a
## bare teleport to the last-safe position (or `fallback_position` if none is
## fresh) is used instead -- the same shape `world_perimeter.gd` falls back
## to `_spawn` with.
var _recovery_callback: Callable
var _fallback_position: Vector3 = Vector3.ZERO

## Lets an owner park this failsafe without tearing it down -- e.g. a scene
## that wants its own recovery to have first refusal over some volume this
## kill plane also covers. Unused by the Cloudreach mount today; kept because
## a silent double-teleport is exactly the class of bug this file exists to
## prevent, so the escape hatch belongs here rather than being invented again
## at the next call site that needs it.
var _suspended := false

var _last_safe_position: Vector3 = Vector3.ZERO
var _has_last_safe_position: bool = false
var _last_safe_age_s: float = 0.0


## bounds: Dictionary with min_x/max_x/min_z/max_z (metres, world space).
## margin pads those outward before the kill volume is built, the same way
## `world_perimeter.gd::KILL_PLANE_MARGIN` gives its own corridor kill volume
## room past the authored edge.
func setup(player_getter: Callable, kill_plane_y: float, bounds: Dictionary,
		recovery_callback: Callable = Callable(), fallback_position: Vector3 = Vector3.ZERO,
		margin: float = 100.0) -> void:
	_player_getter = player_getter
	_kill_plane_y = kill_plane_y
	_min_x = float(bounds.get("min_x", -1000.0)) - margin
	_max_x = float(bounds.get("max_x", 1000.0)) + margin
	_min_z = float(bounds.get("min_z", -1000.0)) - margin
	_max_z = float(bounds.get("max_z", 1000.0)) + margin
	_recovery_callback = recovery_callback
	_fallback_position = fallback_position
	_build_kill_volume()


func set_suspended(value: bool) -> void:
	_suspended = value


func _current_player() -> CharacterBody3D:
	if not _player_getter.is_valid():
		return null
	return _player_getter.call() as CharacterBody3D


## Same "trust on_floor, refresh every physics frame" tracking
## `world_perimeter.gd::_process` uses, so a trigger a moment later can
## recover to a position that was actually real ground, not a stale one from
## long before (see `LAST_SAFE_MAX_AGE_S`).
func _process(delta: float) -> void:
	var body := _current_player()
	if body == null or not is_instance_valid(body):
		return
	if body.is_on_floor() and body.global_position.y > _kill_plane_y + 10.0:
		_last_safe_position = body.global_position
		_has_last_safe_position = true
		_last_safe_age_s = 0.0
	elif _has_last_safe_position:
		_last_safe_age_s += delta


func _build_kill_volume() -> void:
	var area := Area3D.new()
	area.name = "FallRecoveryKillVolume"
	var centre_x := (_min_x + _max_x) * 0.5
	var centre_z := (_min_z + _max_z) * 0.5
	area.position = Vector3(centre_x, _kill_plane_y, centre_z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(_max_x - _min_x, KILL_PLANE_THICKNESS, _max_z - _min_z)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_kill_volume_entered)
	add_child(area)


func _on_kill_volume_entered(body: Node3D) -> void:
	if _suspended:
		return
	var player := _current_player()
	if body != player or player == null:
		return
	var use_last_safe := _has_last_safe_position and _last_safe_age_s <= LAST_SAFE_MAX_AGE_S
	var last_safe := _last_safe_position if use_last_safe else NO_LAST_SAFE
	if _recovery_callback.is_valid():
		_recovery_callback.call(player, last_safe)
	else:
		player.global_position = last_safe if use_last_safe else _fallback_position
		player.velocity = Vector3.ZERO
	recovered.emit(player, use_last_safe)
