extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 2 lane 2.B. A PLAYER CAN JOIN A GAME.
##
##   tools/net/run_net_smoke.sh join_by_address
##
## Every other net smoke in this directory joins through `peer_runner.gd`'s own
## `join` step -- a test-only entry point that reaches straight into
## `Session.join()`. That proved the transport, and it proved nothing at all
## about whether a human, or `tools/owner/`'s launcher, can get into a game:
## before this lane the only way into a world was `title_screen.gd` calling
## `Session.host()`, and there was no join path on the screen or on the command
## line at all.
##
## So this smoke deliberately does NOT use the `host` or `join` steps. Both
## peers boot `--scene=title` -- the real front door -- and reach the session
## through the command-line flags `scripts/ui/title_screen.gd` parses:
##
##   peer 0:  --mp-host=<port>              the owner kit's host
##   peer 1:  --mp-join=127.0.0.1:<port>    the owner kit's client
##
## which is the same `Session.host()` / `Session.join()` the title screen's own
## buttons call, reached the way the launcher reaches it.
##
## What it proves, in order:
##
##   1. `--mp-host` on the real title screen binds a real listen server and
##      enters the world (peer 0 is `is_host`, active, in the world context);
##   2. `--mp-join <address:port>` on the real title screen completes the whole
##      handshake unattended -- connect, hello, snapshot -- with NO step told
##      it to (the coordinator issues nothing until both peers are already up);
##   3. the joiner is a CLIENT with a real ENet id, not the `OfflineMultiplayerPeer`
##      1 that a session-less process reports;
##   4. the host's registry replicates to two peers and both ends agree;
##   5. the joiner left the title screen and is standing in the world, which is
##      the difference between "the socket connected" and "a player joined".
##
## The joiner is patient by design (`title_screen.gd::CMDLINE_JOIN_RETRY_S`):
## the harness starts both processes in the same second and the host's Meadows
## takes ~85 s to build, so a client that gave up on the first refused connect
## could never join a host launched beside it. That patience is exactly what
## `tools/owner/` needs, and this smoke is where it is exercised.
##
## Negative control: run against a tree without the flags (or with the parser
## removed from `title_screen.gd`) and step 2 fails as
## `registry reports 1 peer(s), wanted 2` -- the joiner boots to a title screen
## and stops there, which is precisely the state this lane found the game in.

## Counted rather than inferred. A smoke can pass while running FEWER
## assertions than it should -- a probe that returns null reads as 0 through
## `int()` and a missing branch simply does not assert -- so the run prints how
## many it actually made and the report quotes that number.
var _assertions := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	# The host's port has to be in the JOINER'S ARGV, which is fixed before
	# either process exists -- so it is derived here rather than read off
	# peer 0's `hello` the way the step-driven smokes do. `enet_port_for()` is
	# the coordinator's own derivation, called rather than restated.
	var host_port := enet_port_for(0)
	# The joiner goes deliberately, legitimately silent for the length of one
	# Meadows build. It reaches the world the way a player does -- from the
	# title screen, after the host's snapshot lands, which is AFTER it has
	# already said hello -- and that scene change is one blocking frame of
	# ~85 s (spike S2). Contract §3's 15 s "peer silent" rule would call that
	# a dead peer; it is the only peer in this directory that changes scene
	# after hello, so it is the only one that raises the tolerance. Set before
	# `launch()` because the silence can begin before the LAST hello arrives.
	heartbeat_silence_tolerance_s = 240.0
	if not await launch(2, "title", [], {
		0: ["--mp-host=%d" % host_port],
		1: ["--mp-join=127.0.0.1:%d" % host_port],
	}):
		quit(await finish())
		return

	_check(_peers.size() == 2, "coordinator tracked 2 peers")
	_check(host_port > 0, "derived the host's ENet port before launch (%d)" % host_port)

	# 1. `--mp-host` really hosted. Nothing has been stepped yet: whatever is
	# true here was done by the flag alone.
	var host := await _session_of(0)
	_check(bool(host.get("available", false)), "peer 0 has a Session node")
	_check(bool(host.get("active", false)),
		"--mp-host bound a live listen server with no step telling it to (mode '%s')" % str(host.get("mode", "")))
	_check(str(host.get("mode", "")) == "host", "peer 0's session mode is 'host' (got '%s')" % str(host.get("mode", "")))
	_check(int(host.get("peer_id", 0)) == 1,
		"the listen server's own peer id is 1 (got %d)" % int(host.get("peer_id", 0)))
	var host_context := str(await probe(0, "input_context"))
	_check(host_context == "world",
		"--mp-host left the title screen and entered the world (context '%s')" % host_context)

	# 2. The joiner arrived on its own. `expect_peers` only WATCHES the
	# registry -- it never joins anything (peer_runner.gd::_step_expect_peers).
	#
	# A wide budget because the joiner dials from the FAR SIDE of its own
	# Meadows build: `scripts/mp/join_driver.gd` enters the world first and
	# opens the socket second, because a live ENet connection does not survive
	# ~85 s of blocking scene construction. So the host waits out one world
	# build here, and that wait is the honest cost of the path a player takes.
	var both: Dictionary = await step(0, "expect_peers", {"count": 2}, 12000)
	_check(str(both.get("verdict", "")) == "PASS",
		"the host's registry reached 2 peers with only --mp-join driving the joiner (%s)"
			% str(both.get("detail", "")))
	if str(both.get("verdict", "")) != "PASS":
		print("assertions run: %d" % _assertions)
		quit(await finish())
		return

	# 3. THE ONE THAT SEPARATES "CONNECTED" FROM "JOINED": the joiner left the
	# title screen and is standing in the world. It is also the barrier every
	# probe below waits behind -- `probe()`'s own 20 s deadline is far shorter
	# than a world build, so nothing may be probed on peer 1 until a step
	# addressed to peer 1 has come back.
	var in_world: Dictionary = await step(1, "wait_context", {"equals": "world"}, 12000)
	_check(str(in_world.get("verdict", "")) == "PASS",
		"--mp-join carried the joiner off the title screen into the world (%s)" % str(in_world.get("detail", "")))
	if str(in_world.get("verdict", "")) != "PASS":
		print("assertions run: %d" % _assertions)
		quit(await finish())
		return

	# 4. The joiner is a real client that finished the whole handshake.
	var client := await _session_of(1)
	_check(bool(client.get("available", false)), "peer 1 has a Session node")
	_check(str(client.get("mode", "")) == "client",
		"peer 1's session mode is 'client' (got '%s')" % str(client.get("mode", "")))
	_check(not bool(client.get("is_host", true)), "peer 1 reports is_host false")
	_check(bool(client.get("snapshot_ready", false)),
		"peer 1 applied the host's world snapshot -- the handshake finished, not just the socket")
	# Spike finding 2: a real ENet client id is a large random 32-bit number.
	# 1 here would mean the OfflineMultiplayerPeer every session-less process
	# carries, i.e. a joiner that never actually joined.
	_check(int(client.get("peer_id", 0)) > 1,
		"peer 1 holds a real assigned ENet id, not the session-less 1 (got %d)" % int(client.get("peer_id", 0)))

	# 5. The registry replicated; both ends agree.
	var rows_host: Array = (await _session_of(0)).get("rows", []) as Array
	var rows_client: Array = client.get("rows", []) as Array
	_check(rows_host.size() == 2 and rows_client.size() == 2,
		"both registries hold 2 rows (host %d, client %d)" % [rows_host.size(), rows_client.size()])
	_check(_row_ids(rows_host) == _row_ids(rows_client),
		"the registries agree across peers: host %s vs client %s" % [str(_row_ids(rows_host)), str(_row_ids(rows_client))])

	# 6. And the joiner's own registry agrees it has company -- read from its
	# side of the wire, after it is in the world, so this is the replicated
	# registry rather than the one the host can see by definition.
	var seen: Dictionary = await step(1, "expect_peers", {"count": 2})
	_check(str(seen.get("verdict", "")) == "PASS",
		"the joiner's own registry reports 2 peers (%s)" % str(seen.get("detail", "")))

	print("assertions run: %d" % _assertions)
	quit(await finish())


## `probe session`, as a Dictionary that is always safe to read. `probe()`
## returns null on a peer that did not answer inside its own deadline, and
## `null as Dictionary` is a hard cast error that ends the run with a backtrace
## instead of a failed assertion -- which is a smoke reporting a crash where it
## should be reporting a finding.
func _session_of(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "session")
	return value as Dictionary if value is Dictionary else {}


func _check(condition: bool, message: String) -> void:
	_assertions += 1
	check(condition, message)


## The peer ids in a registry, sorted -- one comparable, printable value per
## registry. Ids rather than `character_id@peer_id` (the shape
## `smoke_net_host_join_leave.gd` uses): this smoke never names the joiner's
## character, because nothing here hands one in -- `title_screen.gd` mints it
## from whatever `--mp-join` found on disk, which is the honest thing to
## compare and not a value this file chose.
func _row_ids(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		out.append(int((row as Dictionary).get("peer_id", 0)))
	out.sort()
	return out
