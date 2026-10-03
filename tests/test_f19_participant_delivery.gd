extends "res://tests/test_case.gd"

## Two distinct owners, the production host registry/prepared writer and actual
## split-save files. Peer identity/admission and captured victories are fixtures;
## this does not substitute for ENet replication or an earned fight.
const DATA := preload("res://tests/test_f19_boss_handoffs.gd")
const HARNESS := preload("res://tests/test_foundation_resource_save.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const WORLD := preload("res://autoload/world_state.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const OWNER := preload("res://scripts/net/character_action_owner.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")

class Roster extends RefCounted:
	func row(peer: int) -> Dictionary:
		return {"character_id": "character-b"} if peer == 2 else {}

class GuestGame extends Node:
	var local: RefCounted
	var world: RefCounted
	var session: Node
	var save_system: RefCounted
	func is_host() -> bool: return false

class GuestSession extends "res://scripts/net/session.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func is_host() -> bool: return false
	func local_peer_id() -> int: return 2
	func _altar_current_epoch() -> String: return "resource-epoch"

func test_all_four_handoffs_save_each_participants_entire_personal_key_and_relic() -> void:
	var data := DATA.new()
	for boss: String in DATA.BOSSES:
		var directory := "user://f19_two_owners_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
		var host := HARNESS.FixtureGame.new()
		host.local = _player("character-a")
		host.world = WORLD.new()
		host.world.world_id = "world-a"
		host.world.reward_delivery_namespace = "namespace-a"
		var session := HARNESS.FixtureSession.new()
		session.fixture = host
		session._registry = Roster.new()
		host.session = session
		var authority := AUTHORITY.new()
		session._character_authority = authority
		assert_true(authority.bind_world("namespace-a"))
		var writer := HARNESS.BoolWriter.new()
		writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
		writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
		host.save_system = writer
		var guest := GuestGame.new()
		guest.local = _player("character-b")
		guest.world = host.world # Explicit world-snapshot transport fixture.
		guest.save_system = writer
		var guest_session := GuestSession.new()
		guest_session.fixture = guest
		guest.session = guest_session
		for game: Node in [host, guest]:
			assert_true(authority.seed_admitted_character(RECORD.portable_projection(game.local.save_data()), game.local.character_id).ok)
			assert_true(writer.save_character_prepared(game, game.local.character_id))
		var intent: Dictionary = data._intent(boss)
		var captured: Dictionary = data._context(boss, false)
		captured.erase("world_namespace")
		captured.erase("boss_settlement_world_flags")
		var duties: Array = []
		for character: String in ["character-a", "character-b"]:
			duties.append({"character_id": character, "action": "boss_relic", "intent": intent, "context": captured})
		var event := EVENT.make(host.world, "original-fight-epoch", "boss:" + boss + ":earned-fight-1", duties)
		assert_false(event.is_empty())
		host.world.reward_deliveries[event.delivery_id] = event
		# Declared settled-world fixture; current flags are read from that world,
		# while the original victory capture remains immutable.
		for flag: String in data._context(boss).boss_settlement_world_flags:
			host.world.flags.set_flag(flag)
		var rpc := HARNESS.FixtureRpc.new()
		rpc.fixture = host
		rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(host.world)
		var rows: Array = []
		for peer: int in [2, 1]: # Guest first must not consume the host's entitlement.
			var character := "character-b" if peer == 2 else "character-a"
			var context: Dictionary = data._context(boss)
			context.boss_settlement_world_flags = host.world.flags.all_set()
			context.merge({"character_id": character, "expected_revision": 0, "in_range": true,
				"in_combat": false, "foundation_runtime_authorized": true, "retained_event": event.delivery_id})
			var token := authority.stage_character_action(character, 0, "boss_relic", intent, context)
			assert_true(token.get("ok") == true, str(token))
			if token.get("ok") != true: continue
			var accepted := authority.staged_creature_training(token)
			assert_eq(rpc.journal_creature_training_prepared(3, character, accepted).get("code"), "not_admitted", "spectator cannot impersonate either participant")
			var journal := rpc.journal_creature_training_prepared(peer, character, accepted)
			assert_true(journal.get("durable") == true, str(journal))
			assert_true(authority.finish_creature_training(token, journal.get("durable") == true))
			if journal.get("durable") == true: rows.append(host.world.reward_deliveries[journal.delivery_id])
		assert_eq(rows.size(), 2)
		var world_bytes := FileAccess.get_file_as_bytes(writer.world_store.path_for("world-a"))
		var restored := WORLD.new()
		restored.load_data(writer.world_store.read("world-a"))
		for game: Node in [host, guest]:
			var character: String = game.local.character_id
			var matching: Array = rows.filter(func(row: Dictionary) -> bool: return row.character_id == character)
			if matching.size() != 1: continue
			var row: Dictionary = matching[0]
			assert_true(ESSENCE._equivalent(restored.reward_deliveries[row.delivery_id], row), "each participant survives actual host-world disk reload")
			assert_eq(game.local.inventory.count(DATA.BOSSES[boss][2]), 0, "hidden preparation does not prepay either owner")
			assert_eq(OWNER.apply_owner(host if game == guest else guest, row).get("code"), "foreign_or_superseded_action", "another owner cannot install this participant's award")
			assert_true(OWNER.apply_owner(game, row).get("saved") == true, "each actual owner BOOL write succeeds")
			assert_true(OWNER.apply_owner(game, row).get("duplicate") == true, "replay saves the same original decision")
			assert_eq(game.local.inventory.count(DATA.BOSSES[boss][2]), 1, "entire authored key per participant without sharing or duplication")
			assert_eq(game.local.redesign_character.relics_held, [DATA.BOSSES[boss][1]])
			assert_true(ESSENCE._equivalent(RECORD.portable_projection(writer.character_store.read(character)), row.after), "actual saved character holds its exact entitlement")
		assert_eq(FileAccess.get_file_as_bytes(writer.world_store.path_for("world-a")), world_bytes, "owner deliveries never write the world file")
		rpc.free()
		session.free()
		guest_session.free()
		host.free()
		guest.free()
		preload("res://tests/helpers/split_save_fixture.gd").wipe(directory)

func _player(character: String) -> RefCounted:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = character
	player.party.add(SPECIES.spawn("terrapup"))
	player.redesign_character = TEACHING.character_loadout_mirror(player.save_data().party, player.redesign_character)
	return player
