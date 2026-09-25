extends "res://tests/test_case.gd"

const PROGRESSION := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const CHAPTER_RUNTIME := preload("res://scripts/world/stormwood_chapter.gd")
const RECORDS := preload("res://scripts/world/stormwood_crown_records.gd")
const PEOPLE := preload("res://scripts/world/village_npcs.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const CHAIN := "stormwood_crown_remembers"
const WEN := {"id": "archivist_wen", "name": "Archivist Wen",
	"body_profile": "field_researcher", "position": [700, 74.15, 2700]}


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json")) as Dictionary


func _entry(flags: RefCounted, chapter: Dictionary) -> Dictionary:
	for row: Dictionary in LOGIC.side_entries(flags, chapter):
		if str(row.id) == CHAIN:
			return row
	return {}


func test_three_distinct_records_then_wen_complete_the_chain() -> void:
	var chapter := _chapter()
	var flags := PROGRESSION.new()
	assert_true(_entry(flags, chapter).is_empty(), "The chain stays hidden before the Crown is reached")
	var first_event := RECORDS.event_for_conversation(RECORDS.conversation_for("rain_ledger"))
	assert_false(LOGIC.dispatch(flags, chapter, first_event).changed,
		"A record cannot count before the Crown is reached")
	flags.set_flag("stormwood:crown_reached")
	assert_eq(_entry(flags, chapter).how, "Find the first surviving Crown record.")
	for step: String in ["step_1", "step_2", "step_3"]:
		assert_false(LOGIC.dispatch(flags, chapter, "side:%s:%s" % [CHAIN, step]).changed,
			"The aggregate %s event cannot skip the records" % step)
	assert_true(LOGIC.dispatch(flags, chapter, first_event).changed)
	assert_true(flags.has("stormwood:side_crown_remembers_1"), "Any first record finds the chain")
	assert_false(LOGIC.dispatch(flags, chapter, first_event).changed, "Rereading cannot count twice")
	assert_eq(_entry(flags, chapter).how, "Read all three records around the heartstone grove.")
	assert_true(LOGIC.dispatch(flags, chapter, RECORDS.event_for_conversation(
		RECORDS.conversation_for("reversal_mark"))).changed)
	assert_false(flags.has("stormwood:side_crown_remembers_2"), "Two records are not the full account")
	assert_true(LOGIC.dispatch(flags, chapter, RECORDS.event_for_conversation(
		RECORDS.conversation_for("root_census"))).changed)
	assert_true(flags.has("stormwood:side_crown_remembers_2"))
	assert_false(flags.has("stormwood:side_crown_remembers_complete"),
		"Reading every record does not finish the chain without Wen")
	assert_eq(_entry(flags, chapter).how, "Bring the complete account to Wen.")
	assert_true(LOGIC.dispatch(flags, chapter, "side:%s:step_3" % CHAIN).changed)
	assert_true(flags.has("stormwood:side_crown_remembers_complete"))
	for main_flag: String in ["stormwood:engine_truth_learned", "stormwood:rootgate_released",
			"stormwood:heartstone_taken"]:
		assert_false(flags.has(main_flag), "The side chain cannot set main flag %s" % main_flag)
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	for record_id: String in RECORDS.record_ids():
		assert_true(loaded.has(RECORDS.count_flag_for(record_id)), "%s survives save/load" % record_id)
	assert_true(loaded.has("stormwood:side_crown_remembers_complete"))


func test_chapter_counts_exactly_the_runtime_records_and_declares_them_persistent() -> void:
	var chapter := _chapter()
	var expected: Array = []
	for record_id: String in RECORDS.record_ids():
		expected.append(RECORDS.count_flag_for(record_id))
		assert_eq(PROGRESSION.scope_of(RECORDS.count_flag_for(record_id)), PROGRESSION.SCOPE_WORLD,
			"Record facts are world-scoped so peers share one reading")
	var side_content: Array = chapter.persistent_flags.side_content
	for flag: String in expected:
		assert_true(side_content.has(flag), "%s is a declared persistent chapter flag" % flag)
	for chain: Dictionary in chapter.side_chains:
		if str(chain.id) != CHAIN:
			continue
		assert_eq(chain.steps[0].count_flags, expected)
		assert_eq(int(chain.steps[0].required_count), 1)
		assert_eq(chain.steps[1].count_flags, expected)
		assert_eq(int(chain.steps[1].required_count), 3)
	var dialogue: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	for record_id: String in RECORDS.record_ids():
		assert_true(dialogue.has(RECORDS.conversation_for(record_id)), "%s has authored text" % record_id)
	assert_true(dialogue.has(CHAPTER_RUNTIME.WEN_RECORDS_RETURN_CONVERSATION))
	assert_eq(RECORDS.event_for_conversation("stormwood_archivist_wen_in_progress"), "",
		"Unrelated conversations submit no record fact")


func test_wen_reports_records_only_after_truth_and_until_complete() -> void:
	var spec := CHAPTER_RUNTIME.npc_spec(WEN)
	var flags := PROGRESSION.new()
	for flag: String in ["stormwood:chapter_started", "stormwood:crown_reached",
			"stormwood:named:crown_guardian:cleared", "stormwood:side_crown_remembers_1",
			"stormwood:side_crown_remembers_2"]:
		flags.set_flag(flag)
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_archivist_wen_in_progress",
		"The records report never pre-empts Wen's main truth conversation")
	flags.set_flag("stormwood:engine_truth_learned")
	assert_eq(PEOPLE.greeting_for(spec, flags), CHAPTER_RUNTIME.WEN_RECORDS_RETURN_CONVERSATION)
	flags.set_flag("stormwood:long_storm_ended")
	assert_eq(PEOPLE.greeting_for(spec, flags), CHAPTER_RUNTIME.WEN_RECORDS_RETURN_CONVERSATION,
		"The report stays available after the Long Storm until the chain is complete")
	flags.set_flag("stormwood:side_crown_remembers_complete")
	assert_eq(PEOPLE.greeting_for(spec, flags), "stormwood_archivist_wen_post_storm")


func test_record_seats_are_clear_readable_island_ground() -> void:
	var field := FIELD.new()
	var layers: Dictionary = BAKE.load_all("stormwood")
	var pickups: Array = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_pickups.json")) as Dictionary).pickups
	var npcs: Array = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_npcs.json")) as Dictionary).characters
	for record: Dictionary in RECORDS.RECORDS:
		var seat := Vector2(float(record.at[0]), float(record.at[1]))
		assert_true(seat.distance_to(Vector2(700, 2700)) < 200.0,
			"%s stands on the Crown island, reached only through its arch" % record.id)
		assert_true(field.slope_degrees_at(seat.x, seat.y) < 15.0, "%s is on walkable ground" % record.id)
		assert_true(seat.distance_to(Vector2(700, 2712)) > 8.0, "%s leaves the heartstone prompt clear" % record.id)
		for layer: String in ["storm_canopy", "storm_deadwood", "crown_canopy", "storm_rock"]:
			var nearest := INF
			for placement: Dictionary in layers.get(layer, []):
				var at: Vector3 = placement.position
				nearest = minf(nearest, Vector2(at.x, at.z).distance_to(seat))
			assert_true(nearest > 6.0, "%s is clear of baked %s (nearest %.1f m)" % [record.id, layer, nearest])
		for pickup: Dictionary in pickups:
			var at: Array = pickup.position
			assert_true(Vector2(float(at[0]), float(at[2])).distance_to(seat) > 8.0,
				"%s does not compete with pickup %s" % [record.id, pickup.id])
		for npc: Dictionary in npcs:
			var at: Array = npc.position
			assert_true(Vector2(float(at[0]), float(at[2])).distance_to(seat) > 8.0,
				"%s does not compete with %s" % [record.id, npc.id])
