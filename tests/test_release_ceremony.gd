extends "res://tests/test_case.gd"

## The M5 keep/release ceremony.
##
## One bullet in MEADOWS_VERTICAL_SLICE.md M5 is not tuning and never will be:
## "Released pal leaves permanently." Everything else in this file guards the
## shape of the decision — six presented, one chosen, one resolution — but the
## save round-trip at the bottom is the one that would let the owner discover,
## a week later, that the pal they agonised over came back on the next load.
##
## Every pal here is given a distinct nickname. Five pals of one species are
## indistinguishable in a record, and a test that cannot tell them apart cannot
## tell "the right one left" from "one of them left".

const PARTY := preload("res://scripts/pals/party.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const CEREMONY := preload("res://scripts/pals/release_ceremony.gd")

const A_SPECIES := "starter_ground"


func _pal(name: String) -> RefCounted:
	var pal: RefCounted = SPECIES.spawn(A_SPECIES)
	pal.rename(name)
	return pal


func _full_party() -> RefCounted:
	var party: RefCounted = PARTY.new()
	for i in PARTY.MAX_PARTY:
		party.add(_pal("member_%d" % i))
	return party


func _names(pals: Array) -> Array:
	var out: Array = []
	for pal: Variant in pals:
		out.append((pal as RefCounted).display())
	return out


# --- when there is anything to decide -------------------------------------

func test_a_party_with_room_gets_no_ceremony() -> void:
	# A dialog asking the player to give up a pal when a slot is free is worse
	# than no dialog. The ceremony exists only because add() refused.
	var party: RefCounted = PARTY.new()
	for i in 4:
		party.add(_pal("member_%d" % i))
	assert_eq(CEREMONY.open(party, _pal("newcomer")), null, "a party of four opened a ceremony")
	assert_ne(CEREMONY.open(_full_party(), _pal("newcomer")), null,
		"a full party did not open a ceremony")


func test_a_newcomer_that_cannot_be_presented_gets_no_ceremony() -> void:
	var party := _full_party()
	assert_eq(CEREMONY.open(party, null), null, "a null newcomer opened a ceremony")
	# Presenting a pal the party already holds would show the same creature in two
	# slots and let the player release it into itself.
	assert_eq(CEREMONY.open(party, party.at(2)), null,
		"a pal the party already holds opened a ceremony")


# --- what is presented ----------------------------------------------------

func test_six_are_presented_with_the_newcomer_last() -> void:
	var party := _full_party()
	var before: Array = party.members()
	var newcomer := _pal("newcomer")
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)

	assert_eq(ceremony.count(), 6)
	var candidates: Array = ceremony.candidates()
	assert_eq(candidates.size(), 6, "the ceremony did not present six")
	for i in 5:
		assert_eq(candidates[i], before[i], "party order was not preserved at slot %d" % i)
		assert_false(ceremony.is_newcomer(i), "slot %d was reported as the newcomer" % i)
	assert_eq(candidates[5], newcomer, "the newcomer was not last")
	assert_eq(ceremony.newcomer_index(), 5)
	assert_true(ceremony.is_newcomer(5))
	assert_eq(ceremony.at(5), newcomer)
	assert_eq(ceremony.at(6), null, "an index past the six returned a pal")


func test_the_party_does_not_grow_while_the_decision_is_open() -> void:
	# The sixth pal is held on the ceremony and nowhere else. If opening one ever
	# parks it somewhere, the release stops being the only way out of a full
	# party — see the header of party.gd.
	var party := _full_party()
	var newcomer := _pal("newcomer")
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)
	assert_eq(party.size(), 5, "opening the ceremony changed the party")
	assert_eq(party.index_of(newcomer), -1, "the newcomer was stored in the party")
	assert_false(ceremony.resolved())

	# candidates() must hand out a copy, for the reason party.members() does.
	var stolen: Array = ceremony.candidates()
	stolen.append(_pal("intruder"))
	assert_eq(ceremony.count(), 6, "appending to candidates() changed the ceremony")


func test_a_summary_says_what_is_being_given_up() -> void:
	var party := _full_party()
	var newcomer := _pal("newcomer")
	newcomer.grant_xp(newcomer.xp_for_next_level() + 3)
	newcomer.take_damage(5.0)
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)

	var summary: Dictionary = ceremony.summary(5)
	for key: String in ["name", "species", "level", "xp", "hp", "max_hp", "trait_id", "newcomer"]:
		assert_true(summary.has(key), "a summary said nothing about '%s'" % key)
	assert_eq(summary["name"], "newcomer")
	assert_eq(summary["species"], newcomer.species_id)
	assert_eq(summary["level"], newcomer.level)
	assert_eq(summary["xp"], newcomer.xp)
	assert_almost_eq(float(summary["hp"]), newcomer.hp, 0.001)
	assert_almost_eq(float(summary["max_hp"]), newcomer.max_hp, 0.001)
	assert_eq(summary["trait_id"], newcomer.trait_id)
	assert_true(bool(summary["newcomer"]), "the newcomer's summary did not say so")
	assert_false(bool((ceremony.summary(0) as Dictionary)["newcomer"]),
		"a party member's summary claimed to be the newcomer")
	assert_true((ceremony.summary(9) as Dictionary).is_empty(),
		"an out-of-range summary invented a pal")


# --- choosing -------------------------------------------------------------

func test_choosing_outside_the_six_is_refused() -> void:
	# Refused rather than clamped. A clamp turns a mis-sent index into a real
	# creature being released, and that is the one mistake here with no undo.
	var ceremony: RefCounted = CEREMONY.open(_full_party(), _pal("newcomer"))
	assert_false(ceremony.choose(6), "an index past the six was accepted")
	assert_eq(ceremony.chosen_index(), -1, "a refused choice was recorded anyway")
	assert_eq(ceremony.last_refusal(), CEREMONY.REFUSED_NOT_A_CANDIDATE)
	assert_false(ceremony.choose(-1), "a negative index was accepted")
	assert_eq(ceremony.chosen_index(), -1)
	assert_eq(ceremony.chosen(), null)


func test_a_choice_can_be_changed_and_taken_back_before_it_is_final() -> void:
	var party := _full_party()
	var ceremony: RefCounted = CEREMONY.open(party, _pal("newcomer"))
	assert_true(ceremony.choose(1))
	assert_eq(ceremony.chosen(), party.at(1))
	assert_true(ceremony.last_refusal().is_empty(), "a successful choice reported a refusal")
	assert_true(ceremony.choose(3))
	assert_eq(ceremony.chosen_index(), 3)
	ceremony.clear_choice()
	assert_eq(ceremony.chosen_index(), -1)
	assert_eq(party.size(), 5, "changing the highlighted choice touched the party")


# --- resolving ------------------------------------------------------------

func test_releasing_a_middle_member_puts_the_newcomer_in_its_place() -> void:
	var party := _full_party()
	var newcomer := _pal("newcomer")
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)
	var doomed: RefCounted = party.at(2)

	assert_true(ceremony.choose(2))
	var outcome: Dictionary = ceremony.resolve()
	assert_false(outcome.is_empty(), "a valid resolution was refused: %s" % ceremony.last_refusal())
	assert_eq(outcome["released"], doomed, "the wrong pal was reported as released")
	assert_true(ceremony.last_refusal().is_empty())
	assert_true(ceremony.resolved())

	assert_eq(party.size(), PARTY.MAX_PARTY, "the party did not end at five")
	assert_eq(party.index_of(doomed), -1, "the released pal is still in the party")
	assert_true(party.index_of(newcomer) >= 0, "the newcomer was not kept")
	assert_eq((outcome["kept"] as Array).size(), 5)
	assert_eq(_names(outcome["kept"]), _names(party.members()), "kept did not match the party")


func test_releasing_the_newcomer_leaves_the_party_exactly_as_it_was() -> void:
	var party := _full_party()
	var before: Array = party.members()
	var newcomer := _pal("newcomer")
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)

	assert_true(ceremony.choose(ceremony.newcomer_index()))
	var outcome: Dictionary = ceremony.resolve()
	assert_eq(outcome["released"], newcomer, "the newcomer was not the one released")
	assert_eq(party.size(), PARTY.MAX_PARTY)
	var after: Array = party.members()
	for i in 5:
		assert_eq(after[i], before[i], "slot %d holds a different pal than before" % i)
	assert_eq(party.index_of(newcomer), -1, "the released newcomer got into the party")


func test_a_ceremony_cannot_be_run_twice() -> void:
	# Two runs would cost two pals for one capture, and the second is a pal the
	# player never chose to give up.
	var party := _full_party()
	var ceremony: RefCounted = CEREMONY.open(party, _pal("newcomer"))
	ceremony.choose(0)
	assert_false((ceremony.resolve() as Dictionary).is_empty())
	var after: Array = party.members()

	assert_true((ceremony.resolve() as Dictionary).is_empty(), "the ceremony resolved twice")
	assert_eq(ceremony.last_refusal(), CEREMONY.REFUSED_ALREADY_RESOLVED)
	assert_eq(party.size(), PARTY.MAX_PARTY, "the second resolution changed the party size")
	assert_eq(_names(party.members()), _names(after), "the second resolution changed the party")

	# And it cannot be re-armed by choosing again, either.
	assert_false(ceremony.choose(1), "a resolved ceremony accepted a new choice")
	assert_eq(ceremony.last_refusal(), CEREMONY.REFUSED_ALREADY_RESOLVED)


func test_resolving_without_a_choice_refuses_and_changes_nothing() -> void:
	var party := _full_party()
	var before: Array = party.members()
	var newcomer := _pal("newcomer")
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)

	assert_true((ceremony.resolve() as Dictionary).is_empty(), "an unchosen ceremony resolved")
	assert_eq(ceremony.last_refusal(), CEREMONY.REFUSED_NONE_CHOSEN)
	assert_false(ceremony.resolved(), "a refused resolution counted as a resolution")
	assert_eq(_names(party.members()), _names(before), "a refused resolution changed the party")
	assert_eq(party.index_of(newcomer), -1, "a refused resolution kept the newcomer")

	# A refusal must not lock the decision out; the player still has to make it.
	assert_true(ceremony.choose(0))
	assert_false((ceremony.resolve() as Dictionary).is_empty(),
		"a ceremony refused once could never be resolved")


func test_releasing_the_deployed_pal_leaves_something_deployed() -> void:
	# An active_index left pointing past the end, or at nothing, is a fight that
	# opens with no creature in it — and it would be blamed on combat, not here.
	for slot in PARTY.MAX_PARTY:
		var party := _full_party()
		party.set_active(slot)
		var ceremony: RefCounted = CEREMONY.open(party, _pal("newcomer"))
		ceremony.choose(slot)
		assert_false((ceremony.resolve() as Dictionary).is_empty())
		assert_true(party.active_index >= 0 and party.active_index < party.size(),
			"releasing slot %d left active_index at %d of %d" % [slot, party.active_index, party.size()])
		assert_ne(party.active(), null, "releasing slot %d left nothing deployed" % slot)


# --- permanently ----------------------------------------------------------

func test_a_released_pal_does_not_come_back_through_the_save() -> void:
	# The M5 bullet that matters most, tested through the real record path rather
	# than by inspecting the array: §10 says a released pal is permanently gone,
	# and the only way the owner would ever find out otherwise is by loading.
	var party := _full_party()
	var newcomer := _pal("newcomer")
	var ceremony: RefCounted = CEREMONY.open(party, newcomer)
	ceremony.choose(3)
	var released: RefCounted = ceremony.resolve()["released"]
	assert_eq(released.display(), "member_3")

	var restored: RefCounted = PARTY.from_records(party.to_records())
	assert_eq(restored.size(), PARTY.MAX_PARTY, "the save did not hold five")
	for pal: Variant in restored.members():
		assert_ne((pal as RefCounted).display(), released.display(),
			"the released pal came back out of the save")
	assert_true(_names(restored.members()).has("newcomer"), "the kept newcomer did not survive the save")
	assert_true(restored.active_index >= 0 and restored.active_index < restored.size())

	# And a second round-trip does not resurrect it either.
	var again: RefCounted = PARTY.from_records(restored.to_records())
	assert_eq(again.size(), PARTY.MAX_PARTY)
	assert_false(_names(again.members()).has(released.display()),
		"the released pal reappeared on the second load")
