extends "res://tests/helpers/net_harness.gd"

# peers: 2
## F13 Tidewake local chains across two real processes, both booted in the
## production Water scene. Proves the co-op split the chains declare:
##  - a CLIENT's speech step (Halen's lead) is committed by the host and its
##    world record reaches both peers;
##  - a CLIENT's delivery debits only the client's materials, and the shelter
##    it builds appears in the HOST's scene;
##  - a per-character receipt check (Pell's return) refuses the client while
##    only the HOST holds its Lantern Cove claim, and accepts once the client
##    claims its own Candy I; the world completion then reaches the host.
## Fixtures: teleport poses; delivered materials added to the client satchel;
## the swim lesson's world completion is set by a host set_world_flag intent.

func _initialize() -> void:
	_run()

func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", log_path,
		"--script", "res://tests/fixtures/water_local_chain_peer.gd", "--", "--role=" + role,
		"--peer=%d" % i, "--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=" + scene, "TB_NET_RUN_ID=" + _run_id]
	args.append_array(extra_args)
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	return OS.create_process(OS.get_executable_path(), args)

func _run() -> void:
	if not await launch(2, "water"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 900000.0
	check((await step(0, "host")).get("verdict") == "PASS", "Host starts production session")
	var session: Dictionary = await probe(0, "session")
	check((await step(1, "join", {"host": "127.0.0.1", "port": session.enet_port})).get("verdict") == "PASS", "Client joins production session")
	for peer in 2:
		check((await step(peer, "expect_peers", {"count": 2})).get("verdict") == "PASS", "Both peers are connected")

	# Lastlight shelter, driven by the client.
	var lead: Dictionary = await step(1, "chain_hear", {"npc": "water_halen", "expect": "water_halen_shelter_lead",
		"expect_flag": "water_claim:local:lastlight_shelter:lead"}, 1200)
	check(lead.get("verdict") == "PASS", "Client hears Halen's lead; host commits it: " + str(lead.get("detail", "")))
	var carried: Dictionary = await step(0, "wait_flag", {"flag": "water_claim:local:lastlight_shelter:lead", "scope": "world", "budget_frames": 600}, 1200)
	check(carried.get("verdict") == "PASS", "Lead record is in host world truth")
	var host_before: Dictionary = await probe(0, "chain")
	var short: Dictionary = await step(1, "chain_site", {"step": "lastlight_shelter_supply", "flag": "water_claim:local:lastlight_shelter:supplied",
		"give": {"driftwood": 4, "reed_fiber": 3}, "expect_recorded": false, "expect_code": "materials"}, 1200)
	check(short.get("verdict") == "PASS", "Host refuses the client's short delivery: " + str(short.get("detail", "")))
	var delivered: Dictionary = await step(1, "chain_site", {"step": "lastlight_shelter_supply", "flag": "water_claim:local:lastlight_shelter:supplied",
		"give": {"reed_fiber": 1}}, 1200)
	check(delivered.get("verdict") == "PASS", "Client delivery committed by the host: " + str(delivered.get("detail", "")))
	await step(0, "wait_flag", {"flag": "water_claim:local:lastlight_shelter:supplied", "scope": "world", "budget_frames": 600}, 1200)
	var client_state: Dictionary = await probe(1, "chain")
	var host_state: Dictionary = await probe(0, "chain")
	check(int(client_state.driftwood) == 0 and int(client_state.reed_fiber) == 0, "Only the deliverer paid: client debited exactly 4 + 4 (%s)" % str(client_state))
	check(int(host_state.driftwood) == int(host_before.driftwood) and int(host_state.reed_fiber) == int(host_before.reed_fiber), "Host materials untouched")
	check(bool(host_state.shelter_built) and bool(client_state.shelter_built), "Shared shelter stands in both scenes")

	# Lantern return: per-character receipts across peers.
	if not bool(host_state.lesson):
		var early: Dictionary = await step(0, "chain_request", {"npc": "water_pell", "step": "lantern_return_lead",
			"flag": "water_claim:local:lantern_return:lead", "expect_recorded": false, "expect_code": "prerequisite"}, 1200)
		check(early.get("verdict") == "PASS", "Lead refused before the swim lesson: " + str(early.get("detail", "")))
	check((await step(0, "chain_world_flag", {"flag": "water_swim_lesson_complete"}, 1200)).get("verdict") == "PASS", "Swim lesson fixture set on the host")
	await step(1, "wait_flag", {"flag": "water_swim_lesson_complete", "scope": "world", "budget_frames": 600}, 1200)
	check((await step(0, "chain_claim", {}, 1200)).get("verdict") == "PASS", "Host claims its own Lantern Cove Candy I")
	var refused: Dictionary = await step(1, "chain_request", {"npc": "water_pell", "step": "lantern_return_report",
		"flag": "water_claim:local:lantern_return:complete", "expect_recorded": false, "expect_code": "claim"}, 1200)
	check(refused.get("verdict") == "PASS", "The host's receipt does not let the client report: " + str(refused.get("detail", "")))
	check((await step(1, "chain_claim", {}, 1200)).get("verdict") == "PASS", "Client claims its own Candy I")
	var reported: Dictionary = await step(1, "chain_request", {"npc": "water_pell", "step": "lantern_return_report",
		"flag": "water_claim:local:lantern_return:complete"}, 1200)
	check(reported.get("verdict") == "PASS", "Client's own receipt completes the return: " + str(reported.get("detail", "")))
	await step(0, "wait_flag", {"flag": "water_claim:local:lantern_return:complete", "scope": "world", "budget_frames": 600}, 1200)
	host_state = await probe(0, "chain")
	client_state = await probe(1, "chain")
	check(int(host_state.candy_receipts) == 2, "Two per-character Candy I receipts in host truth")
	check(int(host_state.candy_i) >= 1 and int(client_state.candy_i) >= 1, "Each character holds its own Candy I")
	check(host_state.records == client_state.records, "Both peers hold the same chain records: " + str(host_state.records))
	quit(await finish())
