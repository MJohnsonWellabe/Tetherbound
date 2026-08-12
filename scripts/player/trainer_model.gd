extends "res://scripts/characters/character_model.gd"

## The trainer's body and its animation.
##
## The loading, fitting and clip-merging all live in the base class now, because
## Grandpa needs exactly the same thing done to exactly the same rig. What is
## left here is the only part that is about the TRAINER: deciding what his body
## should be doing from what the controller is doing.
##
## Reads state rather than being told about it — the same arrangement as the
## combat HUD. A body that keeps its own idea of whether it is running can
## disagree with the character that is running.

@export var player_path: NodePath

var _player: CharacterBody3D = null
## Set while the trainer is aiming a throw, so the body reads as throwing rather
## than as standing still watching its pal be hit.
var _throwing_for: float = 0.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if not build("trainer"):
		# The scene's capsule stays visible, so a missing trainer is a trainer
		# that looks wrong rather than a trainer who is not there.
		push_error("no trainer model; falling back to the placeholder capsule")


func _process(delta: float) -> void:
	if animation_player() == null or _player == null:
		return
	_throwing_for = maxf(0.0, _throwing_for - delta)
	# Only the throw is a committed one-shot (timed by _throwing_for); idle,
	# walk, sprint and jump are all states the trainer can hold indefinitely
	# and must loop — see character_model.gd's play() for why that matters.
	var role := _role_for_state()
	play(_clip_for_role(role), _throwing_for <= 0.0)
	# OF5: gait cadence tracks how fast the body is actually covering ground,
	# not the one speed the clip was baked at. No-op (resets to 1x) for every
	# non-gait role — see character_model.gd's match_gait_rate().
	match_gait_rate(role, _player.call("ground_speed"))


## What the trainer's body should be doing, from what the trainer is doing.
func _role_for_state() -> String:
	if _throwing_for > 0.0:
		return "throw"
	if not _player.is_on_floor():
		return "jump"

	var speed: float = _player.call("ground_speed")
	if speed < 0.4:
		return "idle"
	return "sprint" if bool(_player.call("is_sprinting")) else "walk"


func _clip_for_role(role: String) -> String:
	# The throw's fallback predates the authored clip set; every other role
	# falls back to a clip of its own name, jump to idle.
	match role:
		"throw":
			return clip_for("throw", "pick-up")
		"jump":
			return clip_for("jump")
		_:
			return clip_for(role, role)


## Called when a throw is released, so the body commits to the animation for its
## duration rather than for exactly one frame.
func play_throw(seconds: float = 0.6) -> void:
	_throwing_for = seconds
