extends "res://tests/test_case.gd"

## Real admitted registry, prepared LedgerRpc and split files; the victory
## itself is a declared captured-event fixture, not earned combat evidence.
const HANDOFFS := preload("res://tests/test_f19_boss_handoffs.gd")
const HARNESS := preload("res://tests/test_foundation_resource_save.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const WORLD := preload("res://autoload/world_state.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")

class PeerRegistry extends RefCounted:
	func peer_for_character(character: String) -> int: return 1 if character == "character-a" else 0

class RetrySession extends "res://scripts/net/session.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func is_host() -> bool: return true
	func _retry_combat_mastery_sources() -> void: pass
	func admitted_character_state(_peer: int) -> Dictionary: return _character_authority.state("character-a")

class AttemptWriter extends Node:
	var attempted: Array = []
	func journal_creature_training_prepared(_peer: int, _character: String, accepted: Dictionary) -> Dictionary:
		attempted.append(accepted.source_key)
		return {"ok": false, "durable": false, "code": "declared_test_writer_refusal"}

func test_paid_legacy_boss_duty_never_starves_the_next_owed_duty_for_that_character() -> void:
	var data := HANDOFFS.new()
	var game := HARNESS.FixtureGame.new()
	game.world = WORLD.new()
	game.world.world_id = "world-a"
	game.world.reward_delivery_namespace = "namespace-a"
	game.local = PLAYER.new()
	game.local.configure(ITEMS.new())
	game.local.character_id = "character-a"
	game.local.party.add(SPECIES.spawn("terrapup"))
	game.local.redesign_character.transaction_receipts.append("defeat:boss_warden_aldis:character-a")
	game.local.redesign_character.relics_held.append("meadows")
	var session := RetrySession.new()
	session.fixture = game
	session._registry = PeerRegistry.new()
	session._character_authority = AUTHORITY.new()
	assert_true(session._character_authority.bind_world("namespace-a"))
	assert_true(session._character_authority.seed_admitted_character(RECORD.portable_projection(game.local.save_data()), "character-a").ok)
	for boss: String in ["warden_aldis", "captain_veyra_storm_anchor"]:
		var context := data._context(boss)
		context.erase("boss_settlement_world_flags")
		context.erase("world_namespace")
		var event := EVENT.make(game.world, "original-epoch", "boss:" + boss + ":earned-fight-1", [{
			"character_id": "character-a", "action": "boss_relic", "intent": data._intent(boss), "context": context}])
		assert_false(event.is_empty())
		game.world.reward_deliveries[event.delivery_id] = event
	var writer := AttemptWriter.new()
	writer.name = "LedgerRpc"
	session.add_child(writer)
	session._retry_foundation_events()
	assert_eq(writer.attempted, ["boss:captain_veyra_storm_anchor"], "owed second duty reaches the production stage/writer despite the earlier legacy receipt")
	assert_eq(session._character_authority.revision("character-a"), 0, "declared writer failure rolls back that later attempt")
	session.free()
	game.free()

func test_captured_boss_duty_keeps_original_epoch_through_real_prepared_and_owner_save_retry() -> void:
	var data := HANDOFFS.new()
	var directory := "user://test_f19_delivery_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := HARNESS.FixtureGame.new()
	game.local = PLAYER.new()
	game.local.configure(ITEMS.new())
	game.local.character_id = "character-a"
	game.local.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	game.local.redesign_character = TEACHING.character_loadout_mirror(game.local.save_data().party, game.local.redesign_character)
	game.world = WORLD.new()
	game.world.world_id = "world-a"
	game.world.reward_delivery_namespace = "namespace-a"
	var session := HARNESS.FixtureSession.new()
	session.fixture = game
	game.session = session
	var authority := AUTHORITY.new()
	session._character_authority = authority
	var writer := HARNESS.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	var rpc := HARNESS.FixtureRpc.new()
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(authority.bind_world("namespace-a"))
	assert_true(authority.seed_admitted_character(before, "character-a").ok)
	var intent: Dictionary = data._intent("warden_aldis")
	var captured: Dictionary = data._context("warden_aldis")
	captured.erase("boss_settlement_world_flags")
	captured.erase("world_namespace") # Existing production victory context.
	var event := EVENT.make(game.world, "original-fight-epoch", "boss:warden_aldis:earned-fight-1", [{
		"character_id": "character-a", "action": "boss_relic", "intent": intent, "context": captured}])
	assert_false(event.is_empty())
	game.world.reward_deliveries[event.delivery_id] = event
	var context := data._context("warden_aldis")
	context.merge({"character_id": "character-a", "expected_revision": 0, "in_range": true,
		"in_combat": false, "foundation_runtime_authorized": true, "retained_event": event.delivery_id})
	var wrong := context.duplicate(true)
	wrong.world_namespace = "another-host-world"
	assert_eq(authority.stage_character_action("character-a", 0, "boss_relic", intent, wrong).get("code"), "wrong_world")
	var legacy_context := context.duplicate(true)
	legacy_context.erase("world_namespace")
	assert_eq(authority.stage_character_action("character-a", 0, "boss_relic", intent, legacy_context).get("code"), "wrong_world", "new live stages cannot emit old global identities")
	var legacy := preload("res://scripts/net/foundation_actions.gd").stage(before, 0, "boss_relic", intent, legacy_context, RECORD.errors)
	assert_true(legacy.get("ok") == true, "existing v3 snapshots still reconstruct their original decision")
	legacy.character_revision = 1
	var legacy_row := DELIVERY.make_record("world-a", "namespace-a", "original-fight-epoch", legacy, null, RECORD.errors)
	assert_false(legacy_row.is_empty(), "legacy pending disk rows retain their original ID and exact decision")
	assert_eq(legacy_row.get("receipt"), "defeat:boss_warden_aldis:character-a")
	var frozen_world: Dictionary = game.world.save_data()
	assert_true(writer.save_world_prepared(game, "world-a"))
	assert_true(writer.save_character_prepared(game, "character-a"))
	var world_path: String = writer.world_store.path_for("world-a")
	var owner_path: String = writer.character_store.path_for("character-a")
	var old_world := FileAccess.get_file_as_bytes(world_path)
	var old_owner := FileAccess.get_file_as_bytes(owner_path)
	var token := authority.stage_character_action("character-a", 0, "boss_relic", intent, context)
	assert_true(token.get("ok") == true, str(token))
	if token.get("ok") != true:
		_close(game, rpc, data, directory)
		return
	assert_eq(session.foundation_event_stage_epoch(token), "original-fight-epoch", "derived settlement context cannot erase original retained capture identity")
	writer.refuse_world = true
	var failed := rpc.journal_creature_training_prepared(1, "character-a", authority.staged_creature_training(token))
	assert_eq(failed.get("code"), "training_journal_failed")
	assert_true(authority.finish_creature_training(token, false))
	assert_true(ESSENCE._equivalent(game.world.save_data(), frozen_world))
	assert_eq(authority.state("character-a"), before)
	assert_eq(FileAccess.get_file_as_bytes(world_path), old_world)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	writer.refuse_world = false
	token = authority.stage_character_action("character-a", 0, "boss_relic", intent, context)
	var journal := rpc.journal_creature_training_prepared(1, "character-a", authority.staged_creature_training(token))
	assert_true(journal.get("ok") == true and journal.get("durable") == true, str(journal))
	assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
	if journal.get("durable") != true:
		_close(game, rpc, data, directory)
		return
	var row: Dictionary = game.world.reward_deliveries[journal.delivery_id]
	assert_eq(row.session_id, "original-fight-epoch")
	assert_eq(game.local.inventory.count("tidewake_portal_key"), 0, "prepared journal does not publish early")
	var reloaded := WORLD.new()
	reloaded.load_data(writer.world_store.read("world-a"))
	assert_true(ESSENCE._equivalent(reloaded.reward_deliveries[row.delivery_id], row))
	writer.refuse_owner = true
	var unsaved := OWNER.apply_owner(game, row)
	assert_eq(unsaved.get("code"), "owner_action_save_failed")
	assert_eq(game.local.inventory.count("tidewake_portal_key"), 1)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), old_owner)
	writer.refuse_owner = false
	var retry := OWNER.apply_owner(game, row)
	assert_true(retry.get("saved") == true and retry.get("duplicate") == true, str(retry))
	assert_eq(game.local.inventory.count("tidewake_portal_key"), 1)
	assert_eq(game.local.redesign_character.relics_held, ["meadows"])
	assert_true(ESSENCE._equivalent(RECORD.portable_projection(writer.character_store.read("character-a")), row.after))
	var foreign := row.duplicate(true)
	foreign.host_context.world_namespace = "another-host-world"
	assert_false(DELIVERY.valid(foreign, RECORD.errors))
	_close(game, rpc, data, directory)

func _close(game: Node, rpc: Node, _data: RefCounted, directory: String) -> void:
	rpc.free()
	game.session.free()
	game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)
