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
const DEFEAT_FLAG := "defeated_south_bridge_grunt"
const DOSS_FLAG := "river_nest_doss_cleared"
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
	var earned_mode := "--meadows-crossings" in OS.get_cmdline_user_args()
	if not await launch(2, "world"):
		quit(await finish())
		return

	check(_peers.size() == 2, "coordinator tracked 2 peers")
	if earned_mode:
		# This opt-in mode adds a full unmodified two-creature fight and two
		# save owners to the short flag smoke. Keep its allowance local.
		_step_phase_deadline_ms = Time.get_ticks_msec() + 600.0 * 1000.0

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
	if earned_mode:
		await _run_earned_crossings()
		return
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


## Opt-in earned-content slice. The default invocation above remains the small
## replication smoke. This mode uses declared near-site placement to avoid a
## 1.4km route, but the named fight, key reward, gate interaction and crossing
## still go through production doors; no progression flag is injected.
func _run_earned_crossings() -> void:
	const GUARDIAN := "south_bridge_grunt"
	const KEY_ITEM := "south_bridge_key"
	# The crossing's two authored abutment flats are both y=-2.9; using the
	# stale raw terrain height here drops a teleported body into the gully.
	const GATE_SITE := [8.0, -2.9, 1321.5]
	const FAR_DECK := [8.0, -2.9, 1341.0]

	for peer in 2:
		var seeded: Dictionary = await step(peer, "party_grant", {"species": "bramblebun", "level": 12})
		check(str(seeded.get("verdict", "")) == "PASS",
			"earned mode peer %d received a declared fixture creature through PartySeam (%s)" % [peer, str(seeded.get("detail", ""))])
		for species: String in ["trailpup", "burrowback", "meadowhart", "terrapup"]:
			var retained: Dictionary = await step(peer, "party_grant", {"species": species, "level": 12})
			check(str(retained.get("verdict", "")) == "PASS", "peer %d retained-team fixture added %s" % [peer, species])
		var deployed: Dictionary = await step(peer, "deploy_creature", {})
		check(str(deployed.get("verdict", "")) == "PASS",
			"earned mode peer %d deployed through EncounterDirector (%s)" % [peer, str(deployed.get("detail", ""))])

	for peer in 2:
		var before: Variant = await _story(peer)
		check(_world_says(before, DEFEAT_FLAG) == false,
			"earned mode peer %d starts before the named guardian defeat" % peer)
		check(_world_says(before, GATE_FLAG) == false,
			"earned mode peer %d starts with South Bridge closed" % peer)

	var challenge: Dictionary = await step(0, "trainer_battle", {"trainer": GUARDIAN, "settle": 45})
	check(str(challenge.get("verdict", "")) == "PASS" and str(challenge.get("detail", "")).contains(GUARDIAN),
		"host admitted the authored South Bridge guardian (%s)" % str(challenge.get("detail", "")))
	var encounter: Variant = await probe(0, "encounter")
	var record := encounter as Dictionary if encounter is Dictionary else {}
	var encounter_id := str(record.get("id", ""))
	check(not encounter_id.is_empty(), "host exposed a live shared trainer encounter id")
	if encounter_id.is_empty():
		quit(await finish())
		return
	var opponent_pos: Array = record.get("opponent_pos", []) as Array
	if opponent_pos.size() == 3:
		var guest_staged: Dictionary = await step(1, "teleport", {
			"at": [float(opponent_pos[0]) + 3.0, float(opponent_pos[1]), float(opponent_pos[2]) + 3.0],
			"settle": 30,
		})
		check(str(guest_staged.get("verdict", "")) == "PASS",
			"client staged beside the host's live guardian presentation")
	else:
		check(false, "host encounter record exposed no opponent position for the joining client")
	var joined: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	check(str(joined.get("verdict", "")) == "PASS",
		"client joined the same named guardian encounter (%s)" % str(joined.get("detail", "")))
	# The prior 2400-frame witness ended with the real fight still active
	# (46.3 of 182.6 HP remaining); allow the existing combat pilot
	# enough time to finish rather than treating ordinary fight progress as a
	# fixture or production failure.
	var won: Dictionary = await step(0, "win_trainer_battle", {"budget_frames": 4200, "settle": 120}, 4200)
	check(str(won.get("verdict", "")) == "PASS",
		"shared South Bridge guardian fight resolved through production combat (%s)" % str(won.get("detail", "")))
	if str(won.get("verdict", "")) != "PASS":
		quit(await finish())
		return
	for peer in 2:
		await step(peer, "wait", {"frames": SETTLE_FRAMES})
		var after_fight: Variant = await _story(peer)
		check(str((after_fight as Dictionary).get("context", "")) == "world",
			"peer %d returned to normal exploration after the shared fight" % peer)
		if str((after_fight as Dictionary).get("context", "")) != "world":
			quit(await finish())
			return
		check(_world_says(after_fight, DEFEAT_FLAG) == true,
			"peer %d received the named guardian defeat fact" % peer)
		var inventory: Variant = await _inventory(peer)
		print("bridge post-fight peer %d key count=%d open=%s" % [peer,
			int((inventory as Dictionary).get(KEY_ITEM, 0)), str(_world_says(after_fight, GATE_FLAG))])

	# Approach the earned gate. Automatic opening may already have consumed a
	# key; the client's later normal interact is then an already-open no-op.
	var bridge_story: Dictionary = await _story(0)
	var bridge_y := NAN
	for gate: Dictionary in bridge_story.get("gates", []):
		if str(gate.get("flag", "")) == GATE_FLAG:
			var at: Array = gate.get("position", [])
			if at.size() == 3:
				bridge_y = float(at[1]) + 0.25
	check(not is_nan(bridge_y), "live bridge exposes its built deck height")
	if is_nan(bridge_y):
		quit(await finish())
		return
	for peer in 2:
		var site := GATE_SITE.duplicate()
		site[1] = bridge_y
		if peer == 0:
			site[2] = float(site[2]) - 3.0
		var staged: Dictionary = await step(peer, "teleport", {"at": site, "settle": 30})
		check(str(staged.get("verdict", "")) == "PASS",
			"peer %d staged at the declared bridge gate site: %s" % [peer, str(staged.get("detail", ""))])
	var pressed: Dictionary = await step(1, "press", {"action": "interact", "times": 1})
	check(str(pressed.get("verdict", "")) == "PASS",
		"client pressed the live South Bridge gate interaction (%s)" % str(pressed.get("detail", "")))
	var host_keys: Dictionary = await _inventory(0)
	var guest_keys: Dictionary = await _inventory(1)
	check(int(host_keys.get(KEY_ITEM, 0)) + int(guest_keys.get(KEY_ITEM, 0)) == 1,
		"two participant key rewards paid for exactly one shared bridge opening")
	# Let the front player cross first instead of placing both colliders together.
	for peer: int in [1, 0]:
		await step(peer, "wait", {"frames": SETTLE_FRAMES})
		var opened: Variant = await _story(peer)
		check(_world_says(opened, GATE_FLAG) == true and _gate_open(opened, GATE_FLAG) == true,
			"peer %d sees the earned South Bridge world fact and open live leaf: %s" % [peer, str(opened)])
		var walked: Dictionary = await step(peer, "move_to", {"x": FAR_DECK[0], "z": FAR_DECK[2], "close_enough": 2.0, "budget_frames": 600})
		check(str(walked.get("verdict", "")) == "PASS",
			"peer %d walked the short open deck leg (%s)" % [peer, str(walked.get("detail", ""))])
		if str(walked.get("verdict", "")) != "PASS":
			print("bridge failed position: ", await probe(peer, "position"))
			quit(await finish())
			return
		if peer == 1:
			# Clear the far landing with the first player's followers before the
			# second crosses; stopping the first team on the exit blocks the lane.
			var clear_landing: Dictionary = await step(1, "move_to", {
				"x": 8.0, "z": 1354.0, "close_enough": 2.0, "budget_frames": 600})
			check(str(clear_landing.get("verdict", "")) == "PASS", "guest cleared the far landing for the host")
			if str(clear_landing.get("verdict", "")) != "PASS":
				quit(await finish())
				return

	# Doss is a bounded second production interaction: declared placement at the
	# authored NPC site, real wood/fiber debit and parsed interact, then the
	# shared world repair plus the personal reward only on the client.
	const DOSS_SITE := [74.0, 4187.4]
	var host_before: Dictionary = await _inventory(0)
	var client_grant_wood: Dictionary = await step(1, "storage_grant", {"item": "wood", "n": 1})
	var client_grant_fiber: Dictionary = await step(1, "storage_grant", {"item": "fiber", "n": 1})
	check(str(client_grant_wood.get("verdict", "")) == "PASS" and str(client_grant_fiber.get("verdict", "")) == "PASS",
		"client received the declared one-wood/one-fiber Doss fixture")
	var client_before: Dictionary = await _inventory(1)
	check(int(client_before.get("wood", 0)) >= 1 and int(client_before.get("fiber", 0)) >= 1,
		"client carries both authored Doss inputs before interaction")
	for peer: int in [1]:
		# Use the runner's ground-aware exploration placement rather than a guessed
		# Y coordinate. Two metres east of Doss keeps the player outside the NPC
		# body while remaining inside the authored 3.8m prompt radius.
		var doss_staged: Dictionary = await step(peer, "explore_at", {"at": DOSS_SITE, "settle": 60})
		check(str(doss_staged.get("verdict", "")) == "PASS",
			"peer %d staged at authored Doss site" % peer)
	var doss_press: Dictionary = await step(1, "press", {"action": "interact", "times": 1})
	check(str(doss_press.get("verdict", "")) == "PASS",
		"client pressed Doss's live repair prompt (%s)" % str(doss_press.get("detail", "")))
	for peer in 2:
		await step(peer, "wait", {"frames": SETTLE_FRAMES})
		var doss_story: Variant = await _story(peer)
		check(_world_says(doss_story, DOSS_FLAG) == true,
			"peer %d received the shared repaired-bank flag" % peer)
	var client_after: Dictionary = await _inventory(1)
	var host_after: Dictionary = await _inventory(0)
	check(int(client_after.get("wood", 0)) == int(client_before.get("wood", 0)) - 1 \
			and int(client_after.get("fiber", 0)) == int(client_before.get("fiber", 0)) - 1 \
			and int(client_after.get("coin", 0)) == int(client_before.get("coin", 0)) + 45 \
			and int(client_after.get("potion_large", 0)) == int(client_before.get("potion_large", 0)) + 1,
		"client paid exactly one wood/fiber and received Doss's 45 coin + Large Potion")
	check(host_after == host_before, "host received no personal Doss reward or material debit")
	# Close/advance the acknowledgement and exercise the same prompt again; the
	# cleared world must acknowledge without paying a second time.
	var repeat_press: Dictionary = await step(1, "press", {"action": "interact", "times": 8, "gap_frames": 18})
	check(str(repeat_press.get("verdict", "")) == "PASS", "client completed the post-Doss acknowledgement")
	await step(1, "wait", {"frames": 30})
	var repeat_inventory: Dictionary = await _inventory(1)
	check(repeat_inventory == client_after, "repeating the cleared Doss prompt paid nothing")
	for peer in 2:
		var reloaded: Dictionary = await step(peer, "save_reload_here", {})
		check(str(reloaded.get("verdict", "")) == "PASS", "peer %d production save/reload completed after Doss" % peer)
		var saved_story: Variant = await _story(peer)
		check(_world_says(saved_story, DOSS_FLAG) == true, "peer %d retained Doss repair after save/reload" % peer)
	check(await assert_all_hashes_equal(300), "earned crossing peers retain one shared world after the real gate interaction")
	quit(await finish())


## The lane 5.A probe, asked about the two flags this smoke cares about.
func _story(peer: int) -> Variant:
	return await probe(peer, "story", {
		"world_flags": [GATE_FLAG, CONTROL_FLAG, DEFEAT_FLAG, DOSS_FLAG],
		"player_flags": [],
	})


func _inventory(peer: int) -> Dictionary:
	var value: Variant = await probe(peer, "trainer_reward", {
		"items": ["south_bridge_key", "wood", "fiber", "coin", "potion_large"],
	})
	return (value as Dictionary).get("satchel", {}) as Dictionary if value is Dictionary else {}


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
