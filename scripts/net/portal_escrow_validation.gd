extends RefCounted

## Pure typed portable escrow boundary only; no actor or travel activation.
const INVENTORY := preload("res://autoload/inventory.gd")
const KIND := "portal_unlock"
const VERSION := 1
const KEYS := {"tidewake": "tidewake_portal_key", "cloudreach": "cloudreach_portal_key",
	"stormwood": "stormwood_portal_key", "biome5": "fifth_portal_key"}
const ROW_KEYS := ["version", "kind", "status", "biome", "item", "character_id",
	"world_id", "world_instance_id", "receipt", "key_slot"]


static func receipt(biome: String, character_id: String) -> String:
	return "portal_unlock:%s:%s" % [biome, character_id]


static func valid_row(raw: Variant, character_id: String) -> bool:
	if not raw is Dictionary or character_id.is_empty() or character_id.contains(":"):
		return false
	var row: Dictionary = raw
	if row.size() != ROW_KEYS.size():
		return false
	for key: String in ROW_KEYS:
		if not row.has(key):
			return false
	for field: String in ["version", "key_slot"]:
		var value: Variant = row[field]
		if not (value is int or value is float) or not is_finite(float(value)) or floorf(float(value)) != float(value):
			return false
	for field: String in ["kind", "status", "biome", "item", "character_id", "world_id", "world_instance_id", "receipt"]:
		if not row[field] is String or str(row[field]).is_empty():
			return false
	return int(row.version) == VERSION and row.kind == KIND and row.status in ["pending", "settled"] \
		and KEYS.has(str(row.biome)) and row.item == KEYS[str(row.biome)] \
		and row.character_id == character_id and row.receipt == receipt(str(row.biome), character_id) \
		and int(row.key_slot) >= 0 and int(row.key_slot) < INVENTORY.SLOT_COUNT


static func escrow_errors(raw: Variant, character_id: String) -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary:
		return ["personal escrow must be an object"]
	for key: Variant in raw:
		var value: Variant = raw[key]
		var portal_key := str(key).begins_with(KIND + ":")
		var portal_kind: bool = value is Dictionary and value.get("kind") == KIND
		if portal_key or portal_kind:
			if not valid_row(value, character_id) or str(key) != str(value.get("receipt", "")):
				errors.append("malformed portal escrow %s" % str(key))
	return errors
