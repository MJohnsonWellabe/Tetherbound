extends "res://tests/test_case.gd"

const CHAPTER := preload("res://scripts/world/cloudreach_chapter.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const QUEST := preload("res://scripts/world/quest_log.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const NPCS := preload("res://scripts/world/village_npcs.gd")
const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")


func test_realm_feed_and_canonical_count_completion_survive_reload() -> void:
	var data := CHAPTER.read_data(CHAPTER.CHAPTER_PATH)
	var flags := PROGRESSION.new()
	var log := QUEST.new()
	var meadows_id := log.tracked_id(flags)
	log.set_realm("cloudreach")
	assert_eq(log.tracked_id(flags), "cloudreach_arrive")
	assert_false(CHAPTER.apply_event(flags, data, "arrival_anchor_reached"))
	flags.set_flag("realm_key_cloudreach")
	assert_true(CHAPTER.apply_event(flags, data, "arrival_anchor_reached"))
	assert_eq(log.tracked_id(flags), "cloudreach_learn_crisis")
	assert_true(CHAPTER.apply_event(flags, data, "dialogue:cloudreach_aila_arrival_complete"))
	assert_true(log.tracked_text(flags).ends_with("0/2"))
	flags.set_flag("storm_anchor_lower_west_mapped")
	assert_false(CHAPTER.apply_event(flags, data, "all_count_flags_set"))
	assert_true(log.tracked_text(flags).ends_with("1/2"))
	flags.set_flag("storm_anchor_lower_east_mapped")
	assert_true(log.tracked_text(flags).ends_with("2/2"))
	assert_true(CHAPTER.apply_event(flags, data, "all_count_flags_set"))
	assert_true(flags.has("cloudreach_lower_anchors_investigated"))
	assert_false(flags.has("cloudreach_act_i_complete"))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	assert_eq(log.tracked_id(loaded), "cloudreach_reconnect_survivors")
	assert_true(log.main_entries(loaded)[2]["label"].ends_with("2/2"))
	log.set_realm("meadows")
	assert_eq(log.tracked_id(loaded), meadows_id)


func test_arrival_dialogue_only_advances_when_reached_and_explained() -> void:
	var flags := PROGRESSION.new()
	var data := CHAPTER.read_data(CHAPTER.CHAPTER_PATH)
	assert_false(CHAPTER.apply_event(flags, data, "dialogue:cloudreach_aila_arrival_complete"))
	flags.set_flag("cloudreach_chapter_started")
	var runner := RUNNER.new()
	assert_true(runner.start("cloudreach_aila_arrival"))
	assert_eq(runner.drain_effects().size(), 0)
	runner.advance()
	assert_eq(runner.drain_effects().size(), 0)
	runner.advance()
	assert_eq(runner.drain_effects(), ["cloudreach:cloudreach_aila_arrival_complete"])
	assert_true(ResourceLoader.exists(str(runner.line()["portrait"])))
	assert_ne(str(runner.line()["portrait"]), "res://assets/ui/portraits/trainer.png")


func test_npc_adapter_preserves_three_dimensional_placement_and_installed_profile() -> void:
	var specs := CHAPTER.npc_specs(CHAPTER.read_data(CHAPTER.CHAPTER_PATH), CHAPTER.read_data("res://data/config/cloudreach_npc_runtime.json"))
	assert_eq(specs.size(), 11)
	assert_eq(specs[0]["position"], [-275.0, 180.0, 520.0])
	assert_eq(specs[0]["config_key"], "local_historian")
	assert_false(NPCS.model_config(specs[0]).is_empty())
	var flags := PROGRESSION.new()
	assert_eq(NPCS.greeting_for(specs[0], flags), "cloudreach_aila_arrival")
	flags.set_flag("cloudreach_crisis_learned")
	assert_eq(NPCS.greeting_for(specs[0], flags), "cloudreach_aila_anchor_reminder")
	var unique: Dictionary = {}
	for spec: Dictionary in specs:
		assert_false(unique.has(spec["id"]))
		unique[spec["id"]] = true
		assert_false(NPCS.model_config(spec).is_empty())


func test_same_item_placements_and_realms_have_independent_persistent_identity() -> void:
	var first := CACHE.flag_id("good_candy", "lower_cache", "cloudreach")
	var second := CACHE.flag_id("good_candy", "bridge_cache", "cloudreach")
	assert_ne(first, second)
	assert_ne(first, CACHE.flag_id("good_candy", "lower_cache", "meadows"))
	assert_eq(CACHE.flag_id("good_candy"), "cache:good_candy")
	var flags := PROGRESSION.new()
	flags.set_flag(first)
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	assert_true(loaded.has(first))
	assert_false(loaded.has(second))
	assert_false(loaded.has("cache:good_candy"))
	loaded.load_data({})
	assert_false(loaded.has(first))


func test_stacked_surface_placement_chooses_nearest_authored_elevation() -> void:
	var world := WORLD.new()
	var surfaces: Array[Dictionary] = [
		{"kind": "rect", "centre": Vector2.ZERO, "half": Vector2(10, 10), "height": 100.0},
		{"kind": "rect", "centre": Vector2.ZERO, "half": Vector2(10, 10), "height": 400.0},
	]
	world.set("_surfaces", surfaces)
	assert_eq(world.ground_height_at(0, 0), 400.0)
	assert_eq(world.ground_height_near(Vector3(0, 105, 0)), 100.0)
	assert_true(is_nan(world.ground_height_near(Vector3(30, 105, 0))))
	world.free()


func test_ramps_join_the_level_landing_at_its_edge_and_height() -> void:
	var pad := Vector3(-80, 130, 40)
	var join := WORLD._landing_join(pad, Vector3(0, 105, -260), 6.56)
	assert_eq(join.y, pad.y)
	assert_true(join.distance_to(pad) > 6.0)
	assert_true(absf(join.z - pad.z) < 6.56)
