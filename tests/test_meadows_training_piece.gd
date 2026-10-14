extends "res://tests/test_case.gd"
const PIECE := preload("res://tools/earned_saves/wip_fights/meadows_training_piece.gd")

func _snapshot() -> Dictionary:
	var party: Array = []
	for i in 5:
		party.append({"uid": "creature-%032x" % i, "species": "mudsnout", "level": 20, "xp": 0,
			"cap_level": 20, "breakthroughs": [1], "evolution_choices": {}})
	return {"version": 1, "party": party, "master_wins": ["master_t1", "master_t2"], "feast_recipes": ["feast_t1", "feast_t2"]}

func test_piece_refuses_unearned_cap_or_missing_master_chest() -> void:
	assert_true(PIECE.preflight(_snapshot(), 2, "feed").is_empty())
	var state := _snapshot()
	state.party[4].level = 19
	assert_false(PIECE.preflight(state, 2, "feed").is_empty())
	state = _snapshot()
	state.party[4].uid = state.party[0].uid
	assert_false(PIECE.preflight(state, 2, "master").is_empty())
	state = _snapshot()
	state.feast_recipes = ["feast_t1"]
	assert_false(PIECE.preflight(state, 2, "feed").is_empty())

func test_feed_requires_all_five_next_caps_without_xp_or_identity_changes() -> void:
	var before := _snapshot()
	var after := _snapshot()
	for card: Dictionary in after.party:
		card.cap_level = 30
		card.breakthroughs = [1, 2]
		card.evolution_choices = {"2": "stay"}
	assert_true(PIECE.postflight(before, after, 2, "feed").is_empty())
	after.party[4].cap_level = 20
	assert_false(PIECE.postflight(before, after, 2, "feed").is_empty())
	after.party[4].cap_level = 30
	after.party[0].xp = 1
	assert_false(PIECE.postflight(before, after, 2, "feed").is_empty())

func test_feed_rejects_extra_progression_fields_and_changed_choice_history() -> void:
	var before := _snapshot()
	var after := _snapshot()
	for card: Dictionary in after.party:
		card.cap_level = 30
		card.breakthroughs = [1, 2]
		card.evolution_choices = {"2": "stay"}
	assert_true(PIECE.postflight(before, after, 2, "feed").is_empty())
	after.party[4].taught_traits = {"attack": 1}
	assert_false(PIECE.postflight(before, after, 2, "feed").is_empty())
	after.party[4].erase("taught_traits")
	after.party[4].evolution_choices["1"] = "stay"
	assert_false(PIECE.postflight(before, after, 2, "feed").is_empty())
	after.party[4].evolution_choices.erase("1")
	after.party[4].species = "tuskroot"
	assert_false(PIECE.postflight(before, after, 2, "feed").is_empty())

func test_matched_evolve_retains_other_stay_choices_and_prior_master_history() -> void:
	var before := _snapshot()
	var after := _snapshot()
	for card: Dictionary in after.party:
		card.cap_level = 30
		card.breakthroughs = [1, 2]
		card.evolution_choices = {"2": "stay"}
	var uid := str(before.party[0].uid)
	after.party[0].species = "tuskroot"
	after.party[0].evolution_choices = {"2": "tuskroot"}
	assert_true(PIECE.postflight(before, after, 2, "feed", {uid: "evolve"}).is_empty())
	after.master_wins = ["master_t2"]
	assert_false(PIECE.postflight(before, after, 2, "feed", {uid: "evolve"}).is_empty())
	after.master_wins = before.master_wins.duplicate()
	after.feast_recipes.append("feast_t3")
	assert_false(PIECE.postflight(before, after, 2, "feed", {uid: "evolve"}).is_empty())
