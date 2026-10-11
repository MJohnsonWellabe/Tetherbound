extends RefCounted

## Shared by the talking and challenging versions of Stormwood's cast.
## These are model inputs only; combat rank, dialogue and authority stay on
## the original spec. The installed base rig and its painted features survive.
const CONFIG_PATH := "res://data/config/stormwood_character_presentation.json"
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
static var _settings: Dictionary = {}

static func decorate(spec: Dictionary, identity_id: String, authored_rank: String = "") -> Dictionary:
	var result := spec.duplicate(true)
	var settings := _read()
	var canonical := str(settings.get("aliases", {}).get(identity_id, identity_id))
	var identity: Dictionary = settings.get("identities", {}).get(canonical, {})
	var rank := str(identity.get("rank", authored_rank))
	var uniform_rank := str(settings.get("rank_uniforms", {}).get(rank, ""))
	var style: Dictionary = settings.get("uniform" if not uniform_rank.is_empty() else "civilian", {})
	result["emission_floor"] = float(style.get("emission_floor", 0.0))
	result["night_rim"] = (style.get("night_rim", {}) as Dictionary).duplicate(true)
	if uniform_rank.is_empty():
		return result
	result["presentation_rank"] = uniform_rank
	result["base"] = str(spec.get("config_key", ""))
	var ranked := NPC_RANKS.config_for(uniform_rank, result.base)
	var accessories: Array = ranked.get("accessories", []).duplicate(true)
	var extra_rims: Array = []
	for item: Dictionary in accessories:
		if str(item.get("name", "")) != "badge_rim":
			continue
		# The existing seated rank rim carries identity colour; do not tint
		# the whole body or add a marker at an unmeasured shoulder position.
		item["color"] = str(identity.get("rim_color", item.get("color", "#d2bd85")))
		if rank == "lieutenant":
			var outer := item.duplicate(true)
			outer["name"] = "lieutenant_outer_rim"
			outer["size"] = float(item.get("size", 0.10)) * float(settings.get("lieutenant_rim_scale", 1.28))
			extra_rims.append(outer)
	accessories.append_array(extra_rims)
	# Preserve any individual accessories supplied by an authored placement.
	accessories.append_array((spec.get("accessories", []) as Array).duplicate(true))
	result["accessories"] = accessories
	return result

static func _read() -> Dictionary:
	if _settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if parsed is Dictionary:
			_settings = parsed
	return _settings
