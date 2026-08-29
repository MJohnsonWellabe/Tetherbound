extends "res://tests/test_case.gd"

## R4.4: TMs and teaching (GAME_DESIGN.md 13). data/moves/tms.json,
## scripts/creatures/tm_db.gd and scripts/creatures/teaching.gd -- not
## world placement or progression_state's flag store themselves, which
## tests/test_progression_state.gd and manual play already cover.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")

## T3-CREATURES. The type vocabulary now has ONE source of truth --
## data/config/type_chart.json's `types` -- because it used to be this literal,
## duplicated in tests/test_moves.gd and tests/test_moves_data.gd, and the
## owner's creature-expansion brief adds fire/electric/ice/psychic/dark. Widening
## two hand-maintained copies is how they drift apart. This is still the same
## assertion it always was (a move or TM may not name a type nobody declared);
## it just no longer has a second opinion about what the answer is.
## A `var` rather than a `const`: GDScript requires a constant expression for
## `const`, and this one is read from data at load.
var KNOWN_TYPES: Array = TYPE_CHART.known_types()

var moves: RefCounted = null
var tms: RefCounted = null
var items: RefCounted = null


func before_each() -> void:
	moves = MOVE_DB.new()
	tms = TM_DB.new()
	items = ITEM_DB.new()


## Every `kind: "tm"` item id in data/items/items.json.
func _tm_item_ids() -> Array:
	var found: Array = []
	for id: Variant in items.ids():
		if items.kind(str(id)) == "tm":
			found.append(str(id))
	return found


# --- tms.json is well-formed and every move_id is real -----------------------

func test_every_tm_has_a_display_name() -> void:
	for id: Variant in tms.tm_ids():
		assert_false(tms.display_name(str(id)).is_empty(),
			"TM '%s' has no display name" % id)


func test_every_tm_move_id_exists_in_the_move_table() -> void:
	for id: Variant in tms.tm_ids():
		var move_id := str(tms.move_id(str(id)))
		assert_true(moves.has(move_id),
			"TM '%s' points at unknown move '%s'" % [id, move_id])


func test_every_tm_has_at_least_one_compatible_type_from_the_known_vocabulary() -> void:
	for id: Variant in tms.tm_ids():
		var types := tms.compatible_types(str(id)) as Array
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


# --- OF29: every TM is also a carryable item, and the two files agree --------

## The whole link between data/moves/tms.json and data/items/items.json is
## that a TM's id and its item's id are the same string (items.json's own
## `_comment_tm`). Nothing in the code can enforce that, so these two do:
## a TM with no disc to pick up, or a disc that teaches nothing, is a data
## bug that reaches the player as a satchel slot that does nothing on Use.

func test_every_tm_has_a_matching_kind_tm_item() -> void:
	for id: Variant in tms.tm_ids():
		var tm_id := str(id)
		assert_true(items.has(tm_id),
			"TM '%s' has no matching item in items.json" % tm_id)
		assert_eq(items.kind(tm_id), "tm",
			"item '%s' backs a TM but is not kind 'tm'" % tm_id)


func test_every_tm_item_names_the_same_move_its_tm_entry_does() -> void:
	for item_id: Variant in _tm_item_ids():
		var id := str(item_id)
		assert_true(tms.has(id), "item '%s' is kind 'tm' but tms.json has no such TM" % id)
		var declared := str((items.definition(id) as Dictionary).get("move", ""))
		assert_false(declared.is_empty(), "TM item '%s' names no move" % id)
		assert_eq(declared, str(tms.move_id(id)),
			"TM item '%s' and tms.json disagree about which move it teaches" % id)
		assert_true(moves.has(declared),
			"TM item '%s' names unknown move '%s'" % [id, declared])


## OF29 makes a TM consumed on teach: one disc, one creature. A stack cap
## above 1 would promise the player a slot holding several lessons when
## picking a second one up needs a second slot's worth of disc.
func test_a_tm_item_does_not_stack() -> void:
	for item_id: Variant in _tm_item_ids():
		assert_eq(items.stack_size(str(item_id)), 1,
			"TM item '%s' must not stack -- one disc teaches one creature" % item_id)


# --- teaching.gd itself stays pure: it writes a move, it spends nothing ------

## R4.4 read GAME_DESIGN.md 13's "not consumed after one teaching" as "a TM is
## never consumed at all"; OF29 overrules that at the ITEM layer (the disc is
## removed from the satchel on a successful teach -- see
## `tab_backpack.gd::_on_target_row()`). `teaching.gd` itself never touched an
## inventory and still does not: it takes a creature and a TM id and writes a
## move slot. That separation is what makes the owner's rule reversible in one
## line, so this test guards it rather than the old "not consumed" wording.

func test_teaching_the_same_tm_twice_is_a_pure_function_of_the_creature() -> void:
	var mudsnout: RefCounted = SPECIES.spawn("mudsnout")
	var burrowback: RefCounted = SPECIES.spawn("burrowback")
	assert_ne(str(mudsnout.get("move_charged")), "stone_rush", "test fixture already knew this move")
	assert_ne(str(burrowback.get("move_charged")), "stone_rush", "test fixture already knew this move")

	assert_true(TEACHING.teach(mudsnout, "tm_stone_rush", tms, moves))
	assert_true(TEACHING.teach(burrowback, "tm_stone_rush", tms, moves))

	assert_eq(str(mudsnout.get("move_charged")), "stone_rush")
	assert_eq(str(burrowback.get("move_charged")), "stone_rush")
