extends "res://tests/test_case.gd"

## The type chart (T3-TYPECHART): data/config/type_chart.json,
## scripts/combat/type_chart.gd, and the multiplier's path through
## scripts/combat/combat_math.gd.
##
## Design note, with the argument behind every number asserted here:
## ralph/reports/TYPECHART_DESIGN_2026-08-30.md.
##
## Per docs/decisions/D02 this file is pure logic. Driving two creatures through
## a real fight and watching a type-advantaged hit take a bigger bite is
## `tests/smoke_type_chart.gd`'s job; this file owns the arithmetic and the
## table.
##
## What each group of failures below would look like in play, since none of it
## is loud at run time:
##
## - a broken chart lookup is a mechanic that silently does nothing, and the
##   game plays exactly as it did before this system landed with no error
##   anywhere;
## - a non-reciprocal or incomplete triangle is one type quietly carrying an
##   advantage with no matching weakness, which is invisible until somebody
##   censuses a hundred fights;
## - a magnitude drift is the entire balance argument -- 1.25 was chosen
##   against the owner board's own 1.1x-2.0x TM ladder and against a census of
##   every authored trainer creature in the chapter, and a later edit to 1.5
##   "because it should feel stronger" would pass every other test in this
##   suite while folding the Warden and turning a starter choice into a trap;
## - a default-argument regression in combat_math is every pre-chart call site
##   silently changing damage.

const CHART := preload("res://scripts/combat/type_chart.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const SPECIES_PATH := "res://data/creatures/species.json"
const CHART_PATH := "res://data/config/type_chart.json"

## The three types the chapter actually ships. The chart's own code knows
## nothing about them (the board's six planned types are a data edit), so the
## list lives here, in the tests that assert what the LIVE game contains.
const LIVE_TYPES := ["ground", "water", "air"]

## The advantage magnitude the design note argues for, and its reciprocal.
const ADVANTAGE := 1.25
const DISADVANTAGE := 0.8


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "missing data file: %s" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _species() -> Dictionary:
	var parsed := _json(SPECIES_PATH)
	var block: Variant = parsed.get("species", parsed)
	return block as Dictionary if block is Dictionary else {}


# --- the table itself --------------------------------------------------------


## The triangle is complete: every live type is advantaged into exactly one
## other and disadvantaged into exactly one other.
##
## An incomplete chart is the specific failure the design note rejected on
## measurement -- drop one edge and a type carries a weakness with no
## advantage, which widens the per-type spread rather than narrowing it.
func test_every_live_type_has_exactly_one_advantage_and_one_weakness() -> void:
	for attacker: String in LIVE_TYPES:
		var strong: Array = []
		var weak: Array = []
		for defender: String in LIVE_TYPES:
			var mult := CHART.multiplier(attacker, defender)
			if mult > 1.0:
				strong.append(defender)
			elif mult < 1.0:
				weak.append(defender)
		assert_eq(strong.size(), 1,
			"'%s' is advantaged into %s; the triangle wants exactly one" % [attacker, strong])
		assert_eq(weak.size(), 1,
			"'%s' is disadvantaged into %s; the triangle wants exactly one" % [attacker, weak])


## Reciprocity: if A beats B then B is weak into A, at the reciprocal
## magnitude. A one-sided edge is a type that hits harder AND takes less, which
## compounds into roughly double the intended swing.
func test_the_chart_is_reciprocal() -> void:
	for attacker: String in LIVE_TYPES:
		for defender: String in LIVE_TYPES:
			var forward := CHART.multiplier(attacker, defender)
			var back := CHART.multiplier(defender, attacker)
			if is_equal_approx(forward, 1.0):
				assert_true(is_equal_approx(back, 1.0),
					"'%s' into '%s' is neutral but the reverse is %.3f" % [attacker, defender, back])
				continue
			assert_true(is_equal_approx(forward * back, 1.0),
				"'%s'->'%s' is %.3f and the reverse is %.3f; reciprocal wants their product to be 1.0"
					% [attacker, defender, forward, back])


## A creature is never advantaged or disadvantaged against its own type.
func test_mirror_matchups_are_neutral() -> void:
	for t: String in LIVE_TYPES:
		assert_true(is_equal_approx(CHART.multiplier(t, t), 1.0),
			"'%s' into itself is %.3f, not neutral" % [t, CHART.multiplier(t, t)])


## The magnitudes themselves.
##
## This is the assertion that protects the design argument rather than the
## structure, and it is deliberately exact. 1.25/0.80 was chosen because it
## prices a permanent advantage at roughly one TM rung against the owner
## board's 1.1x-2.0x ladder, because it survives compounding with the three
## 2.0x apex TMs against the real warden_aldis roster without producing a
## one-shot, and because ground is 57.6% of every authored trainer creature in
## the chapter -- at 1.25/0.80 the best-to-worst damage-exchange spread across
## that ladder is 1.38x, where 1.5/0.667 gives 1.77x. If this test is failing
## because somebody deliberately retuned the chart, the design note is what
## needs updating with it, not this number quietly.
func test_the_magnitudes_are_the_ones_the_design_note_argues_for() -> void:
	for attacker: String in LIVE_TYPES:
		for defender: String in LIVE_TYPES:
			var mult := CHART.multiplier(attacker, defender)
			if is_equal_approx(mult, 1.0):
				continue
			var expected := ADVANTAGE if mult > 1.0 else DISADVANTAGE
			assert_true(is_equal_approx(mult, expected),
				"'%s' into '%s' is %.4f; the design note argues %.2f/%.2f"
					% [attacker, defender, mult, ADVANTAGE, DISADVANTAGE])


# --- unknown and malformed input ---------------------------------------------


## An unknown or empty type on either side reads as ORDINARY, never as free
## damage and never as a silent penalty.
##
## This is the case that actually happens: a species with a typo'd `type`, a
## move with none, a creature hand-built by a test that never set one, and --
## the reason it matters most -- any of the board's six planned types (fire,
## ice, nature, light, shadow, electric) the day one is authored. They must be
## playable at neutral the moment they exist.
func test_unknown_and_empty_types_are_neutral() -> void:
	for unknown: String in ["", "   ", "fire", "ice", "nature", "light", "shadow", "electric", "??"]:
		for known: String in LIVE_TYPES:
			assert_true(is_equal_approx(CHART.multiplier(unknown, known), 1.0),
				"attacking with unknown type '%s' is not neutral" % unknown)
			assert_true(is_equal_approx(CHART.multiplier(known, unknown), 1.0),
				"defending as unknown type '%s' is not neutral" % unknown)


## Hand-authored JSON should not switch a mechanic off with a capital letter.
func test_lookup_is_case_and_whitespace_tolerant() -> void:
	for attacker: String in LIVE_TYPES:
		for defender: String in LIVE_TYPES:
			var plain := CHART.multiplier(attacker, defender)
			assert_true(is_equal_approx(CHART.multiplier(attacker.to_upper(), defender), plain),
				"'%s' uppercased stopped matching" % attacker)
			assert_true(is_equal_approx(CHART.multiplier(attacker, " %s " % defender), plain),
				"'%s' with surrounding whitespace stopped matching" % defender)


## `classify` is the one place "what counts as strong" is decided, so the HUD
## cannot drift from the fight by comparing floats itself.
func test_classify_agrees_with_the_multipliers() -> void:
	assert_eq(CHART.classify(1.0), 0, "neutral did not classify as 0")
	assert_eq(CHART.classify(ADVANTAGE), 1, "an advantage did not classify as 1")
	assert_eq(CHART.classify(DISADVANTAGE), -1, "a disadvantage did not classify as -1")
	for attacker: String in LIVE_TYPES:
		for defender: String in LIVE_TYPES:
			assert_eq(
				CHART.effectiveness(attacker, defender),
				CHART.classify(CHART.multiplier(attacker, defender)),
				"effectiveness('%s','%s') disagrees with classify(multiplier(...))"
					% [attacker, defender])


# --- the multiplier's path through the damage formula ------------------------


## Every call site that predates the chart is byte-for-byte unchanged.
##
## `type_mult` defaults to 1.0 for exactly the reason `move_power` does (see
## `base_damage`'s own comment). A regression here is not a wrong number in one
## fight -- it is every pre-chart caller, every tool and every test silently
## computing different damage.
func test_omitting_the_type_multiplier_changes_nothing() -> void:
	for power: float in [8.0, 9.0, 38.0]:
		for move_power: float in [0.85, 1.0, 2.0]:
			assert_true(is_equal_approx(
				MATH.base_damage(power, 40.0, 25.0, move_power),
				MATH.base_damage(power, 40.0, 25.0, move_power, 1.0)),
				"base_damage's type_mult does not default to a no-op")
			assert_true(is_equal_approx(
				MATH.rolled_damage(power, 40.0, 25.0, 0.5, move_power),
				MATH.rolled_damage(power, 40.0, 25.0, 0.5, move_power, 1.0)),
				"rolled_damage's type_mult does not default to a no-op")


## The multiplier reaches the damage, proportionally, and both ways.
func test_the_multiplier_scales_damage_in_both_directions() -> void:
	var neutral := MATH.base_damage(9.0, 40.0, 25.0, 1.0, 1.0)
	var strong := MATH.base_damage(9.0, 40.0, 25.0, 1.0, ADVANTAGE)
	var weak := MATH.base_damage(9.0, 40.0, 25.0, 1.0, DISADVANTAGE)
	assert_true(is_equal_approx(strong, neutral * ADVANTAGE),
		"an advantaged hit dealt %.3f, not %.3f" % [strong, neutral * ADVANTAGE])
	assert_true(is_equal_approx(weak, neutral * DISADVANTAGE),
		"a disadvantaged hit dealt %.3f, not %.3f" % [weak, neutral * DISADVANTAGE])


## The variance band stays a proportion of the hit that was actually dealt,
## rather than a fixed band around the neutral damage -- which is what
## combat.json's `variance` comment promises ("every hit lands between 90% and
## 110%").
func test_variance_stays_proportional_to_the_typed_hit() -> void:
	for mult: float in [DISADVANTAGE, 1.0, ADVANTAGE]:
		var mid := MATH.base_damage(38.0, 40.0, 25.0, 1.0, mult)
		var low := MATH.rolled_damage(38.0, 40.0, 25.0, 0.0, 1.0, mult)
		var high := MATH.rolled_damage(38.0, 40.0, 25.0, 1.0, 1.0, mult)
		assert_true(is_equal_approx(low / mid, 0.9),
			"at x%.2f the low roll was %.4f of the hit, not 0.9" % [mult, low / mid])
		assert_true(is_equal_approx(high / mid, 1.1),
			"at x%.2f the high roll was %.4f of the hit, not 1.1" % [mult, high / mid])


## The compounding check the design note ran, pinned.
##
## A 2.0x apex TM (earthshatter/leviathan_surge/heavenfall, the board's "very
## rare" rung) landing at type advantage must not become a one-shot against the
## chapter's own final boss. Measured against warden_aldis's bulkiest creature
## with the levels his roster actually authors.
func test_an_apex_tm_at_type_advantage_does_not_one_shot_the_warden() -> void:
	var species := _species()
	var tuskroot: Dictionary = species.get("tuskroot", {})
	assert_true(not tuskroot.is_empty(), "tuskroot is missing from species.json")

	# warden_aldis's own roster: tuskroot at level 20, the highest in the game.
	var level := 20.0
	var hp := float(tuskroot.get("base_hp", 130.0)) * (1.0 + 0.06 * (level - 1.0))
	var defence := float(tuskroot.get("base_defence", 19.0)) * (1.0 + 0.05 * (level - 1.0))
	# A generously strong attacker: the same species, same level.
	var attack := float(tuskroot.get("base_attack", 24.0)) * (1.0 + 0.05 * (level - 1.0))

	var apex := MATH.base_damage(38.0, attack, defence, 2.0, ADVANTAGE)
	assert_true(apex < hp,
		"a 2.0x TM at type advantage deals %.1f against %.1f hp -- that is a one-shot, and the "
		% [apex, hp]
		+ "chapter's final exam folds to one prepared creature")


# --- the chart against the data it will actually be asked about --------------


## Every type any live species claims is a type the chart DECLARES.
##
## AMENDED BY T3-CREATURES, and the amendment is worth understanding rather
## than skimming. This test used to require a chart ROW for every species type.
## That was right when the game had three types and all three had rows, but it
## contradicted the chart's own design note, which states that the owner
## board's planned types are "deliberately NOT stubbed" and that "a new type is
## playable at 1.00 the moment a species or move claims one and becomes
## interesting when someone authors its rows". The owner's creature-expansion
## brief then landed creatures carrying five of those types, and the two
## documents could not both be obeyed.
##
## What the assertion protects is a TYPO -- a species whose type is misspelt,
## or missing, resolving to neutral forever with no error anywhere. That is now
## checked against `types` in type_chart.json, which is a hand-authored
## vocabulary: a misspelt type is not in it, and "" is not in it, so the typo is
## still caught. Adding a genuinely new type still takes a deliberate data edit
## in the chart itself.
##
## The coverage that WOULD have been lost -- "the live chapter's types all have
## rows" -- is not lost; it moved into
## `test_the_chapters_own_types_all_still_have_rows` below, where it is stated
## directly instead of as a side effect.
##
## Full argument: ralph/reports/DUALTYPE_DESIGN_2026-08-30.md section 5.
func test_every_species_type_is_declared_by_the_chart() -> void:
	var declared := CHART.known_types()
	assert_false(declared.is_empty(),
		"type_chart.json must declare `types`; without it this test proves nothing")
	for id: String in _species():
		var definition: Variant = _species()[id]
		if not definition is Dictionary:
			continue
		# Both halves: T3-CREATURES made a species' typing potentially two
		# strings, and a typo in the SECOND one would be even quieter than in
		# the first, because the creature would still work.
		for key: String in ["type", "type_secondary"]:
			var t := str((definition as Dictionary).get(key, ""))
			if key == "type_secondary" and t.is_empty():
				continue
			assert_true(declared.has(t),
				"species '%s' has %s '%s', which type_chart.json does not declare" % [id, key, t])


## The chapter's own three types must all still have rows.
##
## Stated on its own because the tests either side of it now check a VOCABULARY
## rather than the matchup table, and without this the whole matchup block could
## be emptied and most of this file would stay green -- the same evaporation
## trap `test_evolution_links.gd` guards against for evolution links. Ground,
## water and air are what the Meadows actually fights with; the five the
## expansion brought in are foreshadowing for regions that do not exist yet and
## are neutral on purpose.
func test_the_chapters_own_types_all_still_have_rows() -> void:
	var chart := _json(CHART_PATH)
	var matchups: Dictionary = chart.get("matchups", {})
	for t: String in LIVE_TYPES:
		assert_true(matchups.has(t),
			"'%s' is a live chapter type and the chart must have a row for it" % t)


## Every move's type likewise -- declared, not necessarily rowed.
##
## AMENDED BY T3-CREATURES for the reason on the species test above. The
## original comment here made a real point that is worth keeping on the record
## rather than deleting: "a move whose type the chart does not name would be
## permanently neutral, which is a dead move in a system where coverage is the
## point." That is TRUE of the ten new-type moves, and it was weighed rather
## than waved away.
##
## The conclusion was that permanently neutral is not dead, it is FLAT: against
## an air defender a ground move is worth 1.25 and a dark move 1.00, and against
## a water defender a ground move is worth 0.80 and a dark move 1.00. So an
## unrowed move is a hedge -- never the best answer, never the worst. That is a
## reasonable thing for a wild creature the player has just caught out of a
## thunderstorm to be holding, and it is strictly SAFER for balance than the
## alternative, since an unrowed move cannot roll an advantage at all.
##
## It stops being flat the day someone authors those rows, which is exactly what
## the chart was built to allow. The thing to check before doing it is
## `tests/test_dual_type.gd`'s reachability pin, because authoring a fire or
## dark row makes the first double weakness (1.5625) reachable, past the 1.5
## that TYPECHART_DESIGN_2026-08-30.md section 3.2 measured as folding the
## Warden.
func test_every_move_type_is_declared_by_the_chart() -> void:
	var declared := CHART.known_types()
	assert_false(declared.is_empty(),
		"type_chart.json must declare `types`; without it this test proves nothing")
	var moves: RefCounted = MOVE_DB.load_default()
	for id: Variant in moves.call("move_ids"):
		var t := str(moves.call("type_of", str(id)))
		assert_true(declared.has(t),
			"move '%s' is type '%s', which type_chart.json does not declare" % [id, t])


## Every type the chart has ROWS for must be one it also declares.
##
## The other direction of the vocabulary check, and the one that stops `types`
## from drifting into decoration: a matchup row for a type absent from `types`
## would mean the two halves of this file disagree about what exists, and the
## vocabulary tests above would be checking against an incomplete list.
func test_the_matchup_table_never_names_an_undeclared_type() -> void:
	var chart := _json(CHART_PATH)
	var matchups: Dictionary = chart.get("matchups", {})
	var declared := CHART.known_types()
	for attacking: String in matchups:
		assert_true(declared.has(attacking),
			"the chart has rows for '%s' but does not declare it in `types`" % attacking)
		var row: Variant = matchups[attacking]
		if not row is Dictionary:
			continue
		for defending: String in (row as Dictionary):
			assert_true(declared.has(defending),
				"the '%s' row names defender '%s', which `types` does not declare" % [
					attacking, defending])


## The keying decision, asserted against the data that makes it non-degenerate.
##
## The chart is keyed on the MOVE's type, not the wielding species'. That is
## what turns coverage into a ten-move-slot problem rather than a five-body
## one, and it is only meaningful if a creature's moves can differ from its own
## type. moves.json's header names the two species that ship that way on
## purpose. If a later edit re-aligns every move to its wielder, the chart
## silently collapses into a species chart -- "carry one of each and switch" --
## and nothing else in this suite would notice.
func test_off_type_coverage_exists_in_the_shipped_roster() -> void:
	var moves: RefCounted = MOVE_DB.load_default()
	var off_type: Array = []
	for id: String in _species():
		var definition: Variant = _species()[id]
		if not definition is Dictionary:
			continue
		var species_type := str((definition as Dictionary).get("type", ""))
		var block: Variant = (definition as Dictionary).get("moves", {})
		if not block is Dictionary:
			continue
		for slot: String in ["quick", "charged"]:
			var move_id := str((block as Dictionary).get(slot, ""))
			if move_id.is_empty():
				continue
			var move_type := str(moves.call("type_of", move_id))
			if not move_type.is_empty() and move_type != species_type:
				off_type.append("%s/%s is %s on a %s creature" % [id, slot, move_type, species_type])
	assert_true(off_type.size() >= 2,
		"only %d species carry an off-type move (%s); the chart is keyed on the MOVE, and with "
			% [off_type.size(), off_type]
		+ "every move aligned to its wielder it degenerates into a species chart")
