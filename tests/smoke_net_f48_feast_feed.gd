extends "res://tests/smoke_net_f48_coop_loop.gd"

# peers: 2
# net-timeout-seconds: 900
## Bounded F48 feast regression, not the integrated chapter/Master proof.
## Uses the existing loop's actual Kitchen cook/feed buttons and receipt
## assertions for BOTH stable characters, then saves/reloads and rejoins.
## Disclosed boundary: feast_t1 is seeded before admission instead of earning
## the Master win here. The full loop still starts with no recipe. All other
## inherited fixture grants and Kitchen stances remain disclosed by that loop.
##   tools/net/run_net_smoke.sh f48_feast_feed


func _initial_feast_recipes() -> Array:
	return ["feast_t1"]


func _loop() -> void:
	_step_phase_deadline_ms = Time.get_ticks_msec() + 900000.0
	_evidence["scope"] = "bounded two-participant feast feed; generated recipe boundary; not F48 integrated closure"
	var start := await _both("feast_boundary")
	for peer in 2:
		check(start[peer].feast_recipes.count("feast_t1") == 1, "peer %d has the disclosed recipe boundary" % peer)
		var trip := await _data(peer, "craft_home_key_trip", {}, 12000)
		if trip.is_empty() or bool(trip.get("skipped", false)): return
	var placed := await _data(0, "craft_place_kitchen", {}, 3000)
	if placed.is_empty(): return
	var before := await _both("before_feast")
	var creature_before: Array = []
	for peer in 2:
		var view := await _data(peer, "f28_feast_view", {})
		var pup: Dictionary = view.get("party", {}).get("terrapup", {})
		check(int(pup.get("cap_level", -1)) == 10, "peer %d starts at the unbroken first cap" % peer)
		creature_before.append(pup)
	var after := await _feast_leg(str(placed.kitchen_uid), before)
	if after.is_empty(): return
	for peer in 2:
		var view := await _data(peer, "f28_feast_view", {})
		var pup: Dictionary = view.get("party", {}).get("terrapup", {})
		for key: String in ["uid", "level", "xp"]:
			check(pup.get(key) == creature_before[peer].get(key), "feast changes the cap, not peer %d's %s" % [peer, key])
		await step(peer, "f27_dismiss_modals", {})
		var again := await _data(peer, "f28_feed", {"kitchen_uid": str(placed.kitchen_uid), "button": "Pup · "}, 600)
		check(again.get("pressed") == false, "peer %d cannot feed the completed tier twice" % peer)
	if not await _pass(1, "save_character_here", {}): return
	if not await _pass(0, "save_reload_here", {}, 8000): return
	if not await _pass(1, "leave", {"reason": "player_left"}): return
	if not await _pass(0, "expect_peers", {"count": 1}, 900): return
	if not await _pass(1, "production_join", {"host": "127.0.0.1", "port": _port, "budget_frames": 14000,
		"returning_route": true, "character": {"character_id": _ids[1]}}, 15000): return
	if not await _pass(0, "expect_peers", {"count": 2}, 900): return
	for peer in 2:
		await step(peer, "wait", {"frames": SETTLE})
		await step(peer, "dismiss_dialogue", {"presses": 16, "settle": 30})
	var reloaded := await _both("feast_reloaded")
	for peer in 2:
		for key: String in ["items", "caps", "master_wins", "feast_recipes", "relics_held", "relics_hung", "receipts"]:
			check(str(reloaded[peer].get(key)) == str(after[peer].get(key)),
				"feast reload: peer %d's %s unchanged" % [peer, key])
		var view := await _data(peer, "f28_feast_view", {})
		var pup: Dictionary = view.get("party", {}).get("terrapup", {})
		for key: String in ["uid", "level", "xp"]:
			check(pup.get(key) == creature_before[peer].get(key),
				"feast reload: peer %d's original creature %s preserved" % [peer, key])
	_completed = true
	print("F48_FEAST_FEED: both participants cooked and fed once; personal caps and receipts survive save/reload and rejoin")
