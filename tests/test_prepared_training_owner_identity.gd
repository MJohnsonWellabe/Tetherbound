extends "res://tests/test_case.gd"

## Actual SaveGame preparation + CharacterSave disk writer under an isolated
## directory. The injected false writer is a disclosed BOOL-failure control;
## there is no live network, host publication, physical placement or ACK.
const SAVE := preload("res://scripts/save/save_game.gd")
const WORLD := preload("res://autoload/world_state.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const CHARACTER := "character-prepared-training"
const NAMESPACE := "world-prepared-training"
const EPOCH := "session-prepared-training"
const TXN := "0123456789abcdef0123456789abcdef"

class OwnerSession extends "res://scripts/net/session.gd":
	var fixture: Node
	func _game() -> Node: return fixture
	func is_host() -> bool: return false
	func _altar_current_epoch() -> String: return EPOCH

class GameFixture extends Node:
	var local: RefCounted
	var world: RefCounted
	var session: Node
	var save_system: RefCounted
	var forwarded: RefCounted
	func _get(property: StringName) -> Variant:
		return forwarded.get(property) if forwarded != null else null
	func is_host() -> bool: return false
	func player_vitals() -> RefCounted: return null
	func save_realm_maps() -> Dictionary: return local.call("map_payloads")

class CharacterWriter extends "res://scripts/save/character_save.gd":
	var refuse := false
	var attempts := 0
	func write(id: String, payload: Dictionary, envelope: Dictionary = {}, retain_previous: bool = false) -> bool:
		attempts += 1
		return false if refuse else super.write(id, payload, envelope, retain_previous)

func _game(directory: String) -> GameFixture:
	var items := preload("res://autoload/item_db.gd").new()
	var game := GameFixture.new()
	game.local = preload("res://autoload/player_state.gd").new()
	game.local.configure(items)
	game.local.character_id = CHARACTER
	game.local.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup"))
	for need: Dictionary in WORLD.altar_recipe(): game.local.inventory.add(need.id, int(need.n) + 1)
	game.world = WORLD.new()
	game.world.world_id = "slot-prepared-training"
	game.world.reward_delivery_namespace = NAMESPACE
	game.forwarded = FIXTURE.game(items, false)
	game.forwarded.party = game.local.party
	game.forwarded.inventory = game.local.inventory
	game.forwarded.local = game.local
	game.forwarded.world = game.world
	game.forwarded.realm_hearts = game.local.hearts
	game.forwarded.progression = game.local.flags
	game.forwarded.map = game.local.map_for("meadows")
	var session := OwnerSession.new()
	session.fixture = game
	game.session = session
	game.save_system = SAVE.new(directory)
	game.save_system.set("_characters", CharacterWriter.new(directory.path_join("characters")))
	return game

func _close(game: GameFixture, directory: String) -> void:
	game.session.free()
	game.free()
	FIXTURE.wipe(directory)

func _altar(before: Dictionary) -> Dictionary:
	var building := {"id": "altar", "realm": "meadows", "paid": true, "uid": "b1",
		"position": [2.0, 0.0, 3.0], "yaw_deg": 0.0}
	var proposal := WORLD.altar_build_transition(before, CHARACTER, 0, "place_building", TXN, building, NAMESPACE)
	if proposal.get("ok") != true: return {}
	return {"version": 1, "kind": "altar_building", "delivery_id": WORLD.altar_build_id(NAMESPACE, CHARACTER, TXN),
		"world_id": "slot-prepared-training", "world_namespace": NAMESPACE, "session_id": EPOCH,
		"character_id": CHARACTER, "action": "place_building", "action_id": TXN,
		"intent": {"request": {"kind": "place_building", "txn_id": TXN, "id": "altar", "realm": "meadows",
			"paid": true, "position": building.position.duplicate(), "yaw_deg": building.yaw_deg},
			"record": building, "cost": proposal.cost.duplicate(true)},
		"before": ESSENCE.training_projection(before), "after": ESSENCE.training_projection(proposal.state),
		"receipt": proposal.receipt, "character_revision": 1, "journal_revision": 1, "status": "pending"}

func test_actual_prepared_altar_owner_write_uses_local_identity_and_preserves_original_bool_retry() -> void:
	var directory := "user://test_prepared_altar_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := _game(directory)
	var saver: RefCounted = game.save_system
	var store: RefCounted = saver.get("_characters")
	var owned: RefCounted = game.local.party.at(0)
	owned.set("hp", float(owned.get("max_hp")) * 0.5)
	var before := RECORD.portable_projection(game.local.save_data())
	assert_true(saver.call("save_character_prepared", game, CHARACTER) == true, "actual initial SaveGame writer")
	var path: String = store.call("path_for", CHARACTER)
	var original := FileAccess.get_file_as_bytes(path)
	var row := _altar(before)
	assert_true(WORLD.altar_build_row_valid(row, NAMESPACE), "canonical paid row")
	if row.is_empty():
		_close(game, directory)
		return
	game.world.reward_deliveries[row.delivery_id] = row.duplicate(true)
	game.world.placed_buildings.append(row.intent.record.duplicate(true))
	game.forwarded.placed_buildings = game.world.placed_buildings
	store.set("refuse", true)
	var failed: Dictionary = game.session.call("apply_altar_building_owner", row)
	assert_false(failed.get("ok") == true)
	assert_true(failed.get("pending") == true and failed.get("code") == "owner_building_save_failed", str(failed))
	assert_eq(FileAccess.get_file_as_bytes(path), original, "BOOL false retains original disk")
	assert_true(ESSENCE._equivalent(ESSENCE.training_projection(game.local.save_data()), row.after))
	assert_true(game.local.party.at(0) == owned)
	assert_true(game.session.call("_owner_training_mutation_blocked", game.local) == true)
	var frozen := ESSENCE.training_projection(game.local.save_data())
	var recovery := preload("res://scripts/creatures/home_recovery.gd")
	recovery.rest(owned, preload("res://scripts/creatures/progression.gd").config(), game.local.redesign_character, game)
	assert_true(ESSENCE._equivalent(ESSENCE.training_projection(game.local.save_data()), frozen),
		"direct story/home recovery cannot heal or grant XP over the failed original owner save")
	var shelter := preload("res://scripts/world/cloudreach_physical_runtime.gd")
	var shelter_cfg: Dictionary = preload("res://scripts/data/redesign_data.gd").json(shelter.DATA_PATH).sheltered_rest
	var shelter_flags: RefCounted = preload("res://autoload/progression_state.gd").new()
	shelter_flags.call("set_flag", str(shelter_cfg.requires_flag))
	assert_eq(shelter.sheltered_rest_xp(owned, int(shelter_cfg.bed_index), shelter_flags,
		shelter_cfg, game.local.redesign_character, game), 0, "the authored shelter cannot grant XP over that same owner freeze")
	assert_true(ESSENCE._equivalent(ESSENCE.training_projection(game.local.save_data()), frozen))
	var raw: Dictionary = saver.call("snapshot", game)
	assert_false(raw.has("character_id"), "flat codec remains unchanged; identity belongs to split envelope")
	assert_false(game.session.call("_owner_training_snapshot_allowed", game.local, raw) == true, "original identity-less guard input refuses")
	var foreign := raw.duplicate(true)
	foreign.character_id = "foreign-prepared-owner"
	assert_false(game.session.call("_owner_training_snapshot_allowed", game.local, foreign) == true)
	assert_false(saver.call("save_character_prepared", game, "foreign-prepared-owner") == true)
	assert_false(FileAccess.file_exists(store.call("path_for", "foreign-prepared-owner")))
	store.set("refuse", false)
	var attempts: int = store.get("attempts")
	var saved: Dictionary = game.session.call("apply_altar_building_owner", row)
	assert_true(saved.get("ok") == true and saved.get("saved") == true, str(saved))
	assert_eq(store.get("attempts"), attempts + 1, "same installed after-state reaches actual disk writer")
	var disk: Dictionary = store.call("read", CHARACTER)
	assert_eq(disk.get("character_id"), CHARACTER)
	assert_true(ESSENCE._equivalent(ESSENCE.training_projection(disk), row.after))
	assert_true(game.local.party.at(0) == owned)
	assert_true(game.session.call("owns_input") == true, "saved owner alone cannot fabricate host ACK")
	_close(game, directory)

func test_actual_prepared_writer_preserves_full_v2_and_v3_pending_owner_projection() -> void:
	const ACTIONS = preload("res://scripts/net/character_action_rules.gd")
	const DELIVERY = preload("res://scripts/net/character_action_delivery.gd")
	const FOUNDATION = preload("res://scripts/net/foundation_actions.gd")
	const FOUNDATION_DELIVERY = preload("res://scripts/net/foundation_delivery.gd")
	const OWNER = preload("res://scripts/net/character_action_owner.gd")
	for version: int in [2, 3]:
		var directory := "user://test_prepared_training_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
		var game := _game(directory)
		var before := RECORD.portable_projection(game.local.save_data())
		var context := {"character_id": CHARACTER, "expected_revision": 0, "in_range": true,
			"source_key": "halda_bounty_board", "in_combat": false, "clock_confirmed": true,
			"world_namespace": NAMESPACE, "host_day": 1, "host_unlocks": []}
		var proposal: Dictionary
		if version == 2:
			proposal = ACTIONS.stage(before, 0, "bounty_rotate", {}, context, RECORD.errors)
		else:
			context.merge({"source_key": "hall_home", "foundation_runtime_authorized": true,
				"grounded_arrival": true, "permit_id": "travel-prepared", "realm": "meadows", "entry_id": "hall_home"}, true)
			proposal = FOUNDATION.stage(before, 0, "portal_arrival",
				{"permit_id": "travel-prepared", "realm": "meadows", "entry_id": "hall_home"}, context, RECORD.errors)
		assert_true(proposal.get("ok") == true, "canonical v%d stage %s" % [version, str(proposal)])
		if proposal.get("ok") != true:
			_close(game, directory)
			continue
		proposal.character_revision = 1
		var row: Dictionary = DELIVERY.make_record(game.world.world_id, NAMESPACE, EPOCH, proposal, null, RECORD.errors) \
			if version == 2 else FOUNDATION_DELIVERY.make_record(game.world.world_id, NAMESPACE, EPOCH, proposal, null, RECORD.errors)
		row = JSON.parse_string(JSON.stringify(row))
		assert_true(WORLD.training_row_valid(row, NAMESPACE))
		game.world.reward_deliveries[row.delivery_id] = row
		var applied := OWNER.apply_owner(game, row)
		assert_true(applied.get("ok") == true and applied.get("saved") == true, "v%d %s" % [version, str(applied)])
		var store: RefCounted = game.save_system.get("_characters")
		var disk: Dictionary = store.call("read", CHARACTER)
		assert_true(ESSENCE._equivalent(RECORD.portable_projection(disk), row.after), "full eight-field v%d saved projection" % version)
		assert_true(game.session.call("owns_input") == true, "no disclosed transport/ACK")
		assert_true(game.session.call("_owner_training_mutation_blocked", game.local) == true,
			"the actual saved v%d row retains its original owner ACK fence" % version)
		var frozen := RECORD.portable_projection(game.local.save_data())
		var bytes_before := FileAccess.get_file_as_bytes(store.call("path_for", CHARACTER))
		var children_before := game.get_child_count()
		var day_before := int(game.get("day"))
		var night := preload("res://scripts/world/night_rest.gd")
		night.rest(game, game)
		assert_eq(game.get_child_count(), children_before, "saved owner without original ACK cannot start a sleep fade or vote")
		assert_eq(night.pass_the_night(game, game), day_before, "solo sleep completion cannot advance a frozen owner's day")
		assert_eq(int(game.get("day")), day_before)
		assert_true(ESSENCE._equivalent(RECORD.portable_projection(game.local.save_data()), frozen),
			"sleep start/completion preserves the exact saved-but-unacknowledged v%d owner" % version)
		assert_eq(FileAccess.get_file_as_bytes(store.call("path_for", CHARACTER)), bytes_before)
		assert_true(game.session.call("owns_input") == true, "sleep cannot discard the original ACK hold")
		_close(game, directory)
