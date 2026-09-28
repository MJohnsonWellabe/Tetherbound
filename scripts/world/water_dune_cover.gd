extends RefCounted

## Local presentation copies only. Neither the terrain bake inputs nor imported
## resources are edited. The central gate is deliberately independent of terrain.
const CONFIG_PATH := "res://data/config/water_dune_cover.json"


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return parsed if parsed is Dictionary else {}


static func applies_to_island(island_id: String, settings: Dictionary) -> bool:
	return bool(settings.get("enabled", false)) \
		and not island_id in settings.get("preserve_islands", ["veilfall"])


static func ground_profile(source: Dictionary, settings: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	if not bool(settings.get("enabled", false)):
		return result
	var overrides: Dictionary = (settings.get("ground_cover", {}) as Dictionary).duplicate(true)
	for key: String in overrides:
		if key != "cover_tiers":
			result[key] = overrides[key]
	for tier: Dictionary in result.get("cover_tiers", []):
		for replacement: Dictionary in overrides.get("cover_tiers", []):
			if str(tier.get("name", "")) == str(replacement.get("name", "")):
				tier.merge(replacement.duplicate(true), true)
	return result


static func layer_profile(source: Dictionary, layer_name: String,
		island_id: String, settings: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	if applies_to_island(island_id, settings):
		var overrides: Dictionary = (settings.get("layers", {}) as Dictionary).get(layer_name, {})
		result.merge(overrides.duplicate(true), true)
	return result


static func accepts_shelter(point: Vector2, centre: Vector2, radius: float,
		layer: Dictionary, settings: Dictionary) -> bool:
	if not bool(settings.get("enabled", false)) or not bool(layer.get("_dune_sheltered", false)):
		return true
	var shelter: Dictionary = settings.get("shelter", {})
	var direction: Array = shelter.get("lee_direction_xz", [1.0, 0.35])
	var lee := Vector2(float(direction[0]), float(direction[1])).normalized()
	var local := (point - centre) / maxf(radius, 1.0)
	return local.length() <= float(shelter.get("max_radius_fraction", 0.78)) \
		and local.dot(lee) >= float(shelter.get("min_projection", 0.04))

