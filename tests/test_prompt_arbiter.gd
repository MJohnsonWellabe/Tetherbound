extends "res://tests/test_case.gd"

## Which of several things standing around the player gets the one prompt line.
##
## This is a new rule rather than a refactor: until now the game had exactly one
## prompt, hardcoded, so there was nothing to arbitrate. The opening puts Grandpa
## and three starters inside a few metres of each other, and every one of them
## wants that line.

const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")


func test_nothing_on_offer_draws_nothing() -> void:
	assert_true(ARBITER.choose([]).is_empty(), "an empty world offers nothing")
	assert_eq(ARBITER.format({}), "")
	assert_eq(ARBITER.choose_index([]), -1)


func test_the_nearest_thing_wins() -> void:
	var offers := [
		ARBITER.offer("Choose Terrapup", 2.9),
		ARBITER.offer("Talk to Grandpa", 1.4),
		ARBITER.offer("Choose Ripplet", 2.2),
	]
	assert_eq(str(ARBITER.choose(offers).get("label")), "Talk to Grandpa")
	assert_eq(ARBITER.choose_index(offers), 1)


## The beat the whole system exists for: three identical-looking offers a metre
## apart, and the player must be able to pick one by walking, not by luck.
func test_walking_between_the_starters_moves_the_prompt() -> void:
	var names := ["Terrapup", "Ripplet", "Galewisp"]
	# Distances as the player walks along the row, standing in front of each.
	var walks := [
		[0.8, 2.1, 3.6],
		[2.0, 0.7, 2.1],
		[3.7, 2.2, 0.9],
	]
	for i in walks.size():
		var offers: Array = []
		for j in names.size():
			offers.append(ARBITER.offer("Choose %s" % names[j], float(walks[i][j])))
		assert_eq(
			str(ARBITER.choose(offers).get("label")),
			"Choose %s" % names[i],
			"standing in front of %s should offer %s" % [names[i], names[i]]
		)


## Two bushes side by side produce byte-identical offers. Godot compares
## Dictionaries by value, so the winner has to be identified by index or the
## arbiter activates whichever equal offer happened to be registered first.
func test_identical_offers_are_still_told_apart_by_index() -> void:
	var offers := [
		ARBITER.offer("Pick berries", 4.0),
		ARBITER.offer("Pick berries", 1.2),
	]
	assert_eq(ARBITER.choose_index(offers), 1, "the nearer of two identical offers")


func test_priority_beats_proximity() -> void:
	var offers := [
		ARBITER.offer("Engage Bramblebun", 1.0),
		ARBITER.offer("Terrapup is out of the fight.", 0.0, 100, false),
	]
	var best := ARBITER.choose(offers)
	assert_eq(str(best.get("label")), "Terrapup is out of the fight.")
	assert_false(ARBITER.is_actionable(best), "a statement is not a button press")


func test_ties_go_to_the_first_registered() -> void:
	var offers := [
		ARBITER.offer("Talk to Grandpa", 2.0),
		ARBITER.offer("Choose Terrapup", 2.0),
	]
	assert_eq(ARBITER.choose_index(offers), 0, "an exact tie must be stable, not random")


func test_a_blank_label_is_not_an_offer() -> void:
	var offers := [
		ARBITER.offer("", 0.1),
		ARBITER.offer("Talk to Grandpa", 5.0),
	]
	assert_eq(str(ARBITER.choose(offers).get("label")), "Talk to Grandpa")
	assert_false(ARBITER.is_actionable(ARBITER.offer("", 0.0)))


## The drawn line has to keep the shape the combat HUD already renders, or every
## existing prompt jumps sideways the day arbitration goes in.
func test_an_actionable_offer_carries_the_button_glyph() -> void:
	var line := ARBITER.format(ARBITER.offer("Engage Bramblebun", 3.0))
	assert_eq(line, "[X] / [E]   Engage Bramblebun")


func test_a_statement_carries_no_button_glyph() -> void:
	var line := ARBITER.format(ARBITER.offer("Terrapup is out of the fight.", 0.0, 100, false))
	assert_eq(line, "Terrapup is out of the fight.")


func test_junk_in_the_offer_list_is_ignored_rather_than_fatal() -> void:
	var offers: Array = [null, 7, "nonsense", ARBITER.offer("Talk to Grandpa", 3.0)]
	assert_eq(str(ARBITER.choose(offers).get("label")), "Talk to Grandpa")
