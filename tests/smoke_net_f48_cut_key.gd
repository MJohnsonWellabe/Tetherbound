extends "res://tests/smoke_net_f18_travel.gd"

# peers: 2
## F48#1 key-use slice: a guest's Tidewake key use cut at the owner-save edge
## (after its owner file is written, before its ACK) neither duplicates nor
## loses anything.
##
##   tools/net/run_net_smoke.sh f48_cut_key
##
## The guest holds one Tidewake key (f18_net_peer disclosed fixture) and uses
## it at the Hall arch with the ordinary prompt; its process is hard-killed at
## LedgerRpc's real "after_owner_write_before_ack" edge of that key use. A fresh
## process rejoins from disk. Afterwards: the key is spent exactly once (none
## left, none duplicated), the personal unlock and its receipt exist exactly
## once on the guest and in the host's admitted record, and the host's journal
## row for it is accepted.

func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "title", [], {1: ["--joiner"]}):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 2400.0 * 1000.0
	for peer in 2:
		if not await _f18_pass(peer, "f18_boot_world", {}, 12000): return
	if not await _f18_pass(0, "f18_fixture", {"key": false}): return
	if not await _f18_pass(1, "f18_fixture", {"guest": true}): return
	var port := int(_peers[0].hello.enet_port)
	if not await _f18_pass(0, "host", {"port": port}): return
	var guest_id := str((await _f18_observe(1)).get("character_id", ""))
	if not await _f18_pass(1, "production_join", {"port": port, "returning_route": true,
			"character": {"character_id": guest_id}}, 12000): return
	for peer in 2:
		if not await _f18_pass(peer, "expect_peers", {"count": 2}): return
	# Let the guest's admission transactions settle before it acts.
	if (await _f18_action(1, "f18_settled", {}, 3000)).is_empty(): return
	if not await _f18_pass(1, "f18_home_key", {}, 12000): return
	var before := await _f18_observe(1)
	check(before.get("tidewake_key_count") == 1 and not before.get("character", {}).get("portal_unlocks", []).has("tidewake"),
		"the guest holds one Tidewake key and no unlock")
	# The cut: the guest kills itself at its key use's owner-save edge.
	_peers[1].quit_sent = true
	var pid := int(_peers[1].pid)
	await step(1, "f18_arch", {"arch": "tidewake", "mode": "unlock", "cut": "owner_before_ack"}, 3000)
	for _f in 1800:
		await process_frame
		_pump_once()
		if not OS.is_process_running(pid): break
	check(not OS.is_process_running(pid), "the guest process ended")
	check(FileAccess.get_file_as_string(str(_peers[1].log_path)).contains("F48 KEY CUT"),
		"the guest died at the key use's real owner-save edge (after owner write, before ACK)")
	if not await _f18_restart_guest():
		quit(await finish())
		return
	# A killed process sends no disconnect: the host holds the dead guest's
	# seat (120 s) before it drops the link; the guest returns after that.
	if not await _f18_pass(0, "expect_peers", {"count": 1, "budget_frames": 12000}, 13000): return
	if not await _f18_pass(1, "production_join", {"port": port, "returning_route": true, "budget_frames": 14000,
			"pick_saved": true, "character": {"character_id": guest_id}}, 15000): return
	for peer in 2:
		if not await _f18_pass(peer, "expect_peers", {"count": 2}): return
	var settled: Dictionary = await _f18_action(1, "f18_settled", {}, 3000)
	if settled.is_empty(): return
	var after := await _f18_observe(1)
	var held := await _f18_observe(0, guest_id)
	var receipts: Array = after.get("character", {}).get("transaction_receipts", [])
	var unlock_receipts := receipts.filter(func(r: Variant) -> bool: return str(r).contains("portal") or str(r).contains("tidewake"))
	check(after.get("tidewake_key_count") == 0, "#1 key cut: the key is spent exactly once, none left (%d)" % int(after.get("tidewake_key_count", -1)))
	check(after.get("character", {}).get("portal_unlocks", []).count("tidewake") == 1, "#1 key cut: the personal unlock exists exactly once")
	check(unlock_receipts.size() >= 1 and unlock_receipts.size() == after.get("character_disk", {}).get("redesign_character", {}).get("transaction_receipts", []).filter(
			func(r: Variant) -> bool: return str(r).contains("portal") or str(r).contains("tidewake")).size(),
		"#1 key cut: the unlock receipt is saved once (%s)" % str(unlock_receipts))
	check(held.get("admitted", {}).get("redesign_character", {}).get("portal_unlocks", []).count("tidewake") == 1
		and held.get("admitted", {}).get("redesign_character", {}).get("transaction_receipts", []) == receipts,
		"the host's admitted record agrees with the guest")
	check(_f18_accepted(held, guest_id, "portal_unlock"), "the host's journal row for the key use is accepted")
	check(after.get("tidewake_view", {}).get("has_key") == false and after.get("tidewake_view", {}).get("character_open") == true,
		"the arch is open for the guest and no key remains to spend again (%s)" % str(after.get("tidewake_view")))
	print("F48_CUT_KEY: guest key use killed after owner write before ACK; rejoin settles one spend and one unlock")
	quit(await finish())
