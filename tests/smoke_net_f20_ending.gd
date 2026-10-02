extends "res://tests/helpers/net_harness.gd"

# peers: 2
## Two real ENet processes with production worlds, UI, journal and disk.
## Each starts from a disclosed post-finale fixture; no earned combat claim.

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "world", [], {1: ["--joiner"]}): quit(await finish()); return
	var port := int(_peers[0].hello.enet_port)
	if not await _pass(0, "host", {"port": port}): return
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": port}): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
		if not await _pass(peer, "f20_return"): return
		if not await _pass(peer, "f20_fifth"): return
		if not await _pass(peer, "f20_talk"): return
		if peer == 0 and not await _pass(peer, "f20_skip"): return
		if peer == 0 and not await _pass(peer, "f20_revisit"): return
	var host := await _inspect(0)
	var guest := await _inspect(1)
	check(host.context.regional_credits_seen and not guest.context.regional_credits_seen,
		"host acknowledgement does not complete guest credits")
	check(guest.credits_open, "guest disconnect starts with actual open credits")
	var guest_id := str(guest.retained.character)
	if not await _pass(1, "drop_link", {}): return
	if not await _pass(1, "wipe_character", {}): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 6000): return
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return
	var returned := await _inspect(1)
	check(returned.retained.character == guest_id and returned.context.homecoming_seen \
		and not returned.context.regional_credits_seen, "rejoin reloads the original personal acknowledgement without crediting interrupted credits")
	if not await _pass(1, "f20_talk"): return
	if not await _pass(1, "f20_skip"): return
	if not await _pass(1, "save_reload_here", {}): return
	if not await _pass(1, "f20_revisit"): return
	var completed := await _inspect(1)
	check(completed.context.regional_credits_seen and not completed.credits_open,
		"guest credits acknowledged exactly once and remain closed after real disk reload")
	check(completed.retained.names == guest.retained.names, "disconnect/reload retains this character's actual five")
	var host_after := await _inspect(0)
	check(host_after.retained.character == host.retained.character and host_after.context.regional_credits_seen,
		"guest reconnect does not overwrite host completion")
	print("F20 TWO PEERS: post-finale fixture; production Home Key, key debit, Grandpa, credits and title rejoin; controller Skip disclosed")
	quit(await finish())

func _inspect(peer: int) -> Dictionary:
	var result := await step(peer, "f20_inspect", {}, 3000)
	check(result.get("verdict") == "PASS", "inspect real peer " + str(peer))
	return result.get("data", {})

func _pass(peer: int, action: String, args: Dictionary = {}, frames: int = 12000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed: bool = result.get("verdict") == "PASS"
	check(passed, "peer %d %s: %s" % [peer, action, result.get("detail", "")])
	if not passed: quit(await finish())
	return passed

## Use the base coordinator's isolation/control protocol with a scoped runner.
func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", log_path, "--script", "res://tests/helpers/f20_peer_runner.gd", "--",
		"--role=%s" % role, "--peer=%d" % i, "--control-port=%d" % control_port,
		"--enet-port=%d" % enet_port, "--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id]
	for extra: Variant in extra_args: args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows(): OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", "0")
	if _is_windows(): return OS.create_process(OS.get_executable_path(), args)
	var quoted: Array[String] = [_shq(OS.get_executable_path())]
	for arg: Variant in args: quoted.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(quoted), _shq(log_path)]])
