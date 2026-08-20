extends "res://tests/test_case.gd"

## The five-creature cap, and the things that could quietly break it.
##
## CLAUDE.md states it twice: "Player can own only five creatures total" and "Never
## implement creature storage beyond five". A cap enforced in one place is a cap that
## can be walked around by adding a second place, so the first test here is that
## `add` is the only door and it is shut at five.
##
## The rest is reordering. Party order is what a deploy wheel will read, and an
## off-by-one in `move` would deploy the wrong creature at the moment that matters
## most — which is a bug the owner would meet in a fight, not in a menu.

const PARTY := preload("res://autoload/party.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

var party: RefCounted = null


func before_each() -> void:
	party = PARTY.new()


func _creature(name: String, hp: float = 100.0) -> RefCounted:
	return CREATURE.from_species("terrapup", {
		"display_name": name, "type": "ground", "base_hp": hp,
		"base_attack": 20.0, "base_defence": 20.0,
	})


func _fill(count: int) -> void:
	for i in count:
		party.add(_creature("Creature %d" % i))


func test_the_cap_is_five() -> void:
	assert_eq(PARTY.MAX_CREATURES, 5)


func test_a_sixth_creature_is_refused_and_changes_nothing() -> void:
	_fill(5)
	assert_true(party.is_full())
	var sixth: RefCounted = _creature("Sixth")
	assert_false(party.add(sixth), "the cap must refuse rather than grow")
	assert_eq(party.size(), 5)
	# The refused creature must not be reachable through the party by any route.
	# There is no box, no reserve and no overflow list, and this is the test
	# that stays failing if anyone adds one.
	for i in 8:
		assert_ne(party.at(i), sixth)


func test_free_slots_counts_down_to_zero_and_stops() -> void:
	assert_eq(party.free_slots(), 5)
	_fill(3)
	assert_eq(party.free_slots(), 2)
	_fill(5)
	assert_eq(party.free_slots(), 0)


func test_the_same_creature_cannot_be_added_twice() -> void:
	var creature: RefCounted = _creature("Biscuit")
	assert_true(party.add(creature))
	assert_false(party.add(creature), "a duplicate would let one creature hold two slots")
	assert_eq(party.size(), 1)


func test_a_null_creature_is_refused() -> void:
	assert_false(party.add(null))
	assert_eq(party.size(), 0)


func test_the_member_list_handed_out_cannot_grow_the_party() -> void:
	_fill(5)
	var members: Array = party.members()
	members.append(_creature("Smuggled"))
	assert_eq(party.size(), 5, "members() must hand out a copy of the list")


func test_reading_an_out_of_range_slot_is_null_not_a_crash() -> void:
	_fill(2)
	assert_eq(party.at(-1), null)
	assert_eq(party.at(9), null)


func test_removing_makes_room_again() -> void:
	_fill(5)
	var gone: RefCounted = party.remove_at(2)
	assert_ne(gone, null, "remove_at should hand back the creature for the ceremony to show")
	assert_eq(party.size(), 4)
	assert_true(party.add(_creature("Replacement")))
	assert_eq(party.size(), 5)


func test_the_ceremony_swap_produces_the_expected_five() -> void:
	# R4.10's resolution order, exactly as tab_creatures.gd performs it: the
	# sixth catch is refused while the belt is full and held OUTSIDE the party
	# (Game.pending_catch), and only after a release does it take the freed
	# holder. A regression in any step here is the ceremony either losing a
	# creature or smuggling a sixth one in.
	_fill(5)
	var newcomer: RefCounted = _creature("Newcomer")
	assert_false(party.add(newcomer), "the catch must be withheld until a release happens")
	assert_eq(party.size(), 5)
	var released: RefCounted = party.remove_at(1)
	assert_ne(released, null)
	assert_true(party.add(newcomer), "the freed holder must accept the withheld catch")
	assert_eq(party.size(), 5)
	assert_eq(party.at(4), newcomer, "the newcomer takes the last holder, not the released one's index")
	for i in 5:
		assert_ne(party.at(i), released, "the released creature must be gone from every slot")


func test_reordering_moves_the_creature_and_nothing_else() -> void:
	_fill(4)
	var first: RefCounted = party.at(0)
	var last: RefCounted = party.at(3)
	party.move(0, 3)
	assert_eq(party.at(3), first)
	assert_eq(party.at(2), last)
	assert_eq(party.size(), 4, "reordering must not add or drop anyone")


func test_reordering_carries_the_active_creature_with_it() -> void:
	# The bug this exists for: the active creature is identified by SLOT, so swapping
	# two creatures without adjusting the index silently deploys the other one.
	_fill(4)
	party.set_active(2)
	var deployed: RefCounted = party.active()
	party.move(2, 0)
	assert_eq(party.active(), deployed, "the creature going out first must not change")
	assert_eq(party.active_index(), 0)


func test_reordering_around_the_active_creature_keeps_it_active() -> void:
	_fill(4)
	party.set_active(2)
	var deployed: RefCounted = party.active()
	party.move(0, 3)
	assert_eq(party.active(), deployed)
	party.move(3, 0)
	assert_eq(party.active(), deployed)


func test_out_of_range_reorders_are_ignored() -> void:
	_fill(3)
	var order: Array = party.members()
	party.move(0, 9)
	party.move(-1, 1)
	assert_eq(party.members(), order)


func test_cycle_active_wraps_both_directions_and_skips_unavailable() -> void:
	_fill(5)
	assert_true(party.cycle_active(1))
	assert_eq(party.active_index(), 1)
	party.at(2).resting = true
	party.at(3).take_damage(party.at(3).max_hp)
	assert_true(party.cycle_active(1))
	assert_eq(party.active_index(), 4, "resting and fainted slots must be skipped")
	assert_true(party.cycle_active(1))
	assert_eq(party.active_index(), 0, "forward cycle wraps")
	assert_true(party.cycle_active(-1))
	assert_eq(party.active_index(), 4, "reverse cycle wraps")


func test_resting_creature_refuses_to_take_the_field() -> void:
	_fill(2)
	party.at(1).resting = true
	assert_false(party.set_active(1))
	assert_ne(party.active_index(), 1)


func test_a_fainted_creature_refuses_to_take_the_field() -> void:
	_fill(3)
	var creature: RefCounted = party.at(1)
	creature.take_damage(creature.max_hp)
	assert_true(creature.fainted)
	assert_false(party.set_active(1), "a fainted creature must refuse rather than deploy")
	assert_ne(party.active_index(), 1)


func test_all_fainted_is_false_for_an_empty_party() -> void:
	# An empty party is not a defeated one. Reporting "all your creatures are down"
	# before the player owns any would be a lie with a scary tone.
	assert_false(party.all_fainted())
	_fill(2)
	assert_false(party.all_fainted())
	for creature in party.members():
		creature.take_damage(creature.max_hp)
	assert_true(party.all_fainted())


func test_removing_the_active_creature_leaves_a_valid_active_slot() -> void:
	_fill(3)
	party.set_active(2)
	party.remove_at(2)
	assert_true(party.active_index() < party.size(), "the active slot must stay in range")
	assert_ne(party.active(), null)


func test_removing_the_last_creature_leaves_no_active() -> void:
	_fill(1)
	party.remove_at(0)
	assert_eq(party.size(), 0)
	assert_eq(party.active(), null)


func test_the_revision_counter_moves_when_the_party_does() -> void:
	var before: int = party.revision
	party.add(null)
	assert_eq(party.revision, before, "a refused add must not make the menu rebuild")
	party.add(_creature("Biscuit"))
	assert_true(party.revision > before)


func test_clear_empties_the_party_and_resets_active() -> void:
	# R3.1: save/load rehydrates the party through clear() + add(), so a stale
	# member left behind by clear() would silently survive every load.
	_fill(3)
	party.set_active(2)
	var before: int = party.revision
	party.clear()
	assert_eq(party.size(), 0)
	assert_eq(party.active_index(), 0)
	assert_eq(party.active(), null)
	assert_true(party.revision > before)
