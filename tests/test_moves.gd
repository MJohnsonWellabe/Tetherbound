extends "res://tests/test_case.gd"

## R4.4: TMs and teaching (GAME_DESIGN.md 13). data/moves/tms.json,
## scripts/creatures/tm_db.gd and scripts/creatures/teaching.gd -- not
## world placement or progression_state's flag store themselves, which
## tests/test_progression_state.gd and manual play already cover.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")

const KNOWN_TYPES := ["ground", "water", "air"]

var moves: RefCounted = null
var tms: RefCounted = null


func before_each() -> void:
	moves = MOVE_DB.new()
	tms = TM_DB.new()


# --- tms.json is well-formed and every move_id is real -----------------------

func test_every_tm_has_a_display_name() -> void:
	for id: Variant in tms.tm_ids():
		assert_false(tms.display_name(str(id)).is_empty(),
			"TM '%s' has no display name" % id)


func test_every_tm_move_id_exists_in_the_move_table() -> void:
	for id: Variant in tms.tm_ids():
		var move_id := tms.move_id(str(id))
		assert_true(moves.has(move_id),
			"TM '%s' points at unknown move '%s'" % [id, move_id])


func test_every_tm_has_at_least_one_compatible_type_from_the_known_vocabulary() -> void:
	for id: Variant in tms.tm_ids():
		var types := tms.compatible_types(str(id))
		assert_false(types.is_empty(), "TM '%s' has no compatible_types" % id)
		for t: Variant in types:
			assert_true(KNOWN_TYPES.has(str(t)),
				"TM '%s' names unknown type '%s'" % [id, t])


func test_an_unknown_tm_id_degrades_gracefully() -> void:
	assert_false(tms.has("does_not_exist"))
	assert_eq(tms.tm("does_not_exist"), {})
	assert_eq(tms.display_name("does_not_exist"), "does_not_exist")
	assert_eq(tms.move_id("does_not_exist"), "")
	assert_eq(tms.compatible_types("does_not_exist"), [])
	assert_false(tms.is_compatible("does_not_exist", "ground"))


# --- compatibility -------------------------------------------------------------

func test_can_learn_true_for_a_listed_type() -> void:
	assert_true(TEACHING.can_learn("ground", "tm_stone_rush", tms))


func test_can_learn_false_for_an_unlisted_type() -> void:
	assert_false(TEACHING.can_learn("water", "tm_stone_rush", tms))


func test_can_learn_false_for_an_unknown_tm() -> void:
	assert_false(TEACHING.can_learn("ground", "does_not_exist", tms))


# --- teaching mutates the right slot, and only on success --------------------

func test_teach_a_charged_tm_replaces_move_charged_and_leaves_move_quick_alone() -> void:
	var mudsnout: RefCounted = SPECIES.spawn("mudsnout")
	var before_quick := str(mudsnout.get("move_quick"))
	assert_ne(str(mudsnout.get("move_charged")), "stone_rush", "test fixture already knew this move")

	var learned := TEACHING.teach(mudsnout, "tm_stone_rush", tms, moves)

	assert_true(learned)
	assert_eq(str(mudsnout.get("move_charged")), "stone_rush")
	assert_eq(str(mudsnout.get("move_quick")), before_quick)


func test_teach_a_quick_tm_replaces_move_quick_and_leaves_move_charged_alone() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	var before_charged := str(terrapup.get("move_charged"))
	assert_ne(str(terrapup.get("move_quick")), "burrow_strike", "test fixture already knew this move")

	var learned := TEACHING.teach(terrapup, "tm_burrow_strike", tms, moves)

	assert_true(learned)
	assert_eq(str(terrapup.get("move_quick")), "burrow_strike")
	assert_eq(str(terrapup.get("move_charged")), before_charged)


func test_teach_refuses_an_incompatible_species_and_changes_nothing() -> void:
	var ripplet: RefCounted = SPECIES.spawn("ripplet")
	var before_quick := str(ripplet.get("move_quick"))
	var before_charged := str(ripplet.get("move_charged"))

	var learned := TEACHING.teach(ripplet, "tm_stone_rush", tms, moves)

	assert_false(learned)
	assert_eq(str(ripplet.get("move_quick")), before_quick)
	assert_eq(str(ripplet.get("move_charged")), before_charged)


func test_teach_refuses_an_unknown_tm_and_changes_nothing() -> void:
	var terrapup: RefCounted = SPECIES.spawn("terrapup")
	var before_quick := str(terrapup.get("move_quick"))
	var before_charged := str(terrapup.get("move_charged"))

	var learned := TEACHING.teach(terrapup, "does_not_exist", tms, moves)

	assert_false(learned)
	assert_eq(str(terrapup.get("move_quick")), before_quick)
	assert_eq(str(terrapup.get("move_charged")), before_charged)


# --- not consumed: the same found TM teaches any number of creatures ---------

func test_the_same_tm_can_teach_more_than_one_creature() -> void:
	var mudsnout: RefCounted = SPECIES.spawn("mudsnout")
	var burrowback: RefCounted = SPECIES.spawn("burrowback")
	assert_ne(str(mudsnout.get("move_charged")), "stone_rush", "test fixture already knew this move")
	assert_ne(str(burrowback.get("move_charged")), "stone_rush", "test fixture already knew this move")

	assert_true(TEACHING.teach(mudsnout, "tm_stone_rush", tms, moves))
	assert_true(TEACHING.teach(burrowback, "tm_stone_rush", tms, moves))

	assert_eq(str(mudsnout.get("move_charged")), "stone_rush")
	assert_eq(str(burrowback.get("move_charged")), "stone_rush")
