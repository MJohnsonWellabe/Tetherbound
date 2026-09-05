extends "res://tests/test_case.gd"

## Pure-data checks for the Cloudreach Phase 3 chapter contract.
##
## These tests pin the directive's durable gameplay requirements: one causal
## three-act chain, functional Fly as the midpoint gate, a separate grounded
## route, distributed NPC/content coverage, replaceable encounter art, authored
## persistent rewards, and a real finale with aftermath. They deliberately do
## not pin exact prose, coordinates, species choices, or balance values that a
## later implementation/visual pass should remain free to tune.

const CONFIG_PATH := "res://data/config/cloudreach_chapter.json"
const WORLD_PATH := "res://data/config/cloudreach_world.json"
const ART_PATH := "res://data/config/art.json"
const ITEMS_PATH := "res://data/items/items.json"

const REGION_IDS := [
	"gate_lower_cliffs",
	"broken_causeways",
	"windscar_ravine",
	"high_roost_sky_shrine",
	"upper_cloudreach",
	"summit_final_stronghold",
]

var _chapter_cache: Dictionary = {}
var _world_cache: Dictionary = {}
var _art_cache: Dictionary = {}
var _items_cache: Dictionary = {}


func _load_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _chapter() -> Dictionary:
	if _chapter_cache.is_empty():
		_chapter_cache = _load_dictionary(CONFIG_PATH)
	return _chapter_cache


func _world() -> Dictionary:
	if _world_cache.is_empty():
		_world_cache = _load_dictionary(WORLD_PATH)
	return _world_cache


func _art() -> Dictionary:
	if _art_cache.is_empty():
		_art_cache = _load_dictionary(ART_PATH)
	return _art_cache


func _items() -> Dictionary:
	if _items_cache.is_empty():
		_items_cache = _load_dictionary(ITEMS_PATH)
	return _items_cache.get("items", {}) as Dictionary


func _list(key: String) -> Array:
	var value: Variant = _chapter().get(key, [])
	return value as Array if value is Array else []


func _entry(entries: Array, id: String) -> Dictionary:
	for value: Variant in entries:
		if value is Dictionary and str((value as Dictionary).get("id", "")) == id:
			return value as Dictionary
	return {}


func _world_regions() -> Dictionary:
	var out := {}
	for value: Variant in (_world().get("regions", []) as Array):
		var region := value as Dictionary
		out[str(region.get("id", ""))] = region
	return out


func _world_landmark_ids() -> Array[String]:
	var out: Array[String] = []
	for value: Variant in (_world().get("landmarks", []) as Array):
		out.append(str((value as Dictionary).get("id", "")))
	return out


func _is_point(value: Variant) -> bool:
	if not value is Array or (value as Array).size() != 3:
		return false
	for coordinate: Variant in value as Array:
		if typeof(coordinate) != TYPE_FLOAT and typeof(coordinate) != TYPE_INT:
			return false
	return true


func _inside_region(point: Array, region_id: String) -> bool:
	var region: Dictionary = _world_regions().get(region_id, {})
	var bounds: Dictionary = region.get("bounds", {})
	if point.size() != 3 or bounds.is_empty():
		return false
	return (
		float(point[0]) >= float(bounds.get("min_x", INF))
		and float(point[0]) <= float(bounds.get("max_x", -INF))
		and float(point[1]) >= float(bounds.get("min_y", INF))
		and float(point[1]) <= float(bounds.get("max_y", -INF))
		and float(point[2]) >= float(bounds.get("min_z", INF))
		and float(point[2]) <= float(bounds.get("max_z", -INF))
	)


func _persistent_flags() -> Array[String]:
	var out: Array[String] = []
	var groups: Dictionary = _chapter().get("persistent_flags", {})
	for group_id: Variant in groups:
		for flag: Variant in groups[group_id] as Array:
			out.append(str(flag))
	return out


func _main_objectives() -> Array:
	var out: Array = []
	for act_value: Variant in _list("acts"):
		out.append_array((act_value as Dictionary).get("objectives", []) as Array)
	return out


func _objective_with_flag(flag_id: String) -> Dictionary:
	for value: Variant in _main_objectives():
		var objective := value as Dictionary
		if str(objective.get("flag_id", "")) == flag_id:
			return objective
	return {}


func _act_order_for_flag(flag_id: String) -> int:
	for act_value: Variant in _list("acts"):
		var act := act_value as Dictionary
		for objective_value: Variant in (act.get("objectives", []) as Array):
			if str((objective_value as Dictionary).get("flag_id", "")) == flag_id:
				return int(act.get("order", 0))
	return 0


func test_chapter_contract_parses_and_targets_cloudreach() -> void:
	assert_false(_chapter().is_empty(), "%s is missing or invalid JSON" % CONFIG_PATH)
	assert_eq(int(_chapter().get("schema_version", 0)), 1)
	assert_eq(str(_chapter().get("realm_id", "")), "cloudreach")
	assert_eq(str(_chapter().get("world_contract", "")), WORLD_PATH)
	assert_false(_world().is_empty(), "the linked Phase 2 world contract is unavailable")


func test_story_problem_is_structured_around_the_authorized_conflict() -> void:
	var problem: Dictionary = _chapter().get("story_problem", {})
	assert_eq(str(problem.get("antagonist", "")), "team_tether")
	assert_false(str(problem.get("network_name", "")).is_empty(), "the regional mechanism has no name")
	var effects: Array = problem.get("regional_effects", [])
	for required in ["ancestral_wind_routes_pinned", "wind_bottled_for_extraction", "locals_stranded", "causeway_travel_broken"]:
		assert_true(effects.has(required), "regional conflict does not encode '%s'" % required)
	assert_false(str(problem.get("escalation_truth", "")).is_empty(), "Act II has no escalation truth")
	assert_false(str(problem.get("resolution", "")).is_empty(), "Act III has no authored resolution")


func test_main_chain_has_three_causal_acts_and_persistent_flags() -> void:
	var acts := _list("acts")
	assert_eq(acts.size(), 3, "Cloudreach requires one clear three-act chapter")
	var catalog := _persistent_flags()
	var objective_ids: Array[String] = []
	var objective_flags: Array[String] = []
	var previous_completion := "realm_key_cloudreach"
	for index in acts.size():
		var act := acts[index] as Dictionary
		assert_eq(int(act.get("order", 0)), index + 1, "acts must stay in playable order")
		assert_true((act.get("entry_flags", []) as Array).has(previous_completion),
			"act %d does not enter from the preceding completion flag" % (index + 1))
		var objectives: Array = act.get("objectives", [])
		assert_true(objectives.size() >= 4, "act %d is a beat list, not a chapter act" % (index + 1))
		for value: Variant in objectives:
			var objective := value as Dictionary
			var id := str(objective.get("id", ""))
			var flag_id := str(objective.get("flag_id", ""))
			assert_false(id.is_empty(), "a main objective has no id")
			assert_false(objective_ids.has(id), "main objective id '%s' is duplicated" % id)
			objective_ids.append(id)
			assert_false(flag_id.is_empty(), "main objective '%s' has no completion flag" % id)
			assert_false(objective_flags.has(flag_id), "main completion flag '%s' is duplicated" % flag_id)
			objective_flags.append(flag_id)
			assert_true(catalog.has(flag_id), "main flag '%s' is not declared persistent" % flag_id)
			assert_false(str(objective.get("label", "")).is_empty(), "objective '%s' has no task-feed label" % id)
			assert_false(str(objective.get("how", "")).is_empty(), "objective '%s' gives no actionable guidance" % id)
		previous_completion = str(act.get("completion_flag", ""))
		assert_true(catalog.has(previous_completion), "act completion '%s' is not persistent" % previous_completion)
		assert_true(objective_flags.has(previous_completion), "act completion has no objective that can set it")


func test_midpoint_unlocks_fly_then_a_separate_grounded_route() -> void:
	var fly := _objective_with_flag("fly_traversal_unlocked")
	var shrine := _objective_with_flag("sky_shrine_reached")
	var truth := _objective_with_flag("storm_anchor_engine_truth_learned")
	var ground := _objective_with_flag("cloudreach_upper_route_unlocked")
	for objective in [fly, shrine, truth, ground]:
		assert_false((objective as Dictionary).is_empty(), "a required Act II traversal beat is missing")
	assert_eq(_act_order_for_flag("fly_traversal_unlocked"), 2)
	assert_eq(_act_order_for_flag("sky_shrine_reached"), 2)
	assert_eq(str(shrine.get("region_id", "")), "high_roost_sky_shrine")
	assert_true((shrine.get("requires_flags", []) as Array).has("fly_traversal_unlocked"),
		"the sheer-cliff shrine no longer requires functional Fly")
	assert_true((truth.get("requires_flags", []) as Array).has("sky_shrine_reached"),
		"the summit-engine truth can be learned before reaching the shrine")
	assert_true((ground.get("requires_flags", []) as Array).has("storm_anchor_engine_truth_learned"),
		"the grounded route unlock bypasses the shrine revelation")
	assert_eq(str(ground.get("completion_event", "")), "sky_shrine_counterweight_released",
		"Act II must release the physical counterweight route authored by Phase 2")


func test_optional_content_has_multistep_exploration_fly_and_trainer_chains() -> void:
	var sides := _list("side_chains")
	assert_true(sides.size() >= 3, "Cloudreach needs several optional regional tasks")
	var categories: Array[String] = []
	var has_fly_step := false
	var has_visible_change := false
	for value: Variant in sides:
		var side := value as Dictionary
		categories.append(str(side.get("category", "")))
		var steps: Array = side.get("steps", [])
		assert_true(steps.size() >= 2, "side chain '%s' is not multi-step" % str(side.get("id", "?")))
		assert_eq(str((steps[-1] as Dictionary).get("flag_id", "")), str(side.get("completion_flag", "")),
			"side chain '%s' cannot complete through its final step" % str(side.get("id", "?")))
		assert_eq(str(side.get("persistence", "")), "save")
		if not str(side.get("visible_state_change", "")).is_empty():
			has_visible_change = true
		for step_value: Variant in steps:
			if ((step_value as Dictionary).get("requires_flags", []) as Array).has("fly_traversal_unlocked"):
				has_fly_step = true
	assert_true(categories.has("exploration"), "no exploration-driven side task exists")
	assert_true(categories.has("trainer_completion"), "no trainer-completion objective exists")
	assert_true(categories.has("fly_exploration"), "no optional Fly exploration chain exists")
	assert_true(has_fly_step, "no optional objective changes after Fly unlock")
	assert_true(has_visible_change, "optional tasks produce no visible world feedback")


func test_npc_cast_reuses_installed_bodies_and_is_distributed() -> void:
	var known_regions := _world_regions()
	var used_regions: Array[String] = []
	var roles: Array[String] = []
	var ids: Array[String] = []
	for value: Variant in _list("npcs"):
		var npc := value as Dictionary
		var id := str(npc.get("id", ""))
		var region_id := str(npc.get("region_id", ""))
		var body := str(npc.get("body_profile", ""))
		assert_false(id.is_empty(), "an NPC has no id")
		assert_false(ids.has(id), "NPC id '%s' is duplicated" % id)
		ids.append(id)
		assert_true(known_regions.has(region_id), "NPC '%s' names unknown region '%s'" % [id, region_id])
		if not used_regions.has(region_id):
			used_regions.append(region_id)
		assert_true(_art().has(body), "NPC '%s' names uninstalled body profile '%s'" % [id, body])
		assert_false(str(npc.get("portrait_profile", "")).is_empty(), "NPC '%s' has no portrait profile" % id)
		assert_false((npc.get("dialogue_ids", []) as Array).is_empty(), "NPC '%s' has no dialogue contract" % id)
		assert_false(str(npc.get("progression_relevance", "")).is_empty(), "NPC '%s' has no purpose" % id)
		for role: Variant in (npc.get("roles", []) as Array):
			if not roles.has(str(role)):
				roles.append(str(role))
	assert_true(used_regions.size() >= 5, "the NPC cast is stacked into too few regions")
	for required_role in ["arrival_guide", "local_resident", "cliff_traveler", "trainer", "bridge_watch", "affected_local", "memorable_side_character", "antagonist_representative", "late_story_npc"]:
		assert_true(roles.has(required_role), "the cast has no '%s' role" % required_role)


func test_trainer_ladder_escalates_through_composition_and_replaceable_teams() -> void:
	var trainers := _list("trainer_ladder")
	assert_true(trainers.size() >= 6, "Cloudreach has no chapter-length trainer ladder")
	var previous_min := 0
	for value: Variant in trainers:
		var trainer := value as Dictionary
		var id := str(trainer.get("id", "?"))
		var levels: Array = trainer.get("level_band", [])
		assert_eq(levels.size(), 2, "trainer '%s' has no level band" % id)
		if levels.size() != 2:
			continue
		assert_true(int(levels[0]) >= previous_min, "trainer ladder gets weaker at '%s'" % id)
		assert_true(int(levels[1]) >= int(levels[0]), "trainer '%s' has an inverted level band" % id)
		previous_min = int(levels[0])
		assert_true(_art().has(str(trainer.get("body_profile", ""))), "trainer '%s' has no installed body" % id)
		var team: Dictionary = trainer.get("team_contract", {})
		assert_true(bool(team.get("replaceable", false)), "trainer '%s' hard-wires its placeholder team" % id)
		assert_false(str(team.get("selection_key", "")).is_empty(), "trainer '%s' has no replacement hook" % id)
		assert_true((team.get("slots", []) as Array).size() >= 2, "trainer '%s' is not a composed encounter" % id)
	assert_true(int((trainers[0] as Dictionary).get("level_band", [0, 0])[0]) >= 19,
		"Cloudreach opens below the Meadows ending strength")
	assert_true(int((trainers[-1] as Dictionary).get("level_band", [0, 0])[1]) >= 33,
		"the second biome does not build to a substantial final challenge")


func test_wild_encounter_tables_cover_regions_without_freezing_final_species() -> void:
	var covered: Array[String] = []
	var previous_min := 0
	for value: Variant in _list("encounter_tables"):
		var table := value as Dictionary
		var id := str(table.get("id", "?"))
		assert_true(bool(table.get("replaceable", false)), "encounter table '%s' freezes placeholder species" % id)
		assert_false(str(table.get("selection_key", "")).is_empty(), "encounter table '%s' has no replacement hook" % id)
		assert_true(bool(table.get("catchable", false)), "table '%s' removes catching from wild combat" % id)
		var levels: Array = table.get("level_range", [])
		assert_eq(levels.size(), 2, "table '%s' has no level range" % id)
		if levels.size() == 2:
			assert_true(int(levels[0]) >= previous_min, "wild difficulty falls at '%s'" % id)
			previous_min = int(levels[0])
		var entries: Array = table.get("entries", [])
		assert_true(entries.size() >= 3, "table '%s' has no encounter composition" % id)
		for entry_value: Variant in entries:
			var entry := entry_value as Dictionary
			assert_false(str(entry.get("role", "")).is_empty(), "table '%s' has a roleless slot" % id)
			assert_false(str(entry.get("placeholder_species", "")).is_empty(), "table '%s' has no usable placeholder" % id)
			assert_true(int(entry.get("weight", 0)) > 0, "table '%s' has a zero-weight slot" % id)
		for region: Variant in (table.get("region_ids", []) as Array):
			if not covered.has(str(region)):
				covered.append(str(region))
	for region_id in REGION_IDS:
		assert_true(covered.has(region_id), "region '%s' has no replaceable wild encounter table" % region_id)


func test_pickups_are_authored_persistent_and_cover_directive_rewards() -> void:
	var ids: Array[String] = []
	var item_ids: Array[String] = []
	var placements: Array[String] = []
	var fly_only_count := 0
	for value: Variant in _list("pickups"):
		var pickup := value as Dictionary
		var id := str(pickup.get("id", ""))
		var item_id := str(pickup.get("item_id", ""))
		var region_id := str(pickup.get("region_id", ""))
		assert_false(id.is_empty(), "an authored pickup has no id")
		assert_false(ids.has(id), "pickup id '%s' is duplicated" % id)
		ids.append(id)
		assert_true(_items().has(item_id), "pickup '%s' names unknown item '%s'" % [id, item_id])
		item_ids.append(item_id)
		assert_true(bool(pickup.get("persistent", false)), "pickup '%s' is not save-persistent" % id)
		assert_true(bool(pickup.get("one_time", false)), "pickup '%s' can be farmed after collection" % id)
		var position: Variant = pickup.get("position", [])
		assert_true(_is_point(position), "pickup '%s' has no 3D position" % id)
		if _is_point(position):
			assert_true(_inside_region(position as Array, region_id), "pickup '%s' is outside '%s'" % [id, region_id])
		var placement := str(pickup.get("placement", ""))
		if not placements.has(placement):
			placements.append(placement)
		if str(pickup.get("requires_unlock", "")) == "fly_traversal_unlocked":
			fly_only_count += 1
	for required_item in ["good_candy", "great_candy", "rare_candy", "potion_small", "potion_large", "revive"]:
		assert_true(item_ids.has(required_item), "Cloudreach has no authored '%s' reward" % required_item)
	assert_true(item_ids.has("tm_wind_blade") or item_ids.has("tm_aerial_flash") or item_ids.has("tm_heavenfall"),
		"Cloudreach has no authored TM findable")
	assert_true(placements.size() >= 6, "pickups are uniformly scattered instead of authored by context")
	assert_true(fly_only_count >= 3, "Fly opens no meaningful pickup pockets")


func test_resource_tier_has_distinct_materials_and_authored_nodes() -> void:
	var tier: Dictionary = _chapter().get("resource_tier", {})
	assert_false(str(tier.get("id", "")).is_empty(), "Cloudreach has no resource-tier id")
	assert_false(str(tier.get("implementation_status", "")).is_empty(), "resource implementation gap is not disclosed")
	var resources: Array = tier.get("resources", [])
	assert_true(resources.size() >= 5, "Cloudreach has no meaningful new resource tier")
	var resource_ids: Array[String] = []
	for value: Variant in resources:
		var resource := value as Dictionary
		var id := str(resource.get("id", ""))
		assert_false(id.is_empty(), "a resource has no id")
		assert_false(resource_ids.has(id), "resource '%s' is duplicated" % id)
		resource_ids.append(id)
		assert_false((resource.get("region_ids", []) as Array).is_empty(), "resource '%s' has no habitat" % id)
		assert_false((resource.get("uses", []) as Array).is_empty(), "resource '%s' prepares nothing" % id)
	var node_resources: Array[String] = []
	for value: Variant in (tier.get("nodes", []) as Array):
		var node := value as Dictionary
		var resource_id := str(node.get("resource_id", ""))
		assert_true(resource_ids.has(resource_id), "node names unknown resource '%s'" % resource_id)
		if not node_resources.has(resource_id):
			node_resources.append(resource_id)
		var position: Variant = node.get("position", [])
		assert_true(_is_point(position), "resource node '%s' has no 3D position" % str(node.get("id", "?")))
		if _is_point(position):
			assert_true(_inside_region(position as Array, str(node.get("region_id", ""))),
				"resource node '%s' is outside its region" % str(node.get("id", "?")))
	for resource_id in resource_ids:
		assert_true(node_resources.has(resource_id), "resource '%s' has no authored world node" % resource_id)


func test_camps_support_recovery_without_punitive_hunger() -> void:
	var contract: Dictionary = _chapter().get("camping_contract", {})
	assert_eq(str(contract.get("satiety_policy", "")), "reuse_existing_slow_nonlethal_drain")
	var camps: Array = contract.get("camps", [])
	assert_true(camps.size() >= 4, "long Cloudreach routes have too few safe rest locations")
	assert_true(camps.size() < REGION_IDS.size(), "safe camps are so common that route pressure disappears")
	for value: Variant in camps:
		var camp := value as Dictionary
		var services: Array = camp.get("services", [])
		for required in ["save", "rest", "creature_recovery"]:
			assert_true(services.has(required), "camp '%s' lacks '%s'" % [str(camp.get("id", "?")), required])
		var position: Variant = camp.get("position", [])
		assert_true(_is_point(position), "camp '%s' has no 3D position" % str(camp.get("id", "?")))
		if _is_point(position):
			assert_true(_inside_region(position as Array, str(camp.get("region_id", ""))),
				"camp '%s' is outside its region" % str(camp.get("id", "?")))


func test_map_contract_uses_real_landmarks_and_covers_every_region() -> void:
	var map: Dictionary = _chapter().get("map_navigation", {})
	var covered: Array[String] = []
	var known_landmarks := _world_landmark_ids()
	for value: Variant in (map.get("region_landmarks", []) as Array):
		var marker := value as Dictionary
		var region_id := str(marker.get("region_id", ""))
		var landmark_id := str(marker.get("landmark_id", ""))
		assert_true(REGION_IDS.has(region_id), "map contract names unknown region '%s'" % region_id)
		assert_true(known_landmarks.has(landmark_id), "map contract names unknown landmark '%s'" % landmark_id)
		if not covered.has(region_id):
			covered.append(region_id)
		assert_false(str(marker.get("navigation_role", "")).is_empty(), "landmark '%s' has no navigation purpose" % landmark_id)
	for region_id in REGION_IDS:
		assert_true(covered.has(region_id), "region '%s' has no navigation landmark" % region_id)
	var unlocks: Array = map.get("unlock_events", [])
	var has_waterward_reveal := false
	for value: Variant in unlocks:
		if str((value as Dictionary).get("flag_id", "")) == "waterward_route_revealed":
			has_waterward_reveal = true
	assert_true(has_waterward_reveal, "the finale never reveals the future Waterward route")
	assert_false(str(map.get("fly_route_readability", "")).is_empty(), "Fly navigation relies only on the minimap")


func test_audio_contract_covers_atmosphere_and_marks_nonblocking_gaps() -> void:
	var required_roles := ["wind", "exposed_cliff", "bridge_creaks", "distant_bird_calls", "high_altitude_silence", "settlement", "boss_zone_escalation"]
	var roles: Array[String] = []
	var audio: Dictionary = _chapter().get("audio_atmosphere", {})
	for value: Variant in (audio.get("cues", []) as Array):
		var cue := value as Dictionary
		var role := str(cue.get("role", ""))
		roles.append(role)
		var source := str(cue.get("source", ""))
		if source.is_empty():
			assert_true(bool(cue.get("non_blocking", false)) or str(cue.get("implementation_status", "")) == "mix_only",
				"audio cue '%s' has no asset and does not disclose a safe fallback" % str(cue.get("id", "?")))
		else:
			assert_true(ResourceLoader.exists(source), "audio cue '%s' names missing source '%s'" % [str(cue.get("id", "?")), source])
	for role in required_roles:
		assert_true(roles.has(role), "Cloudreach audio has no '%s' layer" % role)
	assert_false(str(audio.get("aftermath_mix_change", "")).is_empty(), "victory produces no audio state change")


func test_progression_feedback_continues_xp_level_and_bond_signals() -> void:
	var feedback: Dictionary = _chapter().get("progression_feedback", {})
	for key in ["xp_visible", "level_progress_visible", "level_up_celebration", "bond_progress_visible", "bond_milestone_celebration", "bond_ui_understandable"]:
		assert_true(bool(feedback.get(key, false)), "Cloudreach drops progression feedback '%s'" % key)
	assert_true((feedback.get("shared_actions", []) as Array).has("fly_route_completion"),
		"functional Fly never reinforces the active creature relationship")
	assert_false(str(feedback.get("fly_bond_rule", "")).is_empty(), "Fly bonding has no explicit contract")


func test_finale_is_named_mechanical_replaceable_and_not_an_hp_sponge() -> void:
	var finale: Dictionary = _chapter().get("final_encounter", {})
	assert_eq(str(finale.get("captain_npc_id", "")), "captain_veyra")
	assert_eq(str(finale.get("region_id", "")), "summit_final_stronghold")
	assert_true(_world_landmark_ids().has(str(finale.get("arena_landmark_id", ""))), "final arena has no authored landmark")
	var tags: Array = finale.get("mechanic_tags", [])
	for required in ["wind", "positioning", "switching", "recovery_planning", "movement_skill"]:
		assert_true(tags.has(required), "final encounter does not test '%s'" % required)
	assert_eq(str(finale.get("hp_strategy", "")), "normal_progression_not_hp_sponge")
	assert_true((finale.get("phases", []) as Array).size() >= 3, "the climax is only an enlarged trainer fight")
	assert_false(str(finale.get("arena_identity", "")).is_empty(), "the final arena has no identity")
	var opposition: Dictionary = finale.get("opposition_contract", {})
	assert_true(bool(opposition.get("replaceable", false)), "final species/art are hard-wired")
	assert_eq(str(opposition.get("art_status", "")), "installed_species_placeholders")
	assert_true(_art().has(str(opposition.get("captain_body_profile", ""))), "final captain body is not installed")
	assert_true((opposition.get("slots", []) as Array).size() >= 3, "final opposition has no switching composition")


func test_victory_grants_both_realm_rewards_and_changes_the_world() -> void:
	var rewards: Dictionary = _chapter().get("rewards", {})
	var reward_flags: Array[String] = []
	for value: Variant in (rewards.get("grants", []) as Array):
		reward_flags.append(str((value as Dictionary).get("flag_id", "")))
	for required in ["realm_heart_cloudreach_earned", "realm_key_water", "waterward_route_revealed"]:
		assert_true(reward_flags.has(required), "chapter reward does not grant '%s'" % required)
		assert_true(_persistent_flags().has(required), "reward '%s' is not persistent" % required)
	var final_objective := _objective_with_flag("cloudreach_chapter_complete")
	for required in reward_flags:
		assert_true((final_objective.get("grants_flags", []) as Array).has(required),
			"the final objective cannot actually grant '%s'" % required)
	var aftermath: Dictionary = _chapter().get("aftermath", {})
	assert_eq(str(aftermath.get("required_flag", "")), "cloudreach_winds_restored")
	assert_true((aftermath.get("state_changes", []) as Array).size() >= 5,
		"Cloudreach ends at boss defeat without a regional aftermath")
	assert_false((aftermath.get("return_dialogue_ids", []) as Array).is_empty(), "locals do not react after victory")
	assert_false(str(aftermath.get("save_contract", "")).is_empty(), "aftermath persistence is undefined")
