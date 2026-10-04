extends "res://tests/helpers/net_harness.gd"

# peers: 3
## Bounded real ENet F18 witness: host A, portable guest, independent host B.
## Explicit fixtures: one starter per peer, free-play story flags, one guest
## HomeKey per peer and one guest Tidewake key, one guest staging teleport before evidence starts.
## This does NOT prove an earned opening, boss reward, rendered glow or F18#5.
## After setup: real walk/touch, Satchel Use, controller arch prompts, portable
## bool-save/ACK journals and fresh-process saved-character title entry only.
const F18_STONE_ID := "meadows_trail_camp"
var _f18_witnesses: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	# The one exemption is Godot 4.7's compat notice raised inside the Terrain3D
	# GDExtension when the Meadows terrain enters the tree; no project script
	# calls it. Any other warning or error still fails.
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call", "ERROR:", "WARNING:"],
		"F18 gameplay peer logs have no errors/warnings",
		["WARNING: instance_reset_physics_interpolation() is deprecated."])
	# Title/control hello stays lightweight. Build the same actual fixture
	# worlds sequentially before setup/admission; no simultaneous world writers.
	if not await launch(3, "title", [], {1: ["--joiner"]}):
		quit(await finish())
		return
	var homes := []
	for peer in 3:
		var hello: Dictionary = _peers[peer].hello
		check(not homes.has(hello.get("user_data_dir")), "peer %d has a distinct isolated save directory" % peer)
		homes.append(hello.get("user_data_dir"))
		if not await _f18_pass(peer, "f18_boot_world", {}, 12000): return
		if not await _f18_pass(peer, "f18_fixture", {"guest": peer == 1}): return
	var port_a := int(_peers[0].hello.enet_port)
	var port_b := int(_peers[2].hello.enet_port)
	if not await _f18_pass(0, "host", {"port": port_a}): return
	if not await _f18_pass(2, "host", {"port": port_b}): return
	var fixture := await _f18_observe(1)
	var guest_id := str(fixture.get("character_id", ""))
	check(not guest_id.is_empty(), "fixture autosave minted actual portable guest identity")
	if not await _f18_pass(1, "production_join", {"port": port_a, "returning_route": true,
			"character": {"character_id": guest_id}}, 12000): return
	for peer in [0, 1]:
		if not await _f18_pass(peer, "expect_peers", {"count": 2}): return
	var host_a := await _f18_observe(0, guest_id)
	var host_b := await _f18_observe(2)
	check(host_a.get("world_instance") != host_b.get("world_instance"), "independent host worlds have different instance identities")
	check(not host_a.get("world", {}).get("portal_unlocks", []).has("tidewake")
		and not host_b.get("world", {}).get("portal_unlocks", []).has("tidewake"), "both worlds start with Tidewake locked")
	if not await _f18_pass(1, "f18_stage", {"stone": F18_STONE_ID}): return
	var staged := await _f18_observe(1)
	check(not staged.get("character", {}).get("waystones_activated", {}).get("meadows", []).has(F18_STONE_ID),
		"staging outside touch radius did not activate the personal stone")
	var touch := await _f18_action(1, "f18_touch", {"stone": F18_STONE_ID})
	if touch.is_empty(): return
	var touched_host := await _f18_observe(0, guest_id)
	check(_f18_accepted(touched_host, guest_id, "waystone_touch", str(touch.get("touch_receipt", ""))),
		"actual guest touch has matching accepted host world journal on disk")
	check(touched_host.get("character", {}).get("last_waystones", {}).get("meadows", "")
		== host_a.get("character", {}).get("last_waystones", {}).get("meadows", ""), "guest touch keeps host personal return point")
	var guest_at_stone := await _f18_observe(1)
	if not await _f18_pass(0, "f18_home_key", {}, 12000): return
	var guest_after_host_key := await _f18_observe(1)
	check(_f18_position_same(guest_at_stone, guest_after_host_key)
		and guest_after_host_key.get("home_key_count") == 1,
		"host A own Satchel HomeKey leaves guest at its stone with its own key")
	# Host A intentionally moved itself to the Hall; this becomes its measured
	# baseline for every later guest-only move, rather than the original spawn.
	host_a = await _f18_observe(0, guest_id)
	check(host_a.get("home_key_count") == 1 and host_b.get("home_key_count") == 1,
		"each host retains its own reusable personal HomeKey")
	if not await _f18_pass(1, "f18_home_key", {}, 12000): return
	var after_key_host := await _f18_observe(0, guest_id)
	check(_f18_position_same(host_a, after_key_host) and after_key_host.get("home_key_count") == 1,
		"guest Satchel HomeKey leaves host A at its measured position/realm with its own key")
	check(_f18_accepted(after_key_host, guest_id, "portal_arrival", "", "hall_home"),
		"guest HomeKey return has accepted hall_home arrival on host disk")
	var unlocked := await _f18_action(1, "f18_arch", {"arch": "tidewake", "mode": "unlock"})
	if unlocked.is_empty(): return
	var opened_host := await _f18_observe(0, guest_id)
	var unlock_receipt := str(unlocked.get("observed_reply", {}).get("receipt", ""))
	check(_f18_accepted(opened_host, guest_id, "portal_unlock", unlock_receipt),
		"matching arch controller Use has exact accepted host world journal on disk")
	check(opened_host.get("world", {}).get("portal_unlocks", []).has("tidewake")
		and opened_host.get("world_disk", {}).get("redesign_world", {}).get("portal_unlocks", []).has("tidewake"),
		"key use opens host A world live and durably")
	check(not opened_host.get("character", {}).get("portal_unlocks", []).has("tidewake")
		and opened_host.get("admitted", {}).get("redesign_character", {}).get("portal_unlocks", []).has("tidewake"),
		"key use advances only guest portable character, not host character")
	check(_f18_position_same(host_a, opened_host) and opened_host.get("home_key_count") == 1,
		"guest portal key use keeps host A position/realm and own HomeKey")
	if not await _f18_pass(1, "save_character_here", {}): return
	var portable := await _f18_observe(1)
	check(portable.get("character_disk", {}).get("redesign_character", {}).get("transaction_receipts", []).has(unlock_receipt),
		"guest portable file contains the exact consumed-key receipt before disconnect")
	if not await _f18_pass(1, "leave", {}): return
	if not await _f18_pass(0, "expect_peers", {"count": 1}): return
	if not await _f18_restart_guest():
		quit(await finish())
		return
	var fresh := await _f18_observe(1)
	check(fresh.get("character_id") != guest_id and fresh.get("home_key_count") == 0
		and not fresh.get("character", {}).get("portal_unlocks", []).has("tidewake"),
		"fresh guest process has no in-memory fixture or learned unlock before disk picker")
	if not await _f18_pass(1, "production_join", {"port": port_b, "returning_route": true,
			"pick_saved": true, "character": {"character_id": guest_id}}, 12000): return
	for peer in [1, 2]:
		if not await _f18_pass(peer, "expect_peers", {"count": 2}): return
	var restored := await _f18_observe(1)
	var admitted_b := await _f18_observe(2, guest_id)
	check(restored.get("character_id") == guest_id and restored.get("home_key_count") == 1
		and restored.get("tidewake_key_count") == 0, "production returning title picker loads named portable key state from disk")
	check(restored.get("character", {}).get("portal_unlocks", []).has("tidewake")
		and restored.get("character", {}).get("transaction_receipts", []).has(unlock_receipt)
		and restored.get("character", {}).get("last_waystones", {}).get("meadows") == F18_STONE_ID,
		"fresh-process rejoin preserves personal unlock receipt and last touched stone")
	check(admitted_b.get("admitted", {}).get("redesign_character", {}).get("portal_unlocks", []).has("tidewake")
		and not admitted_b.get("world", {}).get("portal_unlocks", []).has("tidewake")
		and restored.get("tidewake_view", {}).get("open") == true
		and restored.get("tidewake_view", {}).get("character_open") == true
		and restored.get("tidewake_view", {}).get("world_open") == false,
		"second host admits guest personal unlock while its own world remains locked")
	# Cross-world safe spawning is production-owned; HomeKey finds the actual
	# Hall from that position, rather than staging another actor teleport.
	if not await _f18_pass(1, "f18_home_key", {}, 12000): return
	if not await _f18_pass(1, "f18_arch", {"arch": "home", "mode": "enter", "realm": "meadows", "stone": F18_STONE_ID}, 12000): return
	var return_host := await _f18_observe(2, guest_id)
	check(_f18_accepted(return_host, guest_id, "portal_arrival", "", F18_STONE_ID),
		"actual home arch returns rejoined guest to its prior personal stone, with accepted disk arrival")
	check(_f18_position_same(host_b, return_host) and return_host.get("home_key_count") == 1,
		"second host stays put with its own HomeKey during guest personal-stone return")
	if not await _f18_pass(1, "f18_home_key", {}, 12000): return
	if not await _f18_pass(1, "f18_arch", {"arch": "tidewake", "mode": "enter", "realm": "water"}, 15000): return
	var travelled_b := await _f18_observe(2, guest_id)
	check(_f18_accepted(travelled_b, guest_id, "portal_arrival", "", "water_arrival_from_stormwood"),
		"personal unlock actually permits cross-realm Tidewake entry in locked second host world")
	check(not travelled_b.get("world", {}).get("portal_unlocks", []).has("tidewake")
		and not travelled_b.get("world_disk", {}).get("redesign_world", {}).get("portal_unlocks", []).has("tidewake"),
		"portable travel never unlocks second host world live or on disk")
	check(_f18_position_same(host_b, travelled_b) and travelled_b.get("home_key_count") == 1,
		"guest Tidewake crossing leaves second host in Meadows at original position with its own key")
	print("F18_NET_FIXTURES: starter/free-play flags; one HomeKey per peer + guest Tidewake key; one pre-evidence grounded staging teleport. No earned opening/normal-loop/visual acceptance claimed.")
	var file := FileAccess.open(_run_dir.path_join("F18_WITNESSES.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(_f18_witnesses, "\t"))
	quit(await finish())

func _f18_action(peer: int, action: String, args: Dictionary, budget: int = 12000) -> Dictionary:
	var result := await step(peer, action, args, budget)
	check(result.get("verdict") == "PASS", "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	_f18_witnesses.append({"peer": peer, "action": action, "result": result})
	if result.get("verdict") != "PASS":
		quit(await finish())
		return {}
	return result.get("data", {})

func _f18_pass(peer: int, action: String, args: Dictionary, budget: int = 3000) -> bool:
	var result := await step(peer, action, args, budget)
	var ok: bool = result.get("verdict") == "PASS"
	check(ok, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	_f18_witnesses.append({"peer": peer, "action": action, "result": result})
	if not ok: quit(await finish())
	return ok

func _f18_observe(peer: int, character_id: String = "") -> Dictionary:
	var result := await step(peer, "f18_inspect", {"character_id": character_id} if not character_id.is_empty() else {})
	check(result.get("verdict") == "PASS", "peer %d read-only disk observation" % peer)
	var state: Dictionary = result.get("data", {})
	_f18_witnesses.append({"peer": peer, "action": "f18_inspect", "data": state})
	return state

func _f18_accepted(state: Dictionary, character: String, action: String, receipt: String = "", entry: String = "") -> bool:
	var deliveries: Dictionary = state.get("deliveries", {})
	var disk: Dictionary = state.get("world_disk", {}).get("reward_deliveries", {})
	for id: String in deliveries:
		var row: Variant = deliveries[id]
		if not row is Dictionary or row.get("character_id") != character or row.get("status") != "accepted": continue
		if row.get("action", row.get("kind", "")) != action: continue
		if not receipt.is_empty() and row.get("receipt") != receipt: continue
		if not entry.is_empty() and row.get("intent", {}).get("entry_id") != entry: continue
		if state.get("deliveries_disk_exact", {}).get(id) == true and disk.get(id) == row: return true
	return false

func _f18_position_same(before: Dictionary, after: Dictionary) -> bool:
	var a: Array = before.get("position", [])
	var b: Array = after.get("position", [])
	if a.size() != 3 or b.size() != 3: return false
	return before.get("realm") == after.get("realm") \
		and Vector3(float(a[0]), float(a[1]), float(a[2])).distance_to(Vector3(float(b[0]), float(b[1]), float(b[2]))) < 0.2

func _f18_restart_guest() -> bool:
	# End the actual process; never wipe/patch PlayerState to fake memory loss.
	var old: Dictionary = _peers[1]
	var old_pid := int(old.pid)
	old.quit_sent = true
	_send_to(old, {"type": "quit", "code": 0})
	var deadline := Time.get_ticks_msec() + 10000
	while OS.is_process_running(old_pid) and Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
	if OS.is_process_running(old_pid):
		OS.kill(old_pid)
		for frame in 120:
			await process_frame
			if not OS.is_process_running(old_pid): break
	if OS.is_process_running(old_pid):
		check(false, "original guest process did not stop; refuse to restart two writers on one home")
		return false
	old.exited = true
	var controls := CONTROL_PORTS.reserve(1, 0)
	if controls.get("ok") != true:
		check(false, "fresh guest control listener reservation failed")
		return false
	var server: TCPServer = controls.servers[0]
	_control_servers.append(server)
	# Separate log retains pre-restart diagnostics instead of Windows log-file
	# truncation hiding the original run from finish()'s error scan.
	var first_log := str(old.log_path)
	var first_contents := FileAccess.get_file_as_string(first_log) if FileAccess.file_exists(first_log) else ""
	for pattern: String in ["SCRIPT ERROR", "Parse Error", "Invalid call", "ERROR:", "WARNING:"]:
		check(not first_contents.contains(pattern), "pre-restart guest log has no " + pattern)
	var log_path := _run_dir.path_join("peer-1-rejoined.log")
	var pid := _spawn_peer(1, "client", int(controls.ports[0]), int(old.hello.enet_port), "title", str(old.home), log_path, ["--joiner"])
	_isolate_coordinator()
	if pid <= 0:
		check(false, "fresh guest process creation failed")
		return false
	_peers[1] = {"index": 1, "role": "client", "server": server, "sock": null, "rx_buf": "",
		"pid": pid, "home": old.home, "log_path": log_path, "control_port": int(controls.ports[0]),
		"hashes": [], "hello": null, "exited": false, "unexpected_exit": false, "quit_sent": false,
		"last_heartbeat_t": 0.0, "last_heartbeat": null, "heartbeat_deferred_until_s": 0.0,
		"last_verdict": null, "last_value": null}
	deadline = Time.get_ticks_msec() + 180000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_pump_once()
		if not _fatal_reason.is_empty(): return false
		if _peers[1].hello != null:
			check(pid != old_pid and _peers[1].hello.user_data_dir == old.hello.user_data_dir,
				"fresh process on exact original guest save directory")
			return true
	check(false, "fresh guest process failed to announce within bounded startup deadline")
	return false

func _spawn_peer(i: int, role: String, control_port: int, enet_port: int, scene: String,
		home: String, log_path: String, extra_args: Array) -> int:
	# F18 adapter launch, with an explicitly requested renderer-sampling fixture.
	var exe := OS.get_executable_path()
	var args := ["--path", ProjectSettings.globalize_path("res://")]
	if not OS.get_cmdline_user_args().has("--native-peer=%d" % i): args.push_front("--headless")
	elif OS.get_cmdline_user_args().has("--f18-draw-on-request"):
		# Native display/Compatibility resources stay live; unsampled frames are
		# skipped only in this disclosed still-frame proof, never shipping play.
		args.append_array(["--disable-render-loop", "--rendering-driver", "opengl3",
			"--audio-driver", "Dummy", "--resolution", "1280x720"])
	if _is_windows(): args.append_array(["--log-file", log_path])
	args.append_array(["--script", "res://tests/helpers/f18_net_peer.gd", "--", "--role=%s" % role,
		"--peer=%d" % i, "--control-port=%d" % control_port, "--enet-port=%d" % enet_port,
		"--scene=%s" % scene, "TB_NET_RUN_ID=%s" % _run_id])
	for extra: Variant in extra_args: args.append(str(extra))
	OS.set_environment("XDG_DATA_HOME", home)
	if _is_windows(): OS.set_environment("APPDATA", home)
	OS.set_environment("TB_NET_RUN_ID", _run_id)
	OS.set_environment("TB_WORLD_SEED", OS.get_environment("TB_NET_WORLD_SEED") if not OS.get_environment("TB_NET_WORLD_SEED").is_empty() else "0")
	if _is_windows(): return OS.create_process(exe, args)
	var parts: Array[String] = [_shq(exe)]
	for arg: Variant in args: parts.append(_shq(str(arg)))
	return OS.create_process("/bin/sh", ["-c", "exec %s >%s 2>&1" % [" ".join(parts), _shq(log_path)]])
