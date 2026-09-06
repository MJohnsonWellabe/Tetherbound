extends "res://tests/helpers/net_harness.gd"

# peers: 2

## Stage B Wave 7 lane 7.A. **§17 ITEM 24, UNDER LOAD: HOST EXITS MID-FIGHT.**
##
##   tools/net/run_net_smoke.sh host_exit_saves
##
## `smoke_net_host_join_leave.gd` already proves the quiet version of this row:
## a host with nothing happening leaves, writes its world, and the client
## writes none. This is the loud one, which is the one the directive's §21 is
## actually about -- **the host quits while the session is busy**: a fight
## running, a building placed a moment ago and not yet in any file, a world
## flag committed seconds before the exit.
##
## The failure this exists to catch is a save that runs BEFORE the last thing
## that happened, or one that does not run at all because something in the
## teardown path threw first. `session.gd::leave()` saves, then broadcasts,
## then flushes for six frames, then tears down; every one of those steps has
## something in front of it here.
##
## ## What is asserted
##
##   1. the host's world autosave DID NOT EXIST before the exit and DOES after
##      -- the file, in this run's own isolated `XDG_DATA_HOME`, not a live
##      counter that would look identical either way;
##   2. that file carries the LAST change made before the exit. The building
##      and the flag are placed after the fight starts and asserted out of the
##      re-read file, so a save taken one beat too early fails here;
##   3. the client is returned to the title -- `_rpc_session_ended` ->
##      `_return_to_title` -- and its session is no longer active;
##   4. the client wrote no world file, mid-fight or not (D100). The fight is
##      exactly the state in which a client might be tempted to autosave, and
##      the four D100 autosave sites all ask `Game.is_host()`;
##   5. the host's own session is closed.
##
## ## Why the fight is real and the build is real
##
## Neither is faked. `engage_wild` presses the shipping interact on the nearest
## live wild through the real `EncounterDirector`, the client reaches the same
## fight through the real `join_encounter()`, and `build_place` presses the real
## `build_placer`. A smoke that set `_fighting = true` by hand would be testing
## that a boolean survives a save.
##
## The HOST starts the fight and the client joins it, rather than the other way
## round. That is the shape the game supports -- see finding F6 in
## `ralph/reports/MP-7A-RELIABILITY-0906/REPORT.md` -- and it is also the
## sharper test of this row: the peer that quits is the one arbitrating.
##
## ## Negative control (contract §11)
##
## Assertion 1's "did not exist before" is the control for its own "exists
## after": in this run's fresh home nothing has ever written that file, so its
## appearance is caused by the exit and by nothing else. Recorded in
## `ralph/reports/MP-7A-RELIABILITY-0906/REPORT.md`.

const BUILDING_ID := "floor"
const LATE_FLAG := "smoke_host_exit_last_thing"

## Wall-clock seconds of steps. Above the shard's shared 300 s because this
## run stands a fight up inside the step phase, and an encounter is the one
## thing here whose cost is not a fixed number of frames.
const HOST_EXIT_STEP_BUDGET_S := 480.0


func _initialize() -> void:
	_run()


func _run() -> void:
	# The CLIENT goes deliberately, legitimately silent for the length of one
	# scene change: `session.gd::_return_to_title()` calls
	# `change_scene_to_file(TITLE_SCENE)`, and tearing the Meadows down and
	# standing the title screen up is one blocking frame. Contract §3's 15 s
	# "peer silent" rule would call that a dead peer -- measured on this
	# smoke's first run, which reported `ERROR: peer silent (peer 1, no
	# heartbeat for >15 s)` at exactly that moment.
	#
	# Same mechanism and same reasoning as `smoke_net_join_by_address.gd`,
	# which is the only OTHER smoke whose peer changes scene after hello, and
	# the same 240 s. Set before `launch()` because the silence can begin
	# before the last hello arrives. This is the harness's own documented
	# limit, not a tolerance widened until something passed.
	heartbeat_silence_tolerance_s = 240.0
	if not await launch(2, "world"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + HOST_EXIT_STEP_BUDGET_S * 1000.0

	check(_peers.size() == 2, "coordinator tracked 2 peers")

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

	var joined: Dictionary = await step(1, "join",
		{"host": "127.0.0.1", "port": host_port,
		 "character": {"character_id": "host-exit-joiner", "display_name": "Joiner"}}, 6000)
	check(str(joined.get("verdict", "")) == "PASS",
		"peer 1 joined (%s)" % str(joined.get("detail", "")))
	if str(joined.get("verdict", "")) != "PASS":
		quit(await finish())
		return

	# 1's control: nothing has written this file in this run's fresh home.
	var host_saved_before = await probe(0, "autosave_exists")
	check(host_saved_before == false,
		"the host had written no world autosave before the exit (%s)" % str(host_saved_before))
	var client_saved_before = await probe(1, "autosave_exists")
	check(client_saved_before == false,
		"the client had written no world autosave before the exit (%s)" % str(client_saved_before))

	# --- the load ------------------------------------------------------------
	# SETUP, not the feature under test: a peer cannot fight with an empty
	# party, and every headless peer boots with one. `deploy_creature` is the
	# same setup `smoke_net_shared_wild_fight.gd` does before its own
	# `engage_wild`, and it goes through the game's own `encounter_director.gd`.
	# Without it `engage_wild` answers "the engage press did not start a fight",
	# which reads like the encounter path failing when it is really this line
	# missing.
	for i in 2:
		var deployed: Dictionary = await step(i, "deploy_creature", {}, 6000)
		check(str(deployed.get("verdict", "")) == "PASS",
			"SETUP: peer %d has a creature out to fight with (%s)" % [i, str(deployed.get("detail", ""))])

	# THE HOST engages and the client joins, which is the shape the game
	# actually supports -- and, better for this row, it puts the exiting peer
	# in the middle of a fight it is itself arbitrating.
	#
	# FOLLOWING THE CODE, and saying so: this smoke first had the CLIENT engage,
	# on the reasoning that a host arbitrating a fight it did not begin is the
	# harder case. It never bound: `engage_wild` from a client leaves
	# `combat_manager.is_fighting()` true and `encounter_id()` empty, through a
	# 600-frame poll. Every net smoke in the directory engages from peer 0 and
	# reaches a client into the fight through `join_encounter` on a record the
	# host already minted; a client ORIGINATING a wild encounter has no coverage
	# anywhere and does not appear to be a path that exists today. That is
	# recorded as finding F6 rather than worked around, and this smoke uses the
	# supported shape.
	var engaged: Dictionary = await step(0, "engage_wild", {"settle": 60}, 6000)
	var fighting := str(engaged.get("verdict", "")) == "PASS"
	check(fighting, "the host is mid-fight when it exits (%s)" % str(engaged.get("detail", "")))

	var encounter_id := ""
	if fighting:
		var host_view: Dictionary = await _encounter(0)
		encounter_id = str(host_view.get("id", ""))
		check(not encounter_id.is_empty(),
			"the host minted an encounter record for that fight ('%s')" % encounter_id)
		# The client into the same fight, so the session is busy at BOTH ends
		# when the host quits -- which is what "under load" means for this row.
		var here: Array = host_view.get("opponent_pos", []) as Array
		if here.size() == 3:
			var travelled: Dictionary = await step(1, "teleport",
				{"at": [float(here[0]) - 2.5, float(here[1]) + 1.0, float(here[2])]})
			check(str(travelled.get("verdict", "")) == "PASS",
				"the client travelled to the fight (%s)" % str(travelled.get("detail", "")))
		var joined_fight: Dictionary = await step(1, "join_encounter",
			{"encounter_id": encounter_id}, 6000)
		check(str(joined_fight.get("verdict", "")) == "PASS",
			"the client joined the fight in progress, so BOTH ends are busy (%s)"
				% str(joined_fight.get("detail", "")))
	else:
		# HONEST: a Meadows boot that spawned no wild in reach is a world
		# condition, not this row's failure. The run continues so the save half
		# is still measured, and the check above already records that the
		# under-load half did not happen.
		print("coordinator: no wild in reach; the exit is measured WITHOUT a live fight")

	# --- the last things, after the fight started ----------------------------
	# Placed AFTER the load so a save that ran one beat early cannot carry them.
	var built: Dictionary = await step(0, "build_place", {"id": BUILDING_ID})
	check(str(built.get("verdict", "")) == "PASS",
		"the host placed a building mid-session (%s)" % str(built.get("detail", "")))
	var rows_live = await probe(0, "placed_building_rows")
	check(rows_live is Array and (rows_live as Array).size() > 0,
		"the host holds that building record live (%s)" % str(rows_live))

	var flagged: Dictionary = await step(0, "story_flag", {"flag": LATE_FLAG, "scope": "world"})
	check(str(flagged.get("verdict", "")) == "PASS",
		"the host committed a world flag mid-session (%s)" % str(flagged.get("detail", "")))
	var flag_landed: Dictionary = await step(0, "wait_flag",
		{"flag": LATE_FLAG, "scope": "world", "budget_frames": 600})
	check(str(flag_landed.get("verdict", "")) == "PASS",
		"that flag is live on the host immediately before the exit (%s)" % str(flag_landed.get("detail", "")))

	# --- the exit ------------------------------------------------------------
	var host_left: Dictionary = await step(0, "leave", {"reason": "host_exit"}, 900)
	check(str(host_left.get("verdict", "")) == "PASS",
		"the host exited its session under load (%s)" % str(host_left.get("detail", "")))

	# 1. The file exists now.
	var host_saved = await probe(0, "autosave_exists")
	check(host_saved == true, "the host wrote its world autosave on exit (%s)" % str(host_saved))

	# 2. And it carries the last things. `autosave_dict` re-reads THE AUTOSAVE
	# FILE off disk -- the one `session.gd::leave()` writes -- rather than
	# reporting the live arrays, which is the whole point: a live count would
	# be identical whether or not anything was written, and `save_dict` would
	# be worse still because it saves before it reads.
	var saved_raw = await probe(0, "autosave_dict")
	var saved_world: Dictionary = (saved_raw as Dictionary) if saved_raw is Dictionary else {}
	check(not saved_world.is_empty(),
		"the host's autosave file re-read off disk (%d keys)" % saved_world.size())
	check(_building_count(saved_world.get("placed_buildings")) > 0,
		"the saved world carries the building placed after the fight began (%s)"
			% str(saved_world.get("placed_buildings")))

	var saved_flags := _saved_world_flags(saved_world)
	check(saved_flags.has(LATE_FLAG),
		"the saved world carries the flag committed immediately before the exit (flags: %d, has '%s': %s)"
			% [saved_flags.size(), LATE_FLAG, str(saved_flags.has(LATE_FLAG))])

	# 3. The client was sent home.
	var client_ended: Dictionary = await step(1, "wait_context", {"equals": "title", "budget_frames": 3000}, 6000)
	check(str(client_ended.get("verdict", "")) == "PASS",
		"the client was returned to the title screen (%s)" % str(client_ended.get("detail", "")))
	var client_session: Dictionary = await _session_of(1)
	check(not bool(client_session.get("active", true)),
		"the client's session is no longer active (%s)" % str(client_session))

	# 4. D100, under load.
	var client_saved = await probe(1, "autosave_exists")
	check(client_saved == false,
		"the client wrote NO world file, mid-fight or not (%s)" % str(client_saved))
	var client_worlds = await probe(1, "worlds_dir_entries")
	check(client_worlds is Array and (client_worlds as Array).is_empty(),
		"the client's user://worlds/ is empty (%s)" % str(client_worlds))

	# 5. And the host closed its own session rather than merely stopping talking.
	var host_session: Dictionary = await _session_of(0)
	check(not bool(host_session.get("active", true)),
		"the host's session is closed (%s)" % str(host_session))

	quit(await finish())


func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return (value as Dictionary) if value is Dictionary else {}


func _session_of(peer: int) -> Dictionary:
	var raw = await probe(peer, "session")
	return (raw as Dictionary) if raw is Dictionary else {}


## `saved_world_buildings` answers a shape lane 3.C chose; this reads a count
## out of whichever of the two it is (an Array of rows, or a Dictionary
## carrying one) without assuming, so a shape change is a legible 0 rather than
## an `int(null)` that silently aborts the surrounding check.
func _building_count(value: Variant) -> int:
	if value is Array:
		return (value as Array).size()
	if value is Dictionary:
		var d: Dictionary = value
		for key: String in ["rows", "buildings", "placed_buildings"]:
			if d.has(key) and d[key] is Array:
				return (d[key] as Array).size()
	return 0


## Every world flag in a re-read save dictionary. The save file's own key is
## `progression` (`save_game.gd` merges world and player flags into one list
## on disk); this reads whichever of the two shapes is present rather than
## asserting one, and returns a Dictionary so `has()` is a real answer.
func _saved_world_flags(value: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (value is Dictionary):
		return out
	var d: Dictionary = value
	for key: String in ["progression", "flags"]:
		if not d.has(key):
			continue
		var section: Variant = d[key]
		if section is Array:
			for f: Variant in (section as Array):
				out[str(f)] = true
		elif section is Dictionary:
			var sd: Dictionary = section
			for inner: String in ["flags", "set", "ids"]:
				if sd.has(inner) and sd[inner] is Array:
					for f2: Variant in (sd[inner] as Array):
						out[str(f2)] = true
			for k: Variant in sd.keys():
				if sd[k] is bool and bool(sd[k]):
					out[str(k)] = true
	return out
