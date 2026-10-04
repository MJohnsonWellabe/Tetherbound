extends "res://tests/test_case.gd"

## Real authority CAS with disclosed event/observation fixtures. Direct private
## lock insertion below models competing transactions, not their production
## writers. No actual owner BOOL write, transport, or F48 proof is claimed.
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const PREP := preload("res://scripts/net/research_passive_preparation.gd")
const CODEC_TEST := preload("res://tests/test_research_passive_preparation.gd")
const GROOM_TEST := preload("res://tests/test_guest_groom_passive_sync.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const E := preload("res://scripts/creatures/essence.gd")

func _authority(before: Dictionary) -> RefCounted:
	var authority := AUTHORITY.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(authority.seed_discovered_landmarks(DATA.CHARACTER, {"meadows": ["admitted_history"]}))
	return authority

func _prepared(before: Dictionary, event: Dictionary) -> Dictionary:
	return PREP.make(event, event.duties[0], before, 0, "current-epoch", 2.0, 4.0, 1,
		{"meadows": ["observed_landmark"]}, DATA.TXN)

func test_reserve_does_not_promote_before_bool_ack_and_rejoin_cannot_replace_it() -> void:
	var before := GROOM.new()._before()
	var event := CODEC_TEST.new()._event()
	var prepared := _prepared(before, event)
	var authority := _authority(before)
	assert_false(authority.commit_research_preparation(DATA.CHARACTER, prepared, event))
	assert_false(authority.retain_research_preparation(DATA.CHARACTER, prepared, event))
	assert_true(authority.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	assert_true(authority.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	assert_eq(authority.revision(DATA.CHARACTER), 0)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), before), "no ACK call means no promotion, including a failed owner writer")
	assert_true(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_true(authority.seed_admitted_character(prepared.after, DATA.CHARACTER).already_seeded)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), before), "rejoin hello cannot rebase the reserved original")
	assert_true(authority.recover_durable_vitals(DATA.CHARACTER, {}).ok, "read-only admission recovery still works")
	assert_true(authority.recover_durable_training(DATA.CHARACTER, {}).ok)
	assert_false(authority.bind_world("another-world"))
	assert_false(authority.cancel_research_preparation(DATA.CHARACTER, "foreign"))
	assert_true(authority.cancel_research_preparation(DATA.CHARACTER, prepared.hash))
	assert_false(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), before))

func test_research_and_existing_transaction_reservations_exclude_each_other() -> void:
	var before := GROOM.new()._before()
	var event := CODEC_TEST.new()._event()
	var prepared := _prepared(before, event)
	for lock: String in ["_training_stages", "_training_pending", "_portal_stages", "_loadout_pending", "_vitals_pending", "_vitals_stages"]:
		var authority := _authority(before)
		authority.set(lock, {DATA.CHARACTER: {"disclosed_transaction_fixture": true}})
		assert_false(authority.reserve_research_preparation(DATA.CHARACTER, prepared, event), lock)
	var portal_pending := _authority(before)
	portal_pending.bind_portal_pending_reader(func(_character: String) -> bool: return true)
	assert_false(portal_pending.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	var groom := GROOM_TEST.new()._prepared(before)
	var groom_first := _authority(before)
	assert_true(groom_first.reserve_groom_preparation(DATA.CHARACTER, groom))
	assert_false(groom_first.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	var authority := _authority(before)
	assert_true(authority.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	assert_false(authority.reserve_groom_preparation(DATA.CHARACTER, groom))
	assert_eq(authority.stage_portal_debit(DATA.CHARACTER, "water", "unused").code, "transaction_busy")
	assert_eq(authority.stage_character_action(DATA.CHARACTER, 0, "research_event", {}, event.duties[0].context).code, "transaction_busy")
	assert_eq(authority.commit_creature_loadout(DATA.CHARACTER, before.party[0].uid, 0, 0, {}, {}, 1, {}).code, "transaction_busy")
	assert_eq(authority.commit_creature_vitals(DATA.CHARACTER, before.party[0].uid, 0, 1.0, false, 1.0, false, {}).code, "transaction_busy")
	assert_eq(authority.commit_creature_mastery(DATA.CHARACTER, before.party[0].uid, 0, {}, {}, {}, {}).code, "transaction_busy")
	assert_true(authority.refresh_host_local(prepared.after, DATA.CHARACTER).pending_transaction)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), before))

func test_commit_and_failed_world_write_retry_preserve_exact_original() -> void:
	var before := GROOM.new()._before()
	var event := CODEC_TEST.new()._event()
	var prepared := _prepared(before, event)
	var authority := _authority(before)
	assert_true(authority.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	# Explicit fixture: production may call only after authenticated BOOL-save.
	assert_true(authority.commit_research_preparation(DATA.CHARACTER, prepared, event))
	assert_eq(authority.revision(DATA.CHARACTER), 1)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), prepared.after))
	assert_eq(authority.discovered_landmarks(DATA.CHARACTER).meadows, ["admitted_history", "observed_landmark"])
	assert_false(authority.creature_training_is_pending(DATA.CHARACTER), "synchronous real research stage may now acquire the training lock")
	assert_true(authority.commit_research_preparation(DATA.CHARACTER, prepared, event), "same ACK does not promote twice")
	assert_eq(authority.revision(DATA.CHARACTER), 1)
	var context: Dictionary = event.duties[0].context.duplicate(true)
	context.character_id = DATA.CHARACTER
	context.expected_revision = 1
	context.in_range = true
	var stage: Dictionary = authority.stage_character_action(DATA.CHARACTER, 1, "research_event", {}, context)
	assert_true(stage.get("ok") == true, str(stage))
	if stage.get("ok") != true: return
	assert_false(authority.retain_research_preparation(DATA.CHARACTER, prepared, event), "cannot retain over an active real world stage")
	assert_true(authority.finish_creature_training(stage, false), "actual registry rollback for a failed world writer")
	assert_true(authority.retain_research_preparation(DATA.CHARACTER, prepared, event))
	assert_true(authority.retain_research_preparation(DATA.CHARACTER, prepared, event))
	assert_true(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_true(authority.commit_research_preparation(DATA.CHARACTER, prepared, event))
	assert_eq(authority.revision(DATA.CHARACTER), 1, "recommit never repeats elapsed time or discoveries")
	assert_true(authority.cancel_research_preparation(DATA.CHARACTER, prepared.hash))
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), prepared.after), "cancel cannot undo an owner-saved baseline")
	assert_false(authority.commit_research_preparation(DATA.CHARACTER, prepared, event), "no unreserved ACK replay after cleanup")

func test_revision_core_hash_and_retained_source_changes_refuse_without_mutation() -> void:
	var before := GROOM.new()._before()
	var event := CODEC_TEST.new()._event()
	var prepared := _prepared(before, event)
	var authority := _authority(before)
	var stale := prepared.duplicate(true)
	stale.revision = 1
	stale.hash = PREP.preparation_hash(stale)
	assert_false(authority.reserve_research_preparation(DATA.CHARACTER, stale, event))
	var wrong_before := before.duplicate(true)
	wrong_before.party[0].hp = maxf(0.0, float(wrong_before.party[0].hp) - 1.0)
	assert_false(authority.reserve_research_preparation(DATA.CHARACTER, _prepared(wrong_before, event), event))
	assert_false(authority.reserve_research_preparation("foreign", prepared, event))
	assert_true(authority.reserve_research_preparation(DATA.CHARACTER, prepared, event))
	var changed := event.duplicate(true)
	changed.duties[0].context.species_id = "mudsnout"
	assert_false(authority.commit_research_preparation(DATA.CHARACTER, prepared, changed))
	var forged := prepared.duplicate(true)
	forged.hash = "0".repeat(64)
	assert_false(authority.commit_research_preparation(DATA.CHARACTER, forged, event))
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), before))
	assert_true(authority.commit_research_preparation(DATA.CHARACTER, prepared, event))
	var replacement := PREP.make(event, event.duties[0], before, 0, "current-epoch", 2.0, 4.0, 1,
		{"meadows": ["observed_landmark"]}, GROOM.SECOND)
	assert_false(authority.retain_research_preparation(DATA.CHARACTER, replacement, event), "equal after-state cannot substitute another original")
	var later: Dictionary = prepared.after.duplicate(true)
	later.party[0].distance_m_together += 1.0
	assert_true(authority.refresh_host_local(later, DATA.CHARACTER).ok)
	assert_false(authority.commit_research_preparation(DATA.CHARACTER, prepared, event))
	assert_false(authority.retain_research_preparation(DATA.CHARACTER, prepared, event))
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), later), "old ACK cannot roll back later state")
