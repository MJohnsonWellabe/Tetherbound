extends "res://tests/test_case.gd"

const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const ARCH_RUNTIME := preload("res://scripts/world/stormwood_arch_runtime.gd")
const RULES := preload("res://scripts/world/stormwood_arch_rules.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const CHAIN := "stormwood_dark_arches"


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json")) as Dictionary


func _entry(flags: RefCounted, chapter: Dictionary) -> Dictionary:
	for row: Dictionary in LOGIC.side_entries(flags, chapter):
		if str(row.id) == CHAIN:
			return row
	return {}


func test_dark_arches_are_pairs_c_and_d_outside_every_main_objective() -> void:
	var pairs := {}
	for id: String in ARCH_RUNTIME.DARK_ARCHES:
		var arch := RULES.definition(id)
		assert_false(arch.is_empty(), "%s is an authored ancient arch" % id)
		assert_false(bool(arch.get("starts_lit", false)))
		assert_eq(str(arch.get("requires_flag", "")), "stormwood:rootgate_released")
		pairs[str(arch.pair)] = int(pairs.get(str(arch.pair), 0)) + 1
	assert_eq(pairs, {"c": 2, "d": 2}, "Both ends of pairs C and D, nothing else")
	var main_events := JSON.stringify(_chapter().acts)
	for pair: String in ["pair_c", "pair_d", "c_rodline", "c_lantern", "d_hall", "d_giant"]:
		assert_false(main_events.contains(pair), "Main story objectives never require %s" % pair)
	assert_eq(ARCH_RUNTIME.dark_inspection_event("a_ashfoot"), "", "Story arches are not dark-arch inspections")


func test_inspection_paid_relights_and_hesk_complete_the_chain() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	assert_true(_entry(flags, chapter).is_empty())
	flags.set_flag("stormwood:ashfoot_arch_relit")
	assert_eq(_entry(flags, chapter).how, "Inspect a dark ancient arch beyond the Rootgate.")
	assert_false(LOGIC.dispatch(flags, chapter, "side:%s:step_1" % CHAIN).changed,
		"The aggregate inspection event cannot skip an arch visit")
	assert_true(LOGIC.dispatch(flags, chapter, ARCH_RUNTIME.dark_inspection_event("d_hall")).changed)
	assert_true(flags.has("stormwood:side_dark_arches_1"))
	assert_false(LOGIC.dispatch(flags, chapter, ARCH_RUNTIME.dark_inspection_event("d_hall")).changed,
		"The same arch cannot be inspected twice")
	assert_false(LOGIC.dispatch(flags, chapter, "count:" + RULES.lit_flag("d_hall")).changed,
		"No chain step declares a paid arch lit flag as a count fact")
	assert_false(flags.has(RULES.lit_flag("d_hall")))
	for id: String in ["c_rodline", "c_lantern", "d_hall"]:
		flags.set_flag(RULES.lit_flag(id))
	assert_false(ARCH_RUNTIME.dark_arches_relit(flags), "Three lit ends are not both pairs")
	flags.set_flag(RULES.lit_flag("d_giant"))
	assert_true(ARCH_RUNTIME.dark_arches_relit(flags))
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed)
	assert_eq(_entry(flags, chapter).how, "Show Hesk that the old roads are connected.")
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_3" % CHAIN).changed)
	assert_true(flags.has("stormwood:side_dark_arches_complete"))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	assert_true(loaded.has("stormwood:side_dark_arches_inspected:d_hall"))
	assert_true(loaded.has("stormwood:side_dark_arches_complete"))


func test_inspection_facts_are_declared_world_state() -> void:
	var chapter := _chapter()
	var expected: Array = []
	for id: String in ARCH_RUNTIME.DARK_ARCHES:
		var flag := ARCH_RUNTIME.dark_inspection_event(id).trim_prefix("count:")
		expected.append(flag)
		assert_eq(PROGRESSION.scope_of(flag), PROGRESSION.SCOPE_WORLD)
		assert_true((chapter.persistent_flags.side_content as Array).has(flag))
	for chain: Dictionary in chapter.side_chains:
		if str(chain.id) == CHAIN:
			assert_eq(chain.steps[0].count_flags, expected)
			assert_eq(int(chain.steps[0].required_count), 1)
			assert_false((chain.steps[1] as Dictionary).has("count_flags"),
				"Step 2 follows the ledger's lit flags; it declares no writable count facts")


func test_hesk_report_outranks_ordinary_lines_only_while_owed() -> void:
	var spec := CHAPTER_RUNTIME.npc_spec({"id": "rodkeeper_hesk", "name": "Rodkeeper Hesk",
		"body_profile": "local_historian", "position": [-350, 30.31, 450]})
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:chapter_started")
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_rodkeeper_hesk_in_progress")
	flags.set_flag("stormwood:side_dark_arches_1")
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_rodkeeper_hesk_in_progress")
	flags.set_flag("stormwood:side_dark_arches_2")
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(spec, flags), CHAPTER_RUNTIME.HESK_DARK_ARCHES_REPORT)
	flags.set_flag("stormwood:side_dark_arches_complete")
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_rodkeeper_hesk_post_storm")
	var dialogue: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	assert_true(dialogue.has(CHAPTER_RUNTIME.HESK_DARK_ARCHES_REPORT))


func test_arches_lit_before_the_chain_was_wired_still_count_as_inspected() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	for id: String in ARCH_RUNTIME.DARK_ARCHES:
		flags.set_flag(RULES.lit_flag(id))
	assert_true(ARCH_RUNTIME.owed_dark_inspections(flags).is_empty(), "Nothing is owed before the chain is revealed")
	flags.set_flag("stormwood:ashfoot_arch_relit")
	var owed := ARCH_RUNTIME.owed_dark_inspections(flags)
	assert_eq(owed.size(), 4)
	for event: String in owed:
		LOGIC.dispatch(flags, chapter, event)
	assert_true(flags.has("stormwood:side_dark_arches_1"), "An old all-lit save reaches step 1")
	assert_true(ARCH_RUNTIME.owed_dark_inspections(flags).is_empty())
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed,
		"and its already-paid relights complete step 2")
