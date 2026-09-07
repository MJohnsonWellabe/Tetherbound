extends "res://tests/test_case.gd"

## Host-ledger authority proof for authored Stormwood harvest sites. This stays
## pure: it inspects committed player ops instead of a local player inventory.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const HARVEST := preload("res://scripts/world/stormwood_harvest_rules.gd")

const PEER_A := 1
const PEER_B := 771240190
const BREAK_SITE := "stormwood_harvest_glowmoss_hollows_036"
const CROWN_SITE := "stormwood_harvest_hollow_crown_106"

var world: RefCounted
var ledger: RefCounted
var rules: RefCounted


func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)
	rules = HARVEST.new()


func _intent(site_id: String, extra: Dictionary = {}) -> Dictionary:
	var intent := {"kind": "stormwood_harvest", "realm": "stormwood", "site_id": site_id}
	intent.merge(extra, true)
	return intent


func _set_elapsed(seconds: float) -> void:
	world.realm_environment = {"stormwood": {"elapsed": seconds}}


func _grants(delta: Dictionary, peer: int) -> Array:
	var grants: Array = []
	for op: Dictionary in WORLD_LEDGER.player_ops_for(delta, peer):
		if str(op.get("op", "")) == "item_grant":
			grants.append(op)
	return grants


func test_calm_refuses_a_charged_site_even_if_request_claims_break() -> void:
	_set_elapsed(0.0)
	var verdict: Dictionary = ledger.commit(_intent(BREAK_SITE, {"phase": "break"}), PEER_A)
	assert_false(bool(verdict.get("ok")), "the host clock, not request phase, controls availability")
	assert_eq(str(verdict.get("code", "")), "unavailable")
	assert_false(world.flags.has(HARVEST.flag(BREAK_SITE)))
	assert_true(_grants(verdict.delta, PEER_A).is_empty())


func test_break_grants_the_catalogue_yield_not_forged_request_contents() -> void:
	# Glowmoss Hollows has a 324s gentle Calm, then 90s Building; 420s is Break.
	_set_elapsed(420.0)
	var authored: Dictionary = rules.sites[BREAK_SITE]
	var verdict: Dictionary = ledger.commit(_intent(BREAK_SITE, {
		"phase": "calm", "item": "legendary_orb", "amount": 9999,
	}), PEER_A)
	assert_true(bool(verdict.get("ok")))
	assert_true(world.flags.has(HARVEST.flag(BREAK_SITE)))
	var grants := _grants(verdict.delta, PEER_A)
	assert_eq(grants.size(), 1, "one authored yield is granted")
	if grants.size() == 1:
		assert_eq(str(grants[0].get("item", "")), str(authored.item))
		assert_eq(int(grants[0].get("count", 0)), int(authored.amount))


func test_two_peers_contending_for_one_site_create_one_grant() -> void:
	_set_elapsed(420.0)
	var first: Dictionary = ledger.commit(_intent(BREAK_SITE), PEER_B)
	var second: Dictionary = ledger.commit(_intent(BREAK_SITE), PEER_A)
	assert_true(bool(first.get("ok")), "first serialised host claimant wins")
	assert_false(bool(second.get("ok")))
	assert_eq(str(second.get("code", "")), "already_taken")
	assert_eq(_grants(first.delta, PEER_B).size(), 1)
	assert_true(_grants(first.delta, PEER_A).is_empty(), "only winner receives the yield")
	assert_true(_grants(second.delta, PEER_A).is_empty(), "loser receives no yield")


func test_generic_harvest_cannot_bypass_a_reserved_stormwood_site_flag() -> void:
	var verdict: Dictionary = ledger.commit({
		"kind": "harvest", "realm": "stormwood", "flag": HARVEST.flag(BREAK_SITE),
		"item": "legendary_orb", "amount": 9999,
	}, PEER_A)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "malformed")
	assert_false(world.flags.has(HARVEST.flag(BREAK_SITE)))
	assert_true(_grants(verdict.delta, PEER_A).is_empty())


func test_hollow_crown_site_refuses_before_its_route_gate_opens() -> void:
	_set_elapsed(330.0)
	var verdict: Dictionary = ledger.commit(_intent(CROWN_SITE), PEER_A)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "unavailable")
	assert_false(world.flags.has(HARVEST.flag(CROWN_SITE)))
	assert_true(_grants(verdict.delta, PEER_A).is_empty())
