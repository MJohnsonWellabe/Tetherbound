extends "res://tests/helpers/net_harness.gd"

# peers: 2
## side_water_deep_watch_chart across two real processes, both booted in the
## production Water scene (explicit water-only realm fixture). Tidecoil is
## resolved on ONE peer through genuine ordinary creature attacks, and its cache
## is then
## claimed by the CLIENT through its own streamer and the host's claim rule.
##   TB_DEEP_WATCH_RESOLVER=client (default): the client's local once write must
##     reach host world truth (relay -> set_world_flag intent).
##   TB_DEEP_WATCH_RESOLVER=host: the host's direct once write must reach the
##     client's world mirror (relay -> published flag op) so its streamer shows
##     the cache.
## Disclosed inputs: one owned level-55 Terrapup per peer before admission;
## teleport actor poses, real tent/bedroll nodes and ordinary bed interaction.
## No clock/result/trait/save fixture. After the original cache assertions,
## production resolution/departure/day/save/publication/rejoin retain generation 2.

func _initialize() -> void:
	_run()

func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", log_path,
		"--script", "res://tests/fixtures/water_deep_watch_peer.gd", "--", "--role=" + role,
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
	var resolver_name := OS.get_environment("TB_DEEP_WATCH_RESOLVER")
	var resolver := 0 if resolver_name == "host" else 1
	var observer := 1 - resolver
	print("deep watch co-op: resolver=%s" % ("host" if resolver == 0 else "client"))
	if not await launch(2, "water"):
		quit(await finish())
		return
	for peer in 2:
		var granted: Dictionary = await step(peer, "party_grant", {"species": "terrapup", "level": 55})
		check(granted.get("verdict") == "PASS", "Disclosed owned level-55 fight input saved before admission")
		if granted.get("verdict") != "PASS":
			quit(await finish())
			return
		var saved: Dictionary = await step(peer, "save_character_here")
		check(saved.get("verdict") == "PASS", "Disclosed owned fight input reaches its physical character file before admission")
		if saved.get("verdict") != "PASS":
			quit(await finish())
			return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 900000.0
	check((await step(0, "host")).get("verdict") == "PASS", "Host starts production session")
	var session: Variant = await probe(0, "session")
	if _stopped(session, "session probe"):
		quit(await finish())
		return
	check((await step(1, "join", {"host": "127.0.0.1", "port": (session as Dictionary).get("enet_port", 0)})).get("verdict") == "PASS", "Client joins production session")
	for peer in 2:
		check((await step(peer, "expect_peers", {"count": 2})).get("verdict") == "PASS", "Both peers are connected")
	if _stopped({}, "join"):
		quit(await finish())
		return
	var locked: Dictionary = await step(1, "deep_watch_claim_locked", {}, 1200)
	check(locked.get("verdict") == "PASS", "Client: cache withheld and host refuses it as locked before resolution: " + str(locked.get("detail", "")) + " " + str(locked.get("data", {})))
	var host_state: Variant = await probe(0, "deep_watch")
	if _stopped(host_state, "host deep_watch probe (before resolution)"):
		quit(await finish())
		return
	check(not bool((host_state as Dictionary).get("resolved", true)) and int((host_state as Dictionary).get("receipts", -1)) == 0, "Host world: unresolved and unclaimed before resolution")
	var resolution_args := {"accepted_alpha_cycle": true}
	if resolver == 1:
		check((await step(0, "deep_watch_visit_alpha")).get("verdict") == "PASS", "Host approaches the actual retained Alpha")
		check((await step(0, "deploy_creature")).get("verdict") == "PASS", "Host deploys its admitted owned creature")
		check((await step(0, "engage_wild", {"foundation_alpha_site": "water_deep_watch_tidecoil"})).get("verdict") == "PASS",
			"Host opens the actual Alpha record without a client-local substitute")
		var opened: Variant = await probe(0, "encounter")
		if _stopped(opened, "host Alpha encounter"):
			quit(await finish())
			return
		resolution_args["host_encounter_id"] = str((opened as Dictionary).get("id", ""))
		var canonical: Variant = await probe(0, "deep_watch", {"encounter_id": resolution_args.host_encounter_id})
		if _stopped(canonical, "canonical actor prerequisite"):
			quit(await finish())
			return
		check(not resolution_args.host_encounter_id.is_empty() and canonical.get("canonical_actor_ready") == true,
			"Legitimately integrated canonical actor source is required; legacy records cannot supply accepted Alpha defeat")
		if not failures.is_empty():
			quit(await finish())
			return
	var resolved: Dictionary = await step(resolver, "deep_watch_resolve", resolution_args, 1200)
	check(resolved.get("verdict") == "PASS", "Resolver records Tidecoil locally: " + str(resolved.get("detail", "")))
	var carried: Dictionary = await step(observer, "wait_flag", {"flag": "water_named_deep_watch_tidecoil_resolved", "scope": "world", "budget_frames": 600}, 1200)
	check(carried.get("verdict") == "PASS", "Resolution reaches the other peer's world store: " + str(carried.get("detail", "")))
	host_state = await probe(0, "deep_watch")
	if _stopped(host_state, "host deep_watch probe (after resolution)"):
		quit(await finish())
		return
	check(bool((host_state as Dictionary).get("resolved", false)), "Host world truth holds the Tidecoil resolution")
	var claimed: Dictionary = await step(1, "deep_watch_claim", {}, 1200)
	check(claimed.get("verdict") == "PASS", "Client claims the unlocked cache through host authority: " + str(claimed.get("detail", "")) + " " + str(claimed.get("data", {})))
	host_state = await probe(0, "deep_watch")
	var client_state: Variant = await probe(1, "deep_watch")
	if _stopped(host_state, "host deep_watch probe (after claim)") or _stopped(client_state, "client deep_watch probe"):
		quit(await finish())
		return
	check(int((host_state as Dictionary).get("receipts", -1)) == 1, "Host records exactly one durable character receipt")
	check(bool((client_state as Dictionary).get("resolved", false)), "Client mirror holds the resolution")
	if not failures.is_empty():
		quit(await finish())
		return
	var encounter_id := str(resolved.get("data", {}).get("encounter_id", ""))
	var waiting: Dictionary = {}
	var cycle_sample: Variant
	for poll in 20:
		cycle_sample = await probe(0, "deep_watch", {"encounter_id": encounter_id})
		if _stopped(cycle_sample, "accepted waiting cycle"):
			quit(await finish())
			return
		waiting = cycle_sample as Dictionary
		if waiting.get("cycle", {}).get("status") == "waiting" and waiting.get("saved_cycle") == waiting.get("cycle"): break
		await step(0, "wait", {"frames": 30})
	check(not encounter_id.is_empty() and waiting.get("accepted_kill") == true and waiting.get("enemy_fainted") == true,
		"Original host source proves genuine accepted killing strike and faint")
	check(waiting.get("cycle", {}).get("status") == "waiting" and waiting.get("cycle", {}).get("generation") == 1 \
		and waiting.get("saved_cycle") == waiting.get("cycle"), "Production generation-1 resolution is saved before any later save action")
	cycle_sample = await probe(1, "deep_watch")
	if _stopped(cycle_sample, "client waiting cycle"):
		quit(await finish())
		return
	var client_waiting: Dictionary = cycle_sample as Dictionary
	check(client_waiting.get("cycle", {}).get("status") == "waiting", "Client observes accepted waiting cycle before departure")
	if not failures.is_empty():
		quit(await finish())
		return
	var initial_day := int(waiting.get("day", 0))
	var respawn_days := int(preload("res://scripts/repeatables/alpha_respawns.gd").config().respawn_days)
	check(respawn_days == 3 and initial_day > 0, "Actual shipping configured three-day interval")
	for peer in 2:
		check((await step(peer, "deep_watch_depart_alpha")).get("verdict") == "PASS", "Peer reaches authored different region")
	var departed: Dictionary = {}
	for poll in 20:
		cycle_sample = await probe(0, "deep_watch")
		if _stopped(cycle_sample, "accepted departure census"):
			quit(await finish())
			return
		departed = cycle_sample as Dictionary
		var row: Dictionary = departed.get("cycle", {})
		if not row.get("required_departures", []).is_empty() and row.get("departed") == row.get("required_departures"): break
		await step(0, "wait", {"frames": 30})
	check(not departed.get("cycle", {}).get("required_departures", []).is_empty() \
		and departed.get("cycle", {}).get("departed") == departed.get("cycle", {}).get("required_departures"),
		"Production census records every required character leaving the region")
	if not failures.is_empty():
		quit(await finish())
		return
	for peer in 2:
		check((await step(peer, "sleep_stand")).get("verdict") == "PASS", "Disclosed real bedroll and shelter")
	for night in respawn_days:
		for peer in 2:
			check((await step(peer, "sleep_press")).get("verdict") == "PASS", "Ordinary bed interaction votes for next day")
		await step(0, "wait", {"frames": 120})
		await step(1, "wait", {"frames": 120})
		var clock_host: Variant = await probe(0, "day")
		var clock_client: Variant = await probe(1, "day")
		if not _fatal_reason.is_empty():
			quit(await finish())
			return
		check(int(clock_host) == initial_day + night + 1 and int(clock_client) == int(clock_host), "One actual host day transition reaches both peers")
		if night + 1 < respawn_days:
			cycle_sample = await probe(0, "deep_watch")
			if _stopped(cycle_sample, "pre-eligible cycle"):
				quit(await finish())
				return
			var early: Dictionary = cycle_sample as Dictionary
			check(early.get("cycle", {}).get("status") == "waiting" and early.get("cycle", {}).get("generation") == 1,
				"Alpha cannot respawn before its configured day")
		if not failures.is_empty():
			quit(await finish())
			return
	var born: Dictionary = {}
	for poll in 20:
		cycle_sample = await probe(0, "deep_watch")
		if _stopped(cycle_sample, "saved fresh generation"):
			quit(await finish())
			return
		born = cycle_sample as Dictionary
		if born.get("cycle", {}).get("generation") == 2 and born.get("saved_retained") == born.get("retained") \
				and not born.get("retained", {}).is_empty(): break
		await step(0, "wait", {"frames": 30})
	check(born.get("cycle", {}).get("status") == "active" and born.get("cycle", {}).get("generation") == 2 \
		and not born.get("retained", {}).is_empty() and born.get("saved_retained") == born.get("retained"),
		"Production host commits fresh generation-2 traits before body publication or explicit save")
	var retained: Dictionary = born.get("retained", {}).duplicate(true)
	check(retained.get("captured_from") == {"kind": "wild", "world_namespace": born.get("world_namespace"),
		"spawn_id": "water_deep_watch_tidecoil", "spawn_generation": 2}, "Fresh packet binds original host namespace/site and next generation")
	if not failures.is_empty():
		quit(await finish())
		return
	for peer in 2:
		check((await step(peer, "deep_watch_visit_alpha")).get("verdict") == "PASS", "Return to original Alpha activation radius")
		var published: Dictionary = {}
		for poll in 20:
			cycle_sample = await probe(peer, "deep_watch")
			if _stopped(cycle_sample, "published fresh generation"):
				quit(await finish())
				return
			published = cycle_sample as Dictionary
			if published.get("bodies", []).size() == 1 and published.bodies[0].get("generation") == 2: break
			await step(peer, "wait", {"frames": 30})
		check(published.get("retained") == retained and published.get("bodies", []).size() == 1 \
			and published.bodies[0].get("packet") == retained and published.bodies[0].get("initialized") == true \
			and published.bodies[0].get("rolled_traits") == retained.get("rolled_traits"),
			"Host/client publish exactly the original saved generation-2 packet after waiting")
	check((await step(0, "save_reload_here")).get("verdict") == "PASS", "Ordinary host save/reload retains accepted world")
	cycle_sample = await probe(0, "deep_watch")
	if _stopped(cycle_sample, "host reload generation"):
		quit(await finish())
		return
	var reloaded: Dictionary = cycle_sample as Dictionary
	check(reloaded.get("retained") == retained and reloaded.get("saved_retained") == retained, "Host reload does not reroll the fresh generation")
	check((await step(1, "leave")).get("verdict") == "PASS", "Client ordinary leave")
	check((await step(1, "join", {"host": "127.0.0.1", "port": (session as Dictionary).get("enet_port", 0)})).get("verdict") == "PASS", "Client ordinary rejoin")
	check((await step(1, "deep_watch_visit_alpha")).get("verdict") == "PASS", "Rejoined client returns to retained Alpha")
	cycle_sample = await probe(1, "deep_watch")
	if _stopped(cycle_sample, "client rejoin generation"):
		quit(await finish())
		return
	var rejoined: Dictionary = cycle_sample as Dictionary
	check(rejoined.get("character_id") == client_state.get("character_id") and rejoined.get("retained") == retained \
		and rejoined.get("bodies", []).size() == 1 and rejoined.bodies[0].get("packet") == retained,
		"Same-character rejoin retains generation-2 body and exact saved traits without reroll")
	quit(await finish())


## True when the run cannot continue: the harness has recorded a fatal result
## (peer silent/exited, budget), or a probe came back empty. The caller quits
## through finish() instead of dereferencing a null probe and hanging.
func _stopped(value: Variant, what: String) -> bool:
	if not _fatal_reason.is_empty():
		print("deep watch co-op: stopping after %s: %s" % [what, _fatal_reason])
		return true
	if not value is Dictionary:
		check(false, "%s returned nothing (peer dead, silent or probe missing)" % what)
		return true
	return false
