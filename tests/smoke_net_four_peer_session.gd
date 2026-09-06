extends "res://tests/helpers/net_harness.gd"

# peers: 4

## Stage B Wave 7 lane 7.A. **D95'S CAP, AT THE CAP.**
##
##   tools/net/run_net_smoke.sh four_peer_session --peers=4
##
## **NIGHTLY / OWNER-KIT ONLY. NEVER PR CI.** Contract §10 and §8: spike S2
## (`ralph/reports/MP-0D-SPIKE-HOSTCOST-0905/`) measured four concurrent
## Meadows boots at **12.85 GB**, which does not fit beside PR CI on a 16 GB
## runner. The `# peers: 4` header is what keeps this out of
## `verify-multiplayer-shard`; it runs from `verify-multiplayer-wide`, gated on
## `workflow_dispatch`/`schedule`.
##
## `smoke_net_three_peer_session.gd` proves the multi-client mechanics --
## broadcast versus `rpc_id`, a late joiner catching a client's change,
## distinct ids, one leaver not disturbing another. This file exists for the
## two questions only the FOURTH peer can ask:
##
##   1. **The cap admits exactly four and not three.** `session.gd::host()`
##      passes `max_peers - 1` to `ENetMultiplayerPeer.create_server()`, which
##      counts CLIENTS. An off-by-one there is invisible at every smaller count
##      and refuses the last joiner here. `data/config/multiplayer.json`'s
##      `session.max_peers` is 4, and this file reads what the session reports
##      rather than hard-coding the number twice.
##   2. **What four concurrent Meadows actually cost on the box that ran it.**
##      Every peer's `VmHWM` is read and summed, and the total is printed
##      beside S2's 12.85 GB. It is REPORTED, not asserted: this file must not
##      fail because a nightly runner is roomier or tighter than the box S2
##      measured. The number is the deliverable; a threshold would only make
##      the job flaky and teach nobody anything.
##
## Everything else here is the three-peer file's assertions carried to four,
## because "it worked at three" is exactly the kind of claim that stops being
## true at the boundary.
##
## ## If this run dies for want of memory
##
## That is a FINDING and it is the finding this row is owed, not a smoke to
## tune. `net_harness.gd::_check_liveness` reports a peer that exited as
## `ERROR: peer exited`, exit 2, and the run directory keeps every peer log.
## Record the box's total RAM beside it in the lane report; do not lower the
## peer count to make it pass.

const WORLD_FLAG := "smoke_four_peer_world_change"

## kB -> GB, for the one line this file exists to print.
const KB_PER_GB := 1024.0 * 1024.0

## S2's measurement, quoted so the comparison is in the log rather than in
## somebody's memory. Not a threshold -- see this file's header.
const S2_FOUR_BOOT_GB := 12.85


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(4, "world"):
		quit(await finish())
		return

	check(_peers.size() == 4, "coordinator tracked 4 peers")

	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var host_port := int(host_hello.get("enet_port", 0))
	check(host_port > 0, "host reported its ENet port in hello (%d)" % host_port)
	if host_port <= 0:
		quit(await finish())
		return

	var hosted: Dictionary = await step(0, "host", {"port": host_port})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a listen server (%s)" % str(hosted.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# The cap, read off the session rather than restated. `max_peers` is
	# config; this smoke's peer count is its header. If they ever disagree the
	# failure should name both, not silently test three of four.
	var host_session_first: Dictionary = await _session_of(0)
	check(bool(host_session_first.get("is_host", false)), "peer 0 reports is_host")

	# 1. Three joiners, one at a time, and the LAST one is the assertion.
	var names := ["four-peer-a", "four-peer-b", "four-peer-c"]
	for i in range(1, 4):
		var joined: Dictionary = await step(i, "join",
			{"host": "127.0.0.1", "port": host_port,
			 "character": {"character_id": names[i - 1], "display_name": "Peer%d" % i}}, 6000)
		var ok := str(joined.get("verdict", "")) == "PASS"
		if i == 3:
			check(ok, "THE FOURTH PEER was admitted -- D95's cap is host + three joiners, "
				+ "and `create_server()` counts clients (%s)" % str(joined.get("detail", "")))
		else:
			check(ok, "peer %d joined (%s)" % [i, str(joined.get("detail", ""))])
		if not ok:
			quit(await finish())
			return

	# 2. Four rows, on all four, agreeing by content.
	for i in 4:
		var seen: Dictionary = await step(i, "expect_peers", {"count": 4}, 900)
		check(str(seen.get("verdict", "")) == "PASS",
			"peer %d's registry reports 4 peers (%s)" % [i, str(seen.get("detail", ""))])

	var sessions: Array = []
	for i in 4:
		sessions.append(await _session_of(i))
	var keys_0 := _row_keys((sessions[0] as Dictionary).get("rows", []) as Array)
	check(keys_0.size() == 4, "the registry holds exactly 4 rows (%s)" % str(keys_0))
	for i in range(1, 4):
		var keys_i := _row_keys((sessions[i] as Dictionary).get("rows", []) as Array)
		check(keys_i == keys_0,
			"peer %d's registry matches the host's row for row (host %s / peer %d %s)"
				% [i, str(keys_0), i, str(keys_i)])

	# Four distinct ids, only the host's is 1.
	var ids: Array = []
	for i in 4:
		ids.append(int((sessions[i] as Dictionary).get("peer_id", 0)))
	check(int(ids[0]) == 1, "the listen server's own peer id is 1 (got %d)" % int(ids[0]))
	var distinct: Dictionary = {}
	for id: Variant in ids:
		distinct[int(id)] = true
	check(distinct.size() == 4, "all four peer ids are distinct (%s)" % str(ids))

	# A world change made by the LAST joiner, reaching everybody -- the
	# broadcast at full width. A regression to `rpc_id` passes at two peers,
	# leaves one stale at three, and leaves two stale here.
	var flagged: Dictionary = await step(3, "story_flag", {"flag": WORLD_FLAG, "scope": "world"})
	check(str(flagged.get("verdict", "")) == "PASS",
		"the fourth peer changed the world (%s)" % str(flagged.get("detail", "")))
	for i in 4:
		var got: Dictionary = await step(i, "wait_flag",
			{"flag": WORLD_FLAG, "scope": "world", "budget_frames": 900}, 1800)
		check(str(got.get("verdict", "")) == "PASS",
			"peer %d received the fourth peer's world change (%s)" % [i, str(got.get("detail", ""))])

	# Contract §7, at the cap.
	check(await assert_all_hashes_equal(1200),
		"contract §7 state_hash agrees across all four peers")
	check(await expect_desync_free(6.0),
		"the desync detector stayed quiet for six seconds at the full peer cap")

	# 3. THE MEASUREMENT. Reported, never asserted -- see this file's header.
	var total_kb := 0.0
	var per_peer: Array = []
	for i in 4:
		var shells = await probe(i, "realm_shells")
		var hwm := 0.0
		if shells is Dictionary:
			hwm = float((shells as Dictionary).get("vm_hwm_kb", 0.0))
		total_kb += hwm
		per_peer.append("peer %d: %.2f GB" % [i, hwm / KB_PER_GB])
	print("coordinator: FOUR-PEER MEMORY -- %s" % ", ".join(PackedStringArray(per_peer)))
	print("coordinator: four-peer total VmHWM %.2f GB against spike S2's %.2f GB (contract §8)"
		% [total_kb / KB_PER_GB, S2_FOUR_BOOT_GB])
	check(total_kb > 0.0,
		"every peer reported a real VmHWM, so the memory line in this run's log is a measurement (%s)"
			% ", ".join(PackedStringArray(per_peer)))

	# One leaver at the cap: the other three are undisturbed and the host has
	# room for a replacement.
	var left: Dictionary = await step(3, "leave", {})
	check(str(left.get("verdict", "")) == "PASS", "peer 3 left cleanly (%s)" % str(left.get("detail", "")))
	for i in 3:
		var three_left: Dictionary = await step(i, "expect_peers", {"count": 3}, 900)
		check(str(three_left.get("verdict", "")) == "PASS",
			"peer %d is down to 3 peers and still in the session (%s)" % [i, str(three_left.get("detail", ""))])

	var rejoined: Dictionary = await step(3, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": "four-peer-c", "display_name": "Peer3"}}, 6000)
	check(str(rejoined.get("verdict", "")) == "PASS",
		"the vacated slot was reusable -- a peer rejoined to the cap (%s)" % str(rejoined.get("detail", "")))
	var back_to_four: Dictionary = await step(0, "expect_peers", {"count": 4}, 900)
	check(str(back_to_four.get("verdict", "")) == "PASS",
		"the host is back at 4 peers (%s)" % str(back_to_four.get("detail", "")))

	quit(await finish())


func _session_of(peer: int) -> Dictionary:
	var raw = await probe(peer, "session")
	return (raw as Dictionary) if raw is Dictionary else {}


func _row_keys(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		var r: Dictionary = row as Dictionary
		out.append("%s@%d" % [str(r.get("character_id", "")), int(r.get("peer_id", 0))])
	out.sort()
	return out
