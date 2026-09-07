extends "res://tests/test_case.gd"

const TRAINER_MODEL := preload("res://scripts/player/trainer_model.gd")

class FakeLocal:
	extends RefCounted
	var chosen_character: String = "trainer"

class FakeGame:
	extends RefCounted
	var local: RefCounted = null


func _game() -> RefCounted:
	var game := FakeGame.new()
	game.local = FakeLocal.new()
	return game


func test_local_model_reads_the_choice_from_game_local() -> void:
	var game := _game()
	game.local.chosen_character = "lyra"
	assert_eq(TRAINER_MODEL.resolved_appearance_id("", game), "lyra")


func test_remote_spawn_choice_wins_over_the_viewers_local_choice() -> void:
	var game := _game()
	game.local.chosen_character = "kael"
	assert_eq(TRAINER_MODEL.resolved_appearance_id("sera", game), "sera")


func test_missing_choice_keeps_the_original_trainer_fallback() -> void:
	var game := _game()
	game.local.chosen_character = ""
	assert_eq(TRAINER_MODEL.resolved_appearance_id("", game), "trainer")
	assert_eq(TRAINER_MODEL.resolved_appearance_id("", null), "trainer")
