extends "res://tests/helpers/net_harness.gd"

# peers: 2

## F27: a guest's wild win is paid by the host. Two real ENet peers; the host
## engages a wild creature through the production press, the guest joins the
## same record and lands real host-accepted strikes until the opponent falls.
## With combat.json actor_vitals.runtime_enabled the host captures the
## canonical victory: the host's own share is its training row, and the guest's
## share is a retained `wild_defeat` duty (owner-passive gate -> host stage ->
## owner apply/save -> ACK). The guest's combat manager skips its legacy award
## because the host stamped the record it owns the XP.
##
##   tools/net/run_net_smoke.sh f27_guest_wild_win
##
## Asserted on the guest's own record AND the host's admitted view of it:
## exactly one defeat receipt, at least one type essence, XP paid, the guest
## equal to the host (so no legacy local award on top), the host row accepted;
## then nothing changes across reconnect and a reload. The guest drops the
## moment the opponent falls (mid-settlement) and rejoins; the host
## participant is paid exactly once by its own row.
## Disclosed fixtures: party_grant seeds both homes before networking; the
## guest walks to the fight by move_to; creatures are placed beside the
## opponent before each strike (as smoke_net_shared_wild_fight does).
const SPECIES := "terrapup"
const LEVEL := 9
const SWINGS := 60
const SETTLE_POLLS := 40

var _guest_id := ""
var _port := 0


func _initialize() -> void:
	_run()


func _run() -> bool:
	await process_frame
	heartbeat_silence_tolerance_s = 150.0
	# Two world builds exceed the hello budget together: launch on the title,
	# then boot each world in turn (as smoke_net_f27_essence_no_dup does).
	if not await launch(2, "title"): return await _end()
	_step_phase_deadline_ms = Time.get_ticks_msec() + 3600.0 * 1000.0
	for peer in 2:
		if not await _pass(peer, "boot", {"scene": "world"}, 30000): return await _end()
	for peer in 2:
		if not await _pass(peer, "party_grant", {"species": SPECIES, "level": LEVEL}): return await _end()
	var saved: Dictionary = await step(1, "save_character_here", {})
	_guest_id = str((saved.get("data", {}) as Dictionary).get("character_id", ""))
	if not await _pass(0, "host", {}): return await _end()
	_port = int(((await probe(0, "session")) as Dictionary).get("enet_port", 0))
	if not await _pass(1, "join", {"host": "127.0.0.1", "port": _port,
			"character": {"character_id": _guest_id, "display_name": "Wild Guest"}}, 6000): return await _end()
	for peer in 2:
		if not await _pass(peer, "expect_peers", {"count": 2}): return await _end()
	for peer in 2:
		if not await _pass(peer, "deploy_creature", {}): return await _end()
	var guest_before := await _guest()
	var host_before := await _host_self()
	if not await _pass(0, "engage_wild", {}): return await _end()
	var host_view: Dictionary = await _encounter(0)
	var encounter_id := str(host_view.get("id", ""))
	check(str(host_view.get("kind", "")) == "wild" and not encounter_id.is_empty(), "host minted a shared wild record")
	var here := _vec(host_view.get("opponent_pos", []))
	if here == Vector3.INF: return await _end()
	# The guest must first hear the host's announcement, as a player would.
	var announced := false
	for _poll in 16:
		announced = ((await _encounter(1)).get("joinable", []) as Array).has(encounter_id)
		if announced: break
		await step(1, "wait", {"frames": 15})
	check(announced, "the guest was told the fight exists and can be joined")
	# Walk, not teleport: a short fixture jump is not a host-confirmed
	# discontinuity, and the guest's owner-passive replay would (rightly) stop
	# at its speed bound, holding every later duty of that character.
	await step(1, "move_to", {"x": here.x - 2.5, "z": here.z, "close_enough": 4.0, "budget_frames": 2400})
	var joined: Dictionary = await step(1, "join_encounter", {"encounter_id": encounter_id})
	if str(joined.get("verdict", "")) != "PASS": print("guest join result: %s" % str(joined))
	check(str(joined.get("verdict", "")) == "PASS", "guest joined the host's wild record (%s)" % str(joined.get("detail", "")))
	if str(joined.get("verdict", "")) != "PASS": return await _end()
	# The guest fights it down with real host-accepted strikes.
	var done := false
	for swing in SWINGS:
		var view: Dictionary = await _encounter(0)
		if str(view.get("phase", "")) == "done" or float(view.get("opponent_hp", 1.0)) <= 0.0:
			done = true
			break
		var opponent := _vec(view.get("opponent_pos", []))
		if opponent == Vector3.INF: break
		var stand := opponent + Vector3(0.0, 0.0, 3.5)
		await step(1, "place_creature", {"at": [stand.x, stand.y, stand.z], "face": [opponent.x, opponent.y, opponent.z], "settle": 15})
		var toward := opponent - stand
		await step(1, "strike", {"facing": [toward.x, toward.y, toward.z], "slot": "quick", "settle": 20})
	check(done, "the guest's strikes brought the shared opponent down")
	if not done: return await _end()
	# Mid-settlement cut: the guest drops the moment the opponent falls, before
	# its vitals and win share settle, then rejoins. The share settles once.
	if not await _pass(1, "leave", {"reason": "f27_mid_settlement"}): return await _end()
	if not await _pass(0, "expect_peers", {"count": 1}): return await _end()
	await step(0, "wait", {"frames": 120})
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return await _end()
	# Settlement: actor vitals, the host's own row and the guest's retained share.
	var guest_after := await _guest()
	var view := await _host_view()
	for _poll in SETTLE_POLLS:
		if (view.get("row", {}) as Dictionary).get("status") == "accepted" and (guest_after.defeat_receipts as Array).size() == 1: break
		await step(0, "wait", {"frames": 60})
		guest_after = await _guest()
		view = await _host_view()
	if (guest_after.defeat_receipts as Array).is_empty():
		await _projection_diff()
		print("wild runtime: %s" % str((await step(0, "f27_wild_runtime", {})).get("data", {})))
		for peer in 2:
			print("passive peer %d: %s" % [peer, str((await step(peer, "f27_passive_state", {"character_id": _guest_id})).get("data", {}))])
	check((guest_after.defeat_receipts as Array).size() == (guest_before.defeat_receipts as Array).size() + 1,
		"the guest holds exactly one new defeat receipt (%s)" % str(guest_after.defeat_receipts))
	check((view.get("row", {}) as Dictionary).get("action") == "wild_defeat_share" and (view.get("row", {}) as Dictionary).get("status") == "accepted",
		"the host's row for the guest is its accepted wild_defeat share (%s)" % str(view.get("row")))
	var essence_gain := 0
	for item: String in guest_after.items:
		if item.begins_with("essence_"): essence_gain += int(guest_after.items[item]) - int(guest_before.items.get(item, 0))
	check(essence_gain >= 1, "the guest received its type essence (+%d)" % essence_gain)
	var xp_gain := 0
	for i in (guest_after.party as Array).size():
		xp_gain += int(guest_after.party[i].xp) - int(guest_before.party[i].xp) + 1000 * (int(guest_after.party[i].level) - int(guest_before.party[i].level))
	check(xp_gain > 0, "the guest's creature gained XP from the host share")
	for key: String in ["party", "items", "defeat_receipts"]:
		check(str(view.get(key)) == str(guest_after.get(key)),
			"host admitted %s equals the guest's: no legacy local award on top (%s vs %s)" % [key, str(view.get(key)), str(guest_after.get(key))])
	# The host participant is paid exactly once too, by its own training row.
	var host_after := await _host_self()
	check((host_after.defeat_receipts as Array).size() == (host_before.defeat_receipts as Array).size() + 1,
		"the host participant holds exactly one new defeat receipt (%s)" % str(host_after.defeat_receipts))
	var host_essence := 0
	for item: String in host_after.items:
		if item.begins_with("essence_"): host_essence += int(host_after.items[item]) - int(host_before.items.get(item, 0))
	check(host_essence >= 1, "the host participant received its type essence (+%d)" % host_essence)
	# No duplication across reconnect and hard reload.
	if not await _pass(1, "leave", {"reason": "f27_reconnect"}): return await _end()
	if not await _pass(0, "expect_peers", {"count": 1}): return await _end()
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
			"returning_route": true, "character": {"character_id": _guest_id}}, 15000): return await _end()
	await step(1, "wait", {"frames": 240})
	var reconnected := await _guest()
	for key: String in ["party", "items", "defeat_receipts"]:
		check(str(reconnected.get(key)) == str(guest_after.get(key)), "after reconnect %s unchanged (%s)" % [key, str(reconnected.get(key))])
	if not await _pass(1, "save_reload_here", {}, 8000): return await _end()
	var reloaded := await _guest()
	for key: String in ["party", "items", "defeat_receipts"]:
		check(str(reloaded.get(key)) == str(guest_after.get(key)), "after reload %s unchanged (%s)" % [key, str(reloaded.get(key))])
	return await _end()


func _projection_diff() -> void:
	var owner: Dictionary = ((await step(1, "f27_passive_projection", {})).get("data", {}) as Dictionary).get("state", {})
	var host_data: Dictionary = (await step(0, "f27_passive_projection", {"character_id": _guest_id})).get("data", {})
	var host: Dictionary = host_data.get("state", {})
	print("projection diff (host stream error %s):" % str(host_data.get("error")))
	_diff("", owner, host)


func _diff(path: String, a: Variant, b: Variant) -> void:
	if a is Dictionary and b is Dictionary:
		var keys: Dictionary = {}
		for k: Variant in (a as Dictionary).keys() + (b as Dictionary).keys(): keys[k] = true
		for k: Variant in keys: _diff("%s.%s" % [path, str(k)], (a as Dictionary).get(k), (b as Dictionary).get(k))
	elif a is Array and b is Array and (a as Array).size() == (b as Array).size():
		for i in (a as Array).size(): _diff("%s[%d]" % [path, i], a[i], b[i])
	elif str(a) != str(b):
		print("  %s owner=%s host=%s" % [path, str(a).left(160), str(b).left(160)])


func _end() -> bool:
	quit(await finish())
	return true


func _guest() -> Dictionary:
	return ((await step(1, "f27_snapshot", {})).get("data", {}) as Dictionary)


func _host_self() -> Dictionary:
	return ((await step(0, "f27_snapshot", {})).get("data", {}) as Dictionary)


func _host_view() -> Dictionary:
	return ((await step(0, "f27_host_view", {"character_id": _guest_id})).get("data", {}) as Dictionary)


func _encounter(peer: int) -> Dictionary:
	var value = await probe(peer, "encounter")
	return value if value is Dictionary else {}


func _vec(raw: Variant) -> Vector3:
	if not raw is Array or (raw as Array).size() != 3: return Vector3.INF
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _pass(peer: int, action: String, args: Dictionary, budget: int = -1) -> bool:
	var result: Dictionary = await step(peer, action, args, budget)
	var ok := str(result.get("verdict", "")) == "PASS"
	check(ok, "peer %d %s: %s" % [peer, action, str(result.get("detail", ""))])
	return ok
