extends "res://tests/test_case.gd"

## Actual Session retry scan, canonical events/stages/rows and a counted
## admission seam. The writer explicitly refuses: no disk save or ACK claim.
const HARNESS := preload("res://tests/test_foundation_retry_admission.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const MASTERY := preload("res://tests/test_combat_mastery_delivery.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const ORDER := preload("res://scripts/net/foundation_retry_order.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const CHARACTER_ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const CHARACTER_DELIVERY := preload("res://scripts/net/character_action_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const WORLD := preload("res://autoload/world_state.gd")

func _fixture() -> Dictionary:
	return HARNESS.new()._research_fixture(DATA.new()._before())

func _free_fixture(fixture: Dictionary) -> void:
	fixture.session.free()
	fixture.game.free()

func _append_mastery(fixture: Dictionary, action: String) -> Dictionary:
	var before: Dictionary = fixture.authority.state(DATA.CHARACTER)
	var duty: Dictionary = MASTERY.new()._duty(before)
	duty.intent.action_id = action
	duty.context.source_key = "combat_mastery:" + action
	duty.context.outcome.action_id = action
	var event := EVENT.make(fixture.world, "resource-epoch", "mastery:" + action, [duty])
	assert_false(event.is_empty())
	if not event.is_empty(): fixture.world.reward_deliveries[event.delivery_id] = event
	return event

func _append_progression(fixture: Dictionary, action: String, boss: String = "warden_aldis", realm: String = "meadows", biome: String = "meadows") -> Dictionary:
	var before: Dictionary = fixture.authority.state(DATA.CHARACTER)
	var uid: String = before.party[0].uid
	var encounter := "completed-fight"
	var intent := {"trainer_id": boss, "biome": biome, "encounter_id": encounter}
	var context := {"source_key": "boss:" + boss, "realm": realm, "validated_host_outcome": "win",
		"encounter_id": encounter, "participants": [DATA.CHARACTER]}
	var source := "boss:" + boss + ":" + encounter
	if action == "master_win":
		intent = {"master_id": "master_t1", "creature_uid": uid, "encounter_id": encounter}
		context = {"source_key": "master_encounter:" + encounter, "validated_host_outcome": "win",
			"participant_count": 1, "master_id": "master_t1", "creature_uid": uid, "encounter_id": encounter}
		source = "master:" + encounter
	var event := EVENT.make(fixture.world, "resource-epoch", source, [{
		"character_id": DATA.CHARACTER, "action": action, "intent": intent, "context": context}])
	assert_false(event.is_empty())
	if not event.is_empty(): fixture.world.reward_deliveries[event.delivery_id] = event
	return event

func _install_row(fixture: Dictionary, event: Dictionary, status: String) -> Dictionary:
	var before: Dictionary = fixture.authority.state(DATA.CHARACTER)
	var duty: Dictionary = event.duties[0]
	var context: Dictionary = duty.context.duplicate(true)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": 0,
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"retained_event": event.delivery_id, "boss_settlement_world_flags": []})
	# session._retry_foundation_events stages a boss duty in the current world
	# (F19 world-scoped drops), so its accepted receipt carries that namespace.
	if duty.action == "boss_relic": context.world_namespace = fixture.world.reward_delivery_namespace
	var proposal: Dictionary = CHARACTER_ACTIONS.stage(before, 0, duty.action, duty.intent, context, RECORD.errors) \
		if duty.action in CHARACTER_ACTIONS.ACTIONS else ACTIONS.stage(before, 0, duty.action, duty.intent, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return {}
	proposal.character_revision = 1
	var row: Dictionary = CHARACTER_DELIVERY.make_record(fixture.world.world_id, fixture.world.reward_delivery_namespace,
		"resource-epoch", proposal, null, RECORD.errors) if duty.action in CHARACTER_ACTIONS.ACTIONS \
		else DELIVERY.make_record(fixture.world.world_id, fixture.world.reward_delivery_namespace,
			"resource-epoch", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return {}
	row.status = status
	assert_true(WORLD.training_row_valid(row, fixture.world.reward_delivery_namespace, fixture.world.world_id))
	fixture.world.reward_deliveries[row.delivery_id] = row
	var refreshed: Dictionary = fixture.authority.refresh_host_local(row.after, DATA.CHARACTER)
	assert_true(refreshed.get("ok") == true, str(refreshed))
	return row

func test_completed_boss_and_master_precede_190_mastery_originals() -> void:
	for action: String in ["boss_relic", "master_win"]:
		var fixture := _fixture()
		var seed := _append_mastery(fixture, "already-saved-hit")
		var row := _install_row(fixture, seed, "accepted")
		if row.is_empty():
			_free_fixture(fixture)
			continue
		for index: int in 190: _append_mastery(fixture, "unpaid-hit-%d" % index)
		var victory := _append_progression(fixture, action)
		var originals := var_to_bytes(fixture.world.reward_deliveries)
		var baseline: Dictionary = fixture.authority.state(DATA.CHARACTER)
		fixture.session._retry_foundation_events()
		assert_eq(fixture.session.admission_calls, 1, "priority does not project all 190 hit carriers")
		assert_eq(fixture.writer.proposals.size(), 1)
		if fixture.writer.proposals.size() == 1:
			assert_eq(fixture.writer.proposals[0].action, action)
			assert_eq(fixture.writer.proposals[0].host_context.retained_event, victory.delivery_id)
			assert_eq(fixture.writer.proposals[0].expected_character_revision, fixture.authority.revision(DATA.CHARACTER))
		assert_eq(fixture.authority.state(DATA.CHARACTER), baseline, "failed writer rolls back exact current CAS candidate")
		assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals, "all 190 hit originals and the victory remain unchanged")
		_free_fixture(fixture)

func test_pending_original_recovers_before_later_boss_without_new_admission() -> void:
	for pending_action: String in ["combat_mastery", "research_event"]:
		var fixture := _fixture()
		var original: Dictionary
		if pending_action == "research_event":
			_free_fixture(fixture)
			var before: Dictionary = HARNESS.new()._saturated_research_record()
			before.redesign_character.research.species.terrapup.tasks.casts = 2
			fixture = HARNESS.new()._research_fixture(before)
			original = HARNESS.new()._append_research_event(fixture, "pending-third-cast")
		else:
			original = _append_mastery(fixture, "pending-hit")
		var row := _install_row(fixture, original, "pending")
		if row.is_empty():
			_free_fixture(fixture)
			continue
		_append_progression(fixture, "boss_relic")
		var originals := var_to_bytes(fixture.world.reward_deliveries)
		fixture.session._retry_foundation_events()
		assert_eq(fixture.session.admission_calls, 0)
		assert_true(fixture.writer.proposals.is_empty(), "priority cannot replace an unresolved original")
		assert_eq(fixture.writer.rows.size(), 1)
		if fixture.writer.rows.size() == 1: assert_eq(var_to_bytes(fixture.writer.rows[0]), var_to_bytes(row))
		assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
		row.status = "accepted" # Explicit saved-ACK fixture; never a runtime ACK claim.
		fixture.session._retry_foundation_events()
		assert_eq(fixture.session.admission_calls, 1, "next scan checks accepted status freshly")
		assert_eq(fixture.writer.proposals.size(), 1)
		if fixture.writer.proposals.size() == 1: assert_eq(fixture.writer.proposals[0].action, "boss_relic")
		assert_eq(fixture.writer.rows.size(), 1, "accepted original is not redelivered")
		_free_fixture(fixture)

func test_accepted_progression_does_not_starve_remaining_mastery() -> void:
	for action: String in ["boss_relic", "master_win"]:
		var fixture := _fixture()
		var victory := _append_progression(fixture, action)
		var row := _install_row(fixture, victory, "accepted")
		if row.is_empty():
			_free_fixture(fixture)
			continue
		_append_mastery(fixture, "remaining-hit")
		var originals := var_to_bytes(fixture.world.reward_deliveries)
		fixture.session._retry_foundation_events()
		assert_eq(fixture.session.admission_calls, 1, "accepted victory is excluded before projection")
		assert_eq(fixture.writer.proposals.size(), 1)
		if fixture.writer.proposals.size() == 1: assert_eq(fixture.writer.proposals[0].action, "combat_mastery")
		assert_true(fixture.writer.rows.is_empty())
		assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
		_free_fixture(fixture)

func test_unsettled_boss_ceremony_preserves_ordinary_mastery_progress() -> void:
	var fixture := _fixture()
	var seed := _append_mastery(fixture, "saved-before-ceremony")
	var row := _install_row(fixture, seed, "accepted")
	if row.is_empty():
		_free_fixture(fixture)
		return
	_append_mastery(fixture, "ordinary-unpaid-hit")
	_append_progression(fixture, "boss_relic", "captain_marrow_dynamo_core", "stormwood", "stormwood")
	var originals := var_to_bytes(fixture.world.reward_deliveries)
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 1)
	assert_eq(fixture.writer.proposals.size(), 1)
	if fixture.writer.proposals.size() == 1: assert_eq(fixture.writer.proposals[0].action, "combat_mastery")
	assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
	_free_fixture(fixture)

func test_missing_invalid_or_foreign_latest_keeps_original_order() -> void:
	var fixture := _fixture()
	var hit := _append_mastery(fixture, "first-original-hit")
	var row := _install_row(fixture, hit, "accepted")
	if row.is_empty():
		_free_fixture(fixture)
		return
	var victory := _append_progression(fixture, "boss_relic")
	for defect: String in ["missing", "invalid", "foreign_namespace", "pending"]:
		var latest: Dictionary = row.duplicate(true)
		match defect:
			"missing": fixture.world.reward_deliveries.erase(row.delivery_id)
			"invalid": latest.after.inventory = []
			"foreign_namespace": latest.world_namespace = "foreign-world"
			"pending": latest.status = "pending"
		if defect != "missing": fixture.world.reward_deliveries[row.delivery_id] = latest
		var originals := var_to_bytes(fixture.world.reward_deliveries)
		var ordered := ORDER.ordered(fixture.world.reward_deliveries, fixture.world.reward_delivery_namespace, fixture.world.world_id)
		assert_eq(ordered.size(), 2)
		if ordered.size() == 2:
			assert_eq(ordered[0].event.delivery_id, hit.delivery_id, defect)
			assert_eq(ordered[1].event.delivery_id, victory.delivery_id, defect)
		assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
	_free_fixture(fixture)

func test_priority_is_stable_and_preserves_exact_event_and_duty_references() -> void:
	var fixture := _fixture()
	var hit := _append_mastery(fixture, "first-saved-hit")
	var row := _install_row(fixture, hit, "accepted")
	if row.is_empty():
		_free_fixture(fixture)
		return
	var master := _append_progression(fixture, "master_win")
	var ordinary := _append_mastery(fixture, "middle-unpaid-hit")
	var boss := _append_progression(fixture, "boss_relic")
	var originals := var_to_bytes(fixture.world.reward_deliveries)
	var ordered := ORDER.ordered(fixture.world.reward_deliveries, fixture.world.reward_delivery_namespace, fixture.world.world_id)
	assert_eq(ordered.size(), 4)
	if ordered.size() == 4:
		for index: int in 4:
			var expected: Dictionary = [master, boss, hit, ordinary][index]
			assert_true(is_same(ordered[index].event, expected))
			assert_true(is_same(ordered[index].duty, expected.duties[0]))
	assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
	_free_fixture(fixture)
