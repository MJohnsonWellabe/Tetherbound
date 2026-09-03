extends "res://scripts/creatures/creature_body.gd"

## A wild creature: peaceful in the world, an opponent in a fight.
##
## Peaceful is deliberate. GAME_DESIGN.md §14 requires that proximity never
## starts a fight with a peaceful creature, so this node will turn to look at you and
## stop wandering while you are close, and that is the whole of its reaction.
## Starting the fight is always the player pressing a button.
##
## In combat it runs scripts/combat/combat_ai.gd. The decisions live there and
## can be unit-tested; what lives here is measuring the situation, running the
## clocks, and turning an intent into movement.

const AI := preload("res://scripts/combat/combat_ai.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")

signal fainted()
## An aggressive creature has closed on the trainer and is starting the fight itself.
## GAME_DESIGN.md §14 lists "Aggressive creature initiates" alongside the player's own
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

## WORLD-LIFE-0903. Optional: `Callable(pos: Vector3) -> bool`, true when `pos`
## is a fine place to wander to. Unset (the default) for every wild creature
## that has ever existed -- the plain disc pick below is unchanged for them.
## `encounter_director.gd` hands one in for a band1 route cluster whose
## `wander_radius` was widened enough to reach the road (BAND1_ROUTE_CONTRACT.md:
## herds and water-edge clusters now cross or graze beside it), because a
## wider disc can otherwise land a destination standing on the painted trail
## itself -- band1's road is only ~1.8m either side of its own centreline,
## well inside a 20m wander disc. This node has no idea what a "road" is and
## is not going to learn; it only ever asks the callback yes/no.
var _clearance_check: Callable = Callable()

## Aggression. A creature that will start a fight on its own, per GAME_DESIGN.md
## pillar 3 and §14. Peaceful creatures are untouched by all of this: §14's "not
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

## OWNER PLAYTEST 2026-09-02 finding #6: "aiming at the creature is too hard...
## they should move a little less or in slow motion once you go into catch
## mode." `combat_manager.gd` owns the aim window (`throw_aim.gd::is_aiming()`)
## and has no reason to know this creature's movement internals, so it tells
## this node with `set_catch_aim_active()` every physics tick instead — the
## same shape as `set_engaged()`. Scoped to THIS creature (the one being aimed
## at) rather than a global slow-mo: a global time dilation would also slow the
## player's own throw and the rest of the fight's pacing, which the owner never
## asked for. `_catch_aim_slowdown_scale` is TUNABLE — see catching.json's
## `aim.target_slowdown_scale`.
var _catch_aim_active: bool = false
var _catch_aim_slowdown_scale: float = 0.35

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_rng.randomize()
	home = global_position
	_target = home
	_pause_left = _rng.randf_range(_pause_min, _pause_max)
	_combat_cfg = MATH.config().get("enemy", {})
	_catch_aim_slowdown_scale = float(
		CATCH.config().get("aim", {}).get("target_slowdown_scale", _catch_aim_slowdown_scale))


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

## Consecutive physics frames the chase has requested movement without the
## body actually making progress — a static prop's collider (a scattered
## tree, a rock) pins the body in place with the request still aimed straight
## through it. `LP7`: found by instrumenting a real failing run — the creature's
## own position and velocity stayed exactly fixed for 900 straight frames
## while it kept requesting movement toward the player, with a
## `CommonTree_4_Collision` StaticBody3D confirmed overlapping it every
## frame. Not a design obstacle (the meadow is meant to be open ground), so
## routing around it rather than tuning collision layers is the scoped fix.
var _stuck_frames: int = 0
var _stuck_check_pos: Vector3 = Vector3.ZERO
const UNSTICK_AFTER_FRAMES := 20  # ~0.33s at 60Hz — long enough not to trigger on normal accel ramp-up
const UNSTICK_STEER_RAD := 1.3  # ~75 degrees off the direct line, enough to clear most single-prop snags

## `verify-aggression`, 2026-08-17: the steer-only escape above does not clear
## every snag. Caught directly with `velocity`/`is_on_wall()` on a live failing
## run: `is_on_wall() == true`, `velocity == (0,0,0)`, `stuck_frames` climbing
## past 800 while the steer alternated sides every 30 frames the whole time —
## the collision response was cancelling ALL horizontal movement regardless of
## the requested angle, at ordinary walkable ground (same shape of false
## `Terrain3D` wall this test's own header documents for the PLAYER's walk near
## this same slope). Steering direction cannot fix a block that is not
## direction-dependent. After a full steer cycle has had a real chance (both
## sides, several times over) and still made zero net progress, nudge the body
## directly past the false contact — bypassing `move_and_slide`'s collision
## response for one frame — rather than let it sit dead for the rest of the
## chase. Small enough not to skip past the player or through real geometry;
## only fires this rarely, so a slight visual pop on the very rare stuck frame
## is a fair trade against a chase that silently never arrives.
const HARD_UNSTICK_AFTER_FRAMES := 140  # ~2.3s of steering tried and failed
const HARD_UNSTICK_NUDGE := 0.35  # metres

## Steers around, then nudges past, a static collider `requested_dir` runs
## straight through -- the LP7 mechanism above, factored out so `_tick_combat`
## can use it too. GATE-F-LEG-S04's trainer-round auto-switch made a lost
## round run five party members deep instead of ending on the first faint,
## which is long enough for the wild AI to walk a REPOSITION arc into a spot
## the direct line back to CLOSE range cannot clear -- caught live via
## `smoke_tournament_bracket.gd`: `dist` frozen bit-for-bit for 2600+ straight
## frames in `Intent.CLOSE` with `cooldown`/`beat_left` both already at zero,
## the same frozen-position signature LP7 documents, just in the one movement
## path (`_tick_combat`) that never called this. A single-hit fight never ran
## long enough to reach it.
func _unstick(requested_dir: Vector3) -> Vector3:
	if global_position.distance_to(_stuck_check_pos) < 0.05:
		_stuck_frames += 1
	else:
		_stuck_frames = 0
	_stuck_check_pos = global_position

	var dir := requested_dir
	if _stuck_frames > UNSTICK_AFTER_FRAMES:
		# Pinned against something the direct line runs straight through.
		# Steer off it rather than keep requesting the same blocked
		# direction forever. A single fixed angle was not enough on its
		# own — verified over 15 local runs, it cut the failure rate but
		# did not close it, because the first escape angle can itself run
		# into more of the same obstacle (a tree's collision shape is not
		# a point). Alternating sides every half second gives it more than
		# one candidate gap to find rather than committing to a direction
		# that might be blocked too.
		var phase := int((_stuck_frames - UNSTICK_AFTER_FRAMES) / 30.0) % 2
		var side := _side_sign if phase == 0 else -_side_sign
		dir = dir.rotated(Vector3.UP, side * UNSTICK_STEER_RAD)

		if _stuck_frames > HARD_UNSTICK_AFTER_FRAMES:
			global_position += dir * HARD_UNSTICK_NUDGE
			_stuck_frames = 0
			_stuck_check_pos = global_position
	return dir


func _tick_aggression(delta: float) -> bool:
	if _player == null or not is_alive():
		_stuck_frames = 0
		return false

	var notice := float(_aggro_cfg.get("notice_range", 14.0))
	var engage := float(_aggro_cfg.get("engage_range", 3.2))
	var give_up := float(_aggro_cfg.get("give_up_distance", 26.0))

	if OS.has_environment("DEBUG_AGGRO") and Engine.get_physics_frames() % 60 == 0:
		print("[DBG %s] pos=%s home=%s player=%s notice=%.1f engage=%.1f grace=%.2f returning=%s dist3d=%.2f" % [
			name, global_position, home, _player.global_position, notice, engage, _grace_left, _returning_home,
			global_position.distance_to(_player.global_position)
		])

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
		_stuck_frames = 0
		return false

	face_towards(_player.global_position)
	if to_player.length() > engage:
		var chase_dir := _unstick(to_player.normalized())

		if OS.has_environment("DEBUG_AGGRO") and Engine.get_physics_frames() % 30 == 0:
			print("[DBG2 %s] to_player_len=%.2f chase_dir=%s vel=%s is_on_wall=%s is_on_floor=%s stuck_frames=%d" % [
				name, to_player.length(), chase_dir, velocity, is_on_wall(), is_on_floor(), _stuck_frames
			])

		request_move(chase_dir, float(_aggro_cfg.get("chase_speed", 3.4)))
		return true

	# Close enough. Announced once, not every frame — the director may refuse
	# (a fight is already running, the player's creature has fainted) and this must
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


## Retries against `_clearance_check` the same shape `encounter_director.gd`'s
## own `_pick_clear_spot()` already uses for the initial scatter -- a handful
## of attempts from the SAME per-instance `_rng` (never seeded, so this was
## never part of the world's determinism promise), falling back to the last
## candidate rather than freezing in place if every attempt lands on the road.
const WANDER_CLEAR_ATTEMPTS := 8

func _pick_destination() -> Vector3:
	var candidate := home
	for attempt in WANDER_CLEAR_ATTEMPTS:
		var angle := _rng.randf_range(0.0, TAU)
		var distance := _rng.randf_range(1.0, _wander_radius)
		candidate = home + Vector3(sin(angle), 0.0, cos(angle)) * distance
		if not _clearance_check.is_valid() or bool(_clearance_check.call(candidate)):
			return candidate
	return candidate


## See `_clearance_check`'s own comment. A no-op call for every wild creature
## the director does not opt in.
func set_clearance_check(check: Callable) -> void:
	_clearance_check = check


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
		# Fresh combat starts fresh stuck-tracking, not whatever the chase that
		# led here last measured -- `_unstick`'s distance check compares against
		# `_stuck_check_pos`, and a stale value from across the engage boundary
		# would either falsely flag the first CLOSE frame as pinned or hide a
		# real one behind a leftover "just moved" reading.
		_stuck_frames = 0
		_stuck_check_pos = global_position
	else:
		_intent = AI.Intent.IDLE
		_pause_left = _rng.randf_range(_pause_min, _pause_max)
		_target = global_position
		arena = null
		_has_announced = false
		_returning_home = false
		_grace_left = float(_aggro_cfg.get("grace_after_combat", 8.0))
		_catch_aim_active = false


func _tick_combat(delta: float) -> void:
	if not is_alive() or _opponent == null:
		return

	_cooldown = maxf(0.0, _cooldown - delta)
	_beat_left = maxf(0.0, _beat_left - delta)

	var to := _opponent.global_position - global_position
	to.y = 0.0
	var distance := to.length()

	var next: int = AI.decide(_intent, distance, _beat_left, _cooldown, _spaced_config())
	if next != _intent:
		_enter(next)
		# Entering a beat can end the fight underneath us: a completed wind-up
		# emits `strike_ready`, the manager resolves the blow synchronously, and
		# if that blow knocks out the player's creature it disengages this creature
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
		var speed := AI.speed_for(_intent, _combat_cfg)
		if _catch_aim_active:
			speed *= _catch_aim_slowdown_scale
		request_move(_unstick(direction), speed)
	else:
		# Rooted on purpose (TELEGRAPH/RECOVER) is not stuck -- without this the
		# stillness `_unstick`'s own distance check reads as "pinned" the moment
		# CLOSE/REPOSITION resumes, since the body legitimately did not move
		# while rooted. Reset here so the count only ever measures continuous
		# movement-intent frames, never a beat that was never trying to move.
		_stuck_frames = 0
		_stuck_check_pos = global_position


## The numbers this creature is actually fighting with, spacing included.
##
## Public because the combat manager resolves the strike and has to test against
## the same reach the creature positioned itself for. Reading the raw config
## there while this one stands further out is a creature that walks to exactly
## where it can no longer hit anything.
func combat_config() -> Dictionary:
	return _spaced_config()


## The combat config, with `preferred_range` floored by how big the two
## creatures actually are.
##
## The configured 2.1m is centre to centre, and it was written when every
## creature was the same capsule. With real models it is smaller than the pair's
## own bodies: a Triceratops fitted to a 0.72m collider renders well over a
## metre to each side, and a frog adds its own. So the opponent walked to 2.1m
## and stopped with its head inside the other creature's flank — which the blind
## critic found in five of seven combat frames, in one case with antlers coming
## out of the other creature's back.
##
## Floored rather than replaced: the config still decides how much breathing
## room a fight wants, and this only refuses to let it be less than the two
## bodies occupy. A large creature stands further out than a small one for the
## same reason a person does.
func _spaced_config() -> Dictionary:
	if _opponent == null:
		return _combat_cfg
	var mine: float = body_radius()
	var theirs: float = float(_opponent.call("body_radius")) if _opponent.has_method("body_radius") else 0.5
	var floor_at: float = (mine + theirs) * float(_combat_cfg.get("body_clearance", 1.35))

	var preferred: float = maxf(float(_combat_cfg.get("preferred_range", 2.1)), floor_at)
	var spaced := _combat_cfg.duplicate()
	spaced["preferred_range"] = preferred
	# Reach grows with the spacing, or the creature stands exactly where it can
	# no longer hit anything and whiffs forever. Two bodies further apart are
	# further apart at the SURFACE by the same amount, so the swing that used to
	# connect still does.
	spaced["range"] = maxf(float(_combat_cfg.get("range", 2.6)), preferred + 0.5)
	spaced["reposition_distance"] = maxf(float(_combat_cfg.get("reposition_distance", 5.0)), preferred + 2.4)
	return spaced


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


## Told every physics tick by `combat_manager.gd` (mirroring `throw_aim.gd`'s
## own `is_aiming()`), not read here directly — this node has no reference to
## the throw and no reason to gain one. A no-op outside `_tick_combat` (a
## peaceful creature is never the aim target), so a stray true left over from
## a fight that has already ended costs nothing.
func set_catch_aim_active(value: bool) -> void:
	_catch_aim_active = value


func is_winding_up() -> bool:
	return engaged and _intent == AI.Intent.TELEGRAPH


func is_rooted() -> bool:
	return engaged and AI.is_rooted(_intent)


func intent() -> int:
	return _intent


## --- lifecycle ------------------------------------------------------------

## Knocked out. It stays where it fell, slumped, and only vanishes later.
##
## GAME_DESIGN.md §15: "Fainted wild creatures remain visible temporarily but cannot
## be captured." That is not decoration. Over-damaging a creature is how you lose a
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


## Put it back on its feet at its home point. M2 only: a wild creature that stays
## fainted means one fight per session, and the entire question this milestone
## asks is whether the owner wants another one.
func revive_at_home() -> void:
	if instance != null:
		instance.heal_fully()
	visible = true
	rotation = Vector3.ZERO
	set_physics_process(true)
	revive_animation()
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
