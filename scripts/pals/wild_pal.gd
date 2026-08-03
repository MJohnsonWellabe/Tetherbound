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

signal fainted()
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
	var watching := _player != null \
		and global_position.distance_to(_player.global_position) <= _notice_range
	if watching:
		# Stops and looks at you. This is the only cue the game gives that the
		# creature is engageable, and it is why the placeholder has a face.
		face_towards(_player.global_position)
		return
	_wander(delta)


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

func notify_fainted() -> void:
	visible = false
	fainted.emit()


## Put it back on its feet at its home point. M2 only: a wild pal that stays
## fainted means one fight per session, and the entire question this milestone
## asks is whether the owner wants another one.
func revive_at_home() -> void:
	if instance != null:
		instance.heal_fully()
	visible = true
	set_engaged(false)
	place_on_ground(home)
	_target = home
	_pause_left = _rng.randf_range(_pause_min, _pause_max)


func configure(cfg: Dictionary) -> void:
	_wander_radius = float(cfg.get("wander_radius", _wander_radius))
	_wander_speed = float(cfg.get("wander_speed", _wander_speed))
	_notice_range = float(cfg.get("notice_range", _notice_range))
	_pause_min = float(cfg.get("pause_min", _pause_min))
	_pause_max = float(cfg.get("pause_max", _pause_max))
