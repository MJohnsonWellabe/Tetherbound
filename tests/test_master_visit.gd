extends "res://tests/test_case.gd"
const VISIT := preload("res://tools/earned_saves/master_visit.gd")

class ChestPrompt extends Node3D:
	signal activated

func test_chest_geometry_is_not_an_interaction_prompt() -> void:
	var site := Node3D.new()
	var chest := Node3D.new()
	chest.name = "RecipeChest"
	site.add_child(chest)
	chest.add_child(Node3D.new())
	assert_eq(VISIT.chest_prompt(site), null)
	var prompt := ChestPrompt.new()
	chest.add_child(prompt)
	assert_eq(VISIT.chest_prompt(site), prompt)
	site.free()
	assert_eq(VISIT.chest_prompt(null), null)

func test_rebuilt_site_supplies_new_prompt() -> void:
	var site := Node3D.new()
	var chest := Node3D.new()
	chest.name = "RecipeChest"
	site.add_child(chest)
	var old_prompt := ChestPrompt.new()
	chest.add_child(old_prompt)
	assert_eq(VISIT.chest_prompt(site), old_prompt)
	old_prompt.free()
	var new_prompt := ChestPrompt.new()
	chest.add_child(new_prompt)
	assert_eq(VISIT.chest_prompt(site), new_prompt)
	site.free()

func test_failed_pilot_stops_and_preserves_round_receipt() -> void:
	for failure: Dictionary in [{"passed": false, "failures": ["body lost"]},
			{"ok": false}, {"outcome": "running", "timed_out": true}]:
		var visit := VISIT.new()
		var rounds: Array = [{"outcome": "previous round"}]
		assert_false(visit._record_round(failure, rounds), "caller must return before polling or invoking the pilot again")
		assert_eq(rounds.size(), 2)
		assert_eq(visit.failures.size(), 1)
		assert_eq(visit.receipts.size(), 1)
		assert_eq(visit.receipts[0].beat, "duel_rounds")
		assert_eq(visit.receipts[0].results[1], failure)
		failure["later_mutation"] = true
		assert_false(visit.receipts[0].results[1].has("later_mutation"), "failed evidence is retained independently")

func test_success_and_legacy_diagnostics_still_require_saved_master_win() -> void:
	for result: Dictionary in [{"passed": true}, {"ok": true},
			{"outcome": "won", "timed_out": false}]:
		var visit := VISIT.new()
		var rounds: Array = []
		assert_true(visit._record_round(result, rounds))
		assert_eq(rounds.size(), 1)
		assert_true(visit.failures.is_empty())
		assert_true(visit.receipts.is_empty(), "a callback alone is not a saved Master win")
