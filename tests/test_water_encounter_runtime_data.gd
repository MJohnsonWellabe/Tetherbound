extends "res://tests/test_case.gd"
const ADAPTER := preload("res://scripts/world/water_encounter_runtime_data.gd")
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")
const FIELD := preload("res://scripts/world/water_heightfield.gd")


class NamedSpawnProbeDirector:
	extends "res://scripts/combat/water_encounter_director.gd"
	const CREATURE := preload("res://scenes/creatures/creature.tscn")
	const WILD := preload("res://scripts/creatures/wild_creature.gd")
	var probe_positions: Array[Vector3] = []
	var spawn_calls: Array[Dictionary] = []
	var spawned_bodies: Array[Node3D] = []
	var cleared_ids: Dictionary = {}

	func occupied_positions() -> Array[Vector3]:
		return probe_positions

	func world_seed() -> int:
		return 13579

	func _flags_hold(_flags: Array) -> bool:
		return true

	func _once_cleared(id: String) -> bool:
		return cleared_ids.has(id)

	func spawn_wild(species: String, spot: Vector3, opts: Dictionary = {}) -> Node3D:
		spawn_calls.append({"species": species, "spot": spot, "opts": opts.duplicate(true)})
		var wild: Node3D = CREATURE.instantiate()
		wild.set_script(WILD)
		wild.call("populate", species, null)
		spawned_bodies.append(wild)
		return wild

	func site_state(id: String) -> Dictionary:
		return {
			"spawned": _site_spawned.has(id),
			"failed": _site_failures.has(id),
			"members": _site_members.get(id, []).duplicate(),
		}

	func dispose() -> void:
		for body: Node3D in spawned_bodies:
			if is_instance_valid(body):
				body.free()

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
	assert_eq(result.encounter_config.wild_sites.size(), int(encounters.census.wild_clusters))
	assert_true(result.encounter_config.wild_sites.size() > 240)
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
			assert_eq(spec.team[index].species, CATALOG.runtime_id(source))
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
	var surface_sites := 0
	var surface_sites_over_deep_water := 0
	for index in result.encounter_config.wild_sites.size():
		var site: Dictionary = result.encounter_config.wild_sites[index]
		var original: Dictionary = encounters.wild_sites[index]
		assert_false(ids.has(site.id))
		ids[site.id] = true
		assert_eq(site.position[0], original.position[0])
		assert_eq(site.position[2], original.position[2])
		if str(original.get("placement_mode", "ground")) == "water_surface":
			surface_sites += 1
			assert_almost_eq(site.position[1], float(world.terrain.sea_level_m))
			if absf(site.position[1] - field.height_at(site.position[0], site.position[2])) > 1.0:
				surface_sites_over_deep_water += 1
		else:
			assert_almost_eq(site.position[1], field.height_at(site.position[0], site.position[2]))
		assert_eq(site.count, original.count)
	assert_eq(surface_sites, 17)
	assert_true(surface_sites_over_deep_water >= 15,
		"surface mode must materially differ from terrain grounding across the sailing route")


func test_surface_site_contract_rejects_wrong_waterline_or_submerge() -> void:
	var changed := encounters.duplicate(true)
	var surface_index := -1
	for index in changed.wild_sites.size():
		if str(changed.wild_sites[index].get("placement_mode", "")) == "water_surface":
			surface_index = index
			break
	assert_true(surface_index >= 0)
	if surface_index < 0:
		return
	changed.wild_sites[surface_index].surface_y_m = 3.0
	var wrong_level := ADAPTER.build(world, characters, changed, field.height_at)
	assert_false(wrong_level.ok)
	assert_true(str(wrong_level.errors).contains("disagrees with world sea level"))
	changed = encounters.duplicate(true)
	changed.wild_sites[surface_index].surface_submerge_fraction = 0.75
	var wrong_submerge := ADAPTER.build(world, characters, changed, field.height_at)
	assert_false(wrong_submerge.ok)
	assert_true(str(wrong_submerge.errors).contains("invalid submerge fraction"))
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


func test_reserved_named_sites_use_the_fixed_actor_and_once_flag_in_production_selector() -> void:
	var sites_by_id: Dictionary = {}
	for site: Dictionary in result.encounter_config.wild_sites:
		sites_by_id[str(site.id)] = site
	var tables_by_id: Dictionary = {}
	for table: Dictionary in result.chapter.encounter_tables:
		tables_by_id[str(table.id)] = table
	var seen: Dictionary = {}
	for named: Dictionary in result.encounter_config.named_encounters:
		var site: Dictionary = sites_by_id.get(str(named.replaces_wild_site_id), {})
		assert_false(site.is_empty(), str(named.id) + " keeps its reserved wild site")
		if site.is_empty():
			continue
		var plans := DIRECTOR.site_spawn_plans(site, tables_by_id.get(str(site.table_id), {}),
			result.encounter_config.named_encounters, 987654)
		assert_eq(plans.size(), 1, str(named.id) + " resolves to exactly one authored actor")
		if plans.size() != 1:
			continue
		var plan: Dictionary = plans[0]
		assert_eq(plan.id, named.id)
		assert_eq(plan.species, named.species)
		assert_eq(plan.position, named.position)
		assert_eq(plan.display_name, named.display_name)
		assert_eq(plan.opts.name, named.id)
		assert_eq(plan.opts.level, named.level)
		assert_eq(plan.opts.once_id, named.completion_flag)
		seen[str(named.id)] = true
	assert_eq(seen.size(), 5, "all authored Water named encounters reach the production selector")

	var malformed: Dictionary = sites_by_id[str(
		result.encounter_config.named_encounters[0].replaces_wild_site_id)].duplicate(true)
	malformed.named_replacement_id = "missing_named_actor"
	var rejected := DIRECTOR.site_spawn_plans(malformed,
		tables_by_id.get(str(malformed.table_id), {}), result.encounter_config.named_encounters, 987654)
	assert_true(rejected.is_empty(), "a broken reserved reference fails closed instead of rolling a random substitute")


func test_unreserved_site_keeps_deterministic_table_population() -> void:
	var ordinary: Dictionary = {}
	for site: Dictionary in result.encounter_config.wild_sites:
		if str(site.get("named_replacement_id", "")).is_empty():
			ordinary = site
			break
	assert_false(ordinary.is_empty())
	if ordinary.is_empty():
		return
	var table: Dictionary = {}
	for candidate: Dictionary in result.chapter.encounter_tables:
		if str(candidate.id) == str(ordinary.table_id):
			table = candidate
			break
	var first := DIRECTOR.site_spawn_plans(ordinary, table,
		result.encounter_config.named_encounters, 24680)
	var second := DIRECTOR.site_spawn_plans(ordinary, table,
		result.encounter_config.named_encounters, 24680)
	assert_eq(first, second, "ordinary table rolls remain deterministic")
	assert_eq(first.size(), int(ordinary.count))
	for plan: Dictionary in first:
		assert_eq(plan.id, "")
		assert_true(CATALOG.BOARD_IDS.has(CATALOG.board_id(str(plan.species))))


func test_spawn_bridge_applies_named_identity_metadata_once_opts_and_clean_cleared_state() -> void:
	var named: Dictionary = result.encounter_config.named_encounters[0]
	var site: Dictionary = {}
	for candidate: Dictionary in result.encounter_config.wild_sites:
		if str(candidate.id) == str(named.replaces_wild_site_id):
			site = candidate
			break
	var table: Dictionary = {}
	for candidate: Dictionary in result.chapter.encounter_tables:
		if str(candidate.id) == str(site.table_id):
			table = candidate
			break
	assert_false(site.is_empty())
	assert_false(table.is_empty())
	if site.is_empty() or table.is_empty():
		return
	var named_position := Vector3(float(named.position[0]), float(named.position[1]),
		float(named.position[2]))

	var director := NamedSpawnProbeDirector.new()
	director.chapter = {"encounter_tables": [table]}
	director.encounter_config = {"wild_sites": [site], "named_encounters": [named],
		"activation_distance_m": 100.0, "active_wild_cap_per_peer": 16,
		"wild_respawn_seconds": 240.0}
	director.probe_positions = [named_position]
	director.call("_spawn_available_sites")
	assert_eq(director.spawn_calls.size(), 1, "the production site loop consumes the named plan")
	assert_eq(director.spawned_bodies.size(), 1)
	if director.spawn_calls.size() == 1 and director.spawned_bodies.size() == 1:
		var call: Dictionary = director.spawn_calls[0]
		var body: Node3D = director.spawned_bodies[0]
		assert_eq(call.species, named.species)
		assert_eq(call.spot, named_position)
		assert_eq(call.opts.name, named.id)
		assert_eq(call.opts.level, named.level)
		assert_eq(call.opts.once_id, named.completion_flag)
		assert_eq(body.get("display_name"), named.display_name)
		assert_eq((body.get("instance") as RefCounted).get("display_name"), named.display_name)
		assert_eq(body.get_meta("water_named_encounter", ""), named.id)
		assert_eq(body.get_meta("water_reward_role", ""), named.reward_role)
	var live_state := director.site_state(str(site.id))
	assert_true(live_state.spawned)
	assert_false(live_state.failed)
	assert_eq(live_state.members.size(), 1)
	director.dispose()
	director.free()

	var cleared := NamedSpawnProbeDirector.new()
	cleared.chapter = {"encounter_tables": [table]}
	cleared.encounter_config = {"wild_sites": [site], "named_encounters": [named],
		"activation_distance_m": 100.0, "active_wild_cap_per_peer": 16,
		"wild_respawn_seconds": 240.0}
	cleared.probe_positions = [named_position]
	cleared.cleared_ids[str(named.completion_flag)] = true
	cleared.call("_spawn_available_sites")
	var cleared_state := cleared.site_state(str(site.id))
	assert_true(cleared_state.spawned, "a resolved named reservation settles as intentionally absent")
	assert_false(cleared_state.failed, "a resolved named reservation is not a spawn defect")
	assert_true(cleared_state.members.is_empty())
	assert_true(cleared.spawn_calls.is_empty())
	cleared.dispose()
	cleared.free()

	var malformed_site := site.duplicate(true)
	malformed_site.named_replacement_id = "missing_named_actor"
	var malformed := NamedSpawnProbeDirector.new()
	malformed.chapter = {"encounter_tables": [table]}
	malformed.encounter_config = {"wild_sites": [malformed_site], "named_encounters": [named],
		"activation_distance_m": 100.0, "active_wild_cap_per_peer": 16,
		"wild_respawn_seconds": 240.0}
	malformed.probe_positions = [named_position]
	malformed.call("_spawn_available_sites")
	var malformed_state := malformed.site_state(str(site.id))
	assert_false(malformed_state.spawned)
	assert_true(malformed_state.failed, "a malformed reservation remains a visible spawn defect")
	assert_true(malformed.spawn_calls.is_empty())
	malformed.dispose()
	malformed.free()

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
