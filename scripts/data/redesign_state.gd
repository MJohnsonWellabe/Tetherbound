extends RefCounted

const DATA := preload("res://scripts/data/redesign_data.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")

static func defaults(scope: String) -> Dictionary:
	var value: Variant = DATA.json("res://data/schema/%s_state.json" % scope)
	if not value is Dictionary:
		push_error("Redesign %s defaults are missing or malformed" % scope)
		return {}
	return value.duplicate(true)

static func validate(scope: String, value: Variant, owned_uids: Array = [], world_namespace: Variant = null) -> Array[String]:
	var raw_schema: Variant = DATA.json("res://data/schema/%s_state.schema.json" % scope)
	if not raw_schema is Dictionary:
		return ["Redesign %s schema is missing or malformed" % scope]
	var schema: Dictionary = raw_schema
	var errors := DATA.validate(value, schema)
	if not value is Dictionary: return errors
	if scope == "world" and errors.is_empty():
		var alpha: Variant = value.get("alpha_cycles", {}).get("sites", {})
		var catalogue: Variant = DATA.json("res://data/config/alpha_respawns.json")
		var traits: Variant = DATA.json("res://data/config/traits.json")
		for id: String in alpha:
			var row: Dictionary = alpha[id]
			if not catalogue is Dictionary or not catalogue.get("sites", {}).has(id):
				errors.append("unknown alpha site %s" % id)
			if row.has("resolved_at_seconds"):
				if row.next_eligible_seconds < row.resolved_at_seconds:
					errors.append("alpha deadline regressed %s" % id)
				for character: String in row.departed:
					if not row.required_departures.has(character): errors.append("unknown alpha departure %s" % id)
			var packet: Dictionary = row.spawn_traits
			if row.status == "waiting":
				if not packet.is_empty(): errors.append("waiting alpha carries live traits %s" % id)
				continue
			if packet.size() != 4 or packet.get("traits_initialized") != true \
				or not packet.get("rolled_traits") is Array or packet.rolled_traits.size() > 3 \
				or packet.get("taught_traits") != {} or not packet.get("captured_from") is Dictionary:
				errors.append("invalid retained alpha traits %s" % id)
				continue
			var provenance: Dictionary = packet.captured_from
			if provenance.size() != 4 or provenance.get("kind") != "wild" or provenance.get("spawn_id") != id \
				or provenance.get("spawn_generation") != row.generation \
				or not provenance.get("world_namespace") is String or provenance.world_namespace.is_empty() \
				or (world_namespace != null and provenance.world_namespace != world_namespace):
				errors.append("alpha provenance changed %s" % id)
			var seen: Array = []
			for trait_row: Variant in packet.rolled_traits:
				if not traits is Dictionary or not trait_row is String or not traits.get("traits", {}).has(trait_row) or seen.has(trait_row):
					errors.append("invalid alpha trait %s" % id)
				seen.append(trait_row)
	if scope == "character":
		# Optional additive personal carrier. Lazy load preserves the existing
		# Essence -> state dependency without creating a static preload cycle.
		if value.has("research"):
			var research: GDScript = load("res://scripts/creatures/research_log.gd")
			errors.append_array(research.personal_errors(value, research.config()))
		# Additive F43 carrier: v28 records without a board remain valid. Load
		# lazily to avoid a static cycle through Essence's existing state checker.
		if value.has("bounties"):
			var bounty_rules: GDScript = load("res://scripts/world/bounty_board.gd")
			errors.append_array(bounty_rules.board_errors(value.bounties))
		var cooldowns: Variant = value.get("rematch_cooldowns", {})
		if cooldowns is Dictionary and errors.is_empty():
			for key: String in cooldowns:
				var cooldown: Dictionary = cooldowns[key]
				if not key.begins_with(str(cooldown.world_namespace) + ":") or cooldown.next_eligible_seconds < cooldown.paid_at_seconds:
					errors.append("invalid rematch deadline %s" % key)
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
				if pieces[0] == "stormheart_answer":
					# This is a character's historical original-offer receipt, so its
					# creature need not remain in the currently owned roster.
					# Load lazily: Creature -> Essence already depends on this checker.
					var creature_identity: Script = load("res://scripts/creatures/creature_instance.gd")
					if not receipt is String or field != "transaction_receipts" or pieces.size() != 3 \
						or creature_identity.call("valid_uid", pieces[1]) != true \
						or not preload("res://scripts/save/character_identity.gd").is_valid(pieces[2]):
						errors.append("invalid Stormheart answer receipt %s" % receipt)
					continue
				if pieces.size() < 2 or pieces[1].is_empty() or not pieces[0] in ["portal_unlock", "starter_choice", "relic_hang", "craft", "release", "essence_spend", "defeat", "care", "master_recipe", "feast_feed", "candy_feed", "trait_teach", "loadout", "bounty", "research", "rematch", "groom"]:
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
