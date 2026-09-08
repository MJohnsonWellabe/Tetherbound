extends "res://tests/helpers/net_harness.gd"

# peers: 2
## The host resolves the shared world before a fresh character connects. The
## joiner then uses production Iona dialogue; only the host-observed Water realm,
## stable identity and trainer transform can create its personal entitlement.

func _initialize() -> void:
	_run()

func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", log_path, "--script", "res://tests/fixtures/water_alpha_peer.gd", "--",
		"--role=" + role, "--peer=%d" % i, "--control-port=%d" % control_port,
		"--enet-port=%d" % enet_port, "--scene=" + scene, "TB_NET_RUN_ID=" + _run_id]
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
	check((await step(0, "host")).get("verdict") == "PASS", "Host starts production Water session")
	check((await step(0, "water_alpha_attune_world_fixture")).get("verdict") == "PASS",
		"Host supplies an explicit named world for the durable reward journal")
	check((await step(0, "story_flag", {"flag": "water_aquaryn_resolved", "scope": "world"})).get("verdict") == "PASS",
		"Host supplies only the already-resolved shared Alpha world fixture")
	var session: Dictionary = await probe(0, "session")
	check((await step(1, "join", {"host": "127.0.0.1", "port": session.enet_port})).get("verdict") == "PASS",
		"Fresh character joins after shared victory")
	for peer in 2:
		check((await step(peer, "expect_peers", {"count": 2})).get("verdict") == "PASS", "Both peers are connected")
	var before: Dictionary = await probe(1, "water_alpha")
	check(before.get("ready", false) and before.get("resolved", false), "Joiner reconstructs the resolved one-time Alpha")
	check(not before.get("stone", true) and not before.get("entitled", true), "Fresh late joiner begins without a Swim Stone entitlement")
	var forged: Dictionary = await step(1, "water_alpha_attune_request")
	check(forged.get("verdict") == "PASS" and str(forged.get("data", {}).get("host_verdict", {}).get("code", "")) == "not_near_iona",
		"Client request cannot mint a Stone away from host-observed Iona proximity: " + str(forged))
	before = await probe(1, "water_alpha")
	check(not before.get("stone", true) and not before.get("entitled", true), "Rejected remote intent changes neither personal nor world entitlement")
	check((await step(1, "water_alpha_attune_prepare")).get("verdict") == "PASS", "Joiner reaches production Iona")
	var talk: Dictionary = await step(1, "water_alpha_attune_talk")
	check(talk.get("verdict") == "PASS", "Normal Iona dialogue earns the missing personal Stone: " + str(talk))
	var client: Dictionary = await probe(1, "water_alpha")
	var host: Dictionary = await probe(0, "water_alpha", {"character_id": str(client.get("character_id", ""))})
	check(client.get("stone", false) and client.get("entitled", false), "Joiner receives both ride flag and durable character entitlement")
	check(host.get("resolved", false) and host.get("entitled", false), "Host world records the same stable-character entitlement")
	check(int(host.get("entitlement_count", 0)) == 1 and int(client.get("entitlement_count", 0)) == 1,
		"The durable character entitlement exists exactly once on both peers")
	check(int(host.get("capture_claims", -1)) == 0 and int(client.get("capture_claims", -1)) == 0,
		"Late attunement cannot claim or duplicate Aquaryn")
	check((await step(1, "water_alpha_attune_repeat")).get("verdict") == "PASS", "Existing recipient cannot replay Iona attunement")
	var duplicate: Dictionary = await step(1, "water_alpha_attune_request")
	check(duplicate.get("verdict") == "PASS" and str(duplicate.get("data", {}).get("host_verdict", {}).get("code", "")) == "already_attuned",
		"A direct duplicate request reaches only idempotent recovery, never a second entitlement")
	check((await step(1, "water_alpha_resolved_engage")).get("verdict") == "PASS", "Shared Aquaryn encounter remains non-repeatable")
	client = await probe(1, "water_alpha")
	check(client.get("stone", false) and client.get("entitled", false)
		and int(client.get("entitlement_count", 0)) == 1, "Duplicate attempts leave exactly the same personal entitlement")
	print("Water late-join Swim Stone evidence: failures=", failures.size(),
		" character=", str(client.get("character_id", "")))
	quit(await finish())
