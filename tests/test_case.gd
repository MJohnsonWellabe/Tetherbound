extends RefCounted
class_name TestCase

## Base class for a test file.
##
## Deliberately tiny. GUT is the usual choice and is a better tool, but it could
## not be fetched in the build environment this project is developed from, and
## a milestone with no tests at all is worse than a milestone with a 60-line
## runner. See docs/decisions/D02-test-harness.md. Swapping to GUT later means
## rewriting the assert calls and deleting two files; nothing else depends on
## this.
##
## Scope, per docs/decisions/D02: pure logic only. Stat growth, catch chance,
## party rules, save round-trips. Not scenes, not rendering, not input feel.
## Those are verified by playing the game, and pretending otherwise is how a
## green suite starts lying.

var failures: Array[String] = []
var assertion_count := 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func _fail(message: String) -> void:
	failures.append(message)


func assert_true(value: bool, message: String = "") -> void:
	assertion_count += 1
	if not value:
		_fail("expected true, got false%s" % _suffix(message))


func assert_false(value: bool, message: String = "") -> void:
	assertion_count += 1
	if value:
		_fail("expected false, got true%s" % _suffix(message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual != expected:
		_fail("expected %s, got %s%s" % [str(expected), str(actual), _suffix(message)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assertion_count += 1
	if actual == unexpected:
		_fail("expected anything but %s%s" % [str(unexpected), _suffix(message)])


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	assertion_count += 1
	if absf(actual - expected) > tolerance:
		_fail("expected %f +/- %f, got %f%s" % [expected, tolerance, actual, _suffix(message)])


func assert_between(actual: float, low: float, high: float, message: String = "") -> void:
	assertion_count += 1
	if actual < low or actual > high:
		_fail("expected %f..%f, got %f%s" % [low, high, actual, _suffix(message)])


func _suffix(message: String) -> String:
	return "" if message.is_empty() else "  (%s)" % message
