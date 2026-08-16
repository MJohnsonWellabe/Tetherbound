extends "res://tests/test_case.gd"

## The satchel's arithmetic.
##
## Every failure in here is one a player would meet as lost materials: a pickup
## that vanished into a full satchel, a craft that ate half its cost and then
## refused, a stack that merged with something it should not have. None of it is
## visible from playing until it has already cost somebody an hour of gathering.
##
## Runs against the REAL data/items/items.json rather than a fixture, so a stack
## size deleted from the data file fails here rather than in the menu.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")

var db: RefCounted = null
var bag: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)


func test_the_four_starting_items_are_all_defined() -> void:
	# MEADOWS_VERTICAL_SLICE.md M8's minimal set. The menu names none of these;
	# if one is renamed in the data file, this is what says so.
	for id in ["wood", "stone", "fiber", "berries"]:
		assert_true(db.has(id), "items.json is missing %s" % id)
		assert_true(db.stack_size(id) > 1, "%s must stack" % id)


func test_the_six_tools_are_defined() -> void:
	# R2.1's five — axe, pickaxe, hammer, knife, fishing rod — plus R7.6's
	# hoe. Owned, not consumed.
	for id in ["axe", "pickaxe", "hammer", "knife", "fishing_rod", "hoe"]:
		assert_true(db.has(id), "items.json is missing %s" % id)
		assert_eq(db.kind(id), "tool")


## R7.6. A hoe is an ordinary tool in the satchel and nothing more: it holds
## one, it wears down like the other five, and a second one opens its own slot
## rather than stacking. The farm's own rules are `tests/test_farming.gd`'s
## subject; this is the half that belongs to the bag.
func test_the_hoe_is_an_ordinary_single_slot_tool() -> void:
	assert_eq(db.stack_size("hoe"), 1, "a tool that stacks is a tool you can hoard")
	assert_eq(bag.add("hoe", 1), 0)
	var slot: int = bag.find_slot("hoe")
	assert_true(slot >= 0)
	assert_eq(bag.durability_at(slot), db.max_durability("hoe"),
		"a freshly-added tool must read as fully repaired without add() writing the field")
	bag.damage_tool(slot)
	assert_eq(bag.durability_at(slot), db.max_durability("hoe") - 1)
	assert_eq(bag.add("hoe", 1), 0)
	assert_eq(bag.count("hoe"), 2)
	assert_eq(bag.used_slots(), 2)


## R7.6. Seeds are a plain stacking resource — a satchel that needed one slot
## per seed would make sowing six beds an inventory problem.
func test_berry_seeds_stack_like_any_other_resource() -> void:
	assert_true(db.has("berry_seeds"), "items.json is missing berry_seeds")
	assert_eq(db.kind("berry_seeds"), "resource")
	assert_true(db.stack_size("berry_seeds") > 1, "seeds must stack")
	assert_eq(bag.add("berry_seeds", 6), 0)
	assert_eq(bag.used_slots(), 1, "six seeds must be one slot, not six")
	assert_eq(bag.count("berry_seeds"), 6)
	# Sowing spends exactly one, all-or-nothing like every other removal.
	assert_true(bag.remove("berry_seeds", 1))
	assert_eq(bag.count("berry_seeds"), 5)
	assert_false(bag.remove("berry_seeds", 99), "a sow must not half-consume the stack")
	assert_eq(bag.count("berry_seeds"), 5)


## OF29. A TM is a carried item now, not a progression flag — and a single-use
## one, so it deliberately does NOT stack: two discs of the same TM occupy two
## slots, the same way two axes would. The design choice is recorded in
## items.json's `_comment_tm`; this is what stops a later data edit quietly
## turning one slot into "several lessons in hand" without anyone deciding to.
func test_two_copies_of_one_tm_take_two_slots() -> void:
	assert_eq(db.kind("tm_stone_rush"), "tm")
	assert_eq(db.stack_size("tm_stone_rush"), 1, "a TM must not stack")

	assert_eq(bag.add("tm_stone_rush", 1), 0)
	assert_eq(bag.used_slots(), 1)
	assert_eq(bag.count("tm_stone_rush"), 1)

	assert_eq(bag.add("tm_stone_rush", 1), 0, "a second disc must still fit, in its own slot")
	assert_eq(bag.used_slots(), 2)
	assert_eq(bag.count("tm_stone_rush"), 2)


## Teaching spends exactly one disc (tab_backpack.gd::_on_target_row()), so the
## satchel arithmetic underneath it has to empty the slot rather than leave a
## zero-count stack sitting there looking like an item.
func test_spending_a_tm_empties_its_slot() -> void:
	bag.add("tm_burrow_strike", 1)
	var slot: int = bag.find_slot("tm_burrow_strike")
	assert_true(slot >= 0, "the disc should be findable after adding it")

	assert_true(bag.remove("tm_burrow_strike", 1))

	assert_eq(bag.count("tm_burrow_strike"), 0)
	assert_eq(bag.used_slots(), 0)
	assert_true(bag.is_slot_empty(slot))


func test_gathered_with_names_the_right_tool_for_each_tutorial_resource() -> void:
	assert_eq(db.gathered_with("wood"), "axe")
	assert_eq(db.gathered_with("stone"), "pickaxe")
	assert_eq(db.gathered_with("fiber"), "knife")
	assert_eq(db.gathered_with("berries"), "", "berries must never be tool-gated")


func test_harvest_yield_rewards_the_right_tool() -> void:
	assert_eq(db.harvest_yield("wood", 4, true, true), 4)
	assert_eq(db.harvest_yield("wood", 4, true, false), 4,
		"owning nothing else shouldn't matter once the right tool is owned")


func test_harvest_yield_reduces_bare_hands_but_never_to_zero() -> void:
	assert_eq(db.harvest_yield("wood", 4, false, false), 2)
	assert_eq(db.harvest_yield("wood", 1, false, false), 1,
		"a bare-handed gather must never round down to nothing")


func test_harvest_yield_refuses_the_wrong_tool() -> void:
	assert_eq(db.harvest_yield("wood", 4, false, true), 0)


func test_harvest_yield_never_gates_an_ungated_resource() -> void:
	assert_eq(db.harvest_yield("berries", 3, false, false), 3)
	assert_eq(db.harvest_yield("berries", 3, false, true), 3)


func test_a_fresh_satchel_is_empty_and_not_full() -> void:
	assert_eq(bag.used_slots(), 0)
	assert_false(bag.is_full())
	assert_eq(bag.count("wood"), 0)
	assert_eq(bag.slot_count(), 24)


func test_adding_below_a_stack_uses_one_slot() -> void:
	assert_eq(bag.add("wood", 10), 0, "nothing should have been left over")
	assert_eq(bag.count("wood"), 10)
	assert_eq(bag.used_slots(), 1)


func test_adding_past_a_stack_opens_another_slot() -> void:
	var cap: int = db.stack_size("wood")
	bag.add("wood", cap + 5)
	assert_eq(bag.count("wood"), cap + 5)
	assert_eq(bag.used_slots(), 2)
	assert_eq(int(bag.stack_at(0).get("n", 0)), cap, "the first slot should be filled to the cap")
	assert_eq(int(bag.stack_at(1).get("n", 0)), 5)


func test_a_partial_stack_is_topped_up_before_a_new_slot_opens() -> void:
	# The bug this prevents: a satchel holding three half-stacks of wood while
	# reporting itself full.
	bag.add("wood", 10)
	bag.add("wood", 10)
	assert_eq(bag.used_slots(), 1, "two small adds must share a slot")
	assert_eq(bag.count("wood"), 20)


func test_what_does_not_fit_is_reported_not_discarded() -> void:
	var cap: int = db.stack_size("wood")
	var capacity: int = cap * bag.slot_count()
	var left: int = bag.add("wood", capacity + 17)
	assert_eq(left, 17, "the overflow must be handed back to the caller")
	assert_eq(bag.count("wood"), capacity)
	assert_true(bag.is_full())


func test_an_unknown_item_does_not_take_the_satchel_down() -> void:
	# A harvest table naming an item that no longer exists must degrade, not
	# crash: one per slot, identified by its id.
	assert_eq(db.stack_size("moonrock"), 1)
	assert_eq(bag.add("moonrock", 3), 0)
	assert_eq(bag.used_slots(), 3, "an unstackable unknown takes one slot each")
	assert_eq(db.item_name("moonrock"), "moonrock")


func test_removing_is_all_or_nothing() -> void:
	bag.add("stone", 5)
	assert_false(bag.remove("stone", 6), "a craft must not be able to half-consume its cost")
	assert_eq(bag.count("stone"), 5, "a refused removal must change nothing")
	assert_true(bag.remove("stone", 5))
	assert_eq(bag.count("stone"), 0)
	assert_eq(bag.used_slots(), 0, "an emptied stack must free its slot")


func test_removing_drains_the_smallest_stacks_first() -> void:
	var cap: int = db.stack_size("wood")
	bag.add("wood", cap)
	bag.add("wood", 3)
	assert_eq(bag.used_slots(), 2)
	bag.remove("wood", 3)
	assert_eq(bag.used_slots(), 1, "the satchel should consolidate, not scatter singles")
	assert_eq(bag.count("wood"), cap)


func test_room_is_measured_before_a_pickup() -> void:
	var cap: int = db.stack_size("berries")
	assert_true(bag.has_room_for("berries", cap * 24))
	assert_false(bag.has_room_for("berries", cap * 24 + 1))
	bag.add("berries", 1)
	assert_true(bag.has_room_for("berries", cap - 1))


func test_moving_onto_an_empty_slot_relocates_the_stack() -> void:
	bag.add("wood", 8)
	bag.move_slot(0, 11)
	assert_true(bag.is_slot_empty(0))
	assert_eq(int(bag.stack_at(11).get("n", 0)), 8)
	assert_eq(bag.count("wood"), 8, "moving must not create or destroy anything")


func test_moving_onto_the_same_item_merges_up_to_the_cap() -> void:
	var cap: int = db.stack_size("wood")
	# A satchel can only hold two partial stacks of one item as [full, spare],
	# because `add` consolidates. So the merge is tested from that layout: the
	# full stack is dropped onto the spare, filling it and leaving the rest.
	bag.add("wood", cap + 3)
	bag.move_slot(0, 1)
	assert_eq(int(bag.stack_at(1).get("n", 0)), cap, "the target should fill to its cap")
	assert_eq(int(bag.stack_at(0).get("n", 0)), 3, "the overflow stays where it was")
	assert_eq(bag.count("wood"), cap + 3, "a merge must not create or destroy anything")


func test_moving_onto_a_different_item_swaps() -> void:
	bag.add("wood", 8)
	bag.add("stone", 3)
	bag.move_slot(0, 1)
	assert_eq(str(bag.stack_at(0).get("id", "")), "stone")
	assert_eq(str(bag.stack_at(1).get("id", "")), "wood")


func test_a_merge_that_overflows_leaves_the_remainder_behind() -> void:
	var cap: int = db.stack_size("wood")
	bag.add("wood", cap)
	bag.move_slot(0, 9)
	bag.add("wood", 6)
	# Slot 0 now holds 6, slot 9 holds a full stack. Merging 0 into 9 has room
	# for nothing, so nothing may move and nothing may be lost.
	bag.move_slot(0, 9)
	assert_eq(int(bag.stack_at(0).get("n", 0)), 6)
	assert_eq(int(bag.stack_at(9).get("n", 0)), cap)
	assert_eq(bag.count("wood"), cap + 6)


func test_moving_an_empty_slot_does_nothing() -> void:
	bag.add("wood", 4)
	bag.move_slot(3, 0)
	assert_eq(int(bag.stack_at(0).get("n", 0)), 4, "an empty source must not clear the target")


func test_out_of_range_moves_are_ignored() -> void:
	bag.add("wood", 4)
	bag.move_slot(0, 99)
	bag.move_slot(-1, 0)
	assert_eq(bag.count("wood"), 4)


func test_draining_hands_everything_back() -> void:
	# This is what a death satchel is made from. CLAUDE.md: multiple death
	# satchels persist, so nothing may be destroyed on the way out.
	bag.add("wood", 12)
	bag.add("berries", 4)
	var dropped: Array = bag.drain()
	assert_eq(dropped.size(), 2)
	assert_eq(bag.used_slots(), 0)
	var total := 0
	for stack in dropped:
		total += int((stack as Dictionary).get("n", 0))
	assert_eq(total, 16)


func test_reading_a_slot_cannot_edit_the_satchel() -> void:
	bag.add("wood", 5)
	var stack: Dictionary = bag.stack_at(0)
	stack["n"] = 500
	assert_eq(bag.count("wood"), 5, "stack_at must hand out a copy, not the live dictionary")


func test_the_revision_counter_moves_only_on_real_changes() -> void:
	var before: int = bag.revision
	bag.add("wood", 0)
	bag.remove("wood", 1)
	assert_eq(bag.revision, before, "a no-op must not make the menu rebuild")
	bag.add("wood", 1)
	assert_true(bag.revision > before)


func test_set_slot_writes_a_slot_directly_at_the_given_position() -> void:
	# R3.1: save/load rehydrates the satchel through set_slot() so slot
	# POSITION survives a reload, not just slot contents — this is the one
	# thing that makes set_slot() different from add().
	bag.set_slot(10, {"id": "wood", "n": 7})
	assert_eq(bag.stack_at(10), {"id": "wood", "n": 7})
	assert_eq(bag.count("wood"), 7)
	assert_true(bag.is_slot_empty(0))


func test_set_slot_to_null_empties_the_slot() -> void:
	bag.add("wood", 5)
	var occupied: int = bag.find_slot("wood")
	bag.set_slot(occupied, null)
	assert_true(bag.is_slot_empty(occupied))
	assert_eq(bag.count("wood"), 0)


func test_set_slot_out_of_range_is_a_no_op() -> void:
	var before: int = bag.revision
	bag.set_slot(-1, {"id": "wood", "n": 1})
	bag.set_slot(INVENTORY.SLOT_COUNT, {"id": "wood", "n": 1})
	assert_eq(bag.revision, before)
	assert_eq(bag.count("wood"), 0)


func test_split_moves_half_into_an_empty_slot() -> void:
	bag.add("wood", 10)
	assert_true(bag.split_slot(0, 5, 4))
	assert_eq(int(bag.stack_at(0).get("n", 0)), 6)
	assert_eq(int(bag.stack_at(5).get("n", 0)), 4)
	assert_eq(bag.count("wood"), 10, "a split must not create or destroy anything")


func test_split_tops_up_a_matching_stack() -> void:
	bag.add("wood", 10)
	# set_slot writes a second real stack directly, bypassing add()'s own
	# consolidation, so there is something distinct at slot 6 to top up.
	bag.set_slot(6, {"id": "wood", "n": 3})
	assert_true(bag.split_slot(0, 6, 4))
	assert_eq(int(bag.stack_at(0).get("n", 0)), 6)
	assert_eq(int(bag.stack_at(6).get("n", 0)), 7)


func test_split_refuses_a_different_item_in_the_target() -> void:
	bag.add("wood", 10)
	bag.add("stone", 3)
	var target: int = bag.find_slot("stone")
	assert_false(bag.split_slot(bag.find_slot("wood"), target, 4))
	assert_eq(bag.count("wood"), 10, "a refused split must change nothing")
	assert_eq(bag.count("stone"), 3)


func test_split_refuses_the_whole_stack_or_nothing() -> void:
	bag.add("wood", 10)
	assert_false(bag.split_slot(0, 1, 10), "moving everything is move_slot's job, not split's")
	assert_false(bag.split_slot(0, 1, 0))
	assert_false(bag.split_slot(0, 1, -3))
	assert_eq(bag.count("wood"), 10)


func test_split_refuses_an_item_that_does_not_stack() -> void:
	bag.add("axe", 1)
	assert_false(bag.split_slot(bag.find_slot("axe"), 5, 1), "a tool has no half")


func test_split_refuses_when_the_target_has_no_room() -> void:
	var cap: int = db.stack_size("wood")
	bag.add("wood", cap)
	bag.set_slot(6, {"id": "wood", "n": cap - 1})
	assert_false(bag.split_slot(0, 6, 4), "only 1 room but asked to move 4")
	assert_eq(int(bag.stack_at(0).get("n", 0)), cap)
	assert_eq(int(bag.stack_at(6).get("n", 0)), cap - 1)


func test_split_out_of_range_or_same_slot_is_a_no_op() -> void:
	bag.add("wood", 10)
	assert_false(bag.split_slot(0, 0, 4))
	assert_false(bag.split_slot(0, 99, 4))
	assert_false(bag.split_slot(-1, 5, 4))
	assert_eq(bag.count("wood"), 10)


func test_drop_slot_empties_the_slot_and_hands_back_the_stack() -> void:
	bag.add("berries", 6)
	var slot: int = bag.find_slot("berries")
	var dropped: Dictionary = bag.drop_slot(slot)
	assert_eq(str(dropped.get("id", "")), "berries")
	assert_eq(int(dropped.get("n", 0)), 6)
	assert_true(bag.is_slot_empty(slot))
	assert_eq(bag.count("berries"), 0, "a dropped stack is gone, not merely moved")


func test_drop_slot_on_an_empty_slot_is_a_no_op() -> void:
	var before: int = bag.revision
	assert_eq(bag.drop_slot(3), {})
	assert_eq(bag.revision, before)


func test_drop_slot_out_of_range_is_a_no_op() -> void:
	assert_eq(bag.drop_slot(-1), {})
	assert_eq(bag.drop_slot(INVENTORY.SLOT_COUNT), {})


func test_there_is_no_carry_weight_anywhere() -> void:
	# CLAUDE.md hard rule: slot/stack inventory, no carry-weight system. A
	# `weight` or `mass` key appearing in items.json is how that rule would get
	# broken quietly, so the data is checked rather than the code.
	for id in db.ids():
		var definition: Dictionary = db.definition(str(id))
		assert_false(definition.has("weight"), "%s declares a weight" % id)
		assert_false(definition.has("mass"), "%s declares a mass" % id)
