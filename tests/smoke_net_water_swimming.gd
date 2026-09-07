extends "res://tests/helpers/net_harness.gd"

# peers: 2
## Two real peers in Water. Fixture-only realm/positions/resources and catching
## level; no key, Alpha, earned skill, saddle or chapter completion claim.
## Client traverses the authored lesson with input while host observes the
## actual replicated trainer. Then client exhausts and both stand far apart.


func _initialize() -> void:
	_run()


func _resolve_run_dir() -> String:
	if OS.get_name() == "Windows" and OS.get_environment("TB_NET_OUT_DIR").is_empty():
		return OS.get_environment("TEMP").path_join("water-net-" + _run_id.replace(":", "_").replace("/", "_"))
	return super._resolve_run_dir()


func _run() -> void:
	heartbeat_silence_tolerance_s = 60.0
	if not await launch(2, "water"):
		quit(await finish())
		return
	var boot0: Dictionary = await probe(0, "water_swimming")
	var boot1: Dictionary = await probe(1, "water_swimming")
	if not _require(str(boot0.get("current_realm", "")) == "water" and str(boot1.get("current_realm", "")) == "water",
		"both Water scene fixtures also hold the Water player realm"):
		quit(await finish())
		return
	if not _require(not str(boot0.local.user_data_dir).is_empty() and boot0.local.user_data_dir != boot1.local.user_data_dir,
		"peer user directories are isolated: %s / %s" % [boot0.local.user_data_dir, boot1.local.user_data_dir]):
		quit(await finish())
		return
	if not _pass(await step(0, "host", {}), "host Water"):
		quit(await finish())
		return
	var session: Dictionary = await probe(0, "session")
	if not _pass(await step(1, "join", {"host": "127.0.0.1", "port": int(session.enet_port)}), "client joined Water snapshot"):
		quit(await finish())
		return
	for peer in 2:
		if not _pass(await step(peer, "expect_peers", {"count": 2}), "both peers registered"):
			quit(await finish())
			return
	var client_session: Dictionary = await probe(1, "session")
	var client_id := str(int(client_session.peer_id))
	if not _pass(await step(0, "water_fixture", {"mode": "island", "island_id": "first_shore"}), "SETUP host dry First Shore"):
		quit(await finish())
		return
	if not _pass(await step(1, "water_fixture", {"mode": "lesson", "catching_level": 4}), "SETUP client lesson surface and catching level four"):
		quit(await finish())
		return
	if not _pass(await step(1, "water_lesson", {}), "client began actual lesson input"):
		quit(await finish())
		return
	var saw_mode := false
	var saw_owner := false
	var saw_resource := false
	var saw_catching := false
	var first_revision := -1
	var final_revision := -1
	var lesson := {}
	for _sample in 40:
		await step(0, "wait", {"frames": 45})
		var view: Dictionary = await probe(0, "water_swimming")
		var remote: Dictionary = view.get("remote", {}).get(client_id, {})
		var packet: Dictionary = remote.get("net_aquatic", {})
		if not packet.is_empty():
			saw_mode = saw_mode or int(packet.get("mode", -1)) == 1
			saw_owner = saw_owner or int(packet.get("owner_peer_id", -1)) == int(client_id)
			saw_resource = saw_resource or (float(packet.get("stamina_fraction", -1.0)) > 0.0 and float(packet.get("stamina_fraction", 1.0)) < 0.98)
			saw_catching = saw_catching or int(remote.get("net_catching_level", -1)) == 4
			if first_revision < 0:
				first_revision = int(packet.get("revision", -1))
			final_revision = int(packet.get("revision", -1))
		var owned: Dictionary = await probe(1, "water_swimming")
		lesson = owned.get("local", {}).get("lesson", {})
		if not bool(lesson.get("running", true)):
			break
	check(saw_mode, "host observed client HUMAN swimming mode")
	check(saw_owner, "replicated aquatic resource owner equals actual client peer ID")
	check(saw_resource, "host observed spent, nonzero swim stamina fraction")
	check(saw_catching, "host observed client catching level four")
	check(first_revision >= 0 and final_revision > first_revision, "replicated aquatic revisions advanced during movement")
	check(bool(lesson.get("completed", false)) and str(lesson.get("failure", "")).is_empty(), "real input completed lesson: %s" % lesson)
	check(float(lesson.get("distance_m", 0.0)) >= 58.0, "real swimming displacement crossed at least58m")
	if not failures.is_empty():
		quit(await finish())
		return
	var owned_before: Dictionary = await probe(1, "water_swimming")
	if not _pass(await step(1, "water_fixture", {"mode": "exhausted"}), "SETUP client zero stamina"):
		quit(await finish())
		return
	await step(0, "wait", {"frames": 120})
	var owner_after: Dictionary = await probe(1, "water_swimming")
	var host_after: Dictionary = await probe(0, "water_swimming")
	var drowning_remote: Dictionary = host_after.get("remote", {}).get(client_id, {})
	check(float(owner_after.local.health) > 0.0 and float(owner_after.local.health) < float(owned_before.local.health), "client drowning is gradual health loss")
	check(bool(drowning_remote.get("net_aquatic", {}).get("drowning", false)), "host received drowning flag")
	check(bool(drowning_remote.get("applied_aquatic", {}).get("drowning", false)), "remote presentation accepted drowning state")
	for fixture: Dictionary in [{"peer": 0, "island": "first_shore"}, {"peer": 1, "island": "salt_crown"}]:
		if not _pass(await step(fixture.peer, "water_fixture", {"mode": "island", "island_id": fixture.island}), "SETUP separated island bodies"):
			quit(await finish())
			return
	await step(0, "wait", {"frames": 120})
	var a: Dictionary = await probe(0, "water_swimming")
	var b: Dictionary = await probe(1, "water_swimming")
	check(bool(a.local.on_floor) and bool(b.local.on_floor), "both actual bodies retain floor collision on separated islands")
	check(_position(a.local.position).distance_to(_position(b.local.position)) > 1500.0, "bodies are over1.5km apart")
	check(int(a.local.aquatic.mode) == 0 and int(b.local.aquatic.mode) == 0, "both separated bodies are dry LAND mode")
	print("Water network scope: human swimming/state, catching summary, drowning and separated local collisions; no mount/reconnect/chapter claim")
	quit(await finish())


func _require(condition: bool, message: String) -> bool:
	check(condition, message)
	return condition


func _pass(result: Dictionary, message: String) -> bool:
	return _require(str(result.get("verdict", "")) == "PASS", message + ": " + str(result.get("detail", "")))


func _position(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


## The shared harness's process launcher requires /bin/sh. This local override
## preserves its coordinator, control channel, session, budgets and cleanup.
## Child PIDs are actual Godot processes; no shell or visible console wrapper.
func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	if OS.get_name() != "Windows":
		return super._spawn_peer(i, role, control_port, enet_port, scene, home, log_path, extra_args)
	var saved := {}
	for key: String in ["APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME", "TB_NET_RUN_ID", "TB_WORLD_SEED"]:
		saved[key] = OS.get_environment(key)
	for key: String in ["APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME"]:
		OS.set_environment(key, home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", log_path, "--script", "res://tools/net/peer_runner.gd", "--",
		"--role=" + role, "--peer=" + str(i), "--control-port=" + str(control_port),
		"--enet-port=" + str(enet_port), "--scene=" + scene, "TB_NET_RUN_ID=" + _run_id])
	for value: Variant in extra_args:
		args.append(str(value))
	var pid := OS.create_process(OS.get_executable_path(), args, false)
	for key: String in saved:
		OS.set_environment(key, str(saved[key]))
	return pid
