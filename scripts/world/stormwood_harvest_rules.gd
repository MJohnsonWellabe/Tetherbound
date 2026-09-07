extends RefCounted

const SURGE := preload("res://scripts/world/stormwood_surge_rules.gd")
const PATH := "res://data/config/stormwood_harvests.json"
var sites: Dictionary = {}
var surge := SURGE.new()

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	for site: Dictionary in data.get("sites", []):
		sites[str(site.id)] = site

func refusal(id: String, world: RefCounted) -> String:
	if not sites.has(id):
		return "That resource is not part of this forest."
	var site: Dictionary = sites[id]
	var region := str(site.region_id)
	var flags: RefCounted = world.get("flags")
	var gate := {"hollow_crown":"stormwood:crown_reached", "deepwood":"stormwood:rootgate_released", "dynamo":"stormwood:rootgate_released"}.get(region, "") as String
	if not gate.is_empty() and not flags.has(gate):
		return "The route to that resource is still closed."
	var environment: Dictionary = world.get("realm_environment")
	var saved: Variant = environment.get("stormwood", {})
	var raw: Variant = saved.get("elapsed", 0.0) if saved is Dictionary else 0.0
	var elapsed := maxf(0.0, float(raw)) if (raw is float or raw is int) and is_finite(float(raw)) else 0.0
	var rod := str(surge.config.regions.get(region, {}).get("rod_flag", ""))
	var phase := str(surge.phase_at(elapsed, region, not rod.is_empty() and flags.has(rod), flags.has("stormwood:long_storm_ended")).phase)
	if not (site.get("availability", []) as Array).has(phase):
		return "This seam wakes during the Break and Fading."
	return ""

static func flag(id: String) -> String:
	return "harvest_node:order:" + id
