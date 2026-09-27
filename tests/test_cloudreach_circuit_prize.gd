extends "res://tests/test_case.gd"

## F07#0 Cliff Circuit payoff (WORLD §11): "one existing compatible TM choice
## from the chapter's three placed TM rewards, collected through its original
## source receipt". Three prompts at the circuit board share one completion
## flag (one choice per world) and each claims its placed pickup's own cache
## flag through `claim_pickup`. Disclosed co-op limit: two peers choosing
## different TMs within one round trip can each be paid one (never the same TM
## twice; an atomic choice+claim needs a world_ledger op).

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")


class FakeInventory extends RefCounted:
	func has_room_for(_item: String, _count: int) -> bool:
		return true


class FakeGame extends Node:
	var party: RefCounted = PARTY.new()
	var inventory: RefCounted = FakeInventory.new()


func _prizes() -> Array:
	var out: Array = []
	for spec: Dictionary in RULES.read(RUNTIME.DATA_PATH)["interactions"]:
		if spec.has("claims_pickup"):
			out.append(spec)
	return out


func test_the_prizes_are_two_placed_air_tms_and_one_existing_ground_tm() -> void:
	var prizes := _prizes()
	assert_eq(prizes.size(), 3)
	var pickups := {}
	for pickup: Dictionary in RULES.read(RUNTIME.CHAPTER_PATH)["pickups"]:
		pickups[str(pickup.id)] = pickup
	var placed := 0
	var receipts := {}
	for spec: Dictionary in prizes:
		assert_true(str(spec.item_id).begins_with("tm_"))
		assert_eq(str(spec.completion_flag), "side_cliff_circuit_tm_chosen", "one shared choice")
		assert_eq(spec.requires_flags, ["cloudreach_upper_route_unlocked", "side_cliff_circuit_complete"])
		assert_false(receipts.has(str(spec.claims_pickup)), "each pad has its own receipt")
		receipts[str(spec.claims_pickup)] = true
		var pickup: Dictionary = pickups.get(str(spec.claims_pickup), {})
		if not pickup.is_empty():
			assert_eq(str(pickup.get("item_id", "")), str(spec.item_id), "%s grants that pickup's own TM" % str(spec.id))
			placed += 1
	assert_eq(placed, 2, "two pads are the chapter's placed TMs, collected through their own receipts")


## Ruling (a), #356 14:41: every retained five can use at least one pick.
func test_every_retained_five_has_a_usable_circuit_pick() -> void:
	var tms: RefCounted = preload("res://scripts/creatures/tm_db.gd").new()
	var teaching := preload("res://scripts/creatures/teaching.gd")
	var tm_items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/tms.json")).get("tms", {})
	for five: Array in [["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"], ["ripplet", "bramblebun", "mudsnout", "veridian"]]:
		var usable := false
		for spec: Dictionary in _prizes():
			assert_true(tm_items.has(str(spec.item_id)), "%s is an existing TM" % str(spec.item_id))
			for species: String in five:
				if teaching.can_learn(str(SPECIES.spawn(species).get("creature_type")), str(spec.item_id), tms):
					usable = true
		assert_true(usable, "%s can use at least one Circuit pick" % str(five))


func test_one_choice_per_world() -> void:
	var allowed: Array = RULES.read(RUNTIME.NPC_PATH).get("world_choice_flags", [])
	assert_true(allowed.has("side_cliff_circuit_tm_chosen"), "the choice is a world fact the runtime may write")
	var flags: RefCounted = FLAGS.new()
	flags.set_flag("cloudreach_upper_route_unlocked")
	flags.set_flag("side_cliff_circuit_complete")
	for spec: Dictionary in _prizes():
		assert_eq(str(spec.set_physical_flag), "side_cliff_circuit_tm_chosen")
		assert_true(RULES.available(flags, spec), "%s is offered after the circuit" % str(spec.id))
	flags.set_flag("side_cliff_circuit_tm_chosen")
	for spec: Dictionary in _prizes():
		assert_false(RULES.available(flags, spec), "%s is gone once one prize is chosen" % str(spec.id))


func test_only_a_compatible_uncollected_tm_is_offered() -> void:
	var runtime: Node = RUNTIME.new()
	var game := FakeGame.new()
	var flags: RefCounted = FLAGS.new()
	runtime.set("_game", game)
	runtime.set("_flags", flags)
	var prize: Dictionary = _prizes()[0]
	game.party.add(SPECIES.spawn("sparkit"))
	assert_eq(str(runtime.call("tm_prize_refusal", prize)), "None of your companions can learn that TM.", "an all-electric team")
	game.party.add(SPECIES.spawn("galewisp"))
	assert_eq(str(runtime.call("tm_prize_refusal", prize)), "", "an air companion can learn it")
	flags.set_flag(CACHE.flag_id(str(prize.item_id), str(prize.claims_pickup), "cloudreach"))
	assert_eq(str(runtime.call("tm_prize_refusal", prize)), "That TM has already been collected.", "a field-collected TM is not offered twice")
	runtime.free()
	game.free()
