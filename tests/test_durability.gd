extends "res://tests/test_case.gd"

## R2.2: tool durability and free repair.
##
## GAME_DESIGN.md 19: tools "have durability", "repair for free at appropriate
## station". Pure logic against the real data/items/items.json, same reasoning
## test_inventory.gd gives: a durability value deleted from the data file
## should fail here, not in the menu.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")

var db: RefCounted = null
var bag: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)


func test_the_five_tools_all_have_durability() -> void:
	for id in ["axe", "pickaxe", "hammer", "knife", "fishing_rod"]:
		assert_true(db.max_durability(id) > 0, "%s must have a durability" % id)


func test_resources_and_consumables_have_no_durability() -> void:
	for id in ["wood", "stone", "fiber", "berries", "potion_small", "orb_basic"]:
		assert_eq(db.max_durability(id), 0, "%s must not carry a durability" % id)


func test_a_freshly_added_tool_reads_as_fully_repaired() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	assert_true(slot >= 0, "axe must occupy a slot after add()")
	assert_eq(bag.durability_at(slot), db.max_durability("axe"),
		"a slot with no durability key of its own must read as full")


func test_find_slot_returns_minus_one_for_something_not_owned() -> void:
	assert_eq(bag.find_slot("axe"), -1)


func test_damage_tool_reduces_durability_by_the_given_amount() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	var maximum: int = db.max_durability("axe")
	bag.damage_tool(slot)
	assert_eq(bag.durability_at(slot), maximum - 1)
	bag.damage_tool(slot, 3)
	assert_eq(bag.durability_at(slot), maximum - 4)


func test_damage_tool_floors_at_zero_rather_than_going_negative() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	bag.damage_tool(slot, db.max_durability("axe") + 50)
	assert_eq(bag.durability_at(slot), 0, "a broken tool must read 0, never negative")


func test_a_broken_tool_still_occupies_its_slot() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	bag.damage_tool(slot, db.max_durability("axe") + 50)
	assert_false(bag.is_slot_empty(slot),
		"GAME_DESIGN.md 19: repair, never replace -- a broken tool is not destroyed")


func test_repair_tool_restores_to_max_for_free() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	var maximum: int = db.max_durability("axe")
	bag.damage_tool(slot, maximum - 1)
	assert_eq(bag.durability_at(slot), 1)

	var wood_before: int = bag.count("wood")
	bag.repair_tool(slot)
	assert_eq(bag.durability_at(slot), maximum)
	assert_eq(bag.count("wood"), wood_before,
		"GAME_DESIGN.md 19: free repair, no repair-material economy")


func test_repair_on_an_already_full_tool_is_a_harmless_no_op() -> void:
	bag.add("axe", 1)
	var slot: int = bag.find_slot("axe")
	var revision_before: int = bag.revision
	bag.repair_tool(slot)
	assert_eq(bag.durability_at(slot), db.max_durability("axe"))
	assert_eq(bag.revision, revision_before,
		"repairing an already-full tool must not bump revision or fire a redraw")


func test_damage_and_repair_on_a_non_tool_slot_are_harmless_no_ops() -> void:
	bag.add("wood", 5)
	var slot: int = bag.find_slot("wood")
	bag.damage_tool(slot)
	bag.repair_tool(slot)
	var stack: Dictionary = bag.stack_at(slot)
	assert_eq(int(stack.get("n", 0)), 5, "a resource stack must be untouched by tool-only calls")
	assert_false(stack.has("durability"), "a resource must never gain a stray durability key")


func test_durability_at_on_an_empty_slot_is_zero() -> void:
	assert_eq(bag.durability_at(0), 0)
	assert_eq(bag.max_durability_at(0), 0)
