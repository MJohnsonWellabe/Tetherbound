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
	const AUTHORITY = preload("res://scripts/net/character_authority.gd")
	var directory := "user://test_prepared_rematch_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game := _game(directory)
	var characters: RefCounted = game.save_system.get("_characters")
	var worlds: RefCounted = game.save_system.get("_worlds")
	assert_true(game.save_system.call("save_character_prepared", game, CHARACTER), "real initial character file")
	var original_uid := str(game.local.party.at(0).get("uid"))
	var paid_inventory: Array = []
	var paid_clocks: Dictionary = {}
	# These are disclosed canonical-win/host-clock fixtures. The real disk
	# writers, original row recovery and explicit authority ACK below do not
	# substitute for an earned encounter, elapsed time or a network transport.
	var steps := [
		{"world": "owning", "seconds": 100, "paid": true},
		{"world": "foreign", "seconds": 0, "paid": false},
		{"world": "foreign", "seconds": 900000, "paid": false},
		{"world": "owning", "seconds": 1299, "paid": false},
		{"world": "owning", "seconds": 1300, "paid": true},
	]
	for index: int in steps.size():
		var step: Dictionary = steps[index]
		var rematch_world_namespace := NAMESPACE + "-" + str(step.world)
		var world_id := "slot-prepared-rematch-" + str(step.world)
		game.world.world_id = world_id
		game.world.reward_delivery_namespace = rematch_world_namespace
		var prior_world: Dictionary = worlds.call("read", world_id) if worlds.call("has", world_id) else {}
		game.world.reward_deliveries = prior_world.get("reward_deliveries", {}).duplicate(true)
		var disk_before: Dictionary = characters.call("read", CHARACTER)
		assert_false(disk_before.is_empty(), "same stable character is read from its real file on every world step")
		var before := RECORD.portable_projection(disk_before)
		assert_true(ESSENCE._equivalent(before, RECORD.portable_projection(game.local.save_data())))
		var encounter := "fixture-rematch-%d" % index
		var intent := {"trainer_id": "relay_captain", "tier": "r1", "encounter_id": encounter}
		var context := {"character_id": CHARACTER, "expected_revision": index, "source_key": "rematch:relay_captain",
			"in_range": true, "validated_host_outcome": "win", "encounter_id": encounter,
			"trainer_id": "relay_captain", "tier": "r1", "participants": [CHARACTER],
			"world_flags": ["defeated_warden"], "personal_flags": [], "world_namespace": rematch_world_namespace,
			"session_id": EPOCH, "world_seconds": step.seconds}
		var proposal := ACTIONS.stage(before, index, "rematch_win", intent, context, RECORD.errors)
		assert_true(proposal.get("ok") == true, "canonical rematch step %d %s" % [index, str(proposal)])
		if proposal.get("ok") != true:
			_close(game, directory)
			return
		assert_eq(ESSENCE._equivalent(proposal.state.inventory, before.inventory), not step.paid,
			"actual canonical inventory changes only on the owning paid cycles")
		if index > 0 and not step.paid:
			assert_true(ESSENCE._equivalent(proposal.state.inventory, paid_inventory), "no stock minted on the unpaid cycle")
			assert_true(ESSENCE._equivalent(proposal.state.redesign_character.rematch_cooldowns, paid_clocks),
				"actual saved owning clock is retained through foreign/early wins")
		proposal.character_revision = index + 1
		var delivery_id := ESSENCE.training_delivery_id(rematch_world_namespace, CHARACTER)
		var row := DELIVERY.make_record(world_id, rematch_world_namespace, EPOCH, proposal,
			game.world.reward_deliveries.get(delivery_id), RECORD.errors)
		assert_false(row.is_empty(), "same original full projection codec")
		if row.is_empty():
			_close(game, directory)
			return
		game.world.reward_deliveries[delivery_id] = row
		assert_true(worlds.call("write", world_id, game.world.save_data()), "actual pending world file")
		var pending_world: Dictionary = worlds.call("read", world_id)
		var pending: Dictionary = pending_world.get("reward_deliveries", {}).get(delivery_id, {})
		assert_true(ESSENCE._equivalent(pending, row), "exact pending row survived world disk reload")
		game.world.reward_deliveries = pending_world.reward_deliveries.duplicate(true)
		var authority := AUTHORITY.new()
		assert_true(authority.bind_world(rematch_world_namespace))
		assert_true(authority.seed_admitted_character(before, CHARACTER).get("ok") == true)
		assert_true(authority.recover_durable_training(CHARACTER, pending_world.reward_deliveries).get("ok") == true)
		assert_true(authority.creature_training_pending_matches(CHARACTER, pending))
		var owner_bytes := FileAccess.get_file_as_bytes(characters.call("path_for", CHARACTER))
		characters.set("refuse", true)
		var failed := OWNER.apply_owner(game, pending)
		assert_true(failed.get("ok") == false and failed.get("saved") == false and failed.get("pending") == true,
			"original BOOL-false write is not a saved owner or ACK")
		assert_eq(FileAccess.get_file_as_bytes(characters.call("path_for", CHARACTER)), owner_bytes)
		assert_true(game.session.call("owns_input") == true)
		assert_true(authority.creature_training_is_pending(CHARACTER))
		assert_true(ESSENCE._equivalent(RECORD.portable_projection(game.local.save_data()), pending.after),
			"installed exact original decision remains fenced for retry")
		characters.set("refuse", false)
		var retried := OWNER.apply_owner(game, pending)
		assert_true(retried.get("ok") == true and retried.get("saved") == true and retried.get("duplicate") == true,
			"same original decision retries its actual BOOL write without another payout")
		var disk_after: Dictionary = characters.call("read", CHARACTER)
		assert_true(ESSENCE._equivalent(RECORD.portable_projection(disk_after), pending.after))
		assert_eq(str(game.local.party.at(0).get("uid")), original_uid)
		assert_true(game.session.call("owns_input") == true, "saved owner alone is still not host ACK")
		assert_true(authority.creature_training_is_pending(CHARACTER))
		# Explicitly exercise the original accepted-row predicates after both
		# actual files exist; no packet/transport delivery is claimed.
		var accepted := pending.duplicate(true)
		accepted.status = "accepted"
		game.world.reward_deliveries[delivery_id] = accepted
		assert_true(worlds.call("write", world_id, game.world.save_data()), "actual accepted world file")
		var accepted_world: Dictionary = worlds.call("read", world_id)
		var saved_accepted: Dictionary = accepted_world.reward_deliveries[delivery_id]
		assert_true(ESSENCE._equivalent(saved_accepted, accepted))
		game.world.reward_deliveries = accepted_world.reward_deliveries.duplicate(true)
		assert_true(authority.acknowledge_creature_training(CHARACTER, saved_accepted))
		assert_false(authority.creature_training_is_pending(CHARACTER))
		assert_true(game.session.call("_settle_owner_training_accepted", game.local, game.world, saved_accepted))
		assert_false(game.session.call("owns_input"), "only the matching accepted original releases the owner")
		assert_true(ESSENCE._equivalent(authority.state(CHARACTER), pending.after))
		var replay := ACTIONS.stage(RECORD.portable_projection(disk_after), index, "rematch_win", intent, context, RECORD.errors)
		assert_true(replay.get("ok") == false and replay.get("code") == "reconcile_original_delivery",
			"actual owner disk reload cannot replay the same win")
		if index == 0:
			paid_inventory = disk_after.inventory.duplicate(true)
			paid_clocks = disk_after.redesign_character.rematch_cooldowns.duplicate(true)
			assert_eq(paid_clocks.size(), 1)
			assert_eq(paid_clocks[NAMESPACE + "-owning:relay_captain:r1"].next_eligible_seconds, 1300.0)
		if index == steps.size() - 1:
			assert_eq(disk_after.redesign_character.rematch_cooldowns[NAMESPACE + "-owning:relay_captain:r1"].next_eligible_seconds, 2500.0)
			assert_eq(disk_after.redesign_character.transaction_receipts.count("rematch:relay_captain:r1:" + CHARACTER), 1,
				"the original unique reward marker remains singular on the due return")
	assert_true(worlds.call("has", "slot-prepared-rematch-owning") and worlds.call("has", "slot-prepared-rematch-foreign"),
		"both independent world documents persisted alongside the same stable character")
	_close(game, directory)
