extends "res://tests/test_case.gd"

const WORLD := preload("res://autoload/world_state.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const NAMESPACE := "world-altar-recovery"
const CHARACTER := "character-altar-recovery"
const TXN := "0123456789abcdef0123456789abcdef"

func _before() -> Dictionary:
	var inventory := RULES.inventory_from([])
	for need: Dictionary in WORLD.altar_recipe(): inventory.add(need.id, int(need.n) + 1)
	return {"character_id": CHARACTER, "party": [], "redesign_character": STATE.defaults("character"),
		"inventory": RULES.slots(inventory), "portal_escrow": {}, "vitals_escrow": {},
		"equipment": RECORD.empty_equipment(), "realm_hearts": {"active_id": "meadows"}}

func _journal(before: Dictionary) -> Dictionary:
	var building := {"id": "altar", "realm": "meadows", "paid": true, "uid": "b1",
		"position": [2.0, 0.0, 3.0], "yaw_deg": 0.0}
	var proposal := WORLD.altar_build_transition(before, CHARACTER, 0, "place_building", TXN, building, NAMESPACE)
	if proposal.is_empty(): return {}
	var request := {"kind": "place_building", "txn_id": TXN, "id": "altar", "realm": "meadows",
		"paid": true, "position": building.position.duplicate(), "yaw_deg": building.yaw_deg}
	return {"version": 1, "kind": "altar_building", "delivery_id": WORLD.altar_build_id(NAMESPACE, CHARACTER, TXN),
		"world_id": "slot-altar-recovery", "world_namespace": NAMESPACE, "session_id": "session-altar-recovery",
		"character_id": CHARACTER, "action": "place_building", "action_id": TXN,
		"intent": {"request": request, "record": building, "cost": proposal.cost.duplicate(true)},
		"before": ESSENCE.training_projection(before), "after": ESSENCE.training_projection(proposal.state),
		"receipt": proposal.receipt, "character_revision": 1, "journal_revision": 1, "status": "pending"}

func test_real_paid_altar_three_field_journal_recovers_before_and_after_without_replacing_other_admitted_fields() -> void:
	var before := _before()
	assert_true(RECORD.errors(before, CHARACTER).is_empty())
	var row := _journal(before)
	assert_false(row.is_empty())
	if row.is_empty(): return
	assert_true(WORLD.altar_build_row_valid(row, NAMESPACE))
	assert_eq(row.after.size(), 3)
	assert_false(row.after.has("equipment"))
	var expected := before.duplicate(true)
	for field: String in row.after: expected[field] = row.after[field].duplicate(true)
	for initial: Dictionary in [before, expected]:
		var authority := AUTHORITY.new()
		assert_true(authority.bind_world(NAMESPACE))
		assert_true(authority.seed_admitted_character(initial, CHARACTER).ok)
		var reloaded: Dictionary = JSON.parse_string(JSON.stringify(row))
		var outcome := authority.recover_durable_training(CHARACTER, {reloaded.delivery_id: reloaded})
		assert_true(outcome.get("ok") == true)
		assert_true(outcome.get("pending") == true)
		assert_true(ESSENCE._equivalent(authority.state(CHARACTER), expected))
		for field: String in ["character_id", "equipment", "portal_escrow", "vitals_escrow", "realm_hearts"]:
			assert_eq(authority.state(CHARACTER)[field], initial[field], field)
		assert_eq(authority.revision(CHARACTER), 1)
		assert_true(authority.creature_training_pending_matches(CHARACTER, reloaded))
		assert_false(authority.acknowledge_creature_training(CHARACTER, reloaded), "pending journal is not owner ACK")
		assert_true(authority.creature_training_is_pending(CHARACTER))
		reloaded.status = "accepted"
		assert_true(authority.acknowledge_creature_training(CHARACTER, reloaded))
		assert_false(authority.creature_training_is_pending(CHARACTER))
		assert_true(ESSENCE._equivalent(authority.state(CHARACTER), expected))

func test_invalid_or_conflicting_paid_altar_journal_preserves_original_admitted_state() -> void:
	var before := _before()
	var row := _journal(before)
	assert_false(row.is_empty())
	if row.is_empty(): return
	for defect: String in ["extra_projection_field", "foreign_namespace", "conflicting_inventory"]:
		var authority := AUTHORITY.new()
		assert_true(authority.bind_world(NAMESPACE))
		var initial := before.duplicate(true)
		var candidate := row.duplicate(true)
		if defect == "extra_projection_field": candidate.after.equipment = RECORD.empty_equipment()
		elif defect == "foreign_namespace": candidate.world_namespace = "another-world"
		else:
			var inventory := RULES.inventory_from(initial.inventory)
			inventory.add("wood", 1)
			initial.inventory = RULES.slots(inventory)
		assert_true(authority.seed_admitted_character(initial, CHARACTER).ok)
		assert_false(authority.recover_durable_training(CHARACTER, {candidate.delivery_id: candidate}).ok, defect)
		assert_eq(authority.state(CHARACTER), initial, defect)
		assert_eq(authority.revision(CHARACTER), 0, defect)
		assert_false(authority.creature_training_is_pending(CHARACTER), defect)

func test_real_v2_and_v3_pending_journals_recover_the_exact_full_admitted_projection() -> void:
	const ACTIONS = preload("res://scripts/net/character_action_rules.gd")
	const DELIVERY = preload("res://scripts/net/character_action_delivery.gd")
	const FOUNDATION = preload("res://scripts/net/foundation_actions.gd")
	const FOUNDATION_DELIVERY = preload("res://scripts/net/foundation_delivery.gd")
	var before := _before()
	var context := {"character_id": CHARACTER, "expected_revision": 0, "in_range": true,
		"source_key": "halda_bounty_board", "in_combat": false, "clock_confirmed": true,
		"world_namespace": NAMESPACE, "host_day": 1, "host_unlocks": []}
	var bounty := ACTIONS.stage(before, 0, "bounty_rotate", {}, context, RECORD.errors)
	assert_true(bounty.get("ok") == true)
	if bounty.get("ok") != true: return
	bounty.character_revision = 1
	var v2 := DELIVERY.make_record("slot-altar-recovery", NAMESPACE, "session-altar-recovery", bounty, null, RECORD.errors)
	context.merge({"source_key": "hall_home", "foundation_runtime_authorized": true,
		"grounded_arrival": true, "permit_id": "travel-altar-recovery", "realm": "meadows", "entry_id": "hall_home"}, true)
	var arrival := FOUNDATION.stage(before, 0, "portal_arrival",
		{"permit_id": "travel-altar-recovery", "realm": "meadows", "entry_id": "hall_home"}, context, RECORD.errors)
	assert_true(arrival.get("ok") == true)
	if arrival.get("ok") != true: return
	arrival.character_revision = 1
	var v3 := FOUNDATION_DELIVERY.make_record("slot-altar-recovery", NAMESPACE, "session-altar-recovery", arrival, null, RECORD.errors)
	for row: Dictionary in [v2, v3]:
		assert_false(row.is_empty())
		if row.is_empty(): continue
		assert_true(WORLD.training_row_valid(row, NAMESPACE))
		assert_eq(row.after.size(), RECORD.FIELDS.size())
		var authority := AUTHORITY.new()
		assert_true(authority.bind_world(NAMESPACE))
		assert_true(authority.seed_admitted_character(before, CHARACTER).ok)
		var reloaded: Dictionary = JSON.parse_string(JSON.stringify(row))
		assert_eq(RECORD.training_projection(before, reloaded, ESSENCE.training_projection).size(), RECORD.FIELDS.size(), "JSON version %s" % str(reloaded.version))
		var recovered := authority.recover_durable_training(CHARACTER, {reloaded.delivery_id: reloaded})
		assert_true(recovered.get("ok") == true, "version %s recovery %s" % [str(reloaded.version), str(recovered)])
		for field: String in RECORD.FIELDS:
			assert_true(ESSENCE._equivalent(authority.state(CHARACTER)[field], reloaded.after[field]), field)
		assert_true(authority.creature_training_pending_matches(CHARACTER, reloaded))
		reloaded.status = "accepted"
		assert_true(authority.acknowledge_creature_training(CHARACTER, reloaded))
		assert_false(authority.creature_training_is_pending(CHARACTER))

func test_projection_version_dispatch_preserves_integral_json_versions_without_coercing_invalid_versions() -> void:
	var current := _before()
	for version: Variant in [1, 1.0, 2, 2.0, 3, 3.0]:
		assert_eq(RECORD.training_version({"kind": "creature_training", "version": version}), int(version), str(version))
	for version: Variant in [0, 4, 2.5, 3.5, "2", "3", true, null, INF, NAN]:
		assert_eq(RECORD.training_version({"kind": "creature_training", "version": version}), 0, str(version))
	assert_eq(RECORD.training_version({"kind": "altar_building", "version": 3}), 0, "wrong journal kind")
	for version: Variant in [2, 2.0, 3, 3.0]:
		var row := {"kind": "creature_training", "version": version}
		assert_eq(RECORD.training_projection(current, row, ESSENCE.training_projection), current, str(version))
	for version: Variant in [1, 1.0, 2.5, 3.5, "2", "3", true, null, INF, NAN]:
		var row := {"kind": "creature_training", "version": version}
		assert_eq(RECORD.training_projection(current, row, ESSENCE.training_projection), ESSENCE.training_projection(current), str(version))
	assert_eq(RECORD.training_projection(current, {"kind": "altar_building", "version": 3}, ESSENCE.training_projection),
		ESSENCE.training_projection(current), "kind remains required")
