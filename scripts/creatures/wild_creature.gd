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
const UTILITY_EFFECTS := preload("res://scripts/combat/utility_effects.gd")
var _landed_utility_state: Dictionary = {}
var _utility_clock_ms := 0.0
var _ultimate_reaction_left := 0.0
const CATCH := preload("res://scripts/combat/catch_math.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const LUNGE_LANE := preload("res://scripts/combat/lunge_lane.gd")
const PATTERN_CUE := preload("res://scripts/combat/enemy_pattern_telegraph.gd")

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
## F04: an opted-in CHARGER's charge has left the ground. `strike_ready` follows
## when it stops -- on contact, at its full length, or against an obstacle.
signal lunge_started(heading: Vector3, distance: float)
## F10#2: a `route_cue_seconds` phase began (the tell proper follows, with
## `telegraph_started`). A host relays it so a guest's proxy draws the route.
signal route_cue_started(seconds: float)
## F22#0: an observed player commitment caused a dodge or a punish tell.
## Presentation/proof only; it decides nothing.
signal pattern_reacted(kind: String)

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
## An opt-in named attack is picked at the start of its tell, then retained
## through its recovery.  The manager reads this same frozen row at impact, so
## a player never sees one move and is hit by another after a retarget or
## profile refresh.
var _selected_attack: Dictionary = {}
var _selected_attack_attempts: int = 0
var _selected_heading_locked: bool = false
var _move_db: RefCounted = null
var _patterns: Dictionary = {}
var _pattern_context: Dictionary = {}
var _pattern_observer: Callable
var _pattern_cursor := 0
var _pattern_geometry: Dictionary = {}
var _pattern_cue: Node3D
var _pattern_observed := ""
var _pattern_observed_s := 0.0
var _pattern_dodge_left := 0.0
var _pattern_punish: Dictionary = {}
var _pattern_repeat_left := 0
var _pattern_repeating := false
var _pattern_leap_active := false
var _pattern_leap_elapsed := 0.0
var _pattern_leap_duration := 0.45
var _pattern_leap_model_y := 0.0
var _poise: float = 0.0
var _poise_quiet_left: float = 0.0
var _poise_resist_left: float = 0.0
## Host-authored pool size mirrored onto a guest stand-in (sync_poise).
var _synced_poise_max: float = -1.0
var _staggered: bool = false
var _stagger_critical_ready: bool = false

## F04 travelling lunge (combat.json `charger_lunge`). Only a body whose
## per-member override sets `lunge_travels` ever sets any of these; every other
## opponent strikes at the end of its wind-up exactly as before.
##
## The wind-up tracks the target for the first part of the tell, then the
## heading locks and a lane of the configured `lunge` length is on the ground.
## When the tell ends the body really runs down that lane (the body's own
## `begin_combat_burst`, the same capped, collision-respecting displacement the
## player's burst uses). It stops on contact with its target, at the lane's end,
## or against terrain/obstacles, and only then emits `strike_ready`; the
## manager reads `take_lunge_outcome()` and lands the blow only on contact.
var _lunge_active := false
var _lunge_heading := Vector3.ZERO
var _lunge_origin := Vector3.ZERO
var _lunge_distance := 0.0
var _lunge_speed := 0.0
var _lunge_heading_locked := false
var _lunge_outcome: Dictionary = {}
var _lunge_lane: Node3D = null
## F10#2: seconds left in a `route_cue_seconds` phase before the tell proper.
var _route_cue_left := 0.0
## F10#2: the `guard_stance` frontal cone drawn for the current tell.
var _guard_cone: MeshInstance3D = null
var _lunge_tell_total := 0.0
## Host tick (ms) the current tell proper became visible; -1 when none.
var _tell_visible_since_ms := -1

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

## G-2 (docs/specs/GATE3_ENCOUNTER_CONTRACTS.md): this body's per-encounter
## behaviour override, merged OVER `combat.json`'s `enemy` block for this body
## alone. Empty means today's behaviour byte for byte, which is the contract's
## own failure condition -- "fails if any ordinary wild creature's fight changes
## when the block is absent" -- and is why this merges rather than replaces.
##
## Why it exists: before G-2 every opponent in the game fought out of the ONE
## global `enemy` block. Wild bramblebun, relay picket, Sigil captain and the
## Warden all shared a brain and differed only in level and roster, so a
## "memorable, not standard fight + HP" guardian (prompt 63) or a Warden with a
## "recognizable combat identity, not simply the largest numbers" (prompt 69)
## could not be authored at all. `burrow_warrens.json`'s guardian documented a
## signature Earth Fist chosen for being dodgeable; it only ever reached a
## player who CAUGHT it, because `combat_manager.gd` reads `move_charged`
## through a player-side profile and the wild AI never looks at it.
##
## Set by whoever spawns the body, from data that already exists: a
## `spawns.json` alpha/elder block, `burrow_warrens.json`'s guardian block, or a
## trainer team member in `trainers.json`. Never inherited -- a fresh body
## starts empty, so an override cannot leak onto a creature that did not author
## one, which is the contract's other failure condition.
##
## `combat_ai.gd::decide()` stays pure and is untouched: this changes the
## numbers it is handed, not how it thinks. No new intent, no charged-move AI.
var combat_override: Dictionary = {}

## W23-DIFFICULTY (D77). True for a body a TRAINER sent out, set by
## `encounter_director._send_out_next_creature()` beside `combat_override`.
## It selects `combat.json`'s optional `enemy_trainer` overlay in
## `_enemy_config_for_this_body()`: a drilled creature fights with a shorter
## first beat and a tighter cadence than a field animal of the same species,
## which is the baseline the owner measured as soft ("beating other trainers is
## way too easy") and the one thing the G-2 per-member override could not say
## for the 25 of 31 trainers that author no block at all. A wild body never
## sets this and is untouched; the per-member override still wins for every
## key it names, so the authored profiles (WALL, CHARGER...) are unchanged.
var trainer_owned: bool = false

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_rng.randomize()
	home = global_position
	_target = home
	_pause_left = _rng.randf_range(_pause_min, _pause_max)
	_combat_cfg = _enemy_config_for_this_body()
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


## F26 performance (`creature_physics_lod.json` far_wild_tick): a peaceful
## wild far from every trainer steps every `interval_ticks` with the elapsed
## time. Phase is spread by instance so far bodies do not all step together.
var _far_lod_far := false
var _far_lod_recheck := 0
var _far_lod_counter := -1
var _far_lod_elapsed := 0.0


func _physics_process(delta: float) -> void:
	_far_lod_elapsed += delta
	if _far_lod_hold():
		return
	delta = _far_lod_elapsed
	_far_lod_elapsed = 0.0
	slide_time_scale = delta / maxf(get_physics_process_delta_time(), 0.0001) if _far_lod_far else 1.0
	var before := global_position
	# Resting outside a fight may skip the floor sweep (creature_body.gd).
	rest_slide_skip_allowed = not engaged
	if engaged:
		_tick_combat(delta)
	elif is_alive():
		_tick_peaceful(delta)
	if engaged and not protected_heavy_committed() and (utility_movement_multiplier() <= 0.0 or _ultimate_reaction_left > 0.0):
		request_move(Vector3.ZERO)
		velocity.x = 0.0
		velocity.z = 0.0
		_impulse = Vector3.ZERO
	# The body integrates whatever was requested above. Calling super LAST is
	# required: request_move is cleared every frame by design, so a request made
	# after integration would be thrown away.
	super(delta)
	# F04: the charge is judged on where the body actually got to this step,
	# after collision, not where it was asked to go.
	if _lunge_active:
		_after_lunge_step(before, delta)
	if _pattern_leap_active:
		_after_pattern_leap_step(delta)


## True when this tick is skipped: the body is in far-LOD and it is not its
## turn. Any reason to step every tick ends far mode at once.
func _far_lod_hold() -> bool:
	var cfg: Dictionary = physics_lod_config().get("far_wild_tick", {})
	if not bool(cfg.get("enabled", false)) or engaged or aggressive or not is_alive() \
			or not _far_lod_allowed():
		_far_lod_far = false
		return false
	_far_lod_recheck -= 1
	if _far_lod_recheck <= 0:
		_far_lod_recheck = maxi(1, int(cfg.get("recheck_ticks", 15)))
		# No known trainer at all (a detached test body) is never "far".
		var nearest := _nearest_trainer_distance()
		_far_lod_far = is_finite(nearest) and nearest > float(cfg.get("distance_m", 40.0))
	if not _far_lod_far:
		return false
	var interval := maxi(1, int(cfg.get("interval_ticks", 3)))
	if _far_lod_counter < 0:
		_far_lod_counter = get_instance_id() % interval
	_far_lod_counter = (_far_lod_counter + 1) % interval
	return _far_lod_counter != 0


## Subclasses whose motion is not ordinary wandering opt out.
func _far_lod_allowed() -> bool:
	return true


func _nearest_trainer_distance() -> float:
	var nearest := INF
	if _player != null and is_instance_valid(_player):
		nearest = global_position.distance_to(_player.global_position)
	if is_inside_tree():
		for body: Node in get_tree().get_nodes_in_group(&"remote_trainer"):
			if body is Node3D and is_instance_valid(body):
				nearest = minf(nearest, global_position.distance_to((body as Node3D).global_position))
	return nearest


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


## The director refused this creature's engagement for now (the player is in
## a conversation or a trainer battle): ask again after `seconds` rather than
## standing beside the player announced and silent until they walk away.
func defer_engage(seconds: float) -> void:
	_has_announced = false
	_grace_left = maxf(_grace_left, seconds)


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


## `combat.json`'s `enemy` block with this body's own G-2 override laid over it.
##
## Only the `enemy` block's own keys are honoured. An unknown key is dropped
## rather than passed through: the override is authored in content data by a
## band lane, and a typo that silently became a live tuning value -- or a key
## that reached `combat_ai.gd` expecting a shape it does not have -- would be a
## content bug that presents as a physics bug. `_comment*` keys are skipped for
## the same reason every other config reader here skips them.
const _COMBAT_OVERRIDE_KEYS: Array[String] = [
	"power", "telegraph", "recovery", "attack_cooldown", "preferred_range",
	"chase_speed", "reposition_speed", "reposition_time", "reposition_distance",
	"lunge", "first_attack_delay", "cone_degrees", "range", "poise_max",
	"stagger_seconds",
	# Named attacks are deliberately an opt-in, scalar-only extension.  A zero
	# or absent cadence leaves every existing opponent on its one-attack path.
	"charged_every", "charged_telegraph", "charged_recovery",
	"charged_face_lock_fraction",
	# COMBAT §5: the fraction of an ordinary strike's tell after which its
	# heading locks. Absent or 0 keeps today's full-tell tracking.
	"face_lock_fraction",
	# F04: opt-in travelling lunge for a named CHARGER. Absent or false, the
	# body keeps the instantaneous strike and `lunge` stays an impulse.
	"lunge_travels",
	# F10#2 (BOSSES §7 Capacitor Alpha, DIVER): seconds of a visible route line
	# drawn BEFORE the ordinary tell. Absent or 0, the tell starts as before.
	"route_cue_seconds",
	# F10#2 (BOSSES §7 Crown Guardian, WALL): the "stationary frontal guard
	# stance" LOOK -- a frontal cone drawn on the ground for the tell, sized by
	# this body's own range and cone. Presentation only: no block, no damage
	# change (COMBAT: no shields). Absent or false, nothing is drawn.
	"guard_stance",
	# F14#0 C3: this body's strike tell starts the fight camera's wider swing
	# (combat_manager.gd::_wild_tell_swing). Presentation only.
	"tell_camera_swing",
	# F14#1 C3: the fight camera's body_clear ignores this body while its
	# travelling lunge runs (combat_manager.gd::_update_combat_body_clear, the
	# shared `ignore_lunging_foe` rule for one body). Presentation only.
	"camera_ignore_lunge",
	# F14#0 C3 (after COMBAT §5 contact spacing): the fight camera's neutral
	# composition yaw for this opponent, in degrees (combat_manager.gd::
	# _take_camera). A long body held nose to nose with the ally at its full
	# rendered separation needs a near side-on view to show both heads; 0 or
	# absent keeps combat.json's `camera.tracking.composition_yaw_deg`.
	# Presentation only.
	"camera_composition_yaw_deg",
	# F14#0 C3: the trainer steps aside next to the ally instead of at the
	# arena midpoint (combat_manager.gd::_stand_the_trainer_aside), which at
	# the spaced separation is the opponent's head. Presentation only.
	"camera_trainer_beside_ally",
]


func _enemy_config_for_this_body() -> Dictionary:
	var base: Dictionary = MATH.config().get("enemy", {})
	var trainer_overlay: Dictionary = MATH.config().get("enemy_trainer", {}) if trainer_owned else {}
	if combat_override.is_empty() and trainer_overlay.is_empty():
		# The overwhelmingly common path, and deliberately the SAME Dictionary
		# every creature in the game got before G-2 existed -- not a copy, so
		# there is no behaviour difference and no allocation to explain.
		return base
	var merged := base.duplicate(true)
	# Layered in this order on purpose: the trainer overlay is a BASELINE for
	# every trainer-owned body, and the per-member `combat` block is the
	# encounter's own voice, so the member's numbers must win for every key
	# both name. Same key whitelist for both, for the same typo-safety reason.
	for key: String in _COMBAT_OVERRIDE_KEYS:
		if trainer_overlay.has(key):
			merged[key] = trainer_overlay[key]
	for key: String in _COMBAT_OVERRIDE_KEYS:
		if combat_override.has(key):
			merged[key] = combat_override[key]
	return merged


## --- combat ---------------------------------------------------------------

## Re-read `combat_override` into the live fight. A no-op while not engaged --
## `set_engaged(true)` below reads it for itself.
##
## `set_engaged()` snapshots `_enemy_config_for_this_body()` once, when the fight
## opens, which is right for every authored override: `combat_override` is set
## before the body ever enters a fight and never moves again. §10's participant
## scaling is the one thing that moves it afterwards -- a second player joining
## shortens this creature's attack cooldown mid-fight (D112) -- and without this
## the new number would sit on the instance and never be read.
##
## Only the config is re-read. `_cooldown`, `_beat_left` and `_intent` are the
## swing already in flight and are deliberately left alone: the shorter cooldown
## takes effect from the NEXT swing, not by cutting short the one the player is
## currently reading.
func refresh_combat_profile() -> void:
	if engaged:
		_combat_cfg = _enemy_config_for_this_body()


## The director supplies authored identity and measured visible actions. The
## body owns selection, clocks and frozen geometry; it never decides damage.
func configure_patterns(patterns: Dictionary, context: Dictionary, observe: Callable) -> void:
	_patterns = patterns.duplicate(true) if patterns.get("runtime_enabled") == true else {}
	_pattern_context = context.duplicate(true)
	_pattern_observer = observe
	_pattern_cursor = 0
	_pattern_observed = ""
	_pattern_observed_s = 0.0
	_pattern_dodge_left = 0.0
	_pattern_punish.clear()
	_pattern_repeat_left = 0
	_pattern_repeating = false
	_clear_pattern_cue()
	_pattern_geometry.clear()


func pattern_geometry() -> Dictionary:
	return _pattern_geometry.duplicate(true)


func _current_pattern_context() -> Dictionary:
	var context := _pattern_context.duplicate(true)
	if instance != null:
		context["hp_fraction"] = float(instance.get("hp")) / maxf(1.0, float(instance.get("max_hp")))
		context["move_quick"] = str(instance.get("move_quick"))
		context["move_charged"] = str(instance.get("move_charged"))
	return context


func _pattern_profile() -> Dictionary:
	if _patterns.is_empty() or instance == null: return {}
	return AI.select_pattern(_patterns, _combat_cfg, _current_pattern_context(), _pattern_cursor)


func _clear_pattern_cue() -> void:
	if is_instance_valid(_pattern_cue): _pattern_cue.queue_free()
	_pattern_cue = null


func _exit_tree() -> void:
	_clear_pattern_cue()


func _update_pattern_geometry() -> void:
	if _pattern_geometry.is_empty() or _intent != AI.Intent.TELEGRAPH: return
	if not _selected_heading_is_locked():
		_pattern_geometry["heading"] = facing()
	var fraction := clampf(float(_selected_attack.get("marker_tracks_fraction", 0.5)), 0.0, 1.0)
	if _opponent != null and _beat_left > _lunge_tell_total * (1.0 - fraction):
		_pattern_geometry["marker"] = _tracked_pattern_marker()
	if is_instance_valid(_pattern_cue):
		_pattern_cue.call("aim", _pattern_geometry.origin, _pattern_geometry.heading, _pattern_geometry.marker)


func _begin_pattern_cue() -> void:
	_clear_pattern_cue()
	_pattern_geometry.clear()
	if not _selected_attack.has("pattern_attack_id") or _opponent == null: return
	_pattern_geometry = {"profile": _selected_attack.duplicate(true), "origin": global_position,
		"heading": facing(), "marker": _tracked_pattern_marker(), "body": self}
	# Travelling charges already own the same swept-width LungeLane cue.
	if is_inside_tree() and str(_selected_attack.get("telegraph_shape", "")) != "lane":
		_pattern_cue = PATTERN_CUE.begin(self, _selected_attack, global_position, facing(),
			_pattern_geometry.marker, _patterns.get("presentation", {}),
			Color(str(MATH.config().get("telegraph", {}).get("colour", "#ff5a3c"))))


func _tracked_pattern_marker() -> Vector3:
	var origin: Vector3 = _pattern_geometry.get("origin", global_position)
	var offset := _opponent.global_position - origin
	offset.y = 0.0
	var reach := maxf(0.0, float(_selected_attack.get("range", 0.0)))
	if offset.length() > reach: offset = offset.normalized() * reach
	return origin + offset


## A DIVER commits to the shown landing point. The existing collision-aware
## burst moves the body; a blocked arrival cannot damage the distant marker.
func _begin_pattern_leap() -> void:
	var offset: Vector3 = _pattern_geometry.marker - global_position
	offset.y = 0.0
	_pattern_leap_duration = maxf(0.01, float(_patterns.get("casts", {}).get("leap_travel_s", 0.45)))
	_pattern_leap_elapsed = 0.0
	_pattern_leap_model_y = _model.position.y if is_instance_valid(_model) else 0.0
	_pattern_leap_active = begin_combat_burst(offset, offset.length(), _pattern_leap_duration)
	play_attack()
	if not _pattern_leap_active: _finish_pattern_leap()


func _after_pattern_leap_step(delta: float) -> void:
	_pattern_leap_elapsed += delta
	if is_instance_valid(_model):
		var fraction := clampf(_pattern_leap_elapsed / _pattern_leap_duration, 0.0, 1.0)
		_model.position.y = _pattern_leap_model_y + sin(fraction * PI) * float(_patterns.get("casts", {}).get("leap_height_m", 0.75))
	if not combat_burst_active(): _finish_pattern_leap()


func _finish_pattern_leap() -> void:
	_pattern_leap_active = false
	if is_instance_valid(_model): _model.position.y = _pattern_leap_model_y
	var landing: Vector3 = _pattern_geometry.get("marker", global_position)
	_pattern_geometry["blocked"] = Vector2(landing.x - global_position.x, landing.z - global_position.z).length() > maxf(0.15, body_radius())
	_clear_pattern_cue()
	strike_ready.emit()


func _observe_pattern_reaction(delta: float) -> bool:
	_pattern_dodge_left = maxf(0.0, _pattern_dodge_left - delta)
	if _patterns.is_empty() or not _pattern_observer.is_valid(): return false
	var raw: Variant = _pattern_observer.call()
	if not raw is Dictionary: return false
	var observation: Dictionary = raw.duplicate(true)
	var label := str(observation.get("creature_uid", "")) + ":" + str(observation.get("action", "")) + ":" + str(observation.get("action_id", ""))
	_pattern_observed_s = _pattern_observed_s + delta if label == _pattern_observed else 0.0
	_pattern_observed = label
	observation["visible_for_s"] = _pattern_observed_s
	observation["dodge_cooldown_s"] = _pattern_dodge_left
	observation["attack_cooldown_s"] = _cooldown
	var reaction := AI.reaction(_intent, observation, _patterns)
	if reaction == "dodge":
		var cfg: Dictionary = _patterns.get("reactions", {})
		var role := AI.context_role(_patterns, _pattern_context)
		var key := "wild_dodge_cooldown_s" if not trainer_owned else (
			"mobile_trainer_dodge_cooldown_s" if role in ["DIVER", "CHARGER"] else "trainer_dodge_cooldown_s")
		_pattern_dodge_left = float(cfg.get(key, 6.0))
		_side_sign = float(observation.get("side_sign", 1.0))
		_enter(AI.Intent.DODGE)
		pattern_reacted.emit("dodge")
		return true
	if reaction == "punish":
		_pattern_punish = AI.punish_profile(_patterns, _combat_cfg, _current_pattern_context())
		if not _pattern_punish.is_empty():
			_enter(AI.Intent.TELEGRAPH)
			pattern_reacted.emit("punish")
			return true
	return false


## Called by the combat manager when a fight opens and closes.
func set_engaged(value: bool, opponent: Node3D = null) -> void:
	if not value:
		_landed_utility_state.clear()
		_utility_clock_ms = 0.0
		_ultimate_reaction_left = 0.0
	engaged = value
	_opponent = opponent
	# Engagement boundaries can occur while this body is stationary: ordinary
	# teardown calls false, while a failed catch breakout reactivates with true
	# directly after absorb suspended physics. Neither path may carry a timed
	# attack hold/rate across the boundary. cancel_hold preserves faint's final
	# `_finished` state.
	if _animator != null:
		_animator.call("cancel_hold")
	# A charge never survives an engagement boundary, and neither does its lane.
	_cancel_lunge()
	_lunge_outcome.clear()
	_pattern_observed = ""
	_pattern_observed_s = 0.0
	_pattern_dodge_left = 0.0
	_pattern_punish.clear()
	_pattern_repeat_left = 0
	_pattern_repeating = false
	if value:
		_combat_cfg = _enemy_config_for_this_body()
		_selected_attack.clear()
		_selected_attack_attempts = 0
		_selected_heading_locked = false
		_reset_poise()
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
		_selected_attack.clear()
		_selected_attack_attempts = 0
		_selected_heading_locked = false
		_staggered = false
		_stagger_critical_ready = false
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
	_utility_clock_ms += delta * 1000.0
	_ultimate_reaction_left = maxf(0.0, _ultimate_reaction_left - delta)
	# An already committed protected heavy still runs. Only this opponent's
	# issuance/movement pauses; other hosted opponents keep their own clocks.
	if _ultimate_reaction_left > 0.0 and not protected_heavy_committed(): return

	_cooldown = maxf(0.0, _cooldown - delta)
	# F04: the recovery beat starts when the charge stops, not when it starts,
	# so the punish window after a travelling lunge is the profile's full one.
	if not _lunge_active and not _pattern_leap_active:
		_beat_left = maxf(0.0, _beat_left - delta)
	_advance_route_cue(delta)
	_tick_poise(delta)
	if _pattern_leap_active: return
	if _staggered:
		if _beat_left <= 0.0:
			_staggered = false
			# The punish window ended. A new stagger must earn another break;
			# leaving zero poise here let every quick chain-lock the opponent.
			_poise = _poise_max()
			_poise_resist_left = float(_poise_config().get("break_resist_seconds", 0.0))
			_stagger_critical_ready = false
			_enter(AI.Intent.REPOSITION)
		else:
			face_towards(_opponent.global_position)
		return

	var to := _opponent.global_position - global_position
	to.y = 0.0
	var distance := to.length()

	var spaced := _spaced_config()
	var next: int = AI.decide(_intent, distance, _beat_left, _cooldown, spaced)
	if _observe_pattern_reaction(delta): next = _intent
	if next == AI.Intent.REPOSITION and _intent == AI.Intent.RECOVER and _pattern_repeat_left > 0:
		_pattern_repeat_left -= 1
		_pattern_repeating = true
		next = AI.Intent.TELEGRAPH
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

	# Ordinary attacks keep their live tracking.  A selected heavy attack locks
	# its heading through the latter half of the tell and recovery, so its shown
	# direction is the direction the host will actually test at impact.
	if _lunge_active:
		# The charge owns this body until it stops: no retargeting, no stepping.
		return
	if not _selected_heading_is_locked() and not _lunge_heading_is_locked():
		face_towards(_opponent.global_position)
	_aim_lunge_lane()
	_update_pattern_geometry()

	var waiting := distance <= float(spaced.get("preferred_range", 2.1))
	var direction := AI.movement_for(_intent, to, _side_sign, waiting)
	if utility_movement_multiplier() <= 0.0: direction = Vector3.ZERO
	if direction != Vector3.ZERO:
		var movement_profile := spaced.duplicate()
		if _intent == AI.Intent.DODGE: movement_profile.merge(_patterns.get("reactions", {}), true)
		var speed := AI.speed_for(_intent, movement_profile, waiting)
		speed *= utility_movement_multiplier()
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
	return _selected_attack if not _selected_attack.is_empty() else _spaced_config()


func protected_heavy_committed() -> bool:
	return _route_cue_left > 0.0 or ((_intent == AI.Intent.TELEGRAPH or _lunge_active or _pattern_leap_active) \
		and (_selected_attack.get("heavy") == true or _selected_attack.get("protected") == true \
		or _selected_attack.get("interruptible") == false))


func named_combat_target() -> bool:
	return trainer_owned or not str(get_meta(&"named_encounter_id", "")).is_empty() \
		or not str(get_meta(&"water_named_encounter", "")).is_empty() \
		or str(_pattern_context.get("pattern_id", "")).begins_with("named_")


## The one host HP writer calls this after a positive landed debit. Utility
## receipts and expiry use this opponent's clock, which pauses with hitstop.
func apply_landed_utility(move: Dictionary, context: Dictionary) -> bool:
	if move.get("move_id") != "snare" or not engaged or not is_alive(): return false
	if _landed_utility_state.is_empty():
		_landed_utility_state = UTILITY_EFFECTS.empty_state(str(context.get("encounter_id", "")), int(context.get("generation", 0)))
	var staged := UTILITY_EFFECTS.stage_application(_landed_utility_state, "snare", move,
		context, int(_utility_clock_ms), int(MATH.config().get("utility_limits", {}).get("receipt_limit_per_encounter", 4096)))
	if staged.get("ok") != true: return false
	_landed_utility_state = staged.state
	return true


func utility_movement_multiplier() -> float:
	var where := global_position if is_inside_tree() else position
	if instance == null: return 1.0
	var movement := UTILITY_EFFECTS.movement_multiplier(_landed_utility_state, str(instance.get("uid")), where, int(_utility_clock_ms))
	if preload("res://scripts/combat/tether_commands.gd").enabled():
		var snare := preload("res://scripts/combat/tether_commands.gd").snare_modifiers(get_meta(&"tether_snare", {}), str(instance.uid),
			int(get_meta(&"tether_body_generation", 0)), "", Time.get_ticks_msec())
		movement = minf(movement, float(snare.movement))
	return movement


func hold_ultimate_reaction(seconds: float) -> void:
	_ultimate_reaction_left = maxf(_ultimate_reaction_left, clampf(seconds, 0.0, 3.0))


func _selected_heading_is_locked() -> bool:
	if _selected_attack.is_empty() or _selected_heading_locked:
		return _selected_heading_locked
	if _intent != AI.Intent.TELEGRAPH:
		return false
	var fraction := clampf(float(_selected_attack.get("face_lock_fraction", 0.0)), 0.0, 1.0)
	if fraction <= 0.0:
		return false
	var total := maxf(0.001, float(_selected_attack.get("telegraph", 0.0)))
	if _beat_left <= total * (1.0 - fraction):
		_selected_heading_locked = true
	return _selected_heading_locked


func _select_attack() -> Dictionary:
	# Start before spacing.  The named geometry is then overlaid and this one
	# profile receives the damage-scale/reach adjustment exactly once.
	var profile := _combat_cfg.duplicate(true)
	var mine := body_radius()
	var theirs := float(_opponent.call("body_radius")) if _opponent != null and _opponent.has_method("body_radius") else 0.5
	var pattern := _pattern_punish if not _pattern_punish.is_empty() else _pattern_profile()
	_pattern_punish = {}
	if not pattern.is_empty():
		_pattern_cursor += 1
		_pattern_repeat_left = maxi(0, int(pattern.get("repeat_count", 1)) - 1)
		var selected := spaced_config_for(pattern, mine, theirs, _contact_need(), _contact_reach_need())
		if str(selected.get("telegraph_shape", "")) == "lane":
			selected["lane_half_width_m"] = _lunge_lane_half_width()
		return selected
	_selected_attack_attempts += 1
	var cadence := maxi(1, int(_combat_cfg.get("charged_every", 1)))
	if _selected_attack_attempts % cadence != 0:
		profile["move_id"] = str(instance.get("move_quick"))
		return spaced_config_for(profile, mine, theirs, _contact_need(), _contact_reach_need())
	var move_id := str(instance.get("move_charged"))
	if move_id.is_empty():
		profile["move_id"] = str(instance.get("move_quick"))
		return spaced_config_for(profile, mine, theirs, _contact_need(), _contact_reach_need())
	if _move_db == null:
		_move_db = MOVE_DB.new()
	var move: Dictionary = _move_db.move(move_id)
	if move.is_empty():
		profile["move_id"] = str(instance.get("move_quick"))
		return spaced_config_for(profile, mine, theirs, _contact_need(), _contact_reach_need())
	# Enemy power remains the authored absolute enemy value.  A named move only
	# contributes its multiplier at the existing damage roll, never player base
	# charged power.
	for key: String in ["range", "cone_degrees", "lunge"]:
		if move.has(key):
			profile[key] = float(move[key])
	profile["telegraph"] = maxf(1.1, float(_combat_cfg.get("charged_telegraph", move.get("windup", 0.0))))
	profile["recovery"] = maxf(0.6, float(_combat_cfg.get("charged_recovery", move.get("recovery", 0.0))))
	profile["move_id"] = move_id
	profile["face_lock_fraction"] = clampf(float(_combat_cfg.get("charged_face_lock_fraction", 0.0)), 0.0, 1.0)
	# Geometry is overlaid before the one spacing pass, so a large guardian's
	# Earth Fist retains both its authored arc and its valid body-clear reach.
	return spaced_config_for(profile, mine, theirs, _contact_need(), _contact_reach_need())


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
	if not _patterns.is_empty():
		if not _selected_attack.is_empty(): return _selected_attack
		var pattern := _pattern_profile()
		if not pattern.is_empty() and _opponent != null:
			var radius := float(_opponent.call("body_radius")) if _opponent.has_method("body_radius") else 0.5
			return spaced_config_for(pattern, body_radius(), radius, _contact_need(), _contact_reach_need())
	if _opponent == null:
		return _combat_cfg
	var mine: float = body_radius()
	var theirs: float = float(_opponent.call("body_radius")) if _opponent.has_method("body_radius") else 0.5
	return spaced_config_for(_combat_cfg, mine, theirs, _contact_need(), _contact_reach_need())


## COMBAT §5 contact spacing: the separation the two rendered bodies keep, as
## they stand (`preferred_range` floor) and at worst (the reach floor).
func _contact_need() -> float:
	return CONTACT_SPACING.pair_need(self, _opponent)


func _contact_reach_need() -> float:
	return CONTACT_SPACING.pair_reach_need(self, _opponent)


## The spacing arithmetic, static so tests/smoke_combat_baseline.gd fights with
## the SAME numbers a live body does rather than a copy of this function that
## drifts. `mine`/`theirs` are the two gameplay radii.
##
## W23-DIFFICULTY (D77): this is also where `enemy.damage_scale` lands.
## The G-2 profiles author ABSOLUTE `power` values against the 8.0 baseline
## (WALL 12.0, CURRENT 6.4, ACE 14.4), so raising `enemy.power` itself would
## have quietly inverted their shapes -- a CURRENT picket hitting softer than
## a field bramblebun. The scale multiplies AFTER the per-body merge, so every
## opponent in the chapter gets heavier by the same ratio and the profiles
## keep exactly the relationships the contract's table promises. It is NOT in
## `_COMBAT_OVERRIDE_KEYS`: no band file may author it, it is one chapter-wide
## number.
static func spaced_config_for(cfg: Dictionary, mine: float, theirs: float,
		contact_floor: float = 0.0, reach_floor: float = 0.0) -> Dictionary:
	# COMBAT §5: the rendered bodies' own separation (`contact_spacing.gd`)
	# floors the spacing as well, so a long body stands where the pair clears.
	var floor_at: float = maxf((mine + theirs) * float(cfg.get("body_clearance", 1.35)), contact_floor)

	var preferred: float = maxf(float(cfg.get("preferred_range", 2.1)), floor_at)
	var spaced := cfg.duplicate()
	spaced["preferred_range"] = preferred
	# Reach grows with the spacing, or the creature stands exactly where it can
	# no longer hit anything and whiffs forever. Two bodies further apart are
	# further apart at the SURFACE by the same amount, so the swing that used to
	# connect still does.
	spaced["range"] = maxf(maxf(float(cfg.get("range", 2.6)), preferred + 0.5), reach_floor + 0.5)
	spaced["reposition_distance"] = maxf(float(cfg.get("reposition_distance", 5.0)), preferred + 2.4)
	spaced["power"] = float(cfg.get("power", 8.0)) * float(cfg.get("damage_scale", 1.0))
	return spaced


func _enter(intent: int) -> void:
	var previous := _intent
	_intent = intent
	if intent != AI.Intent.TELEGRAPH:
		# A route cue or guard cone belongs to one tell and never outlives it.
		_route_cue_left = 0.0
		_hide_guard_cone()
		if not (previous == AI.Intent.TELEGRAPH and intent == AI.Intent.RECOVER \
			and str(_selected_attack.get("telegraph_shape", "")) == "marker"):
			_clear_pattern_cue()
	var named_enabled := (not _patterns.is_empty() or int(_combat_cfg.get("charged_every", 0)) > 0) and instance != null
	if intent == AI.Intent.TELEGRAPH and _pattern_repeating:
		_pattern_repeating = false
		_selected_attack["telegraph"] = float(_selected_attack.get("repeat_telegraph_s", _selected_attack.get("telegraph", 1.1)))
		_selected_attack["recovery"] = float(_selected_attack.get("repeat_recovery_s", _selected_attack.get("recovery", 0.6)))
		_selected_heading_locked = false
		_beat_left = float(_selected_attack.telegraph)
	elif intent == AI.Intent.TELEGRAPH and named_enabled:
		_selected_attack = _select_attack()
		_selected_heading_locked = false
		_beat_left = float(_selected_attack.get("telegraph", AI.duration_for(intent, _combat_cfg)))
	elif intent == AI.Intent.TELEGRAPH:
		_selected_attack.clear()
		# COMBAT §5: an ordinary strike that authors `face_lock_fraction` keeps
		# its own spaced profile as the selected attack, so its heading locks
		# for the rest of the tell exactly as a named heavy's does.
		if float(_combat_cfg.get("face_lock_fraction", 0.0)) > 0.0:
			_selected_attack = _spaced_config().duplicate(true)
		_selected_heading_locked = false
		_beat_left = AI.duration_for(intent, _combat_cfg)
	elif intent == AI.Intent.RECOVER and previous == AI.Intent.TELEGRAPH and not _selected_attack.is_empty():
		_beat_left = float(_selected_attack.get("recovery", AI.duration_for(intent, _combat_cfg)))
	else:
		_beat_left = AI.duration_for(intent, _attack_row())
		if intent == AI.Intent.DODGE:
			_beat_left = float(_patterns.get("reactions", {}).get("dodge_duration_s", 0.2))
		if intent != AI.Intent.RECOVER and (intent != AI.Intent.REPOSITION or _patterns.is_empty()):
			_selected_attack.clear()
			_selected_heading_locked = false

	if intent == AI.Intent.TELEGRAPH:
		_lunge_outcome.clear()
		_lunge_heading_locked = false
		# The heading-lock clocks measure the tell proper, never the route cue.
		_lunge_tell_total = _beat_left
		_begin_pattern_cue()
		# F10#2: an opted-in body shows its route for `route_cue_seconds` first;
		# the ordinary tell (and its announcement) follows unchanged.
		var cue := route_cue_seconds()
		_route_cue_left = cue
		if cue > 0.0:
			_beat_left += cue
		if lunge_travels() or cue > 0.0:
			_show_lunge_lane()
		if guard_stance():
			_show_guard_cone()
		if cue <= 0.0:
			_announce_tell()
		else:
			route_cue_started.emit(cue)
	elif previous == AI.Intent.TELEGRAPH and intent == AI.Intent.RECOVER \
			and str(_selected_attack.get("telegraph_shape", "")) == "marker":
		_cooldown = float(_selected_attack.get("attack_cooldown", _combat_cfg.get("attack_cooldown", 1.1)))
		_begin_pattern_leap()
	elif previous == AI.Intent.TELEGRAPH and intent == AI.Intent.RECOVER and lunge_travels():
		# F04: the wind-up completed and the charge begins. The blow is not
		# resolved yet: `strike_ready` follows when the body stops.
		_cooldown = float(_selected_attack.get("attack_cooldown", _combat_cfg.get("attack_cooldown", 1.1)))
		_begin_lunge()
	elif previous == AI.Intent.TELEGRAPH:
		# A route line drawn for a strike that does not travel ends with its tell
		# (only a route cue draws one without travelling).
		if not lunge_travels() and _lunge_lane != null and is_instance_valid(_lunge_lane):
			_lunge_lane.queue_free()
			_lunge_lane = null
		# The wind-up just completed, so the blow lands now. Whether it connects
		# is the manager's call, not this creature's.
		strike_ready.emit()
		_cooldown = float(_selected_attack.get("attack_cooldown", _combat_cfg.get("attack_cooldown", 1.1)))
	elif intent == AI.Intent.REPOSITION:
		# One coin flip per reposition rather than one per frame, so it commits
		# to going around one side instead of jittering on the spot.
		_side_sign = 1.0 if _rng.randf() < 0.5 else -1.0


## --- F04 travelling lunge --------------------------------------------------

## The row the next/current strike uses: the frozen named attack when there is
## one, otherwise this body's merged config.
func _attack_row() -> Dictionary:
	return _selected_attack if not _selected_attack.is_empty() else _combat_cfg


## True only for a body whose own override opted in (`lunge_travels`). Every
## ordinary wild reads the shared `enemy` block, which has no such key.
func lunge_travels() -> bool:
	return bool(_attack_row().get("lunge_travels", false))


func is_lunging() -> bool:
	return _lunge_active


func tell_camera_swing() -> bool:
	return bool(_combat_cfg.get("tell_camera_swing", false))


func camera_ignores_lunge() -> bool:
	return bool(_combat_cfg.get("camera_ignore_lunge", false))


## The authored fight-camera composition yaw in degrees, or 0.0 for the shared
## `camera.tracking.composition_yaw_deg`. Read from the override rather than
## `_combat_cfg` because the camera is taken before the fight snapshot.
func camera_composition_yaw_deg() -> float:
	return float(_enemy_config_for_this_body().get("camera_composition_yaw_deg", 0.0))


## True when this opponent's fight stands the trainer beside the ally.
func camera_trainer_beside_ally() -> bool:
	return bool(_enemy_config_for_this_body().get("camera_trainer_beside_ally", false))


## --- F10#2 named-fight cues ------------------------------------------------

## Only for a body whose own override opted in; 0 for every other creature.
func route_cue_seconds() -> float:
	return maxf(0.0, float(_attack_row().get("route_cue_seconds", 0.0)))


func route_cue_left() -> float:
	return _route_cue_left


func guard_stance() -> bool:
	return bool(_attack_row().get("guard_stance", false))


## What a guest's proxy needs to draw this tell's ground marks exactly as this
## body draws them: the lane (`lane_*`, with seconds until its heading locks)
## and/or the guard cone (`guard_*`), plus `route_s` while a route cue runs.
## Empty outside a tell, or for a tell that draws nothing.
func presentation_shape() -> Dictionary:
	var shape := {}
	if _intent != AI.Intent.TELEGRAPH and not _pattern_leap_active:
		return shape
	if not _pattern_geometry.is_empty():
		var origin: Vector3 = _pattern_geometry.origin
		var heading: Vector3 = _pattern_geometry.heading
		var marker: Vector3 = _pattern_geometry.marker
		shape["pattern"] = {"profile": _pattern_geometry.profile.duplicate(true),
			"origin": [origin.x, origin.y, origin.z], "heading": [heading.x, heading.y, heading.z],
			"marker": [marker.x, marker.y, marker.z]}
	var cue := route_cue_seconds()
	if lunge_travels() or cue > 0.0:
		var half := _lunge_lane_half_width()
		shape["lane_start"] = half
		shape["lane_length"] = maxf(0.1, float(_attack_row().get("lunge", 0.0)))
		shape["lane_half_width"] = half
		shape["lane_travels"] = lunge_travels()
		var lock_in := -1.0
		if lunge_travels():
			var fraction := clampf(float(_attack_row().get("face_lock_fraction", _lunge_cfg().get("face_lock_fraction", 0.5))), 0.0, 1.0)
			if _lunge_heading_locked:
				lock_in = 0.0
			elif fraction > 0.0:
				lock_in = maxf(0.0, _beat_left - maxf(0.001, _lunge_tell_total) * (1.0 - fraction))
		shape["lane_lock_in_s"] = lock_in
	if guard_stance():
		var cfg := combat_config()
		shape["guard_reach"] = maxf(0.5, float(cfg.get("range", 2.6)))
		shape["guard_cone"] = clampf(float(cfg.get("cone_degrees", 90.0)), 5.0, 360.0)
	if _route_cue_left > 0.0:
		shape["route_s"] = _route_cue_left
	return shape


## The tell proper begins: the rig's anticipation and the announcement the
## manager's warning ring and HUD read. Called at telegraph entry, or when a
## route cue ends.
func _announce_tell() -> void:
	# Only rigs with an authored attack contact phase opt in. Their visible
	# anticipation spans this body's real profile duration, while legacy clips
	# retain the existing impact-time animation.
	if _animator != null and _animator.has_method("begin_attack_telegraph"):
		_animator.call("begin_attack_telegraph", _beat_left)
	_tell_visible_since_ms = Time.get_ticks_msec()
	telegraph_started.emit(_beat_left)


## Counts a route cue down; its end announces the ordinary tell.
func _advance_route_cue(delta: float) -> void:
	if _route_cue_left <= 0.0 or _intent != AI.Intent.TELEGRAPH:
		return
	_route_cue_left = maxf(0.0, _route_cue_left - delta)
	# A sub-microsecond remainder is float residue, not cue left to show.
	if _route_cue_left <= 0.000001:
		_route_cue_left = 0.0
		_announce_tell()


## A flat fan on the ground in front of the body, `range` long and `cone_degrees`
## wide -- the same shape the manager's hit test uses -- in the shared hazard
## colour. A child, so it turns with the body and holds when its heading locks.
## A guest's proxy passes the host body's `reach`/`cone` instead of its own.
func _show_guard_cone(reach_override: float = 0.0, cone_override: float = 0.0) -> void:
	_hide_guard_cone()
	var cfg := combat_config()
	var reach := maxf(0.5, reach_override if reach_override > 0.0 else float(cfg.get("range", 2.6)))
	var cone := clampf(cone_override if cone_override > 0.0 else float(cfg.get("cone_degrees", 90.0)),
		5.0, 360.0)
	var colour := Color(str(MATH.config().get("telegraph", {}).get("colour", "#ff40e6")))
	colour.a = 0.35
	var steps := maxi(6, int(cone / 6.0))
	var points := PackedVector3Array()
	var half := deg_to_rad(cone) * 0.5
	for i in steps:
		var a0 := -half + (2.0 * half) * float(i) / float(steps)
		var a1 := -half + (2.0 * half) * float(i + 1) / float(steps)
		points.append(Vector3(0.0, 0.05, 0.0))
		points.append(Vector3(sin(a0) * reach, 0.05, cos(a0) * reach))
		points.append(Vector3(sin(a1) * reach, 0.05, cos(a1) * reach))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = colour
	_guard_cone = MeshInstance3D.new()
	_guard_cone.name = "GuardCone"
	_guard_cone.mesh = mesh
	_guard_cone.material_override = material
	_guard_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_guard_cone.set_meta("reach", reach)
	_guard_cone.set_meta("cone_degrees", cone)
	add_child(_guard_cone)


func _hide_guard_cone() -> void:
	if _guard_cone != null and is_instance_valid(_guard_cone):
		_guard_cone.queue_free()
	_guard_cone = null


## How the last travelling lunge ended, for the manager to resolve exactly
## once: `{contact, stopped_by, travelled, distance, heading}`. Empty for an
## ordinary strike, which the manager then resolves by its cone test as before.
func take_lunge_outcome() -> Dictionary:
	var outcome := _lunge_outcome.duplicate()
	_lunge_outcome.clear()
	return outcome


func _lunge_cfg() -> Dictionary:
	return MATH.config().get("charger_lunge", {})


## Contact distance between this body's swept centre and a target's centre.
func _lunge_contact_reach() -> float:
	var theirs := 0.5
	if _opponent != null and is_instance_valid(_opponent) and _opponent.has_method("body_radius"):
		theirs = float(_opponent.call("body_radius"))
	return (body_radius() + theirs) * float(_lunge_cfg().get("contact_scale", 1.2))


## The lane's half-width: this body's own contact footprint, so "my creature's
## footprint is on the lane" and "I get hit" are one rule.
func _lunge_lane_half_width() -> float:
	return body_radius() * float(_lunge_cfg().get("contact_scale", 1.2))


## COMBAT §5: track for the first part of the tell, then hold the heading the
## lane shows. Once locked it stays locked for this tell.
func _lunge_heading_is_locked() -> bool:
	if _lunge_heading_locked:
		return _intent == AI.Intent.TELEGRAPH
	if _intent != AI.Intent.TELEGRAPH or not lunge_travels():
		return false
	var fraction := clampf(float(_attack_row().get("face_lock_fraction", _lunge_cfg().get("face_lock_fraction", 0.5))), 0.0, 1.0)
	if fraction <= 0.0:
		return false
	if _beat_left <= maxf(0.001, _lunge_tell_total) * (1.0 - fraction):
		_lunge_heading_locked = true
	return _lunge_heading_locked


func _show_lunge_lane() -> void:
	if _lunge_lane != null and is_instance_valid(_lunge_lane):
		_lunge_lane.queue_free()
	_lunge_lane = null
	if not is_inside_tree():
		return
	var half := _lunge_lane_half_width()
	_lunge_lane = LUNGE_LANE.begin(self, half, float(_attack_row().get("lunge", 0.0)), half, _lunge_cfg())
	_aim_lunge_lane()


## Follows the heading while it tracks; freezes (and firms up) when it locks.
func _aim_lunge_lane() -> void:
	if _lunge_lane == null or not is_instance_valid(_lunge_lane) or _intent != AI.Intent.TELEGRAPH:
		return
	if bool(_lunge_lane.call("is_locked")):
		return
	_lunge_lane.call("aim", global_position, facing())
	if _lunge_heading_is_locked():
		_lunge_lane.call("lock")


func _begin_lunge() -> void:
	var heading := facing()
	var distance := float(_attack_row().get("lunge", 0.0))
	var speed := maxf(0.1, float(_lunge_cfg().get("travel_speed", 16.0)))
	if _lunge_lane != null and is_instance_valid(_lunge_lane):
		if not bool(_lunge_lane.call("is_locked")):
			_lunge_lane.call("aim", global_position, heading)
			_lunge_lane.call("lock")
		# It stays where it was drawn while the body runs down it, then fades.
		_lunge_lane.call("release")
	_lunge_lane = null
	if distance <= 0.0 or not begin_combat_burst(heading, distance, distance / speed):
		# Nothing to travel: judged where it stands, by the same contact rule.
		var here := Vector2(global_position.x, global_position.z)
		var target := Vector2(_opponent.global_position.x, _opponent.global_position.z) \
			if _opponent != null and is_instance_valid(_opponent) else Vector2.INF
		_lunge_heading = heading
		_lunge_origin = global_position
		_lunge_distance = 0.0
		_finish_lunge(target != Vector2.INF and swept_contact(here, here, target, _lunge_contact_reach()), "no_travel")
		return
	_lunge_active = true
	_lunge_heading = heading
	_lunge_origin = global_position
	_lunge_distance = distance
	_lunge_speed = speed
	play_attack()
	lunge_started.emit(heading, distance)


## Judged after the body integrated this step, so collision has had its say.
func _after_lunge_step(before: Vector3, delta: float) -> void:
	if not engaged or _opponent == null or not is_instance_valid(_opponent):
		_cancel_lunge()
		return
	var cfg := _lunge_cfg()
	var a := Vector2(before.x, before.z)
	var b := Vector2(global_position.x, global_position.z)
	var target := Vector2(_opponent.global_position.x, _opponent.global_position.z)
	var heading := Vector2(_lunge_heading.x, _lunge_heading.z)
	var touched_target := false
	var blocked := false
	var obstacle_dot := float(cfg.get("obstacle_dot", -0.5))
	var max_normal_y := float(cfg.get("obstacle_max_normal_y", 0.7))
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() == _opponent:
			touched_target = true
			continue
		var normal := collision.get_normal()
		var flat := Vector2(normal.x, normal.z)
		if normal.y < max_normal_y and flat.length_squared() > 0.000001 \
				and flat.normalized().dot(heading) < obstacle_dot:
			blocked = true
	if touched_target or swept_contact(a, b, target, _lunge_contact_reach()):
		cancel_combat_burst()
		_finish_lunge(true, "contact")
		return
	if blocked:
		cancel_combat_burst()
		_finish_lunge(false, "obstacle")
		return
	if not combat_burst_active():
		_finish_lunge(false, "distance")
		return
	var planned := _lunge_speed * delta
	if (b - a).dot(heading) < planned * float(cfg.get("min_progress_fraction", 0.35)):
		# Held back without a wall normal: the arena edge's position clamp.
		cancel_combat_burst()
		_finish_lunge(false, "obstacle")


func _finish_lunge(contact: bool, stopped_by: String) -> void:
	_lunge_active = false
	var moved := global_position - _lunge_origin
	_lunge_outcome = {
		"contact": contact,
		"stopped_by": stopped_by,
		"travelled": Vector2(moved.x, moved.z).dot(Vector2(_lunge_heading.x, _lunge_heading.z)),
		"distance": _lunge_distance,
		"heading": _lunge_heading,
	}
	# Whether it connected is still the manager's call, from this outcome.
	strike_ready.emit()


## Stops a charge (and its lane) without a strike: stagger, faint, disengage.
func _cancel_lunge() -> void:
	# F10#2: every path that abandons a tell (stagger, faint, disengage) comes
	# through here, so a route cue or guard cone never outlives its tell.
	_route_cue_left = 0.0
	_clear_pattern_cue()
	_pattern_geometry.clear()
	_pattern_repeat_left = 0
	for child: Node in get_children():
		if child.has_meta(&"enemy_pattern_cast"): child.queue_free()
	_hide_guard_cone()
	if _lunge_active or _pattern_leap_active:
		_lunge_active = false
		if _pattern_leap_active and is_instance_valid(_model): _model.position.y = _pattern_leap_model_y
		_pattern_leap_active = false
		cancel_combat_burst()
	if _lunge_lane != null and is_instance_valid(_lunge_lane):
		_lunge_lane.queue_free()
	_lunge_lane = null
	_lunge_heading_locked = false


## Did a body moving from `a` to `b` pass within `reach` of `target`? Flat
## (x, z) points. Static so the rule is unit-testable without physics.
static func swept_contact(a: Vector2, b: Vector2, target: Vector2, reach: float) -> bool:
	var ab := b - a
	var t := 0.0
	var length_squared := ab.length_squared()
	if length_squared > 0.00000001:
		t = clampf((target - a).dot(ab) / length_squared, 0.0, 1.0)
	return (a + ab * t).distance_to(target) <= reach


## Told every physics tick by `combat_manager.gd` (mirroring `throw_aim.gd`'s
## own `is_aiming()`), not read here directly — this node has no reference to
## the throw and no reason to gain one. A no-op outside `_tick_combat` (a
## peaceful creature is never the aim target), so a stray true left over from
## a fight that has already ended costs nothing.
func set_catch_aim_active(value: bool) -> void:
	_catch_aim_active = value


## Seconds the current tell proper has been visible (route cue excluded), or
## -1 when no tell is showing. COMBAT §4's forced-break read test uses it.
func tell_visible_s() -> float:
	if not is_winding_up():
		return -1.0
	return maxf(0.0, _lunge_tell_total - _beat_left)


## The host tick (ms) at which the current tell proper became visible, or -1
## when no tell is showing. The host compares a guest's committed charge
## start against it, so link latency never widens the read window.
func tell_visible_since_ms() -> int:
	if not is_winding_up():
		return -1
	return _tell_visible_since_ms


func is_winding_up() -> bool:
	# A route cue (F10#2) comes BEFORE the wind-up: only the tell proper counts
	# for interrupts and the HUD's warning. Unset, `_route_cue_left` is 0.
	return engaged and _intent == AI.Intent.TELEGRAPH and _route_cue_left <= 0.0


func _poise_config() -> Dictionary:
	return MATH.config().get("poise", {})


func _poise_max() -> float:
	return poise_max()


## COMBAT §4 break pool for this body: an encounter's authored `poise_max`
## wins, then the role pool (`poise.role_pools`), then the shared default.
## The manager reads this same value so HUD and break threshold agree.
func poise_max() -> float:
	if _synced_poise_max > 0.0:
		return _synced_poise_max
	if _combat_cfg.has("poise_max"):
		return maxf(1.0, float(_combat_cfg.poise_max))
	var pools: Dictionary = _poise_config().get("role_pools", {})
	if not pools.is_empty() and instance != null:
		var role := AI.context_role(_patterns, _pattern_context) if not _pattern_context.is_empty() else ""
		if role.is_empty():
			role = AI.species_role(str(instance.get("species_id")), MATH.config().get("patterns", {}))
		if pools.has(role):
			return maxf(1.0, float(pools[role]))
	return maxf(1.0, float(_poise_config().get("max", 40.0)))


func _reset_poise() -> void:
	_synced_poise_max = -1.0
	_poise = _poise_max()
	_poise_quiet_left = 0.0
	_poise_resist_left = 0.0
	_staggered = false
	_stagger_critical_ready = false


func _tick_poise(delta: float) -> void:
	if _staggered:
		return
	_poise_resist_left = maxf(0.0, _poise_resist_left - delta)
	_poise_quiet_left = maxf(0.0, _poise_quiet_left - delta)
	if _poise_quiet_left <= 0.0:
		_poise = minf(_poise_max(), _poise + float(_poise_config().get("regen_per_second", 20.0)) * delta)


## Drain this body's break meter after a landed blow. Returns true only when
## this call starts a stagger, so presentation can announce the transition once.
func apply_poise_damage(amount: float, force_stagger: bool = false) -> bool:
	_poise_quiet_left = float(_poise_config().get("regen_delay", 2.0))
	# F10#2 (coordinator interim ruling 5860078626, option (a)): a body showing
	# its route cue cannot be staggered, and hits during the cue do not drain
	# its poise either (they still deal damage). Draining to a one-point floor
	# was measured first and left the break one hit into the tell proper, so a
	# masher still cancelled every dive (C2 ratio inf / 3.49).
	if _route_cue_left > 0.0:
		return false
	# COMBAT §4: for a short beat after a stagger ends the body cannot be
	# broken again (forced or not) and its refilled pool is not drained; hits
	# still deal HP damage. Stops chained zero-poise staggers.
	if _poise_resist_left > 0.0:
		return false
	if not force_stagger:
		_poise = maxf(0.0, _poise - maxf(0.0, amount))
	if _staggered or (not force_stagger and _poise > 0.0):
		return false
	_poise = 0.0
	_staggered = true
	_stagger_critical_ready = true
	# A broken charge stops where it is and strikes nothing.
	_cancel_lunge()
	# The cadence attempt was already consumed on entering TELEGRAPH, but its
	# committed profile must not survive a cancelled strike into stagger recovery.
	_selected_attack.clear()
	_selected_heading_locked = false
	# Assign directly instead of entering from TELEGRAPH: `_enter()` treats a
	# TELEGRAPH exit as impact and would emit the cancelled strike.
	_intent = AI.Intent.RECOVER
	_beat_left = float(_combat_cfg.get("stagger_seconds", _poise_config().get("stagger_seconds", 0.6)))
	if _animator != null:
		_animator.call("cancel_hold")
	return true


func consume_stagger_critical() -> bool:
	if not _staggered or not _stagger_critical_ready:
		return false
	_stagger_critical_ready = false
	return true


func poise_fraction() -> float:
	return clampf(_poise / _poise_max(), 0.0, 1.0)


func is_staggered() -> bool:
	return engaged and _staggered


## Multiplayer verdicts carry the host's absolute break-meter state. Applying
## an absolute value is idempotent on the host and prevents a client replay
## from draining poise twice.
func sync_poise(value: float, staggered_now: bool, critical_ready: bool = true,
		stagger_left: float = -1.0, host_poise_max: float = -1.0) -> void:
	# A guest's stand-in has no authored profile or pattern context: the
	# host's own pool size is the one its bar must be read against.
	if host_poise_max > 0.0:
		_synced_poise_max = host_poise_max
	_poise = clampf(value, 0.0, _poise_max())
	_staggered = staggered_now
	_stagger_critical_ready = staggered_now and critical_ready
	if staggered_now:
		_cancel_lunge()
		_selected_attack.clear()
		_selected_heading_locked = false
		_intent = AI.Intent.RECOVER
		_beat_left = stagger_left if stagger_left >= 0.0 else float(_combat_cfg.get(
			"stagger_seconds", _poise_config().get("stagger_seconds", 0.6)))


func stagger_seconds_left() -> float:
	return _beat_left if _staggered else 0.0


func is_rooted() -> bool:
	# A charging body is committed, not open: the HUD's "it's open" waits for
	# the charge to stop. Nor is a body showing its route cue (F10#2): the drawn
	# lane is the cue there, so the HUD says nothing until the tell.
	return engaged and AI.is_rooted(_intent) and not _lunge_active \
		and not (_intent == AI.Intent.TELEGRAPH and _route_cue_left > 0.0)


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
	_cancel_lunge()
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
