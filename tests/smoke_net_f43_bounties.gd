extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F43#0/#2/#3: Halda's personal bounty board across two real ENet peers.
##
##   tools/net/run_net_smoke.sh f43_bounties
##
## #0 each host morning (Game.advance_day) rotates every admitted character's
##    three bounties, drawn only from that character's unlocked biomes.
## #2 a guest's material delivery pays once; a reconnect, a hard process
##    restart and replays of the original request never pay it again.
## #3 boards are personal (distinct instances per character, a guest's claim
##    never touches the host's board) and survive the guest's save/reload.
## Disclosed fixtures: party_grant/storage_grant seed both homes before
## networking; the guest is teleported beside Halda's board; onboarding modals
## are continued with confirm. Rewards, receipts and boards come only from the
## shipping BountyHost/character_action path.
const TEMPLATE := "meadows_material_delivery"
const WOOD_STOCK := 12
const SETTLE_FRAMES := 240

var _host_id := ""
var _guest_id := ""
var _host_port := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 2400.0 * 1000.0
	if await _start_session():
		await _proof()
	quit(await finish())


func _start_session() -> bool:
	for peer in 2:
		if not await _pass(peer, "boot", {"scene": "world"}, 30000): return false
	_host_port = int(((_peers[0] as Dictionary).get("hello", {}) as Dictionary).get("enet_port", 0))
	for peer in 2:
		if not await _pass(peer, "party_grant", {"species": "bramblebun", "level": 5}): return false
		if not await _pass(peer, "storage_grant", {"item": "wood", "n": WOOD_STOCK}): return false
		var saved: Dictionary = await step(peer, "save_character_here", {})
		if not _ok(saved, "peer %d saved its seeded character" % peer): return false
		var id := str((saved.get("data", {}) as Dictionary).get("character_id", ""))
		if peer == 0: _host_id = id
		else: _guest_id = id
	if not await _pass(0, "host", {"port": _host_port}): return false
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": _host_port,
			"character": {"character_id": _guest_id, "display_name": "Bounty Guest"}}, 6000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return false
	return true


func _proof() -> void:
	# Admission issues each character's first board without a client request.
	var host_board := await _settled_host_view(_host_id)
	var guest_held := await _settled_host_view(_guest_id)
	check(int(host_board.board.get("cycle", 0)) >= 1 and int(guest_held.board.get("cycle", 0)) >= 1,
		"#0 both admitted characters received a board (cycles %s / %s)" % [str(host_board.board.get("cycle")), str(guest_held.board.get("cycle"))])
	_want_unlocked(host_board, "host first board")
	_want_unlocked(guest_held, "guest first board")
	_want_personal(host_board, guest_held, "first morning")
	# Mornings rotate every board; stop once the guest holds the delivery.
	for morning in 6:
		if (guest_held.templates as Array).has(TEMPLATE): break
		var before_host := host_board
		var before_guest := guest_held
		if not await _pass(0, "f43_morning", {"characters": [_host_id, _guest_id]}, 2400): return
		host_board = await _settled_host_view(_host_id)
		guest_held = await _settled_host_view(_guest_id)
		_want_rotated(before_host, host_board, "host morning %d" % morning)
		_want_rotated(before_guest, guest_held, "guest morning %d" % morning)
		_want_unlocked(guest_held, "guest morning %d" % morning)
		_want_personal(host_board, guest_held, "morning %d" % morning)
	var offered := (guest_held.templates as Array).has(TEMPLATE)
	check(offered, "guest board offers %s within six mornings (%s)" % [TEMPLATE, str(guest_held.templates)])
	if not offered: return
	var guest := await _guest()
	check(guest.board == guest_held.board, "guest owner record holds the same board as the host's admitted view")
	# Claim at the real board.
	var stand: Dictionary = await step(1, "f43_board_stand", {})
	if not _ok(stand, "guest resolves Halda's board"): return
	if not await _pass(1, "teleport", {"at": stand.data.at}): return
	if not await _pass(1, "f27_dismiss_modals", {}): return
	var claimed: Dictionary = await step(1, "f43_claim", {"template": TEMPLATE}, 2400)
	if not _ok(claimed, "#2 guest delivery claim settles"): return
	var instance := str(claimed.data.instance)
	var paid := await _guest()
	_want_paid_once(guest, paid, "#2 first claim")
	var host_after := await _settled_host_view(_host_id)
	check(host_after.board == host_board.board and host_after.items == host_board.items,
		"#3 a guest claim leaves the host's own board and items untouched")
	await _want_host_matches(paid, "#2 after claim")
	# Reconnect, then replay the original request.
	if not await _pass(1, "leave", {"reason": "f43_reconnect"}): return
	if not await _pass(0, "expect_peers", {"count": 1}): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	_want_same(paid, await _guest(), "#2 after reconnect")
	await _replay_unchanged(instance, paid, "#2 replay after reconnect")
	# Reload from disk in a fresh process, then replay again.
	if not await _restart_and_rejoin(): return
	var reloaded := await _guest()
	_want_same(paid, reloaded, "#3 after reload")
	check(reloaded.board == paid.board, "#3 the personal board survives reload")
	await _replay_unchanged(instance, paid, "#2 replay after reload")
	await _want_host_matches(paid, "#3 after reload")
	# The next morning replaces the paid board; its receipt stays paid.
	if not await _pass(0, "f43_morning", {"characters": [_host_id, _guest_id]}, 2400): return
	var next_guest := await _settled_host_view(_guest_id)
	_want_rotated(paid, next_guest, "morning after the claim")
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	var final := await _guest()
	check(final.board == next_guest.board, "#0 the guest owner saved the new morning's board")
	check(final.bounty_receipts == paid.bounty_receipts and final.items == paid.items,
		"#2 a new morning keeps the single paid receipt and pays nothing (%s)" % str(final.items))
	print("F43_NET_BOUNTIES: personal boards, morning rotation, pay-once across reconnect and reload")


func _want_unlocked(view: Dictionary, label: String) -> void:
	var biomes: Array = ["meadows"] + (view.get("portal_unlocks", []) as Array)
	var ok := (view.templates as Array).size() == 3
	for template: Variant in view.templates:
		if not biomes.has(str(template).get_slice("_", 0)): ok = false
	check(ok, "#0 %s: three bounties from unlocked biomes %s only (%s)" % [label, str(biomes), str(view.templates)])


func _want_personal(host_view: Dictionary, guest_view: Dictionary, label: String) -> void:
	var shared := false
	for a: Dictionary in host_view.board.get("slots", []):
		for b: Dictionary in guest_view.board.get("slots", []):
			if a.instance == b.instance: shared = true
	check(not shared, "#3 %s: host and guest boards share no bounty instance" % label)


func _want_rotated(before: Dictionary, after: Dictionary, label: String) -> void:
	var reused := false
	for a: Dictionary in before.board.get("slots", []):
		for b: Dictionary in after.board.get("slots", []):
			if a.instance == b.instance: reused = true
	check(int(after.board.get("cycle", 0)) == int(before.board.get("cycle", 0)) + 1 and not reused,
		"#0 %s: a new cycle of three fresh instances (cycle %s -> %s)" % [label, str(before.board.get("cycle")), str(after.board.get("cycle"))])


func _want_paid_once(before: Dictionary, after: Dictionary, label: String) -> void:
	check(int(before.items.wood) - int(after.items.wood) == 6, "%s: six wood delivered once (%d -> %d)" % [label, int(before.items.wood), int(after.items.wood)])
	check(int(after.items.essence_ground) - int(before.items.essence_ground) == 8 and int(after.items.stone) - int(before.items.stone) == 3,
		"%s: 8 ground essence and 3 stone paid once (%s -> %s)" % [label, str(before.items), str(after.items)])
	check((after.bounty_receipts as Array).size() == (before.bounty_receipts as Array).size() + 1,
		"%s: exactly one new bounty receipt (%s)" % [label, str(after.bounty_receipts)])


func _want_same(expected: Dictionary, actual: Dictionary, label: String) -> void:
	for key: String in ["items", "bounty_receipts", "board"]:
		check(str(actual.get(key)) == str(expected.get(key)), "%s: %s unchanged (%s vs %s)" % [label, key, str(actual.get(key)), str(expected.get(key))])


func _replay_unchanged(instance: String, expected: Dictionary, label: String) -> void:
	var replay: Dictionary = await step(1, "f43_replay", {"instance": instance}, 600)
	_ok(replay, "%s ran (%s)" % [label, str(replay.get("data", {}))])
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	_want_same(expected, await _guest(), label)
	await _want_host_matches(expected, label)


func _want_host_matches(guest: Dictionary, label: String) -> void:
	var held := await _settled_host_view(_guest_id)
	_want_same(guest, held, label + " (host admitted view)")


## The host's admitted record once no journal row for it is pending.
func _settled_host_view(character_id: String) -> Dictionary:
	var data: Dictionary = {}
	for attempt in 40:
		var view: Dictionary = await step(0, "f43_host_view", {"character_id": character_id})
		data = view.get("data", {}) as Dictionary
		if str(view.get("verdict", "")) == "PASS" and int(data.get("board", {}).get("cycle", 0)) >= 1 \
				and (data.get("row", {}) as Dictionary).get("status") != "pending":
			return data
		await step(0, "wait", {"frames": 30})
	check(false, "host view of %s settled (%s)" % [character_id, str(data.get("row", {}))])
	return data


func _guest() -> Dictionary:
	var shot: Dictionary = await step(1, "f43_view", {})
	return shot.get("data", {}) as Dictionary


## Save/reload: the guest leaves (its production save), the process is
## killed and relaunched on the title from that disk, then rejoins.
func _restart_and_rejoin() -> bool:
	if not await _pass(1, "leave", {"reason": "f43_reload"}): return false
	if not await _pass(0, "expect_peers", {"count": 1}): return false
	var restarted := await _restart_peer(1, "title")
	if not _ok(restarted, "guest process restarted (hard)"): return false
	if not await _pass(1, "f27_title_rejoin", {"host": "127.0.0.1", "port": _host_port, "budget_frames": 40000,
			"character_id": _guest_id}, 42000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	return true


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s: %s" % [label, str(result.get("detail", ""))])
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
