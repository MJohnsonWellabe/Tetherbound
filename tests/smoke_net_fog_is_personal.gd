extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 5 lane 5.C. THE experience test of the lane, in one sentence:
## **a player who joins a host who has explored the whole Meadows must see their
## own fog, not the host's** — while a fact about the WORLD, such as an alpha
## somebody has already beaten, is shared with them at once.
##
##   godot --headless --path . --script tests/smoke_net_fog_is_personal.gd
##
## or, with isolation, orphan-kill and a run-directory artifact:
##
##   tools/net/run_net_smoke.sh fog_is_personal
##
## ## Why both halves are asserted, and why one alone would prove nothing
##
## A smoke that only showed "the joiner's fog is not the host's" would pass just
## as happily in a build where nothing replicates at all — two processes that
## never spoke also have different fog. So the same run has to show the other
## direction on the same pair of peers in the same session: the host beats an
## alpha, and the JOINER learns it. Personal state stays apart; world state
## crosses. Either half failing is a real failure, and a run where the world
## half never crosses tells you the "separate fog" half was measuring nothing.
##
## ## What personal means here, concretely
##
## Fog cells, discovered landmarks and pinned alphas live on a `MapState`
## (`autoload/map_state.gd`), the `MapState` lives on `PlayerState.maps[realm]`,
## and `Game.map` resolves to the LOCAL player's. The join snapshot is
## `WorldState.save_data()` (`session.gd::_rpc_snapshot`) and carries no map
## payload at all, so there is no wire on which one peer's fog could reach
## another — that is the property this smoke pins, so that a later lane adding
## a map payload to the snapshot fails here rather than in a playtest.
##
## The joiner's revealed area is compared against its OWN pre-handshake
## baseline, not merely against the host's. Those are two different claims and
## both matter: equal-to-baseline says the handshake revealed nothing, and
## still-equal-after-the-host-walks says nothing leaks afterwards either.
##
## ## What world means here, concretely
##
## `wild_once_<order>` is a `world` prefix in `data/progression/flag_scopes.json`
## and it has to be: the authored alpha is one creature standing in one place,
## and once anybody has caught or beaten it there is nothing left for anyone
## else to find. `alpha_pins.gd::clear_alpha()` submits it as a `set_world_flag`
## intent through the real `Game.ledger` (D103) — never a direct `set_flag` —
## and the joiner is asked for it on the WORLD store specifically, so a flag
## that somehow landed in the joiner's own player store would not answer.
##
## ## Reading a failure
##
## - The world half fails but the fog half passes: the peers are not really in
##   one session, or the ledger delta is not reaching the client. Check
##   `expect_peers` above it first; nothing below that line means anything if
##   the two processes never connected.
## - The fog half fails (the joiner's cell count moved): something now copies a
##   map across the wire. The snapshot is the first place to look.
## - `alpha_pin` errors with "no authored alpha cluster": `spawns.json`'s
##   authored orders changed. `PIN_ORDER` below is read from the data, so this
##   means the data has no alpha clusters at all.

const ALPHA_PINS := preload("res://scripts/world/alpha_pins.gd")

## The host's stick hold. Real walking, asserted as such — but the same wall the
## movement smoke measured is in front of this one, so it reveals nothing on its
## own and this smoke does not pretend otherwise: the first run measured 4428
## cells before it and 4428 after. The reveal comes from `explore_at` below,
## which stands the host out at the authored alpha cluster and lets
## `game_state.gd`'s own discovery tick lift the fog there.
const WALK_FRAMES := 300
## `game_state.gd` only samples the player's position for fog every
## `_DISCOVERY_INTERVAL_S`, so the walk needs frames after it for that sample to
## land before anybody reads a cell count.
const SETTLE_FRAMES := 90
## A short budget for the two NEGATIVE flag checks. These are expected to FAIL
## (the flag is not set yet), so the budget is what the smoke pays for its own
## control, not a real wait.
const NEGATIVE_BUDGET_FRAMES := 30
## The joiner is given a real budget to receive the committed delta.
const DELTA_BUDGET_FRAMES := 600


func _initialize() -> void:
	_run()


func _run() -> void:
	# Which authored alpha this run uses. Read from the shipping loader rather
	# than hard-coded, so a re-authored `spawns.json` moves this with it.
	var clusters: Array[Dictionary] = ALPHA_PINS.build_clusters()
	check(not clusters.is_empty(),
		"data/config/bands/*/spawns.json authors at least one alpha/elder cluster")
	if clusters.is_empty():
		quit(await finish())
		return
	var pin_order := int(clusters[0].get("order", -1))
	var once_flag := "wild_once_%d" % pin_order
	var pin_at: Vector2 = clusters[0].get("position", Vector2.ZERO)
	var pin_x := pin_at.x
	var pin_z := pin_at.y
	check(pin_order >= 0, "the chosen cluster has an order (%d -> '%s')" % [pin_order, once_flag])
	check(pin_at != Vector2.ZERO,
		"the chosen cluster sits somewhere real (%.0f, %.0f) -- (0, 0) would put the host's"
			% [pin_x, pin_z] + " exploration back on top of its own spawn circle")

	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	# The joiner's OWN fog, before anything has been hosted or joined. Every
	# later claim about peer 1 is measured against this number.
	var joiner_baseline := _fog(await probe(1, "map_fog"))
	check(joiner_baseline.has("cells"),
		"peer 1 has a map to read before the handshake (probe returned %s)" % str(joiner_baseline))
	if not joiner_baseline.has("cells"):
		quit(await finish())
		return
	var baseline_cells := int(joiner_baseline["cells"])
	check(baseline_cells > 0,
		"peer 1 boots with SOME fog of its own revealed (%d cells) -- a zero here would make every"
			% baseline_cells
			+ " 'unchanged' check below vacuously true")

	# --- the handshake, verbatim from smoke_net_movement_two_peers.gd --------
	#
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
	# --- end of the handshake block ------------------------------------------

	# THE ARRIVAL. The host's world snapshot has now been applied on peer 1.
	# Whatever it carried, it did not carry a map.
	var joiner_after_join := _fog(await probe(1, "map_fog"))
	check(joiner_after_join.has("cells"),
		"peer 1 still has a map to read after applying the host's snapshot")
	if not joiner_after_join.has("cells"):
		quit(await finish())
		return
	check(int(joiner_after_join["cells"]) == baseline_cells,
		"the joiner's revealed area is untouched by the handshake (%d cells, was %d)"
			% [int(joiner_after_join["cells"]), baseline_cells])

	# --- the personal half ---------------------------------------------------
	#
	# The host explores. On its own map that must move; on the joiner's it must
	# not, and the joiner is standing still throughout.
	var host_before := _fog(await probe(0, "map_fog"))
	check(host_before.has("cells"), "peer 0 has a map to read before it walks")
	if not host_before.has("cells"):
		quit(await finish())
		return

	var walked: Dictionary = await step(0, "stick", {"x": 0.0, "y": -1.0, "frames": WALK_FRAMES})
	check(str(walked.get("verdict", "")) == "PASS",
		"peer 0 held the stick forward (%s)" % str(walked.get("detail", "")))

	# The stick hold above is real walking and it is asserted as such, but it
	# cannot reveal anything: the first run of this smoke measured 4428 cells
	# before it and 4428 after, because a fresh boot starts inside Grandpa's
	# farmhouse and 2.71 m of travel stays inside the 45 m circle the map
	# reveals at boot. `explore_at` stands the host out at the authored alpha
	# cluster instead and lets `game_state.gd`'s own discovery tick lift the fog
	# there -- see `peer_runner.gd::_step_explore_at` for why the position is
	# supplied and what is still shipping code (all of the revealing).
	var explored: Dictionary = await step(0, "explore_at", {"at": [pin_x, pin_z]})
	check(str(explored.get("verdict", "")) == "PASS",
		"peer 0 stood out at the authored alpha cluster (%s)" % str(explored.get("detail", "")))
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	await step(1, "wait", {"frames": SETTLE_FRAMES})

	var host_after := _fog(await probe(0, "map_fog"))
	check(host_after.has("cells"), "peer 0 still has a map to read after walking")
	if not host_after.has("cells"):
		quit(await finish())
		return
	check(int(host_after["cells"]) > int(host_before["cells"]),
		"the HOST revealed new ground by exploring (%d cells, was %d) -- without this the"
			% [int(host_after["cells"]), int(host_before["cells"])]
			+ " comparison below proves nothing")

	var joiner_after_walk := _fog(await probe(1, "map_fog"))
	check(joiner_after_walk.has("cells"), "peer 1 still has a map to read after the host walked")
	if not joiner_after_walk.has("cells"):
		quit(await finish())
		return
	check(int(joiner_after_walk["cells"]) == baseline_cells,
		"THE JOINER'S FOG IS ITS OWN: unchanged by the host's exploration (%d cells, was %d)"
			% [int(joiner_after_walk["cells"]), baseline_cells])
	check(int(joiner_after_walk["cells"]) < int(host_after["cells"]),
		"the joiner has discovered strictly less than the host (%d < %d)"
			% [int(joiner_after_walk["cells"]), int(host_after["cells"])])

	# An alpha PIN is the same kind of fact as a fog cell: this player found it.
	# The host is standing on the cluster after `explore_at`, so in practice the
	# shipping `AlphaPins` node has already pinned it off its own 300 m proximity
	# tick and this arm only confirms the map holds it — which is the stronger
	# outcome, and the reason the arm treats "already pinned" as a pass rather
	# than as `pin_alpha()` returning false. The joiner has not moved, and its
	# own `AlphaPins` is ticking against its own position and its own map.
	var pinned: Dictionary = await step(0, "alpha_pin", {"order": pin_order})
	check(str(pinned.get("verdict", "")) == "PASS",
		"peer 0 pinned the authored alpha at order %d (%s)" % [pin_order, str(pinned.get("detail", ""))])
	var host_pinned := _fog(await probe(0, "map_fog"))
	var joiner_pinned := _fog(await probe(1, "map_fog"))
	check(host_pinned.has("alpha_pins") and int(host_pinned["alpha_pins"]) >= 1,
		"peer 0 holds the pin it just made (%s)" % str(host_pinned.get("alpha_pins", "absent")))
	check(joiner_pinned.has("alpha_pins") and int(joiner_pinned["alpha_pins"]) == 0,
		"THE JOINER HAS NOT FOUND IT: peer 1 holds no alpha pin (%s)"
			% str(joiner_pinned.get("alpha_pins", "absent")))

	# --- the world half ------------------------------------------------------
	#
	# The negative control first, on BOTH peers: the flag really is unset before
	# anyone beats anything, so the PASS below is the clear arriving and not a
	# flag that was always there. A `wait_flag` that finds nothing FAILS, which
	# is exactly what is wanted here, so the verdict is inverted deliberately.
	for i in 2:
		var before_clear: Dictionary = await step(i, "wait_flag",
			{"flag": once_flag, "scope": "world", "budget_frames": NEGATIVE_BUDGET_FRAMES})
		check(str(before_clear.get("verdict", "")) == "FAIL",
			"control: peer %d's WORLD store does not hold '%s' yet (%s)"
				% [i, once_flag, str(before_clear.get("detail", ""))])

	var cleared: Dictionary = await step(0, "alpha_clear", {"order": pin_order})
	check(str(cleared.get("verdict", "")) == "PASS",
		"peer 0 submitted the beaten alpha as a set_world_flag intent (%s)"
			% str(cleared.get("detail", "")))

	for i in 2:
		var after_clear: Dictionary = await step(i, "wait_flag",
			{"flag": once_flag, "scope": "world", "budget_frames": DELTA_BUDGET_FRAMES})
		check(str(after_clear.get("verdict", "")) == "PASS",
			"A BEATEN ALPHA IS THE WORLD'S: peer %d's WORLD store holds '%s' (%s)"
				% [i, once_flag, str(after_clear.get("detail", ""))])

	# And the consequence the player actually sees: the host's pin is gone,
	# dropped by the shipping `AlphaPins._prune_cleared()` on its own tick,
	# because there is no longer anything there to find. The joiner never had
	# one and still does not.
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	var host_final := _fog(await probe(0, "map_fog"))
	var joiner_final := _fog(await probe(1, "map_fog"))
	check(host_final.has("alpha_pins") and int(host_final["alpha_pins"]) == 0,
		"peer 0's pin cleared once the alpha was beaten (%s)"
			% str(host_final.get("alpha_pins", "absent")))
	check(joiner_final.has("alpha_pins") and int(joiner_final["alpha_pins"]) == 0,
		"peer 1 still holds no pin (%s)" % str(joiner_final.get("alpha_pins", "absent")))
	check(joiner_final.has("cells") and int(joiner_final["cells"]) == baseline_cells,
		"and the joiner's fog is STILL its own at the end of the run (%s, was %d)"
			% [str(joiner_final.get("cells", "absent")), baseline_cells])

	quit(await finish())


## A `map_fog` probe as a Dictionary, or `{}` when the peer had no map to read.
##
## Deliberately not a coercion: a probe that came back null (no `Game.map` on
## that peer) must be visible as a missing key at the assertion, not silently
## read as zero cells. Every caller above checks `has()` before `int()` for the
## same reason -- `int(null)` is not a conversion in GDScript, it aborts the
## function, and a smoke that aborts halfway looks like a smoke with fewer
## assertions rather than like a failure.
func _fog(raw: Variant) -> Dictionary:
	return raw as Dictionary if raw is Dictionary else {}
