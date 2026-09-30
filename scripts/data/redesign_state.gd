extends RefCounted

const DATA := preload("res://scripts/data/redesign_data.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")

static func defaults(scope: String) -> Dictionary:
	return DATA.json("res://data/schema/%s_state.json" % scope).duplicate(true)

static func validate(scope: String, value: Variant, owned_uids: Array = []) -> Array[String]:
	var schema: Dictionary = DATA.json("res://data/schema/%s_state.schema.json" % scope)
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
					if str(stone) != "" and str(stone) != str(biome) + "_entry":
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
				if pieces.size() < 2 or pieces[1].is_empty() or not pieces[0] in ["portal_unlock", "relic_hang", "craft", "release", "essence_spend", "care", "master_recipe", "feast_feed", "trait_teach", "loadout", "bounty", "research", "rematch", "groom"]:
					errors.append("unknown transaction receipt %s" % receipt)
	return errors

static func uids(party_payload: Variant) -> Array[String]:
	var out: Array[String] = []
	if party_payload is Array:
		for row: Variant in party_payload:
			if row is Dictionary: out.append(str(row.get("uid", "")))
	return out
