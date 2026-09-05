extends RefCounted

## Positional save ownership. Array indices remain stable across realm filters.
## Untagged legacy records always belong to Meadows, never the loaded scene.
static func active(game: Node) -> String:
	if game != null:
		for property: Dictionary in game.get_property_list():
			if property.name == "current_realm":
				return str(game.get("current_realm"))
	return "meadows"


static func belongs(record: Variant, realm: String) -> bool:
	return record is Dictionary and str(record.get("realm", "meadows")) == realm


static func for_realm(records: Array, realm: String) -> Array:
	return records.filter(func(record: Variant) -> bool:
		return belongs(record, realm) and not bool(record.get("removed", false)))


static func normalized(records: Variant) -> Array:
	if not records is Array:
		return []
	var result: Array = records.duplicate(true)
	for record: Variant in result:
		if record is Dictionary and not record.has("realm"):
			record["realm"] = "meadows"
	return result
