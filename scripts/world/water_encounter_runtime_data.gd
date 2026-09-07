extends RefCounted

## Pure content translation over production encounter schemas. Never registers
## species, creates nodes, writes flags, chooses an Alpha result or mutates inputs.
const CATALOG := preload("res://scripts/creatures/water_species_catalog.gd")
const TUNING_PATH := "res://data/config/water_combat.json"
const INSTALLED_EXCEPTIONS := ["brooktail", "galecrest"]

static func build(world_config: Dictionary, characters: Dictionary, encounters: Dictionary,
		height_callable: Callable, supplied_tuning: Dictionary = {}) -> Dictionary:
	var errors: Array[String] = []
	var tuning := supplied_tuning.duplicate(true)
	if tuning.is_empty():
		tuning = JSON.parse_string(FileAccess.get_file_as_string(TUNING_PATH))
	var centres: Dictionary = {}
	for island: Dictionary in world_config.get("islands", []):
		centres[str(island.id)] = island.center_xz_m
	var bodies: Dictionary = {}
	for npc: Dictionary in characters.get("npcs", []):
		bodies[str(npc.id)] = npc
	var tables: Array = []
	for authored: Dictionary in encounters.get("tables", []):
		var table := authored.duplicate(true)
		table["selection_key"] = str(authored.id)
		for entry: Dictionary in table.get("entries", []):
			entry["placeholder_species"] = _species(str(entry.get("species_id", entry.get("placeholder_species", ""))), errors)
		tables.append(table)
	var sites: Array = []
	for authored: Dictionary in encounters.get("wild_sites", []):
		var site := authored.duplicate(true)
		site["position"] = _grounded(authored.get("position", []), height_callable, errors, str(authored.id))
		site["requires_flags"] = authored.get("requires_flags", []).duplicate()
		sites.append(site)
	var trainers: Dictionary = {}
	var placements: Array = []
	for authored: Dictionary in characters.get("trainers", []):
		var id := str(authored.id)
		if trainers.has(id):
			errors.append("Duplicate Water trainer: " + id)
			continue
		var reuse_id := str(authored.get("npc_entity_id", ""))
		var position_source: Dictionary = bodies.get(reuse_id, authored)
		var island := str(position_source.get("island_id", ""))
		var offset: Array = position_source.get("island_local_offset", [])
		if not centres.has(island) or offset.size() != 3:
			errors.append("Trainer has invalid island placement: " + id)
			continue
		var centre: Array = centres[island]
		var position := _grounded([float(centre[0]) + float(offset[0]), 0.0,
			float(centre[1]) + float(offset[2])], height_callable, errors, id)
		var spec := authored.duplicate(true)
		spec["name"] = str(authored.get("display_name", id))
		spec["config_key"] = str(authored.get("body_profile", ""))
		spec["base"] = spec.config_key
		spec["rank"] = str(authored.get("rank", "local"))
		spec["chapter_rank"] = spec.rank
		spec["rechallenge"] = false
		spec["position"] = position
		spec["defeat_flag"] = "defeated_" + id
		spec["requires_flags"] = authored.get("requires_flags", []).duplicate()
		spec["reuse_npc_id"] = reuse_id if bodies.has(reuse_id) else ""
		spec["intro"] = str(authored.get("intro_conversation", ""))
		spec["defeated"] = str(authored.get("win_conversation", ""))
		spec["reward"] = tuning.get("reward_tiers", {}).get(spec.rank, {}).duplicate(true)
		var team: Array = []
		for member: Dictionary in authored.get("team", []):
			var translated := member.duplicate(true)
			translated["species"] = _species(str(member.get("species", "")), errors)
			translated["trainer_owned"] = true
			team.append(translated)
		spec["team"] = team
		trainers[id] = spec
		placements.append({"id": id, "position": position.duplicate(), "island_id": island,
			"reuse_npc_id": spec.reuse_npc_id, "requires_flags": spec.requires_flags.duplicate()})
	var config := tuning.duplicate(true)
	config["wild_sites"] = sites
	config["trainers"] = placements
	config["named_encounters"] = []
	config["scripted_encounter_references"] = []
	for key: String in ["named_encounters", "scripted_encounter_references"]:
		for authored: Dictionary in encounters.get(key, []):
			var translated := authored.duplicate(true)
			translated["species"] = _species(str(authored.get("species_id", "")), errors)
			if authored.has("position"):
				translated["position"] = _grounded(authored.position, height_callable, errors, str(authored.id))
			config[key].append(translated)
	var mapping: Dictionary = {}
	for board_id: String in CATALOG.BOARD_IDS:
		mapping[board_id] = CATALOG.runtime_id(board_id)
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "chapter": {}, "encounter_config": {}, "trainer_specs": {}, "board_to_runtime": {}}
	return {"ok": true, "errors": [], "chapter": {"realm_id": "water", "encounter_tables": tables},
		"encounter_config": config, "trainer_specs": trainers, "board_to_runtime": mapping}

static func _species(source: String, errors: Array[String]) -> String:
	var mapped := CATALOG.runtime_id(source)
	if not mapped.is_empty():
		return mapped
	if source in INSTALLED_EXCEPTIONS:
		return source
	errors.append("Unknown Water encounter species: " + source)
	return ""

static func _grounded(raw: Array, height_callable: Callable, errors: Array[String], id: String) -> Array:
	if raw.size() != 3 or not height_callable.is_valid():
		errors.append("Missing encounter position/height service: " + id)
		return []
	var x := float(raw[0])
	var z := float(raw[2])
	var height: float = height_callable.call(x, z)
	if not is_finite(x) or not is_finite(z) or not is_finite(height):
		errors.append("Nonfinite encounter ground: " + id)
		return []
	return [x, height, z]
