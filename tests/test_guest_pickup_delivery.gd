extends "res://tests/test_case.gd"

## F31#5 co-op economy gap (coordinator ruling): a guest's one-time world find
## pays through a journaled reward delivery, so the host's character authority
## gains it exactly once (owner_passive_sync replays reward_delivery_applied
## into CharacterAuthority.apply_owner_reward_delivery). The host and solo keep
## the direct item_grant; a player-dropped stack never routes.

const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")

const HOST := WORLD_LEDGER.HOST_PEER
const GUEST := 771_240_190
const GUEST_CHARACTER := "character-0123456789abcdef0123456789abcdef"

var world: RefCounted = null
var ledger: RefCounted = null


func before_each() -> void:
	world = WORLD_STATE.new()
	world.world_id = "slot-0"
	world.reward_delivery_namespace = "0123456789abcdef0123456789abcdef"
	ledger = WORLD_LEDGER.new(world)


func _claim(flag: String, item: String, count: int, character: String) -> Dictionary:
	var intent := {"kind": "claim_pickup", "realm": "meadows", "flag": flag, "item": item, "count": count}
	if not character.is_empty():
		intent["_actor_character_id"] = character
	return intent


func _ops(verdict: Dictionary, peer: int) -> Array:
	return WORLD_LEDGER.player_ops_for(verdict.get("delta", {}), peer)


func test_a_guest_find_is_a_journaled_reward_delivery_not_a_bare_grant() -> void:
	var verdict: Dictionary = ledger.call("commit", _claim("cache:f31_berries", "berries", 4, GUEST_CHARACTER), GUEST)
	assert_true(verdict.get("ok"), "the guest's claim commits: %s" % str(verdict))
	var ops := _ops(verdict, GUEST)
	assert_eq(ops.size(), 1, "the guest receives exactly one player op")
	assert_eq(str(ops[0].get("op")), "reward_delivery", "and it is a reward delivery, which the authority honours")
	var delivery: Dictionary = ops[0].delivery
	assert_eq(str(delivery.character_id), GUEST_CHARACTER, "addressed to the admitted character")
	assert_eq(delivery.stacks, [{"id": "berries", "n": 4}], "carrying exactly the find")
	assert_eq(str(delivery.delivery_id), REWARD_DELIVERY.delivery_id(world.reward_delivery_namespace,
		"claim_pickup:cache:f31_berries", GUEST_CHARACTER), "receipt (namespace, claim_pickup:<flag>, character)")
	assert_true(world.reward_deliveries.has(str(delivery.delivery_id)), "the host journals the pending row in the world")
	assert_true(world.flags.call("has", "cache:f31_berries"), "the world remembers the find is gone")


func test_the_host_and_solo_keep_the_direct_grant() -> void:
	var verdict: Dictionary = ledger.call("commit", _claim("cache:host_find", "berries", 2, "character-host"), HOST)
	assert_true(verdict.get("ok"))
	var ops := _ops(verdict, HOST)
	assert_eq(ops.size(), 1)
	assert_eq(str(ops[0].get("op")), "item_grant", "a host/solo pickup is unchanged")
	assert_true(world.reward_deliveries.is_empty(), "and journals no delivery")


func test_a_dropped_stack_never_routes_through_the_authority() -> void:
	var verdict: Dictionary = ledger.call("commit", _claim("dropped:abc123", "wood", 3, GUEST_CHARACTER), GUEST)
	assert_true(verdict.get("ok"))
	assert_eq(str(_ops(verdict, GUEST)[0].get("op")), "item_grant",
		"a drop left only the dropper's local satchel, so its pickup must not mint an authority item")
	assert_true(world.reward_deliveries.is_empty())


func test_a_second_claim_pays_nothing_and_the_receipt_is_stable() -> void:
	var first: Dictionary = ledger.call("commit", _claim("cache:once", "fiber", 1, GUEST_CHARACTER), GUEST)
	var again: Dictionary = ledger.call("commit", _claim("cache:once", "fiber", 1, GUEST_CHARACTER), GUEST)
	assert_true(first.get("ok"))
	assert_false(again.get("ok"), "a replayed claim (reconnect resend) commits nothing")
	assert_eq(str(again.get("code")), "already_taken")
	assert_eq(world.reward_deliveries.size(), 1, "one delivery, never two")


func test_a_guest_in_an_unsaved_world_is_refused_without_effect() -> void:
	world.reward_delivery_namespace = ""
	var verdict: Dictionary = ledger.call("commit", _claim("cache:early", "berries", 1, GUEST_CHARACTER), GUEST)
	assert_false(verdict.get("ok"), "no receipt can be keyed without the world's saved identity")
	assert_eq(str(verdict.get("code")), "world_not_ready")
	assert_false(world.flags.call("has", "cache:early"), "and the find stays for a retry")


func test_without_an_admitted_character_the_claim_keeps_the_direct_grant() -> void:
	var verdict: Dictionary = ledger.call("commit", _claim("cache:anon", "berries", 1, ""), GUEST)
	assert_true(verdict.get("ok"))
	assert_eq(str(_ops(verdict, GUEST)[0].get("op")), "item_grant", "nothing to key a receipt on, so behaviour is unchanged")
