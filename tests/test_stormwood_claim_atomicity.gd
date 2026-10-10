extends "res://tests/test_case.gd"

## Actual world ledger and ending decision path with bool-writer/publication
## doubles. This covers ordering/rollback only, not a physical earned finale.
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const ENDING := preload("res://scripts/world/stormwood_ending.gd")

class SessionFixture extends Node:
	func is_host() -> bool: return true
	# This fixture covers the world writer/publication cut. The production
	# Session's canonical owner validation remains outside this fixture.
	func foundation_stormwood_answer(_source: Node, _peer: int, claim: Dictionary,
			_cut: Dictionary = {}, phase: String = "commit") -> bool:
		return phase == "rollback" or (phase in ["stage", "commit"] and claim.get("settled") == true)
	func _altar_current_epoch() -> String: return "session_a"

class TransportFixture extends Node:
	var ledger: RefCounted
	var published: Array[Dictionary] = []
	func publish_journaled_delta(delta: Dictionary) -> void: published.append(delta.duplicate(true))

class GameFixture extends Node:
	var world: RefCounted
	var ledger: Node
	var save_system: RefCounted
	var progression: RefCounted
	var local: RefCounted
	var party: RefCounted

class RefusedCharacterWriter extends RefCounted:
	var writes := 0
	func finish_fallback() -> bool: return true
	func fallback_busy() -> bool: return false
	func save_character_prepared(_game: Object, _character: String) -> bool:
		writes += 1
		return false

class ChapterFixture extends Node:
	var chapter := {"acts": [{"entry_flags": [], "objectives": [{"id": "offer", "flag_id": "stormwood:legendary_offer_made",
		"scope": "world", "requires_flags": ["stormwood:legendary_freed"], "completion_event": "legendary:offer_shown"}]}]}

class EndingFixture extends "res://scripts/world/stormwood_ending.gd":
	var fixture: Node
	var write_ok := false
	var written: Dictionary = {}
	func _decision_game() -> Node: return fixture
	func _character_for_peer(_peer: int) -> String: return "character_a"
	func _has(flag: String) -> bool: return fixture.world.flags.has(flag)
	func _saved_state() -> Dictionary: return fixture.world.realm_environment.stormwood.ending.duplicate(true)
	func _store_state(state: Dictionary) -> void: fixture.world.realm_environment.stormwood.ending = state.duplicate(true)
	func _save_world_claim() -> bool:
		written = fixture.world.save_data().duplicate(true)
		return write_ok

func test_failed_answer_publishes_nothing_and_retry_can_keep_the_original_opposite_choice() -> void:
	var game := GameFixture.new()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	game.world.flags.set_flag(ENDING.FREED_FLAG)
	game.world.realm_environment = {"stormwood": {"ending": {"participants": ["character_a"],
		"claims": {"character_a": {"creature": {"uid": "original_reserved_card"}, "kept": false, "settled": false}}}}}
	game.progression = game.world.flags
	var transport := TransportFixture.new()
	transport.ledger = LEDGER.new(game.world)
	game.ledger = transport
	var source := EndingFixture.new()
	source.fixture = game
	source.session = SessionFixture.new()
	source._chapter = ChapterFixture.new()
	source._foundation_world_binding = weakref(game.world)
	var before: Dictionary = game.world.save_data().duplicate(true)
	var sequence := int(transport.ledger.seq)
	assert_false(source._commit_world_decision(1, true, true))
	assert_true(transport.published.is_empty())
	assert_eq(game.world.save_data(), before)
	assert_eq(transport.ledger.seq, sequence)
	assert_false(game.world.flags.has(ENDING.resolution_flag(true, "character_a")))
	assert_false(game.world.flags.has(ENDING.OFFER_FLAG))
	source.write_ok = true
	assert_true(source._commit_world_decision(1, false, true))
	assert_true(game.world.flags.has(ENDING.resolution_flag(false, "character_a")))
	assert_false(game.world.flags.has(ENDING.resolution_flag(true, "character_a")))
	assert_true(game.world.flags.has(ENDING.OFFER_FLAG))
	assert_eq(source._saved_state().claims.character_a.creature.uid, "original_reserved_card")
	assert_true(source._saved_state().claims.character_a.settled)
	assert_false(source._saved_state().claims.character_a.kept)
	assert_false(transport.published.is_empty())
	assert_eq(source.written, game.world.save_data())
	source._chapter.free()
	source.session.free()
	source.free()
	transport.free()
	game.free()


func test_unsaved_ceremony_rollback_restores_original_live_team_and_inventory_under_real_session_guards() -> void:
	# Declared full-team transaction fixture; only the character writer's
	# failure is doubled. Session guard binding, containers, ceremony proposal,
	# payout installation and scoped rollback are the production code.
	var game := GameFixture.new()
	game.world = WORLD.new()
	game.world.world_id = "rollback-world"
	game.world.reward_delivery_namespace = "rollback-instance"
	game.local = preload("res://autoload/player_state.gd").new()
	game.local.configure(preload("res://autoload/item_db.gd").new())
	game.local.character_id = "character-f41f4a49223483d6bfdf56715944bb7b"
	game.party = game.local.party
	var originals: Array = []
	for index: int in 5:
		var member: RefCounted = game.local.make_creature("terrapup", "Original %d" % index)
		assert_true(game.party.add(member))
		originals.append(member)
	game.party.set("_active", 2)
	game.party.set("_best", 4)
	game.local.inventory.add("wood", 3)
	game.local.redesign_character = game.local.save_data().redesign_character
	var before: Dictionary = game.local.save_data()
	var newcomer: RefCounted = game.local.make_creature("fulgocobra", "Stormheart")
	var claim := {"recipient_character_id": game.local.character_id,
		"creature": preload("res://scripts/save/water_capture_codec.gd").encode(newcomer),
		"party_uids": preload("res://scripts/data/redesign_state.gd").uids(before.party), "kept": true}
	var session: Node = preload("res://scripts/net/session.gd").new()
	game.add_child(session) # Session._game() reads its actual parent.
	var passive: RefCounted = session.call("_owner_passive_service")
	session.call("_bind_training_container_guards")
	assert_false(game.party.owner_mutation_blocked())
	assert_true(passive.stormwood_begin_owner(claim))
	assert_true(game.party.owner_mutation_blocked())
	assert_true(game.local.inventory._owner_mutation_blocked())
	assert_false(session.call("_owner_training_snapshot_allowed", game.local, before), "ordinary snapshots remain fenced")
	assert_false(game.party.add(newcomer), "ordinary adds stay fenced outside the ceremony permit")
	game.local.inventory.set_slot(0, null)
	assert_eq(game.local.save_data().inventory, before.inventory, "ordinary inventory writes stay fenced")
	var released_uid: String = originals[1].uid
	var projected: Dictionary = preload("res://scripts/net/character_record_rules.gd").portable_projection(before)
	var baseline_errors: Array = preload("res://scripts/net/character_authority.gd").errors(projected, game.local.character_id)
	assert_true(baseline_errors.is_empty(), "actual full-team portable baseline: %s" % str(baseline_errors))
	var original_answer := "stormheart_answer:%s:%s" % [newcomer.uid, game.local.character_id]
	var history: Dictionary = preload("res://scripts/data/redesign_state.gd").defaults("character")
	history.transaction_receipts.append(original_answer)
	assert_true(preload("res://scripts/data/redesign_state.gd").validate("character", history).is_empty(),
		"a valid original answer remains historical after its creature is released")
	for malformed: Variant in ["stormheart_answer", "stormheart_answer:",
		"stormheart_answer:invalid_uid:" + game.local.character_id,
		"stormheart_answer:%s:" % newcomer.uid, "stormheart_answer:%s:../other" % newcomer.uid,
		original_answer + ":extra", 42, {"receipt": original_answer}]:
		var invalid: Dictionary = history.duplicate(true)
		invalid.transaction_receipts = [malformed]
		assert_false(preload("res://scripts/data/redesign_state.gd").validate("character", invalid).is_empty(),
			"malformed/wrong-type Stormheart receipt is rejected: %s" % str(malformed))
	var wrong_field: Dictionary = history.duplicate(true)
	wrong_field.transaction_receipts.clear()
	wrong_field.release_receipts.append(original_answer)
	assert_false(preload("res://scripts/data/redesign_state.gd").validate("character", wrong_field).is_empty(),
		"Stormheart answers belong only to transaction_receipts")
	var proposal: Dictionary = preload("res://scripts/net/character_authority.gd").stormwood_answer_proposal(projected, claim, released_uid)
	assert_true(proposal.get("ok") == true, "original claim proposal: %s" % str(proposal))
	assert_true(passive.stormwood_apply_ceremony(claim, released_uid, newcomer), "scoped production release/add must succeed")
	assert_true(game.party.members().has(newcomer))
	assert_false(game.party.members().has(originals[1]))
	assert_eq(game.party.size(), 5)
	assert_false(passive.stormwood_applying)
	# Match the ending's mirror removal before its prepared save. The failed
	# BOOL leaves the derived payout/receipts installed, but nothing durable.
	game.local.redesign_character.creatures.erase(released_uid)
	game.save_system = RefusedCharacterWriter.new()
	var saved: Dictionary = passive.stormwood_save_owner(claim, released_uid)
	assert_true(saved.is_empty(), "failed prepared BOOL retains the unsaved choice, not a terminal proposal: %s" % str(saved))
	assert_eq(game.save_system.writes, 1)
	assert_ne(game.local.save_data().inventory, before.inventory, "release payout was installed before the failed save")
	assert_true(game.local.redesign_character.release_receipts.has("release:" + released_uid))
	assert_true(game.local.redesign_character.transaction_receipts.has("stormheart_answer:%s:%s" % [newcomer.uid, game.local.character_id]))
	assert_true(game.party.owner_mutation_blocked())
	assert_false(session.call("_owner_training_snapshot_allowed", game.local, game.local.save_data()), "a failed prepared save does not unlock snapshots")
	# A conflicting unsaved decision is terminal; use the same cancellation
	# entry point as Ending._cancel_local_claim, with the original freeze kept.
	var conflicting: Dictionary = claim.duplicate(true)
	conflicting.kept = false
	var terminal: Dictionary = passive.stormwood_save_owner(conflicting, released_uid)
	assert_true(terminal.get("terminal") == true)
	passive.stormwood_cancel_owner()
	assert_eq(game.party.size(), 5)
	for index: int in originals.size():
		assert_true(is_same(game.party.at(index), originals[index]), "rollback retains each original live instance in order")
	assert_false(game.party.members().has(newcomer))
	assert_eq(game.party.get("_active"), 2)
	assert_eq(game.party.get("_best"), 4)
	var restored: Dictionary = game.local.save_data()
	assert_eq(restored.party, before.party, "original UIDs and complete cards are restored")
	assert_eq(restored.inventory, before.inventory)
	assert_eq(restored.redesign_character, before.redesign_character, "original release/answer receipts are restored")
	assert_false(passive.stormwood_applying)
	assert_true(passive.stormwood_owner.is_empty())
	assert_false(game.party.owner_mutation_blocked())
	assert_false(game.local.inventory._owner_mutation_blocked())
	assert_false(game.party.add(newcomer), "the ordinary five-creature cap still applies after rollback")
	game.free()
