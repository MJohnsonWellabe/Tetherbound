extends "res://tests/smoke_net_homestead_station_craft.gd"

# peers: 2
## F48#1 craft slice: a guest's station craft cut at the owner-save edge
## (after its owner file is written, before its ACK) neither duplicates nor
## loses anything.
##
##   tools/net/run_net_smoke.sh f48_cut_craft
##
## Same setup as smoke_net_homestead_station_craft (its disclosed fixtures):
## the host plants a Kitchen with its Spice rack, the guest gathers its own
## ingredients through the host's ledger, then crafts a Small Potion there.
## Here the guest process is hard-killed at LedgerRpc's real
## "after_owner_write_before_ack" edge of that craft; the host's row stays
## pending; a fresh guest process rejoins from disk. Afterwards the guest holds
## exactly one more potion and exactly one recipe's debit, the host's record
## agrees, and the host's own stock never moved.

func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "craft cut peer logs have no script errors")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	if not await launch(2, "title", [], {1: ["--scene=world"]}):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 1200000.0
	var port := int((_peers[0] as Dictionary).get("hello", {}).get("enet_port", 0))
	if not await _craft_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "CraftHost"}, 9000): return
	if not await _craft_step(1, "party_grant", {"species": "terrapup"}): return
	if not await _craft_step(1, "seed_opening_complete", {}): return
	var seeded := await _craft_data(1, "save_character_here", {})
	if seeded.is_empty():
		await _craft_finish()
		return
	var guest_id := str(seeded.character_id)
	if not await _craft_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 9000): return
	for node_id: String in ["f31_berry_a", "f31_berry_b"]:
		if not await _craft_step(0, "gather_node_stand", {"id": node_id, "item": "berries", "amount": 2}): return
		if not await _craft_step(1, "gather_node_stand", {"id": node_id, "item": "berries", "amount": 2}): return
		if not await _craft_step(1, "gather_node_take", {"id": node_id}): return
	await step(1, "wait", {"frames": 240})
	if not await _craft_step(0, "pickup_stand", {"id": "f31_craft_fiber", "item": "fiber", "realm": "meadows", "count": 1}): return
	if not await _craft_step(1, "pickup_stand", {"id": "f31_craft_fiber", "item": "fiber", "realm": "meadows", "count": 1}): return
	if not await _craft_step(1, "pickup_take", {}): return
	await step(1, "wait", {"frames": 180})
	var placed := await _craft_data(0, "craft_place_kitchen", {}, 3000)
	if placed.is_empty():
		await _craft_finish()
		return
	await _craft_data(1, "craft_home_key_trip", {}, 12000)
	var before := await _craft_data(1, "craft_count", {"ids": COUNTED})
	var host_before := await _craft_data(0, "craft_count", {"ids": COUNTED})
	if before.is_empty() or host_before.is_empty():
		await _craft_finish()
		return
	# The cut: the guest kills itself at the owner-save edge of the craft.
	(_peers[1] as Dictionary)["quit_sent"] = true
	var pid := int((_peers[1] as Dictionary).get("pid", -1))
	await step(1, "craft_at_host_kitchen", {"kitchen_uid": placed.kitchen_uid, "cut": "owner_before_ack"}, 3000)
	for _f in 1800:
		await process_frame
		_pump_once()
		if not OS.is_process_running(pid): break
	check(not OS.is_process_running(pid), "the guest process ended")
	var cut_log := FileAccess.get_file_as_string(str((_peers[1] as Dictionary).get("log_path", "")))
	check(cut_log.contains("F48 CRAFT CUT"), "the guest died at the craft's real owner-save edge (after owner write, before ACK)")
	var restarted := await _restart_peer(1, "title", "after_cut")
	if not _cut_ok(restarted, "guest relaunched from its own disk"):
		await _craft_finish()
		return
	if not await _craft_step(1, "f27_title_rejoin", {"host": "127.0.0.1", "port": port, "budget_frames": 40000,
			"character_id": guest_id}, 42000): return
	for peer in 2:
		if not await _craft_step(peer, "expect_peers", {"count": 2}): return
	var back: Dictionary = {}
	for _poll in 30:
		back = await _craft_data(1, "craft_count", {"ids": COUNTED})
		var held := await _craft_data(0, "craft_authority_count", {"character_id": guest_id, "ids": COUNTED})
		if not back.is_empty() and held.get("counts", {}) == back.get("counts", {}) and int(back.counts.potion_small) == int(before.counts.potion_small) + 1: break
		await step(1, "wait", {"frames": 60})
	if back.is_empty():
		await _craft_finish()
		return
	check(str(back.character_id) == guest_id, "the same saved guest rejoined")
	check(int(back.counts.potion_small) == int(before.counts.potion_small) + 1, "#1 craft cut: exactly one potion, never two or none (%s)" % str(back.counts))
	check(int(back.counts.berries) == int(before.counts.berries) - 4 and int(back.counts.fiber) == int(before.counts.fiber) - 1,
		"#1 craft cut: exactly one recipe's debit (%s -> %s)" % [str(before.counts), str(back.counts)])
	var held_back := await _craft_data(0, "craft_authority_count", {"character_id": guest_id, "ids": COUNTED})
	check(held_back.get("counts", {}) == back.counts, "the host's authority record agrees with the guest (%s)" % str(held_back.get("counts")))
	var host_after := await _craft_data(0, "craft_count", {"ids": COUNTED})
	check(host_after.get("counts", {}) == host_before.counts, "the host's own stock never moved")
	print("F48_CUT_CRAFT: guest craft killed after owner write before ACK; rejoin settles exactly one potion and one debit")
	quit(await finish())


func _cut_ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s: %s" % [label, str(result.get("detail", ""))])
	return passed


## Hard restart of one guest process on its own home (no Session.leave, no
## autosave). Mirrors smoke_net_proof_two_peer._restart_peer, with a kill.
func _restart_peer(i: int, scene: String, label: String = "") -> Dictionary:
	var old: Dictionary = _peers[i]
	var old_pid := int(old.get("pid", -1))
	old["quit_sent"] = true
	if OS.is_process_running(old_pid):
		OS.execute("kill", ["-9", str(old_pid)])
	for _f in 600:
		await process_frame
		if not OS.is_process_running(old_pid): break
	old["exited"] = true
	var controls := CONTROL_PORTS.reserve(1, 0)
	if not bool(controls.ok):
		return {"verdict": "ERROR", "detail": "could not reserve a control port: %s" % str(controls.reason)}
	var server: TCPServer = controls.servers[0]
	_control_servers.append(server)
	var enet_port := int((old.get("hello", {}) as Dictionary).get("enet_port", enet_port_for(i))) \
		if old.get("hello") is Dictionary else enet_port_for(i)
	var log_path := str(old.log_path) if label.is_empty() else str(old.log_path).get_basename() + "-" + label + ".log"
	var pid := _spawn_peer(i, str(old.role), int(controls.ports[0]), enet_port, scene,
		str(old.home), log_path, [])
	_isolate_coordinator()
	if pid <= 0:
		return {"verdict": "ERROR", "detail": "OS.create_process failed relaunching peer %d" % i}
	var now_s := Time.get_ticks_msec() / 1000.0
	_peers[i] = {
		"index": i, "role": old.role, "server": server, "sock": null, "rx_buf": "",
		"pid": pid, "home": old.home, "log_path": log_path, "control_port": int(controls.ports[0]),
		"hashes": [], "hello": null, "exited": false, "unexpected_exit": false,
		"quit_sent": false, "last_heartbeat_t": 0.0, "last_heartbeat": null,
		"heartbeat_deferred_until_s": now_s + 300.0, # Fresh process boots a world.
		"last_verdict": null, "last_value": null,
	}
	var hello_deadline := Time.get_ticks_msec() + float(_budgets.get("hello_budget_s", DEFAULT_HELLO_BUDGET_S)) * 1000.0
	while Time.get_ticks_msec() < hello_deadline:
		await process_frame
		_pump_once()
		if not _fatal_reason.is_empty():
			return {"verdict": "ERROR", "detail": "restart aborted: %s" % _fatal_reason}
		if (_peers[i] as Dictionary).get("hello") != null:
			return {"verdict": "PASS", "detail": "peer %d pid %d killed; fresh pid %d said hello" % [i, old_pid, pid]}
	return {"verdict": "FAIL", "detail": "restarted peer %d (pid %d) never said hello" % [i, pid]}
