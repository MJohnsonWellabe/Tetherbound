extends Node

## Combat Mode: a STATE, not a scene.
##
## The world keeps rendering, the trainer stays standing where they engaged, the
## terrain stays loaded. Nothing is unloaded and nothing is instanced from a
## separate arena scene. That is a stated requirement (TECHNICAL_START.md,
## "Combat Mode should be a state transition, not a separate unrelated game"),
## and it is also what keeps the transition free of a loading pause.
##
## Combat is PILOTED (docs/decisions/D07): the player takes over their pal,
## both fighters move inside a bounded arena, and attacks are aimed and can
## miss. There is no dodge button — movement is the dodge.
##
## This is the single place that knows a fight is happening. Everything else —
## the player controller, the camera rig, the HUD — is told, and does not ask.
##
## M2 scope: one wild pal, one of yours, quick and charged attacks, and three
## ways out. No catching, no party, no types, no switching UI. The switch SEAM
## is here (`_active_index` into `_party`) so M4 adds members rather than
## restructuring this file.

const MATH := preload("res://scripts/combat/combat_math.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")

signal entered()
signal exited(outcome: String)
signal state_changed()
signal hit_landed(on_enemy: bool, amount: float)
signal attack_missed(by_player: bool)

enum State { INACTIVE, ACTIVE, RESOLVING }

## What the player's pal is doing. Wind-up and recovery are ROOTED: committing
## to an attack costs you your mobility, which is the whole reason a charged
## attack is a decision rather than a better button.
enum Action { READY, WINDUP, RECOVERY }

var state: State = State.INACTIVE

## The player's pals. Length one for M2; M4 grows it. Combat always addresses
## the active fighter through this index so switching is an index change rather
## than a rewrite.
var _party: Array[RefCounted] = []
var _active_index: int = 0
var _enemy: RefCounted = null

var _player: Node3D = null
var _wild: Node3D = null
var _ally_body: Node3D = null
var _camera_rig: Node = null
var _arena: Node3D = null

var _action: Action = Action.READY
var _action_timer: float = 0.0
var _pending_move: Dictionary = {}
var _quick_cooldown: float = 0.0
var _charged_cooldown: float = 0.0

var _resolve_timer: float = 0.0
var _outcome: String = ""

## Seconds after the fight opens during which player input is ignored.
##
## Engage and charged attack are the same physical button (X / interact and
## combat_charged), and `is_action_just_pressed` stays true for the whole frame.
## Without this, the press that starts the fight is also read as the first
## attack of it.
var _input_guard: float = 0.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_physics_process(false)


func active_pal() -> RefCounted:
	if _active_index < 0 or _active_index >= _party.size():
		return null
	return _party[_active_index]


func enemy() -> RefCounted:
	return _enemy


func is_fighting() -> bool:
	return state != State.INACTIVE


func arena() -> Node3D:
	return _arena


## Begin a fight. `ally_body` is the player's deployed pal, `camera_rig` is the
## exploration camera that will be re-pointed at it.
func begin(player: Node3D, wild: Node3D, ally_body: Node3D, party: Array[RefCounted], camera_rig: Node = null) -> bool:
	if is_fighting():
		return false
	if player == null or wild == null or ally_body == null or party.is_empty():
		push_error("cannot begin combat without a player, a wild pal, a deployed body and a party")
		return false

	_player = player
	_wild = wild
	_ally_body = ally_body
	_camera_rig = camera_rig
	_party = party
	_active_index = 0
	_enemy = wild.get("instance")
	if _enemy == null:
		push_error("wild pal has no instance")
		return false

	var pal := active_pal()
	if pal == null or pal.fainted:
		return false

	_action = Action.READY
	_action_timer = 0.0
	_pending_move = {}
	_quick_cooldown = 0.0
	_charged_cooldown = 0.0
	_resolve_timer = 0.0
	_outcome = ""
	_input_guard = float(MATH.config().get("flow", {}).get("input_guard", 0.25))

	_open_arena()
	_place_fighters()

	if not _wild.is_connected("strike_ready", _on_enemy_strike):
		_wild.connect("strike_ready", _on_enemy_strike)
	_wild.call("set_engaged", true, _ally_body)
	_wild.set("arena", _arena)
	_ally_body.set("arena", _arena)

	_take_camera()

	state = State.ACTIVE
	set_physics_process(true)
	entered.emit()
	state_changed.emit()
	return true


## --- setup ----------------------------------------------------------------

## The arena is centred between the two fighters, not on the trainer. Centring
## it on the trainer would put them at the middle of a circle they are supposed
## to be standing at the edge of, watching.
func _open_arena() -> void:
	var cfg: Dictionary = MATH.config().get("arena", {})
	_arena = ARENA.new()
	_arena.name = "CombatArena"
	_player.get_parent().add_child(_arena)
	_arena.call("configure", _midpoint(cfg), cfg)


func _midpoint(cfg: Dictionary) -> Vector3:
	var forward := _forward_axis()
	var deploy := float(cfg.get("deploy_offset", 2.6))
	var separation := float(cfg.get("separation", 5.0))
	return _player.global_position + forward * (deploy + separation * 0.5)


func _forward_axis() -> Vector3:
	var forward := _wild.global_position - _player.global_position
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = -_player.global_transform.basis.z
		forward.y = 0.0
	return Vector3.FORWARD if forward.length() < 0.01 else forward.normalized()


## Arrange the two fighters facing each other, along the line the player was
## already looking down when they engaged.
##
## The trainer is not moved and is never targeted. The fight forms in front of
## them, so the arena appears where the player was standing rather than the
## player being teleported into an arena. That is the whole difference between
## "a state" and "a separate scene".
func _place_fighters() -> void:
	var cfg: Dictionary = MATH.config().get("arena", {})
	var forward := _forward_axis()
	var ally_spot := _player.global_position + forward * float(cfg.get("deploy_offset", 2.6))
	var wild_spot := ally_spot + forward * float(cfg.get("separation", 5.0))

	_ally_body.visible = true
	_place(_ally_body, ally_spot)
	_ally_body.call("face_towards", wild_spot)
	_place(_wild, wild_spot)
	_wild.call("face_towards", ally_spot)
	_stand_the_trainer_aside(forward)


## The trainer steps to the side of the arena as their pal deploys.
##
## They stay in the fight, in frame, and untargetable — but not in the LANE. The
## camera follows the player's pal from behind, and the trainer engaged from
## directly behind that pal, so leaving them where they stood put a 1.8m body
## between the camera and the entire fight for the opening seconds of every
## single encounter. It filled the frame.
##
## This is a small, one-off move at the moment the fight opens, not a system
## that puppets them around afterwards.
func _stand_the_trainer_aside(forward: Vector3) -> void:
	if _arena == null:
		return
	var side := forward.cross(Vector3.UP).normalized()
	var centre: Vector3 = _arena.global_position
	var spot := centre + side * (float(_arena.get("radius")) * 0.78) - forward * 1.5
	_player.global_position = spot
	_player.velocity = Vector3.ZERO

	# Turn them to watch. The controller owns the model's yaw during
	# exploration, and locomotion is suspended, so writing it here is safe.
	var model: Node3D = _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		var to := centre - spot
		to.y = 0.0
		if to.length() > 0.01:
			model.rotation.y = atan2(to.x, to.z)


func _place(body: Node3D, spot: Vector3) -> void:
	if not bool(body.call("place_on_ground", spot)):
		body.global_position = spot


## Point the exploration camera at the pal instead of the trainer.
##
## Reusing the orbit rig rather than adding a combat camera: a piloted pal wants
## exactly the third-person camera M1 already tuned, at a shorter creature's
## height. A second camera would be a second thing to keep in sync, and the rig
## already eases onto a new target for free.
func _take_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _ally_body, MATH.config().get("camera", {}))


func _release_camera() -> void:
	if _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", _player, {})


## --- the loop -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	match state:
		State.ACTIVE:
			_tick_active(delta)
		State.RESOLVING:
			_resolve_timer -= delta
			if _resolve_timer <= 0.0:
				_finish()
		_:
			pass


func _tick_active(delta: float) -> void:
	_quick_cooldown = maxf(0.0, _quick_cooldown - delta)
	_charged_cooldown = maxf(0.0, _charged_cooldown - delta)
	_input_guard = maxf(0.0, _input_guard - delta)

	_tick_action(delta)
	_drive_player_pal()
	if _input_guard <= 0.0:
		_read_player_input()


## Wind-up, strike, recovery. The strike resolves at the END of the wind-up, and
## the recovery that follows is time the player cannot move — which is what the
## opponent is meant to punish.
func _tick_action(delta: float) -> void:
	if _action == Action.READY:
		return
	_action_timer -= delta
	if _action_timer > 0.0:
		return

	if _action == Action.WINDUP:
		_resolve_player_strike()
		_action = Action.RECOVERY
		_action_timer = float(_pending_move.get("recovery", 0.2))
		state_changed.emit()
		return

	_action = Action.READY
	_pending_move = {}
	state_changed.emit()


func _resolve_player_strike() -> void:
	var pal := active_pal()
	if pal == null or _enemy == null or _ally_body == null or _wild == null:
		return

	var origin: Vector3 = _ally_body.call("centre")
	var facing: Vector3 = _ally_body.call("facing")
	var target: Vector3 = _wild.call("centre")

	_ally_body.call("add_impulse", facing, float(_pending_move.get("lunge", 3.6)))

	if not MATH.move_connects(_pending_move, origin, facing, target):
		attack_missed.emit(true)
		state_changed.emit()
		return

	var damage: float = MATH.rolled_damage(
		float(_pending_move.get("power", 9.0)), pal.attack, _enemy.defence, _rng.randf()
	)
	var killed: bool = _enemy.take_damage(damage)
	_wild.call("add_impulse", facing, float(_pending_move.get("lunge", 3.6)) * 0.4)

	# Energy is earned by CONNECTING, not by pressing. That is what makes
	# positioning matter to the charged attack rather than only to survival.
	if bool(_pending_move.get("is_quick", false)):
		pal.gain_energy_from_quick()

	hit_landed.emit(true, damage)
	state_changed.emit()
	if killed:
		_begin_resolve("won")


## Movement is the dodge. The pal is driven straight from the stick, in camera
## space, exactly like the trainer — and is rooted while attacking.
func _drive_player_pal() -> void:
	if _ally_body == null:
		return
	if _action != Action.READY:
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		return
	var basis_value := Basis.IDENTITY
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		basis_value = _camera_rig.call("planar_basis")
	_ally_body.call("request_move", basis_value * Vector3(input.x, 0.0, input.y))


func _read_player_input() -> void:
	var pal := active_pal()
	if pal == null:
		return

	if Input.is_action_just_pressed("combat_run"):
		_begin_resolve("fled")
		return

	if _action != Action.READY:
		return

	if Input.is_action_just_pressed("combat_charged") and _charged_cooldown <= 0.0:
		if pal.spend_charged():
			var charged: Dictionary = MATH.config().get("player_charged", {}).duplicate()
			charged["is_quick"] = false
			_start_action(charged)
			_charged_cooldown = float(charged.get("cooldown", 1.2))
		return

	if Input.is_action_just_pressed("combat_quick") and _quick_cooldown <= 0.0:
		var quick: Dictionary = MATH.config().get("player_quick", {}).duplicate()
		quick["is_quick"] = true
		_start_action(quick)
		_quick_cooldown = float(quick.get("cooldown", 0.45))


func _start_action(move: Dictionary) -> void:
	_pending_move = move
	_action = Action.WINDUP
	_action_timer = float(move.get("windup", 0.18))
	state_changed.emit()


## The opponent announces its swing when its wind-up completes; whether it
## connects is decided here, by the same arithmetic the player's attacks use.
func _on_enemy_strike() -> void:
	if state != State.ACTIVE:
		return
	var pal := active_pal()
	if pal == null or _enemy == null:
		return

	var cfg: Dictionary = MATH.config().get("enemy", {})
	var origin: Vector3 = _wild.call("centre")
	var facing: Vector3 = _wild.call("facing")
	var target: Vector3 = _ally_body.call("centre")

	_wild.call("add_impulse", facing, float(cfg.get("lunge", 3.4)))

	if not MATH.move_connects(cfg, origin, facing, target):
		attack_missed.emit(false)
		state_changed.emit()
		return

	var damage: float = MATH.rolled_damage(
		float(cfg.get("power", 8.0)), _enemy.attack, pal.defence, _rng.randf()
	)
	var killed: bool = pal.take_damage(damage)
	_ally_body.call("add_impulse", facing, float(cfg.get("lunge", 3.4)) * 0.4)

	hit_landed.emit(false, damage)
	state_changed.emit()
	if killed:
		_begin_resolve("lost")


## --- resolution -----------------------------------------------------------

func _begin_resolve(outcome: String) -> void:
	if state == State.RESOLVING:
		return
	_outcome = outcome
	state = State.RESOLVING
	var flow: Dictionary = MATH.config().get("flow", {})
	_resolve_timer = float(flow.get("run_delay", 0.5)) if outcome == "fled" \
		else float(flow.get("faint_pause", 1.6))
	if _wild != null:
		_wild.call("set_engaged", false)
	state_changed.emit()


func _finish() -> void:
	state = State.INACTIVE
	set_physics_process(false)

	if _ally_body != null:
		_ally_body.visible = false
		_ally_body.set("arena", null)
	if _arena != null:
		_arena.queue_free()
		_arena = null
	_release_camera()

	exited.emit(_outcome)
	state_changed.emit()


## --- readouts for the HUD -------------------------------------------------
##
## The HUD asks; it is never pushed to. A HUD that keeps its own copy of the
## fight can disagree with the fight, and the first time that happens it costs
## an afternoon.

func quick_ready() -> bool:
	return _action == Action.READY and _quick_cooldown <= 0.0


func charged_ready() -> bool:
	var pal := active_pal()
	return pal != null and pal.can_use_charged() \
		and _action == Action.READY and _charged_cooldown <= 0.0


## True while the player's pal is committed and cannot move.
func player_is_committed() -> bool:
	return _action != Action.READY


## True while the enemy's wind-up is visible and its blow has not landed. This
## is the fight's only warning, and it is now something the player can act on by
## moving out of the way.
func enemy_is_winding_up() -> bool:
	return _wild != null and bool(_wild.call("is_winding_up"))


## True while the enemy is rooted — winding up or recovering. The recovery half
## is the player's punish window.
func enemy_is_rooted() -> bool:
	return _wild != null and bool(_wild.call("is_rooted"))


func outcome() -> String:
	return _outcome


## Where the two fighters are, for anything that needs to frame them.
func arena_focus() -> Vector3:
	if _ally_body != null and _wild != null:
		return (_ally_body.global_position + _wild.global_position) * 0.5
	if _player != null:
		return _player.global_position
	return Vector3.ZERO
