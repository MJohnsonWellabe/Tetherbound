extends "res://tests/test_case.gd"

const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const SEQUENCE_DIRECTOR := preload("res://scripts/story/sequence_director.gd")
const DIALOGUE_PANEL := preload("res://scripts/ui/dialogue_panel.gd")


class Member:
	extends RefCounted
	var nickname: String = ""
	var display_name: String = ""
	var species_id: String = ""
	var landmarks_visited_together := 0
	var battles_fought := 0
	var rest_nights_together := 0
	var feeds_together := 0

	func _init(display: String, nick: String = "") -> void:
		display_name = display
		nickname = nick


class PartyStub:
	extends RefCounted
	var rows: Array = []

	func members() -> Array:
		return rows.duplicate()


class LocalStub:
	extends RefCounted
	var character_id := "character-homecoming"
	var flags: RefCounted = PROGRESSION.new()
	var realm := "meadows"
	var redesign_character: Dictionary = {"transaction_receipts": []}


class WorldStub:
	extends RefCounted
	var flags: RefCounted = PROGRESSION.new()


class SaverStub:
	extends RefCounted
	var result := true
	var calls := 0
	var saved_character := ""

	func save_character(_game: Object, character_id: String) -> bool:
		calls += 1
		saved_character = character_id
		return result


class GameStub:
	extends RefCounted
	var world: RefCounted = WorldStub.new()
	var local: RefCounted = LocalStub.new()
	var party: RefCounted = PartyStub.new()
	var save_system: RefCounted = SaverStub.new()
	var messages: Array[String] = []

	func push_world_message(message: String) -> void:
		messages.append(message)


func test_runtime_hooks_compile() -> void:
	var sequence: Node = SEQUENCE_DIRECTOR.new()
	var panel: CanvasLayer = DIALOGUE_PANEL.new()
	assert_true(sequence != null)
	assert_true(panel != null)
	sequence.free()
	panel.free()


func test_ahead_world_does_not_unlock_homecoming_without_personal_return() -> void:
	var game := GameStub.new()
	assert_eq(HOMECOMING.conversation_id(game), "")
	game.world.flags.set_flag("water_currents_restored")
	game.world.flags.set_flag("stormwood:long_storm_ended")
	assert_eq(HOMECOMING.conversation_id(game), "", "an ahead world is not a personal ending receipt")
	_home_return(game)
	assert_eq(HOMECOMING.conversation_id(game), "regional_homecoming_0",
		"the protected personal return invites this character")
	game.local.flags.set_flag(HOMECOMING.SEEN_FLAG)
	assert_eq(HOMECOMING.conversation_id(game), HOMECOMING.REPEAT_ID)


func test_live_party_names_use_nickname_then_display_name_and_cap_at_five() -> void:
	var party := PartyStub.new()
	party.rows = [
		Member.new("Terrapup", "Pip"), Member.new("Brooktail"),
		Member.new("Galecrest", "Sky"), Member.new("Mosshell"),
		Member.new("Solmane", "Sunny"), Member.new("Sixth", "Never shown"),
	]
	assert_eq(HOMECOMING.party_names(party), ["Pip", "Brooktail", "Sky", "Mosshell", "Sunny"])
	var game := GameStub.new()
	game.party = party
	_home_return(game)
	assert_eq(HOMECOMING.conversation_id(game), "regional_homecoming_5")
	assert_eq(HOMECOMING.substitutions(game).get("party_5"), "Sunny")
	assert_false(HOMECOMING.substitutions(game).has("party_6"))


func test_five_names_are_spoken_on_separate_lines() -> void:
	var runner := RUNNER.new()
	runner.set_values({
		"party_1": "One", "party_2": "Two", "party_3": "Three",
		"party_4": "Four", "party_5": "Five",
	})
	assert_true(runner.start("regional_homecoming_5"))
	var name_lines: Array[String] = []
	while runner.is_active():
		var text := str(runner.line().get("text", ""))
		for name: String in ["One", "Two", "Three", "Four", "Five"]:
			if text.contains(name):
				name_lines.append(text)
		runner.advance()
	assert_eq(name_lines.size(), 5)
	for line: String in name_lines:
		var names_in_line := 0
		for name: String in ["One", "Two", "Three", "Four", "Five"]:
			names_in_line += 1 if line.contains(name) else 0
		assert_eq(names_in_line, 1)


func test_player_name_that_looks_like_a_token_stays_literal() -> void:
	var runner := RUNNER.new()
	runner.set_values({"party_1": "$party_2", "party_2": "Brooktail"})
	assert_true(runner.start("regional_homecoming_2"))
	runner.advance()
	runner.advance()
	assert_eq(runner.line().get("text"), "$party_2 came home with you.")
	runner.advance()
	assert_eq(runner.line().get("text"), "Brooktail came home with you.")


func test_close_is_finished_but_only_last_line_is_completed() -> void:
	var runner := RUNNER.new()
	var finished: Array[String] = []
	var completed: Array[String] = []
	runner.finished.connect(func(id: String) -> void: finished.append(id))
	runner.completed.connect(func(id: String) -> void: completed.append(id))
	assert_true(runner.start("regional_homecoming_0"))
	runner.close()
	assert_eq(finished, ["regional_homecoming_0"])
	assert_true(completed.is_empty(), "programmatic close must not acknowledge homecoming")
	assert_true(runner.start("regional_homecoming_0"))
	while runner.is_active():
		runner.advance()
	assert_eq(finished.size(), 2)
	assert_eq(completed, ["regional_homecoming_0"])


func test_failed_character_save_rolls_back_and_retry_commits() -> void:
	var game := GameStub.new()
	_home_return(game)
	game.save_system.result = false
	assert_false(HOMECOMING.complete(game, "character-homecoming"))
	assert_false(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	assert_eq(game.save_system.saved_character, "character-homecoming")
	assert_eq(game.messages, [HOMECOMING.SAVE_FAILURE_NOTICE])
	game.save_system.result = true
	assert_true(HOMECOMING.complete(game, "character-homecoming"))
	assert_true(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	assert_eq(game.save_system.calls, 2)
	assert_eq(HOMECOMING.conversation_id(game), HOMECOMING.REPEAT_ID)


func test_homecoming_seen_is_player_scoped() -> void:
	PROGRESSION.reload_scopes()
	assert_eq(PROGRESSION.scope_of(HOMECOMING.SEEN_FLAG), "player")
	assert_eq(PROGRESSION.scope_of(HOMECOMING.CREDITS_SEEN_FLAG), "player")


func test_completion_rechecks_realm_and_character_identity() -> void:
	var game := GameStub.new()
	_home_return(game)
	game.local.realm = "water"
	assert_false(HOMECOMING.complete(game, "character-homecoming"))
	game.local.realm = "meadows"
	game.local.character_id = "character-loaded-after-start"
	assert_false(HOMECOMING.complete(game, "character-homecoming"))
	assert_false(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	assert_eq(game.save_system.calls, 0)


func test_regional_credits_require_personal_return_homecoming_and_pending_receipt() -> void:
	var game := GameStub.new()
	assert_false(HOMECOMING.credits_available(game))
	assert_false(HOMECOMING.credits_pending(game))
	_home_return(game)
	assert_false(HOMECOMING.credits_available(game),
		"the personal travel receipt alone does not acknowledge the conversation")
	game.local.flags.set_flag(HOMECOMING.SEEN_FLAG)
	assert_true(HOMECOMING.credits_available(game))
	assert_true(HOMECOMING.credits_pending(game))
	game.local.flags.set_flag(HOMECOMING.CREDITS_SEEN_FLAG)
	assert_true(HOMECOMING.credits_available(game))
	assert_false(HOMECOMING.credits_pending(game))


func test_regional_credits_save_is_idempotent_and_player_local() -> void:
	var game := _credits_game()
	var world_before: bool = game.world.flags.has("stormwood:long_storm_ended")
	var party_before: int = game.party.members().size()
	assert_true(HOMECOMING.complete_credits(game, "character-homecoming"))
	assert_true(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.world.flags.has("stormwood:long_storm_ended"), world_before)
	assert_eq(game.party.members().size(), party_before)
	assert_false(HOMECOMING.credits_pending(game))
	assert_eq(game.save_system.calls, 1)
	assert_true(HOMECOMING.complete_credits(game, "character-homecoming"))
	assert_eq(game.save_system.calls, 1, "an acknowledged credits receipt is not saved again")
	var other := _credits_game()
	assert_false(other.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_true(HOMECOMING.credits_pending(other))


func test_regional_credits_save_failure_rolls_back_and_retries() -> void:
	var game := _credits_game()
	var world_before: bool = game.world.flags.has("stormwood:long_storm_ended")
	var party_before: int = game.party.members().size()
	game.save_system.result = false
	assert_false(HOMECOMING.complete_credits(game, "character-homecoming"))
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.world.flags.has("stormwood:long_storm_ended"), world_before)
	assert_eq(game.party.members().size(), party_before)
	assert_eq(game.save_system.calls, 1)
	assert_eq(game.messages, [HOMECOMING.CREDITS_SAVE_FAILURE_NOTICE])
	game.save_system.result = true
	assert_true(HOMECOMING.complete_credits(game, "character-homecoming"))
	assert_true(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.save_system.calls, 2)


func test_regional_credits_refuse_changed_character_realm_or_world_without_mutation() -> void:
	var game := _credits_game()
	assert_false(HOMECOMING.complete_credits(game, "different-character"))
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.save_system.calls, 0)
	game.local.realm = "water"
	assert_false(HOMECOMING.complete_credits(game, "character-homecoming"))
	assert_eq(game.save_system.calls, 0)
	game.local.realm = "meadows"
	game.local.redesign_character.transaction_receipts.clear()
	assert_false(HOMECOMING.complete_credits(game, "character-homecoming"))
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.save_system.calls, 0)


func _credits_game() -> GameStub:
	var game := GameStub.new()
	_home_return(game)
	game.local.flags.set_flag(HOMECOMING.SEEN_FLAG)
	return game


func test_terminal_consent_decline_is_not_completion_but_accept_is() -> void:
	var runner := RUNNER.new()
	var completed: Array[String] = []
	runner.completed.connect(func(id: String) -> void: completed.append(id))
	assert_true(runner.start("tournament_halda_signup"))
	runner.advance()
	runner.advance()
	runner.confirm(false)
	assert_true(completed.is_empty())
	assert_true(runner.start("tournament_halda_signup"))
	runner.advance()
	runner.advance()
	runner.confirm(true)
	assert_eq(completed, ["tournament_halda_signup"])


## Synthetic contract fixture: tests the receipt consumer, not actual Home travel.
func _home_return(game: GameStub) -> void:
	game.local.redesign_character.transaction_receipts.append(
		HOMECOMING.HOME_RETURN_PREFIX + "unit-world:" + game.local.character_id + ":unit-host-ticket")


func test_return_receipt_is_bound_to_its_character_and_requires_complete_identity() -> void:
	var game := GameStub.new()
	game.local.redesign_character.transaction_receipts = [
		HOMECOMING.HOME_RETURN_PREFIX + "world:other-character:ticket",
		HOMECOMING.HOME_RETURN_PREFIX + "world:" + game.local.character_id + ":",
		HOMECOMING.HOME_RETURN_PREFIX + ":" + game.local.character_id + ":ticket",
	]
	assert_false(HOMECOMING.eligible(game))
	_home_return(game)
	assert_true(HOMECOMING.eligible(game))
	var other := GameStub.new()
	assert_false(HOMECOMING.eligible(other), "another peer does not inherit the return")


func test_starter_and_memory_are_read_from_current_creatures_only() -> void:
	var party := PartyStub.new()
	var starter := Member.new("Terrapup", "Pip")
	starter.species_id = "terrapup"
	starter.landmarks_visited_together = 3
	party.rows = [starter]
	assert_true(HOMECOMING.starter_status(party).contains("Pip"))
	assert_true(HOMECOMING.bond_memory(party).contains("3 landmarks"))
	party.rows.clear()
	assert_true(HOMECOMING.starter_status(party).contains("no longer travelling"))
	assert_false(HOMECOMING.starter_status(party).contains("Pip"))
	assert_false(HOMECOMING.bond_memory(party).contains("3 landmarks"))


func test_chapter_choices_use_personal_answers_and_do_not_resurrect_companions() -> void:
	var game := GameStub.new()
	game.local.flags.set_flag("legendary_refused")
	game.local.flags.set_flag("cloudreach:legendary_joined")
	game.local.flags.set_flag("stormwood:legendary_answer:claim-a:refused")
	var choices := HOMECOMING.chapter_choices(game.local.flags)
	assert_true(choices.contains("Veridian stay behind"))
	assert_true(choices.contains("welcome Solmane"))
	assert_true(choices.contains("Stormheart choose its own road"))
	assert_false(choices.contains("came home"), "an accepted offer does not imply a retained creature")
