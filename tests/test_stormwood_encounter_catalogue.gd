extends "res://tests/test_case.gd"

const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const FLAGS := preload("res://autoload/progression_state.gd")


func test_wild_records_are_deterministic_namespaced_grounded_and_ordinary() -> void:
	var first := CATALOGUE.wild_config("calm")
	var second := CATALOGUE.wild_config("calm")
	assert_eq(first, second)
	assert_eq((first["spawns"] as Array).size(), 330)
	var orders: Array[int] = []
	for spawn: Dictionary in first["spawns"]:
		assert_true(int(spawn["order"]) >= CATALOGUE.WILD_ORDER_NAMESPACE)
		assert_false(orders.has(int(spawn["order"])))
		orders.append(int(spawn["order"]))
		assert_eq(int(spawn["count"]), CATALOGUE.ORDINARY_GROUP_COUNT)
		assert_true(SPECIES.has(str(spawn["species"])))
		assert_eq((spawn["centre"] as Array).size(), 3)
		var options: Dictionary = spawn["stormwood_phase_options"]
		assert_true(options.has("calm"))
		assert_true(options.has("surge"))


func test_wild_phase_keeps_each_region_in_its_authored_table_band() -> void:
	for phase in ["calm", "surge"]:
		for spawn: Dictionary in CATALOGUE.wild_config(phase)["spawns"]:
			var option: Dictionary = (spawn["stormwood_phase_options"] as Dictionary)[phase]
			var levels: Array = option["level_range"]
			assert_between(int(spawn["level"]), int(levels[0]), int(levels[1]))
			var names: Array[String] = []
			for role: Dictionary in option["roles"]:
				names.append(str(role["placeholder_species"]))
			assert_true(names.has(str(spawn["species"])))


func test_reordering_catalogue_preserves_saved_cluster_identity() -> void:
	var original: Array = CATALOGUE.encounter_catalogue().wild_clusters.duplicate(true)
	var expected := {}
	for spawn: Dictionary in CATALOGUE.wild_config().spawns:
		expected[spawn.id] = spawn.order
	CATALOGUE.encounter_catalogue().wild_clusters.reverse()
	for spawn: Dictionary in CATALOGUE.wild_config().spawns:
		assert_eq(spawn.order, expected[spawn.id])
	CATALOGUE.encounter_catalogue().wild_clusters = original


func test_trainer_specs_are_schema_compatible_and_preserve_authored_3d_metadata() -> void:
	var specs := CATALOGUE.trainer_specs()
	assert_eq(specs.size(), 26)
	var ids: Array[String] = []
	var flags: Array[String] = []
	for spec: Dictionary in specs:
		var id := str(spec["id"])
		assert_ne(id, "")
		assert_false(ids.has(id))
		ids.append(id)
		assert_ne(str(spec["name"]), "")
		assert_false(MODEL.config_for(str(spec["config_key"])).is_empty())
		assert_eq((spec["position"] as Array).size(), 2)
		assert_true(spec["source_position3D"] is Vector3)
		assert_true(spec.has("surface_id"))
		var defeat_flag := str(spec["defeat_flag"])
		assert_true(defeat_flag.begins_with("stormwood:trainer:"))
		assert_false(flags.has(defeat_flag))
		flags.append(defeat_flag)
		var state := FLAGS.new()
		state.set_flag(defeat_flag)
		assert_true(TRAINERS.already_beaten(spec, state))
		assert_false(spec.has("reward"))
		for member: Dictionary in TRAINERS.team_of(spec):
			assert_true(SPECIES.has(str(member["species"])))
			assert_true(int(member["level"]) > 0)
