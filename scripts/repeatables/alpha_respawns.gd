extends RefCounted

## Host-world detached CAS plans. Existing world-save owner must atomically
## commit before publishing a body; callbacks never save or copy a caught card.
const DATA := preload("res://scripts/data/redesign_data.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const HOOKS := preload("res://scripts/creatures/trait_spawn_hooks.gd")
const PATH := "res://data/config/alpha_respawns.json"

static func config() -> Dictionary:
	var raw: Variant = DATA.json(PATH)
	return raw if raw is Dictionary else {}

static func site(id: String) -> Dictionary:
	return config().get("sites", {}).get(id, {}).duplicate(true)

static func _sites(world: Dictionary) -> Dictionary:
	return world.get("alpha_cycles", {}).get("sites", {})

static func _plan(world: Dictionary, id: String, record: Dictionary, operation: String) -> Dictionary:
	var next := world.duplicate(true)
	if not next.has("alpha_cycles"): return {}
	if not next.alpha_cycles.has("sites"): next.alpha_cycles.sites = {}
	next.alpha_cycles.sites[id] = record.duplicate(true)
	return {"ok": true, "operation": operation, "site_id": id,
		"before": world.duplicate(true), "state": next, "record": record.duplicate(true), "durable": false}

## Frozen host region census, not only fighters. Players who disconnect remain
## required until their accepted departure; a newly arriving peer blocks spawn
## while present, but cannot create a permanent departure requirement.
static func resolve(world: Dictionary, id: String, generation: int, world_seconds: int,
		region_characters: Array, outcome: String) -> Dictionary:
	if site(id).is_empty() or world_seconds < 0 or outcome not in ["defeat", "catch"]: return {}
	var old: Dictionary = _sites(world).get(id, {})
	if generation < 1 or (not old.is_empty() and (int(old.generation) != generation or old.status != "active")): return {}
	if old.is_empty() and generation != 1: return {}
	if not old.is_empty() and world_seconds < int(old.next_eligible_seconds): return {}
	var required: Array[String] = []
	for character: Variant in region_characters:
		if not TRAITS.component(character) or required.has(character): return {}
		required.append(character)
	if required.is_empty(): return {}
	required.sort()
	return _plan(world, id, {"generation": generation, "status": "waiting", "resolved_at_seconds": world_seconds,
		"next_eligible_seconds": world_seconds + int(config().respawn_days) * int(config().day_seconds),
		"required_departures": required, "departed": [], "spawn_traits": {}}, "alpha_resolve")

static func depart(world: Dictionary, id: String, generation: int, character: String, actual_region: String) -> Dictionary:
	var row := site(id)
	var old: Dictionary = _sites(world).get(id, {})
	if row.is_empty() or old.is_empty() or old.status != "waiting" or int(old.generation) != generation \
		or actual_region.is_empty() or actual_region == row.region_id \
		or not old.required_departures.has(character) or old.departed.has(character): return {}
	var record := old.duplicate(true)
	record.departed.append(character)
	record.departed.sort()
	return _plan(world, id, record, "alpha_depart")

static func spawn(world: Dictionary, id: String, namespace_id: String, world_seconds: int,
		night: bool, weather: bool) -> Dictionary:
	var row := site(id)
	var old: Dictionary = _sites(world).get(id, {})
	if row.is_empty() or old.is_empty() or old.status != "waiting" \
		or world_seconds < int(old.next_eligible_seconds) or not TRAITS.component(namespace_id): return {}
	for character: String in old.required_departures:
		if not old.departed.has(character): return {}
	var generation := int(old.generation) + 1
	if generation > 2147483647: return {}
	var traits := TRAITS.config()
	# Reuse F30's validated roll pool and seed/provenance. Config changes only
	# weights, so no fourth trait, invented effects or arbitrary stat inflation.
	traits.profiles.alpha = config().trait_profiles.alpha.duplicate(true)
	traits.profiles.alpha_unusual = config().trait_profiles.alpha_unusual.duplicate(true)
	var packet := HOOKS.prepare_host_spawn({"world_namespace": namespace_id, "spawn_id": id,
		"spawn_generation": generation, "alpha": true, "night": night, "weather": weather}, traits)
	if packet.is_empty(): return {}
	var record := old.duplicate(true)
	record.generation = generation
	record.status = "active"
	record.spawn_traits = packet
	return _plan(world, id, record, "alpha_spawn")

## Reattaching a saved active generation returns its retained roll. It must not
## increment the generation or run resolve/spawn again on load/reconnect.
static func retained_spawn(world: Dictionary, id: String) -> Dictionary:
	var record: Dictionary = _sites(world).get(id, {})
	return record.spawn_traits.duplicate(true) if record.get("status") == "active" else {}
