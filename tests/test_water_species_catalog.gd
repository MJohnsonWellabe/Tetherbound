extends "res://tests/test_case.gd"

const ADAPTER := preload("res://scripts/creatures/water_species_catalog.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

var original: Dictionary
var installed: Dictionary


func before_each() -> void:
	installed = SPECIES.table().duplicate(true)
	original = JSON.parse_string(FileAccess.get_file_as_string(SPECIES.SPECIES_PATH)).species


func after_each() -> void:
	SPECIES._table = installed


func test_production_catalogue_registers_water_without_replacing_meadows() -> void:
	assert_eq(installed.size(), original.size() + 12)
	for id: String in ADAPTER.BOARD_IDS:
		assert_true(SPECIES.has(ADAPTER.runtime_id(id)), id)
	assert_eq(installed.mosshell, original.mosshell)


func test_merge_preserves_every_existing_definition_and_is_deeply_isolated() -> void:
	var base := original.duplicate(true)
	var result: Dictionary = ADAPTER.merge_catalogue(base)
	assert_true(result.ok, str(result.errors))
	assert_eq(base, original)
	assert_eq(result.catalogue.size(), original.size() + 12)
	for id: String in original:
		assert_eq(result.catalogue[id], original[id], id)
	assert_eq(result.board_to_runtime.mosshell, "water_mosshell")
	result.catalogue.water_mosshell.moves.quick = "test_changed_move"
	result.catalogue.mosshell.placeholder.height = 999.0
	assert_eq(base, original, "no shared nested dictionaries")


func test_stable_ids_survive_a_new_base_collision_and_merge_is_idempotent() -> void:
	var base := original.duplicate(true)
	base.aquaryn = {"display_name": "Unrelated existing Aquaryn"}
	var once: Dictionary = ADAPTER.merge_catalogue(base)
	assert_true(once.ok)
	assert_eq(once.board_to_runtime.aquaryn, "water_aquaryn")
	assert_eq(once.catalogue.aquaryn, base.aquaryn)
	var twice: Dictionary = ADAPTER.merge_catalogue(once.catalogue)
	assert_true(twice.ok, str(twice.errors))
	assert_eq(twice.catalogue, once.catalogue)
	assert_eq(twice.board_to_runtime, once.board_to_runtime)
	assert_eq(ADAPTER.runtime_id("unknown"), "")
	assert_eq(ADAPTER.board_id("mosshell"), "")
	assert_eq(ADAPTER.board_id("water_tidecoil"), "tidecoil")


func test_namespaced_collision_rejects_the_entire_roster_without_mutation() -> void:
	var base := original.duplicate(true)
	base.water_tidecoil = {"display_name": "Reserved by another catalogue"}
	var before := base.duplicate(true)
	var result: Dictionary = ADAPTER.merge_catalogue(base)
	assert_false(result.ok)
	assert_eq(result.catalogue, before)
	assert_eq(base, before)
	assert_true(result.board_to_runtime.is_empty())


func test_invalid_roster_and_forbidden_swimmer_are_atomic() -> void:
	for mutation: String in ["missing", "tidecoil_mount", "zero_speed", "missing_source"]:
		var roster := ADAPTER.load_roster()
		match mutation:
			"missing": roster.species.erase("aquaryn")
			"tidecoil_mount": roster.species.tidecoil.swim_mount.compatible = true
			"zero_speed": roster.species.aquaryn.swim_mount.speed_mps = 0.0
			"missing_source": roster.species.cannonback.placeholder.source_species = "missing_species"
		var result: Dictionary = ADAPTER.merge_catalogue(original, roster)
		assert_false(result.ok, mutation)
		assert_eq(result.catalogue, original, mutation)
		assert_true(result.board_to_runtime.is_empty(), mutation)


func test_production_species_spawn_preserves_names_stats_moves_and_five_capabilities() -> void:
	var result: Dictionary = ADAPTER.merge_catalogue(original)
	assert_true(result.ok)
	SPECIES._table = result.catalogue
	var roster := ADAPTER.load_roster()
	var swimmers := 0
	for id: String in ADAPTER.BOARD_IDS:
		var runtime: String = result.board_to_runtime[id]
		var definition: Dictionary = SPECIES.definition(runtime)
		var member: RefCounted = SPECIES.spawn(runtime)
		assert_true(member != null, runtime)
		assert_eq(member.species_id, runtime)
		assert_eq(member.display_name, roster.species[id].display_name)
		assert_eq(member.base_hp, roster.species[id].base_hp)
		assert_eq(member.move_quick, roster.species[id].moves.quick)
		assert_eq(member.move_charged, roster.species[id].moves.charged)
		assert_eq(definition.swim_mount, roster.species[id].swim_mount)
		assert_eq(definition.has("rideable"), bool(definition.swim_mount.compatible))
		if bool(definition.swim_mount.compatible):
			var measurements: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_mounts.json"))
			assert_eq(definition.rideable.mount_offset, measurements.mounts[runtime].mount_offset)
			assert_eq(definition.rideable.requires_item, "swim_saddle")
			swimmers += 1
	assert_eq(swimmers, 5)
	assert_false(SPECIES.definition("water_tidecoil").swim_mount.compatible)
	assert_false(SPECIES.definition("water_abyssal_guardian").swim_mount.compatible)
	assert_eq(SPECIES.definition("mosshell"), original.mosshell)


func test_installed_models_contain_every_authored_animation_and_existing_moves() -> void:
	var result: Dictionary = ADAPTER.merge_catalogue(original)
	var checked_models: Dictionary = {}
	var moves: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/moves/moves.json"))
	for id: String in ADAPTER.BOARD_IDS:
		var definition: Dictionary = result.catalogue[ADAPTER.runtime_id(id)]
		var look: Dictionary = definition.placeholder
		assert_true(float(look.height) > 0.0 and float(look.radius) > 0.0)
		for slot: String in ["quick", "charged"]:
			assert_true(moves.moves.has(definition.moves[slot]), id + " " + slot)
		var path := str(look.model)
		if not checked_models.has(path):
			assert_true(ResourceLoader.exists(path), path)
			var scene: PackedScene = load(path)
			var model := scene.instantiate()
			var names: Array[String] = []
			for animation_player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
				for animation: String in animation_player.get_animation_list():
					names.append(animation)
			checked_models[path] = names
			model.free()
		for role: String in look.animations:
			assert_true(str(look.animations[role]) in checked_models[path], id + " missing animation " + role)
