extends TestCase

const BUDGET := preload("res://tools/gate_f/frame_budget.gd")


func test_mixed_press_and_retry_settle_use_their_actual_clocks() -> void:
	var press := BUDGET.action_budget({"action": "press", "args": {"times": 3, "hold": "long", "settle_frames": 8}})
	assert_eq(press.physics_frames, 183)
	assert_eq(press.process_frames, 30)
	var retry := BUDGET.action_budget({"action": "press_until", "args": {"max_presses": 3, "settle_frames": 8}})
	assert_eq(retry.physics_frames, 30)
	assert_eq(retry.process_frames, 6)


func test_process_slowdown_does_not_reprice_physics_waits_as_process_frames() -> void:
	var budget := BUDGET.predict([{"action": "wait", "args": {"seconds": 10}},
		{"action": "press", "args": {"settle_frames": 8}}])
	assert_eq(budget.physics_frames, 602)
	assert_eq(budget.process_frames, 10)
	assert_true(absf(BUDGET.seconds(budget, 1.0 / 60.0, 0.056589) - 10.5992233333) < 0.00001)
	var cap_seconds := 12.0
	assert_true(float(budget.total_frames) * 0.056589 > cap_seconds,
		"the former slower-rate multiplier falsely refuses this mixed workload")
	assert_true(BUDGET.seconds(budget, 1.0 / 60.0, 0.056589) < cap_seconds)
	assert_true(BUDGET.seconds(budget, 0.1, 0.2) > cap_seconds,
		"real sustained physics/process slowdown must still raise the cost")


func test_dialogue_includes_predicate_budget_and_paired_close_waits() -> void:
	var budget := BUDGET.action_budget({"action": "advance_dialogue_until_closed",
		"args": {"max_presses": 10, "settle_frames": 60}})
	assert_eq(budget.physics_frames, 50)
	assert_eq(budget.process_frames, 670)


func test_walk_includes_independent_held_budget_and_answer_edges() -> void:
	var budget := BUDGET.action_budget({"action": "move_to", "args": {
		"budget_frames": 100, "held_budget_frames": 40, "answer_prompts": true}})
	assert_eq(budget.physics_frames, 145)
	assert_eq(budget.process_frames, 4)


func test_capture_and_wall_timeout_do_not_get_slow_physics_multipliers() -> void:
	var capture := BUDGET.action_budget({"action": "capture_seq", "args": {"hz": 0.5, "seconds": 40}})
	assert_eq(capture.physics_frames, 2400)
	assert_eq(capture.process_frames, 240,
		"preserve current executor's one-Hz minimum and six-frame conservative capture budget")
	var load_budget := BUDGET.action_budget({"action": "await_load", "args": {"timeout_s": 180}})
	assert_eq(load_budget.wall_seconds, 180.0)
	assert_eq(load_budget.physics_frames, 1)
	assert_eq(load_budget.process_frames, 1)
	var slow_capture := BUDGET.action_budget({"action": "capture"}, {"capture_settle_frames": 12})
	assert_eq(slow_capture.process_frames, 13, "include the post-draw wait after custom settle frames")


func test_guarded_steps_keep_the_full_budget_and_unknown_actions_are_visible() -> void:
	var plain := {"action": "press", "args": {"times": 4}}
	var guarded := plain.duplicate(true)
	guarded.args.skip_if = {"check": "combat_running", "equals": false}
	assert_eq(BUDGET.action_budget(plain), BUDGET.action_budget(guarded))
	assert_eq(BUDGET.predict([{"action": "new_waiting_action"}]).unsupported_actions,
		["new_waiting_action"])


func test_current_meadows_budgets_report_typed_totals() -> void:
	for name: String in ["S03", "S04"]:
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://tools/gate_f/segments/%s.json" % name))
		var budget := BUDGET.predict(doc.steps)
		assert_true(budget.unsupported_actions.is_empty(), str(budget.unsupported_actions))
		assert_eq(budget.total_frames, budget.physics_frames + budget.process_frames)
		print("FRAME_BUDGET %s %s predicted_seconds=%.3f" % [name, JSON.stringify(budget),
			BUDGET.seconds(budget, 1.0 / 60.0, 0.056589)])
