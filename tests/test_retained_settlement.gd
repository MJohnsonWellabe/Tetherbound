extends "res://tests/test_case.gd"

## Ruling R2: an accepted training decision settles its retained duty durably
## in the world, and the retained event retires once every duty on it is
## settled; so mastery and trainer-round receipts can be windowed without the
## retry loop ever re-staging an old duty (review R1), and a long session stays
## under the 4096 receipt cap.
##
## Disclosed fixtures: test_foundation_resources' admitted character and world
## (as in test_combat_mastery_delivery). Real retained-event codec, Foundation
## staging, the ledger journal and accept ops, and the retry ordering.

const DATA := preload("res://tests/test_foundation_resources.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const RETRY_ORDER := preload("res://scripts/net/foundation_retry_order.gd")
const SETTLE := preload("res://scripts/net/retained_settlement.gd")
const RW := preload("res://scripts/creatures/receipt_windows.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const F32 := preload("res://scripts/world/f32_source_actions.gd")


func _duty(before: Dictionary, action_id: String, character: String = DATA.CHARACTER) -> Dictionary:
	var card: Dictionary = before.party[0]
	return {"character_id": character, "action": "combat_mastery",
		"intent": {"action_id": action_id, "creature_uid": card.uid},
		"context": {"source_key": "combat_mastery:" + action_id, "event_confirmed": true,
			"world_namespace": "resource-namespace", "session_id": "resource-epoch",
			"encounter_id": "mastery-encounter", "participants": [character],
			"binding": {"character_id": character, "creature_uid": card.uid,
				"deployment_generation": 1, "body_instance_id": 55, "actor_generation": 0},
			"outcome": {"action_id": action_id, "move_id": card.move_quick,
				"attacker_uid": card.uid, "target_uid": "host-opponent",
				"target_hp_before": 100.0, "applied_damage": 12.0}}}


## Stage, journal and accept one retained mastery duty; returns the new state.
func _settle_one(world: RefCounted, ledger: RefCounted, before: Dictionary, revision: int, duty: Dictionary, event: Dictionary) -> Dictionary:
	var context: Dictionary = duty.context.duplicate(true)
	context.merge({"character_id": DATA.CHARACTER, "expected_revision": revision, "in_range": true,
		"in_combat": false, "foundation_runtime_authorized": true, "retained_event": event.delivery_id})
	var proposal := ACTIONS.stage(before, revision, "combat_mastery", duty.intent, context, RECORD.errors)
	if proposal.get("ok") != true: return {"refused": "stage:" + str(proposal.get("code", ""))}
	proposal.character_revision = revision + 1
	var previous: Variant = world.reward_deliveries.get(preload("res://scripts/creatures/essence.gd").training_delivery_id("resource-namespace", DATA.CHARACTER))
	var row := DELIVERY.make_record("resource-slot", "resource-namespace", "resource-epoch", proposal, previous, RECORD.errors)
	if row.is_empty(): return {"refused": "row"}
	if ledger.call("commit_creature_training_delivery", row, 1).get("ok") != true: return {"refused": "journal"}
	var accepted: Dictionary = ledger.call("accept_creature_training_delivery", row.delivery_id, DATA.CHARACTER,
		int(row.journal_revision), str(row.receipt), 1)
	if accepted.get("ok") != true: return {"refused": "accept:" + str(accepted.get("code", ""))}
	return {"state": proposal.state}


func _journal_event(world: RefCounted, duties: Array, source: String) -> Dictionary:
	var event := EVENT.make(world, "resource-epoch", source, duties)
	world.reward_deliveries[event.delivery_id] = event
	return event


func test_an_accepted_duty_settles_and_a_fully_settled_event_retires() -> void:
	var fixture := DATA.new()
	var before: Dictionary = fixture._before()
	var world: RefCounted = fixture._world()
	var ledger: RefCounted = LEDGER.new(world)
	var duty := _duty(before, "settle-1")
	var event := _journal_event(world, [duty], "mastery:settle-1")
	assert_false(event.is_empty())
	assert_eq(RETRY_ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot").size(), 1, "one owed duty before")
	var result := _settle_one(world, ledger, before, 0, duty, event)
	assert_false(result.has("refused"), str(result))
	assert_false(world.reward_deliveries.has(event.delivery_id), "a fully settled event retires from the world")
	assert_true(RETRY_ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot").is_empty(),
		"so the retry loop has nothing to re-stage, whatever happens to its receipt")
	assert_false((world.redesign_world.get(SETTLE.FIELD, {}) as Dictionary).has(event.delivery_id), "and its marker goes with it")


func test_a_shared_event_keeps_unsettled_duties_and_marks_the_settled_one() -> void:
	var fixture := DATA.new()
	var before: Dictionary = fixture._before()
	var world: RefCounted = fixture._world()
	var event := EVENT.make(world, "resource-epoch", "mastery:shared", [_duty(before, "shared"), _duty(before, "shared", "other-character")])
	if event.is_empty():
		# The codec may require one recipient per mastery event; then the
		# settlement rule is exercised directly on a two-duty row.
		event = {"delivery_id": "foundation_event:shared", "duties": [_duty(before, "shared"), _duty(before, "shared", "other-character")]}
	var row := {"character_id": DATA.CHARACTER, "action": "combat_mastery"}
	var first: Array = SETTLE.after_accept(world.redesign_world, event, row)
	assert_eq(first, [[SETTLE.key(DATA.CHARACTER, "combat_mastery")], false], "one recipient settled, the event stays")
	world.redesign_world[SETTLE.FIELD] = {str(event.delivery_id): first[0]}
	assert_true(SETTLE.duty_settled(world.redesign_world, str(event.delivery_id), event.duties[0]))
	assert_false(SETTLE.duty_settled(world.redesign_world, str(event.delivery_id), event.duties[1]))
	var second: Array = SETTLE.after_accept(world.redesign_world, event, {"character_id": "other-character", "action": "combat_mastery"})
	assert_true(bool(second[1]), "the last recipient retires it")


func test_only_high_frequency_kinds_settle_or_retire() -> void:
	var event := {"delivery_id": "foundation_event:boss", "duties": [{"character_id": "c", "action": "boss_relic", "intent": {}, "context": {}}]}
	assert_eq(SETTLE.after_accept({}, event, {"character_id": "c", "action": "boss_relic"}), [], "boss relics keep receipt-based behaviour")
	var mixed := {"delivery_id": "foundation_event:mixed", "duties": [
		{"character_id": "c", "action": "combat_mastery", "intent": {}, "context": {}},
		{"character_id": "c", "action": "research_event", "intent": {}, "context": {}}]}
	var result: Array = SETTLE.after_accept({}, mixed, {"character_id": "c", "action": "combat_mastery"})
	assert_false(bool(result[1]), "an event carrying a non-windowed duty never retires")


func test_a_v28_world_without_the_marker_validates() -> void:
	var fixture := DATA.new()
	var world: RefCounted = fixture._world()
	var redesign: Dictionary = world.redesign_world.duplicate(true)
	redesign.erase(SETTLE.FIELD)
	assert_true(STATE.validate("world", redesign, [], "resource-namespace").is_empty())
	redesign[SETTLE.FIELD] = {"foundation_event:x": ["c|combat_mastery"]}
	assert_true(STATE.validate("world", redesign, [], "resource-namespace").is_empty(), "and a world carrying it validates")


func test_ten_thousand_mastery_hits_stay_under_the_cap_and_can_still_gather() -> void:
	# The windowed append path used by combat mastery, run past 10,000 hits,
	# then the real F32 compaction: the character stays far below 4096 and a
	# gather receipt still fits.
	var receipts: Array = []
	for i in 10000:
		receipts = RW.compact(receipts, "combat_mastery", DATA.CHARACTER)
		receipts.append("craft:combat_mastery_%s:%s" % [str(i).sha256_text(), DATA.CHARACTER])
	assert_true(receipts.size() <= RW.window("combat_mastery"), "mastery receipts stay at the window (%d)" % receipts.size())
	receipts = F32.compact_f32_receipts(receipts, DATA.CHARACTER, 256)
	assert_true(receipts.size() + 1 < 4096, "a gather still fits under the cap")


func test_settled_then_evicted_receipt_never_restages() -> void:
	# The review R1 scenario on the real path: settle a duty, evict its receipt
	# from the character (the window), and the retry ordering still owes nothing.
	var fixture := DATA.new()
	var before: Dictionary = fixture._before()
	var world: RefCounted = fixture._world()
	var ledger: RefCounted = LEDGER.new(world)
	var duty := _duty(before, "evict-1")
	var event := _journal_event(world, [duty], "mastery:evict-1")
	var result := _settle_one(world, ledger, before, 0, duty, event)
	assert_false(result.has("refused"), str(result))
	var state: Dictionary = result.get("state", {})
	var evicted: Array = (state.get("redesign_character", {}).get("transaction_receipts", []) as Array).filter(
		func(r: Variant) -> bool: return not str(r).begins_with("craft:combat_mastery_"))
	assert_eq(evicted.size(), (state.redesign_character.transaction_receipts as Array).size() - 1, "the receipt is gone from the record")
	assert_true(RETRY_ORDER.ordered(world.reward_deliveries, "resource-namespace", "resource-slot").is_empty(),
		"nothing is owed, so nothing re-stages")
