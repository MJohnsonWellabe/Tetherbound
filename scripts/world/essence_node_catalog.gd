extends RefCounted

## F32 host data catalogue. This reads and validates detached definitions;
## it does not mount nodes, award inventory, roll seed drops or write a save.
## The world ledger resolves realm/site identity here before an atomic claim.

const DATA_PATH := "res://data/config/essence_nodes.json"
const TYPE_PATH := "res://data/schema/essences.json"


static func read(path: String = DATA_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func known_types() -> Array[String]:
	var result: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TYPE_PATH))
	if parsed is Array:
		for row: Variant in parsed:
			if row is Dictionary and row.get("type") is String:
				result.append(str(row["type"]))
	return result


static func validation_errors(catalogue: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if catalogue.get("clock") != "host_world_day" or catalogue.get("scope") != "world" \
			or catalogue.get("outputs_scope") != "character":
		errors.append("Essence nodes require host-world-day stock and character inventory outputs.")
	var nodes: Variant = catalogue.get("nodes")
	if not nodes is Array:
		errors.append("Essence node catalogue has no node array.")
		return errors
	var types := known_types()
	var seen := {}
	var orders := {}
	var census := {}
	for row: Variant in nodes:
		if not row is Dictionary:
			errors.append("Essence node is not a dictionary.")
			continue
		var node: Dictionary = row
		var id := str(node.get("id", ""))
		var realm := str(node.get("realm", ""))
		var type_id := str(node.get("type", ""))
		var order := str(node.get("order", ""))
		if id.is_empty() or seen.has(id) or order.is_empty() or orders.has(order):
			errors.append("Essence node identity/order is empty or duplicated: " + id)
		seen[id] = true
		orders[order] = true
		if not realm in ["meadows", "water", "cloudreach", "stormwood"] or not types.has(type_id):
			errors.append("Essence node has an unknown live realm/type: " + id)
		var key := realm + ":" + type_id
		census[key] = int(census.get(key, 0)) + 1
		var at: Variant = node.get("at")
		if not at is Array or at.size() != 2:
			errors.append("Essence node needs realm-local x/z coordinates: " + id)
		else:
			for coordinate: Variant in at:
				if not (typeof(coordinate) in [TYPE_INT, TYPE_FLOAT]) or not is_finite(float(coordinate)):
					errors.append("Essence node coordinate is not finite: " + id)
		if not _positive_integer(node.get("respawn_days")):
			errors.append("Essence node needs a positive respawn day count: " + id)
		var outputs: Variant = node.get("outputs")
		if not outputs is Dictionary or outputs.size() != 2 \
				or not _positive_integer(outputs.get("essence_" + type_id)) \
				or not _positive_integer(outputs.get("attuned_" + type_id)):
			errors.append("Essence node must pay its canonical essence and attuned ingredient: " + id)
		var seed: Variant = node.get("seed_drop")
		if not seed is Dictionary or seed.get("item") != "seed_" + type_id \
				or not _positive_integer(seed.get("amount")) \
				or not _chance(seed.get("chance")):
			errors.append("Essence node has an invalid seed drop: " + id)
	for realm: String in ["meadows", "water", "cloudreach", "stormwood"]:
		for type_id: String in types:
			var count := int(census.get(realm + ":" + type_id, 0))
			if count < 1 or count > 2:
				errors.append("Expected one or two essence nodes for " + realm + ":" + type_id)
	return errors


static func _positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) == float(int(value)) and int(value) > 0


static func _chance(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) >= 0.0 and float(value) <= 1.0


## Reject the whole malformed catalogue; do not mount a plausible subset and
## quietly turn the census into fewer than the acceptance's eight types.
static func nodes_for(realm: String, catalogue: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source := read() if catalogue.is_empty() else catalogue
	if not validation_errors(source).is_empty():
		return result
	for node: Dictionary in source["nodes"]:
		if str(node["realm"]) == realm:
			result.append(node.duplicate(true))
	return result


static func by_id(realm: String, site_id: String, catalogue: Dictionary = {}) -> Dictionary:
	for node: Dictionary in nodes_for(realm, catalogue):
		if str(node["id"]) == site_id:
			return node.duplicate(true)
	return {}


## Mount proposal only: callers must first register this stable site with
## the host registry and supply its replicated stock. An unknown stock stays
## disabled in HarvestNode; it cannot fall back to a legacy item grant.
static func harvest_spec(node: Dictionary, replicated_stock: Dictionary) -> Dictionary:
	var spec := node.duplicate(true)
	spec["renewable_site_id"] = str(node.get("id", ""))
	spec["renewable_stock"] = replicated_stock.duplicate(true)
	return spec
