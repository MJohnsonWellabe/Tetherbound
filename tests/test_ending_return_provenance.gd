extends "res://tests/test_case.gd"

const HOME := preload("res://scripts/story/regional_homecoming.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")

func test_return_requires_same_finale_world_and_character_and_is_order_independent() -> void:
	var outcome := "stormwood:legendary_answer:original:refused"
	var prefix := HOME.return_prefix("world_a", outcome)
	var marker := prefix + "permit_a:alice"
	var receipts := ["craft:home_return_world_a_before_finale:alice", marker,
		prefix + "permit_z:alice", prefix + "permit_0:bob"]
	assert_eq(HOME.home_return_receipt(receipts, "world_a", "alice", outcome), marker)
	receipts.reverse()
	assert_eq(HOME.home_return_receipt(receipts, "world_a", "alice", outcome), marker)
	assert_eq(HOME.home_return_receipt(receipts, "world_b", "alice", outcome), "")
	assert_eq(HOME.home_return_receipt(receipts, "world_a", "alice", outcome.replace("original", "later")), "")
	assert_eq(HOME.home_return_receipt([receipts[0]], "world_a", "alice", outcome), "")
	assert_eq(HOME.return_prefix("world_a", ""), "")

func test_personal_outcome_requires_saved_original_answer_not_a_world_flag() -> void:
	var flags := {"stormwood:stormheart_freed": true}
	assert_eq(HOME.personal_outcome(flags), "")
	flags["stormwood:legendary_ceremony_settled"] = true
	flags["stormwood:legendary_answer:original:refused"] = true
	flags["stormwood:regional_outcome:original:refused"] = true
	assert_eq(HOME.personal_outcome(flags), "stormwood:legendary_answer:original:refused")
	flags["stormwood:legendary_answer:later:accepted"] = true
	assert_eq(HOME.personal_outcome(flags), "stormwood:legendary_answer:original:refused")
	flags["stormwood:regional_outcome:later:accepted"] = true
	assert_eq(HOME.personal_outcome(flags), "")

func test_grounded_arrival_mints_ending_marker_only_with_authoritative_finale_context() -> void:
	var current := {"character_id": "alice", "redesign_character": {"transaction_receipts": []}}
	var intent := {"permit_id": "permit_a", "realm": "meadows", "entry_id": "hall_home"}
	var context := {"world_namespace": "world_a", "grounded_arrival": true,
		"permit_id": "permit_a", "realm": "meadows", "entry_id": "hall_home"}
	var before: Dictionary = ACTIONS._acknowledgement(current, "portal_arrival", intent, context)
	assert_true(before.ok)
	assert_eq(HOME.home_return_receipt(before.state.redesign_character.transaction_receipts, "world_a", "alice", "stormwood:legendary_answer:original:refused"), "")
	context.ending_outcome = "stormwood:legendary_answer:original:refused"
	var after: Dictionary = ACTIONS._acknowledgement(current, "portal_arrival", intent, context)
	assert_true(after.ok)
	assert_eq(HOME.home_return_receipt(after.state.redesign_character.transaction_receipts, "world_a", "alice", context.ending_outcome),
		HOME.return_prefix("world_a", context.ending_outcome) + "permit_a:alice")
	assert_true(current.redesign_character.transaction_receipts.is_empty(), "staging never mutates admitted state before durable commit")
