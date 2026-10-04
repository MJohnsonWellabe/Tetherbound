extends "res://tests/test_case.gd"

## F27#0, #1 (defeat, release, crop, care) and #3 (Altar rules) over the real
## shipping helpers: ItemDB, essence.gd, farm_logic.gd and a canonical
## admitted record built by PlayerState.save_data(). The Session CAS, station
## reach and the controller path are covered by smoke_f27_altar_spend.gd and
## the two-peer duplication smoke; this file pins the rules they rely on.
const E := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FARM := preload("res://scripts/world/farm_logic.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const CHARACTER := "f27-owner"
const TYPES := ["ground", "water", "air", "electric", "fire", "dark", "ice", "psychic"]


func _player(entries: Array) -> RefCounted:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	for entry: Array in entries:
		var card: RefCounted = SPECIES.spawn(entry[0])
		player.party.add(card)
		card.set("level", entry[1])
		card.call("_apply_level_stats", PROGRESSION.config())
	return player


func _admitted(player: RefCounted) -> Dictionary:
	var record := RECORD.portable_projection(player.save_data())
	assert_eq(RECORD.errors(record, CHARACTER), [], "fixture is a canonical admitted record")
	return record


func _count(record: Dictionary, item: String) -> int:
	return RULES.inventory_from(record.inventory).count(item)


func _row(record: Dictionary, uid: String) -> Dictionary:
	for row: Dictionary in record.party:
		if row.uid == uid: return row
	return {}


func _wild(species_id: String, level: int) -> Dictionary:
	# A real serialized creature row, as the host's dead enemy card carries.
	var row: Dictionary = RECORD.portable_projection(_player([[species_id, level]]).save_data()).party[0]
	row["uid"] = "wild-" + species_id
	row["hp"] = 0
	row["fainted"] = true
	assert_eq(row.creature_type, SPECIES.definition(species_id).type)
	return row


# --- #0 items -----------------------------------------------------------------

func test_eight_type_essences_and_tether_candy_are_stackable_items() -> void:
	var db: RefCounted = RULES.db()
	var seen: Array[String] = []
	for type_id: String in TYPES:
		var item := E.essence_item(type_id)
		assert_eq(item, "essence_" + type_id, type_id + " maps to its essence item")
		assert_true(db.has(item), item + " is a real ItemDB item")
		assert_eq(db.stack_size(item), 999, item + " stacks to 999")
		seen.append(item)
	assert_eq(seen.size(), 8)
	assert_true(db.has("tether_candy"))
	assert_eq(db.stack_size("tether_candy"), 99, "Tether Candy stacks to 99")
	# Stacking is real slot behavior, not only a number in the catalogue.
	var inventory := RULES.inventory_from(_admitted(_player([["terrapup", 5]])).inventory)
	assert_eq(inventory.add("essence_fire", 600), 0)
	assert_eq(inventory.add("essence_fire", 300), 0)
	assert_eq(inventory.count("essence_fire"), 900)
	var slots_used := 0
	for slot: Variant in RULES.slots(inventory):
		if slot is Dictionary and slot.get("id") == "essence_fire": slots_used += 1
	assert_eq(slots_used, 1, "900 essence is one stack")


# --- #1 sources ---------------------------------------------------------------

func test_defeat_payout_is_typed_level_scaled_and_dual_split() -> void:
	var cfg := E.config()
	assert_eq(E.defeat_payout(_wild("bramblebun", 5), cfg), [{"id": "essence_ground", "n": 1}])
	assert_eq(E.defeat_payout(_wild("bramblebun", 20), cfg), [{"id": "essence_ground", "n": 3}])
	assert_eq(E.defeat_payout(_wild("frostclaw", 12), cfg), [{"id": "essence_ice", "n": 2}])
	# Dual type: remainder to primary, never both full.
	assert_eq(E.defeat_payout(_wild("nightburrow", 20), cfg),
		[{"id": "essence_ground", "n": 2}, {"id": "essence_dark", "n": 1}])
	assert_eq(E.defeat_payout(_wild("nightburrow", 5), cfg), [{"id": "essence_ground", "n": 1}])


func test_wild_defeat_stages_essence_and_reduced_xp_once() -> void:
	var player := _player([["terrapup", 5]])
	var before := _admitted(player)
	var uid: String = before.party[0].uid
	var event := {"event_id": "wild_defeat:f27-unit", "world_namespace": "f27-ns",
		"encounter_id": "enc-1", "enemy_uid": "wild-bramblebun", "enemy_record": _wild("bramblebun", 20),
		"active_uid": uid, "eligible_uids": [uid], "kind": "wild_defeat", "xp_mode": "hybrid"}
	var staged := E.stage_defeat(before, CHARACTER, event, 3, E.config(), PROGRESSION.config())
	assert_true(staged.get("ok") == true, str(staged))
	assert_eq(staged.payout, [{"id": "essence_ground", "n": 3}])
	assert_eq(_count(staged.state, "essence_ground"), _count(before, "essence_ground") + 3)
	var xp_before := int(before.party[0].get("xp", 0))
	var after_row := _row(staged.state, uid)
	assert_true(int(after_row.level) > 5 or int(after_row.xp) > xp_before, "reduced combat XP is still non-zero")
	var ordinary := PROGRESSION.raw_xp_award_for(20, PROGRESSION.config())
	assert_true(PROGRESSION.scaled_combat_xp(20, PROGRESSION.config(), E.config()) < ordinary, "hybrid XP is reduced")
	# Replay of the same host event is a duplicate with no second grant.
	var replay := E.stage_defeat(staged.state, CHARACTER, event, 4, E.config(), PROGRESSION.config())
	assert_true(replay.get("ok") == true and replay.get("duplicate") == true, str(replay))
	assert_false(replay.has("state"))
	# Same event id, different payload is a conflict, not a fresh award.
	var forged := event.duplicate(true)
	forged.enemy_record.level = 40
	assert_eq(E.stage_defeat(staged.state, CHARACTER, forged, 4, E.config(), PROGRESSION.config()).get("code"), "receipt_conflict")


func test_release_pays_the_released_creatures_type_once() -> void:
	var player := _player([["terrapup", 5], ["frostclaw", 12], ["cindercub", 9]])
	var before := _admitted(player)
	var cfg := E.config()
	var frost: String = before.party[1].uid
	var cinder: String = before.party[2].uid
	# floor(3 + 0.5 * 12) = 9 ice essence.
	assert_eq(E.release_payout(before.party[1], cfg), [{"id": "essence_ice", "n": 9}])
	# floor(3 + 0.5 * 9) = 7: fire 4 (primary takes remainder), ground 3.
	assert_eq(E.release_payout(before.party[2], cfg), [{"id": "essence_fire", "n": 4}, {"id": "essence_ground", "n": 3}])
	var released := E.stage_release(before, CHARACTER, frost, 2, cfg)
	assert_true(released.get("ok") == true and released.get("duplicate") == false, str(released))
	assert_eq(released.state.party.size(), 2)
	assert_true(_row(released.state, frost).is_empty(), "released creature leaves the five")
	assert_false(released.state.redesign_character.creatures.has(frost))
	assert_eq(_count(released.state, "essence_ice"), _count(before, "essence_ice") + 9)
	assert_true(released.state.redesign_character.release_receipts.has("release:" + frost))
	# A replay against the committed record is a duplicate, never a second payout.
	var replay := E.stage_release(released.state, CHARACTER, frost, 3, cfg)
	assert_true(replay.get("ok") == true and replay.get("duplicate") == true, str(replay))
	assert_false(replay.has("state"))
	assert_eq(E.stage_release(released.state, CHARACTER, "never-owned", 3, cfg).get("code"), "not_owned")
	var dual := E.stage_release(released.state, CHARACTER, cinder, 3, cfg)
	assert_true(dual.get("ok") == true, str(dual))
	assert_eq(_count(dual.state, "essence_fire"), _count(before, "essence_fire") + 4)
	assert_eq(_count(dual.state, "essence_ground"), _count(before, "essence_ground") + 3)


func test_every_type_crop_harvest_pays_its_configured_essence() -> void:
	var cfg := E.config()
	var farm: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/farm.json")
	for type_id: String in TYPES:
		var tilled := {"state": FARM.TILLED, "ripe_on_day": 0}
		var planted := FARM.planted_crop(tilled, 1, type_id, farm, true)
		assert_false(planted.is_empty(), type_id + " crop can be planted")
		var ripe_day := 1 + int(FARM.crop_definition(farm, type_id).grow_days)
		var harvest := FARM.harvest_candidate(planted, ripe_day, farm)
		assert_false(harvest.is_empty(), type_id + " crop ripens")
		assert_eq(int(harvest.outputs.get("essence_" + type_id, 0)), int(cfg.crop_essence_yield),
			type_id + " crop pays the configured essence")
		assert_eq(int(harvest.outputs.get("attuned_" + type_id, 0)), int(cfg.crop_attuned_yield))
		assert_true(FARM.harvest_candidate(planted, ripe_day - 1, farm).is_empty(), "no early or offline harvest")


func test_care_trickle_is_capped_per_character_per_host_day() -> void:
	var player := _player([["terrapup", 5], ["frostclaw", 5], ["sparkit", 5]])
	var before := _admitted(player)
	var cfg := E.config()
	cfg.care_daily_character_cap = 2
	var uids: Array = before.party.map(func(row: Dictionary) -> String: return row.uid)
	var first := E.stage_care(before, CHARACTER, uids[0], 7, 1, cfg)
	assert_true(first.get("ok") == true, str(first))
	assert_eq(_count(first.state, "essence_ground"), _count(before, "essence_ground") + 1)
	var again := E.stage_care(first.state, CHARACTER, uids[0], 7, 2, cfg)
	assert_true(again.get("duplicate") == true, "the same creature cannot be groomed twice for essence in a day")
	var second := E.stage_care(first.state, CHARACTER, uids[1], 7, 2, cfg)
	assert_true(second.get("ok") == true and second.daily_care_awarded == 2, str(second))
	assert_eq(E.stage_care(second.state, CHARACTER, uids[2], 7, 3, cfg).get("code"), "daily_care_cap")
	var next_day := E.stage_care(second.state, CHARACTER, uids[2], 8, 3, cfg)
	assert_true(next_day.get("ok") == true, "the cap resets on the next host day")
	assert_eq(_count(next_day.state, "essence_electric"), _count(before, "essence_electric") + 1)
	# Shipping cap is small and configured, not unbounded.
	assert_between(float(E.config().care_daily_character_cap), 1.0, 10.0)


func test_no_creature_expedition_or_automation_source_exists() -> void:
	var cfg := E.config()
	for key: String in cfg:
		for banned: String in ["expedition", "automation", "idle", "offline", "passive_income"]:
			assert_false(key.contains(banned), "no automated essence source: " + key)


# --- #2 automatic combat XP ---------------------------------------------------

func test_automatic_combat_xp_is_reduced_but_never_zero() -> void:
	var cfg := E.config()
	assert_between(float(cfg.auto_xp_scale), 0.01, 0.99)
	for level: int in [1, 2, 5, 10, 30, 60]:
		var scaled := PROGRESSION.scaled_combat_xp(level, PROGRESSION.config(), cfg)
		assert_true(scaled >= 1, "level %d wild still pays XP" % level)
		assert_true(PROGRESSION.scaled_party_combat_xp(level, PROGRESSION.config(), cfg) >= 1)


# --- #3 Altar spend -----------------------------------------------------------

func _spend(record: Dictionary, uid: String, spend_id: String, payment: String, revision: int = 5) -> Dictionary:
	return E.stage_spend(record, CHARACTER, uid, spend_id, int(_row(record, uid).level), payment,
		revision, E.config(), PROGRESSION.config())


func _stocked(player: RefCounted) -> Dictionary:
	for type_id: String in TYPES: player.inventory.add("essence_" + type_id, 200)
	player.inventory.add("tether_candy", 3)
	return _admitted(player)


func test_starters_level_through_their_own_type_essence() -> void:
	for starter: Array in [["terrapup", "essence_ground"], ["ripplet", "essence_water"], ["galewisp", "essence_air"]]:
		var before := _stocked(_player([[starter[0], 7]]))
		var uid: String = before.party[0].uid
		var quote := E.quote_spend(before, CHARACTER, uid, 5, E.config(), PROGRESSION.config())
		assert_true(quote.get("ok") == true, str(quote))
		var ids: Array = quote.payments.map(func(p: Dictionary) -> String: return p.id)
		assert_eq(ids, [starter[1], "tether_candy"], starter[0] + " is offered only its type and candy")
		var cost := E.level_cost(7, E.config(), PROGRESSION.config())
		assert_true(cost >= 1)
		var spent := _spend(before, uid, "spend-a", starter[1])
		assert_true(spent.get("ok") == true, str(spent))
		assert_eq(int(_row(spent.state, uid).level), 8, starter[0] + " gains exactly one level")
		assert_eq(_count(spent.state, starter[1]), _count(before, starter[1]) - cost)
		var wrong := "essence_fire"
		assert_eq(_spend(before, uid, "spend-b", wrong).get("code"), "wrong_payment_type", starter[0] + " refuses another type")


func test_dual_type_may_pay_with_either_essence_or_candy() -> void:
	var before := _stocked(_player([["cindercub", 4]]))
	var uid: String = before.party[0].uid
	var quote := E.quote_spend(before, CHARACTER, uid, 5, E.config(), PROGRESSION.config())
	var ids: Array = quote.payments.map(func(p: Dictionary) -> String: return p.id)
	assert_eq(ids, ["essence_fire", "essence_ground", "tether_candy"])
	var cost := E.level_cost(4, E.config(), PROGRESSION.config())
	var by_fire := _spend(before, uid, "fire", "essence_fire")
	assert_true(by_fire.get("ok") == true, str(by_fire))
	assert_eq(_count(by_fire.state, "essence_fire"), 200 - cost)
	assert_eq(_count(by_fire.state, "essence_ground"), 200)
	var by_ground := _spend(by_fire.state, uid, "ground", "essence_ground", 6)
	assert_true(by_ground.get("ok") == true, str(by_ground))
	assert_eq(int(_row(by_ground.state, uid).level), 6)
	assert_eq(_count(by_ground.state, "essence_ground"), 200 - E.level_cost(5, E.config(), PROGRESSION.config()))
	var by_candy := _spend(by_ground.state, uid, "candy", "tether_candy", 7)
	assert_true(by_candy.get("ok") == true, str(by_candy))
	assert_eq(_count(by_candy.state, "tether_candy"), 2, "one candy pays one level")
	assert_eq(_spend(before, uid, "water", "essence_water").get("code"), "wrong_payment_type")


func test_altar_spend_stops_at_cap_and_refuses_without_payment() -> void:
	var player := _player([["terrapup", 9]])
	player.inventory.add("essence_ground", 1)
	var poor := _admitted(player)
	var uid: String = poor.party[0].uid
	assert_eq(E.creature_cap(poor.redesign_character, uid), 10, "fresh creature cap is tier 10")
	assert_eq(_spend(poor, uid, "poor", "essence_ground").get("code"), "insufficient_items")
	var rich := _stocked(_player([["terrapup", 9]]))
	var to_cap := _spend(rich, rich.party[0].uid, "cap", "essence_ground")
	assert_true(to_cap.get("ok") == true, str(to_cap))
	var capped_uid: String = rich.party[0].uid
	assert_eq(int(_row(to_cap.state, capped_uid).level), 10)
	var over := _spend(to_cap.state, capped_uid, "over", "essence_ground", 6)
	assert_eq(over.get("code"), "breakthrough_needed", "the cap holds; essence cannot buy a breakthrough")
	assert_eq(_spend(to_cap.state, capped_uid, "over-candy", "tether_candy", 6).get("code"), "breakthrough_needed")
	var quote := E.quote_spend(to_cap.state, CHARACTER, capped_uid, 6, E.config(), PROGRESSION.config())
	assert_true(quote.get("ok") == true and quote.payments.is_empty(), "a capped creature is quoted no payment")
	# Stale UI (wrong expected level) is refused, not repriced.
	assert_eq(E.stage_spend(rich, CHARACTER, capped_uid, "stale", 8, "essence_ground", 5,
		E.config(), PROGRESSION.config()).get("code"), "stale_level")


func test_altar_spend_id_replays_as_duplicate_and_conflicts_cannot_mint() -> void:
	var before := _stocked(_player([["terrapup", 3]]))
	var uid: String = before.party[0].uid
	var spent := _spend(before, uid, "once", "essence_ground")
	assert_true(spent.get("ok") == true and spent.get("duplicate") == false, str(spent))
	var replay := E.stage_spend(spent.state, CHARACTER, uid, "once", 3, "essence_ground", 5,
		E.config(), PROGRESSION.config())
	assert_true(replay.get("ok") == true and replay.get("duplicate") == true, str(replay))
	assert_false(replay.has("state"), "a replay commits nothing")
	var conflict := E.stage_spend(spent.state, CHARACTER, uid, "once", 4, "essence_ground", 6,
		E.config(), PROGRESSION.config())
	assert_eq(conflict.get("code"), "receipt_conflict")


# --- owner delivery across passive drift (reconnect/reload) ------------------

func _spend_row(before: Dictionary) -> Dictionary:
	var teaching := preload("res://scripts/creatures/teaching.gd")
	var uid: String = before.party[0].uid
	var intent := {"spend_id": "0123456789abcdef0123456789abcdef", "creature_uid": uid,
		"expected_level": int(before.party[0].level), "payment_item": "essence_ground", "expected_character_revision": 0}
	var proposal := E.stage_core_spend(before, CHARACTER, 0, intent, E.config(), PROGRESSION.config(),
		teaching.available_moves, teaching.character_loadout_mirror)
	assert_true(proposal.get("ok") == true, str(proposal))
	var accepted := {"character_id": CHARACTER, "character_revision": 1, "before": before, "state": proposal.state,
		"intent": intent, "action": "altar_spend", "action_id": intent.spend_id, "receipt": proposal.receipt}
	var row := E.next_training_delivery("f27-world", "f27-namespace", "f27-session", accepted, null,
		E.config(), PROGRESSION.config(), teaching.available_moves, teaching.character_loadout_mirror)
	assert_false(row.is_empty(), "a real pending Altar spend row")
	return row


func _owner_stage(owner: Dictionary, row: Dictionary) -> Dictionary:
	var teaching := preload("res://scripts/creatures/teaching.gd")
	return E.stage_training_owner(owner, row, E.config(), PROGRESSION.config(),
		teaching.available_moves, teaching.character_loadout_mirror)


func _drift(record: Dictionary) -> Dictionary:
	var drifted := record.duplicate(true)
	for card: Dictionary in drifted.party:
		card.nourishment = float(card.get("nourishment", 50.0)) - 3.25
		card.happiness = float(card.get("happiness", 50.0)) - 1.5
	return drifted


func test_passive_care_fields_mirror_the_owner_passive_replay_list() -> void:
	assert_eq(E.PASSIVE_CARE_FIELDS, preload("res://scripts/net/owner_passive_replay.gd").PASSIVE_FIELDS)


func test_pending_spend_delivers_once_despite_passive_drift_before_rejoin() -> void:
	var before := _stocked(_player([["terrapup", 4]]))
	var row := _spend_row(before)
	if row.is_empty(): return
	var staged := _owner_stage(_drift(before), row)
	assert_true(staged.get("ok") == true and staged.get("duplicate") == false, "drift is not a baseline conflict: " + str(staged))
	assert_eq(int(_row(staged.state, before.party[0].uid).level), 5)
	assert_eq(_count(staged.state, "essence_ground"), 200 - E.level_cost(4, E.config(), PROGRESSION.config()))
	# Saved-before-ACK owner (marker present) that drifted again: a duplicate, never a second level.
	var saved := _drift(staged.state)
	var replay := _owner_stage(saved, row)
	assert_true(replay.get("ok") == true and replay.get("duplicate") == true, str(replay))
	assert_eq(int(_row(replay.state, before.party[0].uid).level), 5)
	assert_eq(_count(replay.state, "essence_ground"), _count(staged.state, "essence_ground"))


func test_real_conflicts_are_still_refused() -> void:
	var before := _stocked(_player([["terrapup", 4]]))
	var row := _spend_row(before)
	if row.is_empty(): return
	var richer := before.duplicate(true)
	var inventory := RULES.inventory_from(richer.inventory)
	inventory.add("essence_ground", 7)
	richer.inventory = RULES.slots(inventory)
	assert_eq(_owner_stage(richer, row).get("code"), "training_owner_baseline_conflict")
	var applied: Dictionary = _owner_stage(before, row).state
	var tampered := applied.duplicate(true)
	tampered.party[0].level = 9
	assert_eq(_owner_stage(tampered, row).get("code"), "training_marker_state_conflict")


# --- ordinary ceremony release (essence_release character action) -----------

func _release_context(record: Dictionary) -> Dictionary:
	return {"character_id": CHARACTER, "expected_revision": 4, "source_key": "release_ceremony:wild-new",
		"in_range": true, "in_combat": false, "release_ceremony": true, "foundation_runtime_authorized": true}


func test_ceremony_release_action_pays_type_essence_and_removes_one() -> void:
	var rules := preload("res://scripts/net/character_action_rules.gd")
	var five := _admitted(_player([["terrapup", 5], ["frostclaw", 12], ["cindercub", 9], ["sparkit", 5], ["ripplet", 5]]))
	var frost: String = five.party[1].uid
	var intent := {"release_id": "0123456789abcdef0123456789abcdef", "creature_uid": frost}
	var staged := rules.stage(five, 4, "essence_release", intent, _release_context(five), RECORD.errors)
	assert_true(staged.get("ok") == true, str(staged))
	assert_eq(staged.receipt, "release:" + frost)
	assert_eq(staged.state.party.size(), 4)
	assert_eq(_count(staged.state, "essence_ice"), _count(five, "essence_ice") + 9)
	assert_true(staged.state.redesign_character.release_receipts.has("release:" + frost))
	# Same release against the committed record is never a second payout.
	assert_eq(rules.stage(staged.state, 5, "essence_release", intent, _release_context(staged.state), RECORD.errors).get("ok"), false)


func test_ceremony_release_requires_the_ceremony_and_a_full_belt() -> void:
	var rules := preload("res://scripts/net/character_action_rules.gd")
	var four := _admitted(_player([["terrapup", 5], ["frostclaw", 12], ["cindercub", 9], ["sparkit", 5]]))
	var intent := {"release_id": "0123456789abcdef0123456789abcdef", "creature_uid": four.party[1].uid}
	assert_eq(rules.stage(four, 4, "essence_release", intent, _release_context(four), RECORD.errors).get("code"), "release_requires_full_party")
	var five := _admitted(_player([["terrapup", 5], ["frostclaw", 12], ["cindercub", 9], ["sparkit", 5], ["ripplet", 5]]))
	var no_ceremony := _release_context(five)
	no_ceremony.erase("release_ceremony")
	intent.creature_uid = five.party[1].uid
	assert_eq(rules.stage(five, 4, "essence_release", intent, no_ceremony, RECORD.errors).get("code"), "actual_release_ceremony_required")
	var bad := {"release_id": "x", "creature_uid": five.party[1].uid, "payout": 99}
	assert_eq(rules.stage(five, 4, "essence_release", bad, _release_context(five), RECORD.errors).get("code"), "invalid_release_intent")
