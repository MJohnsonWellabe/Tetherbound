extends TestCase


func _steps(segment: String) -> Dictionary:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tools/gate_f/segments/%s.json" % segment))
	var result := {}
	for step: Dictionary in doc.steps:
		result[str(step.id).trim_prefix(segment + "-")] = step
	return result


func test_bram_completion_requires_his_production_victory_before_recovery() -> void:
	var trainers: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/bands/band1_lower_meadows/trainers.json"))
	var flag := ""
	for trainer: Dictionary in trainers.trainers:
		if str(trainer.id) == "old_champion_bram":
			flag = str(trainer.defeat_flag)
	assert_false(flag.is_empty())
	for segment: String in ["S05", "S05C"]:
		var steps := _steps(segment)
		assert_eq(steps["37"].action, "fight_until_resolved")
		assert_eq(steps["37"].args.until_flag, flag,
			"first-round victory and trainer loss must not count as beating Bram")
		assert_true(int(steps["37"].args.budget_frames) > 0)
		assert_true(float(steps["37"].args.switch_below) > 0.0)
		assert_eq(steps["37b"].action, "assert")
		assert_eq(steps["37b"].args.flag, flag)
		assert_eq(steps["38"].action, "wait")
		assert_eq(steps["38b"].args.control, "party_cycle")


func test_trainer_dialogue_stops_at_context_handoff_in_both_evidence_lanes() -> void:
	var cases := {"S05": ["46"], "S05C": ["46"],
		"S10a": ["18", "30", "44"], "S10aC": ["18"],
		"S10b": ["56"], "S10bC": ["56"]}
	for segment: String in cases:
		var steps := _steps(segment)
		for id: String in cases[segment]:
			assert_eq(steps[id].action, "advance_dialogue_until_closed",
				"%s-%s must stop when dialogue yields to combat" % [segment, id])
			assert_true(int(steps[id].args.max_presses) > 0)
			assert_false(steps[id].args.has("times"))


func test_bridge_handoffs_require_pressure_and_actual_pilot_changes() -> void:
	for segment: String in ["S05", "S05C"]:
		var steps := _steps(segment)
		for id: String in ["51", "51c", "51e"]:
			assert_eq(steps[id].action, "combat_checkpoint")
		for id: String in ["51b", "51d", "51f"]:
			assert_eq(steps[id].args.control, "party_cycle")
			assert_true(steps[id].args.verify_switch)
		assert_eq(steps["52"].action, "charged_hit")
		assert_eq(steps["53"].action, "fight_until_resolved")
		assert_eq(steps["53"].args.until_flag, "defeated_south_bridge_grunt")
		assert_eq(steps["54c"].args.control, "interact")
		assert_eq(steps["55"].args.flag, "south_bridge_open")
