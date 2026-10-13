extends "res://tests/test_case.gd"

const ACTOR := preload("res://scripts/net/actor_vitals_delivery.gd")

const WORLD_ID := "stormwood_world"
const WORLD_NAMESPACE := "stormwood_namespace"
const CHARACTER_ID := "owner_d5"
const CREATURE_UID := "creature-d5-session-replay"
const MAX_HP := 472.8


func _record(session_id: String, character_revision: int, vitals_revision: int,
		previous: Variant = null, expected_hp: float = MAX_HP, hp: float = 461.6) -> Dictionary:
	var receipt := {
		"receipt_id": "host:%s:%d" % [session_id, vitals_revision],
		"encounter_id": "1:1",
		"creature_uid": CREATURE_UID,
		"body_generation": 1,
		"vitals_revision": vitals_revision,
	}
	return ACTOR.next_record(WORLD_ID, WORLD_NAMESPACE, session_id, CHARACTER_ID, CREATURE_UID,
		MAX_HP, expected_hp, expected_hp == 0.0, hp, hp == 0.0,
		character_revision, receipt, previous)


func test_new_host_session_can_restart_local_receipt_sequence_without_weakening_global_cas() -> void:
	var previous := _record("session_old", 11516, 6)
	assert_false(previous.is_empty(), "construct the retained D4-style actor vitals row")
	if previous.is_empty():
		return
	previous.status = "accepted"

	var restarted := _record("session_new", 12336, 1, previous, 461.6, 450.0)
	assert_false(restarted.is_empty(),
		"a host-owned new session can begin a fresh encounter-local receipt sequence")
	if restarted.is_empty():
		return
	assert_eq(restarted.session_id, "session_new")
	assert_eq(restarted.character_revision, 12336)
	assert_eq(restarted.journal_revision, previous.journal_revision + 1)

	var same_session_replay := _record("session_old", 12336, 6, previous, 461.6, 450.0)
	assert_true(same_session_replay.is_empty(),
		"same-session encounter/body receipt revisions remain monotonic")

	var stale_global_revision := _record("session_new", 11516, 1, previous, 461.6, 450.0)
	assert_true(stale_global_revision.is_empty(),
		"session changes never bypass the character-wide revision CAS")


func test_new_session_preserves_pending_owner_cas_baseline() -> void:
	var pending := _record("session_old", 11516, 6, null, MAX_HP, 461.6)
	assert_false(pending.is_empty())
	if pending.is_empty():
		return

	var successor := _record("session_new", 12336, 1, pending, 461.6, 450.0)
	assert_false(successor.is_empty(),
		"a different host session can continue the same character's delivery stream")
	if successor.is_empty():
		return
	assert_eq(successor.expected_hp, pending.expected_hp,
		"the oldest unsettled owner HP baseline survives a session transition")
	assert_eq(successor.expected_fainted, pending.expected_fainted,
		"the oldest unsettled faint baseline survives a session transition")
