extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 6 lane 6.B. Directive item 17, the riding half: ONE PLAYER
## RIDES WHILE THE OTHER CARRIES ON PLAYING.
##
##   tools/net/run_net_smoke.sh riding
##
## ## The bar is in two halves and the second is the one that gets missed
##
## 1. **Peer A is visible on their mount to peer B.** Not "peer A's trainer is
##    somewhere near peer A's creature" -- ON it: drawn as riding, seated
##    rather than standing bolt upright, wearing the seat offset its owner is
##    sitting at, and staying there while the animal moves. And the animal
##    itself wears the saddle its owner built, because OP-0904-3 is that the
##    craft has to be visible on the creature and a friend's screen is a screen.
##
## 2. **Peer B never stops playing.** Peer B builds, gathers and moves DURING
##    peer A's ride, in the same coordinator frames, and every one of those
##    lands. A ride that quietly stalls the other player passes half of item 17
##    and fails the half that matters -- and the failure mode is silent, because
##    a stalled peer looks exactly like a peer that had nothing to do.
##
## ## What would fail before this lane, and what would not
##
## Stated so a reader of a red run knows what they are looking at. `net_carried`
## has been replicated since lane 2.C, so a remote rider was already drawn
## somewhere near the animal -- the assertions that were newly true here are
## `riding` (which creature, and that it is a ride at all), `seated` (the pose
## reached the skeleton; `trainer_model.gd::ride_pose_applied()`'s own comment
## says why VISIBLE and SEATED are different claims) and the saddle on the
## remote animal (which had no way at all to cross the wire: "fitted" is a flag
## in the OWNER's progression store).
##
## ## Setup versus the feature
##
## `ride_setup` grants the saddle and puts a Meadowhart in the party, and says
## SETUP in its own detail string. That is deliberate: lane 6.A's smokes
## reported a missing grant as "enter_realm refused", which read as the feature
## failing. Every refusal below that could be a fixture problem names the
## fixture.

## The species under test and its seat, read from the data rather than typed:
## R8.5 adding a second mount or the owner retiring this one must not leave
## this file quietly asserting against a creature nobody rides.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOUNT_SPECIES := "meadowhart"

## Frames for a spawn packet, the first synchronizer delta and the proxy's own
## snap-to-target to land on the far side. `smoke_net_deploy_two_creatures.gd`'s
## number and its reasoning: ten interpolation half-lives plus the reliable
## spawn's round trip.
const SETTLE_FRAMES := 90

## How far the drawn rider may sit from where the seat offset says they should,
## on the viewer. The rider is attached to the mount's transform rather than
## interpolated separately (`remote_trainer.gd::_follow()`), so the honest
## expectation is "exactly", and this is the allowance for the mount's own
## model scale and a frame of ordering. A rider a metre out of their saddle is
## a rider who is visibly not in it.
const SEAT_TOLERANCE_M := 0.35

## Assertions actually evaluated, printed at the end. A test can pass while
## running FEWER checks than it should -- a null read through `get()` is 0 and
## aborts a branch rather than failing it -- so the count is reported and a run
## that is quietly doing less than it claims is visible in the log.
var _asserted := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	_check(_peers.size() == 2, "coordinator tracked 2 peers")

	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	_check(have_session,
		"a Session exists to host/join (lane 2.A); without it there are no trainer bodies to ride on")
	if not have_session:
		quit(await finish())
		return

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	var hosted: Dictionary = await step(0, "host", {})
	_check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	_check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		_check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	# --- end of the copied handshake ------------------------------------------

	var ids: Array[int] = []
	for i in 2:
		var row = await probe(i, "session")
		ids.append(int((row as Dictionary).get("peer_id", 0)) if row is Dictionary else 0)
	_check(ids[0] == 1, "peer 0 is the listen server (id %d)" % ids[0])
	_check(ids[1] != 0 and ids[1] != ids[0],
		"peer 1 has its own distinct peer id (%d)" % ids[1])

	# SETUP, and a finding: a JOINING peer boots holding an open dialogue box
	# from the opening's `house` beat, and `sequence_director._refresh_lockout()`
	# reads that box as a modal panel every frame -- so the client's locomotion
	# is switched off for the whole session and it can neither walk nor jump.
	# Measured on this lane's own runs; see `_step_dismiss_dialogue()` in
	# `tools/net/peer_runner.gd` for the probe row that pinned it and why the
	# fix belongs to the opening's lane rather than to this one. Pressed
	# through here the way a player presses through it.
	for i in 2:
		var cleared: Dictionary = await step(i, "dismiss_dialogue", {})
		_check(str(cleared.get("verdict", "")) == "PASS",
			"SETUP: peer %d is holding the world rather than a dialogue box (%s)"
				% [i, str(cleared.get("detail", ""))])

	# Peer 1 gets a creature of its own too. Not decoration: it is what makes
	# the "which creature is the mount" question have a wrong answer available.
	var theirs: Dictionary = await step(1, "deploy_creature", {"species": "terrapup"})
	_check(str(theirs.get("verdict", "")) == "PASS",
		"SETUP: peer 1 has its own creature out (%s)" % str(theirs.get("detail", "")))

	# SETUP, and it says so: the saddle and the Meadowhart.
	var setup: Dictionary = await step(0, "ride_setup", {"species": MOUNT_SPECIES})
	_check(str(setup.get("verdict", "")) == "PASS",
		"SETUP: peer 0 has a %s out and a saddle in the satchel (%s)"
			% [MOUNT_SPECIES, str(setup.get("detail", ""))])
	if str(setup.get("verdict", "")) != "PASS":
		# Nothing below is meaningful without a mount, and a cascade of
		# feature-shaped failures from a fixture problem is the exact confusion
		# this smoke's header is about.
		print("smoke_net_riding: aborting -- the fixture never stood the mount up")
		quit(await finish())
		return

	var got_on: Dictionary = await step(0, "ride_mount", {})
	_check(str(got_on.get("verdict", "")) == "PASS",
		"peer 0 pressed the mount and got on (%s)" % str(got_on.get("detail", "")))

	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	# --- half one: peer 1 can see peer 0 on their animal -----------------------

	var local_ride = await probe(0, "riding")
	var mine: Dictionary = (local_ride as Dictionary).get("local", {}) if local_ride is Dictionary else {}
	_check(bool(mine.get("mounted", false)), "peer 0 reports itself mounted")
	_check(str(mine.get("species", "")) == MOUNT_SPECIES,
		"peer 0 is on a %s (got '%s')" % [MOUNT_SPECIES, str(mine.get("species", ""))])
	_check(bool(mine.get("saddle_worn", false)),
		"mounting fitted the saddle on peer 0's own animal (OP-0904-3)")

	var drawn := await _drawn_ride(1, ids[0])
	_check(not drawn.is_empty(),
		"peer 1 holds a trainer body for peer %d at all" % ids[0])
	if not drawn.is_empty():
		_check(bool(drawn.get("riding", false)),
			"peer 1 draws peer %d as RIDING, not merely as carried" % ids[0])
		_check(bool(drawn.get("visible", false)),
			"peer 1 actually draws peer %d's rider" % ids[0])
		_check(str(drawn.get("mount_species", "")) == MOUNT_SPECIES,
			"peer 1 knows which animal peer %d is on: a %s (got '%s')"
				% [ids[0], MOUNT_SPECIES, str(drawn.get("mount_species", ""))])
		_check(bool(drawn.get("seated", false)),
			"the seated pose reached the skeleton on peer 1's copy -- a rider drawn standing on a creature's back is OP-0904-3 reopened across the wire")
		_check(bool(drawn.get("saddled", false)) and bool(drawn.get("mount_saddle_worn", false)),
			"the saddle peer 0 built is worn by the animal on peer 1's screen (published %s, worn %s)"
				% [str(drawn.get("saddled", false)), str(drawn.get("mount_saddle_worn", false))])
		_check(_seat_error(drawn) <= SEAT_TOLERANCE_M,
			"peer 1 draws the rider IN the saddle: %.2f m from the seat offset (tolerance %.2f)"
				% [_seat_error(drawn), SEAT_TOLERANCE_M])

	# --- half two: peer 1 never stops playing ---------------------------------
	#
	# The two peers act in the SAME coordinator frame (`race`), which is the
	# harness contract's own honest limit -- it proves the two were in flight
	# together, not that two clocks ticked on the same nanosecond. That is
	# exactly the claim item 17 needs: peer B was gathering, building and
	# moving while peer A was mid-ride.

	var before_buildings := int(await probe(1, "placed_building_count"))
	var before_position: Array = await probe(1, "position")
	_check(before_position.size() == 3, "peer 1's position is readable before the ride")

	# Peer 1 has to have something to gather. SETUP, and it is peer 1's own
	# satchel rather than anything the ride touches.
	await step(1, "storage_grant", {"item": "wood", "n": 8})
	# And its screen has to be its own. The opening's dialogue box opens partway
	# through the `house` beat rather than at boot, so clearing it once after
	# the handshake is not enough -- see the finding at the first `for i in 2`
	# block above.
	var freed: Dictionary = await step(1, "dismiss_dialogue", {})
	_check(str(freed.get("verdict", "")) == "PASS",
		"SETUP: peer 1's own screen is its own before it is asked to play (%s)"
			% str(freed.get("detail", "")))

	var round_one: Array = await race([
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": 0.0, "y": -1.0, "frames": 150}},
		{"peer": 1, "action": "build_place", "args": {"id": "floor"}},
	])
	_check(_all_passed(round_one),
		"peer 1 placed a building WHILE peer 0 rode: %s" % _verdicts(round_one))

	var round_two: Array = await race([
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": 1.0, "y": -1.0, "frames": 150}},
		{"peer": 1, "action": "item_drop", "args": {"item": "wood", "n": 2}},
	])
	_check(_all_passed(round_two),
		"peer 1 dropped a stack WHILE peer 0 rode: %s" % _verdicts(round_two))

	var round_three: Array = await race([
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": -1.0, "y": -1.0, "frames": 150}},
		{"peer": 1, "action": "item_pickup", "args": {}},
	])
	_check(_all_passed(round_three),
		"peer 1 picked it back up WHILE peer 0 rode: %s" % _verdicts(round_three))

	var round_four: Array = await race([
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": 0.0, "y": -1.0, "frames": 150}},
		{"peer": 1, "action": "stick", "args": {"stick": "left", "x": 0.0, "y": -1.0, "frames": 150}},
	])
	_check(_all_passed(round_four),
		"both peers drove their own stick in the same frames: %s" % _verdicts(round_four))

	# Peer 1 FIGHTS while peer 0 rides. The third of item 17's three verbs, and
	# the one with the sharpest edge: a fight is the thing that ENDS a ride
	# (`riding_controller._riding_allowed()` stands down for a running
	# `CombatManager`), so this is also the test that peer 1's fight is peer
	# 1's -- peer 0 must still be on their animal at the end of it.
	#
	# `budget_frames: 6000` on peer 1's entry, found red in CI (run 34049435929,
	# "peer 1 ERROR (no verdict)") against race()'s own 3000-frame/~55s default.
	# `require_record: false` below is DOCUMENTED to mean the record never binds
	# for a client's wild fight (4.C H1), so `_step_engage_wild` is GUARANTEED,
	# every run, to spend its full 20 + settle(240) + bind_budget(600) = 860
	# physics frames before returning -- not a worst case, the only case. 3000
	# frames is only ~3.5x that at nominal speed, thin margin next to how
	# generously this file's own fly/shared_boss cousins budget a step whose
	# cost is known up front (`smoke_net_fly.gd`, `smoke_net_shared_boss.gd`).
	# The fix widens the CLOCK, not the CLAIM: `_all_passed(round_five)` still
	# requires peer 1's fight to actually start and be observed to.
	var round_five: Array = await race([
		{"peer": 0, "action": "stick", "args": {"stick": "left", "x": 0.0, "y": -1.0, "frames": 150}},
		{"peer": 1, "action": "engage_wild",
			"args": {"settle": 240, "require_record": false}, "budget_frames": 6000},
	])
	_check(_all_passed(round_five),
		"peer 1 started a fight WHILE peer 0 rode: %s" % _verdicts(round_five))
	# `require_record: false` above, and it is a finding rather than a
	# convenience. A CLIENT's engage starts a local fight but does not bind a
	# host encounter record inside four seconds -- measured twice here, at 30
	# and at 240 settle frames. `tests/smoke_net_shared_wild_fight.gd` only
	# ever engages on the HOST, so no net smoke had exercised the client side
	# before. That contract is `docs/specs/MP_ENCOUNTER_PROTOCOL.md` §4 and
	# lane 4.C's, not riding's; recorded as finding F3 in this lane's report
	# rather than asserted on here, where a red would name the wrong lane.
	# What THIS smoke needs and does assert is the claim item 17 makes: peer 1
	# is in a fight of its own while peer 0 is on an animal.
	_check(str(await probe(1, "input_context")) == "combat",
		"peer 1 is IN its fight, not merely reported as having started one")
	# There is deliberately no `strike` here. `_step_strike` submits through
	# `submit_encounter_intent()`, which refuses with "this peer is not in a
	# networked fight" for want of the very record finding F3 is about -- so a
	# swing would be this smoke going red on lane 4.C's contract while claiming
	# to be about riding. Measured, not assumed: it was tried and it failed for
	# exactly that reason.

	var after_buildings := int(await probe(1, "placed_building_count"))
	_check(after_buildings > before_buildings,
		"peer 1's building actually landed in the world during the ride (%d -> %d)"
			% [before_buildings, after_buildings])

	# Peer 1's trainer is somewhere else in the world than it started.
	#
	# WORDED AS RELOCATION RATHER THAN AS WALKING, and the distinction is
	# measured rather than tactful. On the first local run of this smoke peer 1
	# held full stick forward for 150 frames and travelled **0.00 m**. That is
	# not this lane's ride: `tests/smoke_net_movement_two_peers.gd`'s own
	# constant block records the same thing from the other side -- a fresh boot
	# starts inside Grandpa's farmhouse and the client (never the host) stops
	# dead against a wall about three metres out, at 2.71 m over twice as many
	# frames. What this assertion is for is "peer 1 is not frozen", and the
	# engage above relocates it to the wild it picked a fight with, which is
	# the game moving the body rather than the harness asserting it did.
	# Walking a longer line is a question about where a net smoke STARTS, and
	# that smoke's header already assigns it to whichever lane teaches the
	# harness to seed a post-opening save.
	var after_position: Array = await probe(1, "position")
	_check(_moved(before_position, after_position) > 0.5,
		"peer 1's trainer is not frozen where it stood: it is %.2f m away, on floor=%s"
			% [_moved(before_position, after_position), str(await probe(1, "on_floor"))])

	# `combat` is a playing context, and after the round above it is the
	# EXPECTED one: peer 1 is mid-fight. What this rules out is a panel, a
	# fade, a lockout or a dead scene -- the shapes a peer stalled by somebody
	# else's ride would actually take.
	var context_after := str(await probe(1, "input_context"))
	_check(context_after == "world" or context_after == "combat" or context_after == "combat_aim",
		"peer 1 is still playing its own game after five rounds beside a ride (context '%s')"
			% context_after)

	# --- and the ride survived all of it ---------------------------------------

	var still = await probe(0, "riding")
	var still_mine: Dictionary = (still as Dictionary).get("local", {}) if still is Dictionary else {}
	_check(bool(still_mine.get("mounted", false)),
		"peer 0 is STILL on the mount after everything peer 1 did")

	var still_drawn := await _drawn_ride(1, ids[0])
	_check(not still_drawn.is_empty() and bool(still_drawn.get("riding", false)),
		"peer 1 still draws peer %d as riding at the end" % ids[0])
	if not still_drawn.is_empty():
		_check(_seat_error(still_drawn) <= SEAT_TOLERANCE_M,
			"the rider is still IN the saddle after the animal has been driven around: %.2f m"
				% _seat_error(still_drawn))
		_check(bool(still_drawn.get("mount_saddle_worn", false)),
			"the animal is still wearing its saddle on peer 1's screen")

	# --- getting off ------------------------------------------------------------

	var got_off: Dictionary = await step(0, "ride_dismount", {})
	_check(str(got_off.get("verdict", "")) == "PASS",
		"peer 0 got off in one piece (%s)" % str(got_off.get("detail", "")))
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var after_ride := await _drawn_ride(1, ids[0])
	_check(not after_ride.is_empty() and not bool(after_ride.get("riding", false)),
		"peer 1 stopped drawing peer %d as a rider once they got off" % ids[0])
	if not after_ride.is_empty():
		_check(not bool(after_ride.get("seated", false)),
			"the seated pose was taken off peer 1's copy of the trainer too")
		_check(bool(after_ride.get("mount_saddle_worn", false)),
			"the saddle STAYS on the animal after dismount (OP-0904-3: it is the visible proof of the craft, not a ride-only prop)")

	var context_end := str(await probe(1, "input_context"))
	_check(context_end == "world" or context_end == "combat" or context_end == "combat_aim",
		"peer 1 is still playing after peer 0's ride ended (context '%s')" % context_end)

	print("smoke_net_riding: %d assertions, %d failures" % [_asserted, failures.size()])
	quit(await finish())


## Every `check` goes through here so the count is honest. `has()` before
## `get()` is the same rule one level down: a probe row read straight through
## `get()` yields null, `bool(null)` is a script error and `int(null)` is 0, so
## a missing key would abort a branch rather than fail it.
func _check(condition: bool, message: String) -> void:
	_asserted += 1
	check(condition, message)


## What peer `viewer` DRAWS of peer `owner`'s ride, or {} when it holds no body
## for them. Awaited fresh at each use rather than cached: the whole point of
## the second half is that things kept moving in between.
func _drawn_ride(viewer: int, owner: int) -> Dictionary:
	var raw = await probe(viewer, "riding")
	if not (raw is Dictionary):
		return {}
	var remote: Variant = (raw as Dictionary).get("remote", {})
	if not (remote is Dictionary):
		return {}
	var key := str(owner)
	if not (remote as Dictionary).has(key):
		return {}
	var row: Variant = (remote as Dictionary)[key]
	return row if row is Dictionary else {}


## How far the drawn rider is from the seat the species authors.
##
## Compared against `species.json`'s own `mount_offset` rather than against a
## number typed here, for the reason the species constant above gives -- and
## `has()`-guarded, because a row with no `gap` must fail this assertion rather
## than pass it with `float(null)` = 0.0.
func _seat_error(row: Dictionary) -> float:
	if not row.has("gap"):
		return INF
	var gap := float(row["gap"])
	if gap < 0.0:
		return INF
	var offset: Vector3 = SPECIES.rideable(MOUNT_SPECIES).get("mount_offset", Vector3.UP)
	return absf(gap - offset.length())


static func _all_passed(results: Array) -> bool:
	if results.is_empty():
		return false
	for entry: Variant in results:
		if not (entry is Dictionary):
			return false
		var verdict: Variant = (entry as Dictionary).get("verdict", {})
		if not (verdict is Dictionary) or str((verdict as Dictionary).get("verdict", "")) != "PASS":
			return false
	return true


static func _verdicts(results: Array) -> String:
	var parts := PackedStringArray()
	for entry: Variant in results:
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var verdict: Variant = row.get("verdict", {})
		var d: Dictionary = verdict if verdict is Dictionary else {}
		parts.append("peer %d %s (%s)" % [int(row.get("peer", -1)),
			str(d.get("verdict", "?")), str(d.get("detail", ""))])
	return "; ".join(parts)


static func _moved(before: Variant, after: Variant) -> float:
	if not (before is Array) or not (after is Array) \
			or (before as Array).size() != 3 or (after as Array).size() != 3:
		return -1.0
	var a: Array = before
	var b: Array = after
	return Vector3(float(a[0]), float(a[1]), float(a[2])) \
		.distance_to(Vector3(float(b[0]), float(b[1]), float(b[2])))
