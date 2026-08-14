extends "res://tests/test_case.gd"

## R2.7. A placed chest's own satchel — scripts/world/storage_state.gd.
##
## Same failure class test_inventory.gd exists for: a deposit that vanishes
## items instead of moving them, a withdraw that duplicates them, a partial
## fit that silently drops the remainder rather than leaving it where the
## player can see it. Pure logic, no scene — the same split test_inventory.gd
## draws for the player's own satchel (docs/decisions/D02).

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const STORAGE_STATE := preload("res://scripts/world/storage_state.gd")

var db: RefCounted = null
var player: RefCounted = null
var chest: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	player = INVENTORY.new(db)
	chest = STORAGE_STATE.new(db)


func test_deposit_moves_items_from_player_to_chest() -> void:
	player.add("wood", 10)
	var leftover: int = chest.deposit(player, "wood", 6)
	assert_eq(leftover, 0)
	assert_eq(player.count("wood"), 4)
	assert_eq(chest.inventory.count("wood"), 6)


func test_withdraw_moves_items_from_chest_to_player() -> void:
	player.add("wood", 10)
	chest.deposit(player, "wood", 10)
	var leftover: int = chest.withdraw(player, "wood", 7)
	assert_eq(leftover, 0)
	assert_eq(chest.inventory.count("wood"), 3)
	assert_eq(player.count("wood"), 7)


func test_deposit_refuses_when_the_player_does_not_have_enough() -> void:
	player.add("wood", 3)
	var leftover: int = chest.deposit(player, "wood", 10)
	# All-or-nothing on the source side: nothing moves rather than a partial
	# 3-of-10 deposit the player never asked for.
	assert_eq(leftover, 10)
	assert_eq(player.count("wood"), 3)
	assert_eq(chest.inventory.count("wood"), 0)


func test_withdraw_refuses_when_the_chest_does_not_have_enough() -> void:
	player.add("wood", 5)
	chest.deposit(player, "wood", 5)
	var leftover: int = chest.withdraw(player, "wood", 20)
	assert_eq(leftover, 20)
	assert_eq(chest.inventory.count("wood"), 5)
	assert_eq(player.count("wood"), 0)


func test_deposit_and_withdraw_are_no_ops_on_zero_or_negative_amounts() -> void:
	player.add("wood", 5)
	assert_eq(chest.deposit(player, "wood", 0), 0)
	assert_eq(chest.deposit(player, "wood", -3), 0)
	assert_eq(player.count("wood"), 5)
	assert_eq(chest.inventory.count("wood"), 0)


func test_the_chest_inventory_is_independent_of_the_player_satchel() -> void:
	# The whole reason storage_state.gd wraps a SECOND Inventory instance
	# rather than sharing the player's: filling the chest must never fill the
	# player's satchel too, and vice versa.
	player.add("stone", 50)
	chest.deposit(player, "stone", 50)
	assert_true(chest.inventory.is_full() or chest.inventory.count("stone") == 50)
	assert_false(player.is_full())
	assert_eq(player.count("stone"), 0)


func test_a_partial_fit_on_deposit_leaves_the_remainder_with_the_player() -> void:
	# Fill the chest to capacity with a second resource first, then try to
	# deposit more wood than the remaining slots can hold, forcing add()'s
	# partial-fit path rather than the simpler full-success case above.
	player.add("stone", 50 * 24)
	chest.deposit(player, "stone", 50 * 24)
	assert_true(chest.inventory.is_full())

	player.add("wood", 10)
	var leftover: int = chest.deposit(player, "wood", 10)
	assert_eq(leftover, 10, "a full chest must accept nothing, not partially swallow the stack")
	assert_eq(player.count("wood"), 10, "refused wood must stay in the player's satchel")


func test_save_data_round_trips_through_load_data() -> void:
	# R3.1-remainder: this is the chest-side half of save/load — a fresh
	# STORAGE_STATE loading another one's save_data() output should end up
	# holding the same stacks in the same slots.
	chest.inventory.set_slot(3, {"id": "wood", "n": 12})
	chest.inventory.set_slot(9, {"id": "stone", "n": 4})

	var restored: RefCounted = STORAGE_STATE.new(db)
	restored.load_data(chest.save_data())

	assert_eq(restored.inventory.stack_at(3), {"id": "wood", "n": 12})
	assert_eq(restored.inventory.stack_at(9), {"id": "stone", "n": 4})
	assert_true(restored.inventory.is_slot_empty(0))


func test_load_data_coerces_stack_counts_back_to_int_after_a_json_round_trip() -> void:
	# save_game.gd embeds save_data()'s output inside the wider save file it
	# JSON.stringify()s, and JSON has no integer type -- every "n" comes back
	# a float. load_data must undo that the same way save_game.gd's own
	# _stack_from_json does for the player's satchel, or a reloaded chest's
	# stacks would silently carry "n": 5.0 instead of 5.
	chest.inventory.set_slot(2, {"id": "wood", "n": 5})
	var round_tripped: Variant = JSON.parse_string(JSON.stringify(chest.save_data()))

	var restored: RefCounted = STORAGE_STATE.new(db)
	restored.load_data(round_tripped)

	var stack: Dictionary = restored.inventory.stack_at(2)
	assert_eq(stack.get("id"), "wood")
	assert_eq(typeof(stack.get("n")), TYPE_INT)
	assert_eq(int(stack.get("n")), 5)


func test_load_data_ignores_a_non_array_payload() -> void:
	chest.inventory.set_slot(0, {"id": "wood", "n": 1})
	chest.load_data("not an array")
	assert_eq(chest.inventory.stack_at(0), {"id": "wood", "n": 1})


func test_storage_never_holds_a_creature_id() -> void:
	# CLAUDE.md: player can own only five creatures, ever, and storage of any kind
	# must never become a way around that. storage_state.gd only ever moves
	# item ids through Inventory's own {id, n} stack contract — there is no
	# species/creature-instance path into it at all, which this asserts directly
	# rather than leaving as an unchecked assumption.
	for id in db.ids():
		assert_ne(db.kind(str(id)), "creature",
			"items.json defines a 'creature' kind; storage_state.gd must never be handed one")
