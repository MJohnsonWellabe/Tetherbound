extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const TRAINER := preload("res://scripts/world/trainer_npc.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const SURFACE := preload("res://scripts/combat/cloudreach_combat_surface.gd")


func test_seven_trainers_use_real_species_models_curve_and_rewards() -> void:
	var chapter := DIRECTOR.read_json(DIRECTOR.CHAPTER_PATH)
	var data := DIRECTOR.read_json(DIRECTOR.CONFIG_PATH)
	var items: Dictionary = DIRECTOR.read_json("res://data/items/items.json")["items"]
	assert_eq(data["trainers"].size(), 7)
	var ids: Array = []
	var maela_skyplume := false
	for placement: Dictionary in data["trainers"]:
		var authored := DIRECTOR.find_id(chapter["trainer_ladder"], str(placement["id"]))
		var spec := DIRECTOR.trainer_spec(authored, placement, data)
		assert_false(ids.has(spec["id"]))
		ids.append(spec["id"])
		assert_eq(spec["defeat_flag"], authored["defeat_flag"])
		assert_false(spec["rechallenge"])
		assert_false(MODEL.config_for(str(spec["config_key"])).is_empty())
		assert_true(spec["position"].size() == 3)
		assert_false(spec["requires_flags"].is_empty())
		assert_between(TRAINER.team_of(spec).size(), 2, 3)
		for entry: Dictionary in TRAINER.team_of(spec):
			var member := TRAINER.creature_for(entry)
			assert_true(member != null)
			assert_eq(member.get("level"), entry["level"])
			assert_false(member.get("combat_override").is_empty())
			assert_false(entry.has("hp_multiplier"))
		for item: Dictionary in TRAINER.reward_items(spec):
			assert_true(items.has(str(item["id"])))
			if str(spec["id"]) == "keeper_maela_trial" and str(item["id"]) == "skyplume" and int(item.get("count", 0)) == 2:
				maela_skyplume = true
		var flags := FLAGS.new()
		flags.set_flag(str(spec["defeat_flag"]))
		var loaded := FLAGS.new()
		loaded.load_data(flags.save_data())
		assert_true(TRAINER.already_beaten(spec, loaded))
	assert_true(maela_skyplume, "Maela's creature trial is the guaranteed playable Skyplume source")


func test_wild_tables_are_replaceable_deterministic_and_within_real_level_ranges() -> void:
	var chapter := DIRECTOR.read_json(DIRECTOR.CHAPTER_PATH)
	var data := DIRECTOR.read_json(DIRECTOR.CONFIG_PATH)
	assert_eq(data["wild_sites"].size(), 6)
	for site: Dictionary in data["wild_sites"]:
		var table := DIRECTOR.find_id(chapter["encounter_tables"], str(site["table_id"]))
		assert_false(table.is_empty())
		assert_true(table["catchable"])
		assert_true(table["replaceable"])
		for index in range(10):
			var rolled := DIRECTOR.roll_wild(table, 404, index)
			assert_eq(rolled, DIRECTOR.roll_wild(table, 404, index))
			assert_true(SPECIES.has(str(rolled["species"])))
			assert_between(float(rolled["level"]), float(table["level_range"][0]), float(table["level_range"][1]))
