extends "res://tests/helpers/net_harness.gd"

# peers: 2 -- MANUAL until the owner-passive rejoin fix (#531) lands; run: tools/net/run_net_smoke.sh f27_essence_no_dup

## F27#4: a guest's Altar essence spend cannot duplicate, or lose its debit,
## through reconnect or reload. Two real ENet peers, the host's real paid
## Altar, the guest's shipping AltarService -> Session RPC -> host journal ->
## owner delivery/save -> ACK path.
##
##   tools/net/run_net_smoke.sh f27_essence_no_dup
##
## Cases, each judged against the guest's own record AND the host's admitted
## view of it (both are what a later admission replays from):
##   A settled:      spend settles; reconnect (leave + production_join), then a
##                   hard process restart (reload from disk) and rejoin; the
##                   original request is replayed. Nothing changes again.
##   B host cut:     LedgerRpc's real "after_host_write_before_delivery" edge on
##                   the host drops the guest link before the delivery leaves;
##                   the guest is hard-restarted and rejoins from its old disk.
##                   Admission delivers the journaled spend exactly once.
##   C owner cut:    LedgerRpc's real "after_owner_write_before_ack" edge on the
##                   guest hard-kills the guest after its owner save, before ACK.
##                   Rejoin settles the same receipt without a second level.
## Disclosed fixtures: party_grant/storage_grant seed both homes before
## networking; the Altar recipe is granted to the host; the guest is
## teleported beside the Altar; onboarding modals are continued with confirm.
##   release:        (--case=release, also in "all") the guest's belt is
##                   five host-admitted creatures; a caught result is parked
##                   on its pending seam (fixture) and the shipping Team-screen
##                   ceremony releases one: the host pays its type essence
##                   once. Releasing that untyped newcomer at once is a free,
##                   unpaid release with a reason. Reconnect and reload change
##                   nothing.
const SPECIES := "bramblebun"
const START_LEVEL := 5
const PAYMENT := "essence_ground"
const ESSENCE_STOCK := 300
const SETTLE_FRAMES := 240

var _guest_id := ""
var _host_port := 0
var _station := ""
var _altar_at := Vector3.ZERO
var _asserts := 0


func _initialize() -> void:
	_run()


func want(condition: bool, message: String) -> void:
	_asserts += 1
	check(condition, message)


func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	var selected := "all"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): selected = arg.trim_prefix("--case=")
	if not await launch(2, "title"):
		quit(await finish())
		return
	# Each case builds two worlds and restarts processes, as
	# smoke_net_cloudreach_activity_payoffs does for its long run.
	_step_phase_deadline_ms = Time.get_ticks_msec() + 7200.0 * 1000.0
	var cases: Array = ["settled", "host_before_delivery", "owner_before_ack", "release"] if selected == "all" else [selected]
	for index: int in cases.size():
		# Every case is the FIRST guest spend of a brand-new session on wiped
		# homes, so one case's leftovers cannot hide another's duplication.
		if index > 0 and not await _fresh_processes(str(cases[index])): break
		if not await _start_session(5 if str(cases[index]) == "release" else 1): break
		match str(cases[index]):
			"settled": await _case_settled()
			"reconnect_spend": await _case_reconnect_spend()
			"release": await _case_release()
			_: await _case_cut(str(cases[index]))
	print("F27_NET_NO_DUP: %d assertions over cases %s" % [_asserts, str(cases)])
	quit(await finish())


## Boot, seed (fixture), save, host, join and place the host's paid Altar.
func _start_session(guest_party: int = 1) -> bool:
	for peer in 2:
		if not await _pass(peer, "boot", {"scene": "world"}, 30000): return false
	_host_port = int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	for peer in 2:
		if not await _pass(peer, "party_grant", {"species": SPECIES, "level": START_LEVEL}): return false
	for extra in guest_party - 1:
		if not await _pass(1, "party_grant", {"species": ["terrapup", "galecrest", "bramblebun", "terrapup"][extra],
				"level": START_LEVEL + extra}): return false
	if not await _pass(1, "storage_grant", {"item": PAYMENT, "n": ESSENCE_STOCK}): return false
	for peer in 2:
		var saved: Dictionary = await step(peer, "save_character_here", {})
		if not _ok(saved, "peer %d saved its seeded character" % peer): return false
		if peer == 1: _guest_id = str((saved.get("data", {}) as Dictionary).get("character_id", ""))
	if not await _pass(0, "host", {"port": _host_port}): return false
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": _host_port,
			"character": {"character_id": _guest_id, "display_name": "Essence Guest"}}, 6000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	if not await _pass(0, "f27_dismiss_modals", {}): return false
	var placed: Dictionary = await step(0, "f27_place_altar", {})
	if not _ok(placed, "host placed a real paid Altar"): return false
	_station = str(placed.data.station_key)
	_altar_at = Vector3(placed.data.position[0], placed.data.position[1], placed.data.position[2])
	return await _pass(0, "f27_dismiss_modals", {})


## Kill both processes, wipe both homes and relaunch them on the title.
func _fresh_processes(label: String) -> bool:
	for i in 2:
		var home := str((_peers[i] as Dictionary).home)
		(_peers[i] as Dictionary)["quit_sent"] = true
		var pid := int((_peers[i] as Dictionary).get("pid", -1))
		if OS.is_process_running(pid): OS.execute("kill", ["-9", str(pid)])
		for _f in 600:
			await process_frame
			if not OS.is_process_running(pid): break
		if home.length() > 8 and DirAccess.dir_exists_absolute(home): OS.execute("rm", ["-rf", home])
		DirAccess.make_dir_recursive_absolute(home)
	for i in 2:
		var restarted := await _restart_peer(i, "title", label)
		if not _ok(restarted, "fresh process %d for case %s" % [i, label]): return false
	return true


func _case_settled() -> void:
	if not await _stand_by_altar(): return
	var before := await _guest()
	var spent: Dictionary = await step(1, "f27_altar_spend", {"station_key": _station, "payment_item": PAYMENT}, 3000)
	if not _ok(spent, "A: guest spend runs"): return
	var result: Dictionary = spent.data.result
	want(result.get("ok") == true and result.get("resolved") == true, "A: the spend settled saved (%s)" % str(result))
	var settled := await _guest()
	_want_one_level(before, settled, int(spent.data.quote_cost), "A settled")
	await _want_host_matches(settled, "accepted", "A settled")
	# Reconnect.
	if not await _pass(1, "leave", {"reason": "f27_reconnect"}): return
	if not await _pass(0, "expect_peers", {"count": 1}): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	_want_same(settled, await _guest(), "A after reconnect")
	# Reload: hard process restart, saved character picked on the title.
	if not await _restart_and_rejoin(): return
	_want_same(settled, await _guest(), "A after reload")
	await _want_host_matches(settled, "accepted", "A after reload")
	if await _stand_by_altar():
		var replay: Dictionary = await step(1, "f27_altar_replay", {"station_key": _station, "request": spent.data.request}, 2000)
		_ok(replay, "A: original request replayed")
		await step(1, "wait", {"frames": 60})
		_want_same(settled, await _guest(), "A after replaying the original request")
		await _want_host_matches(settled, "accepted", "A after replay")


## Opt-in (--case=reconnect_spend): a second spend after an ordinary
## reconnect. Liveness, not duplication; see the F27 report.
func _case_reconnect_spend() -> void:
	if not await _stand_by_altar(): return
	var spent: Dictionary = await step(1, "f27_altar_spend", {"station_key": _station, "payment_item": PAYMENT}, 3000)
	if not _ok(spent, "R: first spend runs"): return
	var settled := await _guest()
	if not await _pass(1, "leave", {"reason": "f27_reconnect"}): return
	if not await _pass(0, "expect_peers", {"count": 1}): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	# A2: a fresh spend after an ordinary reconnect settles exactly once.
	if await _stand_by_altar():
		var again: Dictionary = await step(1, "f27_altar_spend", {"station_key": _station, "payment_item": PAYMENT}, 3000)
		_ok(again, "A2: guest spend after reconnect runs")
		var second: Dictionary = again.get("data", {}).get("result", {})
		want(second.get("ok") == true and second.get("resolved") == true, "A2: the post-reconnect spend settled saved (%s)" % str(second))
		if second.get("resolved") != true: await _passive_report("A2")
		var after_second := await _guest()
		_want_one_level(settled, after_second, E_cost(settled), "A2 after reconnect")
		await _want_host_matches(after_second, "accepted", "A2 after reconnect")
		settled = after_second


func _case_cut(cut: String) -> void:
	var label := "B host cut" if cut == "host_before_delivery" else "C owner cut"
	if not await _stand_by_altar(): return
	var before := await _guest()
	if cut == "host_before_delivery":
		if not await _pass(0, "f27_arm_host_cut", {"character_id": _guest_id}): return
	else:
		(_peers[1] as Dictionary)["quit_sent"] = true # The guest kills itself at the edge.
	var spent: Dictionary = await step(1, "f27_altar_spend",
		{"station_key": _station, "payment_item": PAYMENT, "cut": cut}, 3000)
	var request: Dictionary = (spent.get("data", {}) as Dictionary).get("request", {})
	var cost := int((spent.get("data", {}) as Dictionary).get("quote_cost", -1))
	if cut == "host_before_delivery":
		want(str(spent.get("verdict", "")) == "PASS" and spent.data.get("active") == false,
			"%s: the guest link dropped mid-spend (%s)" % [label, str(spent.get("detail", ""))])
		var view := await _host(_guest_id)
		if (view.get("cut", {}) as Dictionary).is_empty(): await _passive_report(label + " before cut")
		want(not (view.get("cut", {}) as Dictionary).is_empty(), "%s: the host edge fired (%s)" % [label, str(view.get("cut"))])
		want((view.get("row", {}) as Dictionary).get("status") == "pending",
			"%s: the host journaled the spend and holds it pending, unACKed (%s)" % [label, str(view.get("row"))])
		cost = E_cost(before)
	else:
		want(str(spent.get("verdict", "")) == "ERROR", "%s: the guest died at its owner save edge (%s)" % [label, str(spent.get("detail", ""))])
		var view := await _host(_guest_id)
		want((view.get("row", {}) as Dictionary).get("status") == "pending",
			"%s: the host row is still pending without the ACK (%s)" % [label, str(view.get("row"))])
		cost = E_cost(before)
	if not await _restart_and_rejoin(): return
	var recovered := await _guest()
	if int(recovered.party[0].level) != int(before.party[0].level) + 1: await _passive_report(label)
	_want_one_level(before, recovered, cost, label + " after reload")
	await _want_host_matches(recovered, "accepted", label + " after reload")
	if not request.is_empty() and await _stand_by_altar():
		var replay: Dictionary = await step(1, "f27_altar_replay", {"station_key": _station, "request": request}, 2000)
		_ok(replay, label + ": original request replayed")
		await step(1, "wait", {"frames": 60})
		_want_same(recovered, await _guest(), label + " after replaying the original request")


func _case_release() -> void:
	if not await _pass(1, "f27_dismiss_modals", {}): return
	var before := await _guest()
	var hosted := await _host(_guest_id)
	var paid: Dictionary = await step(1, "f27_ceremony_release", {"index": 0, "nickname": "Kept Newcomer"}, 6000)
	if paid.get("verdict") == "PASS" and paid.data.stage != "done":
		print("R diag: %s" % str(paid.data))
		await _passive_report("R")
	if not _ok(paid, "R: guest ceremony release runs"): return
	var released := str(paid.data.released_uid)
	var payout: Array = paid.data.payout
	want(paid.data.stage == "done" and not paid.data.pending_left, "R: the ceremony finished (%s)" % str(paid.data))
	want(not payout.is_empty() and str(paid.data.unpaid_reason).is_empty(), "R: the host-admitted creature quotes a payout (%s)" % str(paid.data))
	var after := await _guest()
	for stack: Dictionary in payout:
		want(int(after.items[stack.id]) - int(before.items[stack.id]) == int(stack.n),
			"R: exactly %d %s paid once (%d -> %d)" % [int(stack.n), stack.id, int(before.items[stack.id]), int(after.items[stack.id])])
	want((after.release_receipts as Array).count("release:" + released) == 1 and (after.release_receipts as Array).size() == (before.release_receipts as Array).size() + 1,
		"R: exactly one new release receipt (%s)" % str(after.release_receipts))
	want(not (paid.data.owned as Array).has(released) and (paid.data.owned as Array).has(paid.data.newcomer_uid) and (paid.data.owned as Array).size() == 5,
		"R: the released creature left and the newcomer took its holder (%s)" % str(paid.data.owned))
	var view := await _host(_guest_id)
	for i in 20:
		if (view.get("row", {}) as Dictionary).get("status") == "accepted": break
		await step(0, "wait", {"frames": 30})
		view = await _host(_guest_id)
	want((view.get("row", {}) as Dictionary).get("action") == "essence_release" and (view.get("row", {}) as Dictionary).get("status") == "accepted",
		"R: host row is the accepted essence_release (%s)" % str(view.get("row")))
	want(str(view.get("items")) == str(after.items) and str(view.get("release_receipts")) == str(after.release_receipts),
		"R: host admitted items/receipts equal the guest's (%s / %s)" % [str(view.get("items")), str(view.get("release_receipts"))])
	want(not str(view.get("party")).contains(released) and (view.get("party", []) as Array).size() == (hosted.get("party", []) as Array).size() - 1,
		"R: host admitted party lost exactly the released creature (%s)" % str(view.get("party")))
	# The newcomer is the guest's own untyped catch: releasing it pays nothing,
	# says why, and still lets it go.
	if not await _pass(1, "f27_dismiss_modals", {}): return
	var unpaid: Dictionary = await step(1, "f27_ceremony_release", {"index": 4, "nickname": "Second Newcomer"}, 6000)
	if not _ok(unpaid, "R2: guest releases its unadmitted newcomer"): return
	want(unpaid.data.released_uid == paid.data.newcomer_uid, "R2: released the first newcomer (%s)" % str(unpaid.data.released_uid))
	want(unpaid.data.stage == "done" and not unpaid.data.pending_left and not (unpaid.data.owned as Array).has(unpaid.data.released_uid),
		"R2: the release still happened (%s)" % str(unpaid.data))
	want((unpaid.data.payout as Array).is_empty() and not str(unpaid.data.unpaid_reason).is_empty(),
		"R2: no payout, with a readable reason (%s)" % str(unpaid.data.unpaid_reason))
	var settled := await _guest()
	want(str(settled.items) == str(after.items) and str(settled.release_receipts) == str(after.release_receipts),
		"R2: items and release receipts unchanged (%s)" % str(settled.items))
	if not await _pass(1, "f27_dismiss_modals", {}): return
	if not await _pass(1, "save_character_here", {}): return
	settled = await _guest()
	# Reconnect, then a hard reload: nothing is paid or released again.
	if not await _pass(1, "leave", {"reason": "f27_reconnect"}): return
	if not await _pass(0, "expect_peers", {"count": 1}): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	_want_same(settled, await _guest(), "R after reconnect")
	if not await _restart_and_rejoin(): return
	_want_same(settled, await _guest(), "R after reload")
	var final_view := await _host(_guest_id)
	want((final_view.get("release_receipts", []) as Array).count("release:" + released) == 1 and str(final_view.get("items")) == str(settled.items),
		"R after reload: host holds one receipt and the same items (%s)" % str(final_view.get("items")))


## Expected price from the guest's actual level, independent of the steps.
func E_cost(before: Dictionary) -> int:
	var essence := preload("res://scripts/creatures/essence.gd")
	return essence.level_cost(int(before.party[0].level), essence.config(),
		preload("res://scripts/creatures/progression.gd").config())


func _passive_report(label: String) -> void:
	for peer in 2:
		var state: Dictionary = await step(peer, "f27_passive_state", {"character_id": _guest_id})
		print("%s passive peer %d: %s" % [label, peer, str(state.get("data", {}))])


func _want_one_level(before: Dictionary, after: Dictionary, cost: int, label: String) -> void:
	want(cost > 0, "%s: a positive price (%d)" % [label, cost])
	want(int(after.party[0].level) == int(before.party[0].level) + 1,
		"%s: exactly one level (L%d -> L%d)" % [label, int(before.party[0].level), int(after.party[0].level)])
	want(int(before.items[PAYMENT]) - int(after.items[PAYMENT]) == cost,
		"%s: exactly one debit of %d %s (%d -> %d)" % [label, cost, PAYMENT, int(before.items[PAYMENT]), int(after.items[PAYMENT])])
	want((after.spend_receipts as Array).size() == (before.spend_receipts as Array).size() + 1,
		"%s: exactly one new spend receipt (%s)" % [label, str(after.spend_receipts)])


func _want_same(expected: Dictionary, actual: Dictionary, label: String) -> void:
	for key: String in ["party", "items", "spend_receipts", "release_receipts"]:
		want(str(actual.get(key)) == str(expected.get(key)), "%s: %s unchanged (%s vs %s)" % [label, key, str(actual.get(key)), str(expected.get(key))])


func _want_host_matches(guest: Dictionary, status: String, label: String) -> void:
	var view := await _host(_guest_id)
	for i in 20:
		if (view.get("row", {}) as Dictionary).get("status") == status: break
		await step(0, "wait", {"frames": 30})
		view = await _host(_guest_id)
	want((view.get("row", {}) as Dictionary).get("status") == status, "%s: host training row %s (%s)" % [label, status, str(view.get("row"))])
	for key: String in ["party", "items", "spend_receipts"]:
		want(str(view.get(key)) == str(guest.get(key)), "%s: host admitted %s equals the guest's (%s vs %s)" % [label, key, str(view.get(key)), str(guest.get(key))])


func _stand_by_altar() -> bool:
	if not await _pass(1, "f27_dismiss_modals", {}): return false
	var stand := _altar_at + Vector3(1.8, 1.0, 0.0)
	return await _pass(1, "teleport", {"at": [stand.x, stand.y, stand.z]})


func _guest() -> Dictionary:
	var shot: Dictionary = await step(1, "f27_snapshot", {})
	return shot.get("data", {}) as Dictionary


func _host(character_id: String) -> Dictionary:
	var view: Dictionary = await step(0, "f27_host_view", {"character_id": character_id})
	return view.get("data", {}) as Dictionary


func _restart_and_rejoin() -> bool:
	var restarted := await _restart_peer(1, "title")
	if not _ok(restarted, "guest process restarted (hard)"): return false
	# A killed process sends no disconnect: the host first refuses the same
	# character (`character_in_use`), then holds its seat for the returning
	# character. f27_title_rejoin retries Join as a player would.
	if not await _pass(1, "f27_title_rejoin", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 20000,
			"character_id": _guest_id}, 22000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	return true


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	want(passed, "%s: %s" % [label, str(result.get("detail", ""))])
	return passed


func _pass(peer: int, action: String, args: Dictionary, budget: int = -1) -> bool:
	return _ok(await step(peer, action, args, budget), "peer %d %s" % [peer, action])


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
