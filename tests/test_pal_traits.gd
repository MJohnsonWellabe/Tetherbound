extends "res://tests/test_case.gd"

## The shipped trait roster.
##
## Mostly a data audit, and unapologetically so. A trait is seven lines of JSON
## and every failure mode is a quiet one: a missing modifier defaults to 1.0, a
## missing weight makes a trait that never appears, a typo makes a trait that
## cannot be assigned. None of those crash, and none of them are noticed by
## playing — which is exactly the shape of bug a test is for.
##
## The numbers themselves stay the owner's to move. What is pinned here is that
## a trait DOES something and does not do too much.

const TRAITS := preload("res://scripts/pals/pal_traits.gd")
const INSTANCE := preload("res://scripts/pals/pal_instance.gd")


# --- the file loads -------------------------------------------------------

func test_the_roster_is_not_empty() -> void:
	assert_true(TRAITS.table().size() >= 6,
		"only %d traits; with too few, every pal of a species feels the same" % TRAITS.table().size())


func test_every_trait_declares_its_fields() -> void:
	# A missing display_name shows the raw id on the appraisal screen; a missing
	# description leaves a blank line in the M5 ceremony, which is the one screen
	# CLAUDE.md says must not be a generic dialog.
	for id: String in TRAITS.ids():
		var definition: Dictionary = TRAITS.definition(id)
		assert_false(str(definition.get("display_name", "")).is_empty(),
			"trait '%s' has no display_name" % id)
		assert_false(str(definition.get("description", "")).is_empty(),
			"trait '%s' has no description" % id)
		assert_true(definition.has("modifiers"), "trait '%s' has no modifiers" % id)


func test_every_trait_states_all_three_stats() -> void:
	# Explicitly, even when the answer is 1.0. A missing key defaults silently,
	# and "I meant to make this one frail" is not visible in a diff.
	for id: String in TRAITS.ids():
		var mods: Dictionary = TRAITS.definition(id).get("modifiers", {})
		for stat: String in TRAITS.STATS:
			assert_true(mods.has(stat), "trait '%s' says nothing about %s" % [id, stat])


func test_no_comment_key_can_become_a_trait() -> void:
	# traits.json invites `_comment_<topic>` keys inline. One written a level too
	# high would otherwise be rollable, and a pal would be born "_comment_range"
	# with no stats at all.
	for id: String in TRAITS.ids():
		assert_false(id.begins_with("_"), "'%s' is prose, not a trait" % id)


# --- the numbers are sane -------------------------------------------------

func test_no_trait_zeroes_or_inverts_a_stat() -> void:
	for id: String in TRAITS.ids():
		for stat: String in TRAITS.STATS:
			assert_true(TRAITS.modifier(id, stat) > 0.0,
				"trait '%s' would leave a pal with no %s at all" % [id, stat])


func test_no_trait_matters_more_than_the_fight_does() -> void:
	# GAME_DESIGN.md §11 wants appraisal shown as stars, which only works while
	# the spread is a nudge. A trait that doubled attack would make the roll more
	# important than every decision made in the fight afterwards.
	for id: String in TRAITS.ids():
		for stat: String in TRAITS.STATS:
			assert_between(TRAITS.modifier(id, stat), 0.75, 1.25,
				"trait '%s' moves %s further than an appraisal can express" % [id, stat])


func test_every_trait_actually_changes_something() -> void:
	# A trait that multiplies everything by exactly 1.0 is a name on a screen and
	# nothing else, which teaches the player that traits do not matter.
	for id: String in TRAITS.ids():
		var moved := false
		for stat: String in TRAITS.STATS:
			if absf(TRAITS.modifier(id, stat) - 1.0) > 0.001:
				moved = true
		assert_true(moved, "trait '%s' changes nothing" % id)


func test_the_roster_is_not_all_upgrades() -> void:
	# A roster of pure gains turns appraisal into one 'is it good' number, and
	# there is then no reason to keep the frail one that hits hard — which is
	# precisely the decision M5's ceremony is built around.
	var with_a_cost := 0
	for id: String in TRAITS.ids():
		for stat: String in TRAITS.STATS:
			if TRAITS.modifier(id, stat) < 1.0:
				with_a_cost += 1
				break
	assert_true(with_a_cost >= 2,
		"only %d trait(s) cost the pal anything" % with_a_cost)


# --- lookups --------------------------------------------------------------

func test_an_unknown_trait_does_not_silently_zero_a_stat() -> void:
	# Same choice catch_math.orb_multiplier made: a typo should leave a pal
	# ordinary, not leave it with no attack.
	assert_almost_eq(TRAITS.modifier("does_not_exist", "attack"), 1.0, 0.001)
	assert_almost_eq(TRAITS.modifier("", "hp"), 1.0, 0.001)


func test_an_unknown_stat_is_harmless() -> void:
	assert_almost_eq(TRAITS.modifier(TRAITS.ids()[0], "speed"), 1.0, 0.001)


func test_every_trait_can_be_assigned_to_a_pal() -> void:
	# The end-to-end check the audit above cannot make: the id in the file is the
	# id the instance accepts.
	for id: String in TRAITS.ids():
		var pal: RefCounted = load("res://scripts/pals/pal_species.gd").spawn("starter_ground")
		assert_true(pal.assign_trait(id), "trait '%s' was refused by a pal" % id)
		assert_eq(pal.trait_id, id)


# --- rolling --------------------------------------------------------------

func test_every_roll_produces_a_real_trait() -> void:
	for step in 41:
		var id: String = TRAITS.roll(float(step) / 40.0)
		assert_true(TRAITS.has(id), "roll %f produced '%s', which is not a trait" % [float(step) / 40.0, id])


func test_a_roll_at_the_very_top_of_the_range_is_still_a_trait() -> void:
	# The off-by-one that leaves a pal traitless once in a few hundred captures
	# and is never reproduced by the person who saw it.
	assert_true(TRAITS.has(TRAITS.roll(1.0)))
	assert_true(TRAITS.has(TRAITS.roll(0.0)))


func test_rolling_is_reproducible() -> void:
	assert_eq(TRAITS.roll(0.37), TRAITS.roll(0.37))


func test_the_common_trait_is_actually_common() -> void:
	# The strong traits only feel strong because most pals do not have one. This
	# checks the weights in data/config/party.json are wired to the roll at all,
	# not that any particular trait is the common one.
	var counts: Dictionary = {}
	var samples := 400
	for step in samples:
		var id: String = TRAITS.roll(float(step) / float(samples))
		counts[id] = int(counts.get(id, 0)) + 1
	var most := 0
	for id: Variant in counts.keys():
		most = maxi(most, int(counts[id]))
	assert_true(most > samples / TRAITS.ids().size(),
		"no trait is any more likely than any other; the roll is ignoring its weights")


func test_a_rare_trait_is_rarer_than_a_common_one() -> void:
	var brittle := 0
	var steady := 0
	var samples := 400
	for step in samples:
		var id: String = TRAITS.roll(float(step) / float(samples))
		if id == "brittle":
			brittle += 1
		elif id == "steady":
			steady += 1
	assert_true(brittle < steady,
		"the glass cannon (%d of %d) is not rarer than the boring one (%d)" % [brittle, samples, steady])
