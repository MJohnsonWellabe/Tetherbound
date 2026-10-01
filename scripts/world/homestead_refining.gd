extends RefCounted

## F32#1 pure one-unit plan for F31's present, tap-started Forge interaction.
## Supply HOST WorldState.save_data()/PlayerState.save_data() snapshots and
## the canonical recipes_forge.json contents, never request/client baselines.
## This helper is currently uncalled. It neither registers recipes nor starts
## a channel, spends inventory, grants items, writes state or creates receipts.
## The canonical ledger must authenticate the actor, resolve the live station,
## recheck proximity/modal/combat/channel completion and inventory CAS, and
## atomically commit ONE unit with the stable character's existing receipt.

const REFINING_IDS := ["rootiron_ingot", "tidesteel_ingot", "skyglass_ingot", "stormglass_plate"]
const STOP_REASONS := ["out_of_radius", "another_modal", "combat"]


static func unit_plan(source: Dictionary, recipe_id: String, station_uid: String,
		realm: String, host_world: Dictionary, host_character: Dictionary) -> Dictionary:
	var definition := recipe_definition(source, recipe_id)
	var channel := manual_channel(source)
	if definition.is_empty() or channel.is_empty():
		return _refusal("invalid_recipe", "This refining recipe is unavailable.")
	if realm != "meadows":
		return _refusal("needs_homestead", "Refine at the homestead Forge.")
	if not _identity(host_world.get("world_id")) or not _identity(host_character.get("character_id")) \
			or host_character.get("realm") != realm:
		return _refusal("invalid_actor", "The character's world residency is unavailable.")
	var station := _built_forge(host_world.get("placed_buildings"), station_uid, realm)
	if station.is_empty():
		return _refusal("missing_station", "Build a Forge at the homestead.")
	# F31 owns paid pose/attachment validation. Resolve the actual Forge UID,
	# never a cached global tier that belongs to a different Forge in the world.
	var provider_path := "res://scripts/build/station_rules.gd"
	if not ResourceLoader.exists(provider_path):
		return _refusal("invalid_station", "The homestead station service is unavailable.")
	var provider: Script = load(provider_path)
	var cfg: Variant = provider.call("config")
	if not cfg is Dictionary: return _refusal("invalid_station", "The station catalogue is unavailable.")
	var resolved: Variant = provider.call("effective_tier", cfg, host_world.get("placed_buildings", []), station_uid)
	if not resolved is Dictionary or resolved.get("ok") != true or not _integer(resolved.get("effective_tier"), 0):
		return _refusal("invalid_station", "The actual Forge's tier is unavailable.")
	var tier := int(resolved["effective_tier"])
	var flags := _personal_flags(host_character.get("flags"))
	if not bool(flags.get("ok", false)):
		return _refusal("invalid_actor", "The character's recipe state is unavailable.")
	for prerequisite: String in _recipe_prerequisites(definition):
		if not (flags["ids"] as Array).has(prerequisite):
			return _refusal("recipe_locked", "Learn this refining recipe on your character.")
	# Base refinement deliberately needs no own/previous attachment. Every
	# attachment costs its own refined ingot; gating that ingot would deadlock.
	# Reading the host tier does not grant the guest any tier or blueprint.
	return {"ok": true, "recipe_id": recipe_id, "station_uid": station_uid,
		"world_id": host_world["world_id"], "character_id": host_character["character_id"],
		"realm": realm, "host_station_tier": int(tier),
		"cost": (definition["cost"] as Array).duplicate(true),
		"output": (definition["output"] as Dictionary).duplicate(true),
		"channel": channel, "requires_present_completed_channel": true}


## Exact four basic refining identities; all amounts/timings remain in config.
## No lookup fallback that could turn an unknown/malformed recipe into free craft.
static func recipe_definition(source: Dictionary, recipe_id: String) -> Dictionary:
	if not REFINING_IDS.has(recipe_id) or source.get("station") != "forge":
		return {}
	var recipes: Variant = source.get("recipes")
	if not recipes is Dictionary:
		return {}
	var raw: Variant = recipes.get(recipe_id)
	if not raw is Dictionary or raw.get("station") != "forge" \
			or not _integer(raw.get("tier"), 1) \
			or int(raw["tier"]) != REFINING_IDS.find(recipe_id) + 1 \
			or not _integer(raw.get("required_attachment_tier"), 0) \
			or int(raw["required_attachment_tier"]) != 0:
		return {}
	var output: Variant = raw.get("output")
	if not output is Dictionary or output.get("id") != recipe_id \
			or not _integer(output.get("n"), 1) or int(output["n"]) != 1:
		return {}
	var cost: Variant = raw.get("cost")
	if not cost is Array or cost.is_empty():
		return {}
	var seen: Array[String] = []
	for need: Variant in cost:
		if not need is Dictionary or not _identity(need.get("id")) \
				or seen.has(need["id"]) or not _integer(need.get("n"), 1):
			return {}
		seen.append(need["id"])
	if raw.has("unlocked_by") and not _identity(raw["unlocked_by"]):
		return {}
	if raw.has("requires_personal_flags") and not _string_ids(raw["requires_personal_flags"]):
		return {}
	return raw.duplicate(true)


static func manual_channel(source: Dictionary) -> Dictionary:
	var channel: Variant = source.get("manual_channel")
	if not channel is Dictionary:
		return {}
	for field: String in ["tap_start", "commit_per_unit"]:
		if typeof(channel.get(field)) != TYPE_BOOL or channel[field] != true:
			return {}
	for field: String in ["held_input", "queue", "offline_production", "pay_unstarted_units"]:
		if typeof(channel.get(field)) != TYPE_BOOL or channel[field] != false:
			return {}
	for field: String in ["seconds_per_unit", "radius_m"]:
		if not _number(channel.get(field)) or float(channel[field]) <= 0.0:
			return {}
	var stops: Variant = channel.get("stop_on")
	if not _string_ids(stops) or stops.size() != STOP_REASONS.size():
		return {}
	for reason: String in STOP_REASONS:
		if not stops.has(reason):
			return {}
	return channel.duplicate(true)


static func _built_forge(records: Variant, uid: String, realm: String) -> Dictionary:
	if uid.is_empty() or not records is Array:
		return {}
	var found := {}
	for row: Variant in records:
		if not row is Dictionary or row.get("uid") != uid:
			continue
		# Refuse duplicate UIDs even when one duplicate names another building.
		if not found.is_empty() or row.get("id") != "forge" \
				or row.get("realm", "meadows") != realm or not _position(row.get("position")):
			return {}
		found = row.duplicate(true)
	return found


static func _personal_flags(payload: Variant) -> Dictionary:
	# This is the existing ProgressionState.save_data() shape, not a new bag.
	if not payload is Dictionary or not _string_ids(payload.get("flags")):
		return {"ok": false}
	return {"ok": true, "ids": (payload["flags"] as Array).duplicate()}


static func _recipe_prerequisites(definition: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if definition.has("unlocked_by"):
		ids.append(definition["unlocked_by"])
	for id: String in definition.get("requires_personal_flags", []):
		if not ids.has(id):
			ids.append(id)
	return ids


static func _string_ids(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen: Array[String] = []
	for id: Variant in value:
		if not _identity(id) or seen.has(id):
			return false
		seen.append(id)
	return true


static func _identity(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()


static func _position(value: Variant) -> bool:
	if not value is Array or value.size() != 3:
		return false
	for coordinate: Variant in value:
		if not _number(coordinate):
			return false
	return true


static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func _integer(value: Variant, minimum: int) -> bool:
	return _number(value) and float(value) == float(int(value)) and int(value) >= minimum


static func _refusal(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason}
