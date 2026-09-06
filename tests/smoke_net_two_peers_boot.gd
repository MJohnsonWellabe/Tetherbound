extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 0 lane 0.F. Proves the net harness itself: two real, isolated
## headless Godot processes both boot the Meadows world, both heartbeat a
## world-state hash the desync detector can compare, both resolve the same
## pinned world seed, and a real held stick in one process actually MOVES
## that process's own player body by a measured distance. NOT a test of the
## game's multiplayer -- there is no `Session` to host/join until Wave 2
## (contract §1) -- a test of the INSTRUMENT.
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

	# The pin (contract §7 amended): every peer in this run was launched with
	# the SAME TB_WORLD_SEED (net_harness.gd::_spawn_peer). `probe world_seed`
	# reads the RESOLVED seed each peer's own spawn tables actually use
	# (`spawn_tables.gd::resolve_seed()`), which is what the pin promises --
	# not the raw per-process roll, which is expected to differ and is why
	# `world_seed` is erased from the hash entirely rather than normalized
	# into it.
	var expected_seed := OS.get_environment("TB_WORLD_SEED")
	if not expected_seed.is_empty() and expected_seed.is_valid_int():
		for i in 2:
			var resolved = await probe(i, "world_seed")
			check(int(resolved) == int(expected_seed),
				"peer %d resolved world_seed %s matches the pin %s" % [i, str(resolved), expected_seed])

	# A real, falsifiable input: a held stick must actually MOVE the body, not
	# merely "not break the context" (that was the original check's flaw --
	# true whether or not the press was ever injected; see the lane report's
	# red/green triple that found this). Real `InputEventJoypadMotion` through
	# `Input.parse_input_event` against the live InputMap AND the polled
	# `Input.get_vector` axis `player_controller.gd::_apply_movement` actually
	# reads (contract §1), same as a controller's own stick would arrive.
	#
	# `jump` was the first attempt at this and is NOT used here: a brand-new
	# game opens on the wake-up-in-bed beat at Grandpa's house
	# (`scripts/story/opening_beats.gd`, and `tests/smoke_playground.gd`'s own
	# comment on `meadows_playground` opening on it) and `_try_jump()`
	# specifically never fires there for a reason this lane could not fully
	# root-cause in the time available -- `is_on_floor()`, `locomotion_enabled()`,
	# `is_carried()` and `input_owner_node()` all read exactly as a normal
	# free-standing player would, `Input.is_action_just_pressed("jump")` reads
	# true on the injected physics frame, and `_try_jump` still never sets
	# `velocity.y`. Ordinary WALKING is not affected (`locomotion_enabled()`
	# reads true throughout, and `_apply_movement` runs on the same
	# `_physics_process` jump does), so this smoke proves the harness can
	# drive and observe real movement with a mechanism the wake beat does not
	# touch, and leaves the jump-specific finding recorded here for whichever
	# wave next needs `jump` in a step script.
	for i in 2:
		var before = await probe(i, "position")
		# y=-1.0 -> _drive_left presses move_forward at full strength.
		var v: Dictionary = await step(i, "stick", {"x": 0.0, "y": -1.0, "frames": 90})
		check(str(v.get("verdict", "")) == "PASS", "peer %d held the stick forward (%s)" % [i, str(v.get("detail", ""))])
		var after = await probe(i, "position")
		var moved_m := 0.0
		if before is Array and after is Array and (before as Array).size() == 3 and (after as Array).size() == 3:
			var b: Array = before
			var a: Array = after
			moved_m = Vector2(float(a[0]) - float(b[0]), float(a[2]) - float(b[2])).length()
		check(moved_m >= 0.5, "peer %d's body moved >= 0.5 m holding the stick forward (moved %.2f m)" % [i, moved_m])

	quit(await finish())
