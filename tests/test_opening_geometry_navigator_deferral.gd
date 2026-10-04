extends "res://tests/test_case.gd"

## Coordinator ruling 2026-10-04 (F02#1 Oskar refusal): a cooperative
## wall-clock deadline defers to the next physics frame, bounded by a count of
## consecutive deferred frames, never by wall time. Every deferral is counted.
const NAV := preload("res://tests/helpers/opening_geometry_navigator.gd")


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
