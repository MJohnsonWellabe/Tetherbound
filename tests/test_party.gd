extends "res://tests/test_case.gd"

## The party, and what a pal is worth.
##
## Two rules here are not tuning and never will be: five is the ceiling, and a
## save round-trip must give back the same creature. CLAUDE.md states the first
## twice; the second is what stops a crash from costing the owner the pal they
## spent an evening levelling. Everything else in this file — how fast a level
## arrives, how much a level-up gives — is deliberately tested for SHAPE rather
## than for value, so rebalancing party.json does not turn the suite red.

const PARTY := preload("res://scripts/pals/party.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const INSTANCE := preload("res://scripts/pals/pal_instance.gd")

const A_SPECIES := "starter_ground"


## A pal with NO trait, for the tests that measure against the species baseline.
##
## `spawn()` gives every pal a trait — GAME_DESIGN.md 11 requires it, and until
## it did, the whole trait system loaded and tested while nothing in the game
## ever called it. That makes `spawn()` the wrong constructor for a test that
## needs an exactly-average pal, because a random trait moves the very ratio
## being asserted. These tests want the baseline, so they ask for it explicitly
## rather than relying on a default that has since correctly changed.
func _pal() -> RefCounted:
	var pal: RefCounted = SPECIES.spawn(A_SPECIES)
	pal.assign_trait("")
	return pal


## A pal built the way the game builds one, trait and all.
func _spawned_pal() -> RefCounted:
	return SPECIES.spawn(A_SPECIES)


func _full_party() -> RefCounted:
	var party: RefCounted = PARTY.new()
	for i in PARTY.MAX_PARTY:
		party.add(_pal())
	return party


# --- traits reach the game ------------------------------------------------

func test_every_spawned_pal_has_a_trait() -> void:
	# The gap this closes: `traits.json` loaded, `pal_traits.gd` was tested, and
	# `assign_trait()` worked — while NOTHING in the game ever called any of it.
	# Every creature in the build had `trait_id == ""`, so a whole system was
	# green and inert at the same time. GAME_DESIGN.md 11 says a pal starts with
	# a trait; this is the line that makes that true of pals the game creates
	# rather than of pals a test creates.
	for i in 12:
		var pal := _spawned_pal()
		assert_false(pal.trait_id.is_empty(), "a spawned pal had no trait")


func test_a_trait_roll_can_be_replayed() -> void:
	# The roll is passed in rather than drawn inside, for the reason
	# catch_math.resolve() gives about its own: a function that reaches for
	# randf() internally cannot be tested and cannot be reproduced from a bug
	# report.
	var a: RefCounted = SPECIES.spawn(A_SPECIES, 0.42)
	var b: RefCounted = SPECIES.spawn(A_SPECIES, 0.42)
	assert_eq(a.trait_id, b.trait_id, "the same roll produced two different traits")


# --- the ceiling ----------------------------------------------------------

func test_the_party_holds_five() -> void:
	# CLAUDE.md, twice. If this number ever changes, it was a design decision and
	# not a refactor.
	assert_eq(PARTY.MAX_PARTY, 5)


func test_a_sixth_pal_is_refused_and_the_party_still_has_five() -> void:
	var party := _full_party()
	assert_eq(party.size(), 5, "five adds should have filled the party")
	var sixth := _pal()
	assert_false(party.add(sixth), "the sixth pal was accepted")
	assert_eq(party.size(), 5, "the party grew past its ceiling")
	assert_eq(party.index_of(sixth), -1, "the refused pal ended up in the party anyway")


func test_the_refusal_says_which_refusal_it_was() -> void:
	# M5 hangs off this: a full party opens the keep/release ceremony, and any
	# other refusal must not. An empty or ambiguous reason makes that impossible
	# to tell apart from a bug.
	var party := _full_party()
	party.add(_pal())
	assert_false(party.last_refusal().is_empty(), "a refusal reported no reason at all")
	assert_eq(party.last_refusal(), PARTY.REFUSED_PARTY_FULL)


func test_a_successful_add_clears_the_previous_refusal() -> void:
	# A stale reason is worse than none: the ceremony would open on the next
	# capture after a full party, forever.
	var party: RefCounted = PARTY.new()
	assert_false(party.add(null))
	assert_true(party.add(_pal()))
	assert_true(party.last_refusal().is_empty())


func test_releasing_one_makes_room_for_exactly_one() -> void:
	var party := _full_party()
	assert_true(party.remove_at(2))
	assert_true(party.add(_pal()), "a released slot should be usable")
	assert_false(party.add(_pal()), "the party accepted a seventh creature over its life")
	assert_eq(party.size(), 5)


func test_the_roster_cannot_be_grown_from_outside() -> void:
	# members() must hand back a copy. GDScript passes an Array by reference, so
	# returning the live one would let any caller sidestep add() entirely and the
	# five-pal rule would hold only by good manners.
	var party := _full_party()
	var roster: Array = party.members()
	roster.append(_pal())
	assert_eq(party.size(), 5, "appending to members() changed the party itself")


func test_a_save_claiming_six_pals_still_loads_five() -> void:
	# Save files are text files on a Windows machine. This will happen.
	var records: Array = _full_party().to_records()
	records.append(_full_party().to_records()[0])
	var party: RefCounted = PARTY.from_records(records)
	assert_eq(party.size(), 5, "a six-pal save produced a six-pal party")


# --- switching ------------------------------------------------------------

func test_active_index_cannot_leave_the_party() -> void:
	var party := _full_party()
	assert_false(party.set_active(5), "an index past the end was accepted")
	assert_false(party.set_active(-1), "a negative index was accepted")
	assert_eq(party.active_index, 0, "a refused switch moved the active pal anyway")
	assert_true(party.set_active(4))
	assert_eq(party.active_index, 4)


func test_switching_is_refused_rather_than_clamped() -> void:
	# A clamp turns a wrong index into a plausible one, and the game deploys the
	# wrong creature into a fight with nothing in the log to say why.
	var party := _full_party()
	party.set_active(3)
	assert_false(party.set_active(99))
	assert_eq(party.active_index, 3)
	assert_eq(party.last_refusal(), PARTY.REFUSED_NO_SUCH_MEMBER)


func test_cycling_wraps_in_both_directions() -> void:
	var party := _full_party()
	party.set_active(4)
	party.cycle_active(1)
	assert_eq(party.active_index, 0, "cycling past the last pal should wrap to the first")
	party.cycle_active(-1)
	assert_eq(party.active_index, 4, "cycling back from the first should wrap to the last")


func test_releasing_a_pal_keeps_the_active_one_pointed_at_the_same_creature() -> void:
	var party := _full_party()
	party.set_active(3)
	var expected: RefCounted = party.at(3)
	party.remove_at(1)
	assert_eq(party.active(), expected, "releasing another pal changed which one is deployed")


func test_releasing_the_last_pal_leaves_a_usable_active_index() -> void:
	var party := _full_party()
	party.set_active(4)
	party.remove_at(4)
	assert_true(party.active_index < party.size(), "active index survived past the end of the party")
	assert_ne(party.active(), null, "the party has members but nothing is deployed")


func test_an_empty_party_deploys_nothing_rather_than_crashing() -> void:
	var party: RefCounted = PARTY.new()
	assert_eq(party.active(), null)
	assert_false(party.cycle_active(1))


# --- persistence ----------------------------------------------------------

func test_records_round_trip_losslessly() -> void:
	# The pal the owner spent an evening on has to come back as itself. Nickname
	# and trait especially: those are the two things that make it THEIRS rather
	# than a Bramblit.
	var party: RefCounted = PARTY.new()
	var pal := _pal()
	pal.rename("Bramble")
	pal.assign_trait("fierce")
	pal.grant_xp(pal.xp_for_next_level() + 5)
	pal.take_damage(12.0)
	party.add(pal)
	party.add(SPECIES.spawn("wild_rabbit"))
	party.set_active(1)

	var restored: RefCounted = PARTY.from_records(party.to_records())
	assert_eq(restored.size(), 2)
	assert_eq(restored.active_index, 1, "which pal was deployed did not survive the save")

	var back: RefCounted = restored.at(0)
	assert_eq(back.species_id, pal.species_id)
	assert_eq(back.nickname, "Bramble")
	assert_eq(back.display(), "Bramble")
	assert_eq(back.trait_id, "fierce")
	assert_eq(back.level, pal.level)
	assert_eq(back.xp, pal.xp)
	assert_almost_eq(back.hp, pal.hp, 0.001)
	assert_almost_eq(back.max_hp, pal.max_hp, 0.001)
	assert_almost_eq(back.attack, pal.attack, 0.001)
	assert_almost_eq(back.defence, pal.defence, 0.001)


func test_a_record_stores_progress_and_not_derived_stats() -> void:
	# Storing max_hp would freeze the creature at the balance of the build that
	# caught it, and every later rebalance would silently skip it.
	var record: Dictionary = _pal().to_record()
	assert_true(record.has("level"))
	assert_true(record.has("trait"))
	assert_false(record.has("max_hp"), "a derived stat was written into the save")
	assert_false(record.has("attack"), "a derived stat was written into the save")


func test_a_record_naming_an_unknown_species_loses_one_pal_and_not_the_save() -> void:
	var records: Array = _full_party().to_records()
	(records[2] as Dictionary)["species"] = "deleted_in_a_later_build"
	var party: RefCounted = PARTY.from_records(records)
	assert_eq(party.size(), 4, "one bad record should cost one pal, not the party")


func test_a_fainted_pal_is_still_fainted_after_a_reload() -> void:
	# M6 gives fainting an unavailable state and a bed to recover in. A pal that
	# quietly comes back at full health across a save would make that pointless.
	var party: RefCounted = PARTY.new()
	var pal := _pal()
	pal.take_damage(pal.max_hp * 2.0)
	party.add(pal)
	var back: RefCounted = PARTY.from_records(party.to_records()).at(0)
	assert_true(back.fainted)
	assert_almost_eq(back.hp, 0.0, 0.001)


# --- levels ---------------------------------------------------------------

func test_xp_crossing_a_level_boundary_raises_stats() -> void:
	# The whole point of a level. If this ever fails, levelling is a number that
	# goes up beside a creature that has not changed.
	var pal := _pal()
	var before_hp: float = pal.max_hp
	var before_attack: float = pal.attack
	var before_defence: float = pal.defence
	assert_eq(pal.grant_xp(pal.xp_for_next_level()), 1, "exactly enough XP should buy exactly one level")
	assert_eq(pal.level, 2)
	assert_true(pal.max_hp > before_hp, "levelling did not raise max HP")
	assert_true(pal.attack > before_attack, "levelling did not raise attack")
	assert_true(pal.defence > before_defence, "levelling did not raise defence")


func test_xp_short_of_a_level_buys_nothing_but_is_kept() -> void:
	var pal := _pal()
	var needed: int = pal.xp_for_next_level()
	assert_eq(pal.grant_xp(needed - 1), 0)
	assert_eq(pal.level, 1)
	assert_eq(pal.xp, needed - 1, "progress towards the next level was thrown away")


func test_a_large_award_grants_every_level_it_paid_for() -> void:
	# Swallowing the surplus is the bug where a big reward feels smaller than a
	# small one.
	var pal := _pal()
	var gained: int = pal.grant_xp(100000)
	assert_true(gained > 1, "a huge award bought only %d level(s)" % gained)
	assert_eq(pal.level, 1 + gained)


func test_a_level_up_hands_over_the_whole_health_increase() -> void:
	# Not a fraction of it. A pal that levels at half health should not receive
	# half its reward — that reads as the game taking something back at the exact
	# moment it was giving.
	var pal := _pal()
	pal.take_damage(pal.max_hp * 0.5)
	var hp_before: float = pal.hp
	var max_before: float = pal.max_hp
	pal.grant_xp(pal.xp_for_next_level())
	assert_almost_eq(pal.hp - hp_before, pal.max_hp - max_before, 0.001)


func test_levelling_stops_at_the_cap() -> void:
	var pal := _pal()
	pal.set_level(INSTANCE.level_cap())
	assert_eq(pal.grant_xp(999999), 0, "a capped pal gained a level")
	assert_eq(pal.level, INSTANCE.level_cap())
	assert_eq(pal.xp_for_next_level(), 0, "a capped pal still owes XP for a level it cannot reach")


func test_growth_is_not_compound() -> void:
	# data/config/party.json spells out why: a compounding 9% per level reaches
	# 74x by level 50 and every fight becomes a walkover or a wall.
	var low := _pal()
	low.set_level(10)
	var high := _pal()
	high.set_level(50)
	assert_true(high.max_hp < low.max_hp * 6.0,
		"level 50 (%f HP) has run away from level 10 (%f HP)" % [high.max_hp, low.max_hp])


func test_a_level_is_never_below_one() -> void:
	var pal := _pal()
	pal.set_level(-4)
	assert_eq(pal.level, 1)


# --- identity -------------------------------------------------------------

func test_a_pal_answers_to_its_species_name_until_it_is_renamed() -> void:
	# §10: new captures keep the species name BY DEFAULT. That is a display rule,
	# so the nickname stays empty and "never named" and "named Bramblit" remain
	# distinguishable.
	var pal := _pal()
	assert_eq(pal.display(), pal.display_name)
	assert_true(pal.nickname.is_empty())
	pal.rename("Bramble")
	assert_eq(pal.display(), "Bramble")
	pal.clear_nickname()
	assert_eq(pal.display(), pal.display_name)


func test_a_pal_cannot_be_renamed_to_nothing() -> void:
	var pal := _pal()
	pal.rename("Bramble")
	assert_false(pal.rename("   "), "whitespace was accepted as a name")
	assert_eq(pal.display(), "Bramble")


func test_an_unknown_trait_is_refused_rather_than_stored() -> void:
	# A trait id that multiplies nothing is invisible until somebody wonders why
	# their Fierce pal hits like everything else.
	var pal := _pal()
	assert_false(pal.assign_trait("not_a_trait"))
	assert_true(pal.trait_id.is_empty())


# --- appraisal ------------------------------------------------------------

func test_appraisal_reports_data_rather_than_a_sentence() -> void:
	# The M4 party menu and the M5 ceremony present the same facts very
	# differently; a string built here would be right for exactly one of them.
	var pal := _pal()
	pal.assign_trait("hardy")
	var report: Dictionary = pal.appraisal()
	for key: String in ["level", "stars", "max_stars", "stats", "trait", "display", "ratio"]:
		assert_true(report.has(key), "appraisal is missing '%s'" % key)
	assert_eq((report["trait"] as Dictionary)["id"], "hardy")
	for stat: String in ["hp", "attack", "defence"]:
		assert_true((report["stats"] as Dictionary).has(stat), "appraisal says nothing about %s" % stat)


func test_appraisal_compares_against_the_species_and_not_against_zero() -> void:
	# A traitless pal is exactly average by definition. If this drifts, every
	# appraisal in the game is measured against the wrong baseline.
	var report: Dictionary = _pal().appraisal()
	assert_almost_eq(float(report["ratio"]), 1.0, 0.0001)


func test_a_tougher_trait_appraises_tougher() -> void:
	var hardy := _pal()
	hardy.assign_trait("hardy")
	var fierce := _pal()
	fierce.assign_trait("fierce")
	var hardy_hp: Dictionary = (hardy.appraisal()["stats"] as Dictionary)["hp"]
	var fierce_hp: Dictionary = (fierce.appraisal()["stats"] as Dictionary)["hp"]
	assert_true(float(hardy_hp["ratio"]) > float(fierce_hp["ratio"]),
		"the trait that exists to add HP did not appraise higher on HP")


func test_appraisal_is_level_independent() -> void:
	# §11 wants stars, and stars are only meaningful if a level-3 pal and a
	# level-40 pal can be compared with them. Growth must cancel out.
	var young := _pal()
	young.assign_trait("keen")
	var old := _pal()
	old.assign_trait("keen")
	old.set_level(37)
	assert_almost_eq(float(young.appraisal()["ratio"]), float(old.appraisal()["ratio"]), 0.0001)


func test_stars_stay_inside_their_range() -> void:
	var pal := _pal()
	for id: Variant in ["", "brittle", "steady", "hardy", "fierce"]:
		pal.assign_trait(str(id))
		var report: Dictionary = pal.appraisal()
		var stars: int = report["stars"]
		assert_true(stars >= 1, "trait '%s' appraised at %d stars" % [id, stars])
		assert_true(stars <= int(report["max_stars"]), "trait '%s' appraised above the maximum" % id)
