extends "res://tests/test_case.gd"

const REPLACEMENT := preload("res://tests/helpers/earned_roster_replacement_segment.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func test_receipt_matches_real_party_removal_and_append_with_duplicate_species() -> void:
	var party := PARTY.new()
	for species in ["ripplet", "bramblebun", "bramblebun", "bramblebun", "mudsnout"]:
		assert_true(party.add(SPECIES.spawn(species)))
	var newcomer := SPECIES.spawn("meadowhart")
	var before := REPLACEMENT.roster_ids(party)
	assert_false(party.add(newcomer), "a pending newcomer cannot become a sixth owner")
	var outgoing: RefCounted = party.remove_at(2)
	assert_eq(outgoing.get_instance_id(), before[2])
	assert_true(party.add(newcomer))
	var after := REPLACEMENT.roster_ids(party)
	assert_true(REPLACEMENT.replacement_receipt(before, after, 2, newcomer.get_instance_id()))
	assert_eq(after.size(), 5)
	assert_eq(after[4], newcomer.get_instance_id())
	assert_false(REPLACEMENT.replacement_receipt(before, after, 1, newcomer.get_instance_id()),
		"a different Bramblebun leaving cannot satisfy the chosen identity")
	var in_place := before.duplicate()
	in_place[2] = newcomer.get_instance_id()
	assert_false(REPLACEMENT.replacement_receipt(before, in_place, 2, newcomer.get_instance_id()),
		"production shifts the other four and appends; it does not replace in place")
	assert_eq(REPLACEMENT.roster_ids(party), after, "receipt checking never changes the roster")


func test_receipt_rejects_sixth_slot_unchanged_and_unrelated_rosters() -> void:
	var before: Array[int] = [1, 2, 3, 4, 5]
	assert_false(REPLACEMENT.replacement_receipt(before, [1, 2, 3, 4, 5, 6], 2, 6))
	assert_false(REPLACEMENT.replacement_receipt(before, before, 2, 6))
	assert_false(REPLACEMENT.replacement_receipt(before, [1, 2, 4, 9, 6], 2, 6))
	assert_false(REPLACEMENT.replacement_receipt(before, [1, 2, 4, 5, 6], -1, 6))
	assert_false(REPLACEMENT.replacement_receipt(before, [1, 2, 4, 5, 6], 5, 6))
	assert_false(REPLACEMENT.replacement_receipt(before, [1, 2, 4, 5, 6], 2, 5))
	assert_false(REPLACEMENT.replacement_receipt([1, 2, 2, 4, 5], [1, 2, 4, 5, 6], 2, 6))
