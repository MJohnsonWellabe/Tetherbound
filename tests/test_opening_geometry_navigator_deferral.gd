extends "res://tests/test_case.gd"

## Coordinator ruling 2026-10-04 (F02#1 Oskar refusal): a cooperative
## wall-clock deadline defers to the next physics frame, bounded by a count of
## consecutive deferred frames, never by wall time. Every deferral is counted.
const NAV := preload("res://tests/helpers/opening_geometry_navigator.gd")


func test_submitting_a_step_does_not_finish_before_its_native_callback() -> void:
	var epoch := NAV.StepEpoch.new()
	var token := epoch.request()
	assert_eq(epoch.completed, 0, "a physics_frame coroutine resume alone is not controller movement")
	assert_true(epoch.begin(token, 41))
	assert_eq(epoch.completed, 0, "the pre callback alone is not the production post observation")
	epoch.finish(41)
	assert_eq(epoch.completed, token, "only the matching actual post epoch finishes this request")


func test_previous_post_and_raw_input_cannot_finish_a_new_step() -> void:
	var epoch := NAV.StepEpoch.new()
	var first := epoch.request()
	assert_true(epoch.begin(first, 41))
	epoch.finish(41)
	var second := epoch.request()
	epoch.finish(41)
	assert_eq(epoch.completed, first, "a repeated previous observation cannot finish the next request")
	assert_true(epoch.begin(0, 42), "raw prompt input has no submitted step token")
	epoch.finish(42)
	assert_eq(epoch.completed, first, "raw prompt movement cannot acknowledge an unexecuted walking request")
	assert_true(epoch.begin(second, 43))
	epoch.finish(43)
	assert_eq(epoch.completed, second)


func test_different_or_unknown_callback_epochs_cannot_acknowledge_a_step() -> void:
	var epoch := NAV.StepEpoch.new()
	var token := epoch.request()
	assert_false(epoch.begin(token + 1, 41), "an unissued future request cannot be manufactured")
	assert_true(epoch.begin(token, 41))
	assert_false(epoch.begin(token, 42), "another pre callback cannot replace an outstanding request")
	epoch.finish(42)
	assert_eq(epoch.completed, 0, "the controller and post observer must belong to the pre callback's actual physics frame")


func test_a_deadline_defers_and_counts_once_per_frame() -> void:
	var ledger: RefCounted = NAV.DeadlineDeferral.new()
	ledger.call("new_frame")
	assert_true(bool(ledger.call("defer", "native query budget")), "the first late frame is retried, not refused")
	assert_true(bool(ledger.call("defer", "native callback deadline before stick input")), "a second late query in the same frame is the same deferral")
	assert_eq(int(ledger.get("total")), 1, "one deferral per frame")
	assert_eq(int(ledger.get("consecutive")), 1)


func test_a_clean_frame_resets_the_consecutive_bound_not_the_total() -> void:
	var ledger: RefCounted = NAV.DeadlineDeferral.new()
	for _frame in 5:
		ledger.call("new_frame")
		ledger.call("defer", "native query budget")
	ledger.call("new_frame") # This frame stays on time.
	ledger.call("new_frame")
	assert_eq(int(ledger.get("consecutive")), 0, "an on-time frame clears the consecutive run")
	assert_eq(int(ledger.get("total")), 5, "the logged total survives")


func test_the_bound_is_a_frame_count() -> void:
	var ledger: RefCounted = NAV.DeadlineDeferral.new()
	var allowed := 0
	for _frame in NAV.MAX_DEFERRAL_FRAMES + 5:
		ledger.call("new_frame")
		if not bool(ledger.call("defer", "native query budget")):
			break
		allowed += 1
	assert_eq(allowed, NAV.MAX_DEFERRAL_FRAMES, "exactly MAX_DEFERRAL_FRAMES consecutive late frames are retried")
	assert_eq(int(ledger.get("consecutive")), NAV.MAX_DEFERRAL_FRAMES + 1, "the next late frame refuses")
	assert_true(NAV.MAX_DEFERRAL_FRAMES > 0 and NAV.MAX_DEFERRAL_FRAMES <= 90, "bounded within the unchanged 90-frame stall cap")
