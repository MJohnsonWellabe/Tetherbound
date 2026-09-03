extends RefCounted

## Left-stick travel that can get around what is in the way.
##
## GATEB-PATH. Every continuous harness in this repo walked by pointing the
## stick at a coordinate and holding it, and that is the single reason
## `tests/smoke_gate_b_continuous.gd` had never finished a run. The Meadows has
## no navmesh -- nothing under `scripts/`, `scenes/` or `autoload/` so much as
## mentions `NavigationServer3D` -- so "walk toward the point" has always meant
## "walk into whatever stands between here and the point, and keep pushing".
##
## The evidence is exact rather than inferred. The run before this reported
##
##   could not reach or activate door 'Door' in 1200 frames (player 3.6m away at
##   (18, 1, -6), door at (15, 1, -3), prompt enabled=true,
##   arbiter winner=EncounterDirector)
##
## and the geometry says why: Oskar stands at [22,-6], Mira's door is the hole
## in cottage_a's front wall, and cottage_a (`data/config/village.json`,
## `at: [18,-2]`, `yaw_deg: -135`) puts that wall's solid left-hand piece
## (`data/config/building_prefabs.json`, local x -2.2..0.2 at local z 3)
## directly across the straight line between them. Twenty seconds of walking
## into plaster, with the door offerable the whole time and simply not visible
## from where the player stood -- `interactable.gd::_has_line_of_sight` refuses
## an offer through a wall, so the EncounterDirector was not stealing the
## interact line, it was the only thing still bidding for it.
##
## What this does instead is the walk a person does in the dark: when a leg
## stops closing on its target, put a hand on the wall and slide. A free-space
## probe picks which hand; repeated failures on that side switch hands.
##
## Deliberately NOT an authored per-villager waypoint table. The same straight
## line breaks at Bram's inn, on the material route's long treks, and at every
## later beat these harnesses have not reached yet, and a table would need an
## entry for each of them. This is the general answer, and it lives entirely in
## the test harness -- no gameplay code changes, because nothing about the game
## is wrong here.
##
## Shared rather than copied: `gate_a_npc_gather_segment.gd` and
## `gate_a_material_route.gd` each had their own straight-line walker with its
## own way of pushing the stick, and two copies of a navigator is how one of
## them silently stops being fixed.

## Physics frames of no measurable progress before the walk decides it is
## pressed against something rather than merely slow.
const STALL_FRAMES := 26
## Metres of closing that count as progress. Loose enough that a diagonal
## scrape along a wall does not read as travel.
const PROGRESS := 0.08
## Physics frames spent walking sideways once a detour starts. Each further
## detour on the same side runs `DETOUR_GROWTH` frames longer, because a long
## wall needs a longer slide than a fence post does.
##
## FENCE-CORNER-0903. A cap on how large one attempt is allowed to grow was
## tried, to stop a single detour from carrying the body arbitrarily far past
## a corner it had already cleared (measured once, uncapped: a single ~40m
## detour, 122m off the straight line). It solved that but cost more than it
## fixed: capping growth makes every attempt smaller, so a spot needing
## several genuinely-working but individually modest attempts to clear now
## failed each one's own smaller showing and abandoned early (measured live
## in the real continuous route: 686 side flips, stuck before ever reaching
## the corner this file exists for). The actual fix for "gone far enough" is
## `step()`'s own forward free-space check below -- it ends a detour the
## instant the way to the target re-opens, independent of how large the
## detour was ever allowed to grow -- so growth stays uncapped and
## `DETOURS_PER_SIDE`'s only job is not letting a truly wrong side spin
## forever.
const DETOUR_FRAMES := 45
const DETOUR_GROWTH := 25
## Detours on one side that fail to unstick before the other side is tried --
## a hard cap, in case `_side` genuinely never sees the abandon check below
## fire (it always should; this is the backstop against that being wrong).
##
## FENCE-CORNER-0903. Raising this alone, tried first, cost a regression:
## bumped to 10 flat, `smoke_gate_b_continuous --gate-b-full-chain` broke a
## SHORTER, previously-reliable leg near RoadGate ("controller could not
## reach authored wood at (16.0, -28.0)", 2 of 2 runs) that a small budget
## (`_travel_budget` ~1680 frames for that ~24m leg) cannot afford to spend
## on ten growing attempts down a side that was simply the wrong one --
## `DETOUR_FRAMES` + growth summed over 10 tries is ~1575 frames on its own,
## before any backoff. A flat cap cannot tell "still working" from "wrong
## side" apart; only measured progress can. See `SIDE_ABANDON_ATTEMPTS`/
## `SIDE_ABANDON_PROGRESS_M` below for what actually decides when to give up
## on a side -- they answer that question in a couple of attempts on a wrong
## side, and let a genuinely-working side (the corner: real westward creep
## every cycle) keep going far past this cap's old value of 3, which is what
## a 15m fence run with a post at each end needed.
const DETOURS_PER_SIDE := 20
## The sideways free-space probe. Only as far as a detour would actually walk.
const PROBE_REACH := 3.0

## GAME-8 / RIG-23. The probe used to be ONE hairline ray at hip height
## (`PROBE_HEIGHT := 1.0`), and that single fact is the whole of the Mira's-shop
## trap. It was blind twice over.
##
##   * Blind to anything short. `shop_interior.gd::_build_counter()` puts two
##     stock crates at local (-1.3, 0.25, 1.5) and (-1.3, 0.72, 1.5) -- tops at
##     0.50m and 0.945m, both UNDER a ray at 1.0. The counter's own top is at
##     exactly 1.0, so the ray grazed it too. To the probe, a room full of
##     furniture read as three metres of open air in every direction.
##   * Blind to width. A ray has none, and the player capsule is 0.8m across
##     (`scenes/player/player.tscn`, radius 0.4). The gap between the room's
##     west wall (INNER_HALF_W 1.69) and the crates' west face (-1.55) is
##     0.14m. A hairline ray goes down it happily; a body cannot fit.
##
## With both probes reading a flat PROBE_REACH, `_freer_side` fell through to
## its documented "a tie goes to +1" rule EVERY time -- and +1 is a perpendicular
## of the direction of travel, so it means opposite world sides walking in and
## walking out. That is exactly the asymmetry run 4 recorded and could not
## explain: entry slid east into the open room and worked every time, exit slid
## west into the 0.14m wall/crate pocket at local x=-1.37 and wedged every time.
## No waypoint could fix it, because the walker was not choosing badly between
## two known sides -- it could not see either one.
##
## So the probe now sweeps the volume the BODY occupies: three heights by three
## lateral offsets, nine rays, nearest hit wins. Still rays, still cheap, still
## only fired when a leg has already stalled.
##
## The lowest height clears `player_controller.gd::STEP_HEIGHT` (0.35): a kerb
## the body steps over must not read as a wall, or every outdoor detour would
## think it was boxed in. The crates at 0.50m are above that line and are seen;
## a stair tread is below it and is not.
const PROBE_HEIGHTS: Array[float] = [0.45, 0.95, 1.55]
## Half the body's own width, so the outer rays trace the capsule's flanks
## rather than its centre line.
const PROBE_HALF_WIDTH := 0.35
## Clearance a side needs before sliding that way is travel rather than a wedge.
## The body is 0.8m across; this is that plus a hand's breadth either side.
const BODY_WIDTH := 0.9
## FENCE-CORNER-0903. How `_begin_detour` decides a committed side is still
## worth persisting on: from the SECOND attempt onward it checks total net
## lateral progress since the side was first committed, and abandons early
## (flips, regardless of `DETOURS_PER_SIDE`) if that total has not covered
## real ground. A wrong side reads this within two attempts; a side that is
## genuinely working (measured live: real, if slow, metres-per-attempt creep
## along a 15m fence run) clears it every time and keeps its growing detour
## going toward `DETOURS_PER_SIDE`'s cap instead.
const SIDE_ABANDON_ATTEMPTS := 2
## Metres of net progress along the committed side, since it was picked,
## an abandon check requires to call the side still working. Below one full
## `BODY_WIDTH` is noise a slide can rack up just easing around its own
## contact point without actually going anywhere.
const SIDE_ABANDON_PROGRESS_M := 1.0
## FENCE-CORNER-0903. Consecutive physics frames a detour's forward
## free-space probe (toward the TARGET, not the detour's own perpendicular)
## must read clear before `step()` trusts it and ends the detour outright.
## 20 frames is a third of a second -- long enough that a momentary gap
## between two pieces of geometry (measured: the tournament board and a
## neighbouring fence panel) cannot read as "the corner is behind me", since
## the body is still moving and that gap closes again within a few frames;
## genuinely open terrain past a cleared corner stays clear for the whole
## window. See `step()`'s own comment on this check for the two failure
## modes (no check at all: 122m overshoot; a one-shot check: 678 flips
## stuck on unrelated geometry) that fixed this number rather than 1 or 60.
const CLEAR_AHEAD_FRAMES := 20
## Frames spent reversing away from the target when BOTH sides are pinched.
## Short: this is shaking loose from a pocket, not a leg of the journey.
const BACKOFF_FRAMES := 30
## A detour is re-examined this often, and must have carried the body at least
## this far since the last check to be allowed to continue.
##
## The old detour committed to `DETOUR_FRAMES` (45, growing by 25) of blind
## sideways push regardless of whether the body was moving at all. Pressed into
## a corner that is a second and a half of grinding against plaster per detour,
## three detours per side, before anything reconsiders.
const DETOUR_CHECK_FRAMES := 15
const DETOUR_MIN_TRAVEL := 0.12
## How far ahead the GROUND is checked before sliding that way, and the drop
## that counts as a cliff rather than a step down.
##
## GATEB-COORD. The free-space probe above is a horizontal ray: it can see a
## wall and is completely blind to a hole. So a detour would cheerfully slide
## off the edge of the Practice Meadow plateau, and the walker would spend the
## rest of its budget four metres below the target trying to climb terrain it
## cannot climb -- the Gate B build segment failed that way over and over,
## reporting its trainer at y=-2.0 while the stance it wanted sat at y=3.0.
## A side whose ground falls away by more than `SAFE_DROP` is treated as
## blocked, exactly like a wall, because for a walker it is worse than one.
const GROUND_LOOK_AHEAD := 2.0
const SAFE_DROP := 1.2
const GROUND_PROBE_DEPTH := 8.0
## How far above the feet the downward ground ray starts, so a step up ahead is
## still seen from above rather than from inside it. Unchanged in value from the
## hip-height number this used before the clearance probe stopped needing one.
const GROUND_PROBE_START := 1.0
## Metres from the target at which the stick eases off, and the smallest
## deflection it eases to. Full stick into a target measured in centimetres
## overshoots and oscillates around it; `gate_a_build_segment.gd` stops within
## `MOVE_EPSILON` 0.16m and had these exact numbers of its own before this file
## existed, so they are kept rather than re-invented.
const EASE_METRES := 0.9
const EASE_FLOOR := 0.32

var _tree: SceneTree = null
var _player: Node3D = null
var _rig: Node3D = null
## `drive.call(local_x: float, local_y: float)` pushes the caller's own left
## stick. Each harness parses its own bindings and signs out of the live
## InputMap, so the navigator hands over stick-space numbers and lets the
## caller stay the one that speaks to `Input`.
var _drive: Callable = Callable()

var _gap := INF
var _stall := 0
var _detour := Vector3.ZERO
var _detour_left := 0
var _side := 0.0
var _side_detours := 0
## Where the body was when `_side` was last freshly picked (not each retry --
## see `SIDE_ABANDON_ATTEMPTS`/`SIDE_ABANDON_PROGRESS_M`). Total displacement
## from here along the committed side is the real "is this working" signal.
var _side_commit_origin := Vector3.ZERO
## Where the body was when the current detour was last examined, and how many
## frames ago that was. A detour that is not carrying the body anywhere is
## abandoned rather than run to its frame count -- see DETOUR_CHECK_FRAMES.
var _detour_origin := Vector3.ZERO
var _detour_age := 0
## Consecutive frames the forward-toward-target probe has read clear during
## the current detour -- see `CLEAR_AHEAD_FRAMES`.
var _clear_ahead := 0
## FENCE-CORNER-0903. True while the current `_detour_left` run is the
## step-back-and-sideways recovery `step()` starts on a stall, as opposed to
## an ordinary `_begin_detour()` slide. A recovery that itself stalls (both
## the direction chosen and the ground it is standing on refuse to move it
## at all -- measured live pinned against a closed gate leaf, `moved/1s
## 0.03` for the rest of the frame budget) must not just start ANOTHER
## recovery: that recomputes the identical direction from the identical
## position and deadlocks forever, which is a strictly worse failure than
## the oscillation this file exists to fix. This flag is the one-recovery-
## then-fall-back guard: a stall during a recovery forces the harder,
## guaranteed-terminating `_back_off()` (full side reset) instead of another
## attempt at the same stuck direction.
var _recovering := false


func _init(tree: SceneTree, player: Node3D, rig: Node3D, drive: Callable) -> void:
	_tree = tree
	_player = player
	_rig = rig
	_drive = drive


## Physics frames this will wait, in total, for locomotion to come back before
## giving up on a leg. Ten minutes: a wild fight is the usual reason and it
## ends on its own; anything longer is a stuck world, not a busy one.
const HELD_FRAMES := 36000


## Walk to `point`, detouring around whatever is in the way. True if it arrived.
##
## GATEB-COORD: a leg PAUSES while the player cannot move.
## `encounter_director.gd::_set_exploration_active()` turns
## `locomotion_enabled` off for the whole of a fight, and a wild creature
## picking one is the single most common thing to happen to a harness walking
## across open meadow. Without this the walk kept pushing the stick at a body
## that could not move, read every frame of it as a stall, escalated into
## longer and longer sideways detours, and then -- the moment the fight
## ended -- set off in whichever direction the last detour had chosen. That is
## how the Gate B build segment kept finding its trainer nine metres east and
## five metres below the stance it had already reached.
##
## Frames spent held do not count against the leg's budget: the budget is a
## measure of walking, and none is being done.
func walk_to(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
	reset()
	var held := 0
	var walked := 0
	while walked < budget:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			return true
		if not can_walk():
			held += 1
			if held > HELD_FRAMES:
				return false
			# Hands off the stick, and forget the stall this was building up:
			# nothing that happened while the body was frozen says anything
			# about what is in the way.
			_drive.call(0.0, 0.0)
			reset()
			await _tree.physics_frame
			continue
		walked += 1
		await step(point)
	return false


## Is the body this is driving actually able to move right now? Public, because
## a caller that drives `step()` itself -- `gate_a_npc_gather_segment.gd` walks
## up to a villager one frame at a time so it can watch the interact line --
## needs the same answer and must not have its own copy of it.
##
## Read off the player rather than passed in, because every harness in this
## repo finds its player by exactly this method and none of them should have to
## remember to wire up a fight check.
func can_walk() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if not _player.has_method("locomotion_enabled"):
		return true
	return bool(_player.call("locomotion_enabled"))


## One physics frame of travel toward `point`. Split out so a caller can
## interleave walking with watching what the world is offering.
func step(point: Vector3) -> void:
	var to := point - _player.global_position
	to.y = 0.0
	if _detour_left > 0:
		# FENCE-CORNER-0903. Stop sliding once straight-at-the-target has read
		# clear for a SUSTAINED stretch, not a single lucky instant. Aimed at
		# a real, if rare, overshoot (a walker that had genuinely cleared the
		# TrailGate corner rode a growing detour a further 40m and landed
		# 122m off the straight line) -- but a one-shot version of this check
		# measured worse than the overshoot it fixed: near closely-packed
		# geometry (the tournament board and its neighbouring fence panels,
		# well before TrailGate) a single favourable probe cancels a detour
		# that is still genuinely needed, the body walks straight back into
		# contact, and the resulting cycle is worse than the oscillation this
		# file exists to fix (678-686 side flips, stuck before ever reaching
		# the corner). `CLEAR_AHEAD_FRAMES` consecutive clear reads is long
		# enough that a momentary gap between two obstacles cannot fake it --
		# actually open terrain past a cleared corner reads clear for the
		# whole stretch, a gap between board and fence does not.
		if _free_space(to.normalized()) >= PROBE_REACH:
			_clear_ahead += 1
		else:
			_clear_ahead = 0
		if _clear_ahead >= CLEAR_AHEAD_FRAMES:
			_detour_left = 0
			_side = 0.0
			_side_detours = 0
			_recovering = false
			_clear_ahead = 0
		# Stop sliding the moment the ground ahead stops being ground. The side
		# was checked when the detour began, but a slide is several metres long
		# and an edge can arrive part-way along it. Guarded on `_detour_left`
		# still being set: the clear-ahead check above may just have ended
		# the detour outright, and `_detour_stalled()` must not be asked
		# about (and silently tick its own ageing counter for) a detour that
		# no longer exists.
		elif _drops_away(_detour):
			_detour_left = 0
			_side = -_side
			_side_detours = 0
		elif _detour_stalled():
			# GAME-8. The side was clear when the detour began and the body has
			# stopped moving anyway -- furniture the probe could not see from
			# where it stood, or a corner that closed as the slide entered it.
			# Give up on this side now instead of grinding out the frame count.
			#
			# FENCE-CORNER-0903. This used to force `_side = -_side` right
			# here, unconditionally, on every stall -- which measured live
			# against a 15m fence run with a corner post at each end
			# (`village_boundary.json`'s TrailGate -> vertex 7 edge,
			# `village_boundary.gd`'s `FenceCornerGuard_6`/`_7`) as 79-94
			# side flips and a walker pinned in a ~10m band that never once
			# covered the last metre or two to either post. Two things were
			# wrong, found by measuring what each candidate fix actually did:
			#
			#   1. Flipping in place discards a side that WAS making real, if
			#      slow, progress. Retreating first and re-trying the SAME side
			#      (`_side`/`_side_detours` left alone here) lets `_begin_detour`'s
			#      own growing-duration retries do their job instead of
			#      restarting the coin flip on every stall.
			#   2. A corner POST sticks out further than the panel either side
			#      of it (`village_boundary.gd`'s `POST_HALF` 1.1m vs. a panel's
			#      own 0.25m half-thickness), so a body hugging the panel at its
			#      ordinary ~0.4-0.5m clearance is already closer to the post
			#      than the post's own face by the time it arrives. A diagonal
			#      retreat (part standoff, part lateral) was tried and measured
			#      WORSE (37-38 flips, same trap) than retreating straight back
			#      (29 flips, real westward creep to within 2m of clearing):
			#      trading standoff for lateral distance the body cannot use yet
			#      just re-hits the post sooner. The lateral progress this file
			#      wants belongs to `_begin_detour`'s own committed slide, once
			#      retreating straight back has actually made room for it.
			#
			# GUARANTEED EXIT. Measured pinned against a closed gate leaf (a
			# separate, real defect that probe was reproducing because it
			# never opens the gate -- the actual gather route always does),
			# the straight-back retreat direction can itself be a direction
			# nothing under it will move along, and `_detour_stalled()`
			# re-firing every `DETOUR_CHECK_FRAMES` would just restart an
			# identical retreat from an identical position forever:
			# `moved/1s 0.03` for the rest of the frame budget, a hard
			# freeze strictly worse than the oscillation this file exists to
			# fix. `_recovering` makes this a ONE-shot: a stall during an
			# already-in-progress recovery falls back to the plain,
			# guaranteed-terminating flip (which sets no new `_detour_left`
			# of its own, so it cannot re-enter this same stuck branch)
			# instead of trying the identical recovery again.
			if _recovering:
				_recovering = false
				_detour_left = 0
				_side = -_side
				_side_detours = 0
			else:
				_recovering = true
				_detour = -to.normalized()
				_detour_left = BACKOFF_FRAMES
				_detour_origin = _player.global_position
				_detour_age = 0
				_push(_detour)
				await _tree.physics_frame
				return
		else:
			_detour_left -= 1
			_push(_detour)
			await _tree.physics_frame
			return
	var gap := to.length()
	if gap < _gap - PROGRESS:
		_gap = gap
		_stall = 0
	else:
		_stall += 1
		if _stall >= STALL_FRAMES:
			_begin_detour(to)
			_push(_detour)
			await _tree.physics_frame
			return
	_push(to.normalized() * clampf(gap / EASE_METRES, EASE_FLOOR, 1.0))
	await _tree.physics_frame


## One physics frame of stick in a world direction, with no detour logic. For a
## deliberate shuffle -- a sidestep to change the interact arbiter's mind --
## which is not a leg of travel and must not be read as a stall.
func push_once(direction: Vector3) -> void:
	_push(direction)


func reset() -> void:
	_gap = INF
	_stall = 0
	_detour = Vector3.ZERO
	_detour_left = 0
	_side = 0.0
	_side_detours = 0
	_detour_origin = Vector3.ZERO
	_detour_age = 0
	_recovering = false
	_side_commit_origin = Vector3.ZERO
	_clear_ahead = 0


## Has the detour currently running stopped carrying the body anywhere?
## Answered on a cadence rather than every frame, because a single physics
## frame of travel is smaller than the noise in a sliding contact.
func _detour_stalled() -> bool:
	_detour_age += 1
	if _detour_age < DETOUR_CHECK_FRAMES:
		return false
	var moved := _player.global_position.distance_to(_detour_origin)
	_detour_age = 0
	_detour_origin = _player.global_position
	return moved < DETOUR_MIN_TRAVEL


## Turn the walk sideways. Which way is decided once per side and then KEPT:
## following a wall means committing to a direction, and a walk that re-chose
## every stall would oscillate in the corner it is trying to leave.
##
## GAME-8. Committing is only sane if the side has room for the body. A side
## narrower than the body is not a slower route, it is the wedge itself, and
## the old code would commit to one for three detours of growing length before
## trying the other. Both sides pinched means the body is in a pocket, and the
## only direction with known-good ground behind it is the way it came.
func _begin_detour(to: Vector3) -> void:
	_stall = 0
	_gap = to.length()
	# An ordinary committed slide is starting, so any FENCE-CORNER-0903
	# stall-recovery in progress is over -- otherwise a recovery that
	# happened to succeed would still read as "already recovering" on the
	# NEXT unrelated stall, cutting straight to the guaranteed-exit flip
	# instead of getting its own one-shot retreat.
	_recovering = false
	# A fresh run at `CLEAR_AHEAD_FRAMES`, scoped to the detour that is about
	# to start rather than left over from wherever the last one ended.
	_clear_ahead = 0
	var perpendicular := to.normalized().cross(Vector3.UP).normalized()
	# FENCE-CORNER-0903. `_side` is picked fresh (or force-flipped) only on
	# these two branches; a repeat call that is just continuing an already-
	# committed side leaves `fresh_side` false. The free-space sanity check
	# below used to run on EVERY call, committed side or not, which measured
	# live against a 15m fence run (`village_boundary.json`'s TrailGate ->
	# vertex 7 edge, two corner posts a body-width apart at either end) as
	# 79-94 side flips and a walker that never got past x=-14 of the 15m it
	# needed: any call into `_begin_detour` only ever happens right after a
	# stall, i.e. right up against something, so the "does the COMMITTED
	# side have room RIGHT NOW" read is close to always false at that exact
	# instant regardless of whether the committed side is actually the way
	# out -- and flipping on that reads it wrote off the very side that was
	# making real (if slow) net progress along the wall. This docstring's
	# own "decided once per side and then KEPT" was already the intent;
	# checking on every repeat call is what was breaking it.
	var fresh_side := false
	if _side == 0.0:
		_side = _freer_side(to)
		_side_detours = 0
		fresh_side = true
	else:
		var abandon := _side_detours >= DETOURS_PER_SIDE
		# FENCE-CORNER-0903. A flat attempt cap cannot tell a side that is
		# genuinely working (creeping metres along a long wall, one retry at
		# a time) from one that was simply wrong from the start -- only
		# measured progress can, so this checks net displacement along
		# `_side` since it was first committed (`_side_commit_origin` is set
		# once below, when the side is freshly picked, not on every retry).
		# A per-ATTEMPT version of this check was tried too: it judges each
		# capped attempt's own showing, which sounds stricter but measured
		# WORSE in the real continuous route -- a spot needing several short,
		# choppy-but-real attempts to clear (each individually unremarkable)
		# now failed each one's own bar and abandoned in a couple of tries,
		# regardless of whether the side was genuinely working. Overshoot
		# past a corner already cleared -- cumulative's own failure mode,
		# measured at 122m off course -- is handled below instead, by
		# actually checking whether the way to the target has opened back
		# up, which is the real "stop now" signal a distance/attempt-based
		# rule was always a proxy for.
		if not abandon and _side_detours >= SIDE_ABANDON_ATTEMPTS:
			var progress := (_player.global_position - _side_commit_origin).dot(perpendicular * _side)
			abandon = progress < SIDE_ABANDON_PROGRESS_M
		if abandon:
			_side = -_side
			_side_detours = 0
			fresh_side = true
	if fresh_side:
		_side_commit_origin = _player.global_position
		if _free_space(perpendicular * _side) < BODY_WIDTH:
			if _free_space(perpendicular * -_side) >= BODY_WIDTH:
				_side = -_side
				_side_detours = 0
				_side_commit_origin = _player.global_position
			else:
				_back_off(to)
				return
	_side_detours += 1
	_detour = perpendicular * _side
	_detour_left = DETOUR_FRAMES + (_side_detours - 1) * DETOUR_GROWTH
	_detour_origin = _player.global_position
	_detour_age = 0


## Reverse out of a pocket neither side can leave. The side choice is cleared
## so the next stall re-probes from wherever backing off got to, which is the
## point: the reason both sides read blocked is usually where the body is
## standing, not where it is trying to go.
func _back_off(to: Vector3) -> void:
	_detour = -to.normalized()
	_detour_left = BACKOFF_FRAMES
	_side = 0.0
	_side_detours = 0
	_detour_origin = _player.global_position
	_detour_age = 0


## +1 or -1: which perpendicular is the better way to slide. A tie goes to +1
## rather than to a coin flip, so a failing run reproduces frame for frame.
##
## A drop beats free space. GATEB-COORD: open air reads as the freest possible
## direction to a horizontal ray, so without checking the ground first the
## probe actively PREFERS walking off a ledge.
func _freer_side(to: Vector3) -> float:
	var side := to.normalized().cross(Vector3.UP).normalized()
	var right_drops := _drops_away(side)
	var left_drops := _drops_away(-side)
	if right_drops != left_drops:
		return -1.0 if right_drops else 1.0
	if _free_space(-side) > _free_space(side) + 0.2:
		return -1.0
	return 1.0


## Does the ground fall away by more than `SAFE_DROP` a step in `direction`?
## True also when there is no ground within `GROUND_PROBE_DEPTH` at all, which
## is the same answer for a walker and a cheaper one to be wrong about.
func _drops_away(direction: Vector3) -> bool:
	var world := _player.get_world_3d()
	var space := world.direct_space_state if world != null else null
	if space == null:
		return false
	var foot := _player.global_position
	var ahead := foot + direction.normalized() * GROUND_LOOK_AHEAD + Vector3.UP * GROUND_PROBE_START
	var query := PhysicsRayQueryParameters3D.create(ahead,
		ahead + Vector3.DOWN * GROUND_PROBE_DEPTH)
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return foot.y - (hit.get("position") as Vector3).y > SAFE_DROP


## Metres of clear space in `direction` for the WHOLE body, capped at
## `PROBE_REACH`. Nine rays -- `PROBE_HEIGHTS` by three lateral offsets across
## `PROBE_HALF_WIDTH` -- and the nearest hit is the answer, because the body
## stops at the first thing any part of it touches. See PROBE_HEIGHTS for why
## one hip-height centre-line ray was not enough (GAME-8).
func _free_space(direction: Vector3) -> float:
	var world := _player.get_world_3d()
	var space := world.direct_space_state if world != null else null
	if space == null:
		return PROBE_REACH
	var forward := direction.normalized()
	if forward.is_zero_approx():
		return PROBE_REACH
	var flank := forward.cross(Vector3.UP).normalized()
	var exclude: Array[RID] = []
	if _player is CollisionObject3D:
		exclude = [(_player as CollisionObject3D).get_rid()]
	var nearest := PROBE_REACH
	for height: float in PROBE_HEIGHTS:
		for offset: float in [-PROBE_HALF_WIDTH, 0.0, PROBE_HALF_WIDTH]:
			var from := _player.global_position + Vector3.UP * height + flank * offset
			var query := PhysicsRayQueryParameters3D.create(from,
				from + forward * PROBE_REACH)
			# Areas are triggers -- interior camera volumes, encounter zones --
			# not things a body can walk into.
			query.collide_with_areas = false
			# An origin already inside geometry means that flank of the body is
			# buried in it, which is the most blocked a direction can be. The
			# default (silently no hit) reads it as wide open instead, and a
			# wedged walker is exactly when this is asked.
			query.hit_from_inside = true
			query.exclude = exclude
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				continue
			nearest = minf(nearest, from.distance_to(hit.get("position", from) as Vector3))
	return nearest


func _push(direction: Vector3) -> void:
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction
	_drive.call(clampf(local.x, -1.0, 1.0), clampf(local.z, -1.0, 1.0))
