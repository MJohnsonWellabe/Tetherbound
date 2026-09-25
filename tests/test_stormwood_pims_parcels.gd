extends "res://tests/test_case.gd"

const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const PARCELS := preload("res://scripts/world/stormwood_pims_parcels.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const CHAIN := "stormwood_pims_parcels"


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json")) as Dictionary


func _npcs() -> Dictionary:
	var out := {}
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_npcs.json"))
	for actor: Dictionary in parsed.characters:
		out[str(actor.id)] = actor
	return out


func _entry(flags: RefCounted, chapter: Dictionary) -> Dictionary:
	for row: Dictionary in LOGIC.side_entries(flags, chapter):
		if str(row.id) == CHAIN:
			return row
	return {}


func _dispatch_outcome(flags: RefCounted, chapter: Dictionary, conversation: String) -> bool:
	var changed := false
	for event: String in PARCELS.outcome_for(conversation).get("events", []):
		changed = bool(LOGIC.dispatch(flags, chapter, event).changed) or changed
	return changed


func test_offer_three_deliveries_and_return_complete_the_chain_once() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	assert_true(_entry(flags, chapter).is_empty(), "Hidden until the A pair links Lantern Pools")
	flags.set_flag("stormwood:lantern_pools_linked")
	assert_eq(_entry(flags, chapter).how, "Collect Pim's sealed parcels.")
	assert_false(_dispatch_outcome(flags, chapter, PARCELS.delivery_conversation("cook_marl")),
		"A household cannot receive a parcel before Pim hands them over")
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed,
		"The aggregate delivery event cannot skip the households")
	assert_true(_dispatch_outcome(flags, chapter, PARCELS.OFFER))
	assert_true(flags.has(PARCELS.STEP_1))
	assert_eq(_entry(flags, chapter).how,
		"Deliver them to Marl at Ashfoot, Oswin at Rodline Post and Lio at Lantern Hollow.")
	assert_true(_dispatch_outcome(flags, chapter, PARCELS.delivery_conversation("cook_marl")))
	assert_false(_dispatch_outcome(flags, chapter, PARCELS.delivery_conversation("cook_marl")),
		"One household cannot count twice")
	assert_true(_dispatch_outcome(flags, chapter, PARCELS.delivery_conversation("trader_oswin")))
	assert_false(flags.has(PARCELS.STEP_2))
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_3" % CHAIN).changed,
		"Pim cannot be answered before the third household")
	assert_true(_dispatch_outcome(flags, chapter, PARCELS.delivery_conversation("caretaker_lio")))
	assert_true(flags.has(PARCELS.STEP_2))
	assert_eq(_entry(flags, chapter).how, "Return to Pim at Lantern Pools.")
	assert_true(_dispatch_outcome(flags, chapter, PARCELS.RETURN))
	assert_true(flags.has(PARCELS.COMPLETE))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	for recipient: String in PARCELS.RECIPIENTS:
		assert_true(loaded.has(PARCELS.delivered_flag(recipient)), "%s delivery survives save/load" % recipient)
	assert_true(loaded.has(PARCELS.COMPLETE))


func test_recipients_are_existing_arch_road_residents_with_authored_lines() -> void:
	var npcs := _npcs()
	var chapter := _chapter()
	var dialogue: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	var counted: Array = []
	for recipient: String in PARCELS.RECIPIENTS:
		assert_true(npcs.has(recipient), "%s is an installed resident" % recipient)
		assert_true(dialogue.has(PARCELS.delivery_conversation(recipient)))
		counted.append(PARCELS.delivered_flag(recipient))
		assert_eq(PROGRESSION.scope_of(PARCELS.delivered_flag(recipient)), PROGRESSION.SCOPE_WORLD)
		assert_true((chapter.persistent_flags.side_content as Array).has(PARCELS.delivered_flag(recipient)))
	for chain: Dictionary in chapter.side_chains:
		if str(chain.id) == CHAIN:
			assert_eq(chain.steps[1].count_flags, counted)
			assert_eq(int(chain.steps[1].required_count), 3)
	for id: String in [PARCELS.OFFER, PARCELS.PROGRESS, PARCELS.RETURN, PARCELS.THANKS]:
		assert_true(dialogue.has(id), "%s is authored" % id)
	assert_true(ResourceLoader.exists(PARCELS.CRATE))


func test_reward_is_per_character_potions_through_the_world_delivery_receipt() -> void:
	var intent := PARCELS.reward_intent()
	assert_eq(intent.kind, "reward_grant")
	assert_eq(intent.realm, "stormwood")
	assert_eq(intent.item, "potion_small")
	assert_eq(int(intent.count), 2)
	assert_false(intent.has("flag"),
		"No new flag: MULTIPLAYER's (world namespace, source, character) delivery receipt is the once-guard")
	assert_true(bool(PARCELS.outcome_for(PARCELS.RETURN).claim))
	assert_true(bool(PARCELS.outcome_for(PARCELS.THANKS).claim))
	assert_false(bool(PARCELS.outcome_for(PARCELS.OFFER).claim))
	assert_true(PARCELS.outcome_for("stormwood_courier_pim_in_progress").is_empty())


func test_pim_and_recipient_greetings_follow_the_chain() -> void:
	var npcs := _npcs()
	var pim := CHAPTER_RUNTIME.npc_spec(npcs.courier_pim)
	var marl := CHAPTER_RUNTIME.npc_spec(npcs.cook_marl)
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:chapter_started")
	assert_eq(PEOPLE.greeting_for(pim, flags), "stormwood_courier_pim_in_progress")
	assert_eq(PEOPLE.greeting_for(marl, flags), "stormwood_cook_marl_in_progress")
	flags.set_flag("stormwood:lantern_pools_linked")
	assert_eq(PEOPLE.greeting_for(pim, flags), PARCELS.OFFER)
	flags.set_flag(PARCELS.STEP_1)
	assert_eq(PEOPLE.greeting_for(pim, flags), PARCELS.PROGRESS)
	assert_eq(PEOPLE.greeting_for(marl, flags), PARCELS.delivery_conversation("cook_marl"))
	flags.set_flag(PARCELS.delivered_flag("cook_marl"))
	assert_eq(PEOPLE.greeting_for(marl, flags), "stormwood_cook_marl_in_progress",
		"A household returns to its own lines after receiving its parcel")
	flags.set_flag(PARCELS.STEP_2)
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(pim, flags), PARCELS.RETURN, "The return survives the Long Storm's end")
	flags.set_flag(PARCELS.COMPLETE)
	assert_eq(PEOPLE.greeting_for(pim, flags), PARCELS.THANKS,
		"After the chain Pim offers the courier's rate to any character not yet paid in this world")


func test_ledger_pays_each_character_once_for_the_courier_rate() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", "stormwood-pims-test")
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var courier := PARCELS.reward_intent()
	courier["_reward_recipients"] = [{"peer": 1, "character_id": "character-courier"}]
	var first: Dictionary = ledger.call("commit", courier, 1)
	assert_true(bool(first.get("ok")), "The courier is paid")
	var again: Dictionary = ledger.call("commit", courier, 1)
	assert_false(bool(again.get("ok")))
	assert_eq(str(again.get("code", "")), "already_taken", "The same character cannot be paid twice")
	var companion := PARCELS.reward_intent()
	companion["_reward_recipients"] = [{"peer": 2, "character_id": "character-companion"}]
	assert_true(bool((ledger.call("commit", companion, 2) as Dictionary).get("ok")),
		"A second character collects their own share")
	assert_eq(world.reward_deliveries.size(), 2)
	for delivery: Dictionary in world.reward_deliveries.values():
		assert_eq(delivery.get("stacks", []), [{"id": "potion_small", "n": 2}])
	assert_true(PARCELS.paid_in_world(world, "character-courier"), "The courier's receipt is visible in this world")
	assert_true(PARCELS.paid_in_world(world, "character-companion"))
	assert_false(PARCELS.paid_in_world(world, "character-latecomer"), "An unpaid character is still owed")
	var other_world: RefCounted = WORLD_STATE.new()
	assert_false(PARCELS.paid_in_world(other_world, "character-courier"),
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
	var character_id := "character-courier"


class ChapterStub extends Node:
	func emit_event(_event: String) -> Dictionary:
		return {"accepted": true}


func _paid_world(character: String) -> RefCounted:
	var world: RefCounted = WORLD_STATE.new()
	world.set("reward_delivery_namespace", "stormwood-pims-thanks")
	var id := REWARD_DELIVERY.delivery_id("stormwood-pims-thanks", PARCELS.REWARD_SOURCE, character)
	(world.get("reward_deliveries") as Dictionary)[id] = {"stacks": [{"id": PARCELS.REWARD_ITEM, "n": 2}]}
	return world


func test_pim_returns_to_her_post_storm_greeting_once_her_thanks_is_heard_while_paid() -> void:
	var pim := CHAPTER_RUNTIME.npc_spec(_npcs().courier_pim)
	var flags := PROGRESSION.new()
	for flag: String in ["stormwood:chapter_started", "stormwood:long_storm_ended", PARCELS.COMPLETE]:
		flags.set_flag(flag)
	assert_eq(PEOPLE.greeting_for(pim, flags), PARCELS.THANKS, "a finished chain opens Pim's thanks first")
	assert_eq(PROGRESSION.scope_of(PARCELS.RECEIVED_FLAG), PROGRESSION.SCOPE_PLAYER,
		"the thanks receipt is this character's own, not the world's")
	var game := GameStub.new()
	game.progression = flags
	game.local = LocalStub.new()
	game.world = _paid_world("character-courier")
	var parcels: Node3D = PARCELS.new()
	parcels.set("game", game)
	assert_true(parcels.call("_paid"), "the fixture character's rate is in this world's delivery journal")
	var chapter := ChapterStub.new()
	assert_true(bool(parcels.call("dialogue_finished", PARCELS.THANKS, chapter)))
	chapter.free()
	assert_true(flags.has(PARCELS.RECEIVED_FLAG), "hearing the thanks while paid records the receipt")
	assert_eq(PEOPLE.greeting_for(pim, flags), "stormwood_courier_pim_post_storm",
		"after the thanks has been heard once Pim falls back to her post-storm greeting")
	flags.set_flag("stormwood:long_storm_ended", false)
	assert_eq(PEOPLE.greeting_for(pim, flags), "stormwood_courier_pim_in_progress",
		"before the storm ends she falls back to her ordinary lines")

	# The same character in a world that still owes it the rate: the receipt
	# from elsewhere is dropped so her thanks, which pays, is reachable again.
	game.world = WORLD_STATE.new()
	(game.world as RefCounted).set("reward_delivery_namespace", "stormwood-pims-other")
	parcels.call("restore_progression_from_game", game)
	assert_false(flags.has(PARCELS.RECEIVED_FLAG), "an unpaid world drops the receipt")
	assert_eq(PEOPLE.greeting_for(pim, flags), PARCELS.THANKS, "an unpaid character is still thanked and paid")
	parcels.free()
	game.free()


func test_paid_is_false_without_a_game_or_local_record() -> void:
	var parcels: Node3D = PARCELS.new()
	assert_false(parcels.call("_paid"), "no Game yet reads as unpaid instead of crashing")
	var game := GameStub.new()
	game.progression = PROGRESSION.new()
	game.world = _paid_world("character-courier")
	parcels.set("game", game)
	assert_false(parcels.call("_paid"), "a Game whose local record is not set yet reads as unpaid")
	parcels.free()
	game.free()
