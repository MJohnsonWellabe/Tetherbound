extends "res://tests/test_case.gd"

## Regression guard for the Gate B Bram flake.  The continuous smoke is the
## behavioural proof; this small contract makes the precise harness bug cheap
## to catch: a pre-press winner snapshot must never be treated as an activation.

const SEGMENT_PATH := "res://tests/helpers/gate_a_npc_gather_segment.gd"
const SEGMENT := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")


func test_controller_activation_is_confirmed_by_the_live_arbiter_signal() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	assert_true(source.contains("_arbiter.connect(\"activated\", activation_handler)"),
		"the helper never observes which provider production actually activated")
	assert_true(source.contains("await _press_and_observe_activation(target)"),
		"the approach still has no post-press activation verdict")
	assert_true(source.contains("activation == ActivationVerdict.COMPETING:"),
		"the approach does not distinguish a competing activation from no activation")
	assert_true(source.contains("activated competing provider"),
		"a competing activation must fail immediately with the actual provider")


func test_activation_verdict_distinguishes_target_competitor_and_nothing() -> void:
	var target := Node.new()
	var competitor := Node.new()
	assert_eq(SEGMENT.activation_verdict(null, target), SEGMENT.ActivationVerdict.NONE)
	assert_eq(SEGMENT.activation_verdict(target, target), SEGMENT.ActivationVerdict.TARGET)
	assert_eq(SEGMENT.activation_verdict(competitor, target), SEGMENT.ActivationVerdict.COMPETING)
	target.free()
	competitor.free()


func test_pre_press_winner_snapshot_is_not_returned_as_success() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	var start := source.find("func _one_approach(")
	var finish := source.find("\n\n## Travel one leg", start)
	assert_true(start >= 0 and finish > start, "could not isolate the approach helper")
	var approach := source.substr(start, finish - start)
	assert_false(approach.contains("await _tap_action(&\"interact\")\n\t\t\treturn true"),
		"a stale pre-press winner is still being reported as a successful activation")
	assert_true(approach.contains("_nav.reset()\n\t\t\tcontinue"),
		"a press that activated nothing should resume the same bounded physical approach")
	assert_true(approach.contains("_competing_activation])\n\t\t\t\treturn false"),
		"a competing activation must not enter the no-activation retry path")


func test_fatal_approach_failure_stops_at_the_outer_retry_boundary() -> void:
	var source := FileAccess.get_file_as_string(SEGMENT_PATH).replace("\r\n", "\n")
	var start := source.find("func _walk_to_and_activate(")
	var finish := source.find("\n\n## Frames spent held", start)
	assert_true(start >= 0 and finish > start, "could not isolate the outer activation retry helper")
	var retry := source.substr(start, finish - start)
	var fatal_guard := retry.find("if not _failures.is_empty():\n\t\t\treturn false")
	var retry_delay := retry.find("for _i in 30:")
	assert_true(fatal_guard >= 0,
		"a competing activation failure is not terminal at the outer retry boundary")
	assert_true(retry_delay > fatal_guard,
		"the retry delay still runs before the fatal competing-activation guard")
