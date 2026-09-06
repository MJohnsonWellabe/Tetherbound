extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 3 lane 3.C. THE player-visible outcome of the lane: one player
## builds, and everybody lives in the world they built in.
##
##   tools/net/run_net_smoke.sh shared_building
##
## ## What it asserts
##
## The CLIENT -- the peer that owns none of the world -- arms a piece and
## presses Place. D103 says that press is a REQUEST: the intent goes to the
## host, the host commits it, and the delta is what plants the structure. So:
##
##   * the client's structure appears in the HOST's `placed_buildings`, at the
##     same index, with the same id, in the same realm, at the same spot;
##   * it stands as a real NODE on both peers, not merely as a record on one --
##     a delta that reached `WorldState` and not `build_placer.gd` is a house
##     nobody can see, and looks identical from the record alone;
##   * and the RELOAD half: the host writes its save, and the client's
##     structure is in the file. That is the assertion that separates "the
##     record went through the host" from "the client wrote its own copy" --
##     a client-only record survives nothing, and a late joiner rebuilds from
##     exactly this file's shape (`GameState.apply_world_snapshot`).
##
## Nothing here proves a race; `tests/test_world_ledger_races.gd` does that
## deterministically and headlessly, which is where race-safety belongs. This
## proves the transport: a client's build is the host's world's build.
##
## ## The debug order if it fails
##
## Read the checks in the order they print. `placed_building_count` on both
## peers first (host up by one and client not means the client's intent never
## reached the host; both unchanged means the press did nothing at all -- read
## the `build_place` step's own `ghost_ok` and record counts in its detail).
## Then `placed_building_rows` on both (a row on the host and none on the
## client means the delta never came back). Then `placed_building_nodes` (rows
## agreeing but no node means `build_placer.gd` did not hear `delta_applied`).
## Then `saved_world_buildings` on the host (a node and a record but nothing in
## the file means the save path, not this lane).

const PIECE := "floor"
## Frames for the client's intent to reach the host and the delta to come back.
const SETTLE_FRAMES := 180


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

	# Actually form the session. This smoke was written before lane 2.A landed,
	# so it could only assert that a Session class existed; with 2.A merged the
	# two processes must really host and join, or every check below reads "0
	# remote bodies" and means only that nobody ever connected.
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

	# --- the client builds ----------------------------------------------------

	var host_before = await probe(0, "placed_building_count")
	var client_before = await probe(1, "placed_building_count")
	check(int(host_before) == int(client_before),
		"both peers start from the same number of structures (host %d, client %d)"
			% [int(host_before), int(client_before)])

	# Peer 1 is the CLIENT. That is the point: a host placing a structure into
	# its own world proves nothing about the transport.
	var pressed: Dictionary = await step(1, "build_place", {"id": PIECE})
	check(str(pressed.get("verdict", "")) == "PASS",
		"the client pressed Place (%s)" % str(pressed.get("detail", "")))
	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	var host_after = await probe(0, "placed_building_count")
	var client_after = await probe(1, "placed_building_count")
	check(int(host_after) == int(host_before) + 1,
		"the client's structure is in the HOST's world (%d -> %d)"
			% [int(host_before), int(host_after)])
	check(int(client_after) == int(host_after),
		"and came back to the client as a committed delta (host %d, client %d)"
			% [int(host_after), int(client_after)])
	if int(host_after) != int(host_before) + 1 or int(client_after) != int(host_after):
		quit(await finish())
		return

	var host_rows = await probe(0, "placed_building_rows")
	var client_rows = await probe(1, "placed_building_rows")
	check(host_rows is Array and client_rows is Array, "both peers report their records")
	if not (host_rows is Array and client_rows is Array):
		quit(await finish())
		return
	print("host records:   %s" % str(host_rows))
	print("client records: %s" % str(client_rows))
	var index := int(host_after) - 1
	var host_record: Dictionary = (host_rows as Array)[index] as Dictionary
	var client_record: Dictionary = (client_rows as Array)[index] as Dictionary
	check(str(host_record.get("id", "")) == PIECE,
		"the host's new record is the piece the client armed ('%s')" % str(host_record.get("id", "")))
	check(host_record == client_record,
		"host and client hold the SAME record at index %d (%s / %s)"
			% [index, str(host_record), str(client_record)])

	# A record with no node is a house nobody can see. Both halves, or neither.
	var host_nodes = await probe(0, "placed_building_nodes")
	var client_nodes = await probe(1, "placed_building_nodes")
	check(_node_at(host_nodes, index, PIECE),
		"the structure STANDS on the host, not just in its record (%s)" % str(host_nodes))
	check(_node_at(client_nodes, index, PIECE),
		"and stands on the client that built it (%s)" % str(client_nodes))

	# --- and it survives the host's save --------------------------------------

	var saved: Dictionary = await step(0, "save_world", {})
	check(str(saved.get("verdict", "")) == "PASS",
		"the host wrote its world to a save slot (%s)" % str(saved.get("detail", "")))
	var in_file = await probe(0, "saved_world_buildings")
	check(in_file is Array, "the host's save file could be read back")
	if not (in_file is Array):
		quit(await finish())
		return
	print("host save file: %s" % str(in_file))
	check((in_file as Array).size() == int(host_after),
		"the save holds every standing structure (%d in the file, %d in the world)"
			% [(in_file as Array).size(), int(host_after)])
	check((in_file as Array).size() > index and (in_file as Array)[index] == host_record,
		"the CLIENT's structure is in the host's saved world -- it went through the host, "
			+ "not into the client's own copy (%s)" % str(in_file))

	# D100: a client writes no world of its own. Stated here as well as in
	# `smoke_net_host_join_leave.gd` because this is the one smoke where a
	# client had a world write to make, and made it as a request instead.
	var client_worlds = await probe(1, "worlds_dir_entries")
	check(client_worlds is Array and (client_worlds as Array).is_empty(),
		"the client wrote no world save of its own (%s)" % str(client_worlds))

	quit(await finish())


## Is there a live placed-building node at `index` with catalogue id `id`?
func _node_at(rows: Variant, index: int, id: String) -> bool:
	if not (rows is Array):
		return false
	for raw: Variant in (rows as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var row := raw as Dictionary
		if int(row.get("index", -1)) == index and str(row.get("id", "")) == id:
			return true
	return false
