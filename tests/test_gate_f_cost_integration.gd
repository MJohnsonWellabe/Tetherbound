extends TestCase

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")


func test_runtime_prices_typed_waits_using_component_medians_without_double_charging_load() -> void:
	var harness := HARNESS.new()
	harness._steps = [{"action": "wait", "args": {"seconds": 10}},
		{"action": "press", "args": {"settle_frames": 8}}]
	harness._cfg.segment_cost_ceiling_s = 12.0
	harness._t0_usec = Time.get_ticks_usec()
	for index in 9:
		harness._record_cost_sample({"physics_seconds_per_frame": 1.0 / 60.0,
			"process_seconds_per_frame": 0.056589 if index < 8 else 0.5,
			"seconds_per_frame": 0.056589 if index < 8 else 0.5})
	assert_almost_eq(harness._physics_cost_s, 1.0 / 60.0)
	assert_almost_eq(harness._process_cost_s, 0.056589)
	harness._apply_price("in-play", harness._cost_median(), 140000.0, 0.056589, false, 0)
	var receipt: Dictionary = harness._reprices[-1]
	assert_eq(receipt.typed_frame_budget.physics_frames, 602)
	assert_eq(receipt.typed_frame_budget.process_frames, 10)
	assert_almost_eq(float(receipt.predicted_remaining_s), 10.6, 0.01)
	assert_false(harness._cost_over_armed,
		"typed runtime budget fits; slower-rate multiplication and paid boot_ms must not arm refusal")
	assert_true(harness._blocked.is_empty())
	harness.free()


func test_component_price_change_is_logged_even_when_legacy_max_rate_stays_constant() -> void:
	var harness := HARNESS.new()
	harness._steps = [{"action": "wait", "args": {"seconds": 10}}]
	harness._t0_usec = Time.get_ticks_usec()
	harness._physics_cost_s = 0.02
	harness._process_cost_s = 0.1
	harness._apply_price("in-play", 0.1, 0.0, 0.1, false, 0)
	harness._physics_cost_s = 0.04
	harness._apply_price("in-play", 0.1, 0.0, 0.1, false, 0)
	assert_eq(harness._reprices.size(), 2)
	assert_almost_eq(float(harness._reprices[-1].physics_frame_cost_s), 0.04)
	harness.free()


func test_disk_cadence_counts_physics_progress_during_slow_process_waits() -> void:
	var typed := {"physics_frames": 600, "process_frames": 120,
		"wall_seconds": 0.0, "total_frames": 720}
	assert_eq(HARNESS._disk_frame_budget(typed, 1.0 / 60.0, 0.05), 960)
	assert_eq(HARNESS._disk_frame_budget(typed, 1.0 / 60.0, 0.001), 720)
