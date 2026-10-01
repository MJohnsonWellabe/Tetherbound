extends RefCounted

const DATA := preload("res://scripts/data/redesign_data.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")

static func defaults(scope: String) -> Dictionary:
	var value: Variant = DATA.json("res://data/schema/%s_state.json" % scope)
	if not value is Dictionary:
		push_error("Redesign %s defaults are missing or malformed" % scope)
		return {}
	return value.duplicate(true)

static func validate(scope: String, value: Variant, owned_uids: Array = []) -> Array[String]:
	var raw_schema: Variant = DATA.json("res://data/schema/%s_state.schema.json" % scope)
	if not raw_schema is Dictionary:
		return ["Redesign %s schema is missing or malformed" % scope]
	var schema: Dictionary = raw_schema
	var errors := DATA.validate(value, schema)
	if not value is Dictionary: return errors
	if scope == "character":
		for field: String in ["waystones_activated", "last_waystones"]:
			var by_biome: Variant = value.get(field, {})
			if not by_biome is Dictionary: continue
			for biome: Variant in by_biome:
				var raw: Variant = by_biome[biome]
				var stones: Array = raw if raw is Array else [raw]
				for stone: Variant in stones:
					if not _waystone_belongs(str(stone), str(biome)):
						errors.append("%s: waystone belongs to another biome" % field)
		var creatures: Variant = value.get("creatures", {})
		if creatures is Dictionary:
			for uid: Variant in creatures:
				if str(uid).is_empty() or not owned_uids.has(str(uid)):
					errors.append("unknown/unowned creature uid %s" % uid)
		for field: String in ["transaction_receipts", "release_receipts", "research_receipts", "bounty_receipts"]:
			var receipts: Variant = value.get(field, [])
			if not receipts is Array: continue
			for receipt: Variant in receipts:
				var pieces := str(receipt).split(":")
				if pieces.size() < 2 or pieces[1].is_empty() or not pieces[0] in ["portal_unlock", "starter_choice", "relic_hang", "craft", "release", "essence_spend", "defeat", "care", "master_recipe", "feast_feed", "trait_teach", "loadout", "bounty", "research", "rematch", "groom"]:
					errors.append("unknown transaction receipt %s" % receipt)
	return errors

static func uids(party_payload: Variant) -> Array[String]:
	var out: Array[String] = []
	if party_payload is Array:
		for row: Variant in party_payload:
			if row is Dictionary: out.append(str(row.get("uid", "")))
	return out


static func _waystone_belongs(id: String, biome: String) -> bool:
	if id.is_empty() or id == biome + "_entry": return true
	var config: Variant = DATA.json("res://data/config/waystones.json")
	if not config is Dictionary: return false
	for stone: Variant in config.get("waystones", []):
		if stone is Dictionary and stone.get("id") == id:
			return stone.get("biome") == biome
	return false
