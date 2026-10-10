extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 6 lane 6.C. Directive item 17, the Fly half: ONE PLAYER FLIES
## WHILE THE OTHER CARRIES ON PLAYING -- and the host, not the flier, decides
## where the flier is allowed to come down.
##
##   tools/net/run_net_smoke.sh fly
##
## ## The three claims
##
## 1. **A flier is visible in the air to everyone else.** Before this lane a
##    gliding trainer replicated as a trainer FALLING: `remote_trainer.gd`
##    derives its animation state from "off the floor, not moving up", and its
##    viewer drove the body toward that position with `move_and_slide()`, which
##    is a ground capsule being pushed through whatever it clipped. So a friend
##    over Cloudreach read as a friend who had stepped off a cliff, with no
##    carrier over their head. The assertions here are that the friend's body
##    is drawn as flying, at the altitude their owner is actually at, hanging
##    under a carrier that exists as a node.
##
## 2. **The other player never stops playing.** Peer 0 gathers, builds and
##    moves in the SAME coordinator frames peer 1 is airborne in. This is the
##    half of item 17 that gets missed, because a stalled peer looks exactly
##    like a peer with nothing to do.
##
## 3. **A client cannot land where the host would not let it.** A Fly anchor is
##    not decoration: `recover_to_anchor()` teleports the trainer to it, so an
##    anchor a client authors alone is a client-authored teleport destination
##    good for the rest of the session. `docs/specs/MP_ENCOUNTER_PROTOCOL.md`
##    §2 -- no peer authors both an action and the position it was measured
##    against -- so the client proposes and the host answers, and this smoke
##    forges a claim half a kilometre from where the host has that peer and
##    asserts the refusal.
##
## ## Which peer flies, and why it is the CLIENT
##
## Peer 1. Deliberately: the host validating its own landing would be the host
## agreeing with itself, and the whole of claim 3 only exists on a peer that is
## not the authority. Peer 0 is the one doing everything else, which also means
## the "still playing" half is measured on the host -- the process carrying the
## simulation, where a stall would hurt most.
##
## ## Setup versus the feature
##
## `fly_setup` grants `fly_traversal_unlocked` and puts a Galecrest in the
## party, and says SETUP in its own detail string. A player earns both (the
## Windscar trial, and a carrier in the team); a two-peer smoke does not play
## to them. Lane 6.A's smokes reported an ungranted realm key as "enter_realm
## refused", which read as the feature failing; every refusal below that could
## be the fixture names the fixture.

const CARRIER_SPECIES := "galecrest"

const SETTLE_FRAMES := 90

## How far the forged claim is planted from where peer 1 actually is. Well past
## `fly_anchor_arbiter.gd`'s `max_drift_m` of 6 m and past anything
## interpolation lag could account for -- the point is not to probe the edge of
## the tolerance but to prove there IS one.
const FORGED_CLAIM_OFFSET_M := 500.0

## How far apart the flier's own altitude and the altitude their friend draws
## them at may be. The remote body is interpolated toward the replicated
## position at an 0.08 s half-life, and a glide moves; this is roughly what
## that lag buys at the sink rates in `fly_traversal.json`, and it is far
## inside "drawn on the ground while its owner is in the sky", which is the
## failure it is written against.
const ALTITUDE_TOLERANCE_M := 6.0

## How high the trainer is stood before the launch press.
##
## The Meadows has no cliff and no authored updraft -- Fly's home is Cloudreach
## -- so a launch off flat ground here is a hop: about two metres up against
## `fly_traversal.json`'s 2 m/s sink, which is a flight that is over in a
## second. Measured: the first run that launched successfully reported
## `flying (glide) at y=2.86` and was on the ground again before the watching
## peer was asked a single question. Sixty metres is thirty seconds of glide,
## which is a flight two peers can both be doing something during. The launch
## itself is unchanged and still the production input; see `fly_launch`'s own
## comment on why the height is harness placement rather than a poke.
const LAUNCH_HEIGHT_M := 45.0

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
		"a Session exists to host/join (lane 2.A); without it there is no host to decide a landing")
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
		"peer 1 has its own distinct peer id (%d), and is therefore NOT the authority on where it lands"
			% ids[1])

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

	# SETUP, and it says so.
	# A larger step budget than the default 3000 frames: the launch-site search
	# below places the body and waits for collision to stream under it at each
	# candidate, which is real wall clock and is the fixture rather than the
	# feature.
	var setup: Dictionary = await step(1, "fly_setup", {"species": CARRIER_SPECIES}, 9000)
	_check(str(setup.get("verdict", "")) == "PASS",
		"SETUP: peer 1 has the Fly unlock and a %s carrier (%s)"
			% [CARRIER_SPECIES, str(setup.get("detail", ""))])
	if str(setup.get("verdict", "")) != "PASS":
		print("smoke_net_fly: aborting -- the fixture never gave peer 1 a way to fly")
		quit(await finish())
		return

	# --- claim 3 first, on the ground: the host owns the anchor ----------------
	#
	# Before anybody is in the air, because a refusal that arrives mid-glide is
	# harder to read and because the ground is where the honest anchor gets
	# granted in the first place.

	# Let the anchor settle before reading a baseline off it. MEASURED: the
	# launch-site search above relocates the trainer twenty metres, which is
	# further than `landing_anchor.resubmit_m`, so the client legitimately
	# proposes a NEW anchor for where it now stands and the host legitimately
	# grants it -- a few frames after the step returns. A baseline read into
	# that window makes the forgery below look as though it moved the anchor,
	# which is the one thing this smoke must not get wrong in either direction.
	await step(1, "wait", {"frames": 120})
	var grounded_anchor := await _anchor(1)
	_check(bool(grounded_anchor.get("host_validated", false)),
		"peer 1 knows its anchor is the HOST's to give (it is a client, not the listen server)")
	_check(int(grounded_anchor.get("accepts", 0)) >= 1,
		"the host granted peer 1 a real landing anchor as it walked (accepts=%d, proposals=%d)"
			% [int(grounded_anchor.get("accepts", 0)), int(grounded_anchor.get("proposals", 0))])
	var honest_anchor: Array = grounded_anchor.get("anchor", [])
	_check(honest_anchor.size() == 3,
		"peer 1 is holding a committed anchor to be pulled back to (%s)" % str(honest_anchor))

	var here: Array = await probe(1, "position")
	_check(here.size() == 3, "peer 1's position is readable")
	var forged := [float(here[0]) + FORGED_CLAIM_OFFSET_M, float(here[1]),
		float(here[2]) + FORGED_CLAIM_OFFSET_M]
	var refusals_before := int(grounded_anchor.get("refusals", 0))
	var accepts_before := int(grounded_anchor.get("accepts", 0))
	var forgery: Dictionary = await step(1, "fly_claim_anchor", {"at": forged})
	_check(str(forgery.get("verdict", "")) == "PASS",
		"peer 1 was able to SEND a landing claim at all (%s)" % str(forgery.get("detail", "")))

	var after_forgery := await _anchor(1)
	_check(int(after_forgery.get("refusals", 0)) > refusals_before,
		"the host REFUSED a landing %.0f m from where it has peer 1 standing (refusals %d -> %d, code '%s')"
			% [FORGED_CLAIM_OFFSET_M, refusals_before, int(after_forgery.get("refusals", 0)),
				str(after_forgery.get("last_code", ""))])
	_check(str(after_forgery.get("last_code", "")) != "ok",
		"the refusal carries a reason code, not silence (got '%s')"
			% str(after_forgery.get("last_code", "")))
	_check(int(after_forgery.get("accepts", 0)) == accepts_before,
		"the forged claim was not also counted as an accept (%d -> %d)"
			% [accepts_before, int(after_forgery.get("accepts", 0))])
	_check(_same_anchor(honest_anchor, after_forgery.get("anchor", [])),
		"peer 1's committed anchor is UNCHANGED by the forgery -- a refused claim must not become a teleport destination (was %s, now %s)"
			% [str(honest_anchor), str(after_forgery.get("anchor", []))])

	# --- claims 1 and 2: peer 1 flies, peer 0 keeps playing --------------------

	# SETUP: peer 0 needs a creature of its own before it can pick a fight, and
	# something in the satchel before it can drop anything. Neither is what is
	# under test; both are what a player brings.
	var host_creature: Dictionary = await step(0, "deploy_creature", {"species": "terrapup"})
	_check(str(host_creature.get("verdict", "")) == "PASS",
		"SETUP: peer 0 has its own creature out to fight beside (%s)"
			% str(host_creature.get("detail", "")))
	var before_buildings := int(await probe(0, "placed_building_count"))
	await step(0, "storage_grant", {"item": "wood", "n": 8})

	# Printed before the attempt, always. A launch that is refused has a reason
	# and the reason is rarely Fly; the first three local runs of this smoke
	# each reported "the second airborne Jump did not launch" while the real
	# answers were, in order, a farmhouse ceiling and a locomotion lock.
	var pre_launch := await _flight(1, "local")
	print("smoke_net_fly: peer 1 before launch: blockers='%s' locomotion=%s carried=%s on_floor=%s lockout=%s"
		% [str(pre_launch.get("blockers", "?")), str(pre_launch.get("locomotion", "?")),
			str(pre_launch.get("carried", "?")), str(pre_launch.get("on_floor", "?")),
			JSON.stringify(pre_launch.get("lockout", {}))])

	var launched: Dictionary = await step(1, "fly_launch", {"height": LAUNCH_HEIGHT_M})
	_check(str(launched.get("verdict", "")) == "PASS",
		"peer 1's second airborne Jump deployed Fly (%s)" % str(launched.get("detail", "")))
	if str(launched.get("verdict", "")) != "PASS":
		print("smoke_net_fly: aborting -- peer 1 never got off the ground")
		quit(await finish())
		return

	await step(0, "wait", {"frames": SETTLE_FRAMES})

	var mine := await _flight(1, "local")
	_check(bool(mine.get("flying", false)), "peer 1 reports itself flying")
	_check(str(mine.get("species", "")) == CARRIER_SPECIES,
		"peer 1 is hanging off a %s (got '%s')" % [CARRIER_SPECIES, str(mine.get("species", ""))])
	_check(bool(mine.get("carrier", false)),
		"peer 1 has the carrier's art over its own head")

	var drawn := await _drawn_flight(0, ids[1])
	_check(not drawn.is_empty(), "peer 0 holds a trainer body for peer %d at all" % ids[1])
	if not drawn.is_empty():
		_check(bool(drawn.get("flying", false)),
			"peer 0 draws peer %d as FLYING, not as a trainer who stepped off a ledge" % ids[1])
		_check(bool(drawn.get("visible", false)), "peer 0 actually draws the flier")
		_check(str(drawn.get("species", "")) == CARRIER_SPECIES,
			"peer 0 knows which carrier peer %d is under (got '%s')"
				% [ids[1], str(drawn.get("species", ""))])
		_check(bool(drawn.get("carrier", false)),
			"peer 0 built the carrier's art over the remote flier's head -- the friend has a bird, not an empty sky")
		_check(bool(drawn.get("hanging", false)),
			"the hanging pose reached the remote flier's skeleton")
		_check(str(drawn.get("state", "")) != "",
			"peer 0 knows the flight's own state word (got '%s')" % str(drawn.get("state", "")))
		_check(_altitude_error(mine, drawn) <= ALTITUDE_TOLERANCE_M,
			"peer 0 draws the flier at the altitude their owner is actually at: %.2f m apart (tolerance %.1f)"
				% [_altitude_error(mine, drawn), ALTITUDE_TOLERANCE_M])

	# Peer 0 plays, in the same coordinator frames peer 1 is in the air.
	var round_one: Array = await race([
		{"peer": 0, "action": "build_place", "args": {"id": "floor"}},
		{"peer": 1, "action": "wait", "args": {"frames": 120}},
	])
	_check(_all_passed(round_one),
		"peer 0 placed a building WHILE peer 1 was airborne: %s" % _verdicts(round_one))

	var round_two: Array = await race([
		{"peer": 0, "action": "item_drop", "args": {"item": "wood", "n": 2}},
		{"peer": 1, "action": "wait", "args": {"frames": 120}},
	])
	_check(_all_passed(round_two),
		"peer 0 dropped a stack WHILE peer 1 was airborne: %s" % _verdicts(round_two))

	var round_three: Array = await race([
		{"peer": 0, "action": "item_pickup", "args": {}},
		{"peer": 1, "action": "wait", "args": {"frames": 120}},
	])
	_check(_all_passed(round_three),
		"peer 0 picked it back up WHILE peer 1 was airborne: %s" % _verdicts(round_three))

	var round_four: Array = await race([
		{"peer": 0, "action": "engage_wild", "args": {}},
		{"peer": 1, "action": "wait", "args": {"frames": 120}},
	])
	_check(_all_passed(round_four),
		"peer 0 started its own fight WHILE peer 1 was airborne: %s" % _verdicts(round_four))

	var after_buildings := int(await probe(0, "placed_building_count"))
	_check(after_buildings > before_buildings,
		"peer 0's building actually landed in the world during the flight (%d -> %d)"
			% [before_buildings, after_buildings])
	var context_mid := str(await probe(0, "input_context"))
	_check(context_mid == "world" or context_mid == "combat" or context_mid == "combat_aim",
		"peer 0 is still playing its own game beside a flight (context '%s')" % context_mid)

	# --- coming down -----------------------------------------------------------

	# A generous budget: the glide sinks from `LAUNCH_HEIGHT_M` at
	# `fly_traversal.json`'s rates, and the descent is real physics rather than
	# a state change. Measured at 60 m the fall had not finished inside 900
	# frames; the height came down and the budget went up rather than the
	# assertion being softened into "roughly landed".
	var landing: Dictionary = await step(1, "fly_land", {"budget_frames": 1500}, 2400)
	_check(str(landing.get("verdict", "")) == "PASS",
		"peer 1 came down (%s)" % str(landing.get("detail", "")))
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var landed := await _anchor(1)
	_check(int(landed.get("accepts", 0)) > accepts_before,
		"the host granted peer 1's real landing (accepts %d -> %d)"
			% [accepts_before, int(landed.get("accepts", 0))])
	_check(not bool(landed.get("pending", true)),
		"peer 1 is not left waiting on an answer that never came")

	var after_flight := await _drawn_flight(0, ids[1])
	_check(not after_flight.is_empty() and not bool(after_flight.get("flying", false)),
		"peer 0 stopped drawing peer %d as flying once they landed" % ids[1])
	if not after_flight.is_empty():
		_check(not bool(after_flight.get("carrier", false)),
			"the carrier art was taken off the remote body -- a bird left behind is a bird that follows a landed trainer around")
		_check(not bool(after_flight.get("hanging", false)),
			"the hanging pose came off too, so the remote trainer walks again")

	var context_end := str(await probe(0, "input_context"))
	_check(context_end == "world" or context_end == "combat" or context_end == "combat_aim",
		"peer 0 is still playing after the flight ended (context '%s')" % context_end)

	print("smoke_net_fly: %d assertions, %d failures" % [_asserted, failures.size()])
	quit(await finish())


func _check(condition: bool, message: String) -> void:
	_asserted += 1
	check(condition, message)


## The landing-anchor ledger off peer `peer`'s own fly controller.
func _anchor(peer: int) -> Dictionary:
	var row := await _flight(peer, "local")
	var block: Variant = row.get("anchor", {})
	return block if block is Dictionary else {}


func _flight(peer: int, half: String) -> Dictionary:
	var raw = await probe(peer, "flying")
	if not (raw is Dictionary):
		return {}
	var block: Variant = (raw as Dictionary).get(half, {})
	return block if block is Dictionary else {}


## What peer `viewer` DRAWS of peer `owner`'s flight, or {} when it holds no
## body for them.
func _drawn_flight(viewer: int, owner: int) -> Dictionary:
	var raw = await probe(viewer, "flying")
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


## `has()` before `get()`: a row missing either altitude must fail this
## assertion rather than pass it with two zeroes that happen to match.
static func _altitude_error(owner: Dictionary, drawn: Dictionary) -> float:
	if not owner.has("y") or not drawn.has("y"):
		return INF
	return absf(float(owner["y"]) - float(drawn["y"]))


static func _same_anchor(before: Variant, after: Variant) -> bool:
	if not (before is Array) or not (after is Array):
		return false
	var a: Array = before
	var b: Array = after
	if a.size() != 3 or b.size() != 3:
		return false
	return Vector3(float(a[0]), float(a[1]), float(a[2])) \
		.distance_to(Vector3(float(b[0]), float(b[1]), float(b[2]))) < 0.01


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
