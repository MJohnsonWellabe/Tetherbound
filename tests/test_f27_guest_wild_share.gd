extends "res://tests/test_case.gd"

## F27 guest share of a host wild victory.
## - wild_actor_scope.gd: the encounter-keyed scope under which a guest's
##   creature vitals are host-owned in a canonical wild fight (never a trainer
##   round scope, so round rewards can never double the wild XP);
## - its settled_before, applied wherever trainer rounds apply theirs;
## - FoundationActions `wild_defeat`, which session._journal_guest_wild_defeats
##   retains per guest and the retry scan commits.
const E := preload("res://scripts/creatures/essence.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const WILD := preload("res://scripts/net/wild_actor_scope.gd")
const ROUND := preload("res://scripts/net/combat_round_reward.gd")
const INVENTORY := preload("res://scripts/world/death_satchel_rules.gd")
const CHARACTER := "f27-share-guest"
const NAMESPACE := "f27-share-world"
const EPOCH := "f27-share-epoch"


func _admitted() -> Dictionary:
	var player := preload("res://autoload/player_state.gd").new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	for species: String in ["terrapup", "bramblebun"]:
		var card: RefCounted = SPECIES.spawn(species)
		player.party.add(card)
		card.set("level", 5)
		card.call("_apply_level_stats", PROGRESSION.config())
	var record := RECORD.portable_projection(player.save_data())
	assert_eq(RECORD.errors(record, CHARACTER), [], "canonical admitted record")
	return record


## Host-saved fight vitals: the active card took `damage`; the bench card is unbound.
func _vitals(record: Dictionary, damage: float) -> Array:
	var active: Dictionary = record.party[0]
	var hp := maxf(0.0, float(active.hp) - damage)
	var member := {"actor_vitals": {active.uid: {"hp": hp, "max_hp": active.max_hp, "fainted": hp == 0.0, "body_generation": 2}}}
	return WILD.settled_vitals(record, member)


func _event(settled: Dictionary) -> Dictionary:
	var wild := preload("res://autoload/player_state.gd").new()
	wild.configure(preload("res://autoload/item_db.gd").new())
	wild.character_id = "wild"
	wild.party.add(SPECIES.spawn("bramblebun"))
	var enemy: Dictionary = RECORD.portable_projection(wild.save_data()).party[0]
	enemy.uid = "wild-share-enemy"
	enemy.level = 4
	enemy.hp = 0
	enemy.fainted = true
	var eligible: Array = []
	for card: Dictionary in settled.party:
		if not card.fainted: eligible.append(card.uid)
	var event := {"event_id": "wild_defeat:" + "ab".repeat(32), "world_namespace": NAMESPACE, "encounter_id": "enc-share",
		"enemy_uid": enemy.uid, "enemy_record": enemy, "active_uid": settled.party[1].uid if settled.party[0].fainted else settled.party[0].uid,
		"eligible_uids": eligible, "kind": "wild_defeat", "xp_mode": "hybrid", "realm": "meadows", "shed": {}}
	event.shed = E.defeat_shed(event, CHARACTER)
	return event


func _duty(event: Dictionary, vitals: Array) -> Dictionary:
	var source := "wild_xp:" + str(event.event_id)
	return {"character_id": CHARACTER, "action": "wild_defeat_share", "intent": event.duplicate(true),
		"context": {"source_key": source, "validated_host_outcome": "win", "defeat_event": event.duplicate(true),
			"settled_vitals": vitals.duplicate(true), "participants": ["f27-share-host", CHARACTER],
			"world_namespace": NAMESPACE, "session_id": EPOCH}}


func _row(duties: Array, source: String) -> Dictionary:
	var row := {"version": 1, "kind": "foundation_event", "world_id": "f27-share-world-id", "world_namespace": NAMESPACE,
		"session_id": EPOCH, "source_id": source, "duties": duties, "status": "retained"}
	row.delivery_id = EVENT.identity(row)
	return row


## Exactly the context the retry scan builds before staging a retained duty.
func _context(duty: Dictionary, revision: int) -> Dictionary:
	var context: Dictionary = duty.context.duplicate(true)
	context.character_id = CHARACTER
	context.expected_revision = revision
	context.in_range = true
	context.retained_event = "foundation_event:retained"
	context.in_combat = false
	context.foundation_runtime_authorized = true
	return context


func test_wild_scope_is_never_a_trainer_round_scope() -> void:
	var scope := WILD.make(NAMESPACE, EPOCH, "meadows", "enc-share")
	assert_true(WILD.scope_valid(scope), "a wild scope for one encounter")
	assert_false(ROUND.scope_valid(scope), "it can never install trainer round rewards")
	var record := {"encounter_id": "enc-share", "kind": "wild", "realm": "meadows", "opponent": {"owner_npc": ""}}
	assert_true(WILD.owns(scope, record, "enc-share"))
	assert_false(WILD.owns(scope, record, "enc-other"), "keyed by its encounter")
	var trainer := record.duplicate(true)
	trainer.kind = "trainer"
	trainer.opponent.owner_npc = "ranger_ada"
	assert_false(WILD.owns(scope, trainer, "enc-share"), "never a trainer fight")
	assert_true(WILD.make(NAMESPACE, EPOCH, "not-a-realm", "enc-share").is_empty())


func test_settlement_applies_host_saved_hp_and_faint_only() -> void:
	var before := _admitted()
	var hurt := WILD.settled_before(before, {"settled_vitals": _vitals(before, 7.5)})
	assert_eq(float(hurt.party[0].hp), float(before.party[0].hp) - 7.5, "the saved HP is applied")
	assert_eq(hurt.party[1], before.party[1], "an unbound bench card is untouched")
	var down := WILD.settled_before(before, {"settled_vitals": _vitals(before, 100000.0)})
	assert_true(down.party[0].fainted == true and float(down.party[0].hp) == 0.0, "a saved knockout faints the card")
	var lying := _vitals(before, 0.0)
	lying[1].hp = 1.0 # Unbound card claiming a changed HP.
	assert_eq(WILD.settled_before(before, {"settled_vitals": lying}), {}, "an unbound card cannot change")
	var short := _vitals(before, 1.0)
	short.pop_back()
	assert_eq(WILD.settled_before(before, {"settled_vitals": short}), {}, "every owned card is accounted for")
	var bigger := _vitals(before, 1.0)
	bigger[0].max_hp = float(bigger[0].max_hp) + 1.0
	assert_eq(WILD.settled_before(before, {"settled_vitals": bigger}), {}, "max HP never changes")


func test_retained_share_duty_validates_and_rejects_tampering() -> void:
	var before := _admitted()
	var vitals := _vitals(before, 3.0)
	var duty := _duty(_event(WILD.settled_before(before, {"settled_vitals": vitals})), vitals)
	var source: String = duty.context.source_key
	assert_true(EVENT.valid(_row([duty], source), NAMESPACE, "f27-share-world-id"), "a host-built share is a valid retained duty")
	assert_false(EVENT.valid(_row([duty], "wild_xp:other"), NAMESPACE, "f27-share-world-id"), "source names the event")
	var forged := duty.duplicate(true)
	forged.intent.eligible_uids = ["someone-else"]
	assert_false(EVENT.valid(_row([forged], source), NAMESPACE, "f27-share-world-id"), "intent equals the frozen event")
	var outsider := duty.duplicate(true)
	outsider.context.participants = ["f27-share-host"]
	assert_false(EVENT.valid(_row([outsider], source), NAMESPACE, "f27-share-world-id"), "only an actual participant")
	var unsettled := duty.duplicate(true)
	unsettled.context.erase("settled_vitals")
	assert_false(EVENT.valid(_row([unsettled], source), NAMESPACE, "f27-share-world-id"), "the settled vitals are frozen in the duty")


func test_share_pays_once_on_the_settled_record_with_battle_credit_and_mood() -> void:
	var before := _admitted()
	var vitals := _vitals(before, 4.0)
	var settled := WILD.settled_before(before, {"settled_vitals": vitals})
	var event := _event(settled)
	var duty := _duty(event, vitals)
	var staged := ACTIONS.stage(before, 3, "wild_defeat_share", duty.intent, _context(duty, 3), RECORD.errors)
	assert_true(staged.get("ok") == true, str(staged))
	assert_eq(float(staged.state.party[0].hp), float(settled.party[0].hp), "the saved fight HP stands")
	assert_eq(int(staged.state.party[0].battles_fought), int(before.party[0].battles_fought) + 1, "one battle credited")
	assert_true(float(staged.state.party[0].happiness) >= float(before.party[0].happiness), "victory mood")
	var essence_before: int = INVENTORY.inventory_from(before.inventory).count("essence_ground")
	assert_eq(INVENTORY.inventory_from(staged.state.inventory).count("essence_ground"), essence_before + 1, "one Ground Essence")
	assert_true(staged.state.redesign_character.transaction_receipts.has(E.defeat_receipt(CHARACTER, event)),
		"the retry scan's receipt is the staged one")
	var again := ACTIONS.stage(staged.state, 4, "wild_defeat_share", duty.intent, _context(duty, 4), RECORD.errors)
	assert_false(again.get("ok") == true, "an applied share never pays twice")


func test_a_creature_knocked_out_in_the_fight_earns_no_share() -> void:
	var before := _admitted()
	var vitals := _vitals(before, 100000.0)
	var settled := WILD.settled_before(before, {"settled_vitals": vitals})
	var event := _event(settled)
	assert_false((event.eligible_uids as Array).has(before.party[0].uid), "the fainted active is not eligible")
	var duty := _duty(event, vitals)
	var staged := ACTIONS.stage(before, 3, "wild_defeat_share", duty.intent, _context(duty, 3), RECORD.errors)
	assert_true(staged.get("ok") == true, str(staged))
	assert_eq(staged.state.party[0].xp, settled.party[0].xp, "no XP for the fainted card")
	assert_true(staged.state.party[0].fainted == true, "it stays fainted")


func test_owner_plan_accepts_only_the_owner_holding_the_settled_vitals() -> void:
	var before := _admitted()
	var vitals := _vitals(before, 5.0)
	var settled := WILD.settled_before(before, {"settled_vitals": vitals})
	var duty := _duty(_event(settled), vitals)
	var context := _context(duty, 3)
	var staged := ACTIONS.stage(before, 3, "wild_defeat_share", duty.intent, context, RECORD.errors)
	var row := {"before": before, "after": staged.state, "host_context": context, "receipt": staged.receipt, "status": "pending"}
	var plan := WILD.owner_plan(settled, row)
	assert_true(plan.get("ok") == true and plan.get("duplicate") == false, "the owner already holds its saved HP " + str(plan))
	assert_eq(WILD.owner_plan(before, row).get("code"), "owner_action_baseline_conflict", "an unsettled owner is not this row's baseline")
	assert_true(WILD.owner_plan(staged.state, row).get("duplicate") == true, "a saved owner is a duplicate, never a second award")


func test_share_action_requires_the_host_frozen_win() -> void:
	var before := _admitted()
	var vitals := _vitals(before, 1.0)
	var duty := _duty(_event(WILD.settled_before(before, {"settled_vitals": vitals})), vitals)
	var context := _context(duty, 3)
	context.validated_host_outcome = "draw"
	assert_eq(ACTIONS.stage(before, 3, "wild_defeat_share", duty.intent, context, RECORD.errors).get("code"), "actual_host_wild_defeat_required")
	var swapped: Dictionary = duty.intent.duplicate(true)
	swapped.xp_mode = "ordinary"
	assert_eq(ACTIONS.stage(before, 3, "wild_defeat_share", swapped, _context(duty, 3), RECORD.errors).get("code"), "actual_host_wild_defeat_required",
		"the packet intent cannot differ from the frozen event")
	context = _context(duty, 3)
	context.in_combat = true
	assert_false(ACTIONS.stage(before, 3, "wild_defeat_share", duty.intent, context, RECORD.errors).get("ok") == true, "never mid-combat")


## A v1 row (Altar spend, host wild defeat) after a v2/v3 action row (this
## share, a research duty) journals: the previous row is validated as its own
## version and only orders the new one (essence.next_training_delivery).
func test_a_v1_training_row_follows_an_accepted_v3_action_row() -> void:
	var before := _admitted()
	var vitals := _vitals(before, 2.0)
	var duty := _duty(_event(WILD.settled_before(before, {"settled_vitals": vitals})), vitals)
	var staged := ACTIONS.stage(before, 3, "wild_defeat_share", duty.intent, _context(duty, 3), RECORD.errors)
	var accepted: Dictionary = staged.duplicate(true)
	accepted.character_revision = 4
	var share_row := preload("res://scripts/net/foundation_delivery.gd").make_record("f27-share-world-id", NAMESPACE, EPOCH,
		accepted, null, RECORD.errors)
	assert_false(share_row.is_empty(), "a valid v3 share row")
	share_row.status = "accepted"
	var teaching := preload("res://scripts/creatures/teaching.gd")
	var after: Dictionary = staged.state
	var essence_stock := INVENTORY.inventory_from(after.inventory)
	essence_stock.add("essence_ground", 50)
	after.inventory = INVENTORY.slots(essence_stock)
	var intent := {"spend_id": "0123456789abcdef0123456789abcdef", "creature_uid": after.party[1].uid,
		"expected_level": int(after.party[1].level), "payment_item": "essence_ground", "expected_character_revision": 4}
	var spend := E.stage_core_spend(after, CHARACTER, 4, intent, E.config(), PROGRESSION.config(),
		teaching.available_moves, teaching.character_loadout_mirror)
	assert_true(spend.get("ok") == true, str(spend))
	var next := {"character_id": CHARACTER, "character_revision": 5, "before": after, "state": spend.state,
		"intent": intent, "action": "altar_spend", "action_id": intent.spend_id, "receipt": spend.receipt}
	var row := E.next_training_delivery("f27-share-world-id", NAMESPACE, "f27-session", next, share_row,
		E.config(), PROGRESSION.config(), teaching.available_moves, teaching.character_loadout_mirror)
	assert_false(row.is_empty(), "the Altar spend journals after the accepted share")
	assert_eq(int(row.get("journal_revision", 0)), int(share_row.journal_revision) + 1, "ordered after it")
