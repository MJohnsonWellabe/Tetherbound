extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 2 lane 2.C. THE player-visible outcome of the lane: two people
## on a LAN see each other walk around the Meadows.
##
##   godot --headless --path . --script tests/smoke_net_movement_two_peers.gd
##
## or, with isolation, orphan-kill and a run-directory artifact:
##
##   tools/net/run_net_smoke.sh net_movement_two_peers
##
## ## What it asserts
##
## Both peers boot the Meadows. Each peer then holds the stick forward for 20 m
## of real walking while the other stands still, and after each leg BOTH peers
## are asked two things: where their own body is (`probe position`), and where
## they are drawing the OTHER peer's body (`probe remote_trainers`, lane 2.C's
## arm in `tools/net/peer_runner.gd`, which reports every node in the
## `remote_trainer` group with the position that process is actually rendering
## it at). The gap between those two numbers is the whole deliverable.
##
## ## The tolerances, and why they are two numbers
##
## A remote body is "seen" within 1.5 m at rest and 4.0 m in motion of the
## owner's own reported position. They differ because the remote is
## deliberately interpolated (`remote_trainer.gd::INTERP_HALF_LIFE_S`): a body
## that is walking is always a little behind its owner and that lag is the
## smoothing working, not a fault, whereas a body that has come to a stop has
## no excuse and must converge. The numbers are constants HERE rather than in
## `data/config/multiplayer.json` because they are this smoke's assertion, not
## a game tunable, and `multiplayer.json` belongs to lane 2.A.
##
## ## Status at the time of writing
##
## `Session` (lane 2.A) does not exist in this lane's base. Without it there is
## nothing to host or join, `trainer_spawn.gd` correctly does nothing, and this
## smoke cannot pass — it would report zero remote bodies. It is written and
## left RED on purpose. Stubbing a fake session to make it green would prove
## the stub, which is exactly the "a retry that turns 0-for-1 into green is a
## finding, not a pass" trap in CLAUDE.md. Run it once 2.A has landed; the
## first thing to check if it fails is that the remote body exists at all
## (`remote_trainers` non-empty), then that its authority is the other peer
## (`mine == false` on the viewer), and only then the distances.

## Lane 2.C's fixed budget: how far a remote body may be from where its owner
## says it is before it is not "seen".
const NEAR_REST_M := 1.5
const NEAR_MOTION_M := 4.0
## The walk each peer takes. `stick` at full deflection is ~4.2 m/s of walk
## speed (`data/config/movement.json`), so 300 physics frames is comfortably
## past 20 m even with the opening beat's settle.
const WALK_M := 20.0
const WALK_FRAMES := 300
## Frames to let the last packets land and the interpolation converge before
## the at-rest comparison. Roughly ten half-lives.
const SETTLE_FRAMES := 60


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

	# A session has to exist before anyone can see anyone. This is the honest
	# gate: if it is not there, say so once and stop, rather than reporting a
	# pile of downstream failures that all mean the same thing.
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there are no remote bodies to see")
	if not have_session:
		quit(await finish())
		return

	# Both peers must be standing in each other's world before either walks:
	# one body per peer, on every peer, including each peer's own invisible
	# outbound proxy (`remote_trainer.gd` hides the body whose authority is
	# this process — the owner already has a local rig standing in that spot).
	for i in 2:
		var bodies = await probe(i, "remote_trainers")
		var d: Dictionary = bodies if bodies is Dictionary else {}
		check(d.size() == 2,
			"peer %d sees 2 trainer bodies (its own proxy and the other peer's), got %d"
				% [i, d.size()])
		var others := _others(d)
		check(others.size() == 1, "peer %d sees exactly 1 body it does not own" % i)
		for row in others:
			check(not str(row.get("name", "")).strip_edges().is_empty(),
				"peer %d's view of the other trainer carries a nameplate ('%s')"
					% [i, str(row.get("name", ""))])
			check(bool(row.get("visible", false)),
				"peer %d actually draws the other trainer" % i)

	# One peer walks at a time, so the moving side and the standing side are
	# both measured on every leg.
	for mover in 2:
		var watcher := 1 - mover
		var before = await probe(mover, "position")

		var v: Dictionary = await step(mover, "stick",
			{"x": 0.0, "y": -1.0, "frames": WALK_FRAMES})
		check(str(v.get("verdict", "")) == "PASS",
			"peer %d held the stick forward (%s)" % [mover, str(v.get("detail", ""))])

		# In motion: sample while the mover has only just stopped pressing, so
		# the interpolation is still catching up. This is the 4.0 m case.
		var moving_owner = await probe(mover, "position")
		var moving_seen = await probe(watcher, "remote_trainers")
		var moved_m := _planar(before, moving_owner)
		check(moved_m >= WALK_M,
			"peer %d walked at least %.0f m (walked %.2f m)" % [mover, WALK_M, moved_m])

		var gap_moving := _gap_to_other(moving_seen, moving_owner)
		check(gap_moving >= 0.0,
			"peer %d had a body for peer %d to look at while it walked" % [mover, watcher])
		check(gap_moving >= 0.0 and gap_moving <= NEAR_MOTION_M,
			"peer %d saw peer %d within %.1f m in motion (%.2f m)"
				% [watcher, mover, NEAR_MOTION_M, gap_moving])

		# At rest: let the packets land, then demand real convergence.
		await step(watcher, "wait", {"frames": SETTLE_FRAMES})
		var rest_owner = await probe(mover, "position")
		var rest_seen = await probe(watcher, "remote_trainers")
		var gap_rest := _gap_to_other(rest_seen, rest_owner)
		check(gap_rest >= 0.0 and gap_rest <= NEAR_REST_M,
			"peer %d saw peer %d within %.1f m at rest (%.2f m)"
				% [watcher, mover, NEAR_REST_M, gap_rest])

		# The standing peer must not have been dragged around by the other's
		# movement: a shared rig, or a synchronizer pointed at the wrong body,
		# shows up here and nowhere else.
		var watcher_pos = await probe(watcher, "position")
		var watcher_seen_by_mover = await probe(mover, "remote_trainers")
		var gap_watcher := _gap_to_other(watcher_seen_by_mover, watcher_pos)
		check(gap_watcher >= 0.0 and gap_watcher <= NEAR_REST_M,
			"peer %d still saw the standing peer %d within %.1f m (%.2f m)"
				% [mover, watcher, NEAR_REST_M, gap_watcher])

	var hashes_ok := await assert_all_hashes_equal(300)
	check(hashes_ok, "both peers' world state hashes agree (contract §7)")

	quit(await finish())


## The bodies in a `remote_trainers` probe that this process does NOT own —
## i.e. the other peers, not its own outbound proxy.
func _others(bodies: Dictionary) -> Array:
	var out: Array = []
	for key in bodies.keys():
		var row: Variant = bodies[key]
		if row is Dictionary and not bool((row as Dictionary).get("mine", false)):
			out.append(row)
	return out


## Planar distance from the one body this process does not own to where its
## owner says it is. -1.0 when there is no such body, so "nothing to see" is
## distinguishable from "seen, but far away".
func _gap_to_other(bodies: Variant, owner_pos: Variant) -> float:
	var d: Dictionary = bodies if bodies is Dictionary else {}
	var others := _others(d)
	if others.size() != 1:
		return -1.0
	return _planar((others[0] as Dictionary).get("pos", []), owner_pos)


static func _planar(a: Variant, b: Variant) -> float:
	if not (a is Array) or not (b is Array):
		return -1.0
	var aa: Array = a
	var bb: Array = b
	if aa.size() != 3 or bb.size() != 3:
		return -1.0
	return Vector2(float(bb[0]) - float(aa[0]), float(bb[2]) - float(aa[2])).length()
