extends "res://tests/test_case.gd"
const ADAPTER := preload("res://scripts/world/water_encounter_runtime_data.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")
var world: Dictionary
var characters: Dictionary
var encounters: Dictionary
var field: RefCounted
var result: Dictionary
func before_each() -> void:
	world = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	characters = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	encounters = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_encounters.json"))
	field = FIELD.new(world)
	result = ADAPTER.build(world, characters, encounters, field.height_at)
func test_complete_counts_and_namespaced_board_species_without_story_leak() -> void:
	assert_true(result.ok, str(result.errors))
	assert_eq(result.trainer_specs.size(), 24)
	assert_eq(result.encounter_config.wild_sites.size(), 240)
	assert_eq(result.chapter.encounter_tables.size(), encounters.tables.size())
	assert_eq(result.board_to_runtime.size(), 12)
	assert_false(JSON.stringify(result).to_lower().contains("cloudreach"))
	var encountered: Dictionary = {}
	for table: Dictionary in result.chapter.encounter_tables:
		for entry: Dictionary in table.entries:
			encountered[CATALOG.board_id(entry.placeholder_species)] = true
	for key: String in ["named_encounters", "scripted_encounter_references"]:
		for entry: Dictionary in result.encounter_config[key]:
			encountered[CATALOG.board_id(entry.species)] = true
	assert_eq(encountered.size(), 12)
	assert_false(encountered.has(""))
	for board: String in CATALOG.BOARD_IDS:
		assert_eq(result.board_to_runtime[board], CATALOG.runtime_id(board))
func test_trainer_levels_rewards_and_unique_defeat_flags_preserve_content() -> void:
	var flags: Dictionary = {}
	var retained_exceptions: Dictionary = {}
	for authored: Dictionary in characters.trainers:
		var spec: Dictionary = result.trainer_specs[authored.id]
		assert_eq(spec.name, authored.display_name)
		assert_eq(spec.config_key, authored.body_profile)
		assert_false(spec.rechallenge)
		assert_eq(spec.defeat_flag, "defeated_" + str(authored.id))
		assert_false(flags.has(spec.defeat_flag))
		flags[spec.defeat_flag] = true
		assert_false(spec.reward.has("flags"))
		assert_eq(spec.team.size(), authored.team.size())
		for index in spec.team.size():
			assert_eq(spec.team[index].level, authored.team[index].level)
			assert_true(spec.team[index].trainer_owned)
			var source := str(authored.team[index].species)
			if source in ["brooktail", "galecrest"]:
				retained_exceptions[source] = true
				assert_eq(spec.team[index].species, source)
			else:
				assert_eq(spec.team[index].species, CATALOG.runtime_id(source))
	assert_true(retained_exceptions.has("brooktail"))
	assert_true(retained_exceptions.has("galecrest"))
	assert_eq(result.encounter_config.active_wild_cap_per_peer, 16)
	assert_eq(result.encounter_config.activation_distance_m, 100)
func test_positions_are_regrounded_and_existing_npc_bodies_are_reused() -> void:
	var centres: Dictionary = {}
	for island: Dictionary in world.islands:
		centres[island.id] = island.center_xz_m
	var npcs: Dictionary = {}
	for npc: Dictionary in characters.npcs:
		npcs[npc.id] = npc
	var reused := 0
	for authored: Dictionary in characters.trainers:
		var spec: Dictionary = result.trainer_specs[authored.id]
		var source: Dictionary = npcs.get(authored.npc_entity_id, authored)
		var centre: Array = centres[source.island_id]
		var x := float(centre[0]) + float(source.island_local_offset[0])
		var z := float(centre[1]) + float(source.island_local_offset[2])
		assert_almost_eq(spec.position[0], x)
		assert_almost_eq(spec.position[2], z)
		assert_almost_eq(spec.position[1], field.height_at(x, z))
		if npcs.has(authored.npc_entity_id):
			reused += 1
			assert_eq(spec.reuse_npc_id, authored.npc_entity_id)
		else:
			assert_eq(spec.reuse_npc_id, "")
	assert_eq(reused, 3)
	var ids: Dictionary = {}
	for index in result.encounter_config.wild_sites.size():
		var site: Dictionary = result.encounter_config.wild_sites[index]
		var original: Dictionary = encounters.wild_sites[index]
		assert_false(ids.has(site.id))
		ids[site.id] = true
		assert_eq(site.position[0], original.position[0])
		assert_eq(site.position[2], original.position[2])
		assert_almost_eq(site.position[1], field.height_at(site.position[0], site.position[2]))
		assert_eq(site.count, original.count)
func test_table_levels_weights_and_named_replacements_remain_exact() -> void:
	for index in encounters.tables.size():
		var table: Dictionary = result.chapter.encounter_tables[index]
		var original: Dictionary = encounters.tables[index]
		assert_eq(table.level_range, original.level_range)
		assert_eq(table.id, original.id)
		for j in table.entries.size():
			assert_eq(table.entries[j].weight, original.entries[j].weight)
			assert_eq(table.entries[j].night_weight, original.entries[j].night_weight)
	for index in encounters.named_encounters.size():
		var named: Dictionary = result.encounter_config.named_encounters[index]
		assert_eq(named.replaces_wild_site_id, encounters.named_encounters[index].replaces_wild_site_id)
		assert_eq(named.level, encounters.named_encounters[index].level)
func test_invalid_species_or_ground_fails_atomically_and_inputs_do_not_mutate() -> void:
	var before: Dictionary = encounters.duplicate(true)
	var changed := encounters.duplicate(true)
	changed.tables[0].entries[0].species_id = "unapproved_species"
	var invalid := ADAPTER.build(world, characters, changed, field.height_at)
	assert_false(invalid.ok)
	assert_true(invalid.trainer_specs.is_empty())
	assert_true(invalid.encounter_config.is_empty())
	var no_ground := ADAPTER.build(world, characters, encounters, func(_x: float, _z: float) -> float: return NAN)
	assert_false(no_ground.ok)
	assert_true(no_ground.chapter.is_empty())
	assert_eq(encounters, before)
