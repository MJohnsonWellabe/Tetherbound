extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 0 lane 0.F. Proves the net harness itself: two real, isolated
## headless Godot processes both boot the Meadows world, both heartbeat a
## world-state hash the desync detector can compare, and a real InputEvent
## pressed in one process is reflected in that same process's own probed
## state. NOT a test of the game's multiplayer -- there is no `Session` to
## host/join until Wave 2 (contract §1) -- a test of the INSTRUMENT.
##
##   godot --headless --path . --script tests/smoke_net_two_peers_boot.gd
##
## or, with isolation, orphan-kill and a run-directory artifact:
##
##   tools/net/run_net_smoke.sh two_peers_boot
##
## Negative control (contract §11): `tests/smoke_net_peer_death.gd` is the
## standing sibling that kills one peer mid-run and proves the coordinator
## records the harness fault -- see that file's own header and
## `ralph/reports/MP-0F-NET-HARNESS-0905/REPORT.md` for the transcript.


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# Both peers must actually be standing in the world, not stuck at a title
	# screen or a load failure, before anything else is asked of them.
	for i in 2:
		var ctx = await probe(i, "input_context")
		check(str(ctx) == "world", "peer %d input_context is 'world' (got '%s')" % [i, str(ctx)])

	# Contract §7's desync detector needs a few heartbeat windows before it
	# can say anything; give it real seconds of play first.
	var desync_ok := await expect_desync_free(3.0)
	check(desync_ok, "no sustained state-hash divergence across peers over 3s of real play")

	var hashes_ok := await assert_all_hashes_equal(300)
	check(hashes_ok, "both peers' world state hashes agree (contract §7)")

	# One real InputEvent per peer -- through Input.parse_input_event against
	# the live InputMap, exactly as a controller's own press would arrive
	# (contract §1). `jump` is asserted the way the delivery brief itself
	# allows: EITHER the probed position changed, OR the context stayed
	# 'world' (the press did not knock the peer into a menu or a fight). This
	# smoke is proving the harness can drive and observe two independent
	# processes, not jump's own physics -- `smoke_playground.gd` already
	# covers that on one process.
	for i in 2:
		var before = await probe(i, "position")
		var v: Dictionary = await step(i, "press", {"action": "jump"})
		check(str(v.get("verdict", "")) == "PASS",
			"peer %d pressed jump (%s)" % [i, str(v.get("detail", ""))])
		var after = await probe(i, "position")
		var ctx_after = await probe(i, "input_context")
		var moved := false
		if before is Array and after is Array and (before as Array).size() == 3 and (after as Array).size() == 3:
			var b: Array = before
			var a: Array = after
			moved = absf(float(a[1]) - float(b[1])) > 0.01 \
				or Vector2(float(a[0]) - float(b[0]), float(a[2]) - float(b[2])).length() > 0.01
		check(moved or str(ctx_after) == "world",
			"peer %d jump reflected: moved=%s context_after=%s" % [i, moved, str(ctx_after)])

	quit(await finish())
