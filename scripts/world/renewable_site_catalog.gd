extends RefCounted

## One source-derived F32 registry for host claims, save validation and mounts.
## This cache contains detached definitions, never stock, receipts or inventory.
## Additional material proposals stay unregistered while their block is OFF.
const BANDS := preload("res://scripts/data/band_content.gd")
const ESSENCE := preload("res://scripts/world/essence_node_catalog.gd")
const REALMS := ["meadows", "water", "cloudreach", "stormwood"]
const MEADOWS_PATH := "res://data/config/harvest.json"
const WATER_PATH := "res://data/config/water_pickups.json"
const CLOUD_PATH := "res://data/config/cloudreach_resources.json"
const CLOUD_CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const STORM_PATH := "res://data/config/stormwood_harvests.json"

static var _loaded := false
static var _sites: Dictionary = {}
static var _invalid: Dictionary = {}


static func by_id(realm: String, site_id: String) -> Dictionary:
	if not realm in REALMS or site_id.is_empty():
		return {}
	_load()
	if _invalid.has(realm):
		return {}
	var site: Variant = (_sites.get(realm, {}) as Dictionary).get(site_id)
	return site.duplicate(true) if site is Dictionary else {}


static func validation_errors() -> Dictionary:
	_load()
	return _invalid.duplicate(true)


static func sites_for(realm: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	_load()
	if _invalid.has(realm): return result
	for site: Dictionary in (_sites.get(realm, {}) as Dictionary).values():
		result.append(site.duplicate(true))
	return result


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _fail(realm: String, reason: String) -> void:
	if not _invalid.has(realm):
		_invalid[realm] = []
	(_invalid[realm] as Array).append(reason)


static func _integer(value: Variant, minimum: int = 1) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) == float(int(value)) and int(value) >= minimum


static func _strings(value: Variant, allow_empty: bool = true) -> bool:
	if not value is Array or (not allow_empty and value.is_empty()):
		return false
	for entry: Variant in value:
		if not entry is String or entry.is_empty():
			return false
	return true


static func _point(value: Variant, size: int) -> bool:
	if not value is Array or value.size() != size:
		return false
	for coordinate: Variant in value:
		if not typeof(coordinate) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
			return false
	return true


static func _policy(realm: String, config: Dictionary) -> Dictionary:
	var policy: Variant = config.get("renewable")
	if not policy is Dictionary or policy.get("clock") != "host_world_day" \
			or policy.get("scope") != "world" \
			or not _integer(policy.get("material_respawn_days")) \
			or not _strings(policy.get("materials"), false):
		_fail(realm, "Malformed renewable policy")
		return {}
	return policy


static func _add(realm: String, site: Dictionary, source_path: String) -> void:
	var outputs: Variant = site.get("outputs")
	var id: Variant = site.get("id")
	if not id is String or id.is_empty() or site.get("realm") != realm \
			or not _point(site.get("at"), 2) or not _integer(site.get("respawn_days")) \
			or not outputs is Dictionary or outputs.is_empty():
		_fail(realm, "Malformed site in " + source_path)
		return
	for item: Variant in outputs:
		if not item is String or item.is_empty() or not _integer(outputs[item]):
			_fail(realm, "Malformed output: " + str(id))
			return
	for key: String in ["requires_world_flags", "availability"]:
		if site.has(key) and not _strings(site[key], key != "availability"):
			_fail(realm, "Malformed " + key + ": " + str(id))
			return
	if site.has("requires_flag") and not site["requires_flag"] is String:
		_fail(realm, "Malformed prerequisite: " + str(id))
		return
	if site.has("charged") and not site["charged"] is bool:
		_fail(realm, "Malformed charged status: " + str(id))
		return
	if site.has("grade") and not site["grade"] is String:
		_fail(realm, "Malformed grade: " + str(id))
		return
	if site.has("region_id") and not site["region_id"] is String:
		_fail(realm, "Malformed region: " + str(id))
		return
	var sites: Dictionary = _sites[realm]
	if sites.has(id):
		_fail(realm, "Duplicate site: " + str(id))
		return
	var detached := site.duplicate(true)
	detached["source_config"] = source_path
	sites[id] = detached


## Preserve source metadata (including prerequisites and candidate status),
## while deriving yield and identity only from the actual authored row.
static func _ordinary(realm: String, row: Dictionary, policy: Dictionary,
		id: String, item_key: String, amount_key: String, position_key: String,
		position_size: int, source_path: String) -> void:
	var item: Variant = row.get(item_key)
	if not item is String or item.is_empty():
		_fail(realm, "Malformed material identity: " + id)
		return
	if not (policy["materials"] as Array).has(item):
		return # Story/unique/food rows retain their own existing contracts.
	var amount: Variant = row.get(amount_key)
	var point: Variant = row.get(position_key)
	if id.is_empty() or not _integer(amount) or not _point(point, position_size):
		_fail(realm, "Malformed material site: " + id)
		return
	if (row.has("realm") and row["realm"] != realm) \
			or (row.has("outputs") and row["outputs"] != {item: int(amount)}) \
			or (row.has("respawn_days") and row["respawn_days"] != policy["material_respawn_days"]):
		_fail(realm, "Conflicting material definition: " + id)
		return
	var site := row.duplicate(true)
	site.merge({"id": id, "realm": realm, "item": item, "amount": int(amount),
		"outputs": {item: int(amount)}, "respawn_days": int(policy["material_respawn_days"]),
		"at": [point[0], point[position_size - 1]]}, true)
	# Presentation is source-derived too; node mounts never invent a second
	# material list or change the chapter's existing authored surface height.
	if realm == "cloudreach":
		var look: Dictionary = _read(CLOUD_PATH).get("resources", {}).get(item, {})
		site.merge(look, false)
	if realm == "water":
		var look: Dictionary = _read("res://data/config/water_resource_models.json").get("resources", {}).get(item, {})
		site.merge(look, false)
	if position_size == 3: site["authored_height"] = float(point[1])
	if realm == "cloudreach":
		site["legacy_flag_day_prefix"] = "harvest_node:order:cloudreach:" + id + ":day:"
	else:
		site["legacy_flag"] = "harvest_node:" + (id if realm == "meadows" else "order:" + id)
	_add(realm, site, source_path)


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	for realm: String in REALMS:
		_sites[realm] = {}
	var meadows := _read(MEADOWS_PATH)
	var meadows_policy := _policy("meadows", meadows)
	if not meadows_policy.is_empty():
		var orders := {}
		# Reuse the established band list; never maintain another placement list.
		for band: String in BANDS.BANDS:
			var path := "%s/%s/harvest.json" % [BANDS.BANDS_DIR, band]
			var document := _read(path)
			var rows: Variant = document.get("nodes")
			if not rows is Array:
				_fail("meadows", "Malformed band harvest array: " + path)
				continue
			for row: Variant in rows:
				if not row is Dictionary or not _integer(row.get("order"), 0):
					_fail("meadows", "Malformed band harvest order: " + path)
					continue
				var order := str(row["order"])
				if orders.has(order):
					_fail("meadows", "Duplicate authored harvest order: " + order)
					continue
				orders[order] = true
				_ordinary("meadows", row, meadows_policy, "order:" + str(row["order"]),
					"item", "amount", "at", 2, path)
	var water := _read(WATER_PATH)
	_load_rows("water", water, WATER_PATH, "harvest", "item_id", "yield", 3)
	_load_additional_materials("meadows", meadows, meadows_policy, MEADOWS_PATH)
	var water_policy: Variant = water.get("renewable")
	_load_additional_materials("water", water, water_policy if water_policy is Dictionary else {}, WATER_PATH)
	var cloud := _read(CLOUD_PATH)
	var chapter := _read(CLOUD_CHAPTER_PATH)
	var tier: Variant = chapter.get("resource_tier")
	if not tier is Dictionary:
		_fail("cloudreach", "Malformed resource tier")
	else:
		cloud["nodes"] = tier.get("nodes")
		_load_rows("cloudreach", cloud, CLOUD_CHAPTER_PATH, "nodes", "resource_id", "amount", 3)
	_load_rows("stormwood", _read(STORM_PATH), STORM_PATH, "sites", "item", "amount", 2)
	var essence := ESSENCE.read()
	var errors := ESSENCE.validation_errors(essence)
	for realm: String in REALMS:
		if not errors.is_empty():
			_fail(realm, "Malformed essence catalogue: " + str(errors))
			continue
		for node: Dictionary in ESSENCE.nodes_for(realm, essence):
			# Every essence placement retains its real material anchor's scope,
			# gates and intended cliff stratum. Offsets cannot bypass a rootgate
			# or move a lower-cliff node onto the highest XZ surface.
			var site := ESSENCE.by_id(realm, str(node["id"]), essence)
			var anchor: Dictionary = site.get("anchor", {})
			var parent: Variant = (_sites[realm] as Dictionary).get(str(anchor.get("id", "")))
			if not parent is Dictionary:
				_fail(realm, "Unknown essence placement anchor: " + str(site.get("id", "")))
				continue
			for key: String in ["requires_flag", "requires_world_flags", "availability", "authored_height"]:
				if parent.has(key): site[key] = parent[key].duplicate(true) if parent[key] is Array else parent[key]
			_add(realm, site, ESSENCE.DATA_PATH)


static func _load_rows(realm: String, config: Dictionary, source_path: String,
		array_key: String, item_key: String, amount_key: String, position_size: int) -> void:
	var policy := _policy(realm, config)
	var rows: Variant = config.get(array_key)
	if policy.is_empty() or not rows is Array:
		_fail(realm, "Malformed ordinary site array: " + source_path)
		return
	var gates: Variant = config.get("region_prerequisites")
	if realm == "stormwood" and not gates is Dictionary:
		_fail(realm, "Malformed region prerequisites")
		return
	var seen := {}
	for raw: Variant in rows:
		if not raw is Dictionary or not raw.get("id") is String or raw["id"].is_empty():
			_fail(realm, "Malformed ordinary site identity")
			continue
		if seen.has(raw["id"]):
			_fail(realm, "Duplicate authored site: " + str(raw["id"]))
			continue
		seen[raw["id"]] = true
		var row: Dictionary = raw.duplicate(true)
		if realm == "water":
			if row.has("claim_policy") and not row["claim_policy"] is String:
				_fail(realm, "Malformed harvest claim policy")
				continue
			if not row.get("claim_policy", "") in ["", "existing_world_pickup_policy", "character_once"]:
				_fail(realm, "Unknown harvest claim policy")
				continue
			if row.get("claim_policy", "") == "character_once":
				continue
		if realm == "cloudreach":
			if not row.get("respawn_policy") in ["world_day_regrow", "encounter_cycle"]:
				_fail(realm, "Malformed resource respawn policy")
				continue
			if row["respawn_policy"] != "world_day_regrow":
				continue
		if realm == "stormwood":
			var region: Variant = row.get("region_id")
			if not region is String or not gates.has(region) or not gates[region] is String:
				_fail(realm, "Malformed harvest region prerequisite")
				continue
			row["requires_flag"] = gates[region]
		_ordinary(realm, row, policy, row["id"], item_key, amount_key, "position", position_size, source_path)


## Only validated, explicitly enabled additional sites enter the SAME registry.
## A default-OFF block changes no known IDs or existing depleted stock. Actual
## terrain/player-path proof is a prerequisite, not something this parser earns.
static func _load_additional_materials(realm: String, config: Dictionary,
		policy: Dictionary, source_path: String) -> void:
	# Ordinary parsing already validated this realm/policy. Never cast a
	# malformed raw policy or admit extras into a failed canonical realm.
	if _invalid.has(realm):
		return
	var block: Variant = config.get("additional_material_node_candidates")
	if not block is Dictionary or typeof(block.get("runtime_enabled")) != TYPE_BOOL:
		_fail(realm, "Malformed additional-material enablement")
		return
	if block["runtime_enabled"] == false:
		return
	var rows: Variant = block.get("nodes")
	if policy.is_empty() or not rows is Array or rows.is_empty():
		_fail(realm, "Malformed enabled additional-material catalogue")
		return
	for raw: Variant in rows:
		if not raw is Dictionary or raw.get("realm") != realm \
				or typeof(raw.get("terrain_and_player_path_proven")) != TYPE_BOOL \
				or raw["terrain_and_player_path_proven"] != true \
				or not raw.get("item") is String or not (policy["materials"] as Array).has(raw["item"]) \
				or not _integer(raw.get("amount")) \
				or raw.get("outputs") != {raw["item"]: int(raw["amount"])} \
				or not _integer(raw.get("respawn_days")) \
				or not _point(raw.get("at"), 2) \
				or not raw.get("model") is String or raw["model"].is_empty() \
				or not _point([raw.get("model_scale")], 1) or float(raw["model_scale"]) <= 0.0:
			_fail(realm, "Unproved or malformed additional-material site")
			continue
		var anchor: Variant = raw.get("anchor")
		if not anchor is Dictionary or not anchor.get("id") is String \
				or not _point(anchor.get("offset_xz_m"), 2):
			_fail(realm, "Malformed additional-material anchor")
			continue
		# Read the already loaded canonical ordinary anchor, not a second list.
		var sites: Dictionary = _sites[realm]
		var parent: Variant = sites.get(anchor["id"])
		if not parent is Dictionary or parent.get("source_additional_material", false) == true:
			_fail(realm, "Unknown ordinary additional-material anchor")
			continue
		var expected := Vector2(float(parent["at"][0]), float(parent["at"][1])) \
			+ Vector2(float(anchor["offset_xz_m"][0]), float(anchor["offset_xz_m"][1]))
		var actual := Vector2(float(raw["at"][0]), float(raw["at"][1]))
		if not expected.is_equal_approx(actual):
			_fail(realm, "Additional-material position differs from its source anchor")
			continue
		if realm == "water" and (typeof(raw.get("requires_dive")) != TYPE_BOOL or raw["requires_dive"] != false):
			_fail(realm, "Main-island material candidates cannot require Dive")
			continue
		var site: Dictionary = raw.duplicate(true)
		# Offsets never remove the anchor's host phase/route restrictions.
		for key: String in ["requires_flag", "requires_world_flags", "availability"]:
			if site.has(key) and site[key] != parent.get(key):
				_fail(realm, "Additional-material prerequisite conflicts with its anchor")
			elif parent.has(key):
				site[key] = parent[key].duplicate(true) if parent[key] is Array else parent[key]
		site["source_additional_material"] = true
		site["order"] = "material:" + str(site.get("id", ""))
		_add(realm, site, source_path)


## World owners mount only admitted IDs from the canonical resolver. Disabled
## or unproved source candidates do not become known stock through this query.
static func additional_materials_for(realm: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not realm in REALMS:
		return result
	_load()
	if _invalid.has(realm):
		return result
	for site: Dictionary in (_sites[realm] as Dictionary).values():
		if site.get("source_additional_material", false) == true:
			result.append(site.duplicate(true))
	return result
