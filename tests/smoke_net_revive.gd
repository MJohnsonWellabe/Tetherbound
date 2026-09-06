extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 4 lane 4.E. THE player-visible outcome of the lane: a player
## who goes down is a problem their friend can solve, not the end of the fight.
##
##   tools/net/run_net_smoke.sh revive
##
## ## What it asserts, in the order a player would experience it
##
## Two peers boot the Meadows, host and join. Peer 1 takes a lethal hit through
## the game's own signal path. Then:
##
##   1. Peer 1 is DOWN, not dead: a window is open with time left on it, its
##      locomotion is off, and its health is zero.
##   2. Peer 1's satchel is still on its back. This is asserted explicitly and
##      it is half the deliverable -- a revive that still costs you your bag is
##      not a revive, so the world's `death_satchels` count and the live
##      satchel-node count must both be exactly what they were before the hit,
##      on BOTH peers.
##   3. Peer 0 knows peer 1 is down, by peer id, off its own `DownedState`.
##   4. Peer 0 stands over the body and HOLDS the real `interact` action for
##      longer than `revive_hold_s`. Nothing about that is a harness arm: it is
##      the same `hold`/`release` injection every other smoke presses buttons
##      with, and the revive is decided by `downed_state.gd` reading the action
##      and the distance.
##   5. Peer 1 is UP: not downed, revived exactly once, expired never, health
##      above zero, locomotion back on -- and still no satchel.
##   6. Peer 1 is PLAYING AGAIN. Not "flagged as alive": it holds the stick
##      forward and its body actually moves across the ground. A player who is
##      standing up but cannot walk has not been revived.
##
## ## Why the reviver is placed rather than walked
##
## `stand_by_downed` puts peer 0's rig 1.8 m from peer 1's body instead of
## driving `move_to`. What `move_to` measures is the stick navigator, which
## this repo has open stall findings against (FENCE-CORNER-0903) and which is
## not what this smoke is about; standing the reviver there is setup, the same
## way lane 3.B's `pickup_stand` stands its prop rather than making the smoke
## walk to one. The revive itself is not helped along by anything.
##
## ## The debug order if it fails
##
## Does peer 1 have a window at all (`downed.local_downed`, and
## `downed.available` before that -- false means `/root/Game/DownedState` was
## never mounted, which is `player_death.gd::build()` not running, not a revive
## bug). Then does peer 0 know about it (`downed.downed_peers` non-empty --
## empty means the `_rpc_downed` broadcast did not resolve, i.e. the two
## processes disagree about the node path). Then is peer 0 actually within
## `revive_radius_m` (`stand_by_downed`'s own detail line reports the gap).
## Only then is it the hold.

## Frames of held `interact`. `revive_hold_s` is 3.0 s in
## `data/config/multiplayer.json`, which is 180 frames at 60 Hz; 300 is that
## with real margin, and still a small fraction of the 45 s window so a slow
## runner cannot turn a revive into a timeout.
const HOLD_FRAMES := 300
## Frames given to the `_rpc_downed` broadcast before peer 0 is asked whether
## it heard it. One loopback round trip is single-digit milliseconds (the ENet
## spike measured a 6.9 ms median RTT); 60 frames is a full second.
const SETTLE_FRAMES := 60
## How far the revived peer must walk to count as playing again. Small on
## purpose: a fresh boot starts inside Grandpa's farmhouse with a wall about
## three metres ahead (`smoke_net_movement_two_peers.gd` measured 2.71 m for
## exactly this hold), so the discriminating question is 0.0 m versus anything,
## not how far.
const WALK_M := 0.5
const WALK_FRAMES := 240


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	# --- the handshake, copied from smoke_net_movement_two_peers.gd ----------
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there is nobody to revive anybody")
	if not have_session:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a world (%s)" % str(hosted.get("detail", "")))
	var host_session = await probe(0, "session")
	var port := int((host_session as Dictionary).get("enet_port", 0)) if host_session is Dictionary else 0
	var joined: Dictionary = await step(1, "join", {"host": "127.0.0.1", "port": port})
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined peer 0's world on port %d (%s)" % [port, str(joined.get("detail", ""))])
	for i in 2:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry holds both players (%s)" % [i, str(seen.get("detail", ""))])
	# --- end of the copied handshake block ----------------------------------

	# Baseline BEFORE anything lethal, so "no satchel was dropped" is measured
	# against what this world actually holds rather than against an assumed
	# zero. A world that ships with a satchel standing would make an assumed
	# zero fail for the wrong reason.
	var base: Array = []
	for i in 2:
		var row := await _downed(i)
		check(bool(row.get("available", false)),
			"peer %d mounted /root/Game/DownedState (lane 4.E)" % i)
		check(_has(row, "satchels"), "peer %d's downed probe reports a satchel count" % i)
		check(not bool(row.get("local_downed", true)),
			"peer %d is not downed before anything happens" % i)
		base.append(row)
	if failures.size() > 0:
		# Every check below reads one of these; a missing probe would produce a
		# page of failures that all mean "the probe is not there".
		quit(await finish())
		return

	var base_records := int((base[1] as Dictionary).get("satchels", -1))
	var base_nodes := int((base[1] as Dictionary).get("satchel_nodes", -1))
	var window_s := float((base[1] as Dictionary).get("window_s", 0.0))
	check(window_s > 0.0,
		"peer 1's downed window is a real number of seconds (%.1f)" % window_s)

	# --- 1. peer 1 goes down -------------------------------------------------
	var felled: Dictionary = await step(1, "go_down", {})
	check(str(felled.get("verdict", "")) == "PASS",
		"peer 1 took a lethal hit through the shipping `died` path (%s)"
			% str(felled.get("detail", "")))
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	var down := await _downed(1)
	check(bool(down.get("local_downed", false)),
		"peer 1 is DOWN, not dead (local_downed)")
	var remaining := float(down.get("remaining_s", 0.0))
	check(remaining > 0.0 and remaining <= window_s,
		"peer 1 has %.1f s left of its %.1f s window" % [remaining, window_s])
	check(not bool(down.get("locomotion", true)),
		"a downed peer 1 cannot walk away")
	check(float(down.get("health", -1.0)) <= 0.0,
		"peer 1's health really is at zero while it is down (%.1f)"
			% float(down.get("health", -1.0)))

	# --- 2. going down dropped no satchel ------------------------------------
	check(int(down.get("satchels", -1)) == base_records,
		"going down dropped NO satchel record on peer 1 (%d, was %d)"
			% [int(down.get("satchels", -1)), base_records])
	check(int(down.get("satchel_nodes", -1)) == base_nodes,
		"going down stood NO satchel body on peer 1 (%d, was %d)"
			% [int(down.get("satchel_nodes", -1)), base_nodes])
	var host_down := await _downed(0)
	check(int(host_down.get("satchels", -1)) == int((base[0] as Dictionary).get("satchels", -2)),
		"the HOST's world gained no satchel record either (%d, was %d)"
			% [int(host_down.get("satchels", -1)),
				int((base[0] as Dictionary).get("satchels", -2))])

	# --- 3. peer 0 knows ------------------------------------------------------
	var known: Array = host_down.get("downed_peers", [])
	check(known.size() == 1,
		"peer 0 knows exactly one teammate is down (knows %d)" % known.size())

	# --- 4. peer 0 stands over the body and holds interact -------------------
	var stood: Dictionary = await step(0, "stand_by_downed", {"offset": 1.8})
	check(str(stood.get("verdict", "")) == "PASS",
		"peer 0 stood over peer 1's body (%s)" % str(stood.get("detail", "")))
	var held: Dictionary = await step(0, "hold", {"action": "interact", "frames": HOLD_FRAMES})
	check(str(held.get("verdict", "")) == "PASS",
		"peer 0 held interact for %d frames (%s)" % [HOLD_FRAMES, str(held.get("detail", ""))])
	await step(0, "release", {"action": "interact"})
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	# --- 5. peer 1 is up ------------------------------------------------------
	var up := await _downed(1)
	check(not bool(up.get("local_downed", true)),
		"peer 1's window is closed")
	check(int(up.get("revived", 0)) == 1,
		"peer 1 was revived exactly once (%d)" % int(up.get("revived", 0)))
	check(int(up.get("expired", -1)) == 0,
		"peer 1's window never expired -- the friend got there first (%d expiries)"
			% int(up.get("expired", -1)))
	check(float(up.get("health", -1.0)) > 0.0,
		"peer 1 stood up with health above zero (%.1f)" % float(up.get("health", -1.0)))
	check(bool(up.get("locomotion", false)),
		"peer 1's locomotion is back on")
	check(int(up.get("satchels", -1)) == base_records,
		"a revived peer 1 still has its bag: no satchel record was ever written (%d, was %d)"
			% [int(up.get("satchels", -1)), base_records])
	check(int(up.get("satchel_nodes", -1)) == base_nodes,
		"no satchel body ever stood for peer 1 (%d, was %d)"
			% [int(up.get("satchel_nodes", -1)), base_nodes])

	var host_up := await _downed(0)
	check((host_up.get("downed_peers", []) as Array).is_empty(),
		"peer 0's revive prompt is gone: it no longer holds a downed teammate")

	# --- 6. peer 1 is PLAYING AGAIN -------------------------------------------
	var before = await probe(1, "position")
	var walked: Dictionary = await step(1, "stick", {"x": 0.0, "y": -1.0, "frames": WALK_FRAMES})
	check(str(walked.get("verdict", "")) == "PASS",
		"peer 1 held the stick forward after being revived (%s)" % str(walked.get("detail", "")))
	var after = await probe(1, "position")
	var moved := _planar(before, after)
	check(moved >= WALK_M,
		"peer 1 is PLAYING AGAIN: it walked %.2f m after the revive (needed %.1f m)"
			% [moved, WALK_M])

	quit(await finish())


## The `downed` probe, always as a Dictionary so every reader below can use
## `has()`/`get()` without a type test of its own. An empty Dictionary is
## indistinguishable from a null probe on purpose: both mean "nothing to read",
## and the `available` check above is what turns that into one honest failure
## instead of a page of them.
func _downed(peer: int) -> Dictionary:
	var raw = await probe(peer, "downed")
	return raw if raw is Dictionary else {}


## `has()` before `get()`. A key that is absent reads back as null, `int(null)`
## is 0, and a comparison against 0 can pass for reasons that have nothing to
## do with the game -- which is exactly the shape of a smoke that runs fewer
## assertions than it looks like it does.
static func _has(row: Dictionary, key: String) -> bool:
	return row.has(key) and row[key] != null


static func _planar(a: Variant, b: Variant) -> float:
	if not (a is Array) or not (b is Array):
		return -1.0
	var aa: Array = a
	var bb: Array = b
	if aa.size() != 3 or bb.size() != 3:
		return -1.0
	return Vector2(float(bb[0]) - float(aa[0]), float(bb[2]) - float(aa[2])).length()
