extends RefCounted

## Drives a creature's animation from what the creature is doing.
##
## Owned by creature_body, which already knows its own speed, and poked by combat for
## the things speed cannot tell you — an attack, a hit taken, a faint.
##
## Clip names come from data, never from code. Every pack names its clips
## differently: the shipped creatures use `Armature|Frog_Attack` and
## `Armature|Triceratops_Run`, and the trainer's library uses `Idle_A` and
## `Throw`. Hard-coding any of that would mean a new creature cannot be added
## without editing this file, which is exactly what `species.json` exists to
## avoid.
##
## One-shots beat the loop. An attack or a death has to finish; locomotion is
## what plays when nothing more important is happening.

## Roles the game asks for. A creature missing one falls back to something it
## does have rather than freezing, because a pack with no `walk` is common and a
## motionless creature is worse than a slightly wrong one.
const IDLE := "idle"
const WALK := "walk"
const RUN := "run"
const ATTACK := "attack"
const HIT := "hit"
const FAINT := "faint"

## Below this, a creature is standing still.
const STILL_SPEED := 0.35
## Above this fraction of its top speed, it is running rather than walking.
const RUN_FRACTION := 0.55

var _player: AnimationPlayer = null
var _clips: Dictionary = {}
var _current: String = ""
## Seconds left of a one-shot that must not be interrupted by locomotion.
var _hold: float = 0.0
## Set once a creature has fainted, so nothing plays over its death.
var _finished := false


func _init(animation_player: AnimationPlayer, clips: Dictionary) -> void:
	_player = animation_player
	_clips = clips


func is_ready() -> bool:
	return _player != null


## Locomotion, from the body's own speed. Called every frame; ignored while a
## one-shot is holding.
func tick(delta: float, speed: float, top_speed: float) -> void:
	if _player == null or _finished:
		return
	_hold = maxf(0.0, _hold - delta)
	if _hold > 0.0:
		return

	if speed < STILL_SPEED:
		_play(IDLE, true)
	elif top_speed > 0.0 and speed > top_speed * RUN_FRACTION:
		_play(RUN, true)
	else:
		_play(WALK, true)


## Play a one-shot and hold locomotion off until it finishes.
func play_once(role: String) -> void:
	if _player == null or _finished:
		return
	var clip := _resolve(role)
	if clip == "":
		return
	_hold = _player.get_animation(clip).length
	_play(role, false)


## A faint is final: it plays once and nothing plays after it, so a creature
## does not stand back up into its idle two seconds after being knocked out.
func play_faint() -> void:
	if _player == null:
		return
	play_once(FAINT)
	_finished = true


func revive() -> void:
	_finished = false
	_hold = 0.0
	_current = ""


## W12-COMPANION-0904. Play `role` once IF this rig has a clip for it (its own
## or a fallback), and say whether it did. The companion-presence layer asks
## for clips by role ("hit" as a flinch, "attack" as a roar) without knowing
## the rig, and a role the pack lacks must cost nothing rather than freeze the
## pose -- `play_once` already refuses an unknown role silently; this is the
## same call with an answer, so a caller can substitute procedural motion.
func play_if_exists(role: String) -> bool:
	if _player == null or _finished:
		return false
	if _resolve(role) == "":
		return false
	play_once(role)
	return true


## A one-shot hold is presentation for a moment nothing more important is
## happening — but "nothing more important" stops being true the instant
## something asks this creature to move under its own power again. Recorded
## with a real fight (`tools/diag_combat_animation.gd`, R4.11): a wild
## creature hit mid-chase keeps closing distance the very next physics frame
## (its AI's CLOSE intent does not pause for being hit), so the body was
## visibly sliding across the arena for the rest of the hit clip's length
## while the pose stayed frozen on the hit reaction — 23.8% of sampled
## frames in one fight. `request_move` calls this whenever it is given a real
## direction, so a creature already back under way is never shown standing
## still for a pose that finished being true.
func cancel_hold() -> void:
	_hold = 0.0


func _play(role: String, looping: bool) -> void:
	var clip := _resolve(role)
	if clip == "" or clip == _current:
		return
	_current = clip
	var animation := _player.get_animation(clip)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	# Cross-faded. A creature that snaps between idle and run reads as broken
	# even when the states are right.
	_player.play(clip, 0.15)


## Find a clip for a role, falling back rather than failing.
##
## A pack with no walk cycle is ordinary — the shipped frog has only idle,
## attack, death and jump. Falling back to idle keeps it animating; returning
## nothing would freeze it mid-pose and look like a crash.
func _resolve(role: String) -> String:
	var wanted := str(_clips.get(role, ""))
	if wanted != "" and _player.has_animation(wanted):
		return wanted
	for alternative in _fallbacks(role):
		var clip := str(_clips.get(alternative, ""))
		if clip != "" and _player.has_animation(clip):
			return clip
	return ""


func _fallbacks(role: String) -> Array[String]:
	match role:
		RUN:
			return [WALK, IDLE]
		WALK:
			return [RUN, IDLE]
		HIT:
			return [IDLE]
		ATTACK:
			return [IDLE]
		FAINT:
			return [IDLE]
		_:
			return []
