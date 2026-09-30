extends "res://tests/test_case.gd"

const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const PORTAL := preload("res://scripts/world/portal_arch.gd")


func _portable(with_key := false, with_creature := false) -> Dictionary:
	var player := PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "owner_a"
	if with_key:
		player.inventory.add("tidewake_portal_key", 1)
	if with_creature:
		player.party.add(INSTANCE.from_species("terrapup", SPECIES.table().terrapup))
	var saved: Dictionary = player.save_data()
	saved.redesign_character = TEACHING.character_loadout_mirror(saved.party, saved.redesign_character)
	return AUTHORITY.portable_projection(saved)


func test_admission_and_rejoin_cannot_replace_or_mutate_owned_baseline() -> void:
	var authority := AUTHORITY.new()
	var original := _portable(true)
	assert_false(authority.seed_admitted_character(original, "owner_a").ok, "world identity is required first")
	assert_true(authority.bind_world("world_a"))
	assert_true(authority.seed_admitted_character(original, "owner_a").ok)
	var detached := authority.state("owner_a")
	detached.inventory[0] = null
	assert_eq(authority.protected_keys("owner_a").tidewake_portal_key, 1, "export cannot erase admitted ownership")
	var stale := _portable()
	var rejoined := authority.seed_admitted_character(stale, "owner_a")
	assert_true(rejoined.ok and rejoined.already_seeded)
	assert_eq(authority.protected_keys("owner_a").tidewake_portal_key, 1, "rejoin retains accepted state")
	assert_false(authority.seed_admitted_character(original, "other_owner").ok, "transport owner and document must match")
	var unknown := original.duplicate(true)
	unknown.inventory[0] = {"id": "forged_portal_key", "n": 1}
	assert_false(authority.seed_admitted_character(unknown, "owner_a").ok, "even a rejoin payload must validate")
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), original))


func test_owned_portal_stage_promotes_only_frozen_state_and_rolls_back_failed_world_save() -> void:
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("world_a"))
	assert_true(authority.seed_admitted_character(_portable(), "owner_a").ok)
	var receipt := PORTAL.receipt("tidewake", "owner_a")
	assert_false(authority.stage_portal_debit("owner_a", "tidewake", receipt).ok,
		"a request cannot claim an absent inventory key")
	var owner := _portable(true)
	assert_true(authority.refresh_host_local(owner, "owner_a").ok)
	var before := authority.state("owner_a")
	var revision := authority.revision("owner_a")
	var stage := authority.stage_portal_debit("owner_a", "tidewake", receipt)
	assert_true(stage.ok)
	assert_false(authority.stage_portal_debit("owner_a", "tidewake", receipt).ok, "a pending stage cannot be replaced")
	assert_false(authority.bind_world("world_b"), "world switch cannot discard pending transaction")
	var forged := stage.duplicate(true)
	forged.token = "foreign_token"
	assert_false(authority.commit_portal_debit(forged))
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	assert_true(authority.commit_portal_debit(stage))
	assert_eq(authority.protected_keys("owner_a").tidewake_portal_key, 0)
	assert_true(authority.finish_portal_debit(stage, false), "failed synchronous world save rolls back hidden debit")
	assert_eq(authority.revision("owner_a"), revision)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a"), before))
	stage = authority.stage_portal_debit("owner_a", "tidewake", receipt)
	assert_true(authority.commit_portal_debit(stage))
	assert_true(authority.finish_portal_debit(stage, true))
	assert_false(authority.finish_portal_debit(stage, false), "retired token cannot refund a saved debit")
	assert_true(authority.seed_admitted_character(before, "owner_a").ok)
	assert_eq(authority.protected_keys("owner_a").tidewake_portal_key, 0, "stale rejoin cannot mint the spent key")
	assert_true(authority.stage_portal_debit("owner_a", "tidewake", receipt).duplicate)


func test_loadout_cas_retains_pending_edit_and_requires_matching_owner_save_ack() -> void:
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("world_a"))
	var original := _portable(false, true)
	assert_true(authority.seed_admitted_character(original, "owner_a").ok)
	var row: Dictionary = original.party[0]
	var slots := {"quick": row.move_quick, "charged": row.move_charged, "utility": row.move_utility}
	var edit := {"edit_id": "owned_station_edit_a", "expected_revision": 0,
		"creature_uid": row.uid, "quick": slots.quick, "charged": slots.charged, "utility": slots.utility}
	var accepted := authority.commit_creature_loadout("owner_a", row.uid, 0, 0, {}, slots, 1, edit)
	assert_true(accepted.ok and accepted.pending_owner_save)
	assert_eq(authority.state("owner_a").party[0].move_ultimate, row.move_ultimate)
	assert_true(AUTHORITY.equivalent(authority.state("owner_a").inventory, original.inventory))
	assert_true(authority.commit_creature_loadout("owner_a", row.uid, 0, 0, {}, slots, 1, edit).duplicate)
	assert_false(authority.commit_creature_mastery("owner_a", row.uid, 1, {}, {}, {}, {}).ok,
		"station edit awaits actual owner save before another mastery mutation")
	assert_false(authority.acknowledge_creature_loadout("owner_a", "foreign_uid", 1, edit))
	assert_false(authority.acknowledge_creature_loadout("owner_a", row.uid, 2, edit))
	var detached := authority.pending_creature_loadout("owner_a")
	detached.receipt.edit_id = "tampered_export"
	assert_eq(authority.pending_creature_loadout("owner_a").receipt.edit_id, edit.edit_id)
	assert_true(authority.seed_admitted_character(original, "owner_a").ok)
	assert_eq(authority.state("owner_a").party[0].loadout_revision, 1)
	assert_true(authority.acknowledge_creature_loadout("owner_a", row.uid, 1, edit))
	assert_true(authority.pending_creature_loadout("owner_a").is_empty())
	assert_false(authority.acknowledge_creature_loadout("owner_a", row.uid, 1, edit), "ACK replay is harmless")
