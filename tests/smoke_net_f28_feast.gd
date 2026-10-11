extends "res://tests/smoke_net_homestead_station_craft.gd"

# peers: 2
## F28#3: an Ascension Feast costs that tier's biome materials plus one
## type-attuned ingredient; it is cooked at the Kitchen and fed to one creature
## of the matching type to lift its cap. Real ENet over loopback: a guest cooks
## at the host's Kitchen through the actual feast panel buttons.
##
##   tools/net/run_net_smoke.sh f28_feast
##
## Proves: the cook debits exactly the authored cost (berries 4, rootstone 2,
## attuned_ground 1) and pays one feast_t1_ground; a second cook without the
## ingredients is refused and moves nothing; feeding it to a water creature
## is refused (type mismatch) and keeps the feast; feeding the ground
## creature at Lv 10 lifts its cap to 20 once, with no level or XP gain, and
## spends the feast; the lifted creature is not offered the feast again; the
## host's admitted record agrees, and a save/reload keeps all of it.
## Disclosed fixtures: as smoke_net_homestead_station_craft (Kitchen + Spice
## rack placed by the host's paid build press; the guest a returning saved
## character with the opening played, standing beside the host's Kitchen).
## Before its first join the guest's own home is seeded (f28_feast_seed, then
## saved): the feast_t1 recipe as Orin Stonewake's chest teaches it (F28#2/#4
## prove that chest: smoke_net_f28_masters), one cook's ingredients, and two
## Lv 10 creatures at the first cap (party_grant): a ground Terrapup and a
## water Ripplet.
const RECIPE := "Ascension Feast 1 (ground)"
const FEAST := "feast_t1_ground"


func _run() -> void:
	await process_frame
	require_peer_logs_without(["SCRIPT ERROR", "Parse Error", "Invalid call"], "feast peer logs have no script errors")
	world_build_allowance_floor_s["production_host"] = 150.0
	world_build_allowance_floor_s["production_join"] = 150.0
	if not await launch(2, "title", [], {1: ["--scene=world"]}):
		quit(await finish())
		return
	_step_phase_deadline_ms = Time.get_ticks_msec() + 900000.0
	var port := int((_peers[0] as Dictionary).get("hello", {}).get("enet_port", 0))
	if not await _craft_step(0, "production_host", {"port": port, "appearance_id": "trainer", "display_name": "FeastHost"}, 9000): return
	if not await _craft_step(1, "party_grant", {"species": "terrapup", "level": 10, "nickname": "Pup"}): return
	if not await _craft_step(1, "party_grant", {"species": "ripplet", "level": 10, "nickname": "Rip"}): return
	if not await _craft_step(1, "seed_opening_complete", {}): return
	if not await _craft_step(1, "f28_feast_seed", {"recipes": ["feast_t1"],
			"items": {"berries": 4, "rootstone": 2, "attuned_ground": 1}}): return
	var seeded := await _craft_data(1, "save_character_here", {})
	if seeded.is_empty():
		await _feast_finish()
		return
	var guest_id := str(seeded.character_id)
	if not await _craft_step(1, "production_join", {"host": "127.0.0.1", "port": port,
		"returning_route": true, "character": {"character_id": guest_id}}, 9000): return
	var placed := await _craft_data(0, "craft_place_kitchen", {}, 3000)
	if placed.is_empty():
		await _feast_finish()
		return
	var kitchen := str(placed.kitchen_uid)
	# The guest walks the few metres to the host's Kitchen (no teleport).
	var station := await _craft_data(1, "f28_station_at", {"kitchen_uid": kitchen}, 1200)
	if station.is_empty():
		await _feast_finish()
		return
	if not await _craft_step(1, "move_to", {"x": float(station.at[0]) + 1.6, "z": float(station.at[2]) + 1.6,
			"close_enough": 1.5, "budget_frames": 2400}, 2800): return
	var before := await _feast(1)
	if before.is_empty():
		await _feast_finish()
		return
	check(_ints(before.items) == {"berries": 4, "rootstone": 2, "attuned_ground": 1, FEAST: 0}
		and int(before.party.terrapup.cap_level) == 10 and int(before.party.terrapup.level) == 10
		and int(before.party.ripplet.cap_level) == 10 and int(before.party.ripplet.level) == 10,
		"the guest starts with one cook's ingredients and two Lv 10 creatures at cap 10 (%s)" % JSON.stringify(before))

	# Cook: the exact cost, one feast.
	await step(1, "f27_dismiss_modals", {})
	var cooked := await _craft_data(1, "f28_cook", {"kitchen_uid": kitchen, "button": RECIPE}, 2400)
	var after_cook := await _feast(1)
	check(cooked.get("pressed") == true, "the Kitchen panel offers %s (%s)" % [RECIPE, str(cooked.get("labels", []))])
	check(_ints(after_cook.get("items", {})) == {"berries": 0, "rootstone": 0, "attuned_ground": 0, FEAST: 1},
		"#3 cooking spent exactly berries 4, rootstone 2, attuned_ground 1 and made one %s (%s; %s)" % [FEAST, str(after_cook.get("items")), str(cooked.get("message"))])
	# Exactly one NEW craft receipt: the guest already holds the opening Home
	# Key gift's craft:home_key_* receipts (home_key_action.gd) from before the cook.
	var craft_receipts := func(state: Dictionary) -> Array:
		return (state.get("receipts", []) as Array).filter(func(r: Variant) -> bool: return str(r).begins_with("craft:"))
	var new_receipts: Array = (craft_receipts.call(after_cook) as Array).filter(
		func(r: Variant) -> bool: return not (craft_receipts.call(before) as Array).has(r))
	check(new_receipts.size() == 1 and (craft_receipts.call(after_cook) as Array).size() == (craft_receipts.call(before) as Array).size() + 1,
		"#3 the cook saved one craft receipt (%s)" % str(new_receipts))

	# Without its ingredients, the same recipe is refused and nothing moves.
	await step(1, "f27_dismiss_modals", {})
	var short := await _craft_data(1, "f28_cook", {"kitchen_uid": kitchen, "button": RECIPE}, 2400)
	var after_short := await _feast(1)
	check(short.get("pressed") == true and after_short.get("items") == after_cook.get("items")
		and after_short.get("receipts") == after_cook.get("receipts"),
		"#3 a cook without the ingredients is refused and moves nothing (%s; %s)" % [str(short.get("message")), str(after_short.get("items"))])

	# Type mismatch: the ground feast on the water creature.
	await step(1, "f27_dismiss_modals", {})
	var mismatch := await _craft_data(1, "f28_feed", {"kitchen_uid": kitchen, "button": "Rip · "}, 2400)
	var after_mismatch := await _feast(1)
	check(mismatch.get("pressed") == true and str(mismatch.get("message", "")).to_lower().contains("match"),
		"#3 feeding the ground feast to the water Ripplet is refused as a type mismatch (%s)" % str(mismatch.get("message")))
	check(int(after_mismatch.get("items", {}).get(FEAST, -1)) == 1 and int(after_mismatch.party.ripplet.cap_level) == 10
		and after_mismatch.party.ripplet == after_short.party.ripplet,
		"#3 the refused feed keeps the feast and leaves the Ripplet at cap 10 (%s)" % JSON.stringify(after_mismatch.party.ripplet))

	# The matching ground creature: cap 10 -> 20, no level or XP.
	await step(1, "f27_dismiss_modals", {})
	var fed := await _craft_data(1, "f28_feed", {"kitchen_uid": kitchen, "button": "Pup · "}, 2400)
	var after_feed := await _feast(1)
	var pup_before: Dictionary = before.party.terrapup
	var pup: Dictionary = after_feed.get("party", {}).get("terrapup", {})
	check(fed.get("pressed") == true and int(pup.get("cap_level", -1)) == 20 and (pup.get("breakthroughs", []) as Array).size() == 1 and int(pup.breakthroughs[0]) == 1
		and int(pup.get("level", -1)) == int(pup_before.level) and int(pup.get("xp", -1)) == int(pup_before.xp),
		"#3 the ground feast lifts the Terrapup's cap to 20 with no level or XP gain (%s; %s)" % [JSON.stringify(pup), str(fed.get("message"))])
	check(int(after_feed.get("items", {}).get(FEAST, -1)) == 0, "#3 feeding spent the feast")
	check((after_feed.get("receipts", []) as Array).filter(func(r: Variant) -> bool: return str(r).begins_with("feast_feed:")).size() == 1,
		"#3 the feed saved one feast receipt")

	# The lifted creature is not offered the tier again.
	await step(1, "f27_dismiss_modals", {})
	var again := await _craft_data(1, "f28_feed", {"kitchen_uid": kitchen, "button": "Pup · "}, 600)
	check(again.get("pressed") == false, "the lifted Terrapup is not offered a tier-1 feast again (%s)" % str(again.get("labels")))

	# The host's admitted record agrees; a reload keeps it.
	var held := {}
	for _poll in 20:
		held = await _feast(0, guest_id)
		if held.get("party") == after_feed.get("party") and held.get("items") == after_feed.get("items"): break
		await step(0, "wait", {"frames": 60})
	check(held.get("party") == after_feed.get("party") and held.get("items") == after_feed.get("items")
		and held.get("receipts") == after_feed.get("receipts"),
		"the host's admitted record of the guest agrees (%s)" % JSON.stringify(held))
	if not await _craft_step(1, "save_reload_here", {}, 8000): return
	var reloaded := await _feast(1)
	check(reloaded.get("party") == after_feed.get("party") and reloaded.get("items") == after_feed.get("items")
		and reloaded.get("receipts") == after_feed.get("receipts"),
		"a save and reload keeps the cooked-and-fed state (%s)" % JSON.stringify(reloaded))
	await _feast_finish()


func _ints(items: Dictionary) -> Dictionary:
	var out := {}
	for id: String in items: out[id] = int(items[id])
	return out


func _feast(peer: int, character_id: String = "") -> Dictionary:
	return await _craft_data(peer, "f28_feast_view", {"character_id": character_id})


func _feast_finish() -> void:
	print("F28#3 feast: exact cost at the host's Kitchen, refused when short, refused on type mismatch, one cap lift on the matching creature.")
	quit(await finish())
