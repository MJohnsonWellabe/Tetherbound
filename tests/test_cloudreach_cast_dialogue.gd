extends "res://tests/test_case.gd"

const NPCS := preload("res://scripts/world/village_npcs.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const LOGIC := preload("res://scripts/world/realm_chapter_progression.gd")
const RUNTIME_PATH := "res://data/config/cloudreach_npc_runtime.json"
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const DIALOGUE_PATH := "res://data/dialogue/cloudreach.json"

## W04's render-source identities, independently of Cloudreach's speaker names.
## Each source uses this installed art.json body (tools/_capture_portraits.gd).
const RENDER_BODY_BY_PLATE := {
	"wilhelm": "innkeeper", "wandering_trainer": "wandering_trainer",
	"lark": "courier", "fenn": "creature_caretaker", "maren": "field_researcher",
	"corin": "trader", "bryn": "young_trainer", "ren": "former_tether_member",
	"officer_b": "officer_b", "captain_b": "captain_b",
	"tobin": "lost_traveler", "garrick": "farmer",
}


func _read(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func _entry(id: String) -> Dictionary:
	for entry: Dictionary in _read(RUNTIME_PATH)["npcs"]:
		if entry["id"] == id:
			return entry
	return {}


func _flags(values: Array) -> RefCounted:
	var flags := FLAGS.new()
	for value: String in values:
		flags.set_flag(value)
	return flags


func _effects(conversation: Dictionary) -> Array:
	var effects: Array = []
	for line: Variant in conversation["lines"]:
		if line is Dictionary and line.has("effect"):
			effects.append(line["effect"])
	return effects


func test_every_canonical_cast_member_and_conversation_has_valid_identity() -> void:
	var chapter := _read(CHAPTER_PATH)
	var runtime := _read(RUNTIME_PATH)
	var table: Dictionary = _read(DIALOGUE_PATH)["conversations"]
	var art := _read("res://data/config/art.json")
	assert_eq(runtime["npcs"].size(), chapter["npcs"].size())
	var ids: Array = []
	for npc: Dictionary in chapter["npcs"]:
		var spec := _entry(npc["id"])
		assert_false(spec.is_empty(), npc["id"])
		assert_false(ids.has(npc["id"]), "duplicate cast placement")
		ids.append(npc["id"])
		assert_true(art.has(npc["body_profile"]))
		assert_true(FileAccess.file_exists(str(art[npc["body_profile"]]["model"])))
		assert_ne(npc["body_profile"], "trainer")
		assert_false(NPCS.model_config({"config_key": npc["body_profile"]}).is_empty())
		var conversations: Array = npc["dialogue_ids"].duplicate()
		conversations.append(spec["greeting"])
		for branch: Dictionary in spec.get("greeting_when", []):
			conversations.append(branch["conversation"])
		for topic: Dictionary in spec.get("topic_interactions", []):
			conversations.append(topic["conversation"])
		for cue: Dictionary in spec.get("encounter_dialogue", []):
			conversations.append(cue["conversation"])
		for id: String in conversations:
			assert_true(table.has(id), id)
			if not table.has(id):
				continue
			assert_eq(table[id]["speaker"], npc["name"], id)
			assert_eq(table[id]["portrait"], spec["portrait"], id)
			assert_true(table[id]["lines"].size() >= 2, id)
			assert_ne(table[id]["portrait"], "res://assets/ui/portraits/trainer.png")
		assert_true(FileAccess.file_exists(spec["portrait"]))
		if npc["id"] == "warden_aila":
			assert_eq(spec["portrait_mode"], "clean_owner_reference")
			assert_eq(spec["portrait"], "res://assets/ui/portraits/cloudreach_aila_clean.png")
		else:
			_assert_render_matches_body(spec, str(npc["body_profile"]), art)
	for id: String in chapter["aftermath"]["return_dialogue_ids"]:
		assert_true(table.has(id), "required aftermath conversation")


func _assert_render_matches_body(spec: Dictionary, body_profile: String, art: Dictionary) -> void:
	assert_eq(spec["portrait_mode"], "installed_body_render")
	var plate := str(spec["portrait"]).get_file().get_basename()
	assert_true(RENDER_BODY_BY_PLATE.has(plate), "unverified render source " + plate)
	if not RENDER_BODY_BY_PLATE.has(plate):
		return
	assert_eq(art[body_profile]["model"], art[RENDER_BODY_BY_PLATE[plate]]["model"],
		"portrait must depict the installed world body for " + str(spec["id"]))
	assert_true(ResourceLoader.exists(str(spec["portrait"])))


func test_payoff_travelers_keep_their_own_portraits_before_and_after_return() -> void:
	var runtime := _read(RUNTIME_PATH)
	var art := _read("res://data/config/art.json")
	var table: Dictionary = _read(DIALOGUE_PATH)["conversations"]
	var returned_portraits: Dictionary = {}
	for traveler: Dictionary in runtime["world_payoffs"]["travelers"]:
		_assert_render_matches_body(traveler, str(traveler["config_key"]), art)
		var ids: Array = [traveler["greeting"]]
		if traveler.has("return_flag"):
			assert_true(traveler.has("return_greeting"), "return dialogue needs a body-specific identity")
			ids.append(traveler.get("return_greeting", ""))
			returned_portraits[traveler["id"]] = traveler["portrait"]
		for id: String in ids:
			assert_true(table.has(id), id)
			if not table.has(id):
				continue
			var expected_speaker := str(traveler["name"])
			if id == "cloudreach_shelter_pair_home":
				expected_speaker = "Returned Traveler"
			assert_eq(table[id]["speaker"], expected_speaker, id)
			var runner := RUNNER.new()
			assert_true(runner.start(id))
			while runner.is_active():
				assert_eq(runner.line()["portrait"], traveler["portrait"], id)
				runner.advance()
	assert_eq(returned_portraits.size(), 2)
	assert_ne(returned_portraits.get("shelter_traveler"), returned_portraits.get("shelter_courier"),
		"the returned pair use different installed bodies and cannot share one face")


func test_dialogue_cannot_manufacture_physical_progression_or_creatures() -> void:
	var table: Dictionary = _read(DIALOGUE_PATH)["conversations"]
	var chapter := _read(CHAPTER_PATH)
	var guards: Array = _read(RUNTIME_PATH)["dialogue_event_guards"]
	var allowed: Dictionary = {}
	for guard: Dictionary in guards:
		allowed[guard["effect"]] = guard
		assert_eq(_effects(table[guard["conversation"]]), [guard["effect"]])
		var event: String = guard["event"]
		assert_true(event.begins_with("dialogue:") or event == "side:packs_on_the_wrong_side:report_to_neri")
		var flags := _flags([])
		assert_false(LOGIC.dispatch(flags, chapter, event)["accepted"], "early " + event)
		flags = _flags(guard["requires_flags"])
		assert_true(LOGIC.dispatch(flags, chapter, event)["accepted"], "ready " + event)
	for id: String in table:
		for effect: String in _effects(table[id]):
			assert_true(allowed.has(effect), id + " has unauthorized event " + effect)
			if allowed.has(effect):
				assert_eq(allowed[effect]["conversation"], id)
		var serialized := JSON.stringify(table[id]).to_lower()
		for forbidden: String in ["battle:", "set_flag:", "species_id", "creature_id", "grant_creature", "sixth slot", "reserve box"]:
			assert_false(serialized.contains(forbidden), id + " assumes " + forbidden)
	for forbidden_id: String in ["cloudreach_maela_fly_unlocked", "cloudreach_veyra_defeated", "cloudreach_veyra_phase_change", "cloudreach_voss_defeated", "cloudreach_tavi_defeated", "cloudreach_neri_pack_return", "cloudreach_orrin_three_bells"]:
		assert_true(_effects(table[forbidden_id]).is_empty(), forbidden_id)


func test_dialogue_events_wait_until_the_authored_last_line() -> void:
	for guard: Dictionary in _read(RUNTIME_PATH)["dialogue_event_guards"]:
		var runner := RUNNER.new()
		assert_true(runner.start(guard["conversation"]))
		while not runner.line()["is_last"]:
			assert_true(runner.drain_effects().is_empty(), guard["conversation"])
			runner.advance()
		assert_eq(runner.drain_effects(), [guard["effect"]])
		runner.advance()
		assert_false(runner.is_active())
		assert_true(runner.drain_effects().is_empty())


func test_maela_readiness_does_not_award_fly_and_sora_waits_for_each_vane() -> void:
	var flags := _flags([])
	var maela := _entry("keeper_maela")
	assert_eq(NPCS.greeting_for(maela, flags), "cloudreach_maela_aerie")
	flags.set_flag("realm_key_cloudreach")
	flags.set_flag("windscar_aerie_prepared")
	assert_eq(NPCS.greeting_for(maela, flags), "cloudreach_maela_flight_trial")
	LOGIC.dispatch(flags, _read(CHAPTER_PATH), "dialogue:cloudreach_maela_flight_trial_ready")
	assert_true(flags.has("cloudreach_act_i_complete"))
	assert_false(flags.has("fly_traversal_unlocked"))
	assert_eq(NPCS.greeting_for(maela, flags), "cloudreach_maela_trial_reminder")
	flags.set_flag("fly_traversal_unlocked")
	assert_eq(NPCS.greeting_for(maela, flags), "cloudreach_maela_fly_unlocked")
	var sora := _entry("naturalist_sora")
	flags.set_flag("sky_shrine_reached")
	var vanes: Array = _read(RUNTIME_PATH)["physical_state_flags"]
	for vane: String in vanes:
		assert_eq(NPCS.greeting_for(sora, flags), "cloudreach_sora_shrine")
		flags.set_flag(vane)
	assert_eq(NPCS.greeting_for(sora, flags), "cloudreach_sora_storm_engine_truth")
	flags.set_flag("storm_anchor_engine_truth_learned")
	assert_eq(NPCS.greeting_for(sora, flags), "cloudreach_sora_aeries")
	flags.set_flag("side_aeries_complete")
	assert_eq(NPCS.greeting_for(sora, flags), "cloudreach_sora_aeries_complete")


func test_courier_requires_real_delivery_and_return_report_survives_reload() -> void:
	var neri := _entry("courier_neri")
	var flags := _flags(["causeway_survivors_reconnected"])
	assert_eq(NPCS.greeting_for(neri, flags), "cloudreach_neri_stranded")
	flags.set_flag("side_courier_pack_recovered")
	assert_eq(NPCS.greeting_for(neri, flags), "cloudreach_neri_pack_return")
	assert_false(LOGIC.dispatch(flags, _read(CHAPTER_PATH), "side:packs_on_the_wrong_side:report_to_neri")["accepted"])
	flags.set_flag("side_courier_medicine_delivered")
	assert_eq(NPCS.greeting_for(neri, flags), "cloudreach_neri_delivery_report")
	assert_eq(neri["position_when"][0]["if_flag"], "side_courier_medicine_delivered")
	assert_eq(neri["position_when"][0]["region_id"], "gate_lower_cliffs")
	assert_true(LOGIC.dispatch(flags, _read(CHAPTER_PATH), "side:packs_on_the_wrong_side:report_to_neri")["accepted"])
	var loaded := FLAGS.new()
	loaded.load_data(flags.save_data())
	assert_eq(NPCS.greeting_for(neri, loaded), "cloudreach_neri_home")


func test_aila_reward_requires_aftermath_and_does_not_repeat_as_greeting() -> void:
	var aila := _entry("warden_aila")
	var flags := _flags(["cloudreach_crisis_learned", "causeway_survivors_reconnected", "cloudreach_act_ii_complete", "captain_veyra_defeated"])
	assert_eq(NPCS.greeting_for(aila, flags), "cloudreach_aila_act_two")
	flags.set_flag("storm_anchor_network_disabled")
	assert_eq(NPCS.greeting_for(aila, flags), "cloudreach_aila_act_two")
	flags.set_flag("cloudreach_winds_restored")
	assert_eq(NPCS.greeting_for(aila, flags), "cloudreach_aila_final_reward")
	assert_eq(aila["position_when"][0]["if_flag"], "cloudreach_winds_restored")
	LOGIC.dispatch(flags, _read(CHAPTER_PATH), "dialogue:cloudreach_aila_final_reward_complete")
	assert_true(flags.has("realm_heart_cloudreach_earned"))
	assert_true(flags.has("realm_key_water"))
	assert_true(flags.has("waterward_route_revealed"))
	assert_eq(NPCS.greeting_for(aila, flags), "cloudreach_aila_after_restoration")
	assert_false(LOGIC.dispatch(flags, _read(CHAPTER_PATH), "dialogue:cloudreach_aila_final_reward_complete")["changed"])


func test_topics_and_aftermath_preserve_ordinary_npc_roles() -> void:
	var flags := _flags(["cloudreach_winds_restored"])
	for pair: Array in [["healer_iven", "cloudreach_iven_after_restoration"], ["bridgekeeper_orrin", "cloudreach_orrin_route_open"], ["keeper_maela", "cloudreach_maela_after_restoration"], ["trader_kelm", "cloudreach_kelm_after_restoration"], ["defector_rusk", "cloudreach_rusk_after_restoration"]]:
		assert_eq(NPCS.greeting_for(_entry(pair[0]), flags), pair[1])
	assert_eq(_entry("trader_kelm")["topic_interactions"][0]["conversation"], "cloudreach_kelm_resource_tier")
	assert_eq(_entry("defector_rusk")["topic_interactions"][0]["conversation"], "cloudreach_rusk_upper_anchor_warning")
	assert_eq(NPCS.greeting_for(_entry("young_trainer_tavi"), _flags([])), "cloudreach_tavi_circuit")
	assert_eq(NPCS.greeting_for(_entry("young_trainer_tavi"), _flags(["side_cliff_circuit_windscar", "cloudreach_upper_route_unlocked"])), "cloudreach_tavi_challenge")
	assert_eq(NPCS.greeting_for(_entry("young_trainer_tavi"), _flags(["side_cliff_circuit_complete"])), "cloudreach_tavi_defeated")
	assert_eq(NPCS.greeting_for(_entry("officer_voss"), _flags(["defeated_cloudreach_voss"])), "cloudreach_voss_defeated")
	assert_eq(NPCS.greeting_for(_entry("captain_veyra"), _flags(["captain_veyra_defeated"])), "cloudreach_veyra_defeated")
