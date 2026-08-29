extends "res://tests/test_case.gd"

## T3-CREATURES: dual typing, and the guard on what it can do to the damage
## curve.
##
## The owner's creature-expansion brief introduces five dual-typed creatures, so
## `type_chart.gd` needed one answer for a defender carrying two rows. The rule
## is MULTIPLICATION and the full argument is in
## `ralph/reports/DUALTYPE_DESIGN_2026-08-30.md`; the short version is that an
## unnamed pairing resolves to `neutral`, and multiplication is the only rule
## under which `neutral` is an IDENTITY. Under "take the more favourable" or
## "average", a second type that nobody has authored rows for would erase or
## halve the first type's weakness -- a free defensive buff whose size depends
## on how much of the chart has been written rather than on anything in the
## fiction.
##
## The most important test in this file is
## `test_the_worst_multiplier_the_real_data_can_produce_is_still_one_advantage`.
## Read its comment before "fixing" it.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")

## What the chart pays a single type advantage. Not hardcoded anywhere else in
## this file -- read from the chart itself, so retuning the magnitude in data
## retunes these assertions with it instead of turning them into lies.
var _advantage: float = TYPE_CHART.multiplier("water", "ground")
var _disadvantage: float = TYPE_CHART.multiplier("air", "ground")

var moves: RefCounted = null


func before_each() -> void:
	moves = MOVE_DB.new()


func _species_types(definition: Dictionary) -> Array:
	var out: Array = [str(definition.get("type", ""))]
	var second := str(definition.get("type_secondary", ""))
	if not second.is_empty():
		out.append(second)
	return out


# --- the rule itself --------------------------------------------------------

func test_a_mono_typed_defender_is_completely_unchanged() -> void:
	# The single most important safety property of this change: seventeen of the
	# seventeen species that existed before it must resolve bit-for-bit as they
	# did. An empty secondary must not even multiply by a float that happens to
	# be 1.0, in case `neutral` is ever retuned away from 1.0.
	for move_type: String in ["ground", "water", "air"]:
		for defender: String in ["ground", "water", "air"]:
			assert_eq(TYPE_CHART.multiplier_dual(move_type, defender, ""),
				TYPE_CHART.multiplier(move_type, defender),
				"mono-typed '%s' vs '%s' move must match the single-type lookup exactly" % [
					defender, move_type])


func test_the_two_halves_multiply() -> void:
	# ground -> air is an advantage on both halves, so a hypothetical Air/Air
	# creature squares it. Nothing in the real roster does this today (see the
	# reachability test below); this pins the ARITHMETIC.
	assert_almost_eq(TYPE_CHART.multiplier_dual("ground", "air", "air"),
		_advantage * _advantage,
		0.0001, "a double weakness must multiply")
	assert_almost_eq(TYPE_CHART.multiplier_dual("water", "air", "air"),
		_disadvantage * _disadvantage,
		0.0001, "a double resistance must multiply")


func test_opposed_halves_cancel_to_exactly_neutral() -> void:
	# The chart's 0.80 is 1/1.25, so a defender weak in one half and resistant
	# in the other lands on precisely neutral. Checked because it is EXACTLY
	# true in IEEE-754 (1.25 * 0.8 == 1.0, not merely close), which is what lets
	# `classify()` report such a pairing as "neither" with no floating-point
	# residue for its is_equal_approx to have to forgive.
	var mult := TYPE_CHART.multiplier_dual("ground", "air", "water")
	assert_eq(mult, TYPE_CHART.neutral(),
		"advantage against one half and disadvantage against the other must cancel exactly")
	assert_eq(TYPE_CHART.classify(mult), 0,
		"a cancelled pairing must read as neither strong nor weak")


func test_an_unauthored_second_type_changes_nothing() -> void:
	# THE WHOLE ARGUMENT FOR MULTIPLYING, as an assertion. Every one of the five
	# dual-typed creatures in the brief pairs an authored type with an
	# unauthored one, so if this ever stops holding, the rule has stopped being
	# neutral-preserving and five creatures have silently changed difficulty.
	for unauthored: String in ["fire", "electric", "ice", "psychic", "dark"]:
		for move_type: String in ["ground", "water", "air"]:
			for primary: String in ["ground", "water", "air"]:
				assert_eq(TYPE_CHART.multiplier_dual(move_type, primary, unauthored),
					TYPE_CHART.multiplier(move_type, primary),
					"'%s' has no authored rows, so it must not move a '%s' move against '%s'" % [
						unauthored, move_type, primary])


func test_order_does_not_matter() -> void:
	# Multiplication commutes, and the data must not care which half an author
	# wrote first -- Cindercub is "Fire/Ground" on its sheet and Ashtusk is
	# "Ground/Fire", and those two orderings must not mean different creatures.
	assert_eq(TYPE_CHART.multiplier_dual("water", "fire", "ground"),
		TYPE_CHART.multiplier_dual("water", "ground", "fire"),
		"swapping primary and secondary must not change the multiplier")


func test_case_and_whitespace_survive_the_second_type() -> void:
	# `multiplier()` is deliberately tolerant because these strings are
	# hand-authored JSON. That tolerance has to reach the secondary too, or a
	# capitalised `type_secondary` would silently switch half a creature off.
	assert_eq(TYPE_CHART.multiplier_dual("Water", " Ground ", "  "),
		TYPE_CHART.multiplier("water", "ground"),
		"a whitespace-only secondary is no secondary")
	assert_eq(TYPE_CHART.multiplier_dual("ground", "AIR", "Air"),
		_advantage * _advantage,
		"the secondary must be case-folded like the primary")


# --- the cap ----------------------------------------------------------------

func test_the_configured_cap_bounds_the_result() -> void:
	var rule: Dictionary = TYPE_CHART.config().get("dual_type", {})
	assert_false(rule.is_empty(),
		"type_chart.json must declare a `dual_type` block; the resolution rule is data")
	var hi := float(rule.get("max", 0.0))
	var lo := float(rule.get("min", 0.0))
	assert_true(hi > TYPE_CHART.neutral(),
		"the dual-type cap must sit above neutral or it would clamp ordinary advantages away")
	assert_true(lo > 0.0 and lo < TYPE_CHART.neutral(),
		"the dual-type floor must sit below neutral and above zero")
	# The bounds are the natural double values, so they must NOT bite on any
	# ordinary two-type pairing -- a cap that clamped a real matchup would be a
	# silent balance change rather than a backstop.
	assert_almost_eq(hi, _advantage * _advantage, 0.0001,
		"the cap should be the natural double-advantage value, so it is non-binding in ordinary play")
	assert_almost_eq(lo, _disadvantage * _disadvantage, 0.0001,
		"the floor should be the natural double-resistance value")


# --- the guard that matters -------------------------------------------------

func test_the_worst_multiplier_the_real_data_can_produce_is_still_one_advantage() -> void:
	# READ THIS BEFORE CHANGING IT.
	#
	# Every move in moves.json against every species in species.json. Today the
	# answer is that the largest multiplier the real game can produce is a
	# single advantage -- exactly what a mono-typed creature already produced
	# before dual typing existed -- because all five dual-typed creatures pair
	# an authored type with an unauthored one. That is the evidence that this
	# whole change moves no damage number in the shipped game.
	#
	# WHEN THIS FAILS, someone has authored the first true double weakness, and
	# the number they have just created is `advantage * advantage` = 1.5625.
	# `ralph/reports/TYPECHART_DESIGN_2026-08-30.md` section 3.2 measured 1.5 as
	# the point where the Warden fight folds -- at that magnitude a 2.0x apex TM
	# starts producing two-hit kills across his roster. So 1.5625 is past a line
	# somebody already measured, and it becomes reachable the moment a fire or
	# dark row is written (Cindercub is Fire/Ground, so an authored water->fire
	# would do it on its own).
	#
	# The right response is NOT to delete this test or widen its bound. It is to
	# decide, deliberately, whether the game wants double weaknesses -- and if
	# it does, to re-measure the Warden against the new maximum and tune
	# `dual_type.max` in data/config/type_chart.json to whatever that says.
	var worst := 0.0
	var worst_why := ""
	var best_resist := 999.0
	for species_id: String in SPECIES.table().keys():
		var types := _species_types(SPECIES.definition(species_id))
		var primary: String = types[0]
		var secondary: String = types[1] if types.size() > 1 else ""
		for move_id: Variant in moves.move_ids():
			var mult := TYPE_CHART.multiplier_dual(moves.type_of(str(move_id)), primary, secondary)
			if mult > worst:
				worst = mult
				worst_why = "%s (%s) hit by %s" % [species_id, "/".join(types), move_id]
			best_resist = minf(best_resist, mult)

	assert_almost_eq(worst, _advantage, 0.0001,
		("the largest type multiplier the real roster can produce is %.4f (%s), but a single advantage "
		+ "is %.4f. A double weakness has become reachable -- read this test's comment, do not widen it.") % [
			worst, worst_why, _advantage])
	assert_almost_eq(best_resist, _disadvantage, 0.0001,
		"the strongest resistance the real roster can produce should still be a single disadvantage")


# --- the data the rule reads ------------------------------------------------

func test_every_species_type_is_from_the_declared_vocabulary() -> void:
	# Coverage that did not exist before this lane: moves had their types
	# checked against a known list in two places, and SPECIES had theirs checked
	# nowhere at all. A typo'd species type does not crash -- it silently
	# resolves to neutral forever, which is the worst kind of bug this chart can
	# have.
	var vocabulary := TYPE_CHART.known_types()
	assert_false(vocabulary.is_empty(),
		"type_chart.json must declare `types`; without it this test proves nothing")
	for species_id: String in SPECIES.table().keys():
		for t: String in _species_types(SPECIES.definition(species_id)):
			assert_true(vocabulary.has(t),
				"species '%s' names type '%s', which is not in type_chart.json's `types`" % [
					species_id, t])


func test_a_secondary_type_is_never_the_same_as_the_primary() -> void:
	for species_id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(species_id)
		var second := str(definition.get("type_secondary", ""))
		if second.is_empty():
			continue
		assert_ne(second, str(definition.get("type", "")),
			("'%s' declares the same type twice. That is not a no-op: it would SQUARE every "
			+ "multiplier against it.") % species_id)


func test_the_expansion_actually_shipped_its_dual_types() -> void:
	# Every test above iterates whatever is there, so deleting all five dual
	# types would turn this file green while proving nothing -- the same trap
	# test_evolution_links.gd guards against for evolutions.
	var dual := 0
	for species_id: String in SPECIES.table().keys():
		if not str(SPECIES.definition(species_id).get("type_secondary", "")).is_empty():
			dual += 1
	assert_true(dual >= 4,
		("the owner's creature-expansion brief names five dual-typed creatures and four are "
		+ "buildable without a new mesh; only %d dual-typed species are in the table") % dual)


# --- the aspect-variant contract -------------------------------------------

func test_every_variant_names_a_real_base_species_and_reuses_its_mesh() -> void:
	# The contract this lane owes the T1-CREATURE-ART lane: a variant is the
	# same mesh as its base, differentiated by material/VFX. A variant that
	# quietly acquired its own model would mean somebody spent a Meshy
	# generation the brief did not authorise for it.
	var variants := 0
	for species_id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(species_id)
		var base_id := str(definition.get("variant_of", ""))
		if base_id.is_empty():
			continue
		variants += 1
		assert_true(SPECIES.has(base_id),
			"'%s' is a variant of '%s', which is not in the species table" % [species_id, base_id])
		if not SPECIES.has(base_id):
			continue
		var mine := str((definition.get("placeholder", {}) as Dictionary).get("model", ""))
		var theirs := str((SPECIES.definition(base_id).get("placeholder", {}) as Dictionary).get("model", ""))
		assert_eq(mine, theirs,
			("aspect variant '%s' must reuse '%s''s mesh -- CLAUDE.md differentiates Meadows creatures "
			+ "by material, scale, VFX and context, and the expansion brief authorises a new mesh for "
			+ "five OTHER creatures, not this one") % [species_id, base_id])
	assert_true(variants >= 4,
		"the four buildable aspect variants should all declare `variant_of`; found %d" % variants)


func test_no_aspect_variant_is_reachable_by_evolving() -> void:
	# The rarity argument, pinned -- amended by D71/T3-SUNSTONE. Every one of
	# these is authored as one or two individuals behind a habitat, time or
	# weather gate. If a variant were also an evolution target, the player
	# could manufacture one from a common creature and the gates would be
	# decoration -- UNLESS the species deliberately opts in with
	# `evolution_authorized: true`, the owner's own directed exception: "there
	# should just be some kind of sunstone you get then you evolve a Mudsnout
	# using the stone to get the Ashtusk." That flag is the whole carve-out,
	# visible in the data rather than a hardcoded species id living quietly
	# inside this test -- a species without it is held to the original rule
	# exactly as before.
	for species_id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(species_id)
		if str(definition.get("variant_of", "")).is_empty():
			continue
		assert_false(definition.has("evolves_into"),
			"aspect variant '%s' must not evolve; that would launder a rare find into another species" % species_id)
		if bool(definition.get("evolution_authorized", false)):
			assert_true(definition.has("evolves_from"),
				("'%s' declares evolution_authorized but names no evolves_from -- " +
				"the flag with nothing behind it is dead data") % species_id)
			continue
		assert_false(definition.has("evolves_from"),
			("aspect variant '%s' must not be an evolution target; it would bypass its own rarity gates " +
			"(set `evolution_authorized: true` for a deliberate, owner-directed exception)") % species_id)


func test_every_species_move_exists_and_matches_one_of_its_own_types() -> void:
	# Not a rule the build enforces generally -- moves.json says a move's type
	# is deliberately NOT cross-checked against its wielder, and Mosshell and
	# Reedwing exercise that on purpose. This checks only the NEW dual-typed
	# creatures, where it IS a design requirement: a dual-typed creature whose
	# moves are both its primary type wears its second type as pure defence and
	# the player never sees it exists.
	for species_id: String in SPECIES.table().keys():
		var definition: Dictionary = SPECIES.definition(species_id)
		if str(definition.get("type_secondary", "")).is_empty():
			continue
		var types := _species_types(definition)
		var creature_moves: Dictionary = definition.get("moves", {})
		var seen: Dictionary = {}
		for slot: String in ["quick", "charged"]:
			var move_id := str(creature_moves.get(slot, ""))
			assert_true(moves.has(move_id),
				"'%s' names %s move '%s', which is not in the move table" % [species_id, slot, move_id])
			if moves.has(move_id):
				seen[moves.type_of(move_id)] = true
		for t: String in types:
			assert_true(seen.has(t),
				("dual-typed '%s' has no %s move, so half its typing is invisible in play -- "
				+ "give it one move of each of its types") % [species_id, t])
