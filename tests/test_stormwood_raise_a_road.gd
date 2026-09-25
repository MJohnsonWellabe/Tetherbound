extends "res://tests/test_case.gd"

const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const ARCH_RUNTIME := preload("res://scripts/world/stormwood_arch_runtime.gd")
const BUILT := preload("res://scripts/world/stormwood_arch_build_rules.gd")
const RULES := preload("res://scripts/world/stormwood_arch_rules.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const CHAIN := "stormwood_raise_a_road"


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json")) as Dictionary


func _entry(flags: RefCounted, chapter: Dictionary) -> Dictionary:
	for row: Dictionary in LOGIC.side_entries(flags, chapter):
		if str(row.id) == CHAIN:
			return row
	return {}


func _arch(uid: String, footing: String, twin: String, x: float) -> Dictionary:
	return {"id": "stormglass_arch", "realm": "stormwood", "uid": uid,
		"position": [x, 0.0, 0.0], "arch_footing": footing, "arch_twin": twin}


func test_road_footings_are_the_optional_sockets_and_never_the_crown() -> void:
	var sockets := {}
	for socket: Dictionary in RULES.config().footings:
		sockets[str(socket.id)] = socket
	for footing: String in BUILT.ROAD_FOOTINGS:
		assert_true(sockets.has(footing), "%s is an authored footing" % footing)
		assert_false((sockets[footing] as Dictionary).has("fixed_twin"), "%s is optional" % footing)
	assert_false(BUILT.ROAD_FOOTINGS.has("still_grove"), "The mandatory Crown footing is never a road choice")
	var flags := PROGRESSION.new()
	flags.set_flag("stormwood:arch_recipe_known")
	flags.set_flag(BUILT.ROAD_CHOSEN_PREFIX + "verge_road")
	flags.set_flag(BUILT.ROAD_CHOSEN_PREFIX + "hollows_road")
	var crown_pair: Array = [_arch("grove", "still_grove", "e_crown", 1.0)]
	assert_true(BUILT.chosen_road(flags, crown_pair).is_empty(), "The Crown pair cannot satisfy the side chain")


func test_choose_build_travel_and_report_complete_the_chain() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	assert_true(_entry(flags, chapter).is_empty())
	flags.set_flag("stormwood:arch_recipe_known")
	assert_eq(_entry(flags, chapter).how, "Choose two optional ancient footings.")
	assert_eq(ARCH_RUNTIME.footing_prompt_label("verge_road", flags), "Choose this footing for your road")
	assert_eq(ARCH_RUNTIME.footing_prompt_label("deepwood_road", flags), "Inspect the old arch footing",
		"The Deepwood footing cannot be chosen before the Rootgate opens")
	assert_eq(ARCH_RUNTIME.footing_prompt_label("still_grove", flags), "Inspect the shattered Crown footing")
	for step: String in ["step_1", "step_3"]:
		assert_false(LOGIC.dispatch(flags, chapter, "side:%s:%s" % [CHAIN, step]).changed,
			"The aggregate %s event cannot skip its facts" % step)
	assert_true(LOGIC.dispatch(flags, chapter, "count:" + BUILT.ROAD_CHOSEN_PREFIX + "verge_road").changed)
	assert_false(flags.has("stormwood:side_raise_a_road_1"), "One footing is not a road")
	assert_eq(ARCH_RUNTIME.footing_prompt_label("verge_road", flags), "Your chosen road footing")
	assert_true(LOGIC.dispatch(flags, chapter, "count:" + BUILT.ROAD_CHOSEN_PREFIX + "capacitor_grove").changed)
	assert_true(flags.has("stormwood:side_raise_a_road_1"), "Choosing is recorded before anything is built")
	assert_eq(ARCH_RUNTIME.footing_prompt_label("hollows_road", flags), "Inspect the old arch footing",
		"No third footing is offered once two are chosen")
	# A pair on one chosen and one unchosen footing is not the chosen road.
	var wrong: Array = [_arch("u1", "verge_road", "u2", 1.0), _arch("u2", "hollows_road", "u1", 2.0)]
	assert_true(BUILT.chosen_road(flags, wrong).is_empty())
	var half: Array = [_arch("u1", "verge_road", "", 1.0)]
	assert_true(BUILT.chosen_road(flags, half).is_empty(), "An unbound arch is not a road")
	var road: Array = [_arch("u1", "verge_road", "u3", 1.0), _arch("u3", "capacitor_grove", "u1", 3.0)]
	assert_false(BUILT.chosen_road(flags, road).is_empty())
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_2" % CHAIN).changed)
	assert_eq(BUILT.road_departure_event("u1", "e_crown", flags, road), "", "Other trips do not count")
	var out_trip := BUILT.road_departure_event("u1", "u3", flags, road)
	assert_eq(out_trip, "count:" + BUILT.ROAD_DEPARTED_PREFIX + "verge_road")
	assert_true(LOGIC.dispatch(flags, chapter, out_trip).changed)
	assert_false(LOGIC.dispatch(flags, chapter, out_trip).changed, "Repeating one direction does not count twice")
	assert_false(flags.has("stormwood:side_raise_a_road_3"), "One direction is not both")
	assert_true(LOGIC.dispatch(flags, chapter, BUILT.road_departure_event("u3", "u1", flags, road)).changed)
	assert_true(flags.has("stormwood:side_raise_a_road_3"))
	assert_eq(_entry(flags, chapter).how, "Report your new road to Keeper Ondra.")
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_4" % CHAIN).changed)
	assert_true(flags.has("stormwood:side_raise_a_road_complete"))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	assert_true(loaded.has(BUILT.ROAD_CHOSEN_PREFIX + "capacitor_grove"))
	assert_true(loaded.has(BUILT.ROAD_DEPARTED_PREFIX + "capacitor_grove"))
	assert_true(loaded.has("stormwood:side_raise_a_road_complete"))


func test_chain_facts_are_declared_world_state() -> void:
	var chapter := _chapter()
	var side: Array = chapter.persistent_flags.side_content
	for footing: String in BUILT.ROAD_FOOTINGS:
		for prefix: String in [BUILT.ROAD_CHOSEN_PREFIX, BUILT.ROAD_DEPARTED_PREFIX]:
			assert_eq(PROGRESSION.scope_of(prefix + footing), PROGRESSION.SCOPE_WORLD)
			assert_true(side.has(prefix + footing), "%s%s is declared" % [prefix, footing])
	assert_true(side.has("stormwood:side_raise_a_road_3"))
	for chain: Dictionary in chapter.side_chains:
		if str(chain.id) == CHAIN:
			assert_eq((chain.steps as Array).size(), 4)
			assert_eq(str(chain.completion_flag), str(chain.steps[3].flag_id))


func test_ondra_report_outranks_ordinary_lines_only_while_owed() -> void:
	var spec := CHAPTER_RUNTIME.npc_spec({"id": "keeper_ondra", "name": "Keeper Ondra",
		"body_profile": "craftsperson", "position": [-160, 34.69, 2700]})
	var flags := PROGRESSION.new()
	for flag: String in ["stormwood:chapter_started", "stormwood:varga_defeated"]:
		flags.set_flag(flag)
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_keeper_ondra_in_progress",
		"Ondra's recipe conversation is untouched")
	flags.set_flag("stormwood:side_raise_a_road_3")
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(spec, flags), CHAPTER_RUNTIME.ONDRA_ROAD_REPORT)
	flags.set_flag("stormwood:side_raise_a_road_complete")
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_keeper_ondra_post_storm")
