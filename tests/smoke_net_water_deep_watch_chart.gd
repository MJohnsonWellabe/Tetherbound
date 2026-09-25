extends "res://tests/helpers/net_harness.gd"

# peers: 2
## side_water_deep_watch_chart across two real processes, both booted in the
## production Water scene (explicit water-only realm fixture). Tidecoil is
## resolved on ONE peer by the director's production won-fight terminal handler
## (no fight is played; poses are teleports) and the Tidecoil cache is then
## claimed by the CLIENT through its own streamer and the host's claim rule.
##   TB_DEEP_WATCH_RESOLVER=client (default): the client's local once write must
##     reach host world truth (relay -> set_world_flag intent).
##   TB_DEEP_WATCH_RESOLVER=host: the host's direct once write must reach the
##     client's world mirror (relay -> published flag op) so its streamer shows
##     the cache.

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
	check((await step(0, "host")).get("verdict") == "PASS", "Host starts production session")
	var session: Dictionary = await probe(0, "session")
	check((await step(1, "join", {"host": "127.0.0.1", "port": session.enet_port})).get("verdict") == "PASS", "Client joins production session")
	for peer in 2:
		check((await step(peer, "expect_peers", {"count": 2})).get("verdict") == "PASS", "Both peers are connected")
	var locked: Dictionary = await step(1, "deep_watch_claim_locked", {}, 1200)
	check(locked.get("verdict") == "PASS", "Client: cache withheld and host refuses it as locked before resolution: " + str(locked.get("detail", "")) + " " + str(locked.get("data", {})))
	var host_state: Dictionary = await probe(0, "deep_watch")
	check(not host_state.resolved and int(host_state.receipts) == 0, "Host world: unresolved and unclaimed before resolution")
	var resolved: Dictionary = await step(resolver, "deep_watch_resolve", {}, 1200)
	check(resolved.get("verdict") == "PASS", "Resolver records Tidecoil locally: " + str(resolved.get("detail", "")))
	var carried: Dictionary = await step(observer, "wait_flag", {"flag": "water_named_deep_watch_tidecoil_resolved", "scope": "world", "budget_frames": 600}, 1200)
	check(carried.get("verdict") == "PASS", "Resolution reaches the other peer's world store: " + str(carried.get("detail", "")))
	host_state = await probe(0, "deep_watch")
	check(bool(host_state.resolved), "Host world truth holds the Tidecoil resolution")
	var claimed: Dictionary = await step(1, "deep_watch_claim", {}, 1200)
	check(claimed.get("verdict") == "PASS", "Client claims the unlocked cache through host authority: " + str(claimed.get("detail", "")) + " " + str(claimed.get("data", {})))
	host_state = await probe(0, "deep_watch")
	var client_state: Dictionary = await probe(1, "deep_watch")
	check(int(host_state.receipts) == 1, "Host records exactly one durable character receipt")
	check(bool(client_state.resolved), "Client mirror holds the resolution")
	quit(await finish())
