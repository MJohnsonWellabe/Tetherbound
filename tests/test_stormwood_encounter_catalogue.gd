extends "res://tests/test_case.gd"

const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MODEL := preload("res://scripts/characters/character_model.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const DIRECTOR := preload("res://scripts/combat/stormwood_encounter_director.gd")


class FixtureDirector extends "res://scripts/combat/stormwood_encounter_director.gd":
	var fixture_progression: RefCounted

	func _progression() -> RefCounted:
		return fixture_progression


class FixtureWild extends Node3D:
	var trainer_owned := false
	var instance: RefCounted
	var alpha_applied := false

	func set_alpha(value: bool) -> void:
		alpha_applied = value


func test_wild_records_include_deterministic_fixed_named_encounters_without_order_collisions() -> void:
	var first := CATALOGUE.wild_config("calm")
	var second := CATALOGUE.wild_config("calm")
	assert_eq(first, second)
	assert_eq((first["spawns"] as Array).size(), 336)
	var orders: Array[int] = []
	var authored_by_id := {}
	for authored: Dictionary in CATALOGUE.encounter_catalogue().named_encounters:
		authored_by_id[str(authored.id)] = authored
	var ordinary := 0
	var named := 0
	for spawn: Dictionary in first["spawns"]:
		assert_false(orders.has(int(spawn["order"])))
		orders.append(int(spawn["order"]))
		assert_true(SPECIES.has(str(spawn["species"])))
		assert_eq((spawn["centre"] as Array).size(), 3)
		if bool(spawn.get("fixed_encounter", false)):
			named += 1
			var authored: Dictionary = authored_by_id.get(str(spawn.stormwood_named_id), {})
			assert_false(authored.is_empty())
			assert_true(int(spawn["order"]) >= CATALOGUE.NAMED_ORDER_NAMESPACE)
			assert_true(int(spawn["order"]) < CATALOGUE.WILD_ORDER_NAMESPACE)
			assert_eq(int(spawn["count"]), 1)
			assert_eq(float(spawn["radius"]), 0.0)
			assert_eq(str(spawn.species), str(authored.placeholder_species))
			assert_eq(int(spawn.level), int(authored.level))
			assert_eq(float(spawn.centre[0]), float(authored.position[0]))
			assert_eq(float(spawn.centre[2]), float(authored.position[2]))
			assert_eq(bool(spawn.catchable), bool(authored.catchable))
			assert_eq(bool(spawn.once_only), bool(authored.once_only))
			assert_eq(str(spawn["stormwood_once_flag"]),
				CATALOGUE.named_once_flag(str(spawn["stormwood_named_id"])))
			var combat: Dictionary = (spawn["alpha"] as Dictionary).get("combat", {})
			assert_false(combat.is_empty())
		else:
			ordinary += 1
			assert_true(int(spawn["order"]) >= CATALOGUE.WILD_ORDER_NAMESPACE)
			assert_eq(int(spawn["count"]), CATALOGUE.ORDINARY_GROUP_COUNT)
			var options: Dictionary = spawn["stormwood_phase_options"]
			assert_true(options.has("calm"))
			assert_true(options.has("surge"))
	assert_eq(ordinary, 330)
	assert_eq(named, 6)


func test_wild_phase_keeps_each_region_in_its_authored_table_band() -> void:
	for phase in ["calm", "surge"]:
		for spawn: Dictionary in CATALOGUE.wild_config(phase)["spawns"]:
			if bool(spawn.get("fixed_encounter", false)):
				continue
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


func test_reordering_named_catalogue_preserves_orders_and_once_flags() -> void:
	var original: Array = CATALOGUE.encounter_catalogue().named_encounters.duplicate(true)
	var expected := {}
	for spawn: Dictionary in CATALOGUE.wild_config().spawns:
		if bool(spawn.get("fixed_encounter", false)):
			expected[spawn.stormwood_named_id] = {
				"order": spawn.order, "flag": spawn.stormwood_once_flag}
	CATALOGUE.encounter_catalogue().named_encounters.reverse()
	for spawn: Dictionary in CATALOGUE.wild_config().spawns:
		if bool(spawn.get("fixed_encounter", false)):
			assert_eq(spawn.order, expected[spawn.stormwood_named_id].order)
			assert_eq(spawn.stormwood_once_flag, expected[spawn.stormwood_named_id].flag)
	CATALOGUE.encounter_catalogue().named_encounters = original


func test_named_once_flag_is_written_and_blocks_the_same_runtime_id_after_reload() -> void:
	var id := "crown_guardian"
	var runtime_id := "wild_once_%d" % CATALOGUE.named_order(id)
	var stable_flag := CATALOGUE.named_once_flag(id)
	var director := FixtureDirector.new()
	director.fixture_progression = FLAGS.new()
	assert_false(director._once_cleared(runtime_id))
	director._mark_once_cleared(runtime_id)
	assert_true(director.fixture_progression.has(stable_flag))
	assert_false(director.fixture_progression.has(runtime_id),
		"implementation-order id must not leak into the durable Stormwood record")
	var reloaded := FLAGS.new()
	reloaded.load_data(director.fixture_progression.save_data())
	director.fixture_progression = reloaded
	assert_true(director._once_cleared(runtime_id),
		"the existing director spawn guard must see the saved stable flag")
	director.free()


func test_named_catchability_uses_the_production_wild_guard() -> void:
	var named_spawn: Dictionary = {}
	for spawn: Dictionary in CATALOGUE.wild_config().spawns:
		if str(spawn.get("stormwood_named_id", "")) == "crown_guardian":
			named_spawn = spawn
	assert_false(named_spawn.is_empty())
	var director := DIRECTOR.new()
	var catchable := FixtureWild.new()
	director._make_alpha(catchable, str(named_spawn.species), named_spawn, 2700.0)
	assert_true(catchable.alpha_applied)
	assert_false(catchable.trainer_owned, "the authored catchable guardian must accept throws")
	assert_eq(str(catchable.get_meta("stormwood_named_encounter")), "crown_guardian")
	var noncatchable_spawn := named_spawn.duplicate(true)
	noncatchable_spawn.catchable = false
	var noncatchable := FixtureWild.new()
	director._make_alpha(noncatchable, str(named_spawn.species), noncatchable_spawn, 2700.0)
	assert_true(noncatchable.trainer_owned,
		"an authored non-catchable named encounter must use the existing catch refusal")
	catchable.free()
	noncatchable.free()
	director.free()


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
