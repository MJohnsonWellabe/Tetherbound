extends "res://tests/test_case.gd"

## F33#0: Harness and Charm slots in the four live tiers (Rootiron, Tidesteel,
## Skyglass, Stormglass), each upgradable +1..+3, over the real gear rules and
## the real item database. Equip/upgrade run the real staging (stage_core);
## the effect runs the real host prepare adapter (prepared_actor_inputs).
##
## Disclosed fixtures: a fresh character with one spawned creature (as in
## test_foundation_resources), gear pieces and materials added straight to its
## satchel, and a homestead station context (Den/Forge) as BuildPlacer would
## supply. No played path is claimed here.

const GEAR := preload("res://scripts/creatures/creature_gear.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const CHARACTER := "gear-owner"
const LIVE := ["Rootiron", "Tidesteel", "Skyglass", "Stormglass"]

var _items: RefCounted


func _db() -> RefCounted:
	if _items == null:
		_items = ITEM_DB.new()
	return _items


func _record(stock: Dictionary = {}) -> Dictionary:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(_db())
	player.character_id = CHARACTER
	player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	for id: String in stock:
		player.inventory.add(id, int(stock[id]))
	var record := RECORD.portable_projection(player.save_data())
	var uid := str(record.party[0].uid)
	if not (record.redesign_character.creatures as Dictionary).has(uid):
		record.redesign_character.creatures[uid] = {}
	return record


func _context(station: String, tier: int = 4) -> Dictionary:
	return {"character_id": CHARACTER, "expected_revision": 0, "homestead": true, "in_range": true,
		"in_combat": false, "source_key": "station:" + station, "station_id": station, "effective_tier": tier}


func _intent(action: String, uid: String, slot: String, item: String, n: int = 1) -> Dictionary:
	return {"action": action, "action_id": ("%032x" % n), "creature_uid": uid, "slot": slot, "item_id": item}


func _id(tier_name: String, slot: String, upgrade: int) -> String:
	var base := "%s_%s" % [tier_name.to_lower(), slot]
	return base if upgrade == 0 else "%s_plus_%d" % [base, upgrade]


func test_four_live_tiers_each_have_harness_and_charm_from_plus_0_to_plus_3() -> void:
	var cfg := GEAR.config()
	assert_eq(int(cfg.max_upgrade), 3)
	var live: Array = cfg.tiers.filter(func(t: Dictionary) -> bool: return t.status == "live").map(func(t: Dictionary) -> String: return t.name)
	assert_eq(live, LIVE, "the four live tiers in biome order")
	for t in LIVE.size():
		for slot: String in GEAR.SLOTS:
			for upgrade in 4:
				var id := _id(LIVE[t], slot, upgrade)
				var row: Dictionary = cfg.items.get(id, {})
				assert_eq(row.get("gear_slot"), slot, id)
				assert_eq(int(row.get("gear_tier", -1)), t + 1, id)
				assert_eq(int(row.get("gear_upgrade", -1)), upgrade, id)
				assert_true(bool(_db().call("has", id)), "%s is a real item" % id)
				var probe := GEAR.empty_slots()
				probe[slot] = id
				assert_eq(GEAR.slots_errors(probe, cfg), [], "%s fits its %s slot" % [id, slot])
				var other := GEAR.empty_slots()
				other["charm" if slot == "harness" else "harness"] = id
				assert_false(GEAR.slots_errors(other, cfg).is_empty(), "%s never fits the other slot" % id)
				var next: Dictionary = cfg.upgrades.get(id, {})
				if upgrade < 3:
					assert_eq(str(next.get("output", "")), _id(LIVE[t], slot, upgrade + 1), "%s upgrades one step" % id)
				else:
					assert_true(next.is_empty(), "%s is the maximum" % id)


func test_bonus_rises_with_tier_and_with_each_upgrade() -> void:
	var cfg := GEAR.config()
	var last_hp := 1.0
	var last_power := 1.0
	for t in LIVE.size():
		var tier_hp := 0.0
		for upgrade in 4:
			var gear := {"harness": _id(LIVE[t], "harness", upgrade), "charm": _id(LIVE[t], "charm", upgrade)}
			var mods := GEAR.modifiers(gear, cfg)
			assert_true(float(mods.max_hp) > last_hp, "%s +%d harness beats the step before (%.3f > %.3f)" % [LIVE[t], upgrade, mods.max_hp, last_hp])
			assert_true(float(mods.move_power) > last_power, "%s +%d charm beats the step before" % [LIVE[t], upgrade])
			last_hp = float(mods.max_hp)
			last_power = float(mods.move_power)
			if upgrade == 0: tier_hp = float(mods.max_hp)
		# The next tier's base piece must beat this tier's +0, so a new biome's gear matters.
		last_hp = tier_hp
		last_power = GEAR.modifiers({"harness": "", "charm": _id(LIVE[t], "charm", 0)}, cfg).move_power
	assert_eq(GEAR.modifiers(GEAR.empty_slots(), cfg), {"max_hp": 1.0, "defence": 1.0, "move_power": 1.0, "ultimate_gain": 1.0},
		"empty slots give no bonus")


func test_equip_at_the_den_then_upgrade_at_the_forge_to_plus_3() -> void:
	var cfg := GEAR.config()
	var record := _record({"rootiron_harness": 1, "rootiron_ingot": 20, "fiber": 10})
	var uid := str(record.party[0].uid)
	var equipped := GEAR.stage_core(record, CHARACTER, 0, _intent("equip", uid, "harness", "rootiron_harness", 1), _context("den"), _db(), cfg)
	assert_true(equipped.get("ok") == true, str(equipped))
	if equipped.get("ok") != true: return
	var state: Dictionary = equipped.state
	assert_eq(GEAR.gear_for(state, uid).harness, "rootiron_harness")
	assert_eq(state.redesign_character.transaction_receipts.count(equipped.receipt), 1)
	for upgrade in [1, 2, 3]:
		var current := _id("Rootiron", "harness", upgrade - 1)
		var staged := GEAR.stage_core(state, CHARACTER, 0, _intent("upgrade", uid, "harness", current, 10 + upgrade), _context("forge"), _db(), cfg)
		assert_true(staged.get("ok") == true, "upgrade to +%d: %s" % [upgrade, str(staged)])
		if staged.get("ok") != true: return
		state = staged.state
		assert_eq(GEAR.gear_for(state, uid).harness, _id("Rootiron", "harness", upgrade))
	var low := GEAR.stage_core(equipped.state, CHARACTER, 0, _intent("upgrade", uid, "harness", "rootiron_harness", 30), _context("forge", 0), _db(), cfg)
	assert_eq(low.get("reason", ""), "station_tier", "a Forge below the recipe tier refuses the upgrade")
	var past := GEAR.stage_core(state, CHARACTER, 0, _intent("upgrade", uid, "harness", "rootiron_harness_plus_3", 20), _context("forge"), _db(), cfg)
	assert_eq(past.get("code", past.get("reason", "")), "maximum_upgrade", "+3 is the cap: %s" % str(past))


func test_gear_refusals() -> void:
	var cfg := GEAR.config()
	var record := _record({"rootiron_charm": 1})
	var uid := str(record.party[0].uid)
	var cases := {
		"needs_den": [_intent("equip", uid, "charm", "rootiron_charm", 1), _context("forge")],
		"ownership": [_intent("equip", "someone-elses-uid", "charm", "rootiron_charm", 2), _context("den")],
		"invalid_piece": [_intent("equip", uid, "harness", "rootiron_charm", 3), _context("den")],
		"needs_home_station_outside_combat": [_intent("equip", uid, "charm", "rootiron_charm", 4), _context("den").merged({"in_combat": true}, true)],
		"missing_piece": [_intent("equip", uid, "charm", "tidesteel_charm", 5), _context("den")],
	}
	for expected: String in cases:
		var staged := GEAR.stage_core(record, CHARACTER, 0, cases[expected][0], cases[expected][1], _db(), cfg)
		assert_false(staged.get("ok") == true, "%s refuses" % expected)
		assert_eq(str(staged.get("code", staged.get("reason", ""))), expected, str(staged))
	var once := GEAR.stage_core(record, CHARACTER, 0, _intent("equip", uid, "charm", "rootiron_charm", 6), _context("den"), _db(), cfg)
	assert_true(once.get("ok") == true, str(once))
	if once.get("ok") == true:
		var again := GEAR.stage_core(once.state, CHARACTER, 0, _intent("equip", uid, "charm", "rootiron_charm", 6), _context("den"), _db(), cfg)
		assert_eq(str(again.get("code", again.get("reason", ""))), "replayed", "the same action never applies twice")
		var stale := GEAR.stage_core(record, CHARACTER, 3, _intent("equip", uid, "charm", "rootiron_charm", 7), _context("den"), _db(), cfg)
		assert_eq(str(stale.get("code", stale.get("reason", ""))), "stale_revision")


func test_host_prepare_applies_equipped_gear_once_and_keeps_portable_hp_intrinsic() -> void:
	var cfg := GEAR.config()
	var record := _record()
	var uid := str(record.party[0].uid)
	record.redesign_character.creatures[uid]["gear"] = {"harness": "skyglass_harness_plus_2", "charm": "skyglass_charm"}
	var card: Dictionary = record.party[0]
	var base := {"max_hp": float(card.max_hp), "defence": 10.0}
	var prepared := GEAR.prepared_actor_inputs(record, CHARACTER, uid, base, {"ultimate": {}}, cfg)
	assert_true(prepared.get("ok") == true, str(prepared))
	if prepared.get("ok") != true: return
	var mods := GEAR.modifiers(record.redesign_character.creatures[uid].gear, cfg)
	assert_almost_eq(float(prepared.stats.max_hp), float(card.max_hp) * float(mods.max_hp), 0.001)
	assert_almost_eq(float(prepared.stats.defence), 10.0 * float(mods.defence), 0.001)
	assert_true(float(prepared.stats.gear_move_power_multiplier) > 1.0)
	assert_eq(str(GEAR.prepared_actor_inputs(record, CHARACTER, uid, prepared.stats, {"ultimate": {}}, cfg).get("code",
		GEAR.prepared_actor_inputs(record, CHARACTER, uid, prepared.stats, {"ultimate": {}}, cfg).get("reason", ""))), "already_prepared",
		"an already geared profile is refused, so gear never compounds")
	var back := GEAR.intrinsic_vitals(float(prepared.stats.max_hp) * 0.5, prepared.stats.max_hp, card.max_hp)
	assert_almost_eq(float(back.hp), float(card.max_hp) * 0.5, 0.001, "half geared HP is half intrinsic HP on the portable row")
	assert_eq(float(back.max_hp), float(card.max_hp))


func test_charm_reaches_strike_power_through_the_real_freeze_and_host_profile() -> void:
	# The encounter director's host move start: F23 freeze_action, then the
	# F33 Charm freeze, then COMBAT_MANAGER.host_move_profile (what the host
	# strikes with). The Charm raises the profile's power by its multiplier.
	var cfg := GEAR.config()
	var creature: RefCounted = preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")
	var moves := preload("res://scripts/creatures/move_db.gd").load_default()
	var actor := {"character_id": CHARACTER, "creature_uid": str(creature.get("uid")), "encounter_id": "gear-encounter",
		"generation": 1, "action": 1}
	var frozen := preload("res://scripts/creatures/move_mastery.gd").freeze_action(creature, "quick", actor, [], moves)
	assert_true(frozen.get("ok") == true, str(frozen))
	if frozen.get("ok") != true: return
	var manager := preload("res://scripts/combat/combat_manager.gd")
	var move_id := str(creature.get("move_quick"))
	var plain: Dictionary = manager.host_move_profile(moves, "player_quick", move_id, 0.5, 0.5, 1.0, 0.0,
		GEAR.freeze_move_profile(frozen.move, GEAR.empty_slots(), cfg))
	var charmed: Dictionary = manager.host_move_profile(moves, "player_quick", move_id, 0.5, 0.5, 1.0, 0.0,
		GEAR.freeze_move_profile(frozen.move, {"harness": "", "charm": "tidesteel_charm_plus_1"}, cfg))
	var mods := GEAR.modifiers({"harness": "", "charm": "tidesteel_charm_plus_1"}, cfg)
	assert_almost_eq(float(charmed.power), float(plain.power) * float(mods.move_power), 0.0001, "the Charm scales strike power once")
	assert_eq(float(charmed.gear_ultimate_gain_multiplier), float(mods.ultimate_gain), "and carries its ultimate gain to the host credit")
