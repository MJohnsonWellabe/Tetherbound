extends "res://tests/test_case.gd"

## R3.3, GAME_DESIGN.md §22. Two pieces of pure logic, no scene required:
## death_satchel.gd's build() has to rehydrate a drained satchel exactly
## (durability included, nothing re-stacked), and player_death.gd's
## resolve_home() has to pick the right respawn point. The fade/tween/
## teleport wiring itself needs a live scene tree the same way camp.gd's own
## rest does — nothing here pretends to cover that half.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const DEATH_SATCHEL := preload("res://scripts/world/death_satchel.gd")
const PLAYER_DEATH := preload("res://scripts/world/player_death.gd")

var db: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()


func test_build_rehydrates_a_drained_inventory_into_the_satchels_own_state() -> void:
	var bag: RefCounted = INVENTORY.new(db)
	bag.add("wood", 10)
	bag.add("axe", 1)
	var dropped: Array = bag.drain()
	assert_eq(bag.used_slots(), 0, "drain must empty the source satchel")

	var satchel: Node3D = DEATH_SATCHEL.new()
	satchel.build(dropped, db)

	assert_eq(satchel.state.inventory.count("wood"), 10)
	assert_eq(satchel.state.inventory.count("axe"), 1)


func test_build_preserves_tool_durability_exactly_rather_than_re_stacking() -> void:
	var bag: RefCounted = INVENTORY.new(db)
	bag.add("axe", 1)
	bag.damage_tool(bag.find_slot("axe"), 3)
	var before: Dictionary = bag.stack_at(bag.find_slot("axe"))
	var dropped: Array = bag.drain()

	var satchel: Node3D = DEATH_SATCHEL.new()
	satchel.build(dropped, db)

	var slot := -1
	for i in satchel.state.inventory.slot_count():
		if not satchel.state.inventory.is_slot_empty(i):
			slot = i
			break
	assert_true(slot >= 0, "the drained axe must land somewhere in the satchel")
	assert_eq(satchel.state.inventory.stack_at(slot).get("durability"), before.get("durability"),
		"set_slot must carry durability through untouched -- add() would have dropped it")


func test_build_on_an_empty_drop_leaves_an_empty_but_valid_satchel() -> void:
	var satchel: Node3D = DEATH_SATCHEL.new()
	satchel.build([], db)
	assert_eq(satchel.state.inventory.used_slots(), 0)


func test_resolve_home_falls_back_when_no_camp_has_been_placed() -> void:
	var fallback := Vector3(1.0, 2.0, 3.0)
	assert_eq(PLAYER_DEATH.resolve_home([], fallback), fallback)
	assert_eq(PLAYER_DEATH.resolve_home("not an array", fallback), fallback)


func test_resolve_home_uses_the_most_recently_placed_camp() -> void:
	# GAME_DESIGN.md §22 names no second camp case, but nothing stops a
	# player building a second one -- the most recent is the only sane
	# reading of "home" once that happens.
	var fallback := Vector3.ZERO
	var buildings: Array = [
		{"id": "floor", "position": [5.0, 0.0, 5.0]},
		{"id": "camp", "position": [10.0, 0.0, 20.0]},
		{"id": "wall", "position": [1.0, 0.0, 1.0]},
		{"id": "camp", "position": [30.0, 0.0, 40.0]},
	]
	assert_eq(PLAYER_DEATH.resolve_home(buildings, fallback), Vector3(30.0, 0.0, 40.0))


func test_resolve_home_ignores_malformed_entries_and_still_falls_back() -> void:
	var fallback := Vector3(9.0, 9.0, 9.0)
	var buildings: Array = [{"id": "camp", "position": [1.0, 2.0]}, "not a dict"]
	assert_eq(PLAYER_DEATH.resolve_home(buildings, fallback), fallback)
