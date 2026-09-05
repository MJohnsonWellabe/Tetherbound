extends "res://tests/test_case.gd"

const RULES := preload("res://scripts/world/cloudreach_physical_rules.gd")
const RUNTIME := preload("res://scripts/world/cloudreach_physical_runtime.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")


func test_all_physical_actions_respect_real_event_prerequisites() -> void:
	var data := RULES.read(RUNTIME.DATA_PATH)
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	var ids: Array = []
	for spec: Dictionary in data["interactions"]:
		assert_false(ids.has(spec["id"]))
		ids.append(spec["id"])
		assert_true(RULES.vec(spec["position"]).is_finite())
		assert_false(RULES.available(FLAGS.new(), spec), spec["id"])
		var flags := FLAGS.new()
		for flag: String in spec["requires_flags"]:
			flags.set_flag(flag)
		assert_true(RULES.available(flags, spec))
		flags.set_flag(spec["completion_flag"])
		assert_false(RULES.available(flags, spec), "one-time " + spec["id"])
		if spec.has("event"):
			assert_false(str(spec["event"]).begins_with("dialogue:"))
			assert_false(str(spec["event"]).begins_with("encounter:"))
			assert_false(LOGIC.dispatch(FLAGS.new(), chapter, spec["event"])["accepted"])
	assert_eq(ids.size(), 15)


func test_trial_requires_ordered_air_crossings_and_real_floor_landing_volume() -> void:
	var gates: Array = RULES.read(RUNTIME.DATA_PATH)["trial"]["gates"]
	var first := RULES.vec(gates[0]["position"])
	var second := RULES.vec(gates[1]["position"])
	assert_eq(RULES.next_gate(0, first - Vector3.RIGHT * 8, first + Vector3.RIGHT * 8, gates, false), 0)
	assert_eq(RULES.next_gate(0, second, second + Vector3.RIGHT, gates, true), 0)
	assert_eq(RULES.next_gate(0, first - Vector3.RIGHT * 8, first + Vector3.RIGHT * 8, gates, true), 1)
	assert_eq(RULES.next_gate(1, second - Vector3.RIGHT * 8, second + Vector3.RIGHT * 8, gates, true), 2)
	var landing := {"position": [0,100,0], "radius_m": 12, "height_tolerance_m": 3}
	assert_true(RULES.in_landing(Vector3(5,100,0), landing))
	assert_false(RULES.in_landing(Vector3(5,40,0), landing), "same XZ on lower floor is not arrival")
	assert_false(RULES.in_landing(Vector3(30,100,0), landing))


func test_sora_rejects_missing_vanes_and_only_conversation_can_report_courier_delivery() -> void:
	var npc := RULES.read(RUNTIME.NPC_PATH)
	var flags := FLAGS.new()
	for flag: String in ["cloudreach_act_i_complete", "fly_traversal_unlocked", "sky_shrine_reached"]:
		flags.set_flag(flag)
	for vane: String in npc["physical_state_flags"]:
		assert_true(RULES.dialogue_guard(flags, npc, "cloudreach:cloudreach_sora_storm_engine_truth").is_empty())
		flags.set_flag(vane)
	assert_false(RULES.dialogue_guard(flags, npc, "cloudreach:cloudreach_sora_storm_engine_truth").is_empty())
	assert_true(RULES.dialogue_guard(flags, npc, "cloudreach:flight_trial_completed").is_empty())
	assert_true(RULES.dialogue_guard(flags, npc, "cloudreach:encounter:captain_veyra_storm_anchor_won").is_empty())
	assert_true(RULES.dialogue_guard(flags, npc, "cloudreach:side:packs_on_the_wrong_side:deliver_medicine").is_empty())


func test_all_seven_encounter_ids_are_guarded_and_circuit_uses_real_battles() -> void:
	var data := RULES.read(RUNTIME.DATA_PATH)
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	assert_eq(data["encounter_requirements"].size(), chapter["trainer_ladder"].size())
	for spec: Dictionary in chapter["trainer_ladder"]:
		assert_false(RULES.encounter_allowed(FLAGS.new(), chapter, data, spec["id"]))
		var flags := FLAGS.new()
		for flag: String in data["encounter_requirements"][spec["id"]]:
			flags.set_flag(flag)
		assert_true(RULES.encounter_allowed(flags, chapter, data, spec["id"]))
	assert_false(RULES.encounter_allowed(FLAGS.new(), chapter, data, "invented_trainer"))
	var flags := FLAGS.new()
	flags.set_flag("fly_traversal_unlocked")
	assert_true(RULES.circuit_events(flags, data).is_empty(), "flight trial isn't a mentor battle")
	flags.set_flag("defeated_cloudreach_senn")
	assert_true(RULES.circuit_events(flags, data).is_empty())
	flags.set_flag("completed_cloudreach_maela_trial_battle")
	assert_eq(RULES.circuit_events(flags, data), ["side:the_cliff_circuit:beat_windscar_pair"])


func test_every_chapter_pickup_and_camp_retains_canonical_identity() -> void:
	var data := RULES.read(RUNTIME.DATA_PATH)
	var chapter := RULES.read(RUNTIME.CHAPTER_PATH)
	assert_eq(chapter["pickups"].size(), 19)
	assert_eq(data["pickup_overrides"].size(), 19)
	for spec: Dictionary in chapter["pickups"]:
		assert_true(data["pickup_overrides"].has(spec["id"]))
		assert_true(RULES.vec(data["pickup_overrides"][spec["id"]]).is_finite())
		assert_true(spec["persistent"] and spec["one_time"])
	assert_eq(chapter["camping_contract"]["camps"].size(), 5)
	var specs := RULES.npc_specs(chapter, RULES.read(RUNTIME.NPC_PATH), FLAGS.new())
	assert_eq(specs.size(), chapter["npcs"].size())
	for spec: Dictionary in specs:
		assert_ne(spec["config_key"], "trainer")
		assert_true(RULES.vec(spec["position"]).is_finite())


func test_bounded_currents_reach_shrine_and_trial_does_not_grant_global_access() -> void:
	var data := RULES.read(RUNTIME.DATA_PATH)
	for draft: Dictionary in data["updrafts"]:
		var bounds := AABB(RULES.vec(draft["position"]), RULES.vec(draft["size"]))
		assert_true(float(draft["ceiling_y"]) <= bounds.end.y)
		assert_true(float(draft["lift_speed"]) <= 18.0)
		assert_ne(draft["requires_flag"], "")
	var trial: Dictionary = data["trial"]
	var volume := AABB(RULES.vec(trial["bounds_position"]), RULES.vec(trial["bounds_size"]))
	for gate: Dictionary in trial["gates"]:
		assert_true(volume.has_point(RULES.vec(gate["position"])))
	assert_false(volume.has_point(Vector3(1110,1050,2940)))
	assert_eq(data["restrictions"].size(), 3)
