extends "res://tests/helpers/net_harness.gd"

# peers: 2
## F17#5: host and guest see the same village layout, arch states and shrine
## states after join and after reload (host production autosave + title Load;
## guest production leave/save + returning-character rejoin). Real ENet over
## loopback; no state grants or fixtures. Unattended title identity
## confirmations and the title Load continuation are disclosed. Covers the
## lawful fresh default (home open, three live arches locked, four sealed,
## eight empty shrines); mutable unlock/relic states belong to F18/F19.
## Peer side: tests/helpers/hall_agreement_net_peer.gd.
const PEER_SCRIPT := "res://tests/helpers/hall_agreement_net_peer.gd"
var _evidence: Dictionary = {"pairs": {}}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "F17 Hall agreement peer logs have no script errors")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	world_build_allowance_floor_s["hall_reload_host"] = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 600000.0
	var hello_host: Dictionary = (_peers[0] as Dictionary).get("hello", {})
	var hello_guest: Dictionary = (_peers[1] as Dictionary).get("hello", {})
	check(hello_host.get("user_data_dir", "") != hello_guest.get("user_data_dir", ""), "distinct actual host/guest user profiles")
	var port := int(hello_host.get("enet_port", 0))
	if not await _hall_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "HallHost"}, 9000): return
	if not await _hall_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": false, "character": {"appearance_id": "lyra", "display_name": "HallGuest"}}, 9000): return
	var joined := await _hall_pair("joined")
	if joined.is_empty():
		await _hall_finish()
		return
	var guest_id := str((joined.guest as Dictionary).pin.character_id)
	if not await _hall_step(1, "hall_leave_guest", {}): return
	if not await _hall_step(0, "expect_peers", {"count": 1}): return
	if not await _hall_step(0, "hall_reload_host", {"port": port}, 9000): return
	if not await _hall_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 9000): return
	var reloaded := await _hall_pair("reloaded")
	if not reloaded.is_empty():
		for side: String in ["host", "guest"]:
			var before: Dictionary = joined[side]
			var after: Dictionary = reloaded[side]
			check(before.digests == after.digests and before.arches == after.arches and before.shrines == after.shrines,
				side + " village/Hall producers persist across reload")
			check(before.pin.scene_instance != after.pin.scene_instance and before.pin.hall_instance != after.pin.hall_instance,
				side + " scene and Hall were rebuilt")
		check(joined.host.pin.world_id == reloaded.host.pin.world_id, "same host world identity after production disk Load")
		check(joined.host.pin.character_id == reloaded.host.pin.character_id, "same host character after production disk Load")
		check(guest_id == reloaded.guest.pin.character_id, "same saved guest character admitted after host reload")
		check(bool(reloaded.guest.pin.character_load_result.get("ok", false)), "production returning-guest reader loaded portable character from disk")
	await _hall_finish()


func _hall_step(peer: int, action: String, args: Dictionary, frames: int = 3000) -> bool:
	var result := await step(peer, action, args, frames)
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	if action in ["hall_reload_host", "hall_leave_guest"]:
		_evidence[action] = result
	if not passed:
		await _hall_finish()
	return passed


func _hall_pair(phase: String) -> Dictionary:
	var captures: Array = []
	# Host, guest, then each again: a peer's pin must survive the other's capture.
	for peer: int in [0, 1, 0, 1]:
		var result := await step(peer, "hall_capture", {"phase": phase}, 1800)
		check(str(result.get("verdict", "")) == "PASS", "%s peer %d independent capture: %s" % [phase, peer, result.get("detail", "")])
		if str(result.get("verdict", "")) != "PASS":
			return {}
		var data: Dictionary = result.get("data", {})
		check(data.get("peer_runtime_path", "") == PEER_SCRIPT, "peer %d runs the Hall agreement peer" % peer)
		captures.append(data)
	var host: Dictionary = captures[0]
	var guest: Dictionary = captures[1]
	check(host.pin == captures[2].pin and host.digests == captures[2].digests, phase + " host pin and producers stable across guest capture")
	check(guest.pin == captures[3].pin and guest.digests == captures[3].digests, phase + " guest pin and producers stable across host capture")
	check(bool(host.pin.hosting) and not bool(guest.pin.hosting), phase + " actual server/client roles")
	check(int(host.pin.local_peer_id) == 1 and int(guest.pin.local_peer_id) > 1, phase + " actual ENet admitted peer IDs")
	check(host.pin.character_id != guest.pin.character_id, phase + " separate admitted stable characters")
	check(host.pin.registry_rows == guest.pin.registry_rows, phase + " replicated admission/realm maps agree")
	check(host.pin.world_id == guest.pin.world_id, phase + " host-authoritative world identity agrees")
	check(host.pin.display == guest.pin.display, phase + " host-authoritative Hall display state agrees")
	check(host.counts == guest.counts and host.node_counts == guest.node_counts, phase + " village/Hall node counts agree")
	check(host.digests.village == guest.digests.village, phase + " village layout (transforms, meshes, materials, signs, colliders) agrees")
	check(host.digests.hall == guest.digests.hall, phase + " Hall structure agrees")
	check(host.arches == guest.arches, phase + " arch states, signs and membranes agree")
	check(host.shrines == guest.shrines, phase + " shrine states agree")
	_hall_defaults(host, phase + " host")
	_hall_defaults(guest, phase + " guest")
	var pair := {"host": host, "guest": guest}
	_evidence.pairs[phase] = pair
	_hall_write_evidence()
	return pair


func _hall_defaults(data: Dictionary, label: String) -> void:
	var display: Dictionary = data.pin.display
	check((display.get("portal_unlocks", []) as Array).is_empty(), label + " fresh locked portal state")
	check((display.get("shrine_display", {}) as Dictionary).is_empty(), label + " fresh empty shrine state")
	check(int(data.counts.road_houses) >= 8 and int(data.counts.road_houses) <= 10, label + " 8-10 road houses")
	check(data.arches.size() == 8 and data.shrines.size() == 8, label + " eight arches and eight pedestals")
	for arch: Dictionary in data.arches:
		var id := str(arch.id)
		var expected := "open" if id == "home" else "locked" if id in ["tidewake", "cloudreach", "stormwood"] else "sealed"
		check(arch.state == expected, label + " " + id + " arch is " + expected)
		check(arch.state_sign == ("Home arch" if id == "home" else expected.capitalize()), label + " visible state sign matches " + id)
		check(bool(arch.sign_visible) and bool(arch.state_sign_visible) and bool(arch.surface_visible), label + " signed visible membrane " + id)
		check(bool(arch.material.get("emission_enabled", false)) == (id == "home"), label + " surface emission " + id)
	for shrine: Dictionary in data.shrines:
		check(shrine.relic_displayed == false, label + " empty shrine " + str(shrine.biome))
		check(bool(shrine.visible_mesh) and bool(shrine.visible_label), label + " visible pedestal and biome sign " + str(shrine.biome))


func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://")]
	if _is_windows():
		args.append_array(["--log-file", log_path])
	args.append_array(["--script", PEER_SCRIPT, "--", "--role=" + role, "--peer=%d" % i,
		"--control-port=%d" % control_port, "--enet-port=%d" % enet_port, "--scene=" + scene,
		"TB_NET_RUN_ID=" + _run_id])
	for extra: Variant in extra_args:
		args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows():
		OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows():
		return OS.create_process(OS.get_executable_path(), args)
	var parts: Array[String] = [_shq(OS.get_executable_path())]
	for arg: Variant in args:
		parts.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])


func _hall_write_evidence() -> void:
	if _run_dir.is_empty():
		return
	_evidence["failures"] = failures.duplicate()
	var file := FileAccess.open(_run_dir.path_join("HALL_AGREEMENT.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_evidence, "\t"))
		file.close()


func _hall_finish() -> void:
	_hall_write_evidence()
	print("F17#5 real ENet join + host title Load + guest saved rejoin; fresh locked/empty Hall state only.")
	var code := await finish()
	_evidence["exit_code"] = code
	_hall_write_evidence()
	quit(code)
