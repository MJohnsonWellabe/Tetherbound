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
## `test_the_worst_multiplier_the_real_data_can_produce_is_one_double_weakness`.
## Read its comment before "fixing" it -- it carries the record of T3-MATCHUPS
## deliberately changing the pin this lane originally set, and why.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TYPE_CHART := preload("res://scripts/combat/type_chart.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

## What the chart pays a single type advantage. Not hardcoded anywhere else in
## this file -- read from the chart itself, so retuning the magnitude in data
## retunes these assertions with it instead of turning them into lies.
var _advantage: float = TYPE_CHART.multiplier("water", "ground")
var _disadvantage: float = TYPE_CHART.multiplier("air", "ground")

var moves: RefCounted = null


func before_each() -> void:
	moves = MOVE_DB.new()


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "missing data file: %s" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## Every band's trainers file, from `band_content.gd`'s own band list rather
## than a copy of it -- a band added there and not here would silently drop out
## of the census below, which is the failure mode this repo keeps rediscovering.
func _trainer_files() -> Array:
	var out: Array = []
	for band: String in BAND_CONTENT.BANDS:
		out.append("res://data/config/bands/%s/trainers.json" % band)
	return out


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
	# THE WHOLE ARGUMENT FOR MULTIPLYING, as an assertion: `neutral` must be an
	# IDENTITY, so a second type nothing has an opinion about cannot move the
	# result. Under "take the more favourable" or "average" it would, and by an
	# amount that depends on how much of the chart has been written.
	#
	# AMENDED BY T3-MATCHUPS. This used to iterate fire/electric/ice/psychic/
	# dark, because when it was written all five were unauthored and every
	# dual-typed creature paired an authored type with one of them -- which was
	# that lane's evidence that dual typing moved no damage number in the
	# shipped game. Those five now have rows, so naming them here would assert
	# the opposite of what the chart does.
	#
	# The property is unchanged and is now tested where it still applies:
	# `nature` and `light` are what remains unauthored, and the second loop
	# below generalises the identity to EVERY pairing rather than a hand-listed
	# few -- a strictly wider assertion than the one it replaces.
	for unauthored: String in ["nature", "light", "definitely_not_a_type"]:
		for move_type: String in ["ground", "water", "air"]:
			for primary: String in ["ground", "water", "air"]:
				assert_eq(TYPE_CHART.multiplier_dual(move_type, primary, unauthored),
					TYPE_CHART.multiplier(move_type, primary),
					"'%s' has no authored rows, so it must not move a '%s' move against '%s'" % [
						unauthored, move_type, primary])

	# The general form: wherever the SECOND half is neutral -- whether because
	# the type is unauthored or because the chart simply has no opinion about
	# that pairing -- the dual answer must equal the single one exactly.
	var declared: Array = TYPE_CHART.config().get("types", [])
	for move_type: String in declared:
		for primary: String in declared:
			for secondary: String in declared:
				if primary == secondary:
					continue
				if not is_equal_approx(
					TYPE_CHART.multiplier(move_type, secondary), TYPE_CHART.neutral()
				):
					continue
				assert_eq(TYPE_CHART.multiplier_dual(move_type, primary, secondary),
					TYPE_CHART.multiplier(move_type, primary),
					("'%s' into '%s' is neutral, so a '%s/%s' defender must resolve exactly as a "
					+ "mono-typed '%s' one. Neutral has stopped being an identity.")
						% [move_type, secondary, primary, secondary, primary])


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

func test_the_worst_multiplier_the_real_data_can_produce_is_one_double_weakness() -> void:
	# READ THIS BEFORE CHANGING IT.
	#
	# WHAT THIS TEST USED TO SAY, AND WHY IT NO LONGER SAYS IT.
	#
	# T3-CREATURES pinned the maximum at a SINGLE advantage (1.25), because
	# every dual-typed creature then paired an authored type (ground/water/air)
	# with an unauthored one, so the second half was always a 1.0 no-op. Its
	# comment said: "when this fails, someone has authored the first true double
	# weakness ... the right response is NOT to delete this test or widen its
	# bound. It is to decide, deliberately, whether the game wants double
	# weaknesses -- and if it does, to re-measure the Warden against the new
	# maximum."
	#
	# T3-MATCHUPS is that day, that decision was taken deliberately, and the
	# Warden WAS re-measured. The full account is
	# `ralph/reports/MATCHUPS_DESIGN_2026-08-30.md` sections 5.1 and 5.2. The
	# three things that decided it:
	#
	# 1. IT IS FORCED, not chosen. `water > ground` is shipped and tuned;
	#    `water > fire` is one of the owner's five fixed pairs, quoted verbatim
	#    in type_chart.json; Ashtusk's Ground/Fire typing is settled owner
	#    direction. Honouring all three makes 1.5625 reachable. There is no
	#    version of this chart that obeys the owner and avoids it, short of
	#    gutting dual typing with a clamp.
	# 2. THE INHERITED ALARM POINTS SOMEWHERE ELSE. 1.5625 is past the 1.5 that
	#    TYPECHART_DESIGN section 3.2 measured as the point where the Warden
	#    folds -- but that threshold was measured on the Warden's own five, and
	#    NONE of them is dual-typed. Nor is any creature on any of the 27
	#    authored trainer rosters (asserted below, so it cannot drift silently).
	#    The Warden fight is bit-for-bit identical under this chart.
	# 3. IT COSTS NO HITS. Worst compounded case is 1.5625 x the 2.0x apex water
	#    TM = 3.125, against a shipped ceiling of 2.5. Measured against wild
	#    Ashtusk at L16 (289 hp) that is 3 charged hits either way.
	#
	# So this is a STRONGER pin than the one it replaces, not a weakened one: it
	# asserts the number AND that exactly one pairing reaches it AND that the
	# pairing is the specific one the design note argues for. If a second
	# pairing appears, or a different one, this fails and the reasoning above
	# has to be redone rather than the bound widened. Cindercub (Fire/Ground) is
	# expected to join Ashtusk here the day its mesh lands and it enters
	# species.json -- that is a second name in the list below, not a new number.
	var double_weakness: float = _advantage * _advantage
	var worst := 0.0
	var worst_pairings: Array = []
	var best_resist := 999.0
	for species_id: String in SPECIES.table().keys():
		var types := _species_types(SPECIES.definition(species_id))
		var primary: String = types[0]
		var secondary: String = types[1] if types.size() > 1 else ""
		for move_id: Variant in moves.move_ids():
			var move_type: String = str(moves.type_of(str(move_id)))
			var mult := TYPE_CHART.multiplier_dual(move_type, primary, secondary)
			if mult > worst + 0.0001:
				worst = mult
				worst_pairings = ["%s move into %s (%s)" % [move_type, species_id, "/".join(types)]]
			elif is_equal_approx(mult, worst):
				var entry := "%s move into %s (%s)" % [move_type, species_id, "/".join(types)]
				if not worst_pairings.has(entry):
					worst_pairings.append(entry)
			best_resist = minf(best_resist, mult)

	assert_almost_eq(worst, double_weakness, 0.0001,
		("the largest type multiplier the real roster can produce is %.4f via %s; the design note "
		+ "argues for exactly one double weakness at %.4f. Read this test's comment before changing "
		+ "the bound -- the number is not the point, the reasoning is.") % [
			worst, worst_pairings, double_weakness])

	# T3-INSTALL, 2026-08-30: Cindercub's mesh landed and it entered
	# species.json, which is the exact, named-in-advance second name this
	# test's own comment above said to expect -- "a second name in the list
	# below, not a new number". Ashtusk and Cindercub are both Fire/Ground,
	# so both are forced into the double weakness by the same owner fixed
	# pair (`water beats fire`) meeting the same shipped edge
	# (`water beats ground`); there is no version of the chart that honours
	# the owner and keeps only one of them. A THIRD name would still be a new
	# design decision and should still fail this test.
	assert_eq(worst_pairings.size(), 2,
		("%d pairings reach the double weakness (%s). MATCHUPS_DESIGN section 5.1 argues for exactly "
		+ "Ashtusk and Cindercub (both Fire/Ground), forced by the owner's `water beats fire` meeting "
		+ "the shipped `water beats ground`. Any other count is a new design decision, not a side effect.") % [
			worst_pairings.size(), worst_pairings])
	var pairing_species: Array = []
	for pairing: Variant in worst_pairings:
		pairing_species.append(str(pairing).split(" into ")[1].split(" (")[0])
	pairing_species.sort()
	assert_eq(pairing_species, ["ashtusk", "cindercub"],
		("the double weakness should be reached by water moves into ashtusk and cindercub (both "
		+ "Ground/Fire); got %s instead") % [worst_pairings])
	for pairing: Variant in worst_pairings:
		assert_true(str(pairing).begins_with("water move into"),
			"the double weakness should be reached by a WATER move; got '%s'" % pairing)

	# The floor did NOT move. No creature resists the same attacker on both
	# halves, so the natural double resistance (0.64) stays unreachable and a
	# dual-typed creature can never become a wall.
	assert_almost_eq(best_resist, _disadvantage, 0.0001,
		("the strongest resistance the real roster can produce is %.4f; it should still be a single "
		+ "disadvantage. A reachable double RESIST is the mirror of the hazard above and wants the "
		+ "same deliberate decision.") % best_resist)


## No creature on any authored trainer roster is dual-typed -- which is why the
## double weakness above cannot reach a single authored fight.
##
## This is the load-bearing fact behind MATCHUPS_DESIGN section 4.2's "+0% on 27
## of 27 rungs" and section 4.3's bit-for-bit-identical Warden, and it was
## previously recorded nowhere. It is a property of the CONTENT, not of the
## chart, so it can be broken by a roster edit in a lane that has never heard of
## this file. When it breaks, the reachability pin above stops being a statement
## about optional wild encounters and starts being a statement about the
## chapter's critical path, and both need re-measuring together.
func test_no_trainer_roster_creature_is_dual_typed() -> void:
	var offenders: Array = []
	var seen := 0
	for path: String in _trainer_files():
		var parsed := _json(path)
		var entries: Variant = parsed.get("trainers", [])
		if not entries is Array:
			continue
		for entry: Variant in entries as Array:
			if not entry is Dictionary:
				continue
			var team: Variant = (entry as Dictionary).get("team", [])
			if not team is Array:
				continue
			for member: Variant in team as Array:
				if not member is Dictionary:
					continue
				var species_id := str((member as Dictionary).get("species", ""))
				if species_id.is_empty():
					continue
				seen += 1
				var definition := SPECIES.definition(species_id)
				if definition.is_empty():
					continue
				if not str(definition.get("type_secondary", "")).is_empty():
					offenders.append("%s fields %s (%s/%s)" % [
						str((entry as Dictionary).get("id", "?")), species_id,
						definition.get("type", ""), definition.get("type_secondary", "")])
	assert_true(seen > 0, "found no trainer roster creatures at all; the census walk is broken")
	assert_true(offenders.is_empty(),
		("%d authored trainer creatures scanned and these are dual-typed: %s. Read "
		+ "ralph/reports/MATCHUPS_DESIGN_2026-08-30.md sections 4.2 and 5.2 -- the type chart's "
		+ "claim that it changes no authored fight rests on this being empty.") % [seen, offenders])


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
