extends Node

## Aiming and throwing an orb.
##
## Combat is piloted, so the player is driving their creature when they decide to
## throw. Pressing Throw hands camera and control back to the TRAINER for a
## real-time over-the-shoulder aim, and hands them forward again on release.
##
## That swap is the design, not an implementation detail. Your creature is left
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
## The orb landed nowhere. Carries the sentence to show the player, because
## "the orb went wide" was printed for every miss regardless of what happened.
signal orb_missed(message: String)
## A throw was refused, with a reason the HUD can show. "I pressed it and
## nothing happened" is otherwise indistinguishable from a dropped input.
signal throw_refused(reason: String)

enum State { IDLE, AIMING, THROWN }

## How far down the camera's centre ray the aim point sits when the reticle is
## not over the target. Roughly arena width: far enough that the throw reads as
## going where you pointed, near enough that it is not effectively parallel.
const AIM_REACH := 12.0

## The soft aim magnet's band, in multiples of the target's body WIDTH (twice
## its radius). Inside `AIM_PULL_INNER` the aim point is fully pulled onto the
## creature; past `AIM_PULL_OUTER` it is not pulled at all; between them it
## smoothsteps. See `_aim_direction()` for the owner directive these came from
## and for why the falloff must stay smooth.
const AIM_PULL_INNER := 1.0
const AIM_PULL_OUTER := 2.5

var state: State = State.IDLE

var _player: Node3D = null
## Bodies a thrown orb passes through instead of stopping on -- BP2's "your own
## creature and trainer intercept your orbs, and the orb is spent". Pushed in by
## `combat_manager.gd` when the fight gets its ally, because this node knows the
## trainer and the target but has no reason to know who is fighting for them.
var _pass_through: Array[Node3D] = []
var _target: Node3D = null
var _camera_rig: Node = null
var _orb: Node3D = null

var _windup: float = 0.0
var _cooldown: float = 0.0
var _guard: float = 0.0
var _thrown_orb_id: String = ""

var _speed: float = 17.0
var _gravity: float = 14.0
var _spawn_height: float = 1.5
var _spawn_forward: float = 0.6
var _release_windup: float = 0.18
var _throw_cooldown: float = 0.9
var _launch_assist_reticle_fraction: float = 1.0
var _launch_assist_max_seconds: float = 0.85
var _launch_assist_max_target_speed: float = 4.5
var _launch_assist_max_distance: float = 2.6


## Pure screen-ray/body geometry, shared with the controller regression. A
## yaw/pitch tolerance cannot prove that a distant reticle is inside a body.
static func reticle_body_geometry(
	eye: Vector3, forward: Vector3, centre: Vector3, radius: float, fraction: float
) -> Dictionary:
	var normal := forward.normalized()
	var along := (centre - eye).dot(normal)
	var offset := (eye + normal * along).distance_to(centre)
	var allowed := maxf(0.0, radius * fraction)
	return {
		"in_front": along > 0.0,
		"reticle_offset": offset,
		"reticle_radius": allowed,
		"inside_body": along > 0.0 and offset <= allowed,
	}


static func first_hit_belongs_to_target(collider: Node, target: Node) -> bool:
	return collider == target or (collider != null and target != null and target.is_ancestor_of(collider))

## A launch-time assist is committed with the button press, not recomputed
## after the wind-up. Otherwise a circling creature can leave the reticle in
## those 0.18 seconds and turn a correctly lined-up controller throw into a
## miss before the orb even leaves the trainer's hand. INF means the reticle
## was not genuinely on the visible target, so the physical wide throw stays
## completely unassisted.
var _committed_assist_point := Vector3.INF
var _released_assist_point := Vector3.INF

## Last `launch_assist_diagnostics()` result, refreshed once per physics tick
## while aiming. Read by `combat_manager.gd::catch_chance_now()` so the number
## the reticle shows is the number the throw would actually resolve at -- see
## that function's header for why it used to be neither.
var _aim_report: Dictionary = {}


## The live aim, for a caller that needs to know where this throw would land
## rather than whether an assist is legal. Empty between aims.
func aim_report() -> Dictionary:
	return _aim_report if state == State.AIMING else {}


func _ready() -> void:
	var cfg: Dictionary = CATCH.config().get("throw", {})
	_speed = float(cfg.get("speed", _speed))
	_gravity = float(cfg.get("gravity", _gravity))
	_spawn_height = float(cfg.get("spawn_height", _spawn_height))
	_spawn_forward = float(cfg.get("spawn_forward", _spawn_forward))
	_release_windup = float(cfg.get("release_windup", _release_windup))
	_throw_cooldown = float(cfg.get("cooldown", _throw_cooldown))
	_launch_assist_reticle_fraction = float(cfg.get(
		"launch_assist_reticle_fraction", _launch_assist_reticle_fraction))
	_launch_assist_max_seconds = float(cfg.get(
		"launch_assist_max_seconds", _launch_assist_max_seconds))
	_launch_assist_max_target_speed = float(cfg.get(
		"launch_assist_max_target_speed", _launch_assist_max_target_speed))
	_launch_assist_max_distance = float(cfg.get(
		"launch_assist_max_distance", _launch_assist_max_distance))
	set_physics_process(false)


## Called by the combat manager when a fight opens.
func arm(player: Node3D, target: Node3D, camera_rig: Node) -> void:
	_player = player
	_target = target
	_camera_rig = camera_rig
	state = State.IDLE
	_windup = 0.0
	_cooldown = 0.0
	_committed_assist_point = Vector3.INF
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
## `orbs.starting_stock` and refilled whenever the practice creature respawned —
## the M3-only placeholder that config block warned about. Grandpa now hands
## the starting orbs over in the opening (`give:orb_basic` in
## data/dialogue/opening.json), every throw spends one from the real
## inventory, and running out means finding or crafting more.
##
## R4.9: more than one tier can now live in the satchel at once, so `stock`
## is the total across every tier `catching.json` names — a player carrying
## only `orb_greater` is not "out of orbs".
func stock() -> int:
	var counts := _orb_counts()
	var total := 0
	for id: String in counts:
		total += int(counts[id])
	return total


## The tier a throw right now would actually use: the strongest one the
## player is carrying. Empty string means no legal throw — `try_begin_aim`'s
## `stock() <= 0` refusal already covers that case before this is ever asked.
func current_orb_id() -> String:
	return CATCH.best_orb(_orb_counts())


func _orb_counts() -> Dictionary:
	var inventory := _inventory()
	var counts := {}
	if inventory == null:
		return counts
	for id: String in CATCH.orb_ids():
		counts[id] = int(inventory.call("count", id))
	return counts


## Spends whichever tier `current_orb_id()` names, and remembers it as
## `_thrown_orb_id` for the resolve step -- the catch odds a throw resolves
## at must match the orb actually spent, not whatever is left in the satchel
## after it (which can already be a weaker tier).
func _spend_orb() -> bool:
	var inventory := _inventory()
	if inventory == null:
		return false
	var id := current_orb_id()
	if id.is_empty():
		return false
	if not bool(inventory.call("remove", id, 1)):
		return false
	_thrown_orb_id = id
	return true


## The tier actually spent by the most recent successful throw. Set once, by
## `_spend_orb()`, and read once, by the resolve step -- never recomputed
## after the spend, which could silently pick a different (weaker) tier than
## the one the orb in flight actually is.
func thrown_orb_id() -> String:
	return _thrown_orb_id


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
	# Refreshed on the PHYSICS tick and cached, not recomputed by the HUD's
	# draw frame: `launch_assist_diagnostics()` casts a ray, and
	# `combat_hud.gd` now reads this every frame it draws the capture reticle.
	# One ray per physics tick is the same cost the throw already pays; one per
	# draw frame is not.
	_aim_report = launch_assist_diagnostics()
	# The arc's own verdict travels with the report, so the HUD can say what the
	# picture says -- see `throw_preview.gd::update_arc()` for the disagreement
	# a render caught between the two.
	var previewing := _preview != null and is_instance_valid(_preview)
	_aim_report["trajectory_hits_target"] = previewing \
		and bool(_preview.get("trajectory_hits_target"))
	_aim_report["trajectory_offset"] = float(_preview.get("trajectory_offset")) \
		if previewing else INF

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

	# CONTROLLER-MAP: interact (X) is the pad's throw button now -- `combat_throw`
	# kept its keyboard F and lost its pad binding when the orb became a hotbar
	# item. `combat_quick` stays because the aim opens on the same press that
	# releases it and a player already holding the attack trigger expects that.
	if Input.is_action_just_pressed("combat_throw") \
			or Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("combat_quick"):
		_commit_launch_assist()
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
	_acquire_target()
	aim_entered.emit()
	return true


## OWNER DIRECTIVE 2026-08-28 §2a.2: "when you go into throwing, it needs to aim
## you onto the creature."
##
## Entering the aim used to leave the camera wherever exploration had left it,
## which on a controller means the player raises the orb and then has to hunt
## for the creature with the right stick before they can even start aiming --
## and the aim camera has just swung to an over-the-shoulder profile with a
## 1.45m shoulder offset, so the view they hunt from is not the view they had.
## The frames from `smoke_catching.gd`'s own fights show the cost: four consecutive
## commits with `reason=reticle_outside_body`, and the run's first throw logged
## the target 7.5m off the screen ray.
##
## So raising the orb ACQUIRES. The rig's yaw and pitch are pointed at the
## target's centre of mass from the eye the aim camera is about to use.
##
## WHICH target: the one the fight is already about. `arm()` is handed exactly
## one `_target` by `combat_manager.gd` when the fight opens, and catching is
## only available inside a fight, so there is no nearest-creature search to get
## wrong and no ambiguity when several creatures are in range -- the encounter
## already chose. That is a deliberately narrower rule than a free-roam lock-on
## would need, and it is the right one here: it can never acquire a creature the
## player is not fighting.
##
## Snapped rather than glided. The camera is already cutting to a different
## profile on this same frame, so a glide would be a second motion on top of a
## cut and would read as drift rather than as acquisition.
func _acquire_target() -> void:
	if _camera_rig == null or _player == null:
		return
	if _target == null or not is_instance_valid(_target) or not _target.has_method("centre"):
		return
	var centre: Vector3 = _target.call("centre")
	var eye := _player.global_position + Vector3.UP * _spawn_height
	var to_target := centre - eye
	if to_target.length_squared() < 0.0001:
		return
	# `camera_rig.gd` measures yaw the same way the player's own facing does:
	# atan2(-x, -z). Taken from `smoke_catching.gd::_aim_camera_along()`, which
	# is the existing caller that already had to know this.
	_camera_rig.set("yaw", atan2(-to_target.x, -to_target.z))
	var flat := Vector2(to_target.x, to_target.z).length()
	if flat > 0.01:
		var cfg: Dictionary = CATCH.config().get("aim", {})
		var pitch := atan2(to_target.y, flat)
		_camera_rig.set("pitch", clampf(
			pitch,
			deg_to_rad(float(cfg.get("pitch_min_deg", -35.0))),
			deg_to_rad(float(cfg.get("pitch_max_deg", 20.0)))
		))
	return


func _apply_aim_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, CATCH.config().get("aim", {}))


func _set_trainer_movable(movable: bool) -> void:
	if _player != null and _player.has_method("set_locomotion_enabled"):
		_player.call("set_locomotion_enabled", movable)


func _leave_aim() -> void:
	_aim_report = {}
	state = State.IDLE
	_windup = 0.0
	_committed_assist_point = Vector3.INF
	_hide_preview()
	_set_trainer_movable(false)
	aim_exited.emit()


## --- the arc ---------------------------------------------------------------

const PREVIEW := preload("res://scripts/combat/throw_preview.gd")
var _preview: Node3D = null


## Redraw the predicted arc from EXACTLY the numbers _release() would use this
## frame — same origin, same _launch_direction, same speed. One code path, so the
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
	_refresh_committed_assist_point(origin)
	var forward := _launch_direction(camera, origin)
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
	# A throw that cannot physically arrive is not a throw, and it must not cost
	# an orb.
	#
	# Found in the Gate B continuous run, 2026-08-23. After a breakout the fight
	# stayed armed while the creature ended up twenty-five metres away, and the
	# game happily took the press every time: reticle ON the body, `eligible`,
	# launch assist applied -- and the orb hit the ground eighteen metres short,
	# because at `speed` 17 under `gravity` 14 the furthest a thrown orb can
	# reach is v²/g, about twenty metres. Nineteen consecutive orbs were spent
	# on throws that were never capable of landing.
	#
	# That is the owner's "I never know if I was close" at its worst: the
	# reticle is a promise this file makes everywhere else, and here the game
	# was showing it over a target the orb could not physically get to.
	#
	# Gated on the committed assist point rather than on the target's distance,
	# so it refuses only when the player is genuinely LOCKED ON to a creature
	# out of reach. Deliberately lobbing an orb at the ground in front of you is
	# still a legal throw.
	if _committed_assist_point != Vector3.INF:
		var hand := _player.global_position + Vector3.UP * _spawn_height
		if not within_ballistic_reach(hand, _committed_assist_point, _speed, _gravity):
			print("catch launch: refused out_of_range distance=%.2f max=%.2f" % [
				hand.distance_to(_committed_assist_point), _speed * _speed / maxf(_gravity, 0.01),
			])
			throw_refused.emit("too far to throw — get closer")
			_leave_aim()
			return
	if not _spend_orb():
		_leave_aim()
		return
	state = State.THROWN
	# The throw is out of your hands, so the trainer stops being one.
	#
	# `_enter_aim()` hands the trainer locomotion and `_leave_aim()` takes it
	# back, but a RELEASED throw goes through neither: it keeps the aim camera
	# on purpose ("watching your own orb arc away is the shot") and sets state
	# directly. So the trainer stayed a live walking actor through the flight
	# AND the whole catch resolution -- and the Gate B run of 2026-08-23 caught
	# what that costs. Trainer at z=-37.5 when the orb left their hand, 3.34m
	# from the Bramblebun; trainer at z=-20.4 by the breakout, seventeen metres
	# away, while the creature had not moved at all. Every subsequent throw was
	# then made from twenty-five metres, out of the orb's physical range.
	#
	# It also breaks the resolution as a shot: the camera is in close on the
	# orb for those seconds and the trainer was jogging out of the county.
	_set_trainer_movable(false)
	# The preview is a promise about a throw that has now been made. Left
	# undrawn-but-visible, its last frame — the arc line and the landing disc —
	# hung frozen in the world through the flight and the whole catch
	# resolution, which a captured frame showed plainly.
	_hide_preview()

	var camera := _aim_camera()
	var origin := _player.global_position + Vector3.UP * _spawn_height
	var forward := _launch_direction(camera, origin)
	origin += forward * _spawn_forward
	_released_assist_point = _committed_assist_point
	var throw_range := -1.0
	if _target != null and is_instance_valid(_target) and _target.has_method("centre"):
		throw_range = origin.distance_to(_target.call("centre"))
	print("catch launch: release assist=%s predicted=%s range=%.2f from=(%.2f, %.2f, %.2f) dir=(%.2f, %.2f, %.2f)" % [
		_released_assist_point != Vector3.INF, _format_assist_point(_released_assist_point),
		throw_range, origin.x, origin.y, origin.z, forward.x, forward.y, forward.z,
	])

	_despawn_orb()
	_orb = ORB_SCENE.instantiate()
	_player.get_parent().add_child(_orb)
	_orb.connect("struck", _on_struck)
	_orb.connect("missed", _on_missed)
	# The trainer goes in the list here rather than at the call site: the orb
	# leaves the trainer's own hand, so without this a throw could register as
	# hitting the person who threw it.
	var ignore: Array[Node3D] = [_player]
	for body: Node3D in _pass_through:
		if body != null and is_instance_valid(body):
			ignore.append(body)
	_orb.call("launch", origin, forward, _speed, _target, ignore)
	# The trainer throws rather than standing there. Their model is on a child
	# node, so this reaches past the body to the thing that animates.
	var body: Node = _player.get_node_or_null(^"Model")
	if body != null and body.has_method("play_throw"):
		body.call("play_throw")

	aim_exited.emit()
	_committed_assist_point = Vector3.INF


## Snapshot the assist at the instant the player commits. The eligibility
## window is intentionally narrower than the existing soft magnetic pull: the
## centre ray must be inside the target's inner half-body and the target must
## have an unobstructed line from the camera. This is launch prediction for a
## good aim, not a lock-on that rescues a wide or blocked throw.
func _commit_launch_assist() -> void:
	_committed_assist_point = Vector3.INF
	var diagnostics := launch_assist_diagnostics()
	_log_launch_assist("commit", diagnostics)
	var camera := _aim_camera()
	if camera == null or _target == null or not is_instance_valid(_target) \
			or not _target.visible or not _target.has_method("centre"):
		return
	var eye := camera.global_position
	var camera_forward := -camera.global_transform.basis.z
	var centre: Vector3 = _target.call("centre")
	var along := (centre - eye).dot(camera_forward)
	if along <= 0.0:
		return
	var radius := 0.5
	if _target.has_method("body_radius"):
		radius = float(_target.call("body_radius"))
	var nearest := eye + camera_forward * along
	if nearest.distance_to(centre) > radius * _launch_assist_reticle_fraction:
		return
	if not _target_is_visible(eye, centre):
		return

	var origin := _player.global_position + Vector3.UP * _spawn_height
	var initial := (centre - origin).normalized()
	origin += initial * _spawn_forward
	var target_velocity := Vector3.ZERO
	if _target is CharacterBody3D:
		target_velocity = launch_target_velocity((_target as CharacterBody3D).velocity)
	_committed_assist_point = predict_launch_point(
		origin, centre, target_velocity, _speed, _gravity, _release_windup,
		_launch_assist_max_seconds, _launch_assist_max_target_speed,
		_launch_assist_max_distance)


## Eligibility belongs to the player's release press, but the target can change
## direction during the deliberate wind-up. Refreshing its *one fixed launch
## point* immediately before the orb exists avoids aiming at a stale future
## position. This never re-checks or widens the commit-time reticle/LOS gate and
## never changes an orb after launch.
func _refresh_committed_assist_point(origin: Vector3) -> void:
	if _committed_assist_point == Vector3.INF or _target == null \
			or not is_instance_valid(_target) or not _target.has_method("centre"):
		return
	var target_velocity := Vector3.ZERO
	if _target is CharacterBody3D:
		target_velocity = launch_target_velocity((_target as CharacterBody3D).velocity)
	_committed_assist_point = predict_launch_point(
		origin, _target.call("centre"), target_velocity, _speed, _gravity, 0.0,
		_launch_assist_max_seconds, _launch_assist_max_target_speed,
		_launch_assist_max_distance)


## Commit-time facts from the actual screen-centre ray and first physics hit.
## This is deliberately read-only: it makes why a legal assist did or did not
## apply observable without widening the visible-body/LOS eligibility rule.
func launch_assist_diagnostics() -> Dictionary:
	var report: Dictionary = {
		"eligible": false,
		"first_hit": "unavailable",
		"line_of_sight": false,
		"reason": "unavailable",
	}
	var camera := _aim_camera()
	if camera == null or _player == null or _target == null or not is_instance_valid(_target) \
			or not _target.visible or not _target.has_method("centre"):
		return report
	var eye := camera.global_position
	var centre: Vector3 = _target.call("centre")
	var radius := float(_target.call("body_radius")) if _target.has_method("body_radius") else 0.5
	var geometry := reticle_body_geometry(
		eye, -camera.global_transform.basis.z, centre, radius, _launch_assist_reticle_fraction)
	report.merge(geometry, true)
	if not bool(report["in_front"]):
		report["reason"] = "behind"
		return report
	var world := _player.get_world_3d()
	if world == null:
		report["reason"] = "no_world"
		return report
	var query := PhysicsRayQueryParameters3D.create(eye, centre)
	query.collide_with_areas = false
	# The same exclusions the orb itself flies with -- see `_sight_exclusions()`.
	query.exclude = _sight_exclusions()
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	var collider := hit.get("collider") as Node
	if collider != null:
		report["first_hit"] = collider.name
	report["line_of_sight"] = first_hit_belongs_to_target(collider, _target)
	if not bool(report["inside_body"]):
		report["reason"] = "reticle_outside_body"
	elif not bool(report["line_of_sight"]):
		report["reason"] = "line_of_sight_blocked"
	else:
		report["eligible"] = true
		report["reason"] = "eligible"
	return report


func _log_launch_assist(stage: String, report: Dictionary) -> void:
	print("catch launch: %s eligible=%s reticle=%.3f/%.3f first_hit=%s los=%s reason=%s" % [
		stage,
		bool(report.get("eligible", false)),
		float(report.get("reticle_offset", -1.0)),
		float(report.get("reticle_radius", -1.0)),
		str(report.get("first_hit", "unavailable")),
		bool(report.get("line_of_sight", false)),
		str(report.get("reason", "unavailable")),
	])


func _format_assist_point(point: Vector3) -> String:
	return "none" if point == Vector3.INF else "(%.2f, %.2f, %.2f)" % [point.x, point.y, point.z]


func _target_is_visible(eye: Vector3, centre: Vector3) -> bool:
	var world := _player.get_world_3d() if _player != null else null
	if world == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, centre)
	query.collide_with_areas = false
	query.exclude = _sight_exclusions()
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	return collider == _target or (collider != null and _target.is_ancestor_of(collider))


## What this ray is allowed to ignore, and why the list is not just the trainer.
##
## OP-0830-5. `_release()` hands the orb an ignore list built from `_player` plus
## `_pass_through` -- which `combat_manager.gd` sets to the player's OWN creature
## -- so an orb flies straight through your creature and hits the target behind
## it. The eligibility check did not, so a creature standing between the camera
## and the thing it is fighting reported `line_of_sight_blocked` and the assist
## was refused, on a throw the physics would have delivered perfectly.
##
## That is not a rare geometry. Combat is piloted: your creature is *supposed* to
## be in the opponent's face, which is exactly where it occludes it. It showed up
## in `tests/smoke_catching.gd`'s own launch log before this lane existed (one of
## four commits in a real fight refused for it) and again in the OP-0830-5
## measurement run.
##
## The ray and the orb now agree about what is solid. This does not widen the
## assist: a reticle genuinely off the body is still ineligible, and anything
## that is not the trainer or the trainer's creature still blocks.
func _sight_exclusions() -> Array[RID]:
	var out: Array[RID] = []
	if _player is CollisionObject3D:
		out.append((_player as CollisionObject3D).get_rid())
	for body: Node3D in _pass_through:
		if body != null and is_instance_valid(body) and body is CollisionObject3D:
			out.append((body as CollisionObject3D).get_rid())
	return out


func _launch_direction(camera: Camera3D, origin: Vector3) -> Vector3:
	if _committed_assist_point != Vector3.INF:
		var fallback := -_player.global_transform.basis.z
		if camera != null:
			fallback = -camera.global_transform.basis.z
		return _ballistic_direction(origin, _committed_assist_point, fallback)
	return _aim_direction(camera, origin)


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
			# OWNER DIRECTIVE 2026-08-28 §2a.3, the second half of "aim assist
			# needs to be stronger". This is the SOFT pull -- how much a
			# near-miss reticle is drawn toward the creature before the throw is
			# even committed -- and it is separate from the launch assist above,
			# which is a hard lead granted only inside the reticle window.
			#
			# The band was `body * 0.5` to `body`, i.e. full pull only inside
			# half a body-width and nothing at all past one. `AIM_PULL_INNER`
			# and `AIM_PULL_OUTER` widen both ends: full pull out to a whole
			# body-width, tapering to nothing at two and a half. The falloff
			# stays a smoothstep for the reason the note above records -- the
			# binary version made the aim jump as the reticle swept past, the
			# "grabbed the stick" feel from an earlier playtest -- so this is a
			# larger, gentler magnet, not a snap.
			var pull := 1.0 - smoothstep(
				body * AIM_PULL_INNER, body * AIM_PULL_OUTER, nearest.distance_to(centre))
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
	return ballistic_direction(origin, point, fallback, _speed, _gravity)


static func ballistic_direction(
	origin: Vector3, point: Vector3, fallback: Vector3, speed: float, gravity: float
) -> Vector3:
	var flat := Vector2(point.x - origin.x, point.z - origin.z)
	var reach := flat.length()
	if reach < 0.01:
		return fallback
	var rise := point.y - origin.y
	var s2 := speed * speed
	var disc := s2 * s2 - gravity * (gravity * reach * reach + 2.0 * rise * s2)
	var horizontal := Vector3(flat.x, 0.0, flat.y) / reach
	if disc < 0.0:
		var direct := point - origin
		return direct.normalized() if direct.length() > 0.01 else fallback
	# The smaller root is the low, fast arc; the high lob spends its flight
	# time hanging in the air over a moving creature.
	var pitch_tan := (s2 - sqrt(disc)) / (gravity * reach)
	return (horizontal + Vector3.UP * pitch_tan).normalized()


## Constant-velocity launch prediction used only after the reticle/visibility
## gate above. Two iterations are enough because the Meadows combatants move at
## walking speed while the orb flies at 17m/s. Every input is bounded so a
## pathological velocity can never turn this mild lead into a snap across the
## arena.
static func predict_launch_point(
	origin: Vector3, centre: Vector3, target_velocity: Vector3,
	speed: float, gravity: float, windup: float, max_seconds: float,
	max_target_speed: float, max_distance: float
) -> Vector3:
	var velocity := target_velocity
	if velocity.length() > max_target_speed:
		velocity = velocity.normalized() * max_target_speed
	var predicted := centre
	for _iteration in 2:
		var fallback := (predicted - origin).normalized()
		var direction := ballistic_direction(origin, predicted, fallback, speed, gravity)
		var horizontal_speed := Vector2(direction.x, direction.z).length() * speed
		var horizontal_distance := Vector2(
			predicted.x - origin.x, predicted.z - origin.z).length()
		var flight := horizontal_distance / maxf(horizontal_speed, 0.01)
		var horizon := clampf(maxf(0.0, windup) + flight, 0.0, max_seconds)
		predicted = centre + velocity * horizon
	var lead := predicted - centre
	if lead.length() > max_distance:
		lead = lead.normalized() * max_distance
	return centre + lead


## CharacterBody3D keeps a small downward velocity while grounded to maintain
## contact. Catch prediction is planar: that bookkeeping must never be treated
## as a falling target during the release windup.
## Whether an orb launched at `speed` under `gravity` can physically LAND on
## `point`. This is the same discriminant `ballistic_direction()` solves: when
## it goes negative there is no launch angle that reaches, and that function
## quietly falls back to the straight line -- which drops short by however far
## out of range the point was. Nothing used to ask the question before spending
## the orb.
static func within_ballistic_reach(
	origin: Vector3, point: Vector3, speed: float, gravity: float
) -> bool:
	var flat := Vector2(point.x - origin.x, point.z - origin.z)
	var reach := flat.length()
	if reach < 0.01:
		return true
	var rise := point.y - origin.y
	var s2 := speed * speed
	return s2 * s2 - gravity * (gravity * reach * reach + 2.0 * rise * s2) >= 0.0


static func launch_target_velocity(body_velocity: Vector3) -> Vector3:
	return Vector3(body_velocity.x, 0.0, body_velocity.z)


func _aim_camera() -> Camera3D:
	if _camera_rig == null:
		return null
	return _camera_rig.get_node_or_null(^"Camera3D") as Camera3D


func _on_struck(target: Node3D, offset: float) -> void:
	state = State.IDLE
	_cooldown = _throw_cooldown
	print("catch launch: strike assist=%s predicted=%s offset=%.3f" % [
		_released_assist_point != Vector3.INF, _format_assist_point(_released_assist_point), offset,
	])
	orb_struck.emit(target, offset)


func _on_missed(reason: String, closest: float, needed: float) -> void:
	state = State.IDLE
	_cooldown = _throw_cooldown
	print("catch launch: miss assist=%s predicted=%s reason=%s closest=%.2f" % [
		_released_assist_point != Vector3.INF, _format_assist_point(_released_assist_point),
		reason, closest,
	])
	_despawn_orb()
	orb_missed.emit(miss_message(reason, closest, needed))


## What a miss tells the player.
##
## Static and pure so the wording is testable without a flight. Every branch
## carries the gap in metres: the difference between a throw that grazed and a
## throw that was never near is the whole of "am I getting better at this", and
## the old single string erased it.
static func miss_message(reason: String, closest: float, needed: float) -> String:
	if closest == INF or closest < 0.0:
		return "the orb went wide"
	var gap := maxf(0.0, closest - needed)
	if gap < 0.05:
		# Rounding "0.005m" to "0.0m" printed a miss that read as a bug. A throw
		# this close missed by less than the message can express, so it says so.
		return "so close — a hand's width wide"
	if gap <= 0.35:
		return "so close — %.1fm wide" % gap
	if reason == "ground":
		return "the orb hit the ground — %.1fm wide" % gap
	if reason == "flight_time":
		return "the orb sailed past — %.1fm wide" % gap
	return "the orb went wide — %.1fm" % gap


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


## Who this trainer's orbs fly past. Set by `combat_manager.gd` each fight.
func set_pass_through(bodies: Array) -> void:
	_pass_through.clear()
	for body: Variant in bodies:
		if body is Node3D and is_instance_valid(body):
			_pass_through.append(body as Node3D)
