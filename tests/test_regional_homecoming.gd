extends "res://tests/test_case.gd"

const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const SEQUENCE_DIRECTOR := preload("res://scripts/story/sequence_director.gd")
const DIALOGUE_PANEL := preload("res://scripts/ui/dialogue_panel.gd")
const OWNER := preload("res://tests/fixtures/regional_ending_owner.gd")


class GameStub:
	extends "res://tests/fixtures/regional_ending_owner.gd"


class PendingOwner:
	extends Node
	var delegate: RefCounted = OWNER.new()
	var local: RefCounted:
		get: return delegate.local
	var party: RefCounted:
		get: return delegate.party
	var pending_intent: Dictionary = {}
	var polls := 0
	var change_session_on_poll := false

	func regional_ending_context() -> Dictionary:
		return delegate.regional_ending_context()

	func commit_regional_ending_ack(intent: Dictionary) -> Dictionary:
		pending_intent = intent.duplicate(true)
		return {"status": "pending"}

	func regional_ending_ack_result(_id: String) -> Dictionary:
		polls += 1
		if change_session_on_poll:
			delegate.session_epoch = "reconnected"
			return {"status": "rejected"}
		return delegate.commit_regional_ending_ack(pending_intent)

	func push_world_message(message: String) -> void:
		delegate.push_world_message(message)


func test_runtime_hooks_compile() -> void:
	var sequence: Node = SEQUENCE_DIRECTOR.new()
	var panel: CanvasLayer = DIALOGUE_PANEL.new()
	assert_true(sequence != null)
	assert_true(panel != null)
	sequence.free()
	panel.free()


func test_shared_finale_does_not_unlock_homecoming_for_a_nonparticipant() -> void:
	var game := GameStub.new()
	assert_eq(HOMECOMING.conversation_id(game), "")
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	assert_eq(HOMECOMING.conversation_id(game), "",
		"an ahead world cannot manufacture a personal accepted finale")
	game.accepted_outcome = true
	assert_eq(HOMECOMING.conversation_id(game), "regional_homecoming_0",
		"a canonical personal accepted outcome is required")
	game.local.flags.set_flag(HOMECOMING.SEEN_FLAG)
	assert_eq(HOMECOMING.conversation_id(game), HOMECOMING.REPEAT_ID)


func test_live_party_names_and_refusal_of_an_invalid_sixth() -> void:
	var party := OWNER.PartyStub.new()
	party.rows = [
		OWNER.Member.new("Terrapup", "Pip"), OWNER.Member.new("Brooktail"),
		OWNER.Member.new("Galecrest", "Sky"), OWNER.Member.new("Mosshell"),
		OWNER.Member.new("Solmane", "Sunny"),
	]
	assert_eq(HOMECOMING.party_names(party), ["Pip", "Brooktail", "Sky", "Mosshell", "Sunny"])
	var game := GameStub.new()
	game.party = party
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	game.accepted_outcome = true
	assert_eq(HOMECOMING.conversation_id(game), "regional_homecoming_5")
	assert_eq(HOMECOMING.substitutions(game).get("party_5"), "Sunny")
	assert_false(HOMECOMING.substitutions(game).has("party_6"))
	party.rows.append(OWNER.Member.new("Sixth", "Never shown"))
	assert_false(HOMECOMING.valid_party(party))
	assert_eq(HOMECOMING.conversation_id(game), "")


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
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	game.accepted_outcome = true
	game.save_system.result = false
	assert_false(await HOMECOMING.complete(game, "character-homecoming", HOMECOMING.context(game)))
	assert_false(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	assert_eq(game.save_system.saved_character, "character-homecoming")
	assert_eq(game.messages, [HOMECOMING.SAVE_FAILURE_NOTICE])
	game.save_system.result = true
	assert_true(await HOMECOMING.complete(game, "character-homecoming", HOMECOMING.context(game)))
	assert_true(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	assert_eq(game.save_system.calls, 2)
	assert_eq(HOMECOMING.conversation_id(game), HOMECOMING.REPEAT_ID)


func test_homecoming_seen_is_player_scoped() -> void:
	PROGRESSION.reload_scopes()
	assert_eq(PROGRESSION.scope_of(HOMECOMING.SEEN_FLAG), "player")
	assert_eq(PROGRESSION.scope_of(HOMECOMING.CREDITS_SEEN_FLAG), "player")


func test_completion_rechecks_realm_and_character_identity() -> void:
	var game := GameStub.new()
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	game.accepted_outcome = true
	game.local.realm = "water"
	assert_false(await HOMECOMING.complete(game, "character-homecoming", HOMECOMING.context(game)))
	game.local.realm = "meadows"
	game.local.character_id = "character-loaded-after-start"
	assert_false(await HOMECOMING.complete(game, "character-homecoming", HOMECOMING.context(game)))
	assert_false(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	assert_eq(game.save_system.calls, 0)


func test_regional_credits_require_homecoming_current_world_and_pending_receipt() -> void:
	var game := GameStub.new()
	assert_false(HOMECOMING.credits_available(game))
	assert_false(HOMECOMING.credits_pending(game))
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	assert_false(HOMECOMING.credits_available(game),
		"the shared finale does not manufacture a personal credits receipt")
	game.accepted_outcome = true
	game.local.flags.set_flag(HOMECOMING.SEEN_FLAG)
	assert_true(HOMECOMING.credits_available(game))
	assert_true(HOMECOMING.credits_pending(game))
	game.local.flags.set_flag(HOMECOMING.CREDITS_SEEN_FLAG)
	assert_true(HOMECOMING.credits_available(game))
	assert_false(HOMECOMING.credits_pending(game))


func test_regional_credits_save_is_idempotent_and_player_local() -> void:
	var game := _credits_game()
	var world_before: bool = game.world.flags.has(HOMECOMING.WORLD_FLAG)
	var party_before: int = game.party.members().size()
	assert_true(await HOMECOMING.complete_credits(game, "character-homecoming", HOMECOMING.context(game)))
	assert_true(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.world.flags.has(HOMECOMING.WORLD_FLAG), world_before)
	assert_eq(game.party.members().size(), party_before)
	assert_false(HOMECOMING.credits_pending(game))
	assert_eq(game.save_system.calls, 1)
	assert_true(await HOMECOMING.complete_credits(game, "character-homecoming", HOMECOMING.context(game)))
	assert_eq(game.save_system.calls, 1, "an acknowledged credits receipt is not saved again")
	var other := _credits_game()
	assert_false(other.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_true(HOMECOMING.credits_pending(other))


func test_regional_credits_save_failure_rolls_back_and_retries() -> void:
	var game := _credits_game()
	var world_before: bool = game.world.flags.has(HOMECOMING.WORLD_FLAG)
	var party_before: int = game.party.members().size()
	game.save_system.result = false
	assert_false(await HOMECOMING.complete_credits(game, "character-homecoming", HOMECOMING.context(game)))
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.world.flags.has(HOMECOMING.WORLD_FLAG), world_before)
	assert_eq(game.party.members().size(), party_before)
	assert_eq(game.save_system.calls, 1)
	assert_eq(game.messages, [HOMECOMING.CREDITS_SAVE_FAILURE_NOTICE])
	game.save_system.result = true
	assert_true(await HOMECOMING.complete_credits(game, "character-homecoming", HOMECOMING.context(game)))
	assert_true(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.save_system.calls, 2)


func test_regional_credits_refuse_changed_character_realm_or_world_without_mutation() -> void:
	var game := _credits_game()
	assert_false(await HOMECOMING.complete_credits(game, "different-character", HOMECOMING.context(game)))
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.save_system.calls, 0)
	game.local.realm = "water"
	assert_false(await HOMECOMING.complete_credits(game, "character-homecoming", HOMECOMING.context(game)))
	assert_eq(game.save_system.calls, 0)
	game.local.realm = "meadows"
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG, false)
	assert_false(await HOMECOMING.complete_credits(game, "character-homecoming", HOMECOMING.context(game)))
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))
	assert_eq(game.save_system.calls, 0)


func _credits_game() -> GameStub:
	var game := GameStub.new()
	game.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	game.local.flags.set_flag(HOMECOMING.SEEN_FLAG)
	game.accepted_outcome = true
	return game


func test_home_key_arrival_farm_and_safe_context_are_required() -> void:
	var game := _credits_game()
	game.durable_home_return = false
	assert_false(HOMECOMING.eligible(game))
	game.durable_home_return = true
	game.at_farm = false
	assert_false(HOMECOMING.eligible(game))
	game.at_farm = true
	game.safe = false
	assert_false(HOMECOMING.eligible(game))
	game.safe = true
	game.home_return_receipt = " "
	assert_false(HOMECOMING.eligible(game))
	assert_eq(game.save_system.calls, 0)


func test_stale_world_session_roster_names_and_memory_cannot_acknowledge() -> void:
	for field: String in ["world_instance_id", "session_epoch", "outcome_id", "home_return_receipt"]:
		var game := _credits_game()
		var frozen := HOMECOMING.context(game)
		game.set(field, "changed")
		assert_false(await HOMECOMING.complete_credits(game, game.local.character_id, frozen), field)
		assert_eq(game.save_system.calls, 0)
	var game := _credits_game()
	game.party.rows = [OWNER.Member.new("Terrapup", "Pip")]
	var frozen := HOMECOMING.context(game)
	game.party.rows[0].nickname = "Renamed"
	assert_false(HOMECOMING.context_matches(game, frozen), "nickname edits can bypass party revision")
	game.party.rows[0].nickname = "Pip"
	game.party.rows[0].battles_fought += 1
	assert_false(HOMECOMING.context_matches(game, frozen), "bond counters are also spoken context")
	game.party.rows[0].battles_fought = 0
	game.party.revision += 1
	assert_false(await HOMECOMING.complete_credits(game, game.local.character_id, frozen))
	assert_eq(game.save_system.calls, 0)


func test_receipt_requires_matching_durable_typed_envelope() -> void:
	var game := _credits_game()
	var intent := HOMECOMING.acknowledgement_intent(HOMECOMING.context(game), HOMECOMING.CREDITS_SEEN_FLAG)
	var receipt := intent.duplicate(true)
	receipt.merge({"status": "committed", "durable": true})
	assert_true(HOMECOMING.receipt_matches(receipt, intent))
	assert_false(HOMECOMING.receipt_matches(true, intent), "bool save success alone is not an owner receipt")
	assert_false(HOMECOMING.receipt_matches({"status": "committed", "durable": true}, {"unexpected": true}))
	for field: String in HOMECOMING.CONTEXT_FIELDS:
		var wrong := receipt.duplicate(true)
		wrong[field] = -1 if field == "party_revision" else "wrong"
		assert_false(HOMECOMING.receipt_matches(wrong, intent), field)
	for field: String in ["transaction_id", "stage", "status", "durable"]:
		var wrong := receipt.duplicate(true)
		wrong[field] = false if field == "durable" else "wrong"
		assert_false(HOMECOMING.receipt_matches(wrong, intent), field)
	game.bool_only = true
	assert_false(await HOMECOMING.complete_credits(game, game.local.character_id, HOMECOMING.context(game)))
	assert_eq(game.save_system.calls, 0)
	assert_false(game.local.flags.has(HOMECOMING.CREDITS_SEEN_FLAG))


func test_pending_owner_acknowledgement_waits_for_receipt() -> void:
	var game := PendingOwner.new()
	game.delegate.accepted_outcome = true
	game.delegate.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(game)
	var frozen := HOMECOMING.context(game)
	assert_true(await HOMECOMING.complete(game, game.local.character_id, frozen))
	assert_eq(game.polls, 1)
	assert_eq(game.delegate.save_system.calls, 1)
	assert_true(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	game.free()


func test_pending_owner_result_cannot_cross_reconnect_generation() -> void:
	var game := PendingOwner.new()
	game.delegate.accepted_outcome = true
	game.delegate.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	game.change_session_on_poll = true
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(game)
	var frozen := HOMECOMING.context(game)
	assert_false(await HOMECOMING.complete(game, game.local.character_id, frozen))
	assert_eq(game.delegate.save_system.calls, 0)
	assert_false(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	game.free()


func test_live_starter_bond_and_choices_are_personal_and_truthful() -> void:
	var game := _credits_game()
	game.party.rows = [OWNER.Member.new("Terrapup", "Pip"), OWNER.Member.new("Mosshell", "Shelby")]
	game.party.rows[1].landmarks_visited_together = 3
	var values := HOMECOMING.substitutions(game)
	assert_true(str(values.starter_status).contains("Pip"))
	assert_true(str(values.bond_memory).contains("Shelby") and str(values.bond_memory).contains("3"))
	assert_true(str(values.chapter_choices).contains("let Veridian"))
	assert_true(str(values.chapter_choices).contains("welcomed the Abyssal Guardian"))
	assert_false(str(values.chapter_choices).contains("Solmane"))
	game.party.rows.remove_at(0)
	game.party.revision += 1
	assert_false(str(HOMECOMING.substitutions(game).starter_status).contains("Pip"))
	assert_false(HOMECOMING.substitutions(game).has("party_2"))
	game.chapter_choices.append("meadows:accepted")
	assert_false(HOMECOMING.eligible(game), "contradictory chapter choices are rejected")


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
