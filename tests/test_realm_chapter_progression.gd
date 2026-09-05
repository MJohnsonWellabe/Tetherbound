extends "res://tests/test_case.gd"

const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const ADAPTER := preload("res://scripts/world/realm_chapter_events.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const PATH := "res://data/config/cloudreach_chapter.json"

class RealmStub extends Node:
	var current_realm := "meadows"


func _chapter() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH)) as Dictionary


func _late_flags() -> RefCounted:
	var flags := PROGRESSION.new()
	flags.set_flag("realm_key_cloudreach")
	flags.set_flag("cloudreach_act_i_complete")
	return flags


func _finish_act_two(flags: RefCounted, chapter: Dictionary) -> void:
	for event: String in ["flight_trial_completed", "landmark:sky_shrine_heartstone_reached",
		"dialogue:cloudreach_sora_storm_engine_truth", "sky_shrine_counterweight_released",
		"counterweight_road_entered"]:
		assert_true(LOGIC.dispatch(flags, chapter, event)["changed"], event)


func test_unknown_and_premature_events_cannot_skip_chapter_gates() -> void:
	var flags := PROGRESSION.new()
	var chapter := _chapter()
	for event: String in ["flag:cloudreach_chapter_complete", "flight_trial_completed",
		"landmark:sky_shrine_heartstone_reached", "encounter:captain_veyra_storm_anchor_won",
		"dialogue:cloudreach_aila_final_reward_complete", "count:realm_key_water",
		"count:storm_anchor_upper_west_disabled"]:
		assert_false(LOGIC.dispatch(flags, chapter, event)["changed"], event)
	assert_eq(flags.all_set().size(), 0)
	# A downstream prerequisite without entry to its act is insufficient.
	flags.set_flag("summit_extraction_engine_reached")
	assert_false(LOGIC.dispatch(flags, chapter, "encounter:captain_veyra_storm_anchor_won")["accepted"])


func test_act_two_requires_each_authored_event_and_survives_save_load() -> void:
	var flags := _late_flags()
	var chapter := _chapter()
	assert_false(LOGIC.dispatch(flags, chapter, "counterweight_road_entered")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, "flight_trial_completed")["changed"])
	assert_false(flags.has("sky_shrine_reached"))
	assert_true(LOGIC.dispatch(flags, chapter, "landmark:sky_shrine_heartstone_reached")["changed"])
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	assert_false(LOGIC.reconcile(loaded, chapter)["changed"])
	assert_false(loaded.has("cloudreach_upper_route_unlocked"))
	for event: String in ["dialogue:cloudreach_sora_storm_engine_truth", "sky_shrine_counterweight_released", "counterweight_road_entered"]:
		assert_true(LOGIC.dispatch(loaded, chapter, event)["changed"])
	assert_true(loaded.has("cloudreach_act_ii_complete"))
	assert_false(loaded.has("cloudreach_chapter_complete"))


func test_upper_anchor_count_is_unique_three_and_recovers_from_partial_save() -> void:
	var flags := _late_flags()
	var chapter := _chapter()
	_finish_act_two(flags, chapter)
	var objective := "cloudreach_disable_upper_anchors"
	assert_eq(LOGIC.count_progress(flags, chapter, objective), Vector2i(0, 3))
	assert_false(LOGIC.dispatch(flags, chapter, "all_count_flags_set")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, "count:storm_anchor_upper_east_disabled")["changed"])
	var revision: int = flags.revision
	assert_false(LOGIC.dispatch(flags, chapter, "count:storm_anchor_upper_east_disabled")["changed"])
	assert_eq(flags.revision, revision)
	assert_eq(LOGIC.count_progress(flags, chapter, objective), Vector2i(1, 3))
	assert_true(LOGIC.dispatch(flags, chapter, "count:storm_anchor_summit_feed_disabled")["changed"])
	assert_eq(LOGIC.count_progress(flags, chapter, objective), Vector2i(2, 3))
	assert_false(flags.has("cloudreach_upper_anchors_disabled"))
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	# Models an interrupted older adapter that saved the last site, not aggregate.
	loaded.set_flag("storm_anchor_upper_west_disabled")
	assert_true(LOGIC.reconcile(loaded, chapter)["changed"])
	assert_eq(LOGIC.count_progress(loaded, chapter, objective), Vector2i(3, 3))
	assert_true(loaded.has("cloudreach_upper_anchors_disabled"))
	assert_false(LOGIC.reconcile(loaded, chapter)["changed"])


func test_finale_keeps_boss_network_aftermath_and_reward_as_separate_beats() -> void:
	var flags := _late_flags()
	var chapter := _chapter()
	_finish_act_two(flags, chapter)
	for flag: String in ["storm_anchor_upper_west_disabled", "storm_anchor_upper_east_disabled", "storm_anchor_summit_feed_disabled"]:
		assert_true(LOGIC.dispatch(flags, chapter, "count:" + flag)["changed"])
	assert_false(LOGIC.dispatch(flags, chapter, "summit_engine_relays_disabled")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, "summit_arena_threshold_crossed")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, "encounter:captain_veyra_storm_anchor_won")["changed"])
	assert_false(flags.has("storm_anchor_network_disabled"))
	assert_false(flags.has("realm_heart_cloudreach_earned"))
	assert_false(LOGIC.dispatch(flags, chapter, "aftermath:cloudreach_winds_restored")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, "summit_engine_relays_disabled")["changed"])
	assert_false(flags.has("cloudreach_winds_restored"))
	assert_true(LOGIC.dispatch(flags, chapter, "aftermath:cloudreach_winds_restored")["changed"])
	assert_false(flags.has("realm_key_water"))
	var result := LOGIC.dispatch(flags, chapter, "dialogue:cloudreach_aila_final_reward_complete")
	assert_eq(result["granted_flags"], ["realm_heart_cloudreach_earned", "realm_key_water", "waterward_route_revealed"])
	assert_eq(result["completed_ids"], ["cloudreach_claim_reward"])
	assert_true(flags.has("cloudreach_chapter_complete"))
	assert_false(flags.has("realm_heart_cloudreach_placed"), "Future Heart power is intentionally undefined")
	assert_false(flags.has("water_realm_entered"), "Water remains future, not enterable")
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	var revision: int = loaded.revision
	for event: String in ["encounter:captain_veyra_storm_anchor_won", "summit_engine_relays_disabled", "aftermath:cloudreach_winds_restored", "dialogue:cloudreach_aila_final_reward_complete"]:
		var replay := LOGIC.dispatch(loaded, chapter, event)
		assert_false(replay["changed"])
		assert_eq(replay["granted_flags"], [])
	assert_eq(loaded.revision, revision)
	assert_eq(loaded.save_data(), flags.save_data())


func test_completed_reward_repairs_missing_entitlements_without_replaying_completion() -> void:
	var flags := _late_flags()
	flags.set_flag("cloudreach_act_ii_complete")
	flags.set_flag("cloudreach_winds_restored")
	flags.set_flag("cloudreach_chapter_complete")
	flags.set_flag("realm_key_water")
	var result := LOGIC.reconcile(flags, _chapter())
	assert_eq(result["completed_ids"], [])
	assert_eq(result["granted_flags"], ["realm_heart_cloudreach_earned", "waterward_route_revealed"])
	assert_false(LOGIC.reconcile(flags, _chapter())["changed"])


func test_side_chain_visibility_order_fly_gate_and_reload() -> void:
	var flags := PROGRESSION.new()
	var chapter := _chapter()
	var prefix := "side:three_bells_against_silence:"
	assert_eq(LOGIC.side_entries(flags, chapter), [])
	assert_false(LOGIC.dispatch(flags, chapter, prefix + "find_lower_bell")["changed"])
	flags.set_flag("cloudreach_crisis_learned")
	assert_eq(LOGIC.side_entries(flags, chapter)[0]["how"], "Find the bell beside the first broken span.")
	assert_false(LOGIC.dispatch(flags, chapter, prefix + "ring_windscar_bell")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, prefix + "find_lower_bell")["changed"])
	assert_true(LOGIC.dispatch(flags, chapter, prefix + "ring_windscar_bell")["changed"])
	assert_false(LOGIC.dispatch(flags, chapter, prefix + "ring_high_roost_bell")["changed"])
	var loaded := PROGRESSION.new()
	loaded.load_data(flags.save_data())
	loaded.set_flag("fly_traversal_unlocked")
	assert_true(LOGIC.dispatch(loaded, chapter, prefix + "ring_high_roost_bell")["changed"])
	assert_true(loaded.has("side_three_bells_complete"))
	assert_true(LOGIC.side_entries(loaded, chapter)[0]["done"])
	assert_eq(LOGIC.side_entries(loaded, chapter)[0]["how"], "")
	assert_false(LOGIC.dispatch(loaded, chapter, prefix + "ring_high_roost_bell")["changed"])
	assert_false(loaded.has("cloudreach_chapter_complete"))


func test_all_authored_side_chains_complete_using_only_their_declared_events() -> void:
	var chapter := _chapter()
	for chain: Dictionary in chapter["side_chains"]:
		var flags := PROGRESSION.new()
		flags.set_flag(str(chain["revealed_by"]))
		flags.set_flag("fly_traversal_unlocked")
		flags.set_flag("cloudreach_upper_route_unlocked")
		for step: Dictionary in chain["steps"]:
			assert_true(LOGIC.dispatch(flags, chapter, "side:%s:%s" % [chain["id"], step["id"]])["changed"], str(step["id"]))
		assert_true(flags.has(str(chain["completion_flag"])))
		var loaded := PROGRESSION.new()
		loaded.load_data(flags.save_data())
		assert_true(loaded.has(str(chain["completion_flag"])))
		assert_false(loaded.has("cloudreach_chapter_complete"))


func test_scene_adapter_uses_production_realm_property_and_rejects_meadows() -> void:
	var game := RealmStub.new()
	var adapter := ADAPTER.new()
	assert_false(adapter._in_realm(game))
	game.current_realm = "cloudreach"
	assert_true(adapter._in_realm(game))
	assert_false(adapter._in_realm(null))
	adapter.free()
	game.free()
