extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 7 lane 7.A, re-pointed at the file by row 21.
## **§17 ITEM 21: DISCONNECT AND RECONNECT.**
##
##   tools/net/run_net_smoke.sh reconnect_keeps_character
##
## A peer whose link dies rejoins by character id inside
## `session.reconnect_window_s` and is the same character to the world it comes
## back to -- and its party, satchel and player-scoped flags come back **off
## `user://characters/<id>/character.json`**, not off whatever the process
## happened to still be holding.
##
## ## What changed, and why the old version could not assert this
##
## 7.A wrote this file while `user://characters/` did not exist: lane 1.C landed
## the character save hours later on a parallel branch. So the original header
## said, in its own words, that everything surviving the reconnect survived "by
## not having gone away, not by being restored", and
## `docs/acceptance/MULTIPLAYER_ACCEPTANCE.md` carried row 21 as **partial** for
## exactly that reason.
##
## Two things make this version assert the file instead:
##
##   1. **`session.gd::_restore_character_here()`**, which this row added.
##      `character_save.gd::apply()` existed -- 1.C wrote it as "the entry point
##      for the multiplayer paths that have a character id and no slot at all" --
##      and had **no caller**. Every peer wrote the file on the way out and
##      nothing ever read one back. `join()` now applies it.
##   2. **The `wipe_character` step.** Between the write and the rejoin, the
##      process's in-memory character is blanked with the game's own loader
##      (`PlayerState.load_data({})`), leaving the file alone. After that the
##      party, the satchel and the player flag exist in exactly one place on
##      this machine: the file. A rejoin that brought them back cannot have got
##      them from anywhere else, and a build without the restore leaves the peer
##      blank and fails.
##
## The negative control at the end closes the other direction: the same
## drop/wipe/rejoin, under a character id that has **no** file, and the peer
## correctly comes back blank. So "the state returned" is not something this
## sequence produces on its own.
##
## ## `reconnect_window_s` is documented intent, not a timer
##
## FINDING carried forward from 7.A, recorded rather than worked around:
## `data/config/multiplayer.json` says `reconnect_window_s` is 120 s and that
## "Wave 2 keeps the row for the process lifetime and reads this only as the
## documented intent". The code does neither --
## `session.gd::_on_peer_disconnected()` calls `_registry.remove(peer_id)`
## IMMEDIATELY, so the row is gone before any window could expire, and
## `peer_registry.gd::add()`'s carry-the-realm-forward branch can never fire for
## a real disconnect. Nothing is broken for the player -- the rejoiner
## re-announces its realm in its own hello -- but the window is unimplemented in
## a different way than the config claims. This smoke rejoins WELL inside 120 s,
## so it is honest under either reading, and asserts the outcome rather than the
## mechanism.
##
## ## Why `drop_link` is followed by `leave`
##
## `drop_link` closes the transport and detaches it, which is what the HOST sees
## when a cable is pulled and the only path that reaches
## `session.gd::_on_peer_disconnected()`. It does not run the CLIENT's own half:
## `multiplayer_peer` is gone before Godot can emit `server_disconnected`, so
## `_on_server_disconnected()` never fires and the client's `_mode` stays
## "client".
##
## The `leave` step that follows runs exactly the two calls, in exactly the
## order, that `_on_server_disconnected()` makes -- `_save_character_here()`
## then `_teardown()` -- so the pair together is the production dead-link path.
## It also matters for what this file is asserting: with `_mode` still set,
## `join()` would call `leave()` itself on the way in and write the character
## file **from the wiped memory** before reading it back, and the file would
## prove nothing. Standing the client down first is what keeps the write and the
## read on either side of the wipe.
##
## ## The shape of the run
##
##    1. host and client form a session; the client's character id is FIXED by
##       the smoke, and its first join finds NO file -- so nothing later can be
##       a stale read of a file that was already there;
##    2. the client earns state a blank process does not have: a creature in its
##       PARTY (through `party_seam.gd`, the opening's own door -- `deploy_creature`
##       spawns an ally body and never touches the party), items in its SATCHEL
##       (a headless peer boots carrying nothing), and a PLAYER-scoped story flag
##       -- waited for, because a client's grant answers `pending` first;
##    3. `Game.autosave_here()` writes its character file; the file is compared
##       against memory, key for key;
##    4. the LINK IS CUT, the host notices, and the client stands itself down;
##    5. the client's in-memory character is BLANKED. The file is now the only
##       copy;
##    6. the host changes the world while the peer is away;
##    7. the client rejoins with the SAME character id -- one registry row under
##       a NEW ENet peer id -- and its party, satchel and player flag are back,
##       equal to the file's, having been blank one step earlier;
##    8. the world change made while it was gone arrived with the fresh snapshot,
##       and the two peers' whole worlds are identical key for key;
##    9. NEGATIVE CONTROL: drop, wipe, and rejoin as a character with no file.
##       The peer stays blank.
##
## ## Negative controls (contract §11)
##
## Step 4's "the host is back to one peer" is the control for step 7's "the host
## is back to two": without it, step 7 would pass on a registry that had simply
## never changed. Step 5's "live is blank, file is not" is the control for step
## 7's restore. Step 9 is the control for the whole sequence.

## The joiner's character id, fixed rather than minted, because this whole smoke
## is about that string finding that file.
const CHARACTER_ID := "reconnect-smoke-character"
const DISPLAY_NAME := "Reconnector"

## The negative control's id. Never saved, so no file can exist for it.
const UNSAVED_ID := "reconnect-smoke-never-saved"

## A world-scope flag the HOST sets while the client is away, so the rejoin's
## snapshot has something to carry that the first one did not. Without it,
## "the rejoiner applied a snapshot" is unfalsifiable -- the world it left is
## the world it would come back to.
const AWAY_FLAG := "smoke_reconnect_changed_while_away"

## What the client's party is given. An ordinary Meadows species -- nothing about
## the row depends on which, only that the species and level that come back are
## the ones that went in.
const PARTY_SPECIES := "bramblebun"

## What the client is given to carry. Two different items with different counts,
## so a satchel that came back with the right total in the wrong places, or the
## right items in the wrong counts, fails.
const SATCHEL: Array = [["potion_small", 3], ["orb_basic", 2]]

## Excluded from the world diff, `smoke_net_late_join_modified_world.gd`'s own
## exclusion for contract §7's own reason: it advances with wall time in both
## processes and is re-synced on its own schedule, so it is never equal at an
## instant.
const VOLATILE_WORLD_KEYS: Array[String] = ["clock_elapsed_seconds"]

## A PLAYER-scoped flag the client earns before the drop.
## `data/progression/flag_scopes.json` puts this one in the `player` block, which
## is what makes it part of the CHARACTER (`character_save.gd::partition()` keeps
## the player half) rather than part of the world. A world flag would come back
## with the host's snapshot and would prove nothing about the file.
const PLAYER_FLAG := "player_slept_at_home"


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

	var joined: Dictionary = await _join(1, host_port, CHARACTER_ID)
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined (%s)" % str(joined.get("detail", "")))
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	var first_session: Dictionary = await _session_of(1)
	var first_peer_id := int(first_session.get("peer_id", 0))
	check(first_peer_id > 1,
		"the joiner holds a real assigned ENet id (%d)" % first_peer_id)

	# NOTHING ON DISK YET. Asserted before anything is written, so no comparison
	# below can be satisfied by a file that was already sitting there -- from an
	# earlier run, or from a `user://` the harness failed to isolate.
	var opening: Dictionary = await _character(1)
	check(not bool(opening.get("file_exists", true)),
		"the first join found NO character file for '%s' -- so nothing below is a stale read (%s)"
			% [CHARACTER_ID, str(opening.get("file", {}))])
	check(str(opening.get("character_id", "")) == CHARACTER_ID,
		"and the peer is playing that id (got '%s')" % str(opening.get("character_id", "")))

	# 2. The client earns state a blank process does not have.
	#
	# A creature in the PARTY, not just a deployed body: `deploy_creature` calls
	# `adopt_starter()`, which spawns the ally body and never touches
	# `Game.party` -- measured on this row's first run, where a peer that had
	# "deployed its own creature" still reported a party of zero. `party_grant`
	# goes through `party_seam.gd::add()`, the opening's own door.
	var granted: Dictionary = await step(1, "party_grant", {"species": PARTY_SPECIES})
	check(str(granted.get("verdict", "")) == "PASS",
		"peer 1 has a creature in its PARTY (%s)" % str(granted.get("detail", "")))
	# And something in the satchel. A headless peer boots carrying NOTHING (also
	# measured on the first run), so there is no starting satchel to lean on.
	for row: Array in SATCHEL:
		var given: Dictionary = await step(1, "storage_grant",
			{"item": str(row[0]), "n": int(row[1])})
		check(str(given.get("verdict", "")) == "PASS",
			"peer 1 is carrying %d %s (%s)" % [int(row[1]), str(row[0]), str(given.get("detail", ""))])
	var earned: Dictionary = await step(1, "story_flag", {"flag": PLAYER_FLAG, "scope": "player"})
	check(str(earned.get("verdict", "")) == "PASS",
		"peer 1 asked for the PLAYER-scoped flag '%s' (%s)" % [PLAYER_FLAG, str(earned.get("detail", ""))])
	# WAITED for, not read on the next line. A client's `grant_player_flag` answers
	# `{"ok": false, "pending": true}` -- the host being ASKED, not a refusal --
	# and the flag lands when the host's grant comes back. Measured: one run read
	# the store before the grant arrived and reported the flag missing, which is a
	# race in the smoke and not a defect in the grant.
	var landed: Dictionary = await step(1, "wait_flag",
		{"flag": PLAYER_FLAG, "scope": "player", "budget_frames": 900})
	check(str(landed.get("verdict", "")) == "PASS",
		"and the host granted it (%s)" % str(landed.get("detail", "")))

	var before: Dictionary = await _character(1)
	var live_before: Dictionary = before.get("live", {}) as Dictionary
	var party_before: Array = live_before.get("party", []) as Array
	var satchel_before: Dictionary = live_before.get("satchel", {}) as Dictionary
	check(party_before.size() > 0,
		"its party is real, and named: %s" % str(party_before))
	check(satchel_before.size() > 0,
		"its satchel is not empty: %s" % str(satchel_before))
	check(bool((live_before.get("player_flags", {}) as Dictionary).get(PLAYER_FLAG, false)),
		"and it holds '%s' in its own PLAYER flag store" % PLAYER_FLAG)

	# 3. The file. `Game.autosave_here()` -- D100's own routing, which on a
	# client is `session.gd::_save_character_here()`.
	var wrote: Dictionary = await step(1, "save_character_here", {})
	check(str(wrote.get("verdict", "")) == "PASS",
		"peer 1 wrote its character file through the production autosave door (%s)"
			% str(wrote.get("detail", "")))
	var written: Dictionary = await _character(1)
	var file_written: Dictionary = written.get("file", {}) as Dictionary
	check(bool(written.get("file_exists", false)),
		"user://characters/%s/character.json exists now" % CHARACTER_ID)
	check((file_written.get("party", []) as Array) == party_before,
		"and the FILE holds that party (file %s / memory %s)"
			% [str(file_written.get("party", [])), str(party_before)])
	check((file_written.get("satchel", {}) as Dictionary) == satchel_before,
		"and that satchel (file %s / memory %s)"
			% [str(file_written.get("satchel", {})), str(satchel_before)])
	check(bool((file_written.get("player_flags", {}) as Dictionary).get(PLAYER_FLAG, false)),
		"and that player flag (file flags: %s)" % str(file_written.get("player_flags", {})))

	# 4. Cut the link. Not `leave` -- see this file's header.
	var dropped: Dictionary = await step(1, "drop_link", {"settle_frames": 60})
	check(str(dropped.get("verdict", "")) == "PASS",
		"the joiner's transport died under it (%s)" % str(dropped.get("detail", "")))

	# The host notices. This is the control for step 7.
	var back_to_one: Dictionary = await step(0, "expect_peers", {"count": 1}, 900)
	check(str(back_to_one.get("verdict", "")) == "PASS",
		"the host noticed the disconnect and is back to 1 peer (%s)" % str(back_to_one.get("detail", "")))
	var rows_gone: Array = (await _session_of(0)).get("rows", []) as Array
	check(not _character_ids(rows_gone).has(CHARACTER_ID),
		"the dropped character is out of the host's registry (%s)" % str(_character_ids(rows_gone)))

	# The client's own half of a dead link.
	var stood_down: Dictionary = await step(1, "leave", {"reason": "link_died"})
	check(not bool((await _session_of(1)).get("active", true)),
		"the dropped client ran its own teardown, the way _on_server_disconnected() does (%s)"
			% str(stood_down.get("detail", "")))

	# 5. THE FALSIFIABILITY STEP. Blank the in-memory character; leave the file.
	var wiped: Dictionary = await step(1, "wipe_character", {})
	check(str(wiped.get("verdict", "")) == "PASS",
		"peer 1's in-memory character was blanked (%s)" % str(wiped.get("detail", "")))
	var blank: Dictionary = await _character(1)
	var live_blank: Dictionary = blank.get("live", {}) as Dictionary
	check((live_blank.get("party", []) as Array).is_empty(),
		"the process now holds NO party (%s)" % str(live_blank.get("party", [])))
	check((live_blank.get("satchel", {}) as Dictionary).is_empty(),
		"and NO satchel (%s)" % str(live_blank.get("satchel", {})))
	check(not bool((live_blank.get("player_flags", {}) as Dictionary).get(PLAYER_FLAG, true)),
		"and has forgotten '%s'" % PLAYER_FLAG)
	# The other half of the same step: the file did NOT change. Without this the
	# restore below could be reading a file the wipe had also emptied.
	var file_blank: Dictionary = blank.get("file", {}) as Dictionary
	check((file_blank.get("party", []) as Array) == party_before,
		"while the FILE still holds the party (%s)" % str(file_blank.get("party", [])))
	check((file_blank.get("satchel", {}) as Dictionary) == satchel_before,
		"and the satchel (%s)" % str(file_blank.get("satchel", {})))
	check(bool((file_blank.get("player_flags", {}) as Dictionary).get(PLAYER_FLAG, false)),
		"and the player flag. THE FILE IS NOW THE ONLY COPY ON THIS MACHINE")

	# 6. The host changes the world while the peer is away.
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

	# 7. Rejoin, same character id, well inside the 120 s window.
	var rejoined: Dictionary = await _join(1, host_port, CHARACTER_ID)
	check(str(rejoined.get("verdict", "")) == "PASS",
		"peer 1 rejoined by character id (%s)" % str(rejoined.get("detail", "")))
	if str(rejoined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

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

	# THE ROW. Blank one step ago; back now; and the only copy was the file.
	var restored: Dictionary = await _character(1)
	var live_after: Dictionary = restored.get("live", {}) as Dictionary
	check((live_after.get("party", []) as Array) == party_before,
		"the rejoiner's PARTY came back off user://characters/%s/character.json"
			% CHARACTER_ID
		+ " -- %s, and the process held %s a step ago"
			% [str(live_after.get("party", [])), str(live_blank.get("party", []))])
	check((live_after.get("satchel", {}) as Dictionary) == satchel_before,
		"and its SATCHEL: %s (was %s)"
			% [str(live_after.get("satchel", {})), str(live_blank.get("satchel", {}))])
	check(bool((live_after.get("player_flags", {}) as Dictionary).get(PLAYER_FLAG, false)),
		"and its PLAYER-scoped '%s', which no world snapshot carries" % PLAYER_FLAG)
	# The whole restored view against the whole file view, so a key this smoke
	# does not name individually cannot come back wrong unnoticed.
	check((live_after.get("party", []) as Array)
			== ((restored.get("file", {}) as Dictionary).get("party", []) as Array)
		and absf(float(live_after.get("satiety", -1.0))
			- float((restored.get("file", {}) as Dictionary).get("satiety", -2.0))) < 0.001,
		"and what it is playing matches what the file says, satiety included (live %s / file %s)"
			% [str(live_after), str(restored.get("file", {}))])

	# 8. And the world it came back to caught it up.
	var away_now: Dictionary = await step(1, "assert", {"check": "flag_set", "flag": AWAY_FLAG})
	check(str(away_now.get("verdict", "")) == "PASS",
		"the rejoiner's fresh snapshot carried the change made while it was away (%s)"
			% str(away_now.get("detail", "")))

	# Both peers agree about the WORLD after the reconnect -- a key-by-key diff of
	# `Game.world_snapshot()`, `smoke_net_late_join_modified_world.gd`'s own
	# assertion and the same payload `session.gd::_rpc_snapshot` puts on the wire.
	#
	# NOT `assert_all_hashes_equal()`, and FINDING F5 is why. Contract §7's
	# `HASHED_KEYS` includes `progression`, and `save_game.gd` writes that key as
	# the world's flags MERGED WITH the local player's own -- the `world_snapshot`
	# probe's own comment in `tools/net/peer_runner.gd` says so in as many words:
	# "two peers holding identical worlds legitimately differ there, and a smoke
	# diffing it would report a divergence that is not one."
	#
	# 7.A's version of this file could ask for hash equality because its joiner
	# held nothing personal. This version gives the client a PLAYER-scoped flag on
	# purpose -- that is the row -- so the hash can never agree again, and
	# measured: "state hashes never agreed across peers within 600 frames" while
	# the two worlds were identical. The background desync detector did not fire
	# (it needs no COMMON hash for `desync_frames`, and the heartbeats still
	# overlap), so this is a false red in an explicit assertion rather than a
	# harness fault -- but it is the same defect either way, and it is reported
	# rather than tuned around. `smoke_net_behind_character_joins_ahead_world.gd`,
	# the other smoke built on divergent player flags, asks for no hash equality
	# either.
	var host_world := await _world_of(0)
	var rejoiner_world := await _world_of(1)
	check(not host_world.is_empty() and not rejoiner_world.is_empty(),
		"both peers answered a world_snapshot probe after the reconnect (host %d keys / rejoiner %d)"
			% [host_world.size(), rejoiner_world.size()])
	var world_diff := _diff_worlds(host_world, rejoiner_world)
	check(world_diff.is_empty(),
		"and their WORLDS are identical key for key after it (differing keys: %s)"
			% str(world_diff))

	# 9. NEGATIVE CONTROL. The same drop, the same wipe, and a rejoin as a
	# character with NO file. If the sequence itself restored anything, this
	# would come back with a party too.
	var control_drop: Dictionary = await step(1, "drop_link", {"settle_frames": 60})
	check(str(control_drop.get("verdict", "")) == "PASS",
		"control: the link died again (%s)" % str(control_drop.get("detail", "")))
	await step(0, "expect_peers", {"count": 1}, 900)
	await step(1, "leave", {"reason": "link_died"})
	var control_wipe: Dictionary = await step(1, "wipe_character", {})
	check(str(control_wipe.get("verdict", "")) == "PASS",
		"control: blanked again (%s)" % str(control_wipe.get("detail", "")))
	var control_join: Dictionary = await _join(1, host_port, UNSAVED_ID)
	check(str(control_join.get("verdict", "")) == "PASS",
		"control: rejoined as '%s', a character that was never saved (%s)"
			% [UNSAVED_ID, str(control_join.get("detail", ""))])
	var control: Dictionary = await _character(1, UNSAVED_ID)
	check(not bool(control.get("file_exists", true)),
		"control: there is no file for '%s' to restore from (%s)"
			% [UNSAVED_ID, str(control.get("file", {}))])
	var control_live: Dictionary = control.get("live", {}) as Dictionary
	check((control_live.get("party", []) as Array).is_empty(),
		"control: so the peer came back with NO party (%s) -- the restore above was the FILE,"
			% str(control_live.get("party", []))
		+ " not something a rejoin does on its own")
	check((control_live.get("satchel", {}) as Dictionary).is_empty(),
		"control: and no satchel (%s)" % str(control_live.get("satchel", {})))
	check(not bool((control_live.get("player_flags", {}) as Dictionary).get(PLAYER_FLAG, true)),
		"control: and no '%s'" % PLAYER_FLAG)

	quit(await finish())


## `join`, with a named character. One helper so the first join, the rejoin and
## the control's join cannot drift apart in how they identify themselves.
func _join(peer: int, port: int, character_id: String) -> Dictionary:
	return await step(peer, "join",
		{"host": "127.0.0.1", "port": port,
		 "character": {"character_id": character_id, "display_name": DISPLAY_NAME}}, 6000)


## The `character_restore` probe: what this process holds in memory and what
## `user://characters/<id>/character.json` holds, side by side and never merged.
func _character(peer: int, character_id: String = CHARACTER_ID) -> Dictionary:
	var value = await probe(peer, "character_restore",
		{"character_id": character_id, "flags": [PLAYER_FLAG]})
	return value if value is Dictionary else {}


## `Game.world_snapshot()` on one peer -- the payload the host puts on the wire.
func _world_of(peer: int) -> Dictionary:
	var raw = await probe(peer, "world_snapshot")
	return (raw as Dictionary) if raw is Dictionary else {}


## Which world keys the two peers disagree on. `VOLATILE_WORLD_KEYS` is
## `smoke_net_late_join_modified_world.gd`'s own exclusion and for its reason:
## `clock_elapsed_seconds` advances with wall time in both processes and is
## re-synced by `_rpc_clock` on its own schedule, so it is never equal at an
## instant.
func _diff_worlds(a: Dictionary, b: Dictionary) -> Array:
	var keys: Dictionary = {}
	for key: Variant in a.keys():
		keys[str(key)] = true
	for key2: Variant in b.keys():
		keys[str(key2)] = true
	var out: Array = []
	for key3: String in keys.keys():
		if VOLATILE_WORLD_KEYS.has(key3):
			continue
		if JSON.stringify(a.get(key3), "", true, true) \
				!= JSON.stringify(b.get(key3), "", true, true):
			out.append(key3)
	out.sort()
	return out


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
