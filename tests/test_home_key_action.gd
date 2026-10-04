extends "res://tests/test_case.gd"

const HOME := preload("res://scripts/net/home_key_action.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const FOUNDATION := preload("res://scripts/net/foundation_actions.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const CHARACTER := "home-key-owner"
const OLD_WORLD := "0123456789abcdef0123456789abcdef"
const NEW_WORLD := "fedcba9876543210fedcba9876543210"


func _player() -> RefCounted:
	var player: RefCounted = PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = CHARACTER
	return player


func _due() -> Dictionary:
	return HOME.due(REWARD.make_record("origin-world", OLD_WORLD, "home_key:grant:" + CHARACTER,
		CHARACTER, "home_key", 1, "home_key_given"), CHARACTER)


func _intent() -> Dictionary:
	return {"delivery_id": _due().delivery_id, "origin_namespace": OLD_WORLD}


func _context(revision: int = 0) -> Dictionary:
	return {"character_id": CHARACTER, "expected_revision": revision, "in_range": true,
		"in_combat": false, "foundation_runtime_authorized": true, "home_key_authorized": true,
		"home_key_record": _due(), "source_key": "opening_home_key:" + str(_due().delivery_id)}


func _filled(player: RefCounted) -> void:
	var maximum: int = ITEMS.new().stack_size("wood")
	for slot: int in player.inventory.slot_count(): player.inventory.set_slot(slot, {"id": "wood", "n": maximum})


func test_actual_portable_projection_carries_only_strict_finite_home_key_debt_without_synthetic_receipts() -> void:
	var player := _player()
	var row := _due()
	player.satchel_escrow[row.delivery_id] = row
	var before: Array = player.redesign_character.transaction_receipts.duplicate()
	var projected := RECORD.portable_projection(player.save_data())
	assert_eq(projected.portal_escrow[row.delivery_id], row)
	assert_eq(projected.redesign_character.transaction_receipts, before)
	assert_true(RECORD.errors(projected, CHARACTER).is_empty())
	assert_eq(RECORD.portable_projection(player.save_data()), projected, "reprojection is idempotent")
	player.satchel_escrow[row.delivery_id].stacks = [{"id": "wood", "n": 1}]
	assert_false(RECORD.errors(RECORD.portable_projection(player.save_data()), CHARACTER).is_empty(),
		"malformed Home Key debt is carried as invalid, never silently dropped or authorized")


func test_json_numeric_equivalence_keeps_exact_finite_debt_schema_owner_and_hash() -> void:
	var decoded: Variant = JSON.parse_string(JSON.stringify(_due()))
	assert_true(HOME.valid_escrow(decoded, CHARACTER), "version and quantity 1.0 are valid JSON numbers")
	assert_false(HOME.valid_escrow(decoded, "another-owner"))
	var invalid_numbers: Array = [1.25, INF, NAN, "1", true]
	for number: Variant in invalid_numbers:
		var bad_version: Dictionary = decoded.duplicate(true)
		bad_version.version = number
		assert_false(HOME.valid_escrow(bad_version, CHARACTER))
		var bad_quantity: Dictionary = decoded.duplicate(true)
		bad_quantity.stacks[0].n = number
		assert_false(HOME.valid_escrow(bad_quantity, CHARACTER))
	var extra: Dictionary = decoded.duplicate(true)
	extra.client_authorized = true
	assert_false(HOME.valid_escrow(extra, CHARACTER), "extra fields never authorize debt")
	var wrong_hash: Dictionary = decoded.duplicate(true)
	wrong_hash.delivery_id = "a".repeat(64)
	assert_false(HOME.valid_escrow(wrong_hash, CHARACTER))
	var alias_player: RefCounted = _player()
	_filled(alias_player)
	alias_player.satchel_escrow[_due().delivery_id] = _due()
	var alias: Dictionary = _legacy_alias(alias_player)
	var decoded_alias: Variant = JSON.parse_string(JSON.stringify(alias))
	assert_true(HOME.is_settled_alias(decoded_alias, CHARACTER))
	assert_false(HOME.valid_escrow(decoded_alias, CHARACTER), "numeric compatibility does not turn an alias into debt")


func test_owe_action_durably_carries_full_bag_debt_without_mutating_inventory() -> void:
	var player := _player()
	_filled(player)
	var current := RECORD.portable_projection(player.save_data())
	var plan := FOUNDATION.stage(current, 0, "home_key_owe", _intent(), _context(), RECORD.errors)
	assert_true(plan.get("ok", false))
	assert_eq(plan.state.inventory, current.inventory)
	assert_eq(plan.state.portal_escrow[_due().delivery_id], _due())
	assert_eq(HOME.key_count(plan.state), 0)
	assert_true(HOME.install_owner(player, {"action": "home_key_owe", "after": plan.state, "intent": _intent()}))
	assert_false(player.flags.call("has", "home_key_given"))
	assert_false(HOME.stage(plan.state, "home_key_deliver", _intent(), _context()).get("ok", false))
	assert_eq(HOME.stage(plan.state, "home_key_deliver", _intent(), _context()).get("code"), "home_key_bag_full")


func test_cross_world_delivery_uses_admitted_original_escrow_and_host_capacity_once() -> void:
	var player := _player()
	_filled(player)
	player.satchel_escrow[_due().delivery_id] = _due()
	var full := RECORD.portable_projection(player.save_data())
	assert_false(HOME.stage(full, "home_key_deliver", _intent(), _context()).get("ok", false))
	player.inventory.set_slot(0, null)
	var current := RECORD.portable_projection(player.save_data())
	var plan := FOUNDATION.stage(current, 0, "home_key_deliver", _intent(), _context(), RECORD.errors)
	assert_true(plan.get("ok", false))
	assert_eq(HOME.key_count(plan.state), 1)
	assert_eq(plan.state.portal_escrow[_due().delivery_id].status, "settled")
	assert_eq(plan.state.portal_escrow[_due().delivery_id].world_namespace, OLD_WORLD)
	assert_false(HOME.stage(plan.state, "home_key_deliver", _intent(), _context()).get("ok", false), "settled source cannot deliver twice")
	var changed := _intent()
	changed.origin_namespace = NEW_WORLD
	assert_false(HOME.stage(current, "home_key_deliver", changed, _context()).get("ok", false))
	var forged := current.duplicate(true)
	forged.portal_escrow = {}
	assert_false(HOME.stage(forged, "home_key_deliver", _intent(), _context()).get("ok", false), "a packet cannot introduce foreign debt")


func test_existing_physical_key_suppresses_duplicate_without_adding_another() -> void:
	var player := _player()
	player.inventory.set_slot(0, {"id": "home_key", "n": 1})
	player.satchel_escrow[_due().delivery_id] = _due()
	var current := RECORD.portable_projection(player.save_data())
	var plan := HOME.stage(current, "home_key_deliver", _intent(), _context())
	assert_true(plan.get("ok", false))
	assert_eq(plan.state.inventory, current.inventory)
	assert_eq(HOME.key_count(plan.state), 1)
	assert_true(HOME.install_owner(player, {"action": "home_key_deliver", "after": plan.state, "intent": _intent()}))
	assert_true(player.flags.call("has", "home_key_given"))
	assert_eq(player.satchel_escrow[_due().delivery_id].status, "settled")


func test_real_registry_hides_inventory_cas_until_saved_delivery_ack_and_rolls_back_failed_world_save() -> void:
	var player := _player()
	player.satchel_escrow[_due().delivery_id] = _due()
	var current := RECORD.portable_projection(player.save_data())
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world(NEW_WORLD))
	assert_true(authority.seed_admitted_character(current, CHARACTER).get("ok", false))
	var stage: Dictionary = authority.stage_character_action(CHARACTER, 0, "home_key_deliver", _intent(), _context())
	assert_true(stage.get("ok", false))
	assert_true(authority._training_locked(CHARACTER))
	assert_eq(HOME.key_count(authority.state(CHARACTER)), 1)
	assert_true(authority.finish_creature_training(stage, false))
	assert_eq(authority.state(CHARACTER), current)
	assert_false(authority._training_locked(CHARACTER))
	stage = authority.stage_character_action(CHARACTER, 0, "home_key_deliver", _intent(), _context())
	var row: Dictionary = DELIVERY.make_record("new-world", NEW_WORLD, "new-epoch", stage, null, RECORD.errors)
	assert_false(row.is_empty())
	assert_true(authority.finish_creature_training(stage, true))
	assert_true(authority._training_locked(CHARACTER), "owner save/ACK still pending")
	assert_false(authority.acknowledge_creature_training(CHARACTER, row))
	row.status = "accepted"
	assert_true(authority.acknowledge_creature_training(CHARACTER, row))
	assert_false(authority._training_locked(CHARACTER))
	assert_eq(HOME.key_count(authority.state(CHARACTER)), 1)


func _legacy_alias(player: RefCounted) -> Dictionary:
	var duplicate := REWARD.make_record("duplicate-world", NEW_WORLD, "home_key:grant:" + CHARACTER,
		CHARACTER, "home_key", 1, "home_key_given")
	assert_true(REWARD.apply(player, duplicate).get("settled", false), "actual old producer suppresses this duplicate")
	return player.satchel_escrow[duplicate.delivery_id].duplicate(true)


func _roundtrip(player: RefCounted) -> RefCounted:
	var decoded: Variant = JSON.parse_string(JSON.stringify(player.save_data()))
	assert_true(decoded is Dictionary)
	var restored := _player()
	restored.load_data(decoded)
	return restored


func test_legacy_alias_of_full_bag_debt_survives_save_reload_and_admission_without_becoming_a_second_gift() -> void:
	var player := _player()
	_filled(player)
	var original := REWARD.make_record("origin-world", OLD_WORLD, "home_key:grant:" + CHARACTER,
		CHARACTER, "home_key", 1, "home_key_given")
	assert_false(REWARD.apply(player, original).get("settled", true))
	var alias := _legacy_alias(player)
	assert_eq(alias.finite_duplicate_of, original.delivery_id)
	assert_true(HOME.is_settled_alias(alias, CHARACTER))
	assert_false(HOME.valid_escrow(alias, CHARACTER), "alias alone remains ineligible as finite debt")
	var restored := _roundtrip(player)
	assert_true(ESSENCE._equivalent(restored.satchel_escrow[alias.delivery_id], alias), "migration preserves the existing alias receipt")
	var projected := RECORD.portable_projection(restored.save_data())
	assert_true(projected.portal_escrow.has(original.delivery_id))
	assert_false(projected.portal_escrow.has(alias.delivery_id), "only original debt enters the authority carrier")
	assert_true(RECORD.errors(projected, CHARACTER).is_empty())
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world(NEW_WORLD))
	var admitted: Dictionary = authority.seed_admitted_character(projected, CHARACTER)
	assert_true(admitted.get("ok", false))
	if not admitted.get("ok", false): return
	assert_eq(HOME.key_count(authority.state(CHARACTER)), 0)
	assert_eq(HOME.stage(authority.state(CHARACTER), "home_key_deliver", _intent(), _context()).get("code"), "home_key_bag_full")
	var alias_intent := {"delivery_id": alias.delivery_id, "origin_namespace": NEW_WORLD}
	var alias_context := _context()
	alias_context.home_key_record = alias
	alias_context.source_key = "opening_home_key:" + str(alias.delivery_id)
	assert_false(HOME.stage(authority.state(CHARACTER), "home_key_deliver", alias_intent, alias_context).get("ok", false))
	restored.inventory.set_slot(0, null)
	var plan := FOUNDATION.stage(RECORD.portable_projection(restored.save_data()), 0,
		"home_key_deliver", _intent(), _context(), RECORD.errors)
	assert_true(plan.get("ok", false))
	if not plan.get("ok", false): return
	assert_eq(HOME.key_count(plan.state), 1)
	assert_eq(plan.state.portal_escrow[original.delivery_id].status, "settled")
	assert_false(plan.state.portal_escrow.has(alias.delivery_id))


func test_legacy_alias_of_saved_given_flag_preserves_one_physical_key_and_all_saved_receipts() -> void:
	var player := _player()
	var original := REWARD.make_record("origin-world", OLD_WORLD, "home_key:grant:" + CHARACTER,
		CHARACTER, "home_key", 1, "home_key_given")
	assert_true(REWARD.apply(player, original).get("settled", false))
	player.redesign_character.transaction_receipts.append("craft:legacy_kept:" + CHARACTER)
	var alias := _legacy_alias(player)
	assert_eq(alias.finite_duplicate_of, "home_key_given")
	alias.room_message_shown = true # This optional legacy field is also preserved.
	player.satchel_escrow[alias.delivery_id] = alias
	assert_true(HOME.is_settled_alias(alias, CHARACTER))
	var restored := _roundtrip(player)
	assert_true(ESSENCE._equivalent(restored.satchel_escrow[alias.delivery_id], alias))
	var projected := RECORD.portable_projection(restored.save_data())
	assert_true(RECORD.errors(projected, CHARACTER).is_empty())
	assert_eq(projected.redesign_character.transaction_receipts, player.redesign_character.transaction_receipts)
	assert_false(projected.portal_escrow.has(alias.delivery_id))
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world(NEW_WORLD))
	var admitted: Dictionary = authority.seed_admitted_character(projected, CHARACTER)
	assert_true(admitted.get("ok", false))
	if not admitted.get("ok", false): return
	assert_eq(HOME.key_count(authority.state(CHARACTER)), 1)
	assert_true(restored.flags.call("has", "home_key_given"))
	assert_eq(restored.inventory.count("home_key"), 1)


func test_malformed_aliases_and_wrong_escrow_keys_are_not_silently_excluded_from_admission_validation() -> void:
	var player := _player()
	_filled(player)
	player.satchel_escrow[_due().delivery_id] = _due()
	var alias := _legacy_alias(player)
	var bad_markers: Array = ["", "trainer:unrelated", "F".repeat(64), str(alias.delivery_id), 1]
	for marker: Variant in bad_markers:
		var bad := alias.duplicate(true)
		bad.finite_duplicate_of = marker
		player.satchel_escrow[alias.delivery_id] = bad
		assert_false(HOME.is_settled_alias(bad, CHARACTER))
		var projected := RECORD.portable_projection(player.save_data())
		assert_true(projected.portal_escrow.has(alias.delivery_id))
		assert_false(RECORD.errors(projected, CHARACTER).is_empty(), "malformed alias is explicitly refused")
	var owed_alias := alias.duplicate(true)
	owed_alias.status = "grant_due"
	owed_alias.stacks = [{"id": "home_key", "n": 1}]
	owed_alias.completion_flag = "home_key_given"
	player.satchel_escrow[alias.delivery_id] = owed_alias
	assert_false(HOME.is_settled_alias(owed_alias, CHARACTER))
	assert_false(RECORD.errors(RECORD.portable_projection(player.save_data()), CHARACTER).is_empty())
	player.satchel_escrow.erase(alias.delivery_id)
	player.satchel_escrow["wrong-key"] = alias
	assert_false(RECORD.errors(RECORD.portable_projection(player.save_data()), CHARACTER).is_empty(), "mismatched key is not a valid legacy alias mapping")
