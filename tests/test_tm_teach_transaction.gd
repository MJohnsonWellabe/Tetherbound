extends "res://tests/test_case.gd"

## Canonical paid knowledge staging, existing registry rollback/JSON journal
## recovery, and detached UI transport controls. No network/native-save claim.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const CHARACTER := "tm-owner"
const NAMESPACE := "tm-world"
const TEACH_ID := "0123456789abcdef0123456789abcdef"

func _player() -> RefCounted:
	var player := PLAYER.new()
	player.configure(preload("res://autoload/item_db.gd").new())
	player.character_id = CHARACTER
	player.party.add(SPECIES.spawn("terrapup"))
	player.party.add(SPECIES.spawn("terrapup"))
	player.inventory.add("tm_burrow_strike", 1)
	return player

func _before() -> Dictionary:
	var player := _player()
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return RECORD.portable_projection(saved)

func _intent(before: Dictionary) -> Dictionary:
	return {"creature_uid": before.party[1].uid, "tm_id": "tm_burrow_strike", "teach_id": TEACH_ID}

func _context(revision: int = 0) -> Dictionary:
	return {"character_id": CHARACTER, "expected_revision": revision, "source_key": "personal_tm:" + CHARACTER,
		"in_range": true, "in_combat": false, "owns_character": true, "foundation_runtime_authorized": true}

func test_tm_stage_consumes_one_disc_teaches_only_chosen_uid_and_preserves_every_equipped_and_mastery_field() -> void:
	var before := _before()
	assert_true(RECORD.errors(before, CHARACTER).is_empty())
	var frozen := before.duplicate(true)
	var proposal := ACTIONS.stage(before, 0, "tm_teach", _intent(before), _context(), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return
	assert_eq(before, frozen, "canonical planner must not mutate admitted source")
	assert_false(proposal.get("durable"))
	assert_false(proposal.get("resolved"))
	assert_eq(proposal.state.party[0], before.party[0], "unselected UID unchanged")
	var expected := before.duplicate(true)
	expected.party[1].known_moves.append("burrow_strike")
	for index: int in expected.inventory.size():
		if expected.inventory[index] is Dictionary and expected.inventory[index].id == "tm_burrow_strike": expected.inventory[index] = null
	expected.redesign_character = TEACHING.character_loadout_mirror(expected.party, expected.redesign_character)
	expected.redesign_character.transaction_receipts.append(proposal.receipt)
	assert_eq(proposal.state, expected, "only exact knowledge, one disc, mirrored knowledge and original receipt change")
	assert_eq(proposal.intent, _intent(before))
	assert_true(proposal.receipt.contains(before.party[1].uid))
	assert_true(proposal.receipt.contains(TEACH_ID))
	assert_false(ACTIONS.stage(proposal.state, 1, "tm_teach", _intent(before), _context(1), RECORD.errors).ok, "same receipt must reconcile")
	var fresh := _intent(before)
	fresh.teach_id = "ffffffffffffffffffffffffffffffff"
	assert_eq(ACTIONS.stage(proposal.state, 1, "tm_teach", fresh, _context(1), RECORD.errors).code, "already_known", "knowledge duplicate even while old quick remains equipped")

func test_tm_refuses_foreign_target_bad_intent_missing_disc_combat_and_stale_revision_without_mutation() -> void:
	var before := _before()
	for defect: String in ["foreign_uid", "unknown_tm", "wrong_type_tm", "extra_field", "fraction_id", "missing_disc", "combat", "foreign_owner", "stale_revision", "missing_authorization"]:
		var current := before.duplicate(true)
		var intent := _intent(current)
		var context := _context()
		match defect:
			"foreign_uid": intent.creature_uid = "another-character-creature"
			"unknown_tm": intent.tm_id = "tm_unknown"
			"wrong_type_tm": intent.tm_id = "tm_fireball"
			"extra_field": intent.price = 0
			"fraction_id": intent.teach_id = 1.5
			"missing_disc": current.inventory = preload("res://scripts/world/death_satchel_rules.gd").slots(preload("res://scripts/world/death_satchel_rules.gd").inventory_from([]))
			"combat": context.in_combat = true
			"foreign_owner": context.character_id = "someone-else"
			"stale_revision": context.expected_revision = 1
			"missing_authorization": context.foundation_runtime_authorized = false
		var frozen := current.duplicate(true)
		assert_false(ACTIONS.stage(current, 0, "tm_teach", intent, context, RECORD.errors).ok, defect)
		assert_eq(current, frozen, defect)

func test_tm_existing_registry_failed_world_write_rolls_back_then_original_json_row_recovers_and_requires_owner_ack() -> void:
	var before := _before()
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world(NAMESPACE))
	assert_true(authority.seed_admitted_character(before, CHARACTER).ok)
	var staged := authority.stage_character_action(CHARACTER, 0, "tm_teach", _intent(before), _context())
	assert_true(staged.ok)
	if not staged.ok: return
	assert_true(authority.finish_creature_training(staged, false), "bool world writer refusal restores original knowledge/disc/revision")
	assert_eq(authority.state(CHARACTER), before)
	assert_eq(authority.revision(CHARACTER), 0)
	staged = authority.stage_character_action(CHARACTER, 0, "tm_teach", _intent(before), _context())
	assert_true(staged.ok)
	if not staged.ok: return
	var row := DELIVERY.make_record("tm-slot", NAMESPACE, "tm-session", staged, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	var restored: Dictionary = JSON.parse_string(JSON.stringify(row))
	assert_true(DELIVERY.valid(restored, RECORD.errors, CHARACTER, NAMESPACE, "tm-slot"))
	var restarted := AUTHORITY.new()
	assert_true(restarted.bind_world(NAMESPACE))
	assert_true(restarted.seed_admitted_character(before, CHARACTER).ok)
	assert_true(restarted.recover_durable_training(CHARACTER, {restored.delivery_id: restored}).ok)
	assert_true(ESSENCE._equivalent(restarted.state(CHARACTER), row.after))
	assert_false(restarted.acknowledge_creature_training(CHARACTER, restored), "pending row never means BOOL owner saved")
	assert_false(restarted.stage_character_action(CHARACTER, 1, "tm_teach", _intent(before), _context(1)).ok)
	var first := DELIVERY.owner_plan(before, restored, RECORD.errors)
	assert_true(first.ok and first.requires_owner_save)
	var repeat := DELIVERY.owner_plan(first.state, restored, RECORD.errors)
	assert_true(repeat.ok and repeat.duplicate and repeat.requires_owner_save, "failed owner write retries original after-state without second disc/knowledge grant")
	assert_true(ESSENCE._equivalent(first.state, repeat.state))
	restored.status = "accepted"
	assert_true(restarted.acknowledge_creature_training(CHARACTER, restored))
	assert_false(restarted.creature_training_is_pending(CHARACTER))
	var forged := row.duplicate(true)
	forged.after.party[0].known_moves.append("burrow_strike")
	assert_false(DELIVERY.valid(forged, RECORD.errors), "journal cannot change chosen UID")

class ProducerDouble extends Node:
	signal homestead_action_completed(action: String, original: Dictionary, result: Dictionary)
	var action := "tm_teach"
	var pouch_scope := {"character_id": CHARACTER, "world_namespace": NAMESPACE, "session_epoch": "tm-session"}
	var original := {"creature_uid": "saved-uid", "tm_id": "tm_burrow_strike", "teach_id": TEACH_ID}
	var submissions: Array[Dictionary] = []
	func retained_training_transaction(actions: Array) -> Dictionary:
		return {"action": action, "intent": original.duplicate(true), "original_revision": 7, "status": "pending"} if actions.has(action) else {}
	func personal_tm_scope() -> Dictionary:
		return {"character_id": CHARACTER, "world_namespace": NAMESPACE, "session_epoch": "tm-session"}
	func homestead_personal_view() -> Dictionary: return {"registry_revision": 99}
	func personal_tm_submit(intent: Dictionary, revision: int, scope: Dictionary) -> Dictionary:
		submissions.append({"intent": intent.duplicate(true), "revision": revision, "scope": scope.duplicate(true)})
		return {"ok": false, "durable": true, "resolved": false, "code": "awaiting_saved_decision"}
	func personal_pouch_scope() -> Dictionary: return pouch_scope.duplicate(true)
	func personal_pouch_available() -> bool: return true
	func personal_pouch_submit(intent: Dictionary, revision: int, scope: Dictionary) -> Dictionary:
		return personal_tm_submit(intent, revision, scope)

class GameDouble extends Node:
	var session: Node

class MenuDouble extends Node:
	var game: Node
	var message := ""
	func say(value: String) -> void: message = value

func test_backpack_restarts_original_tm_intent_and_never_reports_unsaved_or_unacknowledged_success() -> void:
	var producer := ProducerDouble.new()
	var game := GameDouble.new()
	game.session = producer
	var menu := MenuDouble.new()
	menu.game = game
	var tab := preload("res://scripts/ui/tab_backpack.gd").new()
	tab.menu = menu
	tab._poll_tm_transaction()
	assert_eq(producer.submissions.size(), 1)
	assert_eq(producer.submissions[0].intent, producer.original)
	assert_eq(producer.submissions[0].revision, 7, "restart uses saved original, not fresh revision 99")
	assert_eq(tab._tm_intent, producer.original)
	var actual_policy := preload("res://scripts/net/session.gd").new()
	var world_failed: Dictionary = actual_policy._foundation_journal_refusal("tm_teach", {"ok": false, "durable": false, "code": "training_journal_failed"})
	assert_false(world_failed.resolved)
	assert_false(world_failed.terminal_refusal)
	producer.homestead_action_completed.emit("tm_teach", producer.original, world_failed)
	assert_eq(tab._tm_intent, producer.original, "actual BOOL world-write refusal must retain teach ID/revision/scope")
	assert_false(menu.message.begins_with("Learned"))
	assert_true(actual_policy._foundation_journal_refusal("station_craft", {"code": "training_journal_failed"}).terminal_refusal, "other action policy unchanged")
	assert_true(actual_policy._foundation_journal_refusal("tm_teach", {"code": "invalid_training_journal"}).terminal_refusal, "semantic journal refusal remains terminal")
	actual_policy.free()
	producer.homestead_action_completed.emit("tm_teach", producer.original, {"ok": true, "durable": true, "settled": true, "owner_saved": false, "owner_acknowledged": false})
	assert_eq(tab._tm_intent, producer.original)
	assert_false(menu.message.begins_with("Learned"))
	tab._retry_tm_transaction()
	assert_eq(producer.submissions[1], producer.submissions[0], "failed save/lost ACK retry preserves complete original request")
	producer.homestead_action_completed.emit("tm_teach", producer.original, {"ok": true, "durable": true, "settled": true, "owner_saved": true, "owner_acknowledged": true})
	assert_true(tab._tm_intent.is_empty())
	assert_true(menu.message.begins_with("Learned"))
	tab.free()
	menu.free()
	game.free()
	producer.free()

class OwnerSessionFixture extends "res://scripts/net/session.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func is_host() -> bool: return false # Detached admitted-owner side, no transport or host ACK.
	func _altar_current_epoch() -> String: return "tm-session"

class OwnerGameFixture extends Node:
	var local: RefCounted
	var world: RefCounted
	var session: Node
	var save_system: RefCounted

class BoolWriterFixture extends RefCounted:
	var store: RefCounted
	var refuse := false
	var writes := 0
	func finish_fallback() -> void: pass
	func fallback_busy() -> bool: return false
	func save_character_prepared(game: Node, id: String) -> bool:
		writes += 1
		if refuse: return false
		var payload: Dictionary = game.get("local").save_data()
		if game.get("session").call("_owner_training_snapshot_allowed", game.get("local"), payload) != true: return false
		return store.call("write", id, payload) == true

func test_actual_owner_installer_preserves_instances_and_failed_bool_write_retries_without_second_debit_or_ack() -> void:
	const OWNER = preload("res://scripts/net/character_action_owner.gd")
	var directory := "user://test_tm_owner_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := OwnerGameFixture.new()
	game.local = _player()
	game.world = preload("res://autoload/world_state.gd").new()
	game.world.world_id = "tm-slot"
	game.world.reward_delivery_namespace = NAMESPACE
	var session := OwnerSessionFixture.new()
	session.fixture = game
	game.session = session
	var writer := BoolWriterFixture.new()
	writer.store = preload("res://scripts/save/character_save.gd").new(directory)
	game.save_system = writer
	var before := RECORD.portable_projection(game.local.save_data())
	var staged := ACTIONS.stage(before, 0, "tm_teach", _intent(before), _context(), RECORD.errors)
	assert_true(staged.get("ok") == true, str(staged))
	if staged.get("ok") != true:
		session.free()
		game.free()
		return
	staged.character_revision = 1
	var row := DELIVERY.make_record("tm-slot", NAMESPACE, "tm-session", staged, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty():
		session.free()
		game.free()
		return
	assert_true(writer.save_character_prepared(game, CHARACTER))
	var path: String = writer.store.call("path_for", CHARACTER)
	var original := FileAccess.get_file_as_bytes(path)
	var student: RefCounted = game.local.party.at(1)
	var other: RefCounted = game.local.party.at(0)
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	writer.refuse = true
	var failed := OWNER.apply_owner(game, row)
	assert_false(failed.ok)
	assert_true(failed.durable and failed.pending and not failed.saved)
	assert_eq(failed.code, "owner_action_save_failed")
	assert_eq(FileAccess.get_file_as_bytes(path), original, "BOOL false must leave original disk unchanged")
	assert_true(game.local.party.at(1) == student and game.local.party.at(0) == other, "UID live instances preserved")
	assert_true(ESSENCE._equivalent(RECORD.portable_projection(game.local.save_data()), row.after))
	assert_eq(game.local.inventory.count("tm_burrow_strike"), 0)
	assert_eq(student.move_quick, before.party[1].move_quick)
	assert_true(session.owns_input(), "unsaved owner cannot unlock ordinary mutation")
	writer.refuse = false
	var writes_before := writer.writes
	var retried := OWNER.apply_owner(game, row)
	assert_true(retried.ok and retried.saved and retried.duplicate)
	assert_eq(writer.writes, writes_before + 1, "exact installed after-state still requires a real BOOL write")
	assert_true(ESSENCE._equivalent(RECORD.portable_projection(writer.store.call("read", CHARACTER)), row.after))
	assert_eq(game.local.inventory.count("tm_burrow_strike"), 0)
	assert_true(session.owns_input(), "successful owner disk write alone does not fabricate host ACK")
	var accepted := row.duplicate(true)
	accepted.status = "accepted"
	game.world.reward_deliveries[row.delivery_id] = accepted
	assert_true(session._settle_owner_training_accepted(game.local, game.world, accepted), "disclosed accepted-row control releases exact saved retry")
	assert_false(session.owns_input())
	session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

func test_owner_apply_tolerates_passive_care_drift_but_refuses_real_conflicts() -> void:
	# Care accrues between the host's stage and the owner's apply (single
	# player and guest alike). A transaction that writes no care field is not
	# in conflict with that drift; anything else still is.
	var before := _before()
	var proposal := ACTIONS.stage(before, 0, "tm_teach", _intent(before), _context(), RECORD.errors)
	assert_true(proposal.get("ok") == true)
	if proposal.get("ok") != true: return
	proposal.character_revision = 1
	var row := DELIVERY.make_record("tm-slot", NAMESPACE, "tm-session", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return
	var drifted := before.duplicate(true)
	drifted.party[0].nourishment = float(drifted.party[0].nourishment) - 0.5
	drifted.party[1].happiness = float(drifted.party[1].happiness) - 0.1
	drifted.party[0].distance_m_together = float(drifted.party[0].distance_m_together) + 40.0
	drifted.party[1].landmarks_visited_together = int(drifted.party[1].landmarks_visited_together) + 1
	var tolerated := DELIVERY.owner_plan(drifted, row, RECORD.errors)
	assert_true(tolerated.get("ok", false), "passive care drift is not a baseline conflict")
	assert_eq(tolerated.get("state"), row.after, "the owner applies the row's exact after, matching the host")
	var after_drift: Dictionary = row.after.duplicate(true)
	after_drift.party[0].nourishment = float(after_drift.party[0].nourishment) - 0.5
	assert_true(DELIVERY.owner_plan(after_drift, row, RECORD.errors).get("duplicate", false), "an applied row recognises itself through drift")
	for edit: Callable in [
		func(r: Dictionary) -> void: r.party[1].xp = int(r.party[1].xp) + 1,
		func(r: Dictionary) -> void: r.party[0].known_moves.append("burrow_strike"),
		func(r: Dictionary) -> void: r.inventory[0] = {"id": "wood", "n": 1},
		func(r: Dictionary) -> void: r.redesign_character.transaction_receipts.append("craft:another"),
	]:
		var conflicting := drifted.duplicate(true)
		edit.call(conflicting)
		assert_eq(DELIVERY.owner_plan(conflicting, row, RECORD.errors).get("code"), "owner_action_baseline_conflict",
			"a real conflicting edit is still refused")
