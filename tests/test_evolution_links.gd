extends "res://tests/test_case.gd"

## The evolution links in data/pals/species.json.
##
## There is no evolution SYSTEM in the project (HANDOFF §4) — `evolves_into` and
## `evolves_from` are the two ends of a rope nothing pulls on yet. That is
## exactly why they need a test: a link nothing reads is a link nothing
## contradicts, so it rots silently and the first thing to pull on it inherits
## the rot.
##
## The rule these pin is the owner's, given this session: **whatever pal is an
## evolution of another needs to be larger in size** (docs/decisions/D17). The
## biome's one line already satisfies it — Mudsnout 1.40m → Tuskroot 2.00m — but
## it satisfied it by accident until this file existed. Heights are TUNABLE and
## are expected to move; this is what stops the next tune quietly inverting a
## line and nobody noticing until the evolved form looks like a downgrade.
##
## This tests RELATIVE size within a line only. The absolute band is D12/D13's
## settled policy and is not this file's business.

const SPECIES := preload("res://scripts/pals/pal_species.gd")


# --- helpers --------------------------------------------------------------

func _height_of(species_id: String) -> float:
	var placeholder: Variant = SPECIES.definition(species_id).get("placeholder")
	if not (placeholder is Dictionary):
		return -1.0
	return float((placeholder as Dictionary).get("height", -1.0))


# --- the links point at real creatures -------------------------------------

func test_every_evolution_target_exists() -> void:
	# A typo here would go unnoticed for as long as nothing reads the link —
	# which is currently forever.
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		if not definition.has("evolves_into"):
			continue
		var target: String = str(definition["evolves_into"])
		assert_true(SPECIES.has(target),
			"'%s' evolves into '%s', which is not in the species table" % [id, target])


func test_every_evolution_source_exists() -> void:
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		if not definition.has("evolves_from"):
			continue
		var source: String = str(definition["evolves_from"])
		assert_true(SPECIES.has(source),
			"'%s' evolves from '%s', which is not in the species table" % [id, source])


# --- the owner's rule: an evolution is always larger ------------------------

func test_an_evolution_is_larger_than_what_it_came_from() -> void:
	# D17, from the owner this session: "whatever pal is an evolution of another
	# needs to be larger in size". Strictly greater — equal heights would let a
	# line exist where evolving changes nothing you can see.
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		if not definition.has("evolves_into"):
			continue
		var target: String = str(definition["evolves_into"])
		if not SPECIES.has(target):
			continue  # already reported by test_every_evolution_target_exists
		var from_height := _height_of(id)
		var to_height := _height_of(target)
		assert_true(to_height > from_height,
			"D17: '%s' (%.2fm) evolves into '%s' (%.2fm) — the evolved form must be LARGER" % [
				id, from_height, target, to_height])


func test_every_species_in_an_evolution_line_declares_a_height() -> void:
	# Without this the rule above compares two defaults and passes on nothing.
	# `placeholder.height` is what pal_body._fit() sizes the model to, so a
	# missing one is not a cosmetic omission.
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		if not (definition.has("evolves_into") or definition.has("evolves_from")):
			continue
		assert_true(_height_of(id) > 0.0,
			"'%s' is in an evolution line but declares no placeholder.height" % id)


# --- the two ends agree ----------------------------------------------------

func test_the_reverse_link_agrees() -> void:
	# Half a link is worse than none: whichever end the evolution system reads
	# first would be right, and the other would be a bug that only shows up in
	# the direction nobody tested.
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		if definition.has("evolves_into"):
			var target: String = str(definition["evolves_into"])
			if SPECIES.has(target):
				assert_eq(str(SPECIES.definition(target).get("evolves_from", "")), id,
					"'%s' evolves into '%s', but '%s' does not name '%s' as its evolves_from" % [
						id, target, target, id])
		if definition.has("evolves_from"):
			var source: String = str(definition["evolves_from"])
			if SPECIES.has(source):
				assert_eq(str(SPECIES.definition(source).get("evolves_into", "")), id,
					"'%s' evolves from '%s', but '%s' does not name '%s' as its evolves_into" % [
						id, source, source, id])


# --- the rule cannot pass by evaporating ------------------------------------

func test_the_biome_still_has_its_one_evolution() -> void:
	# Every test above iterates the links that exist, so deleting the last link
	# would turn this whole file green while proving nothing. D13 canonises
	# exactly one evolution in the Meadows — Mudsnout → Tuskroot — so at least
	# one link must be there for the rest of the file to have a subject.
	var links := 0
	for id: String in SPECIES.table().keys():
		if SPECIES.definition(id).has("evolves_into"):
			links += 1
	assert_true(links >= 1,
		"no species declares evolves_into; D13 canonises Mudsnout → Tuskroot as the biome's one evolution")
