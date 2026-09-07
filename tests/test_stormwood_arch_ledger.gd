extends "res://tests/test_case.gd"

## Deterministic host-serialisation proof only. `available_stormglass` is the
## caller's character-inventory preflight; ENet delivery and escrow remain an
## integration concern outside this ledger fixture.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const ARCHES := preload("res://scripts/world/stormwood_arch_rules.gd")

const PEER_A := 1
const PEER_B := 771240190

var world: RefCounted
var ledger: RefCounted

func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)

func _intent(id: String, stock: int = 3, realm: String = "stormwood") -> Dictionary:
	return {"kind": "stormwood_relight_arch", "realm": realm, "id": id,
		"available_stormglass": stock}

func _takes(delta: Dictionary, peer: int) -> Array:
	var out: Array = []
	for op: Dictionary in WORLD_LEDGER.player_ops_for(delta, peer):
		if str(op.get("op", "")) == "item_take": out.append(op)
	return out

func test_first_claimant_relights_once_and_only_winner_pays_three() -> void:
	var first: Dictionary = ledger.commit(_intent("a_ashfoot"), PEER_B)
	var second: Dictionary = ledger.commit(_intent("a_ashfoot"), PEER_A)
	assert_true(bool(first.get("ok")), "first host-serialised claimant wins")
	assert_false(bool(second.get("ok")))
	assert_eq(str(second.get("code", "")), "already_lit")
	assert_true(world.flags.has(ARCHES.lit_flag("a_ashfoot")))
	var take := _takes(first.delta, PEER_B)
	assert_eq(take.size(), 1, "winning delta contains exactly one character cost")
	assert_eq(str(take[0].item), "stormglass")
	assert_eq(int(take[0].count), 3)
	assert_eq(_takes(first.delta, PEER_A).size(), 0, "the other peer is never charged")
	assert_true(_takes(second.delta, PEER_A).is_empty(), "repeat claimant pays nothing")

func test_half_lit_pair_has_no_twin_and_full_pair_links_both_directions() -> void:
	assert_true(ARCHES.linked_twin("a_ashfoot", world.flags).is_empty(), "unlit arch has no travel twin")
	assert_true(bool(ledger.commit(_intent("a_ashfoot"), PEER_A).get("ok")))
	assert_true(ARCHES.linked_twin("a_ashfoot", world.flags).is_empty(), "one lit endpoint remains inert")
	assert_true(bool(ledger.commit(_intent("a_pools"), PEER_A).get("ok")))
	assert_eq(str(ARCHES.linked_twin("a_ashfoot", world.flags).id), "a_pools")
	assert_eq(str(ARCHES.linked_twin("a_pools", world.flags).id), "a_ashfoot")

func test_rootgate_guards_c_and_d_until_released() -> void:
	for id: String in ["c_rodline", "d_hall"]:
		var blocked: Dictionary = ledger.commit(_intent(id), PEER_A)
		assert_false(bool(blocked.get("ok")), "%s is gated" % id)
		assert_eq(str(blocked.get("code", "")), "gated")
		assert_true(_takes(blocked.delta, PEER_A).is_empty(), "gated relight costs nothing")
	world.flags.set_flag("stormwood:rootgate_released", true)
	assert_true(bool(ledger.commit(_intent("c_rodline"), PEER_A).get("ok")))
	assert_true(bool(ledger.commit(_intent("d_hall"), PEER_A).get("ok")))

func test_wrong_realm_id_and_insufficient_preflight_stock_refuse_without_cost() -> void:
	for bad: Dictionary in [_intent("a_ashfoot", 3, "meadows"), _intent("no_arch"), _intent("b_pools", 2)]:
		var verdict: Dictionary = ledger.commit(bad, PEER_A)
		assert_false(bool(verdict.get("ok")))
		assert_true(str(verdict.get("code", "")) in ["invalid_arch", "materials"])
		assert_true(_takes(verdict.delta, PEER_A).is_empty(), "refusal has no item_take")
