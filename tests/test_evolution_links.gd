extends "res://tests/test_case.gd"

## The evolution links in data/creatures/species.json.
##
## There is no evolution SYSTEM in the project (HANDOFF §4) — `evolves_into` and
## `evolves_from` are the two ends of a rope nothing pulls on yet. That is
## exactly why they need a test: a link nothing reads is a link nothing
## contradicts, so it rots silently and the first thing to pull on it inherits
## the rot.
##
## The rule these pin is the owner's, given this session: **whatever creature is an
## evolution of another needs to be larger in size** (docs/decisions/D17). The
## biome's one line already satisfies it — Mudsnout 1.40m → Tuskroot 2.00m — but
## it satisfied it by accident until this file existed. Heights are TUNABLE and
## are expected to move; this is what stops the next tune quietly inverting a
## line and nobody noticing until the evolved form looks like a downgrade.
##
## This tests RELATIVE size within a line only. The absolute band is D12/D13's
## settled policy and is not this file's business.
##
## D71/T3-SUNSTONE: Mudsnout is no longer a single-destination line. It now
## also carries `evolves_into_variants` (item_id -> target), read BESIDE the
## original single-string `evolves_into` rather than replacing it (see
## ralph/reports/SUNSTONE_DESIGN_2026-08-30.md). Every rule this file already
## enforced on the primary link -- target exists, D17's strictly-larger rule,
## the reverse link agreeing -- applies just as hard to a variant branch, so
## the back half of this file mirrors each check for `evolves_into_variants`
## rather than silently only covering the field that existed first.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")


# --- helpers --------------------------------------------------------------

func _height_of(species_id: String) -> float:
	var placeholder: Variant = SPECIES.definition(species_id).get("placeholder")
	if not (placeholder is Dictionary):
		return -1.0
	return float((placeholder as Dictionary).get("height", -1.0))


## `id`'s variant branches (item_id -> target), or {} if it declares none.
func _variants_of(id: String) -> Dictionary:
	var raw: Variant = SPECIES.definition(id).get("evolves_into_variants", {})
	return raw as Dictionary if raw is Dictionary else {}


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


func test_every_evolution_variant_target_exists() -> void:
	# The `evolves_into_variants` mirror of test_every_evolution_target_exists
	# above -- a typo'd target here is exactly as invisible until read.
	for id: String in SPECIES.table().keys():
		for item_id: String in _variants_of(id).keys():
			var target: String = str(_variants_of(id)[item_id])
			assert_true(SPECIES.has(target),
				"'%s' evolves into '%s' (via %s), which is not in the species table" % [id, target, item_id])


# --- the owner's rule: an evolution is always larger ------------------------

func test_an_evolution_is_larger_than_what_it_came_from() -> void:
	# D17, from the owner this session: "whatever creature is an evolution of another
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


func test_a_variant_evolution_is_also_larger_than_what_it_came_from() -> void:
	# D17 binds every branch, not just the primary one -- a Mudsnout that
	# grows into a smaller Ashtusk would be exactly the silent downgrade this
	# whole file exists to catch, just reached through the newer field.
	for id: String in SPECIES.table().keys():
		for item_id: String in _variants_of(id).keys():
			var target: String = str(_variants_of(id)[item_id])
			if not SPECIES.has(target):
				continue  # already reported by test_every_evolution_variant_target_exists
			var from_height := _height_of(id)
			var to_height := _height_of(target)
			assert_true(to_height > from_height,
				"D17: '%s' (%.2fm) evolves into '%s' (%.2fm) via %s — the evolved form must be LARGER" % [
					id, from_height, target, to_height, item_id])


func test_every_species_in_an_evolution_line_declares_a_height() -> void:
	# Without this the rule above compares two defaults and passes on nothing.
	# `placeholder.height` is what creature_body._fit() sizes the model to, so a
	# missing one is not a cosmetic omission.
	for id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(id)
		if not (definition.has("evolves_into") or definition.has("evolves_from")
				or not _variants_of(id).is_empty()):
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
				# D71: the back-link may point through the PRIMARY evolves_into
				# (the common case) or through one of the source's variant
				# branches (Ashtusk, reached via mudsnout.evolves_into_variants
				# rather than mudsnout.evolves_into itself) -- either satisfies
				# the promise that whichever end the evolution system reads
				# first agrees with the other.
				var source_def: Dictionary = SPECIES.definition(source)
				var primary_target := str(source_def.get("evolves_into", ""))
				var names_me := primary_target == id or _variants_of(source).values().has(id)
				assert_true(names_me,
					"'%s' evolves from '%s', but '%s' names '%s' neither as its evolves_into nor in its evolves_into_variants" % [
						id, source, source, id])


func test_the_reverse_link_agrees_for_variants() -> void:
	# The forward half of the same promise, for a variant branch specifically:
	# whatever a variant target names as its own evolves_from must be the
	# species that names IT in evolves_into_variants.
	for id: String in SPECIES.table().keys():
		for item_id: String in _variants_of(id).keys():
			var target: String = str(_variants_of(id)[item_id])
			if not SPECIES.has(target):
				continue  # already reported by test_every_evolution_variant_target_exists
			assert_eq(str(SPECIES.definition(target).get("evolves_from", "")), id,
				"'%s' evolves into '%s' via %s, but '%s' does not name '%s' as its evolves_from" % [
					id, target, item_id, target, id])


# --- the rule cannot pass by evaporating ------------------------------------

func test_the_biome_still_has_its_one_evolution_line() -> void:
	# Every test above iterates the links that exist, so deleting the last link
	# would turn this whole file green while proving nothing. D13 canonised
	# exactly one evolution LINE in the Meadows — Mudsnout → Tuskroot. D71
	# gave that line a second destination (Mudsnout → Ashtusk, via a Sunstone)
	# without adding a second line: there is still exactly one species that
	# evolves at all, so this still measures the same thing D13 asked for.
	var links := 0
	for id: String in SPECIES.table().keys():
		if SPECIES.definition(id).has("evolves_into"):
			links += 1
	assert_true(links >= 1,
		"no species declares evolves_into; D13 canonises Mudsnout as the biome's one evolving species")
