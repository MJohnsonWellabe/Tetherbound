extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 2 lane 2.A. THE SESSION ITSELF, over two real processes.
##
##   tools/net/run_net_smoke.sh host_join_leave
##
## What this proves, in the order it proves it:
##
##   1. peer 0 hosts a real `ENetMultiplayerPeer` listen server (D95) and is
##      `multiplayer.is_server()`;
##   2. peer 1 joins by IP and the `join` step does not return until the host's
##      world snapshot has been APPLIED -- deliverable 3's "a joiner may not
##      send intents before `snapshot_applied`" is what makes this step honest;
##   3. `expect_peers 2` on BOTH ends: the registry is replicated, not local;
##   4. the two registries agree by fingerprint, and both list the same peer ids
##      and character ids;
##   5. the client leaves, and `expect_peers 1` on the host -- the host noticed
##      the disconnect and re-broadcast the registry without it;
##   6. the host exits: it writes its own world autosave, and the client's
##      autosave slot and `user://worlds/` both stay untouched (D100 --
##      "a client never writes a world file").
##
## Each peer has its own `XDG_DATA_HOME` (contract §2), so 6 is a real
## filesystem comparison between two isolated `user://` trees, not two reads of
## one directory.
##
## Negative control (contract §11): this file was seen RED before the session
## existed -- `step host` came back
## `ERROR: unknown action 'host'` from `peer_runner.gd`'s own dispatch, on the
## previous wave head. See `ralph/reports/MP-2A-SESSION-0906/REPORT.md`.


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# The host's ENet port, read off its own hello rather than recomputed here:
	# the coordinator derives the base from the run id, so no constant in this
	# file could be right (peer_runner.gd::_initialize's hello comment).
	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var host_port := int(host_hello.get("enet_port", 0))
	check(host_port > 0, "host reported its ENet port in hello (%d)" % host_port)
	if host_port <= 0:
		quit(await finish())
		return

	# 1. Host.
	var hosted: Dictionary = await step(0, "host", {"port": host_port})
	check(str(hosted.get("verdict", "")) == "PASS", "peer 0 hosted a listen server (%s)" % str(hosted.get("detail", "")))

	var host_session = await probe(0, "session")
	check(bool((host_session as Dictionary).get("is_host", false)), "peer 0 reports is_host")
	check(int((host_session as Dictionary).get("peer_id", 0)) == 1,
		"the listen server's own peer id is 1 (got %s)" % str((host_session as Dictionary).get("peer_id")))

	# 2. Join. The step returns only after the snapshot is applied.
	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": "smoke-joiner", "display_name": "Joiner"}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS", "peer 1 joined and applied the world snapshot (%s)"
		% str(joined.get("detail", "")))

	var client_session = await probe(1, "session")
	var cs: Dictionary = client_session as Dictionary
	check(not bool(cs.get("is_host", true)), "peer 1 reports is_host false")
	check(bool(cs.get("snapshot_ready", false)), "peer 1's snapshot_applied gate is open")
	# Spike finding 2: ENet client ids are large random 32-bit numbers, never
	# small sequential ones. Asserted so a future transport swap that hands out
	# 2, 3, 4 is a visible change rather than a silent assumption.
	check(int(cs.get("peer_id", 0)) > 1,
		"peer 1's ENet id is a real assigned id, not the server's 1 (got %d)" % int(cs.get("peer_id", 0)))

	# 3. Both ends see two peers.
	for i in 2:
		var v: Dictionary = await step(i, "expect_peers", {"count": 2})
		check(str(v.get("verdict", "")) == "PASS", "peer %d's registry reports 2 peers (%s)" % [i, str(v.get("detail", ""))])

	# 4. The registries agree -- by content fingerprint, and by the rows
	# themselves so a failure names what differs rather than two hashes.
	var rows_host: Array = ((await probe(0, "session")) as Dictionary).get("rows", []) as Array
	var rows_client: Array = ((await probe(1, "session")) as Dictionary).get("rows", []) as Array
	check(rows_host.size() == 2 and rows_client.size() == 2,
		"both registries hold 2 rows (host %d, client %d)" % [rows_host.size(), rows_client.size()])
	check(_row_keys(rows_host) == _row_keys(rows_client),
		"registry rows agree across peers: host %s vs client %s" % [str(_row_keys(rows_host)), str(_row_keys(rows_client))])
	check(_row_keys(rows_host).has("smoke-joiner@%d" % int(cs.get("peer_id", 0))),
		"the joiner's character id landed in the host's registry under its real peer id")

	# 5. The client leaves; the host notices and drops the row.
	var left: Dictionary = await step(1, "leave", {})
	check(str(left.get("verdict", "")) == "PASS", "peer 1 left cleanly (%s)" % str(left.get("detail", "")))
	var back_to_one: Dictionary = await step(0, "expect_peers", {"count": 1})
	check(str(back_to_one.get("verdict", "")) == "PASS",
		"the host's registry is back to 1 peer (%s)" % str(back_to_one.get("detail", "")))

	# 6. D100. Before the host exits, neither peer has an autosave in this run's
	# fresh, isolated home; after it, the host has one and the client does not.
	var client_saved_before = await probe(1, "autosave_exists")
	check(client_saved_before == false, "the client had written no autosave before the host exited (%s)"
		% str(client_saved_before))

	var host_left: Dictionary = await step(0, "leave", {"reason": "host_exit"})
	check(str(host_left.get("verdict", "")) == "PASS", "the host exited its session (%s)" % str(host_left.get("detail", "")))

	var host_saved = await probe(0, "autosave_exists")
	check(host_saved == true, "the host wrote its world autosave on exit (%s)" % str(host_saved))
	var client_saved = await probe(1, "autosave_exists")
	check(client_saved == false, "the client wrote NO world save, on join or on leave (%s)" % str(client_saved))

	var client_worlds = await probe(1, "worlds_dir_entries")
	check(client_worlds is Array and (client_worlds as Array).is_empty(),
		"the client's user://worlds/ is empty (%s)" % str(client_worlds))

	quit(await finish())


## `character_id@peer_id` per row, sorted -- one comparable, printable value per
## registry that names both halves of the mapping the registry exists to hold.
func _row_keys(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		var r: Dictionary = row as Dictionary
		out.append("%s@%d" % [str(r.get("character_id", "")), int(r.get("peer_id", 0))])
	out.sort()
	return out
