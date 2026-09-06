extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 7 lane 7.A. **§17 ITEM 21: DISCONNECT AND RECONNECT.**
##
##   tools/net/run_net_smoke.sh reconnect_keeps_character
##
## A peer whose link dies rejoins by character id inside
## `session.reconnect_window_s` and is the same character to the world it comes
## back to. That is the row. What this file asserts is **exactly the part of it
## that is implemented**, and it says out loud which part is not.
##
## ## The honest gap, stated before the assertions rather than after
##
## `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` row 20 and `session.gd
## ::_save_character_here()` both record it: **the character save is not
## written**. Lane 1.C is deferred, D100's `user://characters/<id>/
## character.json` does not exist, and a client writes NOTHING on leave. So
## there is no portable character to restore, and a smoke that asserted "the
## rejoiner got its party back from disk" would be asserting a feature nobody
## has built.
##
## What actually survives a reconnect today, and what this file therefore
## tests, is:
##
##   - the character id. `session.gd::_local_character_id()` mints one per
##     PROCESS and writes it back, so a peer that loses its link and rejoins
##     from the same process dials in as the same character;
##   - the registry identity. `peer_registry.gd::add()` drops any older row
##     holding that character id and carries its realm onto the new one, so a
##     rejoiner is one row, not two, under a NEW ENet peer id;
##   - everything the process never lost, because it never restarted: party,
##     satchel, position, realm. This is real -- it is what a player who
##     bounced a router gets back -- but it survives by not having gone away,
##     not by being restored, and this file's checks say so in their own text;
##   - a fresh world snapshot. The rejoiner re-applies the host's world, which
##     is where any world change made while it was gone reaches it.
##
## What this file does NOT assert, and why:
##
##   - a rejoin from a RESTARTED process. That is the case the character file
##     exists for, and today it mints a NEW character id, so the host cannot
##     recognise it. Recorded as handover H2 in
##     `ralph/reports/MP-7A-RELIABILITY-0906/REPORT.md`, not faked here.
##
## ## `reconnect_window_s` is documented intent, not a timer
##
## FINDING, recorded rather than worked around: `data/config/multiplayer.json`
## says `reconnect_window_s` is 120 s and that "Wave 2 keeps the row for the
## process lifetime and reads this only as the documented intent". The code
## does neither -- `session.gd::_on_peer_disconnected()` calls
## `_registry.remove(peer_id)` IMMEDIATELY, so the row is gone before any
## window could expire, and `peer_registry.gd::add()`'s carry-the-realm-forward
## branch (the only code that reads a previous row) can therefore never fire
## for a real disconnect. Nothing here is broken for the player -- the rejoiner
## re-announces its realm in its own hello -- but the window is unimplemented
## in a different way than the config claims. This smoke rejoins WELL inside
## 120 s, so it is honest under either reading, and asserts the outcome (one
## row, same character id, new peer id) rather than the mechanism.
##
## ## The shape of the run
##
##   1. host and client form a session; the client's character id is FIXED by
##      the smoke so the assertion is about identity, not about a minted string;
##   2. the client's state before the drop is read -- party size, satchel,
##      position -- so "the same character came back" is a comparison, not a
##      claim;
##   3. the LINK IS CUT with `drop_link` -- the transport closed out from under
##      the session, which is what a pulled cable does and the only path that
##      reaches `session.gd::_on_peer_disconnected()`. Not `leave`;
##   4. the host notices and is back to one peer;
##   5. the client rejoins with the SAME character id, inside the window;
##   6. the host's registry holds ONE row for that character, under a NEW peer
##      id; the client's own state is what it was; the world snapshot re-applied.
##
## ## Negative control (contract §11)
##
## Step 4 is the control for step 6: if the host never dropped the row, step 6
## would pass on a registry that had simply never changed. Both are asserted.

## The joiner's character id, fixed rather than minted, because this whole
## smoke is about that string surviving.
const CHARACTER_ID := "reconnect-smoke-character"
const DISPLAY_NAME := "Reconnector"

## A world-scope flag the HOST sets while the client is away, so the rejoin's
## snapshot has something to carry that the first one did not. Without it,
## "the rejoiner applied a snapshot" is unfalsifiable -- the world it left is
## the world it would come back to.
const AWAY_FLAG := "smoke_reconnect_changed_while_away"


func _initialize() -> void:
	_run()


func _run() -> void:
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")

	var host_hello: Dictionary = (_peers[0] as Dictionary).get("hello", {}) as Dictionary
	var host_port := int(host_hello.get("enet_port", 0))
	check(host_port > 0, "host reported its ENet port in hello (%d)" % host_port)
	if host_port <= 0:
		quit(await finish())
		return

	# 1. A session.
	var hosted: Dictionary = await step(0, "host", {"port": host_port})
	check(str(hosted.get("verdict", "")) == "PASS",
		"peer 0 hosted a listen server (%s)" % str(hosted.get("detail", "")))
	if str(hosted.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": CHARACTER_ID, "display_name": DISPLAY_NAME}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined (%s)" % str(joined.get("detail", "")))
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var first_session: Dictionary = await _session_of(1)
	var first_peer_id := int(first_session.get("peer_id", 0))
	check(first_peer_id > 1,
		"the joiner holds a real assigned ENet id (%d)" % first_peer_id)

	var rows_before: Array = (await _session_of(0)).get("rows", []) as Array
	check(_character_ids(rows_before).has(CHARACTER_ID),
		"the host's registry holds '%s' before the drop (%s)"
			% [CHARACTER_ID, str(_character_ids(rows_before))])

	# 2. What the client is, before the link dies. Compared afterwards -- the
	# point of the row is that this is the same character, and a smoke that
	# only counted registry rows would pass on a stranger with the same name.
	var party_before = await probe(1, "party")
	var pos_before = await probe(1, "position")
	check(party_before != null, "read the joiner's party before the drop (%s)" % str(party_before))
	check(pos_before is Array, "read the joiner's position before the drop (%s)" % str(pos_before))

	# 3. Cut the link. Not `leave`.
	var dropped: Dictionary = await step(1, "drop_link", {"settle_frames": 60})
	check(str(dropped.get("verdict", "")) == "PASS",
		"the joiner's transport died under it (%s)" % str(dropped.get("detail", "")))

	# 4. The host notices. This is the control for step 6.
	var back_to_one: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	check(str(back_to_one.get("verdict", "")) == "PASS",
		"the host noticed the disconnect and is back to 1 peer (%s)" % str(back_to_one.get("detail", "")))
	var rows_gone: Array = (await _session_of(0)).get("rows", []) as Array
	check(not _character_ids(rows_gone).has(CHARACTER_ID),
		"the dropped character is out of the host's registry (%s)" % str(_character_ids(rows_gone)))

	# The host changes the world while the peer is away, so the rejoin's
	# snapshot has to carry something the first one could not have.
	var flagged: Dictionary = await step(0, "story_flag", {"flag": AWAY_FLAG, "scope": "world"})
	check(str(flagged.get("verdict", "")) == "PASS",
		"the host changed the world while the peer was away (%s)" % str(flagged.get("detail", "")))
	var flag_landed: Dictionary = await step(0, "wait_flag",
		{"flag": AWAY_FLAG, "scope": "world", "budget_frames": 600})
	check(str(flag_landed.get("verdict", "")) == "PASS",
		"that change committed on the host (%s)" % str(flag_landed.get("detail", "")))

	var away_yet: Dictionary = await step(1, "assert", {"check": "flag_set", "flag": AWAY_FLAG})
	check(str(away_yet.get("verdict", "")) != "PASS",
		"the disconnected peer did NOT receive that change while it was gone (%s)"
			% str(away_yet.get("detail", "")))

	# 5. Rejoin, same character id, well inside the 120 s window.
	var rejoined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": CHARACTER_ID, "display_name": DISPLAY_NAME}}, 6000)
	check(str(rejoined.get("verdict", "")) == "PASS",
		"peer 1 rejoined by character id (%s)" % str(rejoined.get("detail", "")))
	if str(rejoined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 6. One row, same character, new peer id.
	var both_again: Dictionary = await step(0, "expect_peers", {"count": 2}, 900)
	check(str(both_again.get("verdict", "")) == "PASS",
		"the host's registry is back to 2 peers (%s)" % str(both_again.get("detail", "")))

	var rows_after: Array = (await _session_of(0)).get("rows", []) as Array
	var ids_after := _character_ids(rows_after)
	check(ids_after.count(CHARACTER_ID) == 1,
		"'%s' appears exactly ONCE in the host's registry, not twice (%s)"
			% [CHARACTER_ID, str(ids_after)])

	var second_session: Dictionary = await _session_of(1)
	var second_peer_id := int(second_session.get("peer_id", 0))
	check(second_peer_id > 1 and second_peer_id != first_peer_id,
		"the rejoiner came back under a NEW ENet peer id (%d -> %d)" % [first_peer_id, second_peer_id])
	check(_peer_id_for_character(rows_after, CHARACTER_ID) == second_peer_id,
		"the host maps '%s' to the rejoiner's new peer id %d (registry: %s)"
			% [CHARACTER_ID, second_peer_id, str(rows_after)])

	# The rejoin re-applied the host's world, including the change made while
	# the peer was gone. This is the half of "gets its character back" that IS
	# implemented today: the world catches up.
	var away_now: Dictionary = await step(1, "assert", {"check": "flag_set", "flag": AWAY_FLAG})
	check(str(away_now.get("verdict", "")) == "PASS",
		"the rejoiner's fresh snapshot carried the change made while it was away (%s)"
			% str(away_now.get("detail", "")))

	# And the character it came back as is the character it left as. HONEST
	# WORDING: this survives because the process never restarted, not because
	# anything restored it -- see this file's header. It is still the assertion
	# the row needs, and it would fail if a rejoin reset the local player.
	var party_after = await probe(1, "party")
	check(str(party_after) == str(party_before),
		"the rejoiner's party is unchanged across the reconnect (before %s / after %s)"
			% [str(party_before), str(party_after)])
	# HONEST NOTE, and the reason the position check below exists: a headless
	# peer boots with an EMPTY party, so the comparison above is `[] == []` --
	# a true comparison over no data. It would still catch a rejoin that
	# replaced the local player with a different one carrying a party, which is
	# worth keeping, but it is not on its own evidence that the character
	# survived. The body's position is: it is real, non-trivial, per-process
	# data that no snapshot carries and that a reset local player would lose.
	var pos_after = await probe(1, "position")
	check(pos_after is Array and pos_before is Array,
		"read the rejoiner's position after the reconnect (%s)" % str(pos_after))
	var drift := _distance(pos_before, pos_after)
	check(drift >= 0.0 and drift <= float(_budgets.get("near_tolerance_rest_m", DEFAULT_NEAR_REST_M)),
		"the rejoiner's body is where it was, within the at-rest tolerance (%.2f m of %.2f m; before %s / after %s)"
			% [drift, float(_budgets.get("near_tolerance_rest_m", DEFAULT_NEAR_REST_M)),
			   str(pos_before), str(pos_after)])

	check(await assert_all_hashes_equal(600),
		"contract §7 state_hash agrees again after the reconnect")

	quit(await finish())


## Metres between two `probe position` answers. -1.0 when either is not the
## three-float array the probe promises, so a shape failure is a legible
## out-of-tolerance rather than an `int(null)` that aborts the check.
func _distance(a: Variant, b: Variant) -> float:
	if not (a is Array) or not (b is Array):
		return -1.0
	var pa: Array = a
	var pb: Array = b
	if pa.size() != 3 or pb.size() != 3:
		return -1.0
	return Vector3(float(pa[0]), float(pa[1]), float(pa[2])).distance_to(
		Vector3(float(pb[0]), float(pb[1]), float(pb[2])))


func _session_of(peer: int) -> Dictionary:
	var raw = await probe(peer, "session")
	return (raw as Dictionary) if raw is Dictionary else {}


func _character_ids(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		if row is Dictionary:
			out.append(str((row as Dictionary).get("character_id", "")))
	out.sort()
	return out


## 0 -- `peer_registry.gd`'s own "no peer" sentinel, and the only id ENet never
## assigns -- when the character is not in the registry at all.
func _peer_id_for_character(rows: Array, character_id: String) -> int:
	for row: Variant in rows:
		if row is Dictionary and str((row as Dictionary).get("character_id", "")) == character_id:
			return int((row as Dictionary).get("peer_id", 0))
	return 0
