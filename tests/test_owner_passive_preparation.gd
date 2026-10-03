extends "res://tests/test_case.gd"

## Pure exact-input replay and the real authority CAS. Fixtures disclose the
## retained source and trusted host context; no transport or actual save proof.
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const AUTH := preload("res://scripts/net/character_authority.gd")
const FIXTURE := preload("res://tests/test_research_passive_preparation.gd")
const GROOM := preload("res://tests/test_den_groom_saved_transaction.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const E := preload("res://scripts/creatures/essence.gd")

func _capture_event() -> Dictionary:
	var creature := preload("res://scripts/creatures/creature_species.gd").spawn("mosshell")
	var traits := preload("res://scripts/creatures/traits.gd").roll_spawn("resource-namespace", "checkpoint-caught-source", 1, true, false, false)
	var offer := {"offer_id": "checkpoint-catch", "source_key": "capture:checkpoint-catch",
		"world_namespace": "resource-namespace", "session_id": "original-epoch", "participants": [DATA.CHARACTER],
		"realm": "meadows", "creature": preload("res://scripts/save/water_capture_codec.gd").encode(creature), "capture_traits": traits}
	var duty := {"character_id": DATA.CHARACTER, "action": "capture_offer", "intent": {}, "context": offer}
	return preload("res://scripts/net/foundation_event.gd").make(DATA.new()._world(), "original-epoch", offer.source_key, [duty])

func _fixture() -> Dictionary:
	var before: Dictionary = GROOM.new()._before()
	var cursor := REPLAY.begin(before, {"meadows": ["admitted_history"]})
	var uids: Array = []
	for card: Dictionary in before.party: uids.append(card.uid)
	var replay := REPLAY.apply(cursor, {"version": 1, "sequence": 1, "op": "condition", "delta": 0.016666666666667, "uids": uids},
		{"max_elapsed": 1.0, "max_speed": 20.0, "realm": "meadows", "landmarks": {}})
	assert_true(replay.ok)
	var event: Dictionary = FIXTURE.new()._event()
	var prepared := PREP.make(event, event.duties[0], before, 0, "current-epoch", replay.cursor, DATA.TXN)
	assert_false(prepared.is_empty())
	var authority := AUTH.new()
	assert_true(authority.bind_world("resource-namespace"))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).ok)
	assert_true(authority.seed_discovered_landmarks(DATA.CHARACTER, cursor.discovered))
	return {"before": before, "cursor": replay.cursor, "event": event, "prepared": prepared, "authority": authority}

func test_owner_requires_full_exact_checkpoint_and_original_source() -> void:
	var f := _fixture()
	assert_true(PREP.make(f.event, f.event.duties[0], f.before, 0, "current-epoch", {"state": 4, "discovered": []}, DATA.TXN).is_empty())
	assert_true(PREP.valid_host(f.prepared, f.event, f.cursor))
	assert_true(PREP.owner_plan(f.prepared.after, f.prepared, f.event, f.prepared.discoveries).ok)
	assert_false(PREP.owner_plan(f.before, f.prepared, f.event, f.prepared.discoveries).ok, "owner must already match; preparation never installs care")
	var changed: Dictionary = f.prepared.after.duplicate(true)
	changed.party[0].distance_m_together += 0.000001
	assert_false(PREP.owner_plan(changed, f.prepared, f.event, f.prepared.discoveries).ok)
	assert_false(PREP.owner_plan(f.prepared.after, f.prepared, f.event, {}).ok, "discovery checkpoint is exact too")
	var other: Dictionary = f.event.duplicate(true)
	other.duties[0].context.species_id = "mudsnout"
	assert_false(PREP.valid(f.prepared, other))
	for field: String in ["final_sequence", "input_prefix_hash", "after"]:
		var candidate: Dictionary = f.prepared.duplicate(true)
		if field == "final_sequence": candidate.final_sequence += 1
		elif field == "input_prefix_hash": candidate.input_prefix_hash = "a".repeat(64)
		else: candidate.after.party[0].happiness -= 0.000001
		candidate.hash = PREP.preparation_hash(candidate)
		assert_false(PREP.valid_host(candidate, f.event, f.cursor), field)
	var large := {"landmarks_visited_together": 9007199254740992}
	var next := {"landmarks_visited_together": 9007199254740993}
	assert_false(PREP.exact(large, next), "full checkpoint preserves distinct int64 counters")

func test_reservation_requires_local_cursor_and_same_existing_lock() -> void:
	var f := _fixture()
	var authority: RefCounted = f.authority
	assert_false(authority.reserve_research_preparation(DATA.CHARACTER, f.prepared, f.event), "a valid owner packet has no host cursor capability")
	assert_false(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, {}))
	assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, f.cursor))
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, f.cursor))
	assert_true(authority.creature_training_is_pending(DATA.CHARACTER))
	assert_eq(authority.revision(DATA.CHARACTER), 0)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), f.before))
	assert_eq(authority.stage_portal_debit(DATA.CHARACTER, "water", "unused").code, "transaction_busy")
	assert_false(authority.bind_world("another-world"))
	assert_false(authority.cancel_owner_passive_checkpoint(DATA.CHARACTER, "foreign"))
	for lock: String in ["_training_stages", "_training_pending", "_portal_stages", "_loadout_pending", "_vitals_pending", "_vitals_stages", "_groom_preparations"]:
		var separate := _fixture()
		separate.authority.set(lock, {DATA.CHARACTER: {"fixture": true}})
		assert_false(separate.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, separate.prepared, separate.event, separate.cursor), lock)

func test_exact_cas_retry_after_failed_real_research_stage_and_stale_ack() -> void:
	var f := _fixture()
	var authority: RefCounted = f.authority
	assert_true(authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, f.prepared, f.event, f.cursor))
	# Test models an authenticated successful owner save at this call boundary.
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_eq(authority.revision(DATA.CHARACTER), 1)
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), f.prepared.after))
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	var context: Dictionary = f.event.duties[0].context.duplicate(true)
	context.character_id = DATA.CHARACTER
	context.expected_revision = 1
	context.in_range = true
	var stage: Dictionary = authority.stage_character_action(DATA.CHARACTER, 1, "research_event", {}, context)
	assert_true(stage.get("ok") == true, str(stage))
	if stage.get("ok") != true: return
	assert_false(authority.retain_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(authority.finish_creature_training(stage, false))
	assert_true(authority.retain_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_eq(authority.revision(DATA.CHARACTER), 1, "original prefix applied only once")
	assert_true(authority.cancel_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_false(authority.commit_owner_passive_checkpoint(DATA.CHARACTER, f.prepared.hash))
	assert_true(E._equivalent(authority.state(DATA.CHARACTER), f.prepared.after), "cancel never rolls back saved checkpoint")

func test_capture_checkpoint_binds_original_offer_without_granting_its_creature() -> void:
	var f := _fixture()
	var capture := _capture_event()
	assert_false(capture.is_empty())
	var prepared := PREP.make(capture, capture.duties[0], f.before, 0, "current-epoch", f.cursor, DATA.TXN)
	assert_false(prepared.is_empty())
	assert_true(PREP.valid_host(prepared, capture, f.cursor))
	assert_eq(prepared.after.party.size(), f.before.party.size(), "checkpoint changes no roster; original capture handler owns the later choice")
	assert_true(PREP.exact(prepared.after, f.cursor.state))
	assert_true(f.authority.reserve_owner_passive_checkpoint(DATA.CHARACTER, prepared, capture, f.cursor))
	assert_true(f.authority.commit_owner_passive_checkpoint(DATA.CHARACTER, prepared.hash))
	assert_eq(f.authority.state(DATA.CHARACTER).party.size(), f.before.party.size())
	var substituted := capture.duplicate(true)
	substituted.duties[0].context.creature.nickname = "changed after preparation"
	assert_false(PREP.valid(prepared, substituted), "full retained creature offer remains immutable")
	var selected := capture.duplicate(true)
	selected.duties[0].intent = {"offer_id": "checkpoint-catch", "keep": true, "released_uid": ""}
	assert_true(PREP.make(selected, selected.duties[0], f.before, 0, "current-epoch", f.cursor, DATA.TXN).is_empty(),
		"capture choice must not rewrite the original empty-intent offer duty")
	var unsupported := capture.duplicate(true)
	unsupported.duties[0].action = "wild_capture"
	assert_true(PREP.make(unsupported, unsupported.duties[0], f.before, 0, "current-epoch", f.cursor, DATA.TXN).is_empty())
