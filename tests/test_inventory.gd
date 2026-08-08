extends "res://tests/test_case.gd"

## The inventory: slots, stacks, tools, and the one thing it must never grow.
##
## Two rules here are not tuning and never will be: there is NO weight limit
## (GAME_DESIGN.md §19, and CLAUDE.md as a hard rule), and a refusal must leave
## the inventory exactly as it was. Everything else — how many slots, how big a
## stack, how long an axe lasts — is deliberately tested for SHAPE rather than
## for value, so retuning items.json does not turn the suite red.

const DEFS := preload("res://scripts/items/item_defs.gd")
const STACK := preload("res://scripts/items/item_stack.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")

## The M8 starting set. Named here rather than read from the file, so DELETING an
## item from items.json fails a test instead of quietly shrinking the game.
const M8_ITEMS := [
	"wood", "stone", "fiber", "berries",
	"axe", "pickaxe", "hammer", "knife", "fishing_rod",
	"tether_orb",
	# M6's revival item. GAME_DESIGN.md §16's first route back from a faint is
	# "a special revival item", and it is an item rather than a special case for
	# the same reason the orb is one. Listed here rather than exempted, so the
	# assertion below still means "nothing has crept in that no milestone asked
	# for" — this one was asked for by name.
	"revival_draught",
	# M12's saddle. GAME_DESIGN.md §17: "Ride/swim/fly require crafted
	# saddle/harness-type equipment", and it is ONE entry because the same
	# section says the riding saddle is generic across every compatible pal.
	# Listed by name for the reason the draught is: this assertion means
	# "nothing has crept in that no milestone asked for", and a saddle per
	# species would show up here as four names nobody could point at a bullet.
	"riding_saddle",
]

## A stackable material and a tool, picked once so the tests below read as
## statements about inventories rather than about wood.
const A_MATERIAL := "wood"
const A_TOOL := "axe"


func _inventory(slots: int = -1) -> RefCounted:
	return INVENTORY.new(slots)


# --- the table ------------------------------------------------------------

func test_every_item_loads_with_everything_the_loader_promises() -> void:
	# A missing display name or a stack limit of zero is invisible until a slot
	# refuses to hold the thing that is in it.
	assert_false(DEFS.table().is_empty(), "items.json loaded nothing at all")
	for id: Variant in DEFS.ids():
		var item_id := str(id)
		assert_false(DEFS.display_name(item_id).is_empty(), "%s has no display name" % item_id)
		assert_true(DEFS.CATEGORIES.has(DEFS.category(item_id)),
			"%s is category '%s', which nothing can sort" % [item_id, DEFS.category(item_id)])
		assert_true(DEFS.stack_limit(item_id) >= 1, "%s cannot be held one at a time" % item_id)
		assert_true(DEFS.max_durability(item_id) >= 0, "%s has negative durability" % item_id)


func test_the_starting_set_is_the_one_m8_names() -> void:
	# M8: Wood, Stone, Fiber, Berries; Axe, Pickaxe, Hammer, Knife, Fishing Rod.
	# Plus the orb, which the game already hands out. Nothing beyond it.
	for id: Variant in M8_ITEMS:
		assert_true(DEFS.has(str(id)), "items.json is missing '%s'" % id)
	assert_eq(DEFS.ids().size(), M8_ITEMS.size(),
		"items.json holds something M8 does not name: %s" % ", ".join(DEFS.ids()))


func test_every_tool_has_durability_and_nothing_else_does() -> void:
	# §19: tools have durability and repair for free. A tool with none would be
	# indestructible without anything in a diff to say so.
	for id: Variant in DEFS.ids():
		var item_id := str(id)
		if DEFS.is_tool_item(item_id):
			assert_true(DEFS.max_durability(item_id) > 0, "tool '%s' never wears out" % item_id)
		else:
			assert_eq(DEFS.max_durability(item_id), 0,
				"'%s' is not a tool but has durability" % item_id)


func test_an_unknown_item_gets_a_placeholder_rather_than_a_crash() -> void:
	# Same behaviour as pal_species.placeholder(): a stale id from a save or a
	# recipe describes as SOMETHING usable instead of returning an empty
	# Dictionary that the next line divides by.
	var missing := "deleted_in_a_later_build"
	assert_false(DEFS.has(missing))
	assert_true(DEFS.definition(missing).is_empty(), "an unknown id claimed to have a definition")
	var placeholder: Dictionary = DEFS.placeholder(missing)
	for key: String in ["display_name", "category", "stack_limit", "max_durability"]:
		assert_true(placeholder.has(key), "the placeholder is missing '%s'" % key)
	assert_eq(DEFS.display_name(missing), missing)
	assert_eq(DEFS.stack_limit(missing), 1, "an unknown item could not be held at all")
	assert_false(DEFS.is_durable(missing))


func test_an_unknown_item_can_be_described_but_not_acquired() -> void:
	# The placeholder exists so a stale id can be DRAWN, not so it can be picked
	# up. An item that is not in items.json is a typo, not a discovery.
	var inventory := _inventory()
	assert_false(inventory.add("moon_rock", 1), "the inventory accepted an item that does not exist")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_UNKNOWN_ITEM)
	assert_true(inventory.is_empty())


func test_a_tool_never_stacks_however_the_data_reads() -> void:
	# The decision, enforced in one place: anything with durability has a stack
	# limit of 1, so a stack can never hold two axes with one durability between
	# them. If this ever fails, every split and repair needs a which-one argument.
	for id: Variant in DEFS.ids():
		if DEFS.is_durable(str(id)):
			assert_eq(DEFS.stack_limit(str(id)), 1, "'%s' is durable and stacks" % id)


# --- slots and stacks -----------------------------------------------------

func test_the_slot_count_comes_from_data() -> void:
	# It is a tunable, not a magic number: "I keep running out of room" has to be
	# answerable by editing items.json.
	assert_true(DEFS.slot_count() > 0)
	assert_eq(_inventory().slot_count(), DEFS.slot_count())


func test_adding_the_same_item_fills_a_partial_stack_before_taking_a_slot() -> void:
	# Without this, picking up wood ten times gives ten slots of wood and the bag
	# is full after one clearing.
	var inventory := _inventory()
	for i in 10:
		assert_true(inventory.add(A_MATERIAL, 1))
	assert_eq(inventory.used_slots(), 1, "ten pickups took %d slots" % inventory.used_slots())
	assert_eq(inventory.count_of(A_MATERIAL), 10)


func test_a_stack_overflows_into_the_next_slot_at_its_limit() -> void:
	var limit: int = DEFS.stack_limit(A_MATERIAL)
	var inventory := _inventory()
	assert_true(inventory.add(A_MATERIAL, limit + 1))
	assert_eq(inventory.used_slots(), 2, "a stack grew past its own limit")
	assert_eq(int(inventory.at(0).count), limit)
	assert_eq(int(inventory.at(1).count), 1)
	assert_eq(inventory.count_of(A_MATERIAL), limit + 1)


func test_count_of_sees_every_slot() -> void:
	var inventory := _inventory()
	inventory.add(A_MATERIAL, DEFS.stack_limit(A_MATERIAL) * 2 + 3)
	assert_eq(inventory.count_of(A_MATERIAL), DEFS.stack_limit(A_MATERIAL) * 2 + 3)
	assert_eq(inventory.count_of("stone"), 0, "the inventory found something it does not hold")


func test_tools_take_one_slot_each() -> void:
	var inventory := _inventory()
	assert_true(inventory.add(A_TOOL, 3))
	assert_eq(inventory.used_slots(), 3, "three axes shared a slot")


# --- splitting and merging ------------------------------------------------

func test_splitting_a_stack_preserves_the_total() -> void:
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 20)
	assert_true(inventory.split_slot(0, 8))
	assert_eq(int(inventory.at(0).count), 12)
	assert_eq(int(inventory.at(1).count), 8)
	assert_eq(inventory.count_of(A_MATERIAL), 20, "splitting created or destroyed items")


func test_splitting_off_everything_or_nothing_is_refused() -> void:
	# Both are a stick slipping on a controller. One leaves an empty stack in a
	# slot, the other teleports the pile sideways; both read as a bug.
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 20)
	assert_false(inventory.split_slot(0, 0), "splitting off nothing was allowed")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_BAD_AMOUNT)
	assert_false(inventory.split_slot(0, 20), "splitting off the whole stack was allowed")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_BAD_AMOUNT)
	assert_false(inventory.split_slot(0, -3), "a negative split was allowed")
	assert_eq(inventory.used_slots(), 1, "a refused split moved something anyway")
	assert_eq(inventory.count_of(A_MATERIAL), 20)


func test_merging_two_slots_leaves_the_remainder_where_it_was() -> void:
	# Dropping 40 wood onto a stack that can take 9 leaves 31 in the hand, not 31
	# nowhere.
	var limit: int = DEFS.stack_limit(A_MATERIAL)
	var inventory := _inventory()
	inventory.add(A_MATERIAL, limit + 10)
	inventory.remove_at(0, 5)
	var total: int = inventory.count_of(A_MATERIAL)
	assert_true(inventory.merge_slots(1, 0))
	assert_eq(int(inventory.at(0).count), limit, "the merge did not fill the target stack")
	assert_eq(int(inventory.at(1).count), 5, "the remainder was destroyed rather than left behind")
	assert_eq(inventory.count_of(A_MATERIAL), total, "merging changed how much was held")


func test_two_tools_refuse_to_merge() -> void:
	# There is no honest answer to which durability the merged axe would carry.
	var inventory := _inventory()
	inventory.add(A_TOOL, 2)
	inventory.use_tool(0, 5)
	assert_false(inventory.merge_slots(1, 0))
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_NOT_STACKABLE)
	assert_eq(inventory.used_slots(), 2)


func test_moving_onto_an_occupied_slot_swaps_rather_than_refusing() -> void:
	# Refusing would make reordering a full inventory impossible without an empty
	# slot to shuffle through, which is exactly when reordering matters.
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 5)
	inventory.add("stone", 5)
	assert_true(inventory.move(0, 1))
	assert_eq(str(inventory.at(0).item_id), "stone")
	assert_eq(str(inventory.at(1).item_id), A_MATERIAL)


# --- refusing cleanly -----------------------------------------------------

func test_a_full_inventory_refuses_an_add_and_is_unchanged_afterwards() -> void:
	# A refusal that half-applies is worse than one that fails: "you picked up 12
	# of 30 stone and the rest is gone" is a bug nobody can reproduce.
	var inventory := _inventory(3)
	for i in 3:
		assert_true(inventory.add(A_TOOL, 1))
	assert_true(inventory.is_full())
	var before: Array = inventory.to_records()

	assert_false(inventory.add("stone", 1), "a full inventory accepted another item")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_INVENTORY_FULL)
	assert_eq(inventory.to_records(), before, "a refused add changed the inventory anyway")


func test_an_add_that_only_partly_fits_adds_nothing() -> void:
	var limit: int = DEFS.stack_limit(A_MATERIAL)
	var inventory := _inventory(1)
	assert_true(inventory.add(A_MATERIAL, limit))
	assert_false(inventory.add(A_MATERIAL, 5), "an overflowing add was partly applied")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_INVENTORY_FULL)
	assert_eq(inventory.count_of(A_MATERIAL), limit, "a refused add still added some")


func test_a_full_inventory_still_takes_more_of_something_it_already_holds() -> void:
	# Full means every slot is occupied, not that nothing more can be held. A
	# half stack of wood in the last slot still has room for wood.
	var inventory := _inventory(2)
	inventory.add(A_TOOL, 1)
	inventory.add(A_MATERIAL, 1)
	assert_true(inventory.is_full())
	assert_true(inventory.add(A_MATERIAL, 5), "a partial stack refused more of its own item")
	assert_eq(inventory.count_of(A_MATERIAL), 6)


func test_a_successful_add_clears_the_previous_refusal() -> void:
	# A stale reason makes a UI open the "bag full" toast on the next pickup,
	# forever.
	var inventory := _inventory()
	assert_false(inventory.add("moon_rock", 1))
	assert_true(inventory.add(A_MATERIAL, 1))
	assert_true(inventory.last_refusal().is_empty())


func test_spending_more_than_is_held_spends_nothing() -> void:
	# A build cost that takes half its wood and then fails has charged the player
	# for nothing.
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 10)
	assert_false(inventory.remove(A_MATERIAL, 11))
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_NOT_ENOUGH)
	assert_eq(inventory.count_of(A_MATERIAL), 10, "a refused spend took some anyway")
	assert_true(inventory.remove(A_MATERIAL, 10))
	assert_eq(inventory.count_of(A_MATERIAL), 0)
	assert_true(inventory.is_empty(), "an emptied stack kept its slot")


func test_a_bad_slot_index_is_refused_rather_than_clamped() -> void:
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 4)
	assert_false(inventory.remove_at(99, 1))
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_NO_SUCH_SLOT)
	assert_false(inventory.remove_at(-1, 1))
	assert_eq(inventory.count_of(A_MATERIAL), 4)


func test_the_slots_cannot_be_rearranged_from_outside() -> void:
	# slots() must hand back a copy, for the reason party.members() does: GDScript
	# passes an Array by reference, so returning the live one would let any caller
	# drop a stack into a slot without going near add().
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 1)
	var copy: Array = inventory.slots()
	copy[5] = STACK.create("stone", 99)
	assert_eq(inventory.count_of("stone"), 0, "writing to slots() changed the inventory itself")


# --- tools ----------------------------------------------------------------

func test_using_a_tool_wears_it_down() -> void:
	var inventory := _inventory()
	inventory.add(A_TOOL, 1)
	var tool_stack: RefCounted = inventory.at(0)
	var full: int = tool_stack.max_durability()
	assert_eq(int(tool_stack.durability), full, "a fresh tool did not start at full durability")
	assert_true(inventory.use_tool(0))
	assert_true(int(tool_stack.durability) < full, "using the tool cost nothing")


func test_a_broken_tool_keeps_its_slot_and_refuses_to_be_used() -> void:
	# The decision: a tool at zero durability is BROKEN, not DESTROYED. §19 says
	# repair is free, and a tool that deleted itself would put that repair out of
	# reach — and losing the axe is pure punishment in a game with no carry cost
	# for keeping it.
	var inventory := _inventory()
	inventory.add(A_TOOL, 1)
	var tool_stack: RefCounted = inventory.at(0)
	inventory.use_tool(0, tool_stack.max_durability() * 2)
	assert_eq(int(tool_stack.durability), 0, "durability went past zero")
	assert_true(tool_stack.is_broken())
	assert_eq(inventory.count_of(A_TOOL), 1, "the broken tool vanished from the inventory")
	assert_false(inventory.use_tool(0), "a broken tool kept working")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_TOOL_BROKEN)


func test_repair_is_free_and_whole() -> void:
	var inventory := _inventory()
	inventory.add(A_TOOL, 1)
	var tool_stack: RefCounted = inventory.at(0)
	inventory.use_tool(0, tool_stack.max_durability())
	assert_true(inventory.repair(0))
	assert_eq(int(tool_stack.durability), tool_stack.max_durability(),
		"repair did not restore the whole tool")
	assert_false(tool_stack.is_broken())
	assert_almost_eq(tool_stack.durability_fraction(), 1.0, 0.0001)


func test_a_material_is_not_a_tool() -> void:
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 4)
	assert_false(inventory.use_tool(0), "wood wore out")
	assert_eq(inventory.last_refusal(), INVENTORY.REFUSED_NOT_DURABLE)
	assert_false(inventory.repair(0))
	assert_eq(inventory.count_of(A_MATERIAL), 4)


# --- no weight, ever ------------------------------------------------------

func test_there_is_no_weight_limit() -> void:
	# GAME_DESIGN.md §19 and CLAUDE.md, as a hard rule. Fill every slot with the
	# heaviest-sounding thing in the game and assert that not one add is refused.
	var inventory := _inventory()
	var limit: int = DEFS.stack_limit("stone")
	for i in inventory.slot_count():
		assert_true(inventory.add("stone", limit),
			"add %d of %d was refused ('%s') — something is counting weight"
				% [i + 1, inventory.slot_count(), inventory.last_refusal()])
	assert_eq(inventory.count_of("stone"), limit * inventory.slot_count())
	assert_true(inventory.last_refusal().is_empty())


func test_no_refusal_token_is_about_weight() -> void:
	# A field that exists gets used, and the first use anyone finds for a weight
	# is refusing a pickup. This is the tripwire: a token about mass, bulk or
	# encumbrance is a carry-weight system arriving under another name.
	for token: Variant in INVENTORY.REFUSALS:
		for banned: String in ["weight", "heavy", "mass", "bulk", "encumb", "overload"]:
			assert_false(str(token).contains(banned),
				"refusal token '%s' is about carry weight" % token)


func test_no_item_declares_a_weight() -> void:
	for id: Variant in DEFS.ids():
		var definition: Dictionary = DEFS.definition(str(id))
		for banned: String in ["weight", "mass", "bulk", "encumbrance"]:
			assert_false(definition.has(banned), "'%s' declares a %s" % [id, banned])


# --- persistence ----------------------------------------------------------

func test_records_round_trip_slots_counts_and_durability() -> void:
	# The worn axe has to come back worn, and in the slot the player put it in:
	# §19 asks for quick tool selection, and a reload that tidies everything
	# leftwards moves the tool out from under the button they had learned.
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 137)
	inventory.add(A_TOOL, 1)
	inventory.add("berries", 4)
	inventory.move(3, 11)
	inventory.use_tool(2, 17)

	var restored: RefCounted = INVENTORY.from_records(inventory.to_records())
	assert_eq(restored.slot_count(), inventory.slot_count())
	assert_eq(restored.count_of(A_MATERIAL), 137)
	assert_eq(restored.count_of("berries"), 4)
	assert_eq(restored.count_of(A_TOOL), 1)
	for i in inventory.slot_count():
		var before: RefCounted = inventory.at(i)
		var after: RefCounted = restored.at(i)
		if before == null:
			assert_eq(after, null, "slot %d gained something across a save" % i)
			continue
		assert_ne(after, null, "slot %d lost its stack across a save" % i)
		assert_eq(str(after.item_id), str(before.item_id), "slot %d holds a different item" % i)
		assert_eq(int(after.count), int(before.count), "slot %d holds a different amount" % i)
		assert_eq(int(after.durability), int(before.durability), "slot %d lost its wear" % i)


func test_a_record_stores_progress_and_not_derived_facts() -> void:
	# Writing the stack limit or the display name would freeze an item at the
	# balance of the build that dropped it and skip every later rebalance.
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 3)
	var record: Dictionary = (inventory.to_records()[0] as Dictionary)
	assert_true(record.has("item"))
	assert_true(record.has("count"))
	assert_true(record.has("slot"))
	assert_false(record.has("stack_limit"), "a derived value was written into the save")
	assert_false(record.has("display_name"), "a derived value was written into the save")
	assert_false(record.has("durability"), "a material carries a durability it does not have")


func test_a_save_naming_an_item_that_no_longer_exists_loses_one_stack() -> void:
	# Save files are text files on a Windows machine. This will happen.
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 5)
	inventory.add("stone", 5)
	var records: Array = inventory.to_records()
	(records[0] as Dictionary)["item"] = "deleted_in_a_later_build"
	var restored: RefCounted = INVENTORY.from_records(records)
	assert_eq(restored.count_of("stone"), 5, "one bad record cost the whole save")
	assert_eq(restored.count_of(A_MATERIAL), 0)


func test_a_save_claiming_an_impossible_slot_keeps_the_item() -> void:
	# Losing the arrangement is recoverable; losing the worn axe an hour into an
	# evening is not. A record with a slot past the end falls through to the first
	# free slot rather than being dropped.
	var inventory := _inventory(4)
	inventory.add(A_TOOL, 1)
	inventory.use_tool(0, 9)
	var records: Array = inventory.to_records()
	(records[0] as Dictionary)["slot"] = 999
	var restored: RefCounted = INVENTORY.from_records(records, 4)
	assert_eq(restored.count_of(A_TOOL), 1, "an out-of-range slot cost the tool")
	assert_eq(int(restored.at(0).durability), DEFS.max_durability(A_TOOL) - 9,
		"the rescued tool came back unworn")


func test_a_save_with_two_records_on_one_slot_keeps_both_items() -> void:
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 5)
	inventory.add("stone", 5)
	var records: Array = inventory.to_records()
	(records[1] as Dictionary)["slot"] = 0
	var restored: RefCounted = INVENTORY.from_records(records)
	assert_eq(restored.count_of(A_MATERIAL), 5)
	assert_eq(restored.count_of("stone"), 5, "the colliding record was thrown away")


func test_a_save_with_more_stacks_than_slots_loses_the_surplus_and_not_the_save() -> void:
	var big := _inventory(6)
	for i in 6:
		big.add(A_TOOL, 1)
	var restored: RefCounted = INVENTORY.from_records(big.to_records(), 3)
	assert_eq(restored.slot_count(), 3, "a shrunken inventory grew to fit its save")
	assert_eq(restored.count_of(A_TOOL), 3)


func test_a_save_claiming_a_stack_above_its_limit_is_clamped() -> void:
	var inventory := _inventory()
	inventory.add(A_MATERIAL, 5)
	var records: Array = inventory.to_records()
	(records[0] as Dictionary)["count"] = 100000
	var restored: RefCounted = INVENTORY.from_records(records)
	assert_eq(restored.count_of(A_MATERIAL), DEFS.stack_limit(A_MATERIAL),
		"a hand-edited count produced a stack past its own limit")


func test_a_save_claiming_a_tool_above_full_durability_is_clamped() -> void:
	var inventory := _inventory()
	inventory.add(A_TOOL, 1)
	var records: Array = inventory.to_records()
	(records[0] as Dictionary)["durability"] = 999999
	var restored: RefCounted = INVENTORY.from_records(records)
	assert_eq(int(restored.at(0).durability), DEFS.max_durability(A_TOOL),
		"a tool came back tougher than its own definition")
