extends "res://tests/test_case.gd"

## Coordinator ruling 2026-10-04 (F02#1 Oskar refusal): a cooperative
## wall-clock deadline defers to the next physics frame, bounded by a count of
## consecutive deferred frames, never by wall time. Every deferral is counted.
const NAV := preload("res://tests/helpers/opening_geometry_navigator.gd")

## Exercise the real wake/retry handler without a mounted world or native
## queries. Production callback epochs, walking counters and admission remain
## the actual helper's implementations; only locomotion/input transport are fake.
class RetryProbe extends "res://tests/helpers/opening_geometry_navigator.gd":
	var walking_allowed := true
	var last_drive := Vector2.INF
	func _init() -> void:
		_active_walk_budget = WalkBudget.new(5)
		_drive = record_drive
	func can_walk() -> bool:
		return walking_allowed
	func record_drive(x: float, y: float) -> void:
		last_drive = Vector2(x, y)
	func abandon_request() -> int:
		_waiting_point = Vector3(27, 0.85, 7.6)
		_request = _waiting_point
		_waiting_step = _step_epoch.request()
		_step_epoch.begin(_waiting_step, 41)
		_step_epoch.finish(42)
		_checked_start = true
		return _waiting_step


func test_actual_wake_resubmits_only_the_same_abandoned_private_input() -> void:
	var probe := RetryProbe.new()
	var token := probe.abandon_request()
	probe._physics_frame_wake()
	assert_true(probe._requested)
	assert_eq(probe._requested_step, token)
	assert_eq(probe._request, Vector3(27, 0.85, 7.6))
	assert_eq(probe._step_epoch.issued, token, "no replacement epoch or allowance is created")
	assert_eq(probe._step_epoch.completed, 0, "wake/retry is not a controller acknowledgement")
	assert_false(probe._checked_start, "a stale landing cannot establish arrival after a retry")
	assert_eq(probe._active_walk_budget.walked, 1)


func test_actual_wake_keeps_inflight_queued_pending_raw_and_blocked_inputs_unsubmitted() -> void:
	for blocked: String in ["in_flight", "queued", "post_pending", "raw", "locomotion", "refused", "budget"]:
		var probe := RetryProbe.new()
		var token := probe.abandon_request()
		match blocked:
			"in_flight": probe._step_epoch.begin(token, 43)
			"queued": probe._requested = true
			"post_pending": probe._production_pending = true
			"raw": probe._raw = true
			"locomotion": probe.walking_allowed = false
			"refused": probe._reason = "existing refusal"
			"budget": probe._active_walk_budget = NAV.WalkBudget.new(0)
		probe._physics_frame_wake()
		assert_eq(probe._requested_step, 0, blocked + " cannot submit a private retry")
		assert_eq(probe._step_epoch.completed, 0, blocked + " cannot fabricate a post witness")
		assert_eq(probe._step_epoch.issued, token, blocked + " cannot replenish the request")


func test_actual_wake_refuses_replaced_target_or_newer_private_epoch() -> void:
	for replacement: String in ["target", "epoch"]:
		var probe := RetryProbe.new()
		probe.abandon_request()
		if replacement == "target":
			probe._request = Vector3.ZERO
		else:
			probe._step_epoch.request()
		probe._physics_frame_wake()
		assert_true(probe.refused(), replacement + " replacement is not silently adopted")
		assert_false(probe._requested)
		assert_eq(probe.last_drive, Vector2.ZERO)
		assert_eq(probe._step_epoch.completed, 0)


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


func test_callback_waits_spend_the_whole_walk_allowance_once_per_actual_frame() -> void:
	var budget := NAV.WalkBudget.new(3)
	var epoch := NAV.StepEpoch.new()
	var token := epoch.request()
	for frame in [41, 42, 43]:
		assert_true(budget.advance(frame, true), "waiting for this one request still spends an allowed walking frame")
		assert_true(budget.advance(frame, true), "a second callback in that same physical frame cannot spend it twice")
	assert_eq(budget.walked, 3)
	assert_eq(epoch.completed, 0, "budget consumption is independent of a missing native completion")
	assert_false(budget.advance(44, true), "no fourth walking frame can be granted while the original request remains pending")
	assert_eq(budget.walked, 3, "the original whole-walk limit is not replenished per request")
	assert_true(budget.exhausted)
	assert_eq(token, 1)


func test_abandoned_post_retries_actual_input_without_manufacturing_completion() -> void:
	var budget := NAV.WalkBudget.new(2)
	var epoch := NAV.StepEpoch.new()
	var token := epoch.request()
	assert_true(budget.advance(41, true))
	assert_true(epoch.begin(token, 41))
	assert_eq(epoch.retry_token(token), 0, "a pending actual pre cannot be overwritten")
	epoch.finish(42)
	assert_eq(epoch.completed, 0, "a mismatched post never acknowledges the original input")
	assert_eq(epoch.retry_token(token), token, "the abandoned input remains eligible for an actual fresh pair")
	assert_true(budget.advance(42, true))
	assert_true(epoch.begin(epoch.retry_token(token), 42))
	assert_eq(epoch.completed, 0, "resubmitting alone still earns no movement witness")
	epoch.finish(42)
	assert_eq(epoch.completed, token, "only the fresh matching actual post acknowledges the input")
	assert_eq(epoch.retry_token(token), 0, "a finished input cannot be replayed")
	assert_eq(epoch.retry_token(0), 0, "no public/raw step is an outstanding private request")
	assert_eq(epoch.retry_token(token + 1), 0, "an unissued future input cannot be submitted")
	assert_eq(epoch.issued, 1, "retrying does not issue a replacement or replenish its allowance")
	assert_false(budget.advance(43, true), "the retry consumed the last original walking tick")


func test_only_nonwalking_holds_are_excluded_from_the_original_walk_allowance() -> void:
	var budget := NAV.WalkBudget.new(2)
	assert_true(budget.advance(41, false))
	assert_true(budget.advance(41, false))
	assert_eq(budget.held, 1)
	assert_eq(budget.walked, 0)
	assert_true(budget.advance(42, true), "locomotion-enabled frames count even when a modal owns input")
	assert_true(budget.advance(43, false))
	assert_true(budget.advance(44, true))
	assert_eq(budget.walked, 2)
	assert_eq(budget.held, 2)
	assert_false(budget.advance(45, true))


func test_native_completion_does_not_replenish_the_walking_frame_limit() -> void:
	var budget := NAV.WalkBudget.new(2)
	var epoch := NAV.StepEpoch.new()
	var first := epoch.request()
	assert_true(budget.advance(41, true))
	assert_true(epoch.begin(first, 41))
	epoch.finish(41)
	var second := epoch.request()
	assert_true(budget.advance(42, true))
	assert_true(epoch.begin(second, 42))
	epoch.finish(42)
	assert_eq(epoch.completed, second)
	assert_eq(budget.walked, 2, "actual post checks finish requests but cannot reset the shared walking clock")
	assert_false(budget.advance(43, true))


func test_a_same_frame_locomotion_handback_counts_once_without_an_extra_hold() -> void:
	var budget := NAV.WalkBudget.new(1)
	assert_true(budget.advance(41, false))
	assert_true(budget.advance(41, true))
	assert_true(budget.advance(41, true))
	assert_eq(budget.walked, 1)
	assert_eq(budget.held, 0)
	assert_false(budget.advance(42, false), "once the last permitted walking frame ends, a hold cannot extend the finished walk")


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
