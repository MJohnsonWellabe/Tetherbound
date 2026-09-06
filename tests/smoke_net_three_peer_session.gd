extends "res://tests/helpers/net_harness.gd"

# peers: 3

## Stage B Wave 7 lane 7.A. **§17 ITEM 2, THE HALF NOBODY HAD RUN.**
##
##   tools/net/run_net_smoke.sh three_peer_session --peers=3
##
## **NIGHTLY / OWNER-KIT ONLY. NEVER PR CI.** Contract §10 and §8: spike S2
## (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`) measured four concurrent
## Meadows boots at 12.85 GB, which does not fit beside PR CI on a 16 GB
## runner. The `# peers: 3` header above is what keeps this out of
## `verify-multiplayer-shard`, whose discovery step matches `# peers: 2`
## exactly; it runs from `verify-multiplayer-wide`, gated on
## `workflow_dispatch`/`schedule`.
##
## Row 2 of `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` says "join with up to
## three", and its evidence cell has read *"3/4-peer runs owed"* since the row
## was written. Everything before this file proved the session with exactly two
## processes, and two is the one peer count at which a whole class of bug
## cannot appear: a registry that replicates to "the client" rather than to
## every client, a snapshot addressed to the wrong peer, a broadcast that is
## really an `rpc_id`, `max_peers` arithmetic off by one.
##
## ## What is asserted, and why each is a three-peer question
##
##   1. **Three peers form one session.** D95's cap is host + three joiners,
##      and `ENetMultiplayerPeer.create_server()` counts CLIENTS, so
##      `session.gd::host()` passes `max_peers - 1`. Two peers never exercise
##      that subtraction.
##   2. **Every peer's registry holds all three rows, and they agree** -- by
##      content, not by count. `session.gd::_broadcast_registry()` is a plain
##      `rpc()`; a regression to `rpc_id()` is invisible at two peers and
##      leaves one of three stale here.
##   3. **The second joiner is a LATE joiner relative to the first.** Peer 2
##      joins after peer 1 has already changed the world, so its snapshot must
##      carry a change made by somebody who is not the host. That is item 22
##      at three peers, and it is the assertion that a world record has to
##      travel client -> host -> client to pass.
##   4. **Each peer holds a distinct ENet id**, none of them 1 except the
##      host's. Spike finding 2: ids are large and random, and a harness that
##      assumed 1/2/3 would pass at two peers by accident.
##   5. **The desync detector is quiet across all three** (contract §7), and
##      every state hash agrees.
##   6. **One joiner leaving does not disturb the other.** The host drops to
##      two rows and peer 1 -- who did not move -- still holds a live session
##      with the right count. At two peers "somebody left" and "the session
##      ended" are the same event; here they are not.
##
## ## Memory, which is the reason this file has a header at all
##
## The run records each peer's `VmHWM` through the `realm_shells` probe, so the
## nightly job's own log carries the measurement rather than a claim about it.
## S2's 12.85 GB is for FOUR boots; three should sit near three quarters of it.
## `smoke_net_four_peer_session.gd` is where that number is actually tested.

const WORLD_FLAG_FROM_CLIENT := "smoke_three_peer_client_change"


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(3, "world"):
		quit(await finish())
		return

	check(_peers.size() == 3, "coordinator tracked 3 peers")

	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var host_port := int(host_hello.get("enet_port", 0))
	check(host_port > 0, "host reported its ENet port in hello (%d)" % host_port)
	if host_port <= 0:
		quit(await finish())
		return

	# 1. Host, then two joiners, one at a time.
	var hosted: Dictionary = await step(0, "host", {"port": host_port})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a listen server (%s)" % str(hosted.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var joined_1: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": "three-peer-a", "display_name": "Ana"}}, 6000)
	check(str(joined_1.get("verdict", "")) == "PASS",
		"peer 1 joined (%s)" % str(joined_1.get("detail", "")))

	# 3's setup: a change made by a CLIENT, before the third peer exists.
	var flagged: Dictionary = await step(1, "story_flag",
		{"flag": WORLD_FLAG_FROM_CLIENT, "scope": "world"})
	check(str(flagged.get("verdict", "")) == "PASS",
		"peer 1 (a client) changed the world (%s)" % str(flagged.get("detail", "")))
	var landed_on_host: Dictionary = await step(0, "wait_flag",
		{"flag": WORLD_FLAG_FROM_CLIENT, "scope": "world", "budget_frames": 900})
	check(str(landed_on_host.get("verdict", "")) == "PASS",
		"that client's change committed on the host (%s)" % str(landed_on_host.get("detail", "")))

	var joined_2: Dictionary = await step(2, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": "three-peer-b", "display_name": "Bo"}}, 6000)
	check(str(joined_2.get("verdict", "")) == "PASS",
		"peer 2 joined a world a CLIENT had already changed (%s)" % str(joined_2.get("detail", "")))
	if str(joined_2.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 2. All three, on all three, agreeing by content.
	for i in 3:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 3}, 900)
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry reports 3 peers (%s)" % [i, str(seen.get("detail", ""))])

	var sessions: Array = []
	for i in 3:
		sessions.append(await _session_of(i))
	var keys_0 := _row_keys((sessions[0] as Dictionary).get("rows", []) as Array)
	for i in range(1, 3):
		var keys_i := _row_keys((sessions[i] as Dictionary).get("rows", []) as Array)
		check(keys_i == keys_0,
			"peer %d's registry matches the host's row for row (host %s / peer %d %s)"
				% [i, str(keys_0), i, str(keys_i)])
	check(keys_0.size() == 3, "the registry holds exactly 3 rows (%s)" % str(keys_0))

	# 3. The late joiner has the client's change.
	var late_has_it: Dictionary = await step(2, "assert",
		{"check": "flag_set", "flag": WORLD_FLAG_FROM_CLIENT})
	check(str(late_has_it.get("verdict", "")) == "PASS",
		"peer 2's snapshot carried a world change made by peer 1, not by the host (%s)"
			% str(late_has_it.get("detail", "")))

	# 4. Three distinct ids, only the host's is 1.
	var ids: Array = []
	for i in 3:
		ids.append(int((sessions[i] as Dictionary).get("peer_id", 0)))
	check(ids[0] == 1, "the listen server's own peer id is 1 (got %d)" % int(ids[0]))
	check(int(ids[1]) > 1 and int(ids[2]) > 1,
		"both joiners hold real assigned ENet ids, neither of them 1 (%s)" % str(ids))
	check(int(ids[1]) != int(ids[2]),
		"the two joiners hold DIFFERENT ids (%s)" % str(ids))

	# 5. Contract §7, across three processes rather than two.
	check(await assert_all_hashes_equal(900),
		"contract §7 state_hash agrees across all three peers")
	check(await expect_desync_free(6.0),
		"the desync detector stayed quiet for six seconds with three peers connected")

	# Memory, for the record. Not a bar -- a measurement the nightly log keeps.
	for i in 3:
		var shells = await probe(i, "realm_shells")
		if shells is Dictionary:
			print("coordinator: peer %d VmHWM=%s kB VmRSS=%s kB" % [i,
				str((shells as Dictionary).get("vm_hwm_kb", "?")),
				str((shells as Dictionary).get("vm_rss_kb", "?"))])

	# 6. One joiner leaves; the other is undisturbed.
	var left: Dictionary = await step(2, "leave", {})
	check(str(left.get("verdict", "")) == "PASS", "peer 2 left cleanly (%s)" % str(left.get("detail", "")))

	var host_two: Dictionary = await step(0, "expect_peers", {"count": 2}, 900)
	check(str(host_two.get("verdict", "")) == "PASS",
		"the host is down to 2 peers (%s)" % str(host_two.get("detail", "")))
	var other_two: Dictionary = await step(1, "expect_peers", {"count": 2}, 900)
	check(str(other_two.get("verdict", "")) == "PASS",
		"peer 1 -- who did not move -- also sees 2 peers (%s)" % str(other_two.get("detail", "")))

	var still_in: Dictionary = await _session_of(1)
	check(bool(still_in.get("active", false)),
		"peer 1's session is still active after somebody ELSE left (%s)" % str(still_in))
	check(not bool(still_in.get("is_host", true)),
		"and peer 1 did not silently become a host (%s)" % str(still_in))

	quit(await finish())


func _session_of(peer: int) -> Dictionary:
	var raw = await probe(peer, "session")
	return (raw as Dictionary) if raw is Dictionary else {}


## `character_id@peer_id` per row, sorted -- one comparable, printable value per
## registry that names both halves of the mapping the registry exists to hold.
## Same shape `smoke_net_host_join_leave.gd` uses, so a failure here reads the
## same way as one there.
func _row_keys(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		var r: Dictionary = row as Dictionary
		out.append("%s@%d" % [str(r.get("character_id", "")), int(r.get("peer_id", 0))])
	out.sort()
	return out
