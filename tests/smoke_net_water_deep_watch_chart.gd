extends "res://tests/helpers/net_harness.gd"

# peers: 2
## side_water_deep_watch_chart across two real processes, both booted in the
## production Water scene (explicit water-only realm fixture). Pre-session
## owned level49 Mosshells and trainer/actor placement/aim are input fixtures,
## not earned progression. The host opens the original retained Tidecoil and
## the client joins that real encounter; the non-resolver flees normally.
##   TB_DEEP_WATCH_RESOLVER=client (default): CLIENT inputs land the killing hit.
##   TB_DEEP_WATCH_RESOLVER=host: HOST inputs land the killing hit.
## Both require the same canonical host resolution/world relay, then the real
## client cache claim and one durable receipt. No private terminal callback,
## HP cap/top-up, guest Alpha copy or fixture flag is used. This does not claim
## earned journey proof or a guest-local flag-write relay branch.

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
	_step_phase_deadline_ms = Time.get_ticks_msec() + 900000.0
	var fixture_uids: Array[String] = []
	for peer in 2:
		if not await _required_step(peer, "party_grant", {"species": "water_mosshell", "level": 49}):
			quit(await finish())
			return
		var prepared: Variant = await probe(peer, "deep_watch")
		if _stopped(prepared, "owned input fixture"):
			quit(await finish())
			return
		var uid := ""
		for creature: Dictionary in (prepared as Dictionary).get("owned", []):
			if creature.get("species") == "water_mosshell" and int(creature.get("level", 0)) == 49:
				uid = str(creature.get("uid", ""))
		check(not uid.is_empty() and not fixture_uids.has(uid), "Peer %d owns its distinct fixture UID before joining" % peer)
		if uid.is_empty() or fixture_uids.has(uid):
			quit(await finish())
			return
		fixture_uids.append(uid)
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
	var staged: Dictionary = await step(0, "deep_watch_stage", {}, 1200)
	check(staged.get("verdict") == "PASS", "Host streams the original retained Tidecoil: " + str(staged.get("detail", "")))
	if staged.get("verdict") != "PASS":
		quit(await finish())
		return
	if not await _required_step(1, "deep_watch_stage"):
		quit(await finish())
		return
	for peer in 2:
		if not await _required_step(peer, "deploy_creature"):
			quit(await finish())
			return
	var opened: Dictionary = await step(0, "deep_watch_open", {}, 1200)
	check(opened.get("verdict") == "PASS", "Host opens the real named fight through production interaction: " + str(opened.get("detail", "")))
	if opened.get("verdict") != "PASS":
		quit(await finish())
		return
	var id := str(opened.get("data", {}).get("encounter_id", ""))
	var opponent: Dictionary = opened.get("data", {}).get("opponent", {})
	check(opponent.get("species_id") == "tidecoil" and opponent.get("card", {}).get("uid") == staged.get("data", {}).get("card", {}).get("uid"),
		"Opened record uses the original retained Tidecoil UID, not another nearby wild")
	if not await _required_step(1, "join_encounter", {"encounter_id": id}):
		quit(await finish())
		return
	var client_session: Variant = await probe(1, "session")
	var guest_fight: Variant = await probe(1, "encounter")
	if _stopped(client_session, "client identity") or _stopped(guest_fight, "admitted guest record"):
		quit(await finish())
		return
	var host_peer := int((session as Dictionary).get("peer_id", 0))
	var client_peer := int((client_session as Dictionary).get("peer_id", 0))
	check(host_peer == 1 and client_peer > 1, "Resolver identities come from two real ENet peers")
	var guest: Dictionary = guest_fight
	check(guest.get("bound_id") == id and guest.get("id") == id and guest.get("phase") == "active"
		and (guest.get("participants", []) as Array).has(client_peer)
		and guest.get("presentation_script") == "res://scripts/creatures/shared_opponent_proxy.gd"
		and int(guest.get("presentation_body_generation", -1)) == int(opponent.get("body_generation", 0))
		and guest.get("opponent_card", {}).get("uid") == opponent.get("card", {}).get("uid"),
		"Client joins the actual host record and renders its canonical UID/generation")
	if not await _required_step(observer, "press", {"action": "combat_run"}):
		quit(await finish())
		return
	var sole: Dictionary = await step(0, "deep_watch_wait_resolver", {"encounter_id": id,
		"resolver_peer": host_peer if resolver == 0 else client_peer}, 1200)
	check(sole.get("verdict") == "PASS" and int(sole.get("data", {}).get("body_id", -1)) == int(staged.get("data", {}).get("body_id", -2))
		and int(sole.get("data", {}).get("body_generation", -1)) == int(opponent.get("body_generation", 0)),
		"Normal withdrawal preserves the original canonical body/runtime for the sole resolver: " + str(sole.get("detail", "")))
	if sole.get("verdict") != "PASS":
		quit(await finish())
		return
	var resolved: Dictionary = await step(resolver, "deep_watch_resolve", {"encounter_id": id}, 1200)
	check(resolved.get("verdict") == "PASS", "Resolver finishes Tidecoil through real combat input: " + str(resolved.get("detail", "")))
	var carried: Dictionary = await step(observer, "wait_flag", {"flag": "water_named_deep_watch_tidecoil_resolved", "scope": "world", "budget_frames": 600}, 1200)
	check(carried.get("verdict") == "PASS", "Resolution reaches the other peer's world store: " + str(carried.get("detail", "")))
	host_state = await probe(0, "deep_watch")
	if _stopped(host_state, "host deep_watch probe (after resolution)"):
		quit(await finish())
		return
	check(bool((host_state as Dictionary).get("resolved", false)), "Host world truth holds the Tidecoil resolution")
	var source: Dictionary = (host_state as Dictionary).get("victory_source", {})
	var accepted: Dictionary = source.get("accepted", {})
	var deployments: Array = source.get("deployments", [])
	check(source.get("ok") == true and accepted.get("ok") == true and accepted.get("delta", {}).get("killed") == true
		and int(accepted.get("peer", 0)) == (host_peer if resolver == 0 else client_peer)
		and accepted.get("delta", {}).get("encounter_id") == id and source.get("enemy_record", {}).get("fainted") == true
		and float(source.get("enemy_record", {}).get("hp", -1)) == 0.0
		and source.get("enemy_record", {}).get("uid") == opponent.get("card", {}).get("uid"),
		"Actual host frozen defeat source proves the chosen resolver killed the original named UID")
	check(deployments.size() == 1 and deployments[0].get("active_uid") == fixture_uids[resolver]
		and int(deployments[0].get("peer_id", 0)) == (host_peer if resolver == 0 else client_peer),
		"Accepted defeat uses the same resolver-owned UID admitted before the session")
	var cycle: Dictionary = (host_state as Dictionary).get("alpha_cycle", {})
	check(cycle.get("status") == "waiting" and int(cycle.get("generation", -1)) == int(staged.get("data", {}).get("alpha_generation", 0)),
		"One canonical original Alpha generation is durably resolved without replacement")
	var claimed: Dictionary = await step(1, "deep_watch_claim", {}, 1200)
	check(claimed.get("verdict") == "PASS", "Client claims the unlocked cache through host authority: " + str(claimed.get("detail", "")) + " " + str(claimed.get("data", {})))
	host_state = await probe(0, "deep_watch")
	var client_state: Variant = await probe(1, "deep_watch")
	if _stopped(host_state, "host deep_watch probe (after claim)") or _stopped(client_state, "client deep_watch probe"):
		quit(await finish())
		return
	check(int((host_state as Dictionary).get("receipts", -1)) == 1, "Host records exactly one durable character receipt")
	check(bool((client_state as Dictionary).get("resolved", false)), "Client mirror holds the resolution")
	check(int((client_state as Dictionary).get("named_bodies", -1)) == 0, "Client never creates an independent named Alpha body")
	quit(await finish())


func _required_step(peer: int, action: String, args: Dictionary = {}) -> bool:
	var result: Dictionary = await step(peer, action, args, 1200)
	var ok: bool = result.get("verdict") == "PASS" and _fatal_reason.is_empty()
	check(ok, "Peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	return ok


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
