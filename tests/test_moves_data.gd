extends "res://tests/test_case.gd"

## data/moves/moves.json and the `moves` field every species.json entry
## carries (D30).
##
## The fight itself never asks "does this move exist" — it just resolves
## whatever id a species names. If that id has a typo, the failure a player
## would see is a mute move on a nameplate with no obvious cause. These tests
## catch the typo at build time instead, the same job test_catch_math.gd
## already does for a missing `catch_rate`.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const MOVE_DB := preload("res://scripts/pals/move_db.gd")

## The Meadows' whole type vocabulary (data/pals/species.json's own `type`
## values). A move's `type` field is flavour, not a gameplay check, but it
## still has to be a real type or it is just a typo nobody will ever see fail.
const KNOWN_TYPES := ["ground", "water", "air"]

var moves: RefCounted = null


func before_each() -> void:
	moves = MOVE_DB.new()


func _species_ids() -> Array:
	return SPECIES.table().keys()


# --- every species names two real moves -------------------------------------

func test_every_species_declares_a_quick_and_a_charged_move() -> void:
	for species_id: Variant in _species_ids():
		var def := SPECIES.definition(str(species_id))
		var species_moves: Dictionary = def.get("moves", {})
		assert_false(str(species_moves.get("quick", "")).is_empty(),
			"%s has no quick move" % species_id)
		assert_false(str(species_moves.get("charged", "")).is_empty(),
			"%s has no charged move" % species_id)


func test_every_species_move_id_exists_in_the_move_table() -> void:
	for species_id: Variant in _species_ids():
		var def := SPECIES.definition(str(species_id))
		var species_moves: Dictionary = def.get("moves", {})
		var quick_id := str(species_moves.get("quick", ""))
		var charged_id := str(species_moves.get("charged", ""))
		assert_true(moves.has(quick_id),
			"%s's quick move '%s' is not in moves.json" % [species_id, quick_id])
		assert_true(moves.has(charged_id),
			"%s's charged move '%s' is not in moves.json" % [species_id, charged_id])


func test_a_species_quick_move_is_actually_slotted_quick() -> void:
	for species_id: Variant in _species_ids():
		var def := SPECIES.definition(str(species_id))
		var quick_id := str((def.get("moves", {}) as Dictionary).get("quick", ""))
		assert_eq(moves.slot(quick_id), "quick",
			"%s's quick move '%s' is not slotted quick" % [species_id, quick_id])


func test_a_species_charged_move_is_actually_slotted_charged() -> void:
	for species_id: Variant in _species_ids():
		var def := SPECIES.definition(str(species_id))
		var charged_id := str((def.get("moves", {}) as Dictionary).get("charged", ""))
		assert_eq(moves.slot(charged_id), "charged",
			"%s's charged move '%s' is not slotted charged" % [species_id, charged_id])


# --- every move in the table is well-formed ----------------------------------

func test_every_move_has_a_display_name() -> void:
	for id: Variant in moves.move_ids():
		assert_false(moves.display_name(str(id)).is_empty(),
			"move '%s' has no display name" % id)


func test_every_move_has_a_valid_slot() -> void:
	for id: Variant in moves.move_ids():
		var slot := moves.slot(str(id))
		assert_true(slot == "quick" or slot == "charged",
			"move '%s' has an unrecognised slot '%s'" % [id, slot])


func test_every_move_has_positive_power() -> void:
	for id: Variant in moves.move_ids():
		assert_true(moves.power(str(id)) > 0.0, "move '%s' has non-positive power" % id)


func test_every_move_type_is_from_the_known_vocabulary() -> void:
	for id: Variant in moves.move_ids():
		var move_type := str(moves.move(str(id)).get("type", ""))
		assert_true(KNOWN_TYPES.has(move_type),
			"move '%s' has unknown type '%s'" % [id, move_type])


func test_quick_moves_declare_energy_gain() -> void:
	for id: Variant in moves.move_ids():
		var definition := moves.move(str(id))
		if str(definition.get("slot", "")) == "quick":
			assert_true(definition.has("energy_gain"),
				"quick move '%s' has no energy_gain" % id)


func test_charged_moves_declare_energy_cost() -> void:
	for id: Variant in moves.move_ids():
		var definition := moves.move(str(id))
		if str(definition.get("slot", "")) == "charged":
			assert_true(definition.has("energy_cost"),
				"charged move '%s' has no energy_cost" % id)


# --- graceful degradation on an unknown id -----------------------------------

func test_an_unknown_move_id_degrades_gracefully() -> void:
	assert_false(moves.has("does_not_exist"))
	assert_eq(moves.move("does_not_exist"), {})
	assert_eq(moves.display_name("does_not_exist"), "does_not_exist")
	assert_almost_eq(moves.power("does_not_exist"), 1.0, 0.0001)
