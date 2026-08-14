extends Node

## Aiming and throwing an orb.
##
## Combat is piloted, so the player is driving their pal when they decide to
## throw. Pressing Throw hands camera and control back to the TRAINER for a
## real-time over-the-shoulder aim, and hands them forward again on release.
##
## That swap is the design, not an implementation detail. Your pal is left
## undefended while you aim and the opponent does not stop attacking it, so
## throwing costs you something. Without that cost, throwing is free and the
## right play is to throw constantly between attacks, which is the version of
## catching that answers no question worth asking.
##
## Split out of combat_manager.gd, which already owns the fight. This owns the
## aim: the camera profile, the reticle, the orb, and the stock.

const CATCH := preload("res://scripts/combat/catch_math.gd")
const ORB_SCENE := preload("res://scenes/combat/orb.tscn")

signal aim_entered()
signal aim_exited()
## The orb landed on the target. `offset` is metres off centre of mass.
signal orb_struck(target: Node3D, offset: float)
signal orb_missed()
## A throw was refused, with a reason the HUD can show. "I pressed it and
## nothing happened" is otherwise indistinguishable from a dropped input.
signal throw_refused(reason: String)

enum State { IDLE, AIMING, THROWN }

## How far down the camera's centre ray the aim point sits when the reticle is
## not over the target. Roughly arena width: far enough that the throw reads as
## going where you pointed, near enough that it is not effectively parallel.
const AIM_REACH := 12.0

var state: State = State.IDLE

var _player: Node3D = null
var _target: Node3D = null
var _camera_rig: Node = null
var _orb: Node3D = null

var _windup: float = 0.0
var _cooldown: float = 0.0
var _guard: float = 0.0

var _speed: float = 17.0
var _gravity: float = 14.0
var _spawn_height: float = 1.5
var _spawn_forward: float = 0.6
var _release_windup: float = 0.18
var _throw_cooldown: float = 0.9


func _ready() -> void:
	var cfg: Dictionary = CATCH.config().get("throw", {})
	_speed = float(cfg.get("speed", _speed))
	_gravity = float(cfg.get("gravity", _gravity))
	_spawn_height = float(cfg.get("spawn_height", _spawn_height))
	_spawn_forward = float(cfg.get("spawn_forward", _spawn_forward))
	_release_windup = float(cfg.get("release_windup", _release_windup))
	_throw_cooldown = float(cfg.get("cooldown", _throw_cooldown))
	set_physics_process(false)


## Called by the combat manager when a fight opens.
func arm(player: Node3D, target: Node3D, camera_rig: Node) -> void:
	_player = player
	_target = target
	_camera_rig = camera_rig
	state = State.IDLE
	_windup = 0.0
	_cooldown = 0.0
	set_physics_process(true)


func disarm() -> void:
	if state == State.AIMING:
		_leave_aim()
	_despawn_orb()
	state = State.IDLE
	set_physics_process(false)
	# Belt-and-braces alongside `_leave_aim()`'s own call below: `disarm()` is
	# the combat manager's general "stop whatever the throw was doing" path
	# and can fire while `state` is THROWN (orb already in flight, catch
	# still resolving) as well as AIMING, so `_leave_aim()` alone would miss
	# restoring the lock in that case.
	_set_trainer_movable(false)


func is_aiming() -> bool:
	return state == State.AIMING


func is_busy() -> bool:
	return state != State.IDLE


## Orbs live in the satchel, not here.
##
## `stock` used to be a plain int seeded from catching.json's
## `orbs.starting_stock` and refilled whenever the practice pal respawned —
## the M3-only placeholder that config block warned about. Grandpa now hands
## the starting orbs over in the opening (`give:orb_basic` in
## data/dialogue/opening.json), every throw spends one from the real
## inventory, and running out means finding or (later, M8) crafting more.
func stock() -> int:
	var inventory := _inventory()
	return int(inventory.call("count", "orb_basic")) if inventory != null else 0


func _spend_orb() -> bool:
	var inventory := _inventory()
	if inventory == null:
		return false
	return bool(inventory.call("remove", "orb_basic", 1))


func _inventory() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; the trainer has no satchel to throw from")
		return null
	return game.get("inventory")


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_guard = maxf(0.0, _guard - delta)

	if state == State.AIMING:
		_tick_aiming(delta)


func _tick_aiming(delta: float) -> void:
	_update_preview()

	# Backing out is free and spends nothing, INCLUDING during the release
	# wind-up — the orb is only spent in _release() itself. The cancel used to
	# be unreachable once the wind-up started (the early return sat above it),
	# which turned a mis-press into a guaranteed spent orb 0.18s later.
	if _guard <= 0.0 and (Input.is_action_just_pressed("combat_run")
			or Input.is_action_just_pressed("menu_cancel")):
		_leave_aim()
		return

	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_release()
		return
	if _guard > 0.0:
		return

	if Input.is_action_just_pressed("combat_throw") or Input.is_action_just_pressed("combat_quick"):
		_windup = _release_windup


## Try to enter aim mode. Returns false with a reason on the signal when the
## throw cannot happen, so the refusal is always explained.
func try_begin_aim(target_can_be_caught: bool, refusal: String) -> bool:
	if state != State.IDLE or _cooldown > 0.0:
		return false
	if stock() <= 0:
		throw_refused.emit("no orbs left")
		return false
	if not target_can_be_caught:
		throw_refused.emit(refusal)
		return false

	state = State.AIMING
	# The button that opens the aim is also the button that releases it, and
	# `is_action_just_pressed` stays true for the whole frame. Same guard as the
	# one that stops engaging a fight from being read as the first attack of it.
	_guard = 0.15
	_windup = 0.0
	_apply_aim_camera()
	# Owner playtest report, second round: "when you go to throw should fully
	# control the character again so you can move him and throw." This file's
	# own header already documented the INTENT ("hands camera and control
	# back to the TRAINER") but only the camera swap was ever wired up --
	# encounter_director.gd disables the trainer's locomotion for the whole
	# fight (D07: "the trainer stands where they engaged"), and nothing here
	# ever turned it back on for the one window D07 did not anticipate: a
	# real-time aim explicitly meant to be a repositionable over-the-shoulder
	# shot, not a static reticle. This is a deliberate, owner-directed
	# amendment to D07's stationary-trainer sub-rule, scoped to exactly the
	# aim/throw window -- general combat still holds the trainer still.
	_set_trainer_movable(true)
	aim_entered.emit()
	return true


func _apply_aim_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, CATCH.config().get("aim", {}))


func _set_trainer_movable(movable: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", movable)


func _leave_aim() -> void:
	state = State.IDLE
	_windup = 0.0
	_hide_preview()
	_set_trainer_movable(false)
	aim_exited.emit()


## --- the arc ---------------------------------------------------------------

const PREVIEW := preload("res://scripts/combat/throw_preview.gd")
var _preview: Node3D = null


## Redraw the predicted arc from EXACTLY the numbers _release() would use this
## frame — same origin, same _aim_direction, same speed. One code path, so the
## promise on screen and the flight of the orb cannot drift apart.
func _update_preview() -> void:
	if _player == null:
		return
	if _preview == null or not is_instance_valid(_preview):
		_preview = PREVIEW.new()
		_preview.name = "ThrowPreview"
		_player.get_parent().add_child(_preview)
	var camera := _aim_camera()
	var origin := _player.global_position + Vector3.UP * _spawn_height
	var forward := _aim_direction(camera, origin)
	origin += forward * _spawn_forward
	_preview.call("update_arc", origin, forward, _speed, _target)
	_slow_the_stick_near_the_target(camera)


## Fine aim: while the camera's centre line passes near the creature, the look
## stick slows further (`aim.near_target_scale`), so the last few degrees of
## the line-up do not overshoot. Cleared with full speed the moment the
## reticle leaves the creature's neighbourhood, and reset wholesale by every
## set_target when the aim ends.
func _slow_the_stick_near_the_target(camera: Camera3D) -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_look_scale") or camera == null:
		return
	var scale_value := 1.0
	if _target != null and is_instance_valid(_target) and _target.has_method("centre"):
		var eye := camera.global_position
		var forward := -camera.global_transform.basis.z
		var centre: Vector3 = _target.call("centre")
		var along := (centre - eye).dot(forward)
		if along > 0.0:
			var body := 1.0
			if _target.has_method("body_radius"):
				body = float(_target.call("body_radius")) * 2.0
			var off_line := (eye + forward * along).distance_to(centre)
			if off_line <= body:
				scale_value = float(CATCH.config().get("aim", {}).get("near_target_scale", 0.6))
	_camera_rig.call("set_look_scale", scale_value)


func _hide_preview() -> void:
	if _preview != null and is_instance_valid(_preview):
		_preview.call("hide_arc")


## Throw at whatever the reticle is over.
##
## NOT parallel to the camera. The aim camera sits about a metre and a half off
## to one side so the trainer's body does not cover the crosshair, and an orb
## thrown along the camera's forward from the trainer's hand travels a line
## that is offset by exactly that much — it lands a body's width to the side of
## everything the player aimed at, consistently, and reads as the game ignoring
## the input.
##
## So the aim is a point: where the camera's centre ray reaches, and then a
## direction from the hand to that point. The reticle is a promise, and this is
## what keeps it.
func _release() -> void:
	if not _spend_orb():
		_leave_aim()
		return
	state = State.THROWN
	# The preview is a promise about a throw that has now been made. Left
	# undrawn-but-visible, its last frame — the arc line and the landing disc —
	# hung frozen in the world through the flight and the whole catch
	# resolution, which a captured frame showed plainly.
	_hide_preview()

	var camera := _aim_camera()
	var origin := _player.global_position + Vector3.UP * _spawn_height
	var forward := _aim_direction(camera, origin)
	origin += forward * _spawn_forward

	_despawn_orb()
	_orb = ORB_SCENE.instantiate()
	_player.get_parent().add_child(_orb)
	_orb.connect("struck", _on_struck)
	_orb.connect("missed", _on_missed)
	_orb.call("launch", origin, forward, _speed, _target)
	# The trainer throws rather than standing there. Their model is on a child
	# node, so this reaches past the body to the thing that animates.
	var body: Node = _player.get_node_or_null(^"Model")
	if body != null and body.has_method("play_throw"):
		body.call("play_throw")

	aim_exited.emit()


## Where the reticle is pointing, converted into a direction from the hand.
##
## The aim point is taken along the camera's centre ray. It prefers the actual
## target when the reticle is near it, so a throw lined up on the creature is
## thrown at the creature rather than at a spot behind it — the alternative is a
## fixed reach that is wrong at every distance except one.
func _aim_direction(camera: Camera3D, origin: Vector3) -> Vector3:
	if camera == null:
		return -_player.global_transform.basis.z

	var eye := camera.global_position
	var forward := -camera.global_transform.basis.z
	var aim_point := eye + forward * AIM_REACH

	if _target != null and is_instance_valid(_target) and _target.has_method("centre"):
		var centre: Vector3 = _target.call("centre")
		var along := (centre - eye).dot(forward)
		if along > 0.0:
			# How far the target sits from the camera's centre line. The pull
			# toward the creature is piecewise: a guaranteed full lock while
			# the ray is within half a body-width (a reticle ON the creature
			# means the creature — smoke_catching's whole aim strategy leans on
			# this, and so does a player's), then a smoothstep falloff out to a
			# full body-width. The old assist was binary over the whole width,
			# which made the aim jump discontinuously as the reticle swept
			# past — the "grabbed the stick" feel from the playtest.
			var nearest := eye + forward * along
			var body := 1.0
			if _target.has_method("body_radius"):
				body = float(_target.call("body_radius")) * 2.0
			var pull := 1.0 - smoothstep(body * 0.5, body, nearest.distance_to(centre))
			aim_point = aim_point.lerp(centre, pull)

	# BALLISTIC, not a straight line. This is the fix for the throw mechanic's
	# deepest problem, found by instrumenting the smoke test: the aim used to
	# return the straight direction at the aim point, and the orb flies a
	# parabola — at speed 17 under gravity 14 it drops 2.4m over an 11m throw
	# and 4m over 14m, so every locked-on throw beyond ~9m sailed under its
	# target. The snap window hid it at close range and nothing hid it past
	# that; "the orb went wide" was almost always "the orb fell short". The
	# reticle is a promise, so the launch direction is now the solved arc that
	# LANDS on the aim point. Out of ballistic range (~20m flat at current
	# numbers) falls back to the straight line, which visibly falls short —
	# with the arc preview drawing exactly that truth.
	return _ballistic_direction(origin, aim_point, forward)


## The low-arc launch direction that lands a projectile of `_speed` under
## `_gravity` on `point`. Falls back to the straight line when the point is
## unreachable at this speed.
func _ballistic_direction(origin: Vector3, point: Vector3, fallback: Vector3) -> Vector3:
	var flat := Vector2(point.x - origin.x, point.z - origin.z)
	var reach := flat.length()
	if reach < 0.01:
		return fallback
	var rise := point.y - origin.y
	var s2 := _speed * _speed
	var disc := s2 * s2 - _gravity * (_gravity * reach * reach + 2.0 * rise * s2)
	var horizontal := Vector3(flat.x, 0.0, flat.y) / reach
	if disc < 0.0:
		var direct := point - origin
		return direct.normalized() if direct.length() > 0.01 else fallback
	# The smaller root is the low, fast arc; the high lob spends its flight
	# time hanging in the air over a moving creature.
	var pitch_tan := (s2 - sqrt(disc)) / (_gravity * reach)
	return (horizontal + Vector3.UP * pitch_tan).normalized()


func _aim_camera() -> Camera3D:
	if _camera_rig == null:
		return null
	return _camera_rig.get_node_or_null(^"Camera3D") as Camera3D


func _on_struck(target: Node3D, offset: float) -> void:
	state = State.IDLE
	_cooldown = _throw_cooldown
	orb_struck.emit(target, offset)


func _on_missed() -> void:
	state = State.IDLE
	_cooldown = _throw_cooldown
	_despawn_orb()
	orb_missed.emit()


func _despawn_orb() -> void:
	if _orb != null and is_instance_valid(_orb):
		_orb.queue_free()
	_orb = null


## The orb that is currently resting on the ground after a strike, so the catch
## resolution can wobble it. Null at every other time.
func resting_orb() -> Node3D:
	return _orb if _orb != null and is_instance_valid(_orb) else null


func clear_orb() -> void:
	_despawn_orb()
