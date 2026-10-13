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


## essence._equivalent memoises large containers by the pair's type-exact
## bytes; verdicts must equal the uncached rules, including int/float
## equivalence and the refusal of non-finite numbers.
func test_memoised_equivalence_keeps_the_numeric_rules() -> void:
	const E := preload("res://scripts/creatures/essence.gd")
	var ints := {}
	var floats := {}
	for i in 40:
		ints["k%d" % i] = i
		floats["k%d" % i] = float(i)
	for pass_index in 2: # second pass is served by the memo
		assert_true(E._equivalent(ints, floats), "int and float values stay equivalent (pass %d)" % pass_index)
		assert_eq(E._equivalent(ints, floats), E._equivalent_uncached(ints, floats))
	var changed := floats.duplicate()
	changed["k7"] = 7.5
	assert_false(E._equivalent(ints, changed))
	var infinite: Array = []
	for i in 40: infinite.append(INF)
	for pass_index in 2:
		assert_false(E._equivalent(infinite, infinite.duplicate()), "non-finite numbers are never equivalent (pass %d)" % pass_index)
	assert_true(E._equivalent({"a": 1}, {"a": 1.0}), "small values take the unmemoised rules")


## Inside a mastery job step a prepared write is only recorded (owed), so it
## can never refuse -- the guarantee that lets the step skip its world
## rollback snapshot (ledger_rpc._rollback_snapshot). Outside a step the
## ordinary refusal stands.
class BusySave extends "res://scripts/save/save_game.gd":
	func fallback_busy() -> bool: return true

func test_a_write_inside_a_step_never_refuses_and_stays_owed() -> void:
	var saver := BusySave.new("user://test_owed_scope_%d/" % Time.get_ticks_usec())
	assert_false(saver.save_world_prepared(null, "slot"), "outside a step a busy writer refuses")
	saver._deferring = true # The state begin_deferred_writes() opens (it refuses while busy).
	assert_true(saver.in_deferred_scope())
	assert_true(saver.save_world_prepared(null, "slot"), "inside a step the world write is recorded, never refused")
	assert_true(saver.save_character_prepared(null, "c1"), "inside a step the character write is recorded, never refused")
	saver.end_deferred_scope()
	assert_true(saver.deferring_writes(), "both writes stay owed for the flush")
	assert_false(saver.in_deferred_scope())
