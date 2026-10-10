extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F28#2/#4: Orin Stonewake (master_t1) across two real ENet peers.
##
##   tools/net/run_net_smoke.sh f28_masters
##
## #2 each Master fight is a 1v1 with the creature the player chose; a loss
##    teaches nothing and the Master can be challenged again; a win opens the
##    chest, which teaches that tier's Ascension Feast once per character.
## #4 host and guest each earn their own recipe; opening the chest again, a
##    reconnect and a reload never grant it twice.
## Disclosed fixtures: party_grant seeds both homes before networking (a weak
## creature for the guest's deliberate loss, a strong one to win); trainers
## are teleported beside the Master/chest; onboarding modals are continued
## with confirm. Swings come from peer_runner's win_trainer_battle (real
## host-arbitrated strike intents); a loss is the Master's own fight.
const MASTER := "master_t1"
const WINNER := "terrapup"
const LOSER := "bramblebun"
const SETTLE_FRAMES := 240

var _host_id := ""
var _guest_id := ""
var _port := 0
var _npc := Vector3.ZERO
var _chest_at := Vector3.ZERO


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	if not await launch(2, "title"):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 2400.0 * 1000.0
	if await _start():
		await _proof()
	quit(await finish())


func _start() -> bool:
	for peer in 2:
		if not await _pass(peer, "boot", {"scene": "world"}, 30000): return false
	if not await _pass(0, "party_grant", {"species": WINNER, "level": 40}): return false
	if not await _pass(1, "party_grant", {"species": LOSER, "level": 2}): return false
	if not await _pass(1, "party_grant", {"species": WINNER, "level": 40}): return false
	for peer in 2:
		var saved: Dictionary = await step(peer, "save_character_here", {})
		if not _ok(saved, "peer %d saved its seeded character" % peer): return false
		if peer == 0: _host_id = str((saved.get("data", {}) as Dictionary).get("character_id", ""))
		else: _guest_id = str((saved.get("data", {}) as Dictionary).get("character_id", ""))
	if not await _pass(0, "host", {}): return false
	_port = int(((await probe(0, "session")) as Dictionary).get("enet_port", 0))
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": _port,
			"character": {"character_id": _guest_id, "display_name": "Master Guest"}}, 6000): return false
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return false
	for peer in 2:
		if not await _pass(peer, "f27_dismiss_modals", {}): return false
	return true


func _proof() -> void:
	# The site mounts once a trainer is in Meadows near it.
	var definition: Dictionary = preload("res://scripts/creatures/breakthrough.gd").master(MASTER)
	var at: Array = definition.position
	for peer in 2:
		if not await _pass(peer, "f28_stand", {"at": [float(at[0]) + 6.0, float(at[2]) + 6.0], "settle": 90}): return
	var site: Dictionary = {}
	for attempt in 30:
		site = await step(0, "f28_site", {"master_id": MASTER})
		if str(site.get("verdict", "")) == "PASS": break
		await step(0, "wait", {"frames": 30})
	if not _ok(site, "host mounted %s" % MASTER): return
	_npc = _vec(site.data.master)
	_chest_at = _vec(site.data.chest)
	var host_before := await _view(0, "")
	var guest_before := await _view(1, "")
	# Guest loss: its weak creature, chosen deliberately. Nothing is taught.
	if not await _stand(1, _npc): return
	if not await _pass(1, "f28_challenge", {"master_id": MASTER, "species": LOSER}, 2400): return
	if not await _pass(1, "f28_await_fight_end", {"budget_frames": 7200}, 7600): return
	var lost := await _view(1, "")
	check(lost.master_wins == guest_before.master_wins and int(lost.has_feast) == 0,
		"#2 a loss records no win and teaches nothing (%s)" % str(lost.master_wins))
	await _chest(1, "#2 chest after a loss")
	check(int((await _view(1, "")).has_feast) == 0, "#2 the chest stays shut after a loss")
	# Host win with its chosen creature.
	if not await _stand(0, _npc): return
	if not await _pass(0, "f28_challenge", {"master_id": MASTER, "species": WINNER}, 2400): return
	if not await _pass(0, "win_trainer_battle", {"budget_frames": 6000}, 6400): return
	await step(0, "wait", {"frames": SETTLE_FRAMES})
	# Guest retry with its strong creature, and win.
	if not await _stand(1, _npc): return
	if not await _pass(1, "f28_challenge", {"master_id": MASTER, "species": WINNER}, 2400): return
	if not await _pass(1, "win_trainer_battle", {"budget_frames": 6000, "fixture_guest_master": true}, 6400): return
	var settle_polls := 0
	for poll in 60:
		if ((await _view(1, "")).master_wins as Array).has(MASTER): break
		settle_polls += 1
		if poll % 10 == 9: print("F28 guest win still settling after %d polls; input owner %s; host duels %s" % [poll + 1, str((await probe(1, "input_context"))), str((await step(0, "f28_host_duels", {})).get("data", {}))])
		await step(1, "wait", {"frames": 60})
	print("F28 guest win settled after %d polls of 60 frames" % settle_polls)
	for peer in 2:
		var won := await _view(peer, "")
		check((won.master_wins as Array).count(MASTER) == 1, "#2 peer %d holds exactly one %s win (%s)" % [peer, MASTER, str(won.master_wins)])
	# Each opens the chest: their own recipe, once.
	await _chest(0, "host chest")
	await _chest(1, "guest chest")
	var host_paid := await _view(0, "")
	var guest_paid := await _view(1, "")
	for pair: Array in [[host_before, host_paid, "host"], [guest_before, guest_paid, "guest"]]:
		check(int(pair[1].has_feast) == 1, "#4 the %s learned %s's feast exactly once (%s)" % [pair[2], MASTER, str(pair[1].feast_recipes)])
		check(int(pair[1].candy) > int(pair[0].candy), "#2 the %s's chest paid its Tether Candy (%d -> %d)" % [pair[2], int(pair[0].candy), int(pair[1].candy)])
	await _want_host_matches(guest_paid, "#4 host admitted guest after chest")
	# Second opens, reconnect and reload never regrant.
	await _chest(0, "host second chest")
	await _chest(1, "guest second chest")
	_want_same(host_paid, await _view(0, ""), "#4 host after a second chest")
	_want_same(guest_paid, await _view(1, ""), "#4 guest after a second chest")
	if not await _pass(1, "leave", {"reason": "f28_reconnect"}): return
	if not await _pass(0, "expect_peers", {"count": 1}): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return
	await step(1, "wait", {"frames": SETTLE_FRAMES})
	_want_same(guest_paid, await _view(1, ""), "#4 guest after reconnect")
	if not await _pass(1, "save_reload_here", {}, 8000): return
	_want_same(guest_paid, await _view(1, ""), "#4 guest after reload")
	await _chest(1, "guest chest after reload")
	_want_same(guest_paid, await _view(1, ""), "#4 guest after a chest replay post-reload")
	await _want_host_matches(guest_paid, "#4 host admitted guest at the end")
	print("F28_NET_MASTERS: chosen-creature loss then retry win, one recipe per character, no regrant")


func _stand(peer: int, at: Vector3) -> bool:
	if not await _pass(peer, "f27_dismiss_modals", {}): return false
	return await _pass(peer, "f28_stand", {"at": [at.x + 2.0, at.z + 1.0]})


func _chest(peer: int, label: String) -> void:
	if not await _stand(peer, _chest_at): return
	var opened: Dictionary = await step(peer, "f28_chest", {"master_id": MASTER}, 1200)
	_ok(opened, "%s ran (%s)" % [label, str(opened.get("data", {}))])
	# A press refused for a revision that moved under it is pressed again.
	var answers: Array = opened.get("data", {}).get("completed", []) + opened.get("data", {}).get("answers", [])
	for answer: Variant in answers:
		if answer is Dictionary and answer.get("code") == "source_or_revision_changed":
			await step(peer, "wait", {"frames": 120})
			var again: Dictionary = await step(peer, "f28_chest", {"master_id": MASTER}, 1200)
			print("%s pressed again after a revision change: %s" % [label, str(again.get("data", {}))])
			break
	await step(peer, "wait", {"frames": SETTLE_FRAMES})


func _want_same(expected: Dictionary, actual: Dictionary, label: String) -> void:
	for key: String in ["master_wins", "feast_recipes", "recipe_receipts", "candy"]:
		check(str(actual.get(key)) == str(expected.get(key)), "%s: %s unchanged (%s vs %s)" % [label, key, str(actual.get(key)), str(expected.get(key))])


func _want_host_matches(guest: Dictionary, label: String) -> void:
	_want_same(guest, await _view(0, _guest_id), label)


func _view(peer: int, character_id: String) -> Dictionary:
	return ((await step(peer, "f28_view", {"character_id": character_id, "master_id": MASTER})).get("data", {}) as Dictionary)


func _vec(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() != 3: return Vector3.INF
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _ok(result: Dictionary, label: String) -> bool:
	var passed := str(result.get("verdict", "")) == "PASS"
	check(passed, "%s: %s" % [label, str(result.get("detail", ""))])
	return passed


func _pass(peer: int, action: String, args: Dictionary, budget: int = -1) -> bool:
	return _ok(await step(peer, action, args, budget), "peer %d %s" % [peer, action])
