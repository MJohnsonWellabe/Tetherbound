extends "res://tests/test_case.gd"

## Proves the harness itself runs, discovers methods, and can distinguish a
## pass from a failure. Every other test file in this project is only
## trustworthy if these pass.
##
## There is deliberately no game logic here yet. M0 is a boot probe: a project
## that opens, a controller that enumerates, and an .exe that exports. The first
## real tests arrive with the first real formula, which is M2's damage
## calculation.

var _before_each_ran := false


func before_each() -> void:
	_before_each_ran = true


func test_before_each_runs_before_the_test() -> void:
	assert_true(_before_each_ran, "before_each should have set the flag")


func test_equality_assertions() -> void:
	assert_eq(2 + 2, 4)
	assert_ne(2 + 2, 5)
	assert_true(true)
	assert_false(false)


func test_float_assertions_respect_tolerance() -> void:
	assert_almost_eq(0.1 + 0.2, 0.3)
	assert_between(0.5, 0.0, 1.0)


func test_a_failure_is_recorded_rather_than_thrown() -> void:
	# Run an assertion that must fail, on a throwaway instance, and confirm the
	# harness captured it. Without this the suite could be green because nothing
	# is capable of going red.
	var probe: Object = load("res://tests/test_case.gd").new()
	probe.assert_eq(1, 2)
	assert_eq(probe.failures.size(), 1, "a failed assertion should record exactly one failure")
	assert_true(
		probe.failures[0].contains("expected 2, got 1"),
		"failure message should name both values"
	)
