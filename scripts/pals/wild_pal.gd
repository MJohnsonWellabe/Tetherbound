extends "res://scripts/pals/pal_body.gd"

## A wild creature: peaceful in the world, an opponent in a fight.
##
## Peaceful is deliberate. GAME_DESIGN.md §14 requires that proximity never
## starts a fight with a peaceful pal, so this node will turn to look at you and
## stop wandering while you are close, and that is the whole of its reaction.
## Starting the fight is always the player pressing a button.
##
## In combat it runs scripts/combat/combat_ai.gd. The decisions live there and
## can be unit-tested; what lives here is measuring the situation, running the
## clocks, and turning an intent into movement.

const AI := preload("res://scripts/combat/combat_ai.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")

signal fainted()
## An aggressive pal has closed on the trainer and is starting the fight itself.
## GAME_DESIGN.md §14 lists "Aggressive pal initiates" alongside the player's own
## ways in; this is that path. The director decides whether it may proceed.
signal wants_to_engage()
## Emitted when the wind-up finishes and the blow should be resolved. The
## manager owns damage, so the creature announces the swing and does not decide
## whether it connected.
signal strike_ready()
signal telegraph_started(seconds: float)

## Live state. The combat manager reads this off the node by name; it is the one
## piece of a creature that has to survive being knocked out.
var instance: RefCounted = null

var home: Vector3 = Vector3.ZERO
var engaged: bool = false

var _wander_radius: float = 7.0
var _wander_speed: float = 1.4
var _notice_range: float = 9.0
var _pause_min: float = 1.5
var _pause_max: float = 4.0

var _player: Node3D = null
var _target: Vector3 = Vector3.ZERO
var _pause_left: float = 0.0

## Aggression. A creature that will start a fight on its own, per GAME_DESIGN.md
## pillar 3 and §14. Peaceful pals are untouched by all of this: §14's "not
## simple proximity" rule is scoped to them, and they still only ever fight when
## the player presses a button.
var aggressive: bool = false
var _aggro_cfg: Dictionary = {}
var _grace_left: float = 0.0
var _has_announced: bool = false
var _returning_home: bool = false

## Combat state.
var _opponent: Node3D = null
var _intent: int = AI.Intent.IDLE
var _beat_left: float = 0.0
var _cooldown: float = 0.0
var _side_sign: float = 1.0
var _combat_cfg: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_rng.randomize()
	home = global_position
	_target = home
	_pause_left = _rng.randf_range(_pause_min, _pause_max)
	_combat_cfg = MATH.config().get("enemy", {})


## Give it a species and a live instance in one call, so a caller cannot end up
## with a body that has no health.
func populate(id: String, player: Node3D) -> bool:
	setup(id)
	_player = player
	instance = SPECIES.spawn(id)
	aggressive = SPECIES.is_aggressive(id)
	_aggro_cfg = CATCH.config().get("aggression", {})
	return instance != null


func is_alive() -> bool:
	return instance != null and not instance.fainted


func _physics_process(delta: float) -> void:
	if engaged:
		_tick_combat(delta)
	elif is_alive():
		_tick_peaceful(delta)
	# The body integrates whatever was requested above. Calling super LAST is
	# required: request_move is cleared every frame by design, so a request made
	# after integration would be thrown away.
	super(delta)


## --- peaceful -------------------------------------------------------------

func _tick_peaceful(delta: float) -> void:
	_grace_left = maxf(0.0, _grace_left - delta)

	if aggressive and _tick_aggression(delta):
		return

	var watching := _player != null \
		and global_position.distance_to(_player.global_position) <= _notice_range
	if watching:
		# Stops and looks at you. This is the only cue the game gives that the
		# creature is engageable, and it is why the placeholder has a face.
		face_towards(_player.global_position)
		return
	_wander(delta)


## Close on the trainer and start the fight. Returns true when it has taken over
## this frame, so the peaceful behaviour below it is skipped.
##
## Deliberately thin — notice, close, initiate. No stalking, no growl phase, no
## standing your ground. Those are a behaviour system; this is a flag and a
## chase, and it is enough to find out whether being ambushed is fun before
## building the rest.
func _tick_aggression(delta: float) -> bool:
	if _player == null or not is_alive():
		return false

	var notice := float(_aggro_cfg.get("notice_range", 14.0))
	var engage := float(_aggro_cfg.get("engage_range", 3.2))
	var give_up := float(_aggro_cfg.get("give_up_distance", 26.0))

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var from_home := global_position.distance_to(home)

	# Chased too far. Without this it follows you across the whole meadow and
	# the only way out of an ambush is to win it, which is not danger, it is a
	# corridor.
	if _returning_home or from_home > give_up:
		_returning_home = true
		var back := home - global_position
		back.y = 0.0
		if back.length() < 1.5:
			_returning_home = false
			return false
		face_towards(home)
		request_move(back.normalized(), float(_aggro_cfg.get("chase_speed", 3.4)) * 0.7)
		return true

	# Just fought. Being re-engaged the instant a fight ends is a soft lock, not
	# a threat.
	if _grace_left > 0.0 or to_player.length() > notice:
		_has_announced = false
		return false

	face_towards(_player.global_position)
	if to_player.length() > engage:
		request_move(to_player.normalized(), float(_aggro_cfg.get("chase_speed", 3.4)))
		return true

	# Close enough. Announced once, not every frame — the director may refuse
	# (a fight is already running, the player's pal has fainted) and this must
	# not spam the signal while it waits.
	if not _has_announced:
		_has_announced = true
		wants_to_engage.emit()
	return true


func _wander(delta: float) -> void:
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_target = _pick_destination()
		return

	var to := _target - global_position
	to.y = 0.0
	if to.length() < 0.5:
		_pause_left = _rng.randf_range(_pause_min, _pause_max)
		return
	request_move(to.normalized(), _wander_speed)


func _pick_destination() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var distance := _rng.randf_range(1.0, _wander_radius)
	return home + Vector3(sin(angle), 0.0, cos(angle)) * distance


## --- combat ---------------------------------------------------------------

## Called by the combat manager when a fight opens and closes.
func set_engaged(value: bool, opponent: Node3D = null) -> void:
	engaged = value
	_opponent = opponent
	if value:
		_combat_cfg = MATH.config().get("enemy", {})
		_intent = AI.Intent.CLOSE
		_beat_left = 0.0
		# It does not swing the instant the fight opens; the player gets a beat
		# to read the situation.
		_cooldown = float(_combat_cfg.get("first_attack_delay", 1.5))
		_side_sign = 1.0 if _rng.randf() < 0.5 else -1.0
	else:
		_intent = AI.Intent.IDLE
		_pause_left = _rng.randf_range(_pause_min, _pause_max)
		_target = global_position
		arena = null
		_has_announced = false
		_returning_home = false
		_grace_left = float(_aggro_cfg.get("grace_after_combat", 8.0))


func _tick_combat(delta: float) -> void:
	if not is_alive() or _opponent == null:
		return

	_cooldown = maxf(0.0, _cooldown - delta)
	_beat_left = maxf(0.0, _beat_left - delta)

	var to := _opponent.global_position - global_position
	to.y = 0.0
	var distance := to.length()

	var next: int = AI.decide(_intent, distance, _beat_left, _cooldown, _combat_cfg)
	if next != _intent:
		_enter(next)
		# Entering a beat can end the fight underneath us: a completed wind-up
		# emits `strike_ready`, the manager resolves the blow synchronously, and
		# if that blow knocks out the player's pal it disengages this creature
		# and clears `_opponent` before the call returns. Everything below reads
		# `_opponent`, so it has to be re-checked rather than trusted from the
		# guard at the top of the function.
		if not engaged or _opponent == null:
			return

	# It always faces its target, even while rooted. Facing is how the player
	# reads what it is about to do, and a creature that winds up while pointing
	# somewhere else is telegraphing a lie.
	face_towards(_opponent.global_position)

	var direction := AI.movement_for(_intent, to, _side_sign)
	if direction != Vector3.ZERO:
		request_move(direction, AI.speed_for(_intent, _combat_cfg))


func _enter(intent: int) -> void:
	var previous := _intent
	_intent = intent
	_beat_left = AI.duration_for(intent, _combat_cfg)

	if intent == AI.Intent.TELEGRAPH:
		telegraph_started.emit(_beat_left)
	elif previous == AI.Intent.TELEGRAPH:
		# The wind-up just completed, so the blow lands now. Whether it connects
		# is the manager's call, not this creature's.
		strike_ready.emit()
		_cooldown = float(_combat_cfg.get("attack_cooldown", 1.1))
	elif intent == AI.Intent.REPOSITION:
		# One coin flip per reposition rather than one per frame, so it commits
		# to going around one side instead of jittering on the spot.
		_side_sign = 1.0 if _rng.randf() < 0.5 else -1.0


func is_winding_up() -> bool:
	return engaged and _intent == AI.Intent.TELEGRAPH


func is_rooted() -> bool:
	return engaged and AI.is_rooted(_intent)


func intent() -> int:
	return _intent


## --- lifecycle ------------------------------------------------------------

## Knocked out. It stays where it fell, slumped, and only vanishes later.
##
## GAME_DESIGN.md §15: "Fainted wild pals remain visible temporarily but cannot
## be captured." That is not decoration. Over-damaging a pal is how you lose a
## catch, and a creature that simply disappears the instant it faints never
## shows you the chance you just destroyed — the body on the ground is the
## feedback for the mistake.
func notify_fainted() -> void:
	var cfg: Dictionary = CATCH.config().get("faint", {})
	rotation.x = deg_to_rad(float(cfg.get("slump_degrees", 72.0)))
	set_physics_process(false)
	fainted.emit()


## Clear the body away, once the loss has had time to register.
func clear_faint() -> void:
	visible = false
	rotation.x = 0.0


## Put it back on its feet at its home point. M2 only: a wild pal that stays
## fainted means one fight per session, and the entire question this milestone
## asks is whether the owner wants another one.
func revive_at_home() -> void:
	if instance != null:
		instance.heal_fully()
	visible = true
	rotation = Vector3.ZERO
	set_physics_process(true)
	set_engaged(false)
	place_on_ground(home)
	_target = home
	_pause_left = _rng.randf_range(_pause_min, _pause_max)
	_returning_home = false
	_has_announced = false
	_grace_left = 0.0


func configure(cfg: Dictionary) -> void:
	_wander_radius = float(cfg.get("wander_radius", _wander_radius))
	_wander_speed = float(cfg.get("wander_speed", _wander_speed))
	_notice_range = float(cfg.get("notice_range", _notice_range))
	_pause_min = float(cfg.get("pause_min", _pause_min))
	_pause_max = float(cfg.get("pause_max", _pause_max))
