extends "res://tests/test_case.gd"

## A world yield never drops into a full satchel (coordinator 2026-10-12): the
## host trial-fills the actor's satchel with every item_grant of the delta
## BEFORE anything applies. No room for the full yield (all-or-nothing, so a
## partial fit refuses too) → refused "Satchel full", nothing consumed, the find
## stays in the world. Room → the ordinary gather, once.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const PEER := 1

var world: RefCounted
var ledger: RefCounted


func before_each() -> void:
	world = WORLD_STATE.new()
	world.world_id = "room-world"
	ledger = WORLD_LEDGER.new(world)


func _slots(free: int) -> Array:
	var bag := BAG.inventory_from([])
	var filler := ["wood", "stone", "fiber", "berries", "rootstone", "ironwood", "potion_small", "revive",
		"good_candy", "great_candy", "rare_candy", "potion_large", "stamina_mushroom", "speed_mushroom",
		"cliffglass_ore", "skyplume", "gale_fiber", "cloudberry", "sparkfur", "windworn_heartwood",
		"rootiron_ingot", "attuned_ground", "attuned_water", "attuned_air"]
	for i in filler.size() - free:
		bag.call("add", filler[i], 1)
	return BAG.slots(bag)


func _pickup(slots: Variant, count: int = 1) -> Dictionary:
	var intent := {"kind": "claim_pickup", "realm": "meadows", "flag": "cache:elder_hollow",
		"item": "elixir_guard", "count": count}
	if slots != null: intent["_satchel_slots"] = slots
	return ledger.call("commit", intent, PEER)


func test_a_full_satchel_leaves_the_pickup_in_the_world_and_loses_nothing() -> void:
	var refused := _pickup(_slots(0))
	assert_false(refused.get("ok"), "refused")
	assert_eq(str(refused.get("code")), "no_room")
	assert_true(str(refused.get("reason")).contains("Satchel full"))
	assert_false(world.flags.call("has", "cache:elder_hollow"), "the find is not consumed")
	assert_true((refused.get("delta") as Dictionary).get("ops", []).is_empty(), "nothing granted or taken")
	var taken := _pickup(_slots(1))
	assert_true(taken.get("ok"), "after making room: the ordinary gather")
	assert_eq(WORLD_LEDGER.player_ops_for(taken.get("delta"), PEER).size(), 1, "granted once")
	assert_false(_pickup(_slots(1)).get("ok"), "and never twice")


func test_a_partial_fit_refuses_whole() -> void:
	# elixir_guard stacks; one free slot holds a full stack, so ask for more
	# than one stack can take to force a partial fit.
	var cap := int(BAG.db().call("max_stack", "elixir_guard")) if BAG.db().has_method("max_stack") else 99
	var refused := _pickup(_slots(1), cap + 1)
	assert_false(refused.get("ok"), "all-or-nothing: a partial fit is refused (cap %d)" % cap)
	assert_false(world.flags.call("has", "cache:elder_hollow"))


func test_without_slot_information_the_old_rules_apply() -> void:
	assert_true(_pickup(null).get("ok"), "callers that send no satchel are unchanged")
