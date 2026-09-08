extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_earned_rootgate_segment.gd")

class QuietSegment extends SEGMENT:
	func _fail(message: String) -> bool:
		failures.append(message)
		return false

func test_guardian_approach_stays_outside_real_capsules_as_species_grow() -> void:
	for radii in [Vector2(1.1, 0.4), Vector2(2.4, 0.4)]:
		var stance := SEGMENT.guardian_stance(Vector3(700, 74, 2700), Vector3(700, 74, 2690), radii.x, radii.y)
		assert_true(stance.distance_to(Vector2(700, 2700)) > radii.x + radii.y,
			"walking to the chosen stance must not require entering the guardian capsule")
		assert_almost_eq(stance.x, 700.0, 0.001)
		assert_true(stance.y < 2700)
	assert_false(SEGMENT.guardian_stance(Vector3.ZERO, Vector3.ZERO, 1.1, 0.4).is_zero_approx())

func test_null_tree_is_a_missing_earned_entry_not_a_scene_access() -> void:
	var segment := QuietSegment.new()
	var observed: Dictionary = await segment.run(null, null, null)
	assert_false(observed.passed)

func test_entry_requires_the_actual_paid_linked_crown_record() -> void:
	var record := {"id": "stormglass_arch", "realm": "stormwood", "paid": true,
		"arch_twin": "e_crown", "arch_footing": "still_grove", "uid": "actual-build-id"}
	assert_eq(SEGMENT.paid_crown_record([record]), record)
	for key in ["paid", "arch_twin", "arch_footing", "uid", "realm"]:
		var invalid := record.duplicate()
		invalid.erase(key)
		assert_true(SEGMENT.paid_crown_record([invalid]).is_empty(), "missing " + key + " must refuse")
	var removed := record.duplicate()
	removed.removed = true
	assert_true(SEGMENT.paid_crown_record([removed]).is_empty())
	assert_true(SEGMENT.paid_crown_record([]).is_empty())

func test_new_helper_cannot_claim_completion_from_paid_arch_alone() -> void:
	var segment := SEGMENT.new()
	assert_false(segment.result().passed)
	assert_eq(segment.result().endpoint, "earned Rootgate / Act II")

func test_live_endpoint_preserves_named_guardian_truth_and_barrier_requirements() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_rootgate_segment.gd")
	for bypass in ["global_position =", "set(\"pending_build\"", "progression\").call(\"set\"",
		"call(\"emit_event\"", "call(\"travel_for_peer\"", "call(\"enter_realm\"", "face_towards"]:
		assert_false(source.contains(bypass), "earned segment must not bypass " + bypass)
	for contract in ["stormwood:named:crown_guardian:cleared", "stormwood:engine_truth_learned",
		"stormwood:rootgate_released", "stormwood:act_ii_complete", "collision.disabled",
		"_roster_ids() != _party_before", "build_cancel"]:
		assert_true(source.contains(contract), "endpoint retains " + contract)
