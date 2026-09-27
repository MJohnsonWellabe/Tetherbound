extends "res://tests/test_case.gd"

## Owner ruling 2026-09-26: Rook's `stormwood_deepwood_circuit` reward is
## TM: Thunder Break, paid once per character through the ledger's existing
## `reward_grant` delivery receipt, and the receipt survives a world reload.
const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const ROOK := preload("res://scripts/world/stormwood_rook_circuit_reward.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const CHAIN := "stormwood_deepwood_circuit"


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json")) as Dictionary


func _rook_actor() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_npcs.json"))
	for actor: Dictionary in parsed.characters:
		if str(actor.id) == ROOK.ROOK:
			return actor
	return {}


func test_the_reward_is_the_owners_thunder_break_tm() -> void:
	var intent := ROOK.reward_intent()
	assert_eq(intent.kind, "reward_grant")
	assert_eq(intent.realm, "stormwood")
	assert_eq(intent.source, "stormwood_deepwood_circuit")
	assert_eq(intent.item, "tm_thunder_break", "owner ruling 2026-09-26")
	assert_eq(int(intent.count), 1)
	assert_false(intent.has("flag"), "No new flag: the per-character delivery receipt is the once-guard")
	var items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/items.json"))
	items = items.get("items", items)
	assert_true(items.has("tm_thunder_break"))
	assert_eq(str(items.tm_thunder_break.kind), "tm")
	assert_eq(str(items.tm_thunder_break.move), "thunder_break")


func test_return_completes_the_chain_once_and_claims_thanks_claims_again() -> void:
	var ret := ROOK.outcome_for(ROOK.RETURN)
	assert_eq(ret.events, ["side:%s:step_3" % CHAIN])
	assert_true(bool(ret.claim))
	var thanks := ROOK.outcome_for(ROOK.THANKS)
	assert_eq(thanks.events, [], "Rook's thanks never re-completes the world chain")
	assert_true(bool(thanks.claim))
	assert_true(ROOK.outcome_for("stormwood_rook_circuit_offer").is_empty())
	assert_true(ROOK.outcome_for("stormwood_rook_circuit_progress").is_empty())
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	for flag: String in ["stormwood:chapter_started", "stormwood:lantern_hollow_reached",
			"stormwood:side_deepwood_circuit_1", "stormwood:side_deepwood_circuit_2"]:
		flags.set_flag(flag)
	for event: String in ret.events:
		LOGIC.dispatch(flags, chapter, event)
	assert_true(flags.has(ROOK.COMPLETE), "Returning to Rook completes the circuit")
	var again := false
	for event: String in ret.events:
		again = bool(LOGIC.dispatch(flags, chapter, event).changed) or again
	assert_false(again, "A second return changes nothing")


func test_rook_offers_the_prize_on_return_then_thanks_after_completion() -> void:
	var rook := CHAPTER_RUNTIME.npc_spec(_rook_actor())
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:chapter_started")
	flags.set_flag("stormwood:lantern_hollow_reached")
	assert_eq(PEOPLE.greeting_for(rook, flags), "stormwood_rook_circuit_offer")
	flags.set_flag("stormwood:side_deepwood_circuit_1")
	flags.set_flag("stormwood:side_deepwood_circuit_2")
	assert_eq(PEOPLE.greeting_for(rook, flags), ROOK.RETURN)
	flags.set_flag(ROOK.COMPLETE)
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(rook, flags), ROOK.THANKS,
		"After the circuit any character not yet paid in this world can collect from Rook, even after the storm")
	flags.set_flag(ROOK.RECEIVED_FLAG)
	assert_eq(PEOPLE.greeting_for(rook, flags), "stormwood_ace_trainer_rook_post_storm",
		"Once this character has heard his thanks while paid, Rook returns to his own lines")


func test_both_conversations_are_authored_and_name_the_tm() -> void:
	var conversations: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).get("conversations", {})
	for id: String in [ROOK.RETURN, ROOK.THANKS]:
		assert_true(conversations.has(id), "%s is authored" % id)
		assert_true(" ".join(conversations[id].lines).contains("Thunder Break"), "%s names the TM" % id)


func test_ledger_pays_each_character_once_and_the_receipt_survives_reload() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", "stormwood-rook-tm-test")
	world.flags.set_flag(ROOK.COMPLETE)
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var host := ROOK.reward_intent()
	host["_reward_recipients"] = [{"peer": 1, "character_id": "character-host"}]
	assert_true(bool((ledger.call("commit", host, 1) as Dictionary).get("ok")), "The host's character is paid")
	var again: Dictionary = ledger.call("commit", host, 1)
	assert_false(bool(again.get("ok")))
	assert_eq(str(again.get("code", "")), "already_taken", "The same character cannot be paid twice")
	assert_eq(world.reward_deliveries.size(), 1)
	for delivery: Dictionary in world.reward_deliveries.values():
		assert_eq(delivery.get("stacks", []), [{"id": "tm_thunder_break", "n": 1}])
	assert_true(ROOK.paid_in_world(world, "character-host"))
	assert_false(ROOK.paid_in_world(world, "character-companion"), "Another character is still owed their own TM")
	var reloaded: RefCounted = WORLD_STATE.new()
	reloaded.load_data(world.save_data())
	assert_true(ROOK.paid_in_world(reloaded, "character-host"), "The receipt survives a save and reload")
	var after_reload: Dictionary = WORLD_LEDGER.new(reloaded).call("commit", host, 1)
	assert_eq(str(after_reload.get("code", "")), "already_taken", "Reloading cannot pay the same character again")
	assert_false(ROOK.paid_in_world(WORLD_STATE.new(), "character-host"),
		"Once per character per world: another world keeps its own receipt")


class GameStub extends Node:
	var progression: RefCounted
	var local: Variant = null
	var world: RefCounted
	var messages: Array[String] = []

	func player_flags() -> RefCounted:
		return progression

	func push_world_message(text: String) -> void:
		messages.append(text)


class LocalStub extends RefCounted:
	var character_id := "character-host"


class ChapterStub extends Node:
	var events: Array[String] = []

	func emit_event(event: String) -> Dictionary:
		events.append(event)
		return {"accepted": true}


func _node_with(paid: bool) -> Array:
	var game := GameStub.new()
	game.progression = PROGRESSION.new()
	game.progression.set_flag(ROOK.COMPLETE)
	game.local = LocalStub.new()
	game.world = WORLD_STATE.new()
	game.world.set("reward_delivery_namespace", "stormwood-rook-thanks")
	if paid:
		var id := preload("res://scripts/net/reward_delivery.gd").delivery_id(
			"stormwood-rook-thanks", ROOK.REWARD_SOURCE, "character-host")
		(game.world.get("reward_deliveries") as Dictionary)[id] = {"stacks": [{"id": ROOK.REWARD_ITEM, "n": 1}]}
	var node: Node = ROOK.new()
	node.game = game
	return [game, node]


func test_thanks_heard_while_paid_sets_the_greeting_preference_and_pays_nothing_again() -> void:
	var pair := _node_with(true)
	var game: Node = pair[0]
	var node: Node = pair[1]
	var chapter := ChapterStub.new()
	assert_true(bool(node.dialogue_finished(ROOK.THANKS, chapter)))
	assert_eq(chapter.events, [], "Thanks never re-completes the chain")
	assert_true(game.progression.has(ROOK.RECEIVED_FLAG), "Heard while paid: Rook moves on")
	assert_eq(game.messages, [], "An already-paid character is not paid or told again")
	assert_false(bool(node.get("_claiming")), "No claim was submitted for a paid character")
	chapter.free()
	node.free()
	game.free()


func test_a_world_that_still_owes_the_tm_restores_rooks_thanks() -> void:
	var pair := _node_with(false)
	var game: Node = pair[0]
	var node: Node = pair[1]
	game.progression.set_flag(ROOK.RECEIVED_FLAG)
	node.call("_update_thanks_receipt")
	assert_false(game.progression.has(ROOK.RECEIVED_FLAG),
		"A receipt from another world cannot hide the TM this world still owes")
	node.free()
	game.free()


func test_a_guest_collects_their_own_tm_once_after_the_host_world_earns_it() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", "stormwood-rook-tm-guest")
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var guest := ROOK.reward_intent()
	guest["_reward_recipients"] = [{"peer": 2, "character_id": "character-guest"}]
	var early: Dictionary = ledger.call("commit", guest, 2)
	assert_eq(str(early.get("code", "")), "not_earned", "A guest's TM waits until the host's world has the circuit")
	world.flags.set_flag(ROOK.STEP_2)
	assert_true(bool((ledger.call("commit", guest, 2) as Dictionary).get("ok")), "The guest collects their own TM")
	assert_eq(str((ledger.call("commit", guest, 2) as Dictionary).get("code", "")), "already_taken",
		"The guest cannot collect twice")
	var forged := ROOK.reward_intent()
	forged["count"] = 3
	forged["_reward_recipients"] = [{"peer": 3, "character_id": "character-forger"}]
	assert_eq(str((ledger.call("commit", forged, 3) as Dictionary).get("code", "")), "not_authored",
		"A guest cannot mint more than the authored single TM")
	var other := ROOK.reward_intent()
	other["item"] = "tm_stormfall"
	other["_reward_recipients"] = [{"peer": 3, "character_id": "character-forger"}]
	assert_eq(str((ledger.call("commit", other, 3) as Dictionary).get("code", "")), "not_authored",
		"A guest cannot swap in another TM")
	assert_true(ROOK.paid_in_world(world, "character-guest"))
	assert_false(ROOK.paid_in_world(world, "character-forger"))


func test_the_thanks_heard_preference_is_player_scoped() -> void:
	assert_eq(PROGRESSION.scope_of(ROOK.RECEIVED_FLAG), "player",
		"Each character's greeting preference is their own, never the world's")
