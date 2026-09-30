extends "res://tests/test_case.gd"

const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const ACTOR := preload("res://scripts/net/actor_vitals_delivery.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const CHARACTER := preload("res://scripts/save/character_save.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
var _dir := ""

class OwnerWriter:
	extends RefCounted
	var store: RefCounted
	var refuse := false
	var writes := 0
	func save_character(game: Node, id: String) -> bool:
		writes += 1
		if refuse:
			return false # Simulate an actual bool-writer refusal, never equality.
		var saved: Dictionary = game.get("local").save_data()
		if not bool(game.get("session").call("_owner_vitals_snapshot_allowed", game.get("local"), saved)):
			return false
		saved.redesign_character = preload("res://scripts/creatures/teaching.gd").character_loadout_mirror(saved.party, saved.redesign_character)
		return bool(store.call("write", id, saved))
	func finish_fallback() -> void:
		pass
	func save_character_prepared(game: Node, id: String) -> bool:
		return save_character(game, id)
	func fallback_busy() -> bool:
		return false
	func save_world_prepared(_game: Node, _id: String) -> bool:
		writes += 1
		return not refuse

class OwnerGame:
	extends Node
	var local: RefCounted
	var world: RefCounted
	var save_system: RefCounted
	var session: Node = preload("res://scripts/net/session.gd").new()
	func is_host() -> bool:
		return true
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE and is_instance_valid(session):
			session.free()

class UnadmittedTransport:
	extends "res://scripts/net/ledger_rpc.gd"
	var fixture: Node
	func _game() -> Node:
		return fixture
	func _registered_character(_peer: int) -> String:
		return ""

class PreparedProbe:
	extends "res://scripts/save/save_game.gd"
	var writes := 0
	var finishes := 0
	var busy := false
	func fallback_busy() -> bool:
		return busy
	func finish_fallback() -> bool:
		finishes += 1
		busy = true # A completion listener has started a replacement fallback.
		return true
	func _write_world_snapshot(_game: Object, _world: String) -> bool:
		writes += 1
		return true
	func _write_character_snapshot(_game: Object, _character: String) -> bool:
		writes += 1
		return true

func before_each() -> void:
	_dir = "user://test_actor_vitals_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	DirAccess.make_dir_recursive_absolute(_dir)

func after_each() -> void:
	FIXTURE.wipe(_dir)

func _player() -> RefCounted:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "owner_a"
	player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	return player

func _portable(player: RefCounted) -> Dictionary:
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return AUTHORITY.portable_projection(saved)

func _receipt(uid: String, ordinal: int) -> Dictionary:
	return {"receipt_id": "host_process:hit_%d" % ordinal, "encounter_id": "encounter_a",
		"creature_uid": uid, "body_generation": 1, "vitals_revision": ordinal}

func _row(portable: Dictionary, ordinal: int, hp: float, previous: Variant = null) -> Dictionary:
	var owned: Dictionary = portable.party[0]
	return ACTOR.next_record("world_a", "namespace_a", "session_a", "owner_a", owned.uid,
		float(owned.max_hp), float(owned.hp), bool(owned.fainted), hp, hp == 0.0,
		ordinal, _receipt(owned.uid, ordinal), previous)

func test_private_stage_world_failure_restores_hp_revision_and_replay_history() -> void:
	var portable := _portable(_player())
	var owned: Dictionary = portable.party[0]
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("namespace_a"))
	assert_true(authority.seed_admitted_character(portable, "owner_a").ok)
	var before := authority.state("owner_a")
	var stage := authority.stage_creature_vitals("owner_a", owned.uid, 0,
		float(owned.hp), false, float(owned.hp) - 10.0, false, _receipt(owned.uid, 1))
	assert_true(stage.ok)
	assert_false(authority.stage_creature_vitals("owner_a", owned.uid, 1,
		float(owned.hp) - 10.0, false, 1.0, false, _receipt(owned.uid, 2)).ok)
	assert_false(authority.stage_portal_debit("owner_a", "tidewake", "foreign").ok)
	assert_false(authority.commit_creature_mastery("owner_a", owned.uid, 1, {}, {}, {}, {}).ok)
	var tampered := stage.duplicate(true)
	tampered.accepted.hp = 1.0
	assert_eq(authority.staged_creature_vitals(tampered).hp, float(owned.hp) - 10.0)
	assert_true(authority.finish_creature_vitals(stage, false))
	assert_eq(authority.revision("owner_a"), 0)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	assert_true(authority.pending_creature_vitals("owner_a").is_empty())
	stage = authority.stage_creature_vitals("owner_a", owned.uid, 0,
		float(owned.hp), false, float(owned.hp) - 10.0, false, _receipt(owned.uid, 1))
	assert_false(bool(stage.get("duplicate", false)), "failed world save cannot become a saved replay")
	assert_true(authority.finish_creature_vitals(stage, true))
	assert_false(authority.finish_creature_vitals(stage, false), "retired stage cannot refund accepted HP")
	assert_true(authority.commit_creature_vitals("owner_a", owned.uid, 0,
		float(owned.hp), false, float(owned.hp) - 10.0, false, _receipt(owned.uid, 1)).durable)

func test_lost_ack_cumulative_recovery_and_latest_ack_reject_foreign_healthy_reseed() -> void:
	var portable := _portable(_player())
	var owned: Dictionary = portable.party[0]
	var first := _row(portable, 1, float(owned.hp) - 10.0)
	var second := _row(portable, 2, float(owned.hp) - 20.0, first)
	assert_eq(second.expected_hp, owned.hp, "earliest unsettled baseline survives a missed ACK")
	var intermediate := first.duplicate(true)
	intermediate.status = "settled"
	var partially_saved := portable.duplicate(true)
	partially_saved.party[0].hp = first.hp
	partially_saved.vitals_escrow[first.delivery_id] = intermediate
	assert_true(ACTOR.personal_baseline_matches(partially_saved.party[0], second, intermediate))
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("namespace_a"))
	assert_true(authority.seed_admitted_character(partially_saved, "owner_a").ok)
	assert_true(authority.recover_durable_vitals("owner_a", {second.delivery_id: second}).ok)
	assert_eq(authority.state("owner_a").party[0].hp, second.hp)
	assert_eq(authority.revision("owner_a"), 2, "restart retains durable revision high-water")
	assert_true(authority.seed_admitted_character(portable, "owner_a").already_seeded)
	assert_eq(authority.state("owner_a").party[0].hp, second.hp, "fresh rejoin cannot heal retained authority")
	assert_false(authority.acknowledge_creature_vitals("owner_a", owned.uid, 1, first.receipt))
	assert_true(authority.acknowledge_creature_vitals("owner_a", owned.uid, 2, second.receipt))
	var before := authority.state("owner_a")
	var foreign := second.duplicate(true)
	foreign.world_namespace = "foreign_world"
	foreign.delivery_id = ACTOR.delivery_id("foreign_world", "owner_a", owned.uid)
	assert_false(authority.recover_durable_vitals("owner_a", {foreign.delivery_id: foreign}).ok)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	var old_projection := portable.duplicate(true)
	old_projection.erase("vitals_escrow")
	var old_authority := AUTHORITY.new()
	assert_true(old_authority.bind_world("namespace_a"))
	assert_true(old_authority.seed_admitted_character(old_projection, "owner_a").ok)
	assert_true(old_authority.state("owner_a").vitals_escrow.is_empty(), "old28 projection defaults without resetting fields")
	var empty_ack := {"op": "actor_vitals_accept", "scope": "world", "delivery_id": second.delivery_id,
		"character_id": "", "journal_revision": second.journal_revision, "receipt": second.receipt}
	assert_false(ACTOR.valid_world_op(empty_ack, {second.delivery_id: second}, "namespace_a"))
	var game := OwnerGame.new()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	game.world.reward_deliveries[second.delivery_id] = second.duplicate(true)
	var writer := OwnerWriter.new()
	game.save_system = writer
	var transport := UnadmittedTransport.new()
	transport.fixture = game
	transport.ledger = LEDGER.new(game.world)
	var before_world: Dictionary = game.world.save_data()
	assert_false(transport._accept_actor_vitals(second.delivery_id, 2, second.receipt, 999))
	assert_eq(writer.writes, 0, "an unadmitted known-receipt ACK must refuse before durable write")
	assert_true(ACTOR.equivalent(game.world.save_data(), before_world), "no mutation of another owner's pending journal")
	transport.free()
	game.free()

func test_owner_write_loss_keeps_accepted_hp_and_requires_real_retry_write() -> void:
	var game := OwnerGame.new()
	game.local = _player()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	var writer := OwnerWriter.new()
	writer.store = CHARACTER.new(_dir + "characters/")
	game.save_system = writer
	assert_true(writer.save_character(game, "owner_a"))
	var path: String = writer.store.call("path_for", "owner_a")
	var original := FileAccess.get_file_as_bytes(path)
	var portable := _portable(game.local)
	var row := _row(portable, 1, float(portable.party[0].hp) - 10.0)
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	writer.refuse = true
	assert_false(ACTOR.apply_owner(game, row).ok)
	assert_eq(game.local.party.at(0).hp, row.hp, "accepted live HP never rolls back healthy")
	assert_true(game.local.satchel_escrow.is_empty(), "only the unsaved marker rolls back")
	assert_eq(FileAccess.get_file_as_bytes(path), original)
	assert_false(game.session.call("_owner_vitals_snapshot_allowed", game.local, game.local.save_data()),
		"ordinary autosave cannot persist accepted HP without its failed marker")
	var latest := _row(portable, 2, float(portable.party[0].hp) - 20.0, row)
	game.world.reward_deliveries[latest.delivery_id] = latest.duplicate(true)
	assert_false(ACTOR.apply_owner(game, row).ok, "a superseded delivery cannot write or ACK")
	assert_false(ACTOR.apply_owner(game, latest).ok, "latest-only retry still refuses the injected writer")
	assert_eq(game.local.party.at(0).hp, latest.hp, "validated unsaved prior receipt permits latest cumulative HP")
	assert_true(game.local.satchel_escrow.is_empty())
	assert_eq(FileAccess.get_file_as_bytes(path), original)
	row = latest
	writer.refuse = false
	var writes_before := writer.writes
	assert_true(ACTOR.apply_owner(game, row).ok, "live HP equality still performs a real write")
	assert_eq(writer.writes, writes_before + 1)
	assert_eq(writer.store.call("read", "owner_a").party[0].hp, row.hp)
	assert_true(game.local.satchel_escrow.has(row.delivery_id))
	assert_true(game.session.call("_owner_vitals_snapshot_allowed", game.local, game.local.save_data()),
		"actual successful marker write clears the guarded retry context")
	writes_before = writer.writes
	assert_true(ACTOR.apply_owner(game, row).ok)
	assert_eq(writer.writes, writes_before + 1, "duplicate exact receipt is not a disk-success shortcut")
	game.local.party.at(0).hp = float(row.hp) - 1.0
	assert_false(ACTOR.apply_owner(game, row).ok, "old marker cannot ACK over a newer live accepted hit")
	assert_eq(writer.writes, writes_before + 1)
	game.local.party.at(0).hp = float(row.expected_hp)
	assert_false(ACTOR.apply_owner(game, row).ok, "old exact marker cannot replace legitimate later live healing")
	assert_true(game.session.call("_owner_vitals_snapshot_allowed", game.local, game.local.save_data()),
		"refused exact replay cannot create a new unsaved proof or poison ordinary saves")
	game.free()

func test_prepared_writer_never_flushes_a_reentrant_replacement_fallback() -> void:
	var saver := PreparedProbe.new()
	assert_true(saver.save_world_prepared(null, "world_a"))
	assert_eq(saver.writes, 1)
	assert_eq(saver.finishes, 0, "frozen prepared CAS cannot emit fallback completion")
	saver.finish_fallback()
	assert_false(saver.save_world_prepared(null, "world_a"))
	assert_eq(saver.writes, 1, "replacement fallback fails closed before the writer")
	assert_eq(saver.finishes, 1, "prepared refusal does not flush or reemit")
	assert_false(saver.save_character_prepared(null, "owner_a"))
	assert_eq(saver.writes, 1, "owner writer refuses the same reentrant replacement")
	saver.busy = false
	assert_true(saver.save_character_prepared(null, "owner_a"))
	assert_eq(saver.writes, 2)
	assert_eq(saver.finishes, 1, "prepared owner save never emits completion inside receipt freeze")
