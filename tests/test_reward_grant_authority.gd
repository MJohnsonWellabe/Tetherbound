extends "res://tests/test_case.gd"

## X05 host authority (#253 Cloudreach findings): a GUEST's `reward_grant` is
## judged by the host against its own record of that activity. The request's
## `peers`, `source`, `item`, `count` and position are never trusted:
## - recipients are always the sender alone (ledger_rpc.gd `_reward_recipients`);
## - the source must be one a guest really pays itself, with its authored payout;
## - the activity must already be complete in the host's world;
## - a payout with a fixed place needs the host's copy of the guest standing there.
## The host's own grants are unaffected.

const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const LEDGER_RPC := preload("res://scripts/net/ledger_rpc.gd")

const HOST := 1
const GUEST := 771240190
const OTHER := 55012
const COURIER_BAG := Vector3(-288.0, 180.0, 516.0)

var world: RefCounted
var ledger: RefCounted


func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)


func _grant(source: String, item: String, count: int, flag: String = "",
		actor: Dictionary = {}) -> Dictionary:
	var intent := {"kind": "reward_grant", "realm": "cloudreach", "source": source,
		"_reward_recipients": [{"peer": GUEST, "character_id": "guest-char"}]}
	if not item.is_empty():
		intent["item"] = item
		intent["count"] = count
	if not flag.is_empty():
		intent["flag"] = flag
	if not actor.is_empty():
		intent["_reward_actor"] = actor
	return intent


func _couriers(actor: Dictionary) -> Dictionary:
	return _grant("cloudreach_couriers_thanks", "potion_small", 2,
		"cloudreach_payout:couriers_thanks", actor)


func _at_bag() -> Dictionary:
	return {"peer": GUEST, "realm": "cloudreach", "position": COURIER_BAG + Vector3(2.0, 0.0, 1.0)}


func _refused(verdict: Dictionary, code: String, why: String) -> void:
	assert_false(bool(verdict.get("ok")), why)
	assert_eq(str(verdict.get("code", "")), code, why)
	assert_true(world.reward_deliveries.is_empty(), "%s: nothing is journaled" % why)


func test_guest_cannot_invent_a_reward_source() -> void:
	_refused(ledger.commit(_grant("rpc-reward", "coin", 999), GUEST), "unknown_source",
		"an unauthored source")
	_refused(ledger.commit(_grant("cloudreach_couriers_thanks_2", "potion_small", 2,
		"cloudreach_payout:couriers_thanks"), GUEST), "unknown_source", "a near-miss source")


func test_guest_cannot_change_an_authored_payout() -> void:
	world.flags.set_flag("side_stranded_couriers_complete")
	_refused(ledger.commit(_grant("cloudreach_couriers_thanks", "potion_small", 20,
		"cloudreach_payout:couriers_thanks", _at_bag()), GUEST), "not_authored", "a raised count")
	_refused(ledger.commit(_grant("cloudreach_couriers_thanks", "potion_large", 2,
		"cloudreach_payout:couriers_thanks", _at_bag()), GUEST), "not_authored", "a swapped item")
	_refused(ledger.commit(_grant("cloudreach_couriers_thanks", "potion_small", 2,
		"cloudreach_payout:other", _at_bag()), GUEST), "not_authored", "a different claim flag")


func test_guest_cannot_claim_before_the_host_world_completes_the_activity() -> void:
	_refused(ledger.commit(_couriers(_at_bag()), GUEST), "not_earned",
		"the couriers are not home in the host's world")
	_refused(ledger.commit(_grant("broken_cart_coll:repair", "coin", 25), GUEST), "not_earned",
		"the cart is not repaired in the host's world")
	_refused(ledger.commit(_grant("meadowhart_herd_visit", "orb_basic", 3,
		"band1_meadowhart_herd_found"), GUEST), "not_earned", "nobody has met the herd")


func test_guest_must_stand_at_a_placed_reward() -> void:
	world.flags.set_flag("side_stranded_couriers_complete")
	_refused(ledger.commit(_couriers({}), GUEST), "too_far", "no host view of the guest")
	_refused(ledger.commit(_couriers({"peer": GUEST, "realm": "cloudreach",
		"position": COURIER_BAG + Vector3(40.0, 0.0, 0.0)}), GUEST), "too_far", "40 m away")
	_refused(ledger.commit(_couriers({"peer": GUEST, "realm": "meadows",
		"position": COURIER_BAG}), GUEST), "too_far", "the right spot in another realm")


func test_guest_cannot_mint_rewards_under_made_up_once_ids() -> void:
	# Each new source would be a new delivery: the id itself must be real.
	for forged: String in ["a1", "a2", "wild_once_999999", "hollows_alpha"]:
		_refused(ledger.commit(_grant("trainer:%s:coins" % forged, "coin", 90), GUEST),
			"not_authored", "%s: the Warrens clear coins under a made-up id" % forged)
		_refused(ledger.commit(_grant("trainer:%s:item:potion_large" % forged, "potion_large", 2), GUEST),
			"not_authored", "%s: an authored item under a made-up id" % forged)
		_refused(ledger.commit(_grant("trainer:%s:xp" % forged, "", 0), GUEST),
			"not_authored", "%s: an XP receipt under a made-up id" % forged)


func test_guest_xp_receipt_is_its_own_whatever_peers_it_names() -> void:
	var xp := _grant("trainer:warrens_cleared:xp", "", 0)
	xp["peers"] = [HOST, OTHER]
	var verdict: Dictionary = ledger.commit(xp, GUEST)
	assert_true(bool(verdict.get("ok")), str(verdict))
	assert_eq(verdict.get("paid", []), [GUEST], "only the sender's receipt is written")
	assert_false(world.flags.has(WORLD_LEDGER.reward_flag("trainer:warrens_cleared:xp", HOST)),
		"the host's receipt is untouched")
	assert_false(world.flags.has(WORLD_LEDGER.reward_flag("trainer:warrens_cleared:xp", OTHER)),
		"another guest's receipt is untouched")


func test_guest_trainer_sources_carry_only_authored_once_rewards() -> void:
	_refused(ledger.commit(_grant("trainer:meadows_alpha_bramble:item:stick", "stick", 1), GUEST),
		"not_authored", "an item no named wild pays")
	_refused(ledger.commit(_grant("trainer:wild_once_5001:item:potion_large", "revive", 2), GUEST),
		"not_authored", "the item differs from the source")
	_refused(ledger.commit(_grant("trainer:wild_once_5001:item:potion_large", "potion_large", 9), GUEST),
		"not_authored", "an inflated authored item")
	_refused(ledger.commit(_grant("trainer:wild_once_5001:item:revive", "revive", 2), GUEST),
		"not_authored", "another component's count")
	_refused(ledger.commit(_grant("trainer:warrens_cleared:coins", "coin", 777777), GUEST),
		"not_authored", "an unauthored coin payout")
	_refused(ledger.commit(_grant("trainer:wild_once_5001:coins", "coin", 90), GUEST),
		"not_authored", "a payout that belongs to another once id")
	_refused(ledger.commit(_grant("trainer:wild_once_5001:xp", "", 0), GUEST),
		"not_authored", "an XP receipt the once id does not pay")
	_refused(ledger.commit(_grant("trainer:warrens_cleared:xp:again", "", 0), GUEST),
		"not_authored", "an XP source with extra segments")
	_refused(ledger.commit(_grant("trainer:x:flag:band1_champion", "", 0, "band1_champion"), GUEST),
		"not_authored", "a trainer flag grant")


func test_guest_authored_claims_still_pay() -> void:
	world.flags.set_flag("side_stranded_couriers_complete")
	assert_true(bool(ledger.commit(_couriers(_at_bag()), GUEST).get("ok")), "the couriers' thanks")
	world.flags.set_flag("band1_broken_cart_repaired")
	assert_true(bool(ledger.commit(_grant("broken_cart_coll:repair", "coin", 25), GUEST).get("ok")),
		"the cart repair coins")
	world.flags.set_flag("stormwood:side_pims_parcels_2")
	assert_true(bool(ledger.commit(_grant("stormwood_pims_parcels", "potion_small", 2), GUEST).get("ok")),
		"Pim's parcels")
	world.flags.set_flag("band1_meadowhart_herd_met")
	assert_true(bool(ledger.commit(_grant("meadowhart_herd_visit", "orb_basic", 3,
		"band1_meadowhart_herd_found"), GUEST).get("ok")), "the herd visit")
	assert_true(bool(ledger.commit(_grant("trainer:wild_once_5001:item:potion_large", "potion_large", 2),
		GUEST).get("ok")), "an authored band alpha item")
	assert_true(bool(ledger.commit(_grant("trainer:warrens_once_elder_trailpup:item:potion_large",
		"potion_large", 2), GUEST).get("ok")), "an authored Warrens resident item")
	assert_true(bool(ledger.commit(_grant("trainer:warrens_cleared:coins", "coin", 90), GUEST).get("ok")),
		"the Warrens clear coins")
	assert_true(bool(ledger.commit(_grant("trainer:warrens_cleared:xp", "", 0), GUEST).get("ok")),
		"the once-only XP component")
	var hollows := "wild_once_%d" % int(load("res://scripts/combat/stormwood_encounter_catalogue.gd")
		.call("named_order", "hollows_alpha"))
	assert_true(bool(ledger.commit(_grant("trainer:%s:item:great_candy" % hollows, "great_candy", 1),
		GUEST).get("ok")), "a Stormwood named encounter's item")


func test_host_grants_are_not_restricted() -> void:
	var intent := _grant("rpc-reward", "coin", 3)
	intent["_reward_recipients"] = [{"peer": HOST, "character_id": "host-char"}]
	assert_true(bool(ledger.commit(intent, HOST).get("ok")), "host code pays what it validated")


class Registry extends RefCounted:
	func row(peer: int) -> Dictionary:
		return {"character_id": "char-%d" % peer}


class Session extends RefCounted:
	var _registry := Registry.new()
	func registry() -> RefCounted: return _registry


class GameFixture extends Node:
	var session := Session.new()


class RpcFixture extends "res://scripts/net/ledger_rpc.gd":
	var fixture_game: Node
	func _game() -> Node: return fixture_game


func _peers_of(rows: Array) -> Array:
	var out: Array = []
	for row: Variant in rows:
		out.append(int((row as Dictionary).get("peer", 0)))
	return out


func test_guest_recipients_are_the_sender_whatever_peers_it_names() -> void:
	var game := GameFixture.new()
	var rpc := RpcFixture.new()
	rpc.fixture_game = game
	var from_guest: Array = rpc.call("_reward_recipients", {"peers": [OTHER, HOST]}, GUEST)
	var one_guest: Array = rpc.call("_reward_recipients", {"peer": OTHER}, GUEST)
	var from_host: Array = rpc.call("_reward_recipients", {"peers": [OTHER, GUEST]}, HOST)
	rpc.free()
	game.free()
	assert_eq(_peers_of(from_guest), [GUEST], "a guest's `peers` cannot name anyone else")
	assert_eq(_peers_of(one_guest), [GUEST], "nor can its `peer`")
	assert_eq(_peers_of(from_host), [OTHER, GUEST], "the host's own list is still honoured")
