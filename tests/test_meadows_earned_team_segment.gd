extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/meadows_earned_team_segment.gd")
const TOURNAMENT := preload("res://scripts/world/tournament.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")


class Admission extends Node:
	var admitted: Node3D
	var fighting := true
	func enemy_body() -> Node3D:
		return admitted
	func is_fighting() -> bool:
		return fighting


func test_training_selection_prefers_the_eligible_current_offer_before_latching_identity() -> void:
	assert_eq(SEGMENT.preferred_candidate_index([120.0, 4.0, 8.0], 1), 1,
		"the offered nearby candidate must win over a distant lower-level candidate")
	assert_eq(SEGMENT.preferred_candidate_index([4.0, 4.0], 1), 1,
		"a contested equal-distance offer must retain production's exact chosen body")
	assert_eq(SEGMENT.preferred_candidate_index([4.0, 4.1], 1), 1,
		"a valid offer sampled in this frame wins over a second opinion of its tie")
	assert_eq(SEGMENT.preferred_candidate_index([120.0, 8.0, 20.0], -1), 1,
		"without an eligible offer, approach the nearest eligible live candidate")
	assert_eq(SEGMENT.preferred_candidate_index([120.0, 8.0, 20.0], 7), 1,
		"an offer outside the already-filtered list cannot bypass species/level/ownership limits")
	assert_eq(SEGMENT.preferred_candidate_index([], -1), -1)
	assert_eq(SEGMENT.preferred_candidate_index([INF, NAN, -2.0], -1), -1)
	assert_eq(SEGMENT.APPROACH_FRAMES, 3600, "selection repair does not extend the failed approach deadline")


func test_engagement_checks_the_admitted_body_after_the_input_frame() -> void:
	var selected := Node3D.new()
	selected.name = "Bramblebun"
	var nearby := Node3D.new()
	nearby.name = "Mudsnout"
	var combat := Admission.new()
	var segment := SEGMENT.new()
	segment._combat = combat
	combat.admitted = selected
	assert_true(segment._verify_engagement(selected))
	# The input had a valid Bramblebun offer; a subsequent admission must still
	# be that body before any chip, aim or throw consumes the chosen reference.
	combat.admitted = nearby
	assert_false(segment._verify_engagement(selected))
	assert_true(str(segment.result().failures).contains("Mudsnout"))
	combat.admitted = selected
	combat.fighting = false
	assert_false(segment._verify_engagement(selected))
	selected.free()
	nearby.free()
	combat.free()


func test_missing_live_context_cannot_create_or_complete_preparation() -> void:
	var segment := SEGMENT.new()
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_eq(observed.world, null)
	assert_true(not observed.failures.is_empty())


func test_catch_receipt_rejects_replacement_reorder_duplicate_and_sixth_member() -> void:
	assert_true(SEGMENT.one_new_member([10, 20], [10, 20, 30]))
	assert_false(SEGMENT.one_new_member([10, 20], [10, 20]))
	assert_false(SEGMENT.one_new_member([10, 20], [10, 30, 40]))
	assert_false(SEGMENT.one_new_member([10, 20], [20, 10, 30]))
	assert_false(SEGMENT.one_new_member([10, 20], [10, 20, 10]))
	assert_false(SEGMENT.one_new_member([1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 6]))


func test_training_receipt_accepts_level_rollover_but_rejects_no_xp_and_replacement() -> void:
	var before: Array[Dictionary] = [{"id": 10, "level": 2, "xp": 80}]
	assert_true(SEGMENT.earned_training_progress(before, [{"id": 10, "level": 3, "xp": 2}]))
	assert_true(SEGMENT.earned_training_progress(before, [{"id": 10, "level": 2, "xp": 90}]))
	assert_false(SEGMENT.earned_training_progress(before, before))
	assert_false(SEGMENT.earned_training_progress(before, [{"id": 20, "level": 3, "xp": 2}]))
	assert_false(SEGMENT.earned_training_progress(before, []))
	assert_false(SEGMENT.earned_training_progress(
		[{"id": 10, "level": 2, "xp": 80}, {"id": 20, "level": 3, "xp": 50}],
		[{"id": 10, "level": 3, "xp": 2}, {"id": 20, "level": 3, "xp": 0}]),
		"one member's progress cannot hide another member's lost XP")


func test_shared_care_refuses_missing_context_without_spending_or_receipts() -> void:
	var segment := SEGMENT.new()
	var observed: Dictionary = await segment.care_existing(null, null, null, "berries", 0)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])


func test_earned_requirement_uses_real_tournament_roster_and_training_rules() -> void:
	var party := PARTY.new()
	for index in TOURNAMENT.required_party_size():
		var creature: RefCounted = SPECIES.spawn("bramblebun")
		creature.call("set_level", TOURNAMENT.required_level(), PROGRESSION.config())
		party.add(creature)
	assert_true(TOURNAMENT.team_ready(party))
	assert_true(TOURNAMENT.training_ready(party))
	party.at(0).set_level(TOURNAMENT.required_level() - 1, PROGRESSION.config())
	assert_true(TOURNAMENT.team_ready(party))
	assert_false(TOURNAMENT.training_ready(party))


func test_live_preparation_has_no_state_injection_or_direct_interaction_callbacks() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_team_segment.gd")
	for forbidden: String in ["reset_for_new_game", "set_flag(", "inventory.add(",
		"party.add(", "set_level(", "take_damage(", "gain_xp(", "heal(", "revive(",
		"_begin_resolve(", "load_game(", "save_game(", "global_position =",
		"set_physics_process(", "set_process(", "rig.set(", "cycle_active(",
		"interaction_activate(", "_on_target_row(", "_hold_the_fight_where_it_was("]:
		assert_false(source.contains(forbidden), "earned route may not bypass input: " + forbidden)
