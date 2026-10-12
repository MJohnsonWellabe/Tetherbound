extends "res://tests/test_case.gd"

## F20/F19#5 regression (12 Oct). The homecoming read "stormwood:stormheart_freed",
## a world flag nothing produced, so no earned world ever reached the homecoming,
## the Home Key finale or the credits (marrow_aftermath r14). This pins the flag
## the real release writes to the one the homecoming reads, through the authored
## chapter dispatch and the real Game.regional_ending_context(), so a rename on
## either side fails here instead of silently closing the ending.

const HOME := preload("res://scripts/story/regional_homecoming.gd")
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const CHAPTER := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_PATH := "res://data/config/stormwood_chapter.json"
const OBJECTIVES_PATH := "res://data/config/regional_ending_objectives.json"
const CHARACTER := "character-freed-flag-regression"
## Uses the live /root/Game autoload, which is in the tree only after _init().
const RUNS_IN_INITIALIZED_TREE := true


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CHAPTER_PATH))


func test_the_release_event_produces_the_flag_the_homecoming_reads() -> void:
	assert_eq(HOME.WORLD_FLAG, ENDING.FREED_FLAG)
	var produced: Array = []
	for act: Dictionary in _chapter().get("acts", []):
		for objective: Dictionary in act.get("objectives", []):
			if objective.get("completion_event") == "dynamo:release":
				produced.append(objective.get("flag_id"))
	assert_eq(produced, [HOME.WORLD_FLAG], "the ending's dynamo:release completes exactly the flag the homecoming requires")
	var objectives: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH))
	assert_eq(objectives.get("required_world_flag"), HOME.WORLD_FLAG)


func test_real_release_makes_a_settled_owners_ending_context_live() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.root.get_node_or_null(^"Game") if tree != null and tree.root != null else null
	assert_true(game != null, "Game autoload is available")
	if game == null:
		return
	var original_world: RefCounted = game.world
	var original_world_data: Dictionary = game.world.save_data().duplicate(true)
	var original_character: Dictionary = game.local.save_data().duplicate(true)
	var original_realm: String = game.current_realm
	game.reset_for_new_game()
	game.current_realm = "stormwood"
	game.local.set("character_id", CHARACTER)
	for index: int in 5:
		game.party.add(game.make_creature("terrapup", "Keeper %d" % (index + 1)))
	var starter := str(game.party.at(0).uid)
	game.local.redesign_character.transaction_receipts.append("starter_choice:%s:%s" % [CHARACTER, starter])
	# The settled personal answer, written by the ending's own recorder.
	ENDING.record_answer(game.call("player_flags"), "freed-flag-claim", true, game.party)
	game.local.flags.set_flag("stormwood:legendary_ceremony_settled")
	game.world.flags.set_flag("stormwood:act_ii_complete")
	game.world.flags.set_flag("stormwood:marrow_defeated")
	assert_true(HOME.journey_context(game).is_empty(), "before the release no ending context exists")

	# The ending emits dynamo:release once Marrow falls; its writer commits the
	# completed objective as a shared world flag (stormwood_ending.gd).
	var writer := func(flag: String) -> Dictionary:
		game.world.flags.set_flag(flag)
		return {"ok": true}
	var result: Dictionary = CHAPTER.dispatch(game.progression, _chapter(), "dynamo:release", writer)
	assert_true(bool(result.get("accepted", false)), "the authored chapter accepts the real release event")
	assert_true(game.world.flags.has(ENDING.FREED_FLAG), "the release writes the freed world fact")

	var context: Dictionary = game.call("regional_ending_context")
	assert_false(context.is_empty(), "the real ending context is live after the release")
	assert_eq(context.get("accepted_outcome"), true)
	assert_true((context.get("chapter_choices", []) as Array).has("stormwood:accepted"))
	assert_eq(context.get("starter_uid"), starter)
	assert_false(HOME.journey_context(game).is_empty(), "the homecoming journey reads that context")
	assert_eq(HOME.aftermath_conversation(game), "stormwood_homecoming_aftermath")

	game.reset_for_new_game()
	game.world = original_world
	game.world.load_data(original_world_data)
	game.local.load_data(original_character)
	game.current_realm = original_realm
	game.call("_ensure_containers")
