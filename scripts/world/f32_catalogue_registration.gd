extends RefCounted

## Foundation-owned ItemDB constructor calls this owned overlay adapter.
## It does not register any Forge recipe in generic Game.craft: only F31's
## present-channel consumer may invoke the four refining source definitions.
static func apply_items(items: Dictionary) -> Dictionary:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/items/f32_materials.json"))
	if not source is Dictionary or source.get("runtime_enabled") != true:
		return items
	var result := items.duplicate(true)
	for id: String in source.get("items", {}):
		var row: Variant = source.items[id]
		if not row is Dictionary or not row.get("name") is String or not _positive_integer(row.get("stack")):
			return items
		if result.has(id) and result[id] != row:
			push_error("Conflicting canonical F32 item definition: " + id)
			return items
		result[id] = row.duplicate(true)
		result[id]["stack"] = int(row["stack"])
	for id: String in source.get("display_overrides", {}):
		if not result.has(id): return items
		var replacement: Variant = source.display_overrides[id]
		if not replacement is Dictionary: return items
		for field: String in replacement:
			if not field in ["name", "blurb", "description"] or not replacement[field] is String:
				return items
		result[id].merge(replacement, true)
	return result


static func _positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and float(value) > 0 and float(value) < 2147483647.0

## Existing baseline registration census for the literal ten water proposals.
## Tests/review callers can compare the actual runtime book without mutation.
static func water_registration_errors(items: Dictionary, recipes: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var water: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_crafting.json"))
	if not water is Dictionary or not water.get("recipes") is Dictionary or water.recipes.size() != 10:
		result.append("Expected exactly ten authored water recipes.")
		return result
	for id: String in water.item_registration_proposals:
		if items.get(id) != water.item_registration_proposals[id]: result.append("Missing water item: " + id)
	for id: String in water.recipes:
		if recipes.get(id) != water.recipes[id]: result.append("Missing water recipe: " + id)
	return result
