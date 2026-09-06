extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 0 lane 0.F -- the negative control contract §11 requires: "a
## net smoke is not evidence until it has been run against the head of the
## previous wave and failed there for the right reason." Launches two peers
## exactly like `smoke_net_two_peers_boot.gd`, then kills peer 1 outright and
## proves the coordinator notices: `_fatal_reason` gets set, `finish()`
## returns 2, and the reason contains "peer exited" (contract §3's
## `ERROR: peer exited <code>` wording -- this harness cannot recover a real
## exit code across an `OS.kill()`+`OS.is_process_running()` reap, so it
## records the unexpected-death fact with the peer index instead of a code;
## see `net_harness.gd::_check_liveness` and the lane report's limitations
## section for why).
##
## Deliberately its own smoke rather than a second mode of the boot smoke:
## `# peers: 2` + `RETRIES: 1` runs this unconditionally on every CI push
## (contract §10), so the negative control stays a standing regression check
## on the HARNESS ITSELF rather than a one-off transcript only a human
## remembers to re-run by hand.
##
## This file's own process exit code is EXPECTED to be 0 -- it is asserting
## that the coordinator correctly produced a 2, not itself standing in for
## that 2. Inverting it (exiting non-zero when the kill goes UNDETECTED) is
## what keeps `verify-multiplayer-shard` red on the one failure this smoke
## exists to catch: a harness that stops noticing a dead peer.


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		print("FAIL: could not even launch 2 peers to kill one (%s)" % ", ".join(failures))
		quit(1)
		return

	for i in 2:
		var ctx = await probe(i, "input_context")
		if str(ctx) != "world":
			print("FAIL: peer %d input_context is '%s', not 'world', before the kill" % [i, str(ctx)])
			quit(1)
			return

	var victim: Dictionary = _peers[1]
	var pid := int(victim.get("pid", -1))
	print("smoke_net_peer_death: killing peer 1 (pid=%d) mid-run" % pid)
	OS.kill(pid)

	# Give the coordinator's own liveness check (_pump_once, driven here by
	# repeated probes on the SURVIVING peer 0) real frames to notice.
	var detected := false
	for i in 300:
		await probe(0, "input_context")
		if not _fatal_reason.is_empty():
			detected = true
			break

	var code := await finish()
	print("smoke_net_peer_death: coordinator exit code=%d fatal_reason='%s'" % [code, _fatal_reason])

	var ok := detected and code == 2 and _fatal_reason.findn("peer exited") >= 0
	if ok:
		print("PASS: negative control -- killing peer 1 made the coordinator record exit 2: %s"
			% _fatal_reason)
		quit(0)
	else:
		print(("FAIL: negative control did not behave as contract §11 requires " +
			"(detected=%s code=%d fatal='%s')") % [detected, code, _fatal_reason])
		quit(1)
