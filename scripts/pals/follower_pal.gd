extends "res://scripts/pals/pal_body.gd"

## The player's pal, walking behind them in the world.
##
## Before this, the player's pal existed only inside a fight: the encounter
## director instanced a body, set `visible = false`, and turned it on when
## combat opened. This inverts that. GAME_DESIGN.md's pillar 2 is that the five
## become emotionally important, and a creature that only exists while you are
## hitting something with it is a weapon, not a companion (docs/decisions/D12
## says the same thing about scale).
##
## It writes no locomotion of its own. Everything here decides a direction and a
## speed and hands both to `pal_body.request_move()`, which is the same call the
## combat AI and the player's own stick go through — so a following pal walks up
## the same hills, at the same acceleration, with the same animation blending as
## a fighting one.
##
## It stops following while a fight is running, because the combat manager is
## driving the same body. Two things calling `request_move` on one creature in
## one frame is one of them silently losing.

## Beyond this the pal has been left behind by something the game did rather than
## by the player walking — a fight that ended across the meadow, a fall, a
## teleport. It gives up and reappears near the trainer rather than jogging back
## across the biome.
const LEASH := 45.0


var leader: Node3D = null

var _following: bool = false
## Metres. Kept well clear of the trainer's own capsule: a follower that stands
## on top of the player is a follower that shoves the camera around.
var _stop_distance: float = 3.0
var _resume_distance: float = 4.0
var _run_distance: float = 8.0
var _walk_speed: float = 3.0
var _run_speed: float = 5.6
## True while it is closing the gap. Hysteresis: without it the pal oscillates
## between "close enough" and "too far" on the boundary and jitters in place.
var _closing: bool = false


func configure_following(cfg: Dictionary) -> void:
	_stop_distance = float(cfg.get("stop_distance", _stop_distance))
	_resume_distance = float(cfg.get("resume_distance", _resume_distance))
	_run_distance = float(cfg.get("run_distance", _run_distance))
	_walk_speed = float(cfg.get("walk_speed", _walk_speed))
	_run_speed = float(cfg.get("run_speed", _run_speed))


func set_following(value: bool) -> void:
	_following = value
	_closing = false
	# Off every physics layer while following, so it can never wall the trainer
	# in. It only re-closes the gap once past `_stop_distance` and has no idea
	# whether "close enough" also means "standing in the way" — reversing
	# direction on foot leaves it briefly ahead rather than behind, and two
	# solid CharacterBody3D capsules aimed straight at each other simply stop
	# dead. Confirmed as the real, intermittent cause of RB3's
	# smoke_aggression.gd failure (a frozen trainer 60-70m short, never a
	# pathing or aggression-timing bug). Restored once combat takes over,
	# because `wild_pal.gd`'s `_spaced_config()` keeps the two fighters apart
	# by real collision, not just by distance math, and dropping that turned
	# up as a *different* flake in `smoke_catching.gd` ("the pal moved 4.04m
	# on the stick while aiming") the first time this was tried scoped wider,
	# to the whole lifetime of the body rather than just the following state.
	collision_layer = 0 if value else 1


func is_following() -> bool:
	return _following


func _physics_process(delta: float) -> void:
	if _following:
		_tick_follow()
	# The body integrates whatever was requested above. Calling super LAST is
	# required: `request_move` is cleared every frame by design, so a request
	# made after integration would be thrown away. Same rule as wild_pal.gd.
	super(delta)


func _tick_follow() -> void:
	if leader == null or not is_instance_valid(leader):
		return

	var to := leader.global_position - global_position
	to.y = 0.0
	var distance := to.length()

	if distance > LEASH:
		# Never a raycast — docs/decisions/D09. `place_on_ground` asks the world
		# first and only falls back to a ray for things the terrain does not know
		# about.
		place_on_ground(leader.global_position - leader.global_basis.z * _stop_distance)
		_closing = false
		return

	if _closing:
		_closing = distance > _stop_distance
	else:
		_closing = distance > _resume_distance

	if not _closing:
		# Standing with you rather than staring past you.
		face_towards(leader.global_position)
		return

	var speed := _run_speed if distance > _run_distance else _walk_speed
	request_move(to / maxf(distance, 0.001), speed)
