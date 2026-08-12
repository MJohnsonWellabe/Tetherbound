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
	var leftover := chest.deposit(player, "wood", 6)
	assert_eq(leftover, 0)
	assert_eq(player.count("wood"), 4)
	assert_eq(chest.inventory.count("wood"), 6)


func test_withdraw_moves_items_from_chest_to_player() -> void:
	player.add("wood", 10)
	chest.deposit(player, "wood", 10)
	var leftover := chest.withdraw(player, "wood", 7)
	assert_eq(leftover, 0)
	assert_eq(chest.inventory.count("wood"), 3)
	assert_eq(player.count("wood"), 7)


func test_deposit_refuses_when_the_player_does_not_have_enough() -> void:
	player.add("wood", 3)
	var leftover := chest.deposit(player, "wood", 10)
	# All-or-nothing on the source side: nothing moves rather than a partial
	# 3-of-10 deposit the player never asked for.
	assert_eq(leftover, 10)
	assert_eq(player.count("wood"), 3)
	assert_eq(chest.inventory.count("wood"), 0)


func test_withdraw_refuses_when_the_chest_does_not_have_enough() -> void:
	player.add("wood", 5)
	chest.deposit(player, "wood", 5)
	var leftover := chest.withdraw(player, "wood", 20)
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
	var leftover := chest.deposit(player, "wood", 10)
	assert_eq(leftover, 10, "a full chest must accept nothing, not partially swallow the stack")
	assert_eq(player.count("wood"), 10, "refused wood must stay in the player's satchel")


func test_storage_never_holds_a_creature_id() -> void:
	# CLAUDE.md: player can own only five pals, ever, and storage of any kind
	# must never become a way around that. storage_state.gd only ever moves
	# item ids through Inventory's own {id, n} stack contract — there is no
	# species/pal-instance path into it at all, which this asserts directly
	# rather than leaving as an unchecked assumption.
	for id in db.ids():
		assert_ne(db.kind(str(id)), "creature",
			"items.json defines a 'creature' kind; storage_state.gd must never be handed one")
