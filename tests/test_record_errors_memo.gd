extends "res://tests/test_case.gd"

## P0 (12 Oct): character_record_rules.errors() is memoised (it ran ~18 times
## per landed mastery hit over the same records). The memo must give exactly
## the uncached verdict, never alias type-different input, and never share a
## mutable verdict with callers.
const RULES := preload("res://scripts/net/character_record_rules.gd")

func test_memoised_errors_equal_the_uncached_verdict_and_never_alias_types() -> void:
	var bad := {"character_id": "c1"}
	var first: Array[String] = RULES.errors(bad, "c1")
	assert_eq(first, RULES._errors_uncached(bad, "c1"))
	assert_false(first.is_empty(), "an incomplete record is refused")
	first.append("caller mutation")
	assert_eq(RULES.errors(bad, "c1"), RULES._errors_uncached(bad, "c1"), "a caller's copy never reaches the memo")
	assert_eq(RULES.errors(bad, "c2"), RULES._errors_uncached(bad, "c2"), "the expected character is part of the key")
	var as_int := {"character_id": "c1", "n": 1}
	var as_float := {"character_id": "c1", "n": 1.0}
	assert_ne(var_to_bytes([as_int, "c1"]), var_to_bytes([as_float, "c1"]), "int and float input never share a memo key")
	assert_eq(RULES.errors(as_float, "c1"), RULES._errors_uncached(as_float, "c1"))
	assert_eq(RULES.errors(as_int, "c1"), RULES._errors_uncached(as_int, "c1"))
	assert_eq(RULES.errors("not a record", "c1"), RULES._errors_uncached("not a record", "c1"))
