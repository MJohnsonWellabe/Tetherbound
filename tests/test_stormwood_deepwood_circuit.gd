extends "res://tests/test_case.gd"

const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const ENCOUNTER_HUB := preload("res://scripts/world/stormwood_encounter_hub.gd")
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const CHAPTER_PATH := "res://data/config/stormwood_chapter.json"


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CHAPTER_PATH)) as Dictionary


func _circuit_specs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for spec: Dictionary in CATALOGUE.trainer_specs():
		if str(spec.get("group", "")) == "deepwood_circuit":
			spec["defeat_flag"] = "stormwood:trainer:%s:defeated" % str(spec.id)
			out.append(spec)
	return out


func test_any_three_distinct_production_trainers_advance_real_quest_events() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:lantern_hollow_reached")
	var entries: Array = LOGIC.side_entries(flags, chapter)
	var circuit: Dictionary = entries.filter(func(row: Dictionary) -> bool:
		return str(row.id) == "stormwood_deepwood_circuit")[0]
	assert_eq(circuit.how, "Accept Rook's circuit at Lantern Hollow.")
	assert_true(LOGIC.dispatch(flags, chapter, "side:stormwood_deepwood_circuit:step_1").changed)
	assert_false(LOGIC.dispatch(flags, chapter, "side:stormwood_deepwood_circuit:step_2").changed,
		"The aggregate step cannot be completed without real trainer-win facts")
	var specs := _circuit_specs()
	assert_eq(specs.size(), 5, "The authored trainer group remains the selection source")
	var first_event := ENCOUNTER_HUB.circuit_count_event(specs[0])
	assert_true(LOGIC.dispatch(flags, chapter, first_event).changed)
	assert_false(LOGIC.dispatch(flags, chapter, first_event).changed, "A repeat win cannot credit twice")
	assert_true(LOGIC.dispatch(flags, chapter, ENCOUNTER_HUB.circuit_count_event(specs[1])).changed)
	assert_false(flags.has("stormwood:side_deepwood_circuit_2"))
	assert_true(LOGIC.dispatch(flags, chapter, ENCOUNTER_HUB.circuit_count_event(specs[2])).changed)
	assert_true(flags.has("stormwood:side_deepwood_circuit_2"))
	circuit = LOGIC.side_entries(flags, chapter).filter(func(row: Dictionary) -> bool:
		return str(row.id) == "stormwood_deepwood_circuit")[0]
	assert_eq(circuit.how, "Return to Rook for the circuit's acknowledgement.")
	assert_true(LOGIC.dispatch(flags, chapter, "side:stormwood_deepwood_circuit:step_3").changed)
	assert_true(flags.has("stormwood:side_deepwood_circuit_complete"))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	assert_true(loaded.has("stormwood:side_deepwood_circuit_complete"), "Circuit completion survives save/load")


func test_acceptance_credits_earlier_authored_trainer_wins() -> void:
	var specs := _circuit_specs()
	var authored := {}
	var flags := PROGRESSION.new()
	for spec: Dictionary in specs:
		authored[str(spec.id)] = spec
	flags.set_flag(str(specs[1].defeat_flag))
	flags.set_flag(str(specs[4].defeat_flag))
	var events := CHAPTER_RUNTIME.circuit_win_events(authored, flags)
	assert_eq(events.size(), 2)
	assert_true(events.has(ENCOUNTER_HUB.circuit_count_event(specs[1])))
	assert_true(events.has(ENCOUNTER_HUB.circuit_count_event(specs[4])))


func test_completed_circuit_preserves_rooks_prior_dialogue_fallback() -> void:
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:chapter_started")
	flags.set_flag("stormwood:side_deepwood_circuit_1")
	flags.set_flag("stormwood:side_deepwood_circuit_2")
	flags.set_flag("stormwood:side_deepwood_circuit_complete")
	var spec := CHAPTER_RUNTIME.npc_spec({"id": "ace_trainer_rook", "name": "Rook",
		"body_profile": "rival_trainer", "position": [-150, 61.14, 4460]})
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_ace_trainer_rook_in_progress",
		"Completing the side quest must not remove Rook's prior story dialogue")
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_ace_trainer_rook_post_storm")
