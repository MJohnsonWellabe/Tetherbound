extends Node

## Combat Mode: a STATE, not a scene.
##
## The world keeps rendering, the trainer stays standing where they engaged, the
## terrain stays loaded. Nothing is unloaded and nothing is instanced from a
## separate arena scene. That is a stated requirement (TECHNICAL_START.md,
## "Combat Mode should be a state transition, not a separate unrelated game"),
## and it is also what keeps the transition free of a loading pause.
##
## Combat is PILOTED (docs/decisions/D07): the player takes over their creature,
## both fighters move inside a bounded arena, and attacks are aimed and can
## miss. There is no dodge button — movement is the dodge.
##
## This is the single place that knows a fight is happening. Everything else —
## the player controller, the camera rig, the HUD — is told, and does not ask.
##
## M2 scope: one wild creature, one of yours, quick and charged attacks, and three
## ways out. No catching, no party, no types, no switching UI. The switch SEAM
## is here (`_active_index` into `_party`) so M4 adds members rather than
## restructuring this file.

const MATH := preload("res://scripts/combat/combat_math.gd")
const ARENA := preload("res://scripts/combat/combat_arena.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const THROW_AIM := preload("res://scripts/combat/throw_aim.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLASH := preload("res://scripts/combat/impact_flash.gd")
const TELEGRAPH_GLOW := preload("res://scripts/combat/telegraph_glow.gd")
const TARGET_MARKER := preload("res://scripts/combat/target_marker.gd")
## D30: XP/bond arithmetic and named-move power, both pure data readers with
## no scene-tree dependency — see their own file headers.
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")

signal entered()
signal exited(outcome: String)
signal state_changed()
signal hit_landed(on_enemy: bool, amount: float)
signal attack_missed(by_player: bool)
## A throw finished resolving. `shakes` is how many times the orb wobbled, and
## comes from the single decision made when it landed — it is never re-rolled.
signal catch_resolved(success: bool, shakes: int)
signal catch_refused(reason: String)
signal orb_shook(index: int)
## D32: a voluntary mid-combat switch just completed. `index` is the new
## `_active_index`. Distinct from `state_changed` (still emitted alongside it)
## so the HUD can react to "who is out" without diffing the whole state.
signal creature_switched(index: int)

enum State { INACTIVE, ACTIVE, RESOLVING }

## Why a fight ended. "caught" is new in M3 and is deliberately distinct from
## "won": beating a creature and keeping one are different outcomes and the
## world needs to treat them differently.
const OUTCOME_CAUGHT := "caught"

## What the player's creature is doing. Wind-up and recovery are ROOTED: committing
## to an attack costs you your mobility, which is the whole reason a charged
## attack is a decision rather than a better button.
enum Action { READY, WINDUP, RECOVERY }

var state: State = State.INACTIVE

## The player's creatures. Length one for M2; M4 grows it. Combat always addresses
## the active fighter through this index so switching is an index change rather
## than a rewrite.
var _party: Array[RefCounted] = []
var _active_index: int = 0
var _enemy: RefCounted = null

## D32. Seconds left before another voluntary switch is allowed. Set by
## `request_switch`, ticked down in `_tick_active`. Does not gate a faint —
## there is no auto-switch-on-faint (D32's own "what was deliberately not
## built") — only the player's own next `request_switch`/`cycle_active` call.
var _switch_lockout: float = 0.0

## D30. What the active creature and its bench earned from the fight that just
## ended, keyed by `creature_instance.label()`: `{"xp": int, "levels": int}`. Reset
## at the start of every fight and overwritten by the next victory. The HUD
## reads this; nothing here draws it. Two un-nicknamed party members of the
## same species collide on this key — a later milestone that keys the HUD's
## own readout by party index rather than label can retire this note.
var last_xp_award: Dictionary = {}

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

## An attack press made during wind-up, recovery or cooldown, kept alive for
## `flow.input_buffer` seconds and fired the moment the creature is ready. Without
## this, presses in the ~0.4s dead window were silently discarded and mashing
## at a natural rhythm read as dropped input. "" / "quick" / "charged".
var _buffered_attack: String = ""
var _buffer_left: float = 0.0

var _resolve_timer: float = 0.0
var _outcome: String = ""

## Seconds after the fight opens during which player input is ignored.
##
## Engage and charged attack are the same physical button (X / interact and
## combat_charged), and `is_action_just_pressed` stays true for the whole frame.
## Without this, the press that starts the fight is also read as the first
## attack of it.
var _input_guard: float = 0.0

## Catching. The aim and the projectile live in throw_aim.gd; what lives here is
## deciding whether a throw is allowed and what its result means to the fight.
##
## The resolution is a staged sequence, not a bare timer: the creature is drawn
## in while the orb hangs (ABSORB), the orb drops and the camera glides into a
## close-up, a beat of stillness (WAIT), the shakes (SHAKING), a held breath
## (VERDICT), then the outcome. The outcome itself was decided the moment the
## orb landed; the phases only perform it.
enum CatchPhase { NONE, ABSORB, WAIT, SHAKING, VERDICT }
var _throw: Node = null
var _catch_phase: CatchPhase = CatchPhase.NONE
var _catch_timer: float = 0.0
var _catch_shakes_total: int = 0
var _catch_succeeded: bool = false
var _catch_index: int = 0

## `R9.4-remainder-9-combat`: floats over the real opponent for the length of
## the fight, so it cannot be confused with an ambient decorative creature from the
## same spawn cluster.
var _target_marker: Node3D = null

var _rng := RandomNumberGenerator.new()

## D30 named-move lookup, loaded once. Read-only after construction, so one
## instance shared for the life of the manager is fine — the same choice
## `_rng` above already makes.
var _moves: RefCounted = null


func _ready() -> void:
	_rng.randomize()
	_moves = MOVE_DB.new()
	set_physics_process(false)

	_throw = THROW_AIM.new()
	_throw.name = "ThrowAim"
	add_child(_throw)
	_throw.connect("orb_struck", _on_orb_struck)
	_throw.connect("orb_missed", _on_orb_missed)
	_throw.connect("throw_refused", func(reason: String) -> void: catch_refused.emit(reason))
	# The camera comes BACK when the aim ends. This signal had no listener at
	# all: cancelling an aim, and every throw, left the whole rest of the fight
	# framed through the over-the-shoulder aim profile parked on the trainer.
	# After a release the aim camera is kept deliberately — watching your own
	# throw arc away is the shot — and the strike or miss decides what's next.
	_throw.connect("aim_exited", _on_aim_exited)


func throw_aim() -> Node:
	return _throw


func active_creature() -> RefCounted:
	if _active_index < 0 or _active_index >= _party.size():
		return null
	return _party[_active_index]


func enemy() -> RefCounted:
	return _enemy


func is_fighting() -> bool:
	return state != State.INACTIVE


func arena() -> Node3D:
	return _arena


## Begin a fight. `ally_body` is the player's deployed creature, `camera_rig` is the
## exploration camera that will be re-pointed at it.
func begin(player: Node3D, wild: Node3D, ally_body: Node3D, party: Array[RefCounted], camera_rig: Node = null) -> bool:
	if is_fighting():
		return false
	if player == null or wild == null or ally_body == null or party.is_empty():
		push_error("cannot begin combat without a player, a wild creature, a deployed body and a party")
		return false

	_player = player
	_wild = wild
	_ally_body = ally_body
	_camera_rig = camera_rig
	_party = party
	_active_index = 0
	_enemy = wild.get("instance")
	if _enemy == null:
		push_error("wild creature has no instance")
		return false

	var creature := active_creature()
	if creature == null or creature.fainted:
		return false

	_action = Action.READY
	_action_timer = 0.0
	_pending_move = {}
	_quick_cooldown = 0.0
	_charged_cooldown = 0.0
	_buffered_attack = ""
	_buffer_left = 0.0
	_resolve_timer = 0.0
	_outcome = ""
	_input_guard = float(MATH.config().get("flow", {}).get("input_guard", 0.25))

	_catch_phase = CatchPhase.NONE
	_catch_timer = 0.0
	_catch_shakes_total = 0

	_switch_lockout = 0.0
	last_xp_award.clear()

	_open_arena()
	_place_fighters()
	_throw.call("arm", _player, _wild, _camera_rig)

	if not _wild.is_connected("strike_ready", _on_enemy_strike):
		_wild.connect("strike_ready", _on_enemy_strike)
	if not _wild.is_connected("telegraph_started", _on_enemy_telegraph):
		_wild.connect("telegraph_started", _on_enemy_telegraph)
	_wild.call("set_engaged", true, _ally_body)
	_wild.set("arena", _arena)
	_ally_body.set("arena", _arena)

	_target_marker = TARGET_MARKER.begin(_arena, _wild, MATH.config().get("target_marker", {}))

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


## The trainer steps to the side of the arena as their creature deploys.
##
## They stay in the fight, in frame, and untargetable — but not in the LANE. The
## camera follows the player's creature from behind, and the trainer engaged from
## directly behind that creature, so leaving them where they stood put a 1.8m body
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
	# Well inside the boundary rather than on it. The aim camera sits several
	# metres behind the trainer, and standing them at the very edge put that
	# camera outside the arena looking in through the wall.
	var spot := centre + side * (float(_arena.get("radius")) * 0.55) - forward * 1.2

	# Re-grounded rather than trusting the arena centre's own height (D09: ask
	# the world, never carry a Y across a horizontal move). `centre` is the
	# midpoint between where the player engaged and the wild creature, and `spot`
	# is shifted sideways from it — on a slope those two points are at
	# different heights, and this teleport (a raw position write, not a
	# physics move) has nothing else to correct it: the trainer fell through
	# the terrain forever on ground uneven enough for the difference to clear
	# the collision, `move_and_slide` never finding a floor to catch it on the
	# way down. A missing ground reading here is a placement to skip, same as
	# `creature_body.place_on_ground`, rather than a spot to stand on regardless.
	var height := _ground_height(spot.x, spot.z)
	if not is_nan(height):
		spot.y = height
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


## The world's own ground query, found by walking up the tree — same pattern
## as `creature_body._ground_height`. Not cached: this is a one-off correction at
## the moment a fight opens, not a per-frame lookup.
func _ground_height(x: float, z: float) -> float:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("ground_height_at"):
			return float(node.call("ground_height_at", x, z))
		node = node.get_parent()
	return NAN


## Point the exploration camera at the creature instead of the trainer.
##
## Reusing the orbit rig rather than adding a combat camera: a piloted creature wants
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
	_buffer_left = maxf(0.0, _buffer_left - delta)
	_switch_lockout = maxf(0.0, _switch_lockout - delta)
	if _buffer_left <= 0.0:
		_buffered_attack = ""

	if _catch_phase != CatchPhase.NONE:
		_tick_catch_resolution(delta)
		return

	_tick_action(delta)
	_drive_player_creature()
	if _input_guard <= 0.0:
		_read_player_input()
	_consume_buffered_attack()


## Wind-up, strike, recovery. The strike resolves at the END of the wind-up, and
## the recovery that follows is time the player cannot move — which is what the
## opponent is meant to punish.
func _tick_action(delta: float) -> void:
	if _action == Action.READY:
		return

	# Track the target through the wind-up. The creature is rooted from the press to
	# the end of recovery, and the connect test runs against the enemy's LIVE
	# position at the end of the wind-up — so a swing whose facing was frozen at
	# the press whiffed on any enemy that stepped sideways, and standing still
	# and pressing attack swung at whatever direction the creature last WALKED in.
	# Facing is free to give: range and timing stay the real skills, and the
	# owner's first-playtest verdict was "too hard to hit", not "too easy".
	if _action == Action.WINDUP and _ally_body != null and _wild != null:
		_ally_body.call("face_towards", _wild.call("centre"))

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
	var creature := active_creature()
	if creature == null or _enemy == null or _ally_body == null or _wild == null:
		return

	var origin: Vector3 = _ally_body.call("centre")
	var facing: Vector3 = _ally_body.call("facing")
	var target: Vector3 = _wild.call("centre")

	if not MATH.move_connects(_pending_move, origin, facing, target):
		attack_missed.emit(true)
		state_changed.emit()
		return

	var is_quick: bool = bool(_pending_move.get("is_quick", false))
	var move_id: String = creature.move_quick if is_quick else creature.move_charged
	var damage: float = MATH.rolled_damage(
		float(_pending_move.get("power", 9.0)), creature.attack, _enemy.defence, _rng.randf(),
		_moves.power(move_id)
	)
	var killed: bool = _enemy.take_damage(damage)
	_wild.call("add_impulse", facing, float(_pending_move.get("lunge", 3.6)) * 0.4)
	_wild.call("play_faint" if killed else "play_hit")
	_flash_at(_wild.call("centre"), not is_quick)

	# Energy is earned by CONNECTING, not by pressing. That is what makes
	# positioning matter to the charged attack rather than only to survival.
	if is_quick:
		creature.gain_energy_from_quick()

	hit_landed.emit(true, damage)
	state_changed.emit()
	if killed:
		_award_victory()
		_begin_resolve("won")


## --- progression (D30) ------------------------------------------------------

## The fight has just been WON — `_enemy` is still valid (called before
## `_begin_resolve` starts tearing anything down). The creature that landed the
## killing blow gets the full award and a bond tick for the win; every other
## non-fainted party member gets `party_share` of the same award, matching
## the rest of the party having been "in the fight" without taking the risk.
## A fainted party member gets nothing — it did not fight.
func _award_victory() -> void:
	if _enemy == null:
		return
	var cfg: Dictionary = PROGRESSION.config()
	var award: int = PROGRESSION.xp_award_for(_enemy.level, cfg)
	var share: int = PROGRESSION.party_share(award, cfg)

	last_xp_award.clear()
	for i in _party.size():
		var member: RefCounted = _party[i]
		if member == null or member.fainted:
			continue
		var amount: int = award if i == _active_index else share
		var levels_gained: int = member.gain_xp(amount, cfg)
		last_xp_award[member.label()] = {"xp": amount, "levels": levels_gained}

	var winner := active_creature()
	if winner != null:
		winner.gain_bond(int(cfg.get("bond", {}).get("battle_won", 0)), cfg)


## D30's bond a freshly caught creature starts with. Split out of `_finish_catch`'s
## success branch so this exact rule is reachable on its own, without the rest
## of catch resolution's staged VFX/camera machinery.
func _apply_catch_bond(caught: RefCounted) -> void:
	if caught == null:
		return
	var cfg: Dictionary = PROGRESSION.config()
	caught.gain_bond(int(cfg.get("bond", {}).get("successful_catch_start", 0)), cfg)


## Movement is the dodge. The creature is driven straight from the stick, in camera
## space, exactly like the trainer — and is rooted while attacking.
func _drive_player_creature() -> void:
	if _ally_body == null:
		return
	if _action != Action.READY:
		return
	# Aiming abandons your creature. It stops taking stick input while you line up the
	# throw and the opponent does not stop attacking it — that is the entire cost
	# of catching, and without it throwing is free and the correct play is to
	# throw constantly between attacks.
	if bool(_throw.call("is_aiming")):
		return

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		return
	var basis_value := Basis.IDENTITY
	if _camera_rig != null and _camera_rig.has_method("planar_basis"):
		basis_value = _camera_rig.call("planar_basis")
	_ally_body.call("request_move", basis_value * Vector3(input.x, 0.0, input.y))


func _read_player_input() -> void:
	var creature := active_creature()
	if creature == null:
		return

	# While aiming, throw_aim.gd owns the input: Run cancels the aim rather than
	# ending the fight, and the attack buttons release the orb. Reading them here
	# too would make one press do two things.
	if bool(_throw.call("is_busy")):
		return

	if Input.is_action_just_pressed("combat_run"):
		_begin_resolve("fled")
		return

	# Attack presses are RECORDED whatever state the creature is in, and fired by
	# `_consume_buffered_attack()` the moment it is ready. Throws stay
	# un-buffered: a throw is a deliberate mode change, and one that fires
	# half a second after the press feels like the game acting on its own.
	if Input.is_action_just_pressed("combat_charged"):
		_buffered_attack = "charged"
		_buffer_left = float(MATH.config().get("flow", {}).get("input_buffer", 0.3))
	elif Input.is_action_just_pressed("combat_quick"):
		_buffered_attack = "quick"
		_buffer_left = float(MATH.config().get("flow", {}).get("input_buffer", 0.3))

	if _action != Action.READY:
		return

	if Input.is_action_just_pressed("combat_throw"):
		_try_throw()


## Fire a buffered attack press once the creature is ready for it.
##
## Split from `_read_player_input` so a press made during recovery fires on the
## frame recovery ends rather than waiting for the next press. The charged
## branch consumes the buffer even when energy is short — a refused press
## should stay refused, not retry itself every frame until it surprises you.
func _consume_buffered_attack() -> void:
	if _action != Action.READY or _buffered_attack == "" or _input_guard > 0.0:
		return
	if bool(_throw.call("is_busy")):
		return
	var creature := active_creature()
	if creature == null:
		return

	if _buffered_attack == "charged":
		if _charged_cooldown > 0.0:
			return
		_buffered_attack = ""
		if creature.spend_charged():
			var charged: Dictionary = MATH.config().get("player_charged", {}).duplicate()
			charged["is_quick"] = false
			_start_action(charged)
			_charged_cooldown = float(charged.get("cooldown", 1.2))
		return

	if _quick_cooldown > 0.0:
		return
	_buffered_attack = ""
	var quick: Dictionary = MATH.config().get("player_quick", {}).duplicate()
	quick["is_quick"] = true
	_start_action(quick)
	_quick_cooldown = float(quick.get("cooldown", 0.45))


func _start_action(move: Dictionary) -> void:
	_pending_move = _with_reach_for_the_bodies(move)
	_action = Action.WINDUP
	_action_timer = float(move.get("windup", 0.18))
	# Face and lunge at the START of the wind-up, not at the strike. The lunge
	# used to fire on the same frame as the connect test, and an impulse only
	# changes velocity — position is integrated NEXT physics frame — so the
	# lunge could never help the swing that fired it; it was pure
	# follow-through, and the charged attack whiffed structurally against any
	# repositioning enemy. Applied here, it integrates across the whole
	# wind-up and genuinely closes the gap the test will be run over. The
	# animation starts here too, so the body moves when the motion does.
	if _ally_body != null and _wild != null:
		_ally_body.call("face_towards", _wild.call("centre"))
		_ally_body.call("add_impulse", _ally_body.call("facing"), float(_pending_move.get("lunge", 3.6)))
		_ally_body.call("play_attack")
	state_changed.emit()


## Floor a move's reach by the two creatures' actual sizes.
##
## Reach is measured centre to centre, and the configured 2.6m was written when
## every creature was the same capsule. Against a large opponent, two bodies
## that are merely touching are already further apart than that, so the player's
## attack whiffs at point-blank range — which reads as the game dropping the
## input, and is the single complaint most likely to end a playtest.
##
## The wild creature applies the same floor to its own attacks. Both sides space
## themselves by their bodies; both sides reach as far as they have spaced.
func _with_reach_for_the_bodies(move: Dictionary) -> Dictionary:
	if _ally_body == null or _wild == null:
		return move
	var mine := 0.5
	var theirs := 0.5
	if _ally_body.has_method("body_radius"):
		mine = float(_ally_body.call("body_radius"))
	if _wild.has_method("body_radius"):
		theirs = float(_wild.call("body_radius"))

	var clearance: float = float(MATH.config().get("enemy", {}).get("body_clearance", 1.35))
	var adjusted := move.duplicate()
	adjusted["range"] = maxf(float(move.get("range", 2.6)), (mine + theirs) * clearance + 0.5)
	return adjusted


## The wind-up's own visual event, independent of the "! incoming" banner
## text `combat_hud.gd` draws from `enemy_is_winding_up()`. `seconds` is the
## exact beat duration `wild_creature.gd` just entered, so the glow disappears on
## the same physics tick the strike actually lands rather than an approximate
## guess at it.
func _on_enemy_telegraph(seconds: float) -> void:
	var cfg: Dictionary = MATH.config().get("telegraph", {})
	if not bool(cfg.get("enabled", true)) or _wild == null:
		return
	var host: Node = _arena if _arena != null else _player.get_parent()
	TELEGRAPH_GLOW.begin(
		host,
		_wild.global_position,
		Color(str(cfg.get("colour", "#ff5a3c"))),
		float(cfg.get("radius", 1.1)),
		seconds
	)


## The opponent announces its swing when its wind-up completes; whether it
## connects is decided here, by the same arithmetic the player's attacks use.
func _on_enemy_strike() -> void:
	if state != State.ACTIVE:
		return
	var creature := active_creature()
	if creature == null or _enemy == null:
		return

	# The creature's OWN numbers, not the raw config: it spaces itself by how big
	# the two bodies are, and its reach grows with that spacing. Testing the
	# swing against the config's flat 2.6m while it stands further out than that
	# is a creature that walks to exactly where it can no longer hit anything.
	var cfg: Dictionary = _wild.call("combat_config") if _wild.has_method("combat_config") \
		else MATH.config().get("enemy", {})
	var origin: Vector3 = _wild.call("centre")
	var facing: Vector3 = _wild.call("facing")
	var target: Vector3 = _ally_body.call("centre")

	_wild.call("add_impulse", facing, float(cfg.get("lunge", 3.4)))
	_wild.call("play_attack")

	if not MATH.move_connects(cfg, origin, facing, target):
		attack_missed.emit(false)
		state_changed.emit()
		return

	# The wild AI has one attack, not a quick/charged pair (scripts/combat/
	# combat_ai.gd's Intent enum never branches on a move slot), so its own
	# `move_quick` id stands in for "whatever this creature just swung with".
	var damage: float = MATH.rolled_damage(
		float(cfg.get("power", 8.0)), _enemy.attack, creature.defence, _rng.randf(),
		_moves.power(_enemy.move_quick)
	)
	var killed: bool = creature.take_damage(damage)
	_ally_body.call("add_impulse", facing, float(cfg.get("lunge", 3.4)) * 0.4)
	_ally_body.call("play_faint" if killed else "play_hit")
	_flash_at(_ally_body.call("centre"), false)

	hit_landed.emit(false, damage)
	state_changed.emit()
	if killed:
		_begin_resolve("lost")


## A blow that landed has to look like one.
##
## The blind critic counted bright warm pixels at the moment of contact:
## `combat/05-quick-attack-lands` held ten of them, `palworld-01` held 24,623,
## and its summary of the beat was that the health bar got shorter and nothing
## else happened. Damage numbers are state; this is the event.
##
## Charged hits burst larger and warmer than quick ones. If the expensive move
## and the free one look the same, building energy was never worth doing.
func _flash_at(where: Vector3, charged: bool) -> void:
	var cfg: Dictionary = MATH.config().get("impact", {})
	if not bool(cfg.get("enabled", true)):
		return
	var key := "charged" if charged else "quick"
	var spec: Dictionary = cfg.get(key, {})
	# Parented into the WORLD, not to this manager. CombatManager is a plain
	# Node, and a Node3D hung under one is outside the 3D transform chain: the
	# burst was created correctly twelve times in a row and rendered none of
	# them. The arena is a Node3D that already exists for exactly the length of
	# the fight, so it also cleans these up on its way out.
	var host: Node = _arena if _arena != null else _player.get_parent()
	FLASH.burst(
		host,
		where,
		Color(str(spec.get("colour", "#ffd27a"))),
		float(spec.get("radius", 1.5)),
		float(spec.get("duration", 0.34)),
		float(spec.get("strength", 1.0))
	)


## --- catching -------------------------------------------------------------

## Legality is checked before the aim opens, not after the orb lands.
##
## §15 says a faint ENDS the capture opportunity. That is a refusal, not a very
## low chance, and telling the player before they spend an orb and a vulnerable
## second of aiming is the difference between a rule and a punishment.
func _try_throw() -> void:
	if _enemy == null:
		return
	var allowed: bool = CATCH.can_be_caught(_enemy.fainted, false)
	_throw.call("try_begin_aim", allowed, "%s is out cold — too late to catch it" % _enemy.display_name)
	state_changed.emit()


func _on_orb_struck(_target: Node3D, offset: float) -> void:
	if state != State.ACTIVE or _enemy == null:
		return

	# Re-checked at the moment of impact as well as before the aim: the opponent
	# can faint to your creature's attack while the orb is still in the air, and an
	# orb that lands on a corpse must not catch it.
	if not CATCH.can_be_caught(_enemy.fainted, false):
		catch_refused.emit("%s fainted before the orb landed" % _enemy.display_name)
		_throw.call("clear_orb")
		_take_camera()
		state_changed.emit()
		return

	var radius := 0.5
	if _wild != null and _wild.has_method("body_radius"):
		radius = float(_wild.call("body_radius"))

	# The decision, made once. Everything after this dramatises it.
	#
	# R4.9: the orb id has to be the one `throw_aim.gd` actually SPENT for
	# this throw, not whatever tier is best right now — the satchel already
	# lost that orb by the time the strike resolves, and re-querying "best
	# available" here could silently price a greater-orb throw at the basic
	# multiplier (or vice versa) if the two ever disagree.
	var decision: Dictionary = CATCH.resolve(
		SPECIES.catch_rate(_enemy.species_id),
		_enemy.hp_fraction(),
		str(_throw.call("thrown_orb_id")),
		offset,
		radius,
		_rng.randf()
	)
	_catch_succeeded = bool(decision["caught"])
	_catch_shakes_total = int(decision["shakes"])
	_catch_index = 0

	# The performance: a flash says the throw landed, the creature is drawn in
	# toward the hanging orb, and the camera starts its glide into the close-up
	# the rest of the sequence plays through. The old presentation was
	# `_wild.visible = false` — one frame, no event, and a HUD label counting
	# dots. Everything else about "catching is still bad" starts there.
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	var absorb := float(cfg.get("absorb_seconds", 0.45))
	var orb: Node3D = _throw.call("resting_orb")
	var strike_point: Vector3 = orb.global_position if orb != null \
		else (_wild.call("centre") if _wild != null else Vector3.ZERO)
	_catch_flash("strike", strike_point)
	if _wild != null and _wild.has_method("play_absorb"):
		_wild.call("play_absorb", strike_point, absorb)
	elif _wild != null:
		_wild.visible = false
	# The "this is your opponent" marker has no opponent to mark while the
	# creature is in the orb; left on, it floats over empty grass all wobble.
	if _target_marker != null and is_instance_valid(_target_marker):
		_target_marker.visible = false
	_watch_the_orb(orb)

	_catch_phase = CatchPhase.ABSORB
	# The orb hangs for `absorb` and then has to fall; the timeout is a backstop
	# for a strike over ground the drop raycast never finds, not the schedule.
	_catch_timer = absorb + 2.5
	state_changed.emit()


func _on_orb_missed() -> void:
	if state != State.ACTIVE:
		return
	# A clean miss is not a failed catch. It costs an orb and the moment, and it
	# gets its own message, because "you missed" and "it broke out" are different
	# things to have just done.
	catch_refused.emit("the orb went wide")
	_take_camera()
	state_changed.emit()


## A cancelled aim hands the camera straight back to the creature. A released throw
## keeps the aim camera — watching your own orb arc away is the shot — and
## `_on_orb_struck` / `_on_orb_missed` decide where it goes next.
func _on_aim_exited() -> void:
	if state != State.ACTIVE:
		return
	if bool(_throw.call("is_busy")):
		return
	_take_camera()


func _tick_catch_resolution(delta: float) -> void:
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	_catch_timer -= delta

	match _catch_phase:
		CatchPhase.ABSORB:
			# Wait for the orb to actually be on the ground; the first shake of
			# an orb still falling would read as the animation firing early.
			var orb: Node3D = _throw.call("resting_orb")
			var rested: bool = orb != null and bool(orb.call("is_resting"))
			if rested or _catch_timer <= 0.0:
				_catch_phase = CatchPhase.WAIT
				_catch_timer = float(cfg.get("first_shake_delay", 0.9))
		CatchPhase.WAIT:
			if _catch_timer <= 0.0:
				_catch_phase = CatchPhase.SHAKING
				_catch_timer = 0.0
		CatchPhase.SHAKING:
			if _catch_timer > 0.0:
				return
			if _catch_index < _catch_shakes_total:
				_catch_index += 1
				var orb: Node3D = _throw.call("resting_orb")
				if orb != null and orb.has_method("shake"):
					orb.call("shake", _catch_index)
				orb_shook.emit(_catch_index)
				_catch_timer = float(cfg.get("shake_interval", 0.85))
				return
			# All shakes performed. The held breath before the verdict — this
			# pause existed in config from the start and was silently ignored:
			# the verdict used to land on the same frame as the final shake.
			_catch_phase = CatchPhase.VERDICT
			_catch_timer = float(cfg.get("settle_pause", 0.8))
		CatchPhase.VERDICT:
			if _catch_timer <= 0.0:
				_finish_catch()


func _finish_catch() -> void:
	_catch_phase = CatchPhase.NONE
	var cfg: Dictionary = CATCH.config().get("resolve", {})
	var orb: Node3D = _throw.call("resting_orb")

	if _catch_succeeded:
		# D30: a caught creature starts with a bond head start rather than at zero,
		# same as GAME_DESIGN.md's read that catching is itself an act of
		# trust. `_enemy` IS what `caught_instance()` will hand the director in
		# a moment, so setting it here is setting it on the instance that
		# actually joins the party.
		_apply_catch_bond(_enemy)
		# The seal: the orb blooms warm and stays glowing, the camera stays on
		# it through the fight's resolve pause, and the orb is only freed with
		# the rest of the fight in `_finish()`.
		if orb != null:
			if orb.has_method("seal"):
				orb.call("seal")
			_catch_flash("caught", orb.global_position)
		catch_resolved.emit(true, _catch_index)
		_begin_resolve(OUTCOME_CAUGHT)
		return

	# It broke out: a sharper, whiter burst covers the orb vanishing, and the
	# creature pops back to full size with a shove — an event, not a toggle.
	# No free damage either way: the cost of a failed catch is the orb and the
	# seconds you spent standing still, which is quite enough.
	if orb != null:
		_catch_flash("breakout", orb.global_position)
	_throw.call("clear_orb")
	if _wild != null:
		if _wild.has_method("play_breakout"):
			_wild.call("play_breakout", float(cfg.get("breakout_pop_seconds", 0.35)))
		else:
			_wild.visible = true
		if _ally_body != null:
			var away: Vector3 = _wild.global_position - _ally_body.global_position
			_wild.call("add_impulse", away, 2.5)
		# Re-engage from scratch: the creature takes the same "read the
		# situation" beat it takes when a fight opens (`first_attack_delay`)
		# instead of swinging on the frame it reappears.
		_wild.call("set_engaged", true, _ally_body)
	if _target_marker != null and is_instance_valid(_target_marker):
		_target_marker.visible = true
	_take_camera()
	catch_resolved.emit(false, _catch_index)
	state_changed.emit()


## Point the camera at the resting orb for the resolution close-up. The rig
## glides rather than cuts (`resolve_camera.retarget_lag`), so the shot arrives
## while the orb is still dropping and settles with it.
func _watch_the_orb(orb: Node3D) -> void:
	if orb == null or _camera_rig == null or not _camera_rig.has_method("set_target"):
		return
	_camera_rig.call("set_target", orb, CATCH.config().get("resolve_camera", {}))


## One of the catch's three flashes (catching.json `vfx`): strike, caught,
## breakout. Same impact_flash.gd primitive the attacks use, so it reads on
## both renderers and advances on the physics clock.
func _catch_flash(key: String, at: Vector3) -> void:
	var spec: Dictionary = CATCH.config().get("vfx", {}).get(key, {})
	if spec.is_empty():
		return
	var host: Node = _arena if _arena != null else _player.get_parent()
	FLASH.burst(
		host,
		at,
		Color(str(spec.get("colour", "#ffd27a"))),
		float(spec.get("radius", 1.2)),
		float(spec.get("duration", 0.35)),
		float(spec.get("strength", 1.0))
	)


## The instance the player just caught, for the director to keep. Valid only
## between `catch_resolved(true, ...)` and the end of the fight.
func caught_instance() -> RefCounted:
	return _enemy if _outcome == OUTCOME_CAUGHT else null


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

	_throw.call("disarm")
	if _ally_body != null:
		_ally_body.visible = false
		_ally_body.set("arena", null)
	# Freed with the arena it was parented to; only the stale reference needs
	# clearing here.
	_target_marker = null
	if _arena != null:
		_arena.queue_free()
		_arena = null
	_release_camera()

	exited.emit(_outcome)
	state_changed.emit()


## --- switching (D32) --------------------------------------------------------
##
## Voluntary mid-combat switching. LOGIC ONLY here — the header comment has
## named `_active_index` into `_party` as this seam since M2, and this is that
## later milestone. No input is read here and no selector is drawn: a future
## HUD milestone binds `combat_switch_left`/`combat_switch_right` (tap cycles,
## hold opens the party strip, D32) to the functions below.
##
## There is no auto-switch-on-faint (D32's own "what was deliberately not
## built") — a faint of the active creature still ends the fight exactly as it
## always has. This only ever fires from the player's own choice.

## Party indices, in `_party` order, that are alive and not the one currently
## piloted — what a switch selector has to offer.
func switchable_indices() -> Array[int]:
	var out: Array[int] = []
	for i in _party.size():
		if i == _active_index:
			continue
		var member: RefCounted = _party[i]
		if member != null and not member.fainted:
			out.append(i)
	return out


## Is a voluntary switch allowed RIGHT NOW? Mirrors the guards the fight
## already applies elsewhere: aiming owns the controls (`_drive_player_creature`'s
## own comment), a resolving catch pauses the whole fight
## (`is_resolving_catch`'s own comment), and `player_is_committed()` refuses
## it mid-swing — switching out from under a wind-up would refund the very
## commitment a charged attack is supposed to cost. The lockout stops a tap
## being spammed into a stutter of creatures.
func can_switch() -> bool:
	return is_fighting() \
		and not is_aiming() \
		and not is_resolving_catch() \
		and not player_is_committed() \
		and _switch_lockout <= 0.0


## The next (`direction > 0`) or previous (`direction < 0`) switchable party
## member from the active one, wrapping around the whole party order and
## skipping fainted members. Delegates to `request_switch` so cycling and any
## future direct-pick selector share one path in and one set of guards.
func cycle_active(direction: int) -> bool:
	var size := _party.size()
	if size < 2:
		return false
	var step: int = 1 if direction >= 0 else -1
	var i := _active_index
	for _n in size - 1:
		i = ((i + step) % size + size) % size
		var member: RefCounted = _party[i]
		if member != null and not member.fainted:
			return request_switch(i)
	return false


## Switch the piloted creature to party index `index`. Guarded rather than
## clamped: an illegal request is refused outright (returns false), never
## partially applied.
func request_switch(index: int) -> bool:
	if not can_switch():
		return false
	if index < 0 or index >= _party.size() or index == _active_index:
		return false
	var member: RefCounted = _party[index]
	if member == null or member.fainted:
		return false

	_activate_party_member(index)
	_switch_lockout = float(MATH.config().get("switch", {}).get("lockout_seconds", 1.5))
	creature_switched.emit(index)
	state_changed.emit()
	return true


## The body-swap core. Re-points `_active_index` at `index` and, if the
## incoming creature is a different species from whatever `_ally_body` is
## currently wearing, re-skins that SAME body through `setup()` — the
## identical call `encounter_director._spawn_ally_body()` makes for a brand
## new creature. There is deliberately only one piloted body in a fight (M2's "one
## of yours" scope never grew a second one), so a switch re-casts it rather
## than instancing another; the incoming creature takes over at the exact position
## and facing the old body already had, because that body never moved.
##
## The switched-OUT creature keeps its hp/energy exactly as the fight left them —
## no reset, no heal; only the piloted identity changes. Action/cooldown state
## resets to READY because it belongs to whichever creature is being piloted, and
## it is safe to zero here: `can_switch()`'s `player_is_committed()` guard
## already refused this call unless the fight was between actions.
func _activate_party_member(index: int) -> void:
	var incoming: RefCounted = _party[index]
	_active_index = index

	if _ally_body != null and str(_ally_body.get("species_id")) != incoming.species_id:
		_ally_body.call("setup", incoming.species_id)

	_action = Action.READY
	_action_timer = 0.0
	_pending_move = {}
	_quick_cooldown = 0.0
	_charged_cooldown = 0.0
	_buffered_attack = ""
	_buffer_left = 0.0


## --- readouts for the HUD -------------------------------------------------
##
## The HUD asks; it is never pushed to. A HUD that keeps its own copy of the
## fight can disagree with the fight, and the first time that happens it costs
## an afternoon.

func quick_ready() -> bool:
	return _action == Action.READY and _quick_cooldown <= 0.0


func charged_ready() -> bool:
	var creature := active_creature()
	return creature != null and creature.can_use_charged() \
		and _action == Action.READY and _charged_cooldown <= 0.0


## True while the player's creature is committed and cannot move.
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


func is_aiming() -> bool:
	return _throw != null and bool(_throw.call("is_aiming"))


func orbs_left() -> int:
	return int(_throw.call("stock")) if _throw != null else 0


## R4.9: which orb tier a throw right now would actually use — the HUD's own
## orb cluster reads this so it never names/shows a tier the player is not
## about to spend.
func current_orb_id() -> String:
	return str(_throw.call("current_orb_id")) if _throw != null else "orb_basic"


## True from the orb striking to the verdict. The fight is paused around it:
## neither fighter acts, because a creature landing a hit on an orb that is
## deciding whether it caught something is nonsense. (The wild creature's own physics
## is off for the duration — it is inside the orb.)
func is_resolving_catch() -> bool:
	return _catch_phase != CatchPhase.NONE


## The odds a clean, dead-centre hit would resolve at RIGHT NOW, for the aim
## HUD. Purely a readout of the same arithmetic the throw will use — telling
## the player their odds before they spend an orb is the answer to "I never
## know if I was close", front half. (The shake count is the back half.)
func catch_chance_now() -> float:
	if _enemy == null:
		return 0.0
	var radius := 0.5
	if _wild != null and _wild.has_method("body_radius"):
		radius = float(_wild.call("body_radius"))
	return CATCH.catch_chance(
		SPECIES.catch_rate(_enemy.species_id), _enemy.hp_fraction(), current_orb_id(), 0.0, radius
	)


## Where the two fighters are, for anything that needs to frame them.
func arena_focus() -> Vector3:
	if _ally_body != null and _wild != null:
		return (_ally_body.global_position + _wild.global_position) * 0.5
	if _player != null:
		return _player.global_position
	return Vector3.ZERO
