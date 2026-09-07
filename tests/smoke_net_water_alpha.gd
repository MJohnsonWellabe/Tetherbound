extends "res://tests/helpers/net_harness.gd"

# peers: 2
## Host remains Meadows; client enters Water through the real realm router.
## Position/owned level49 Mosshell are explicit fixtures. No damage or result
## fixture: the host shell's real Alpha attacks the actual remote participant.

func _initialize() -> void:
	_run()

## Dedicated peer subclass adds Alpha actions without changing shared runner.
## Keep the existing harness's process ownership, isolation and run-id contract.
func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", log_path,
		"--script", "res://tests/fixtures/water_alpha_peer.gd", "--", "--role=" + role,
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
	var water_only := OS.get_cmdline_user_args().has("--water-only")
	if not await launch(2, "water" if water_only else "world"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 900000.0
	check((await step(0, "host")).get("verdict") == "PASS", "Host starts production session")
	var session: Dictionary = await probe(0, "session")
	check((await step(1, "join", {"host": "127.0.0.1", "port": session.enet_port})).get("verdict") == "PASS", "Client joins production session")
	for peer in 2:
		check((await step(peer, "expect_peers", {"count": 2})).get("verdict") == "PASS", "Both peers are connected")
	if not water_only:
		for flag in ["realm_key_water", "realm_gate_water_unlocked"]:
			check((await step(0, "story_flag", {"flag": flag, "scope": "world"})).get("verdict") == "PASS", "Host opens explicit Water entry fixture")
			check((await step(1, "wait_flag", {"flag": flag})).get("verdict") == "PASS", "Client receives Water entry fixture")
		var entered: Dictionary = await step(1, "enter_realm", {"realm": "water"}, 18000)
		check(entered.get("verdict") == "PASS", "Client enters Water through Game.enter_realm")
		if entered.get("verdict") != "PASS":
			quit(await finish())
			return
	var host: Dictionary = {}
	for attempt in 180:
		host = await probe(0, "water_alpha")
		if host.get("ready", false):
			break
		await step(0, "wait", {"frames": 30})
	check(host.get("ready", false) and (water_only or host.get("shell", false)), "Host builds actual Water Alpha authority")
	if not host.get("ready", false):
		quit(await finish())
		return
	check(host.current_realm == ("water" if water_only else "meadows") and host.authority, "Host owns Alpha while client participates independently")
	check(host.path == "/root/WaterArchipelago/WaterAlpha", "Shell Alpha has production realm path")
	check((await step(1, "water_alpha_prepare")).get("verdict") == "PASS", "Client summons owned fixture beside Alpha")
	var before: Dictionary = await probe(1, "water_alpha")
	check(not before.stone and not before.resolved, "No Stone or completion is supplied by setup")
	var engaged: Dictionary = await step(1, "water_alpha_engage")
	check(engaged.get("verdict") == "PASS", "Client's engagement is authorized by remote host: " + str(engaged))
	if engaged.get("verdict") != "PASS":
		quit(await finish())
		return
	host = await probe(0, "water_alpha")
	var client: Dictionary = await probe(1, "water_alpha")
	if water_only:
		check(vector(host.player_position).distance_to(vector(client.player_position)) > 1000.0, "Players remain on different islands during client's Alpha fight")
	check(host.record.get("participants", {}).size() == 1, "Host records only the client as participant")
	check(not host.local_fight and client.local_fight, "Host stays out of local combat while client owns its combat presentation")
	check(str(host.record.get("encounter_id", "")) == str(client.record.get("encounter_id", ""))
		and not str(client.record.get("encounter_id", "")).is_empty(), "Both processes refer to one host encounter")
	check(absf(float(host.hp) - float(client.hp)) < 0.01, "Client HP replica agrees with host Alpha")
	check(vector(host.position).distance_to(vector(client.position)) < 3.0, "Client Alpha pose follows the host simulation")
	check((await step(1, "water_alpha_forge")).get("verdict") == "PASS", "Forged outcome is sent across the actual transport")
	host = await probe(0, "water_alpha")
	client = await probe(1, "water_alpha")
	check(not host.resolved and not client.stone, "Forged catch outcome cannot resolve Alpha or grant Stone")
	check((await step(1, "water_alpha_wait_hit")).get("verdict") == "PASS", "Real host Alpha strike damages the client's owned creature")
	client = await probe(1, "water_alpha")
	check(not client.stone, "An unfinished real fight grants no premature Stone")
	check((await step(1, "leave")).get("verdict") == "PASS", "Client exits production session during the Alpha fight")
	quit(await finish())

func vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
