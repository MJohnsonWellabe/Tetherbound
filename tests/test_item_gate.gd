extends "res://tests/test_case.gd"

## SB10 — the generic mechanism behind every physical gate the spec names: a
## carried item operates the world, never a level check, never a UI lock.
##
## Every failure here is one a player would meet as a gate that silently eats
## a key without opening, or a key that comes back after being spent, or a
## gate that forgets it was already opened. Pure logic, no scene tree — same
## split `test_progression_state.gd` and `test_inventory.gd` already draw.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")

const KEY_ID := "castle_gate_key"
const FLAG_ID := "south_bridge_open"

var db: RefCounted = null
var bag: RefCounted = null
var progression: RefCounted = null
var gate: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)
	progression = PROGRESSION_STATE.new()
	gate = ITEM_GATE.new(KEY_ID, FLAG_ID)


func test_a_fresh_gate_is_not_open() -> void:
	assert_false(gate.is_open(progression))


func test_trying_without_the_item_stays_locked_and_sets_no_flag() -> void:
	var opened: bool = gate.try_open(bag, progression)
	assert_false(opened)
	assert_false(gate.is_open(progression))
	assert_false(progression.has(FLAG_ID))


func test_trying_with_the_item_opens_and_consumes_exactly_one() -> void:
	bag.add(KEY_ID, 2)
	var opened: bool = gate.try_open(bag, progression)
	assert_true(opened)
	assert_true(gate.is_open(progression))
	assert_eq(bag.count(KEY_ID), 1)


func test_opening_sets_the_gates_own_flag_id_not_a_generic_one() -> void:
	bag.add(KEY_ID, 1)
	gate.try_open(bag, progression)
	assert_true(progression.has(FLAG_ID))


func test_a_different_gate_does_not_share_another_gates_flag() -> void:
	bag.add(KEY_ID, 1)
	gate.try_open(bag, progression)
	var other_gate: RefCounted = ITEM_GATE.new(KEY_ID, "mill_crossing_restored")
	assert_false(other_gate.is_open(progression))


func test_an_already_open_gate_reports_open_without_touching_the_inventory() -> void:
	progression.set_flag(FLAG_ID)
	bag.add(KEY_ID, 1)
	var opened: bool = gate.try_open(bag, progression)
	assert_true(opened)
	assert_eq(bag.count(KEY_ID), 1)


func test_trying_again_after_opening_does_not_spend_a_second_item() -> void:
	bag.add(KEY_ID, 1)
	gate.try_open(bag, progression)
	assert_eq(bag.count(KEY_ID), 0)
	var opened_again: bool = gate.try_open(bag, progression)
	assert_true(opened_again)
	assert_eq(bag.count(KEY_ID), 0)


## --- SF34: a gate with more than one key -------------------------------------

const SIGILS := ["field_sigil", "ridge_sigil", "river_sigil"]
const HALL_FLAG := "hall_approach_open"


func test_a_three_key_gate_reports_what_it_needs() -> void:
	var hall: RefCounted = ITEM_GATE.new(SIGILS, HALL_FLAG)
	assert_eq(hall.required(), 3)
	assert_eq(hall.held(bag), 0)


func test_two_of_three_sigils_leaves_the_gate_sealed_and_spends_nothing() -> void:
	var hall: RefCounted = ITEM_GATE.new(SIGILS, HALL_FLAG)
	bag.add("field_sigil", 1)
	bag.add("ridge_sigil", 1)
	assert_eq(hall.held(bag), 2)
	assert_false(hall.try_open(bag, progression))
	assert_false(hall.is_open(progression))
	assert_eq(bag.count("field_sigil"), 1, "a failed attempt must not eat a Sigil")
	assert_eq(bag.count("ridge_sigil"), 1)


func test_three_of_three_opens_and_consumes_one_of_each() -> void:
	var hall: RefCounted = ITEM_GATE.new(SIGILS, HALL_FLAG)
	for id: String in SIGILS:
		bag.add(id, 1)
	assert_true(hall.try_open(bag, progression))
	assert_true(hall.is_open(progression))
	for id: String in SIGILS:
		assert_eq(bag.count(id), 0)


## Three copies of ONE key are not three keys. `held()` counts distinct
## required ids, never stack size.
func test_a_stack_of_one_sigil_does_not_count_as_three() -> void:
	var hall: RefCounted = ITEM_GATE.new(SIGILS, HALL_FLAG)
	bag.add("field_sigil", 3)
	assert_eq(hall.held(bag), 1)
	assert_false(hall.try_open(bag, progression))


## The single-key form still behaves exactly as it did before SF34 -- this is
## the same class `road_gate.gd` and the bridge still construct with a String.
func test_a_one_key_gate_still_takes_a_plain_string() -> void:
	var single: RefCounted = ITEM_GATE.new(KEY_ID, "some_other_gate")
	assert_eq(single.required(), 1)
	assert_eq(single.item_id, KEY_ID)
	bag.add(KEY_ID, 1)
	assert_true(single.try_open(bag, progression))
	assert_eq(bag.count(KEY_ID), 0)


func test_open_state_survives_a_save_load_round_trip_through_progression_state() -> void:
	bag.add(KEY_ID, 1)
	gate.try_open(bag, progression)
	var data: Dictionary = progression.save_data()

	var reloaded_progression: RefCounted = PROGRESSION_STATE.new()
	reloaded_progression.load_data(data)
	var reloaded_gate: RefCounted = ITEM_GATE.new(KEY_ID, FLAG_ID)
	assert_true(reloaded_gate.is_open(reloaded_progression))
