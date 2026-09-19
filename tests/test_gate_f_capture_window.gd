extends TestCase

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")


func test_background_keeps_all_prescribed_ids() -> void:
	var segment: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/gate_f/segments/S04C.json"))
	var plans := HARNESS._plan_captures(segment.steps)
	var ids: Array[String] = []
	for row: Dictionary in plans:
		if str(row.id).begins_with("S04-SEQ-final-"):
			ids.append(str(row.id))
	assert_eq(ids.size(), 40)
	assert_eq(ids[0], "S04-SEQ-final-000")
	assert_eq(ids[-1], "S04-SEQ-final-039")
	for id in ids:
		assert_true((segment.owes as Array).has(id))


func test_delayed_render_does_not_duplicate_one_frame_for_catchup() -> void:
	var sequence := {"attempted": 1, "count": 40, "last_rendered_frame": 50, "next_t": 1.0}
	assert_false(HARNESS._sequence_due(sequence, 8.0, 50))
	assert_true(HARNESS._sequence_due(sequence, 8.0, 51))
	sequence.last_rendered_frame = 51
	sequence.next_t = 9.0
	assert_false(HARNESS._sequence_due(sequence, 8.0, 52))
	sequence.attempted = 40
	assert_false(HARNESS._sequence_due(sequence, 60.0, 99))


func test_count_and_full_window_both_required() -> void:
	var sequence := {"id": "fixture", "start_t": 10.0, "seconds": 40.0, "count": 40,
		"attempted": 40, "written": 40, "combat_frames": 12, "aftermath_frames": 28}
	assert_false(bool(HARNESS._sequence_result(sequence, 49.0).complete))
	var complete: Dictionary = HARNESS._sequence_result(sequence, 50.0)
	assert_true(bool(complete.complete))
	assert_true(str(complete.actual).contains("combat=12, aftermath=28"))
	sequence.trainer_transition_frames = 3
	sequence.aftermath_frames = 25
	assert_true(str(HARNESS._sequence_result(sequence, 50.0).actual).contains("trainer_transition=3"))
	sequence.written = 39
	assert_false(bool(HARNESS._sequence_result(sequence, 90.0).complete))


func test_checkpoint_requires_fresh_bidirectional_damage_and_switch_window() -> void:
	assert_false(HARNESS._combat_checkpoint_ready(0.0, 8.0, true))
	assert_false(HARNESS._combat_checkpoint_ready(8.0, 0.0, true))
	assert_false(HARNESS._combat_checkpoint_ready(8.0, 8.0, false))
	assert_true(HARNESS._combat_checkpoint_ready(8.0, 8.0, true))
