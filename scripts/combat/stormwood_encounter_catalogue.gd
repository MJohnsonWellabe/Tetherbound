extends RefCounted

## Pure adapter between the authored Stormwood catalogues and the production
## encounter/trainer shapes. Runtime ownership remains with the Stormwood world.

const ENCOUNTERS_PATH := "res://data/config/stormwood_encounters.json"
const TRAINERS_PATH := "res://data/config/stormwood_trainers.json"
const HEIGHTFIELD := preload("res://scripts/world/stormwood_heightfield.gd")

## `encounter_director.gd` uses its numeric `order` for deterministic seeded
## scatter and wild node names. Reserve a realm-owned block so these cannot
## collide with the existing Meadows authored orders.
const WILD_ORDER_NAMESPACE := 300000
const ORDINARY_GROUP_COUNT := 2

static var _encounters: Dictionary = {}
static var _trainers: Dictionary = {}


static func wild_config(phase: String = "calm") -> Dictionary:
	var selected_phase := "surge" if phase == "surge" else "calm"
	var source := encounter_catalogue()
	var tables := _tables_by_id(source.get("tables", []))
	var field := HEIGHTFIELD.new()
	var spawns: Array = []
	var clusters: Array = source.get("wild_clusters", []) as Array
	for index in clusters.size():
		var cluster: Dictionary = clusters[index] as Dictionary
		var table_id := str(cluster.get("%s_table_id" % selected_phase, ""))
		var table: Dictionary = tables.get(table_id, {}) as Dictionary
		if table.is_empty():
			continue
		var cluster_id := str(cluster.get("id", ""))
		var seed := _stable_hash("%s:%s" % [cluster_id, selected_phase])
		var raw_position: Array = cluster.get("position", []) as Array
		if raw_position.size() < 3:
			continue
		var x := float(raw_position[0])
		var z := float(raw_position[2])
		var levels: Array = table.get("level_range", []) as Array
		if levels.size() < 2:
			continue
		var low := int(levels[0])
		var high := int(levels[1])
		if high < low:
			continue
		var species := _species_for(table, seed)
		if species.is_empty():
			continue
		spawns.append({
			"id": "stormwood_wild_%s" % cluster_id,
			"order": WILD_ORDER_NAMESPACE + _stable_hash(cluster_id),
			"species": species,
			"count": ORDINARY_GROUP_COUNT,
			"centre": [x, field.height_at(x, z), z],
			"radius": float(cluster.get("radius", 0.0)),
			"level": low + posmod(seed, high - low + 1),
			"stormwood_cluster_id": cluster_id,
			"stormwood_region_id": str(cluster.get("region_id", "")),
			"stormwood_phase": selected_phase,
			"stormwood_phase_options": _phase_options(cluster, tables),
		})
	return {"spawns": spawns}


static func trainer_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for raw: Variant in trainer_catalogue().get("trainers", []):
		if not raw is Dictionary:
			continue
		var authored := raw as Dictionary
		var source_position: Array = authored.get("position", []) as Array
		if source_position.size() < 3:
			continue
		var team: Array = []
		for member_raw: Variant in authored.get("party", []):
			if member_raw is Dictionary:
				var member := member_raw as Dictionary
				team.append({"species": str(member.get("placeholder_species", "")),
					"level": int(member.get("level", 0))})
		var spec: Dictionary = {
			"id": str(authored.get("id", "")),
			"name": str(authored.get("display_name", "")),
			"config_key": str(authored.get("humanoid_key", "")),
			"position": [float(source_position[0]), float(source_position[2])],
			"source_position3D": Vector3(float(source_position[0]), float(source_position[1]), float(source_position[2])),
			"surface_id": str(authored.get("surface_id", "")),
			"team": team,
			"defeat_flag": "stormwood:trainer:%s:defeated" % str(authored.get("id", "")),
			"rechallenge": not bool(authored.get("one_time", true)),
			"stormwood_region_id": str(authored.get("region_id", "")),
			"stormwood_rank": str(authored.get("rank", "")),
			"route_class": str(authored.get("route_class", "")),
		}
		if authored.get("reward") is Dictionary:
			spec["reward"] = (authored.get("reward") as Dictionary).duplicate(true)
		specs.append(spec)
	return specs


static func encounter_catalogue() -> Dictionary:
	if _encounters.is_empty():
		_encounters = _read_json(ENCOUNTERS_PATH)
	return _encounters


static func trainer_catalogue() -> Dictionary:
	if _trainers.is_empty():
		_trainers = _read_json(TRAINERS_PATH)
	return _trainers


static func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


static func _tables_by_id(raw_tables: Array) -> Dictionary:
	var result := {}
	for raw: Variant in raw_tables:
		if raw is Dictionary:
			var table := raw as Dictionary
			result[str(table.get("id", ""))] = table
	return result


static func _phase_options(cluster: Dictionary, tables: Dictionary) -> Dictionary:
	var options := {}
	for phase in ["calm", "surge"]:
		var id := str(cluster.get("%s_table_id" % phase, ""))
		var table: Dictionary = tables.get(id, {}) as Dictionary
		if not table.is_empty():
			options[phase] = {"table_id": id,
				"level_range": (table.get("level_range", []) as Array).duplicate(),
				"roles": (table.get("roles", []) as Array).duplicate(true)}
	return options


static func _species_for(table: Dictionary, seed: int) -> String:
	var roles: Array = table.get("roles", []) as Array
	var total := 0
	for raw: Variant in roles:
		if raw is Dictionary:
			total += _weight_for(str((raw as Dictionary).get("weight", "")))
	if total <= 0:
		return ""
	var chosen := posmod(seed, total)
	for raw: Variant in roles:
		if not raw is Dictionary:
			continue
		var role := raw as Dictionary
		chosen -= _weight_for(str(role.get("weight", "")))
		if chosen < 0:
			return str(role.get("placeholder_species", ""))
	return ""


static func _weight_for(weight: String) -> int:
	match weight:
		"common": return 6
		"uncommon": return 3
		"rare": return 1
		_: return 0


static func _stable_hash(text: String) -> int:
	var value := 5381
	for code: int in text.to_utf8_buffer():
		value = int((value * 33 + int(code)) & 0x7fffffff)
	return value
