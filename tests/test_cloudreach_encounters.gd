extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const TRAINER := preload("res://scripts/world/trainer_npc.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const SURFACE := preload("res://scripts/combat/cloudreach_combat_surface.gd")
const NATIVE_WILD_SITE_IDS: Array[String] = [
	"lower_cliff_foragers", "causeway_watch", "ravine_wind",
	"roost_perches", "upper_scouts", "summit_watch",
]


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
	var native_ids: Array[String] = []
	var authored_ids: Dictionary = {}
	for site: Dictionary in data["wild_sites"]:
		var id := str(site.get("id", ""))
		assert_false(id.is_empty(), "every Cloudreach wild site has a deterministic ID")
		assert_false(authored_ids.has(id), "Cloudreach wild site IDs remain unique: %s" % id)
		authored_ids[id] = true
		if NATIVE_WILD_SITE_IDS.has(id):
			native_ids.append(id)
		else:
			assert_true(not str(site.get("_why_road_visibility_0907", "")).is_empty()
					or not str(site.get("_why_air_patrol_visibility_0907", "")).is_empty(),
				"%s is an explicit ROAD/air-patrol addition, not silent ecology inflation" % id)
			assert_true(int(site.get("count", 0)) >= 2,
				"%s contributes the required visible creature pair" % id)
		var table := DIRECTOR.find_id(chapter["encounter_tables"], str(site["table_id"]))
		assert_false(table.is_empty())
		assert_true(table["catchable"])
		assert_true(table["replaceable"])
		for index in range(10):
			var rolled := DIRECTOR.roll_wild(table, 404, index)
			assert_eq(rolled, DIRECTOR.roll_wild(table, 404, index))
			assert_true(SPECIES.has(str(rolled["species"])))
			assert_between(float(rolled["level"]), float(table["level_range"][0]), float(table["level_range"][1]))
	native_ids.sort()
	var expected_native := NATIVE_WILD_SITE_IDS.duplicate()
	expected_native.sort()
	assert_eq(native_ids, expected_native,
		"the original six-site Cloudreach ecology contract remains present by identity")


func test_road_sightline_creatures_cannot_body_block_the_trainer_corridor() -> void:
	var trainer := CharacterBody3D.new()
	var wild := CharacterBody3D.new()
	DIRECTOR.keep_trainer_corridor_clear(wild, trainer)
	assert_true(wild.get_collision_exceptions().has(trainer),
		"ROAD creature ignores only the trainer body")
	assert_true(trainer.get_collision_exceptions().has(wild),
		"trainer has the reciprocal ROAD creature exception")
	wild.free()
	trainer.free()
