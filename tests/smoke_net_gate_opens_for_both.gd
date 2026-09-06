extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 5 lane 5.A. THE player-visible outcome of the lane's first half:
## one person opens a gate and BOTH of them can walk through it.
##
##   godot --headless --path . --script tests/smoke_net_gate_opens_for_both.gd
##
## or, with isolation, orphan-kill and a run-directory artifact:
##
##   tools/net/run_net_smoke.sh net_gate_opens_for_both
##
## ## What it asserts
##
## Both peers boot the Meadows and form a session. Peer 1 -- the CLIENT, on
## purpose, because a client's write is the one that has to make a round trip
## and the one that used to change nothing on anybody else's machine -- opens
## the South Bridge by submitting the same `set_world_flag` intent
## `gated_crossing.gd::_on_tried()` submits when a player presses the leaf with
## the key in their satchel. Then both peers are asked two things:
##
##   * does THE WORLD say the bridge is open (`WorldState.flags`, never the
##     merged view -- a merged read cannot tell "the world opened this" from
##     "my own store happens to hold that id"), and
##   * has the gate NODE this process is drawing actually re-posed?
##
## Both halves matter and they fail differently. A flag that crossed with no
## node change is a delta that reached `WorldState` and never reached the scene
## -- the leaf still solid, the collider still there, a player walking into an
## invisible wall over an open bridge. That is the failure this smoke exists
## for, and it is invisible from the flag alone. It is the same split lane 3.C
## draws between `placed_building_rows` and `placed_building_nodes`.
##
## ## Why the world flag and not a walk
##
## Walking a body across the South Bridge takes a route the harness cannot
## currently drive: the crossing is ~1.4 km south of the farmhouse spawn and
## `smoke_net_movement_two_peers.gd`'s own comment records that a fresh boot
## walks 2.71 m before it meets a wall. "Both can pass" is asserted as the two
## facts that MAKE passage possible -- the world says open, and the leaf on each
## screen has swung and dropped its collider -- rather than as a walk this
## harness cannot yet seat a player for. Whichever lane teaches the net harness
## to seed a post-opening save should upgrade this to the walk; the assertions
## below are the ones that would go red first if replication broke, either way.
##
## ## Debug order if it fails
##
## Is there a session at all (`session.available`), did the intent commit or was
## it refused (the step's own detail line carries `ok`/`pending`/`code`), does
## the WORLD flag read true on the host (if not, the intent never committed),
## does it read true on the client (if not, `_rpc_delta` is not arriving), and
## only then the gate rows (if the flag is true on a peer whose gate says shut,
## the `progression_restore` sweep is not reaching that node -- and on the HOST
## specifically, remember `ledger_rpc.gd::_commit_here()` does not run that
## sweep at all, which is why every story consumer also listens for
## `delta_applied`).

## The gate this smoke opens. A world flag in `data/progression/flag_scopes.json`
## and `gated_crossing.gd`'s own default `flag_id`, so the node that has to
## re-pose is the one the world already builds.
const GATE_FLAG := "south_bridge_open"
## A second, unrelated world gate, asserted UNSET throughout. Without it "both
## peers say open" is satisfied by a bug that opens every gate on any delta,
## which is a strictly worse world than one that opens none.
const CONTROL_FLAG := "road_gate_open"
## Frames for the committed delta to cross and for each peer's next `_process`
## to re-pose its scene. Generous: the assertion is "it arrives", not "it
## arrives fast", and a tight budget here buys a flaky smoke and nothing else.
const SETTLE_FRAMES := 120


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	# --- the handshake, copied verbatim from smoke_net_movement_two_peers.gd ---
	var session = await probe(0, "session")
	var have_session := session is Dictionary and bool((session as Dictionary).get("available", false))
	check(have_session,
		"a Session exists to host/join (lane 2.A); without it there is no world to share a gate in")
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
	# --- end of the copied handshake ------------------------------------------

	# The gate has to be SHUT on both peers before anybody opens it, or every
	# assertion below is satisfied by a world that was never gated.
	for i in 2:
		var before = await _story(i)
		check(_world_says(before, GATE_FLAG) == false,
			"peer %d starts with the South Bridge shut" % i)
		check(_gate_open(before, GATE_FLAG) == false,
			"peer %d starts with the bridge's leaf still across the deck" % i)

	# The CLIENT opens it. This is the direction that has to make a round trip:
	# a client cannot commit, so its intent goes to the host, is arbitrated
	# there, and comes back as a delta -- and before this lane, that delta
	# changed no gate node on either machine.
	var opened: Dictionary = await step(1, "story_flag", {"flag": GATE_FLAG, "scope": "world"})
	check(str(opened.get("verdict", "")) == "PASS",
		"peer 1 (the client) submitted the open-the-bridge intent (%s)" % str(opened.get("detail", "")))

	for i in 2:
		await step(i, "wait", {"frames": SETTLE_FRAMES})

	# The deliverable, both halves, on both peers.
	for i in 2:
		var after = await _story(i)
		check(after != null, "peer %d answered the story probe" % i)
		if after == null:
			continue
		check(_world_says(after, GATE_FLAG) == true,
			"peer %d's WORLD says the South Bridge is open" % i)
		check(_gate_open(after, GATE_FLAG) == true,
			"peer %d's own bridge gate has re-posed and is open (%s)"
				% [i, str(_gate_rows(after))])
		check(_world_says(after, CONTROL_FLAG) == false,
			"peer %d did not have an unrelated gate opened for it as well" % i)

	# One world, one bridge: the two processes must still agree about everything
	# the contract hashes, not merely about this flag.
	check(await assert_all_hashes_equal(300),
		"both peers still hold the same world after the gate opened (contract §7 hashed keys)")

	quit(await finish())


## The lane 5.A probe, asked about the two flags this smoke cares about.
func _story(peer: int) -> Variant:
	return await probe(peer, "story", {
		"world_flags": [GATE_FLAG, CONTROL_FLAG],
		"player_flags": [],
	})


## `null` rather than `false` when the probe did not answer, so "the peer did
## not report" cannot read as "the peer reported shut".
func _world_says(story: Variant, flag: String) -> Variant:
	if not story is Dictionary:
		return null
	var world: Variant = (story as Dictionary).get("world", {})
	if not world is Dictionary or not (world as Dictionary).has(flag):
		return null
	return bool((world as Dictionary)[flag])


## Whether any gate NODE in this peer's world that names `flag` reports itself
## open. `null` when this peer is drawing no such gate at all -- which is a
## different failure from "the gate is shut" and must not be reported as one.
func _gate_open(story: Variant, flag: String) -> Variant:
	if not story is Dictionary:
		return null
	var found := false
	var open := false
	for raw: Variant in ((story as Dictionary).get("gates", []) as Array):
		if not raw is Dictionary or str((raw as Dictionary).get("flag", "")) != flag:
			continue
		found = true
		open = open or bool((raw as Dictionary).get("open", false))
	return open if found else null


func _gate_rows(story: Variant) -> String:
	if not story is Dictionary:
		return "no story"
	return JSON.stringify((story as Dictionary).get("gates", []))
