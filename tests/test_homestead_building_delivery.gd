extends "res://tests/test_case.gd"

## F31 paid Homestead stations/attachments on the Altar building journal:
## version-2 codec, exact price, placement record, world op binding, ledger
## doors, owner stage/recovery and paid-provenance refund. Version-1 Altar
## rows must keep validating exactly as before.
const DELIVERY := preload("res://scripts/net/homestead_building_delivery.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const NAMESPACE := "world-homestead-delivery"
const WORLD_ID := "slot-homestead-delivery"
const CHARACTER := "character-homestead-delivery"
const TXN := "0123456789abcdef0123456789abcdef"
const TXN_2 := "fedcba9876543210fedcba9876543210"
const TXN_3 := "00112233445566778899aabbccddeeff"


func _before(extra: Array = []) -> Dictionary:
	var inventory := RULES.inventory_from([])
	for need: Dictionary in DELIVERY.cost("workbench") + DELIVERY.cost("forge") + DELIVERY.cost("forge_meadows") + extra:
		inventory.add(need.id, int(need.n))
	return {"character_id": CHARACTER, "party": [], "redesign_character": STATE.defaults("character"),
		"inventory": RULES.slots(inventory), "portal_escrow": {}, "vitals_escrow": {},
		"equipment": RECORD.empty_equipment(), "realm_hearts": {"active_id": "meadows"}}


func _record(id: String, uid: String, parent_uid: String = "", slot: int = 0) -> Dictionary:
	return {"id": id, "realm": "meadows", "uid": uid, "position": [-6.0, 1.0, 20.0],
		"yaw_deg": 0.0, "paid": true, "parent_uid": parent_uid, "slot": slot}


func _request(action: String, txn: String, record: Dictionary) -> Dictionary:
	if action == "dismantle":
		return {"kind": "dismantle", "realm": "meadows", "uid": record.uid, "txn_id": txn}
	return {"kind": "place_building", "realm": "meadows", "id": record.id, "position": record.position.duplicate(),
		"yaw_deg": record.yaw_deg, "paid": true, "txn_id": txn, "parent_uid": record.parent_uid}


## Same row shape LedgerRpc.journal_altar_building_prepared writes.
func _row(full: Dictionary, revision: int, action: String, txn: String, record: Dictionary) -> Dictionary:
	var proposal := DELIVERY.transition(full, CHARACTER, revision, action, txn, record, NAMESPACE)
	if proposal.is_empty(): return {}
	return {"version": 2, "kind": "altar_building", "delivery_id": DELIVERY.delivery_id(NAMESPACE, CHARACTER, txn),
		"world_id": WORLD_ID, "world_namespace": NAMESPACE, "session_id": "session-homestead-delivery",
		"character_id": CHARACTER, "action": action, "action_id": txn,
		"intent": {"request": _request(action, txn, record), "record": record.duplicate(true), "cost": proposal.cost.duplicate(true)},
		"before": ESSENCE.training_projection(full), "after": ESSENCE.training_projection(proposal.state),
		"receipt": proposal.receipt, "character_revision": revision + 1, "journal_revision": 1, "status": "pending"}


func _world() -> RefCounted:
	var world: RefCounted = WORLD.new()
	world.reward_delivery_namespace = NAMESPACE
	world.world_id = WORLD_ID
	return world


func test_price_is_the_settled_catalogue_row_and_never_the_altar() -> void:
	assert_eq(DELIVERY.cost("workbench"), [{"id": "wood", "n": 10}, {"id": "stone", "n": 4}])
	assert_eq(DELIVERY.cost("forge_meadows"), [{"id": "rootstone", "n": 8}, {"id": "ironwood", "n": 8}, {"id": "rootiron_ingot", "n": 2}])
	for id: String in ["altar", "forge_biome5", "wall", "storage", ""]:
		assert_eq(DELIVERY.cost(id), [], id)
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DELIVERY.CATALOGUE))
	var cfg := STATION_RULES.config()
	var conflicting := catalogue.duplicate(true)
	for row: Dictionary in conflicting.buildables:
		if row.id == "workbench": row.cost = [{"id": "wood", "n": 1}]
	assert_eq(DELIVERY.cost_from(conflicting, cfg, "workbench"), [], "a legacy row cannot reprice the Workbench")
	var duplicated := catalogue.duplicate(true)
	duplicated.homestead_buildables.append({"id": "kitchen", "cost": [{"id": "wood", "n": 1}]})
	assert_eq(DELIVERY.cost_from(duplicated, cfg, "kitchen"), [], "duplicate rows never pick a price by order")
	var drifted := cfg.duplicate(true)
	for row: Dictionary in drifted.attachments:
		if row.id == "den_meadows": row.cost[0].n = 1
	assert_eq(DELIVERY.cost_from(catalogue, drifted, "den_meadows"), [], "attachment config and catalogue must agree")


func test_canonical_record_carries_stable_parent_and_slot_identity() -> void:
	assert_true(DELIVERY.record_valid(_record("workbench", "b1")))
	assert_true(DELIVERY.record_valid(_record("forge_meadows", "b2", "b1", 1)))
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(_record("forge_meadows", "b2", "b1", 1)))
	assert_true(DELIVERY.record_valid(reloaded), "JSON float slot still canonical")
	var bad := {
		"altar keeps version 1": _record("altar", "b1"),
		"attachment without parent": _record("forge_meadows", "b2"),
		"station with parent": _record("forge", "b2", "b1", 1),
		"wrong slot": _record("forge_tidewake", "b2", "b1", 1),
		"self parent": _record("forge_meadows", "b2", "b2", 1),
		"bad uid": _record("forge", "b01"),
		"reserved tier": _record("forge_biome5", "b2", "b1", 5),
	}
	for label: String in bad: assert_false(DELIVERY.record_valid(bad[label]), label)
	var extra := _record("forge", "b1")
	extra.arch_twin = ""
	assert_false(DELIVERY.record_valid(extra), "no extra fields")
	var unpaid := _record("forge", "b1")
	unpaid.paid = false
	assert_false(DELIVERY.record_valid(unpaid), "never a free record")


func test_paid_place_debits_and_proven_dismantle_refunds_the_same_price() -> void:
	var before := _before()
	var record := _record("workbench", "b1")
	var place := DELIVERY.transition(before, CHARACTER, 0, "place_building", TXN, record, NAMESPACE)
	assert_true(place.get("ok") == true)
	if place.get("ok") != true: return
	var after := RULES.inventory_from(place.state.inventory)
	var start := RULES.inventory_from(before.inventory)
	assert_eq(after.count("wood"), start.count("wood") - 10)
	assert_eq(after.count("stone"), start.count("stone") - 4)
	assert_true(place.state.redesign_character.transaction_receipts.has(place.receipt))
	assert_true(place.receipt.contains(":homestead_build:"), "distinct from Altar receipts")
	var refund := DELIVERY.transition(place.state, CHARACTER, 1, "dismantle", TXN_2, record, NAMESPACE)
	assert_true(refund.get("ok") == true)
	if refund.get("ok") == true:
		var back := RULES.inventory_from(refund.state.inventory)
		assert_eq(back.count("wood"), start.count("wood"))
		assert_eq(back.count("stone"), start.count("stone"))
	assert_true(DELIVERY.transition(place.state, CHARACTER, 1, "place_building", TXN, record, NAMESPACE).is_empty(), "receipt replay refused")
	var poor := before.duplicate(true)
	poor.inventory = RULES.slots(RULES.inventory_from([]))
	assert_true(DELIVERY.transition(poor, CHARACTER, 0, "place_building", TXN, record, NAMESPACE).is_empty(), "no stock, no placement")
	assert_true(DELIVERY.transition(before, CHARACTER, 0, "place_building", "not-a-txn", record, NAMESPACE).is_empty())
	assert_true(DELIVERY.transition(before, CHARACTER, 0, "place_building", TXN, _record("altar", "b1"), NAMESPACE).is_empty())


func test_version_two_row_round_trips_and_rejects_tampering_while_version_one_altar_rows_still_validate() -> void:
	var before := _before()
	var row := _row(before, 0, "place_building", TXN, _record("forge", "b1"))
	assert_false(row.is_empty())
	if row.is_empty(): return
	assert_eq(row.delivery_id, WORLD.altar_build_id(NAMESPACE, CHARACTER, TXN), "same journal id formula")
	assert_true(DELIVERY.row_valid(row, NAMESPACE, WORLD_ID))
	assert_true(WORLD.altar_build_row_valid(row, NAMESPACE, WORLD_ID), "existing journal readers dispatch version 2")
	assert_true(WORLD.training_row_valid(row, NAMESPACE, WORLD_ID))
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(row))
	assert_true(WORLD.altar_build_row_valid(reloaded, NAMESPACE, WORLD_ID), "JSON reload")
	var tampered := {}
	for key: String in ["cost", "after", "request", "record", "version", "namespace", "receipt"]:
		var bad := row.duplicate(true)
		match key:
			"cost": bad.intent.cost[0].n = 1
			"after": bad.after.inventory = before.inventory.duplicate(true)
			"request": bad.intent.request.parent_uid = "b9"
			"record": bad.intent.record.position = [0.0, 0.9, 0.0]
			"version": bad.version = 1
			"namespace": bad.world_namespace = "another-world"
			"receipt": bad.receipt = "craft:x"
		tampered[key] = bad
	for key: String in tampered: assert_false(WORLD.altar_build_row_valid(tampered[key], NAMESPACE, WORLD_ID), key)
	# The original version-1 Altar contract is untouched.
	var altar_inventory := RULES.inventory_from(before.inventory)
	for need: Dictionary in WORLD.altar_recipe(): altar_inventory.add(need.id, int(need.n))
	var altar_full := before.duplicate(true)
	altar_full.inventory = RULES.slots(altar_inventory)
	var altar := {"id": "altar", "realm": "meadows", "paid": true, "uid": "b1", "position": [2.0, 0.0, 3.0], "yaw_deg": 0.0}
	var proposal := WORLD.building_transition(altar_full, CHARACTER, 0, "place_building", TXN, altar, NAMESPACE)
	assert_true(proposal.get("ok") == true and proposal.receipt.contains(":altar_build:"), "Altar keeps its own transition")
	if proposal.get("ok") != true: return
	var v1 := {"version": 1, "kind": "altar_building", "delivery_id": WORLD.altar_build_id(NAMESPACE, CHARACTER, TXN),
		"world_id": WORLD_ID, "world_namespace": NAMESPACE, "session_id": "session-homestead-delivery",
		"character_id": CHARACTER, "action": "place_building", "action_id": TXN,
		"intent": {"request": {"kind": "place_building", "txn_id": TXN, "id": "altar", "realm": "meadows", "paid": true,
			"position": altar.position.duplicate(), "yaw_deg": 0.0}, "record": altar, "cost": proposal.cost.duplicate(true)},
		"before": ESSENCE.training_projection(altar_full), "after": ESSENCE.training_projection(proposal.state),
		"receipt": proposal.receipt, "character_revision": 1, "journal_revision": 1, "status": "pending"}
	assert_true(WORLD.altar_build_row_valid(v1, NAMESPACE, WORLD_ID), "version-1 Altar row")
	var as_v2 := v1.duplicate(true)
	as_v2.version = 2
	assert_false(WORLD.altar_build_row_valid(as_v2, NAMESPACE, WORLD_ID), "an Altar record never passes as version 2")


func test_world_ledger_commits_only_journaled_station_records_and_refunds_only_proven_ones() -> void:
	var world := _world()
	var ledger: RefCounted = LEDGER.new(world)
	# A legacy/forged intent cannot plant or remove a gated homestead station.
	var forged: Dictionary = ledger.call("commit", {"kind": "place_building", "realm": "meadows", "id": "forge",
		"position": [-6.0, 1.0, 20.0], "yaw_deg": 0.0, "paid": true, "txn_id": TXN_3}, 1)
	assert_false(forged.get("ok") == true)
	assert_eq(forged.get("code"), "station_transaction_required")
	assert_true(world.placed_buildings.is_empty())
	var free_op := {"op": "building_add", "scope": "world", "realm": "meadows", "uid": "b1", "id": "workbench",
		"position": [-6.0, 1.0, 20.0], "yaw_deg": 0.0, "paid": true, "txn_id": TXN_3}
	assert_eq(int(world.apply_delta({"ops": [free_op]})), 0, "an unjournaled station op is not applied")
	assert_true(world.placed_buildings.is_empty())

	var before := _before()
	var record := _record("forge", "b1")
	var place := _row(before, 0, "place_building", TXN, record)
	var verdict: Dictionary = ledger.call("commit_altar_building", place, 1)
	assert_true(verdict.get("ok") == true, str(verdict))
	assert_eq(world.placed_buildings.size(), 1)
	if world.placed_buildings.size() != 1: return
	assert_true(ESSENCE._equivalent(world.placed_buildings[0], record), "placed record is the canonical version-2 record")
	assert_eq(int(world.next_building_uid), 2)
	assert_true(WORLD.training_world_errors(world.reward_deliveries, NAMESPACE, WORLD_ID, world.placed_buildings).is_empty())
	# The saved world reloads with the same binding.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(world.save_data()))
	assert_true(WORLD.training_world_errors(saved.reward_deliveries, NAMESPACE, WORLD_ID, saved.placed_buildings).is_empty(), "saved binding")
	# Dropping the paid record from the world breaks its journal binding.
	assert_false(WORLD.altar_buildings_bound(world.reward_deliveries, []), "journal requires its building")
	# No legacy dismantle and no refund while the placement is unaccepted.
	var legacy: Dictionary = ledger.call("commit", {"kind": "dismantle", "realm": "meadows", "uid": "b1", "txn_id": TXN_3}, 1)
	assert_eq(legacy.get("code"), "station_transaction_required")
	var after_place: Dictionary = before.duplicate(true)
	for field: String in place.after: after_place[field] = place.after[field].duplicate(true)
	var early := _row(after_place, 1, "dismantle", TXN_2, record)
	assert_false(ledger.call("commit_altar_building", early, 1).get("ok") == true, "refund needs an accepted paid placement")
	world.reward_deliveries[place.delivery_id].status = "accepted"
	var refund := _row(after_place, 1, "dismantle", TXN_2, record)
	var removed: Dictionary = ledger.call("commit_altar_building", refund, 1)
	assert_true(removed.get("ok") == true, str(removed))
	assert_true(world.placed_buildings.is_empty())
	assert_true(WORLD.training_world_errors(world.reward_deliveries, NAMESPACE, WORLD_ID, world.placed_buildings).is_empty(), "place + refund history binds")


func test_attachment_record_commits_with_its_parent_and_slot() -> void:
	var world := _world()
	var ledger: RefCounted = LEDGER.new(world)
	var before := _before()
	var parent := _record("forge", "b1")
	var place := _row(before, 0, "place_building", TXN, parent)
	assert_true(ledger.call("commit_altar_building", place, 1).get("ok") == true)
	world.reward_deliveries[place.delivery_id].status = "accepted"
	var after_place: Dictionary = before.duplicate(true)
	for field: String in place.after: after_place[field] = place.after[field].duplicate(true)
	var attachment := _record("forge_meadows", "b2", "b1", 1)
	attachment.position = [-6.0 - 1.0 - 1.8, 1.0, 20.0]
	var row := _row(after_place, 1, "place_building", TXN_2, attachment)
	assert_false(row.is_empty())
	if row.is_empty(): return
	assert_true(ledger.call("commit_altar_building", row, 1).get("ok") == true)
	assert_eq(world.placed_buildings.size(), 2)
	if world.placed_buildings.size() != 2: return
	assert_eq(world.placed_buildings[1].parent_uid, "b1")
	assert_eq(int(world.placed_buildings[1].slot), 1)
	var tier := STATION_RULES.effective_tier(STATION_RULES.config(), world.placed_buildings, "b1")
	assert_true(tier.get("ok") == true, str(tier))
	assert_eq(int(tier.get("effective_tier", -1)), 1, "the paid Meadows attachment raises the station tier")


func test_character_authority_stages_and_recovers_the_version_two_journal() -> void:
	var before := _before()
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world(NAMESPACE))
	assert_true(authority.seed_admitted_character(before, CHARACTER).ok)
	var record := _record("workbench", "b1")
	var seeded: Dictionary = authority.state(CHARACTER)
	var proposal := DELIVERY.transition(seeded, CHARACTER, 0, "place_building", TXN, record, NAMESPACE)
	var stage: Dictionary = authority.stage_altar_building(CHARACTER, proposal)
	assert_true(stage.get("ok") == true, str(stage.get("code", "")))
	assert_eq(authority.revision(CHARACTER), 1)
	assert_true(authority.finish_creature_training(stage, false), "failed world save restores")
	assert_eq(authority.revision(CHARACTER), 0)
	assert_true(ESSENCE._equivalent(authority.state(CHARACTER), seeded))
	# Host restart: the saved pending row is the only recovery truth.
	var row := _row(before, 0, "place_building", TXN, record)
	var fresh := AUTHORITY.new()
	assert_true(fresh.bind_world(NAMESPACE))
	assert_true(fresh.seed_admitted_character(before, CHARACTER).ok)
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(row))
	var recovered: Dictionary = fresh.recover_durable_training(CHARACTER, {reloaded.delivery_id: reloaded})
	assert_true(recovered.get("ok") == true and recovered.get("pending") == true, str(recovered))
	assert_true(ESSENCE._equivalent(ESSENCE.training_projection(fresh.state(CHARACTER)), row.after))
	reloaded.status = "accepted"
	assert_true(fresh.acknowledge_creature_training(CHARACTER, reloaded))
	assert_false(fresh.creature_training_is_pending(CHARACTER))
