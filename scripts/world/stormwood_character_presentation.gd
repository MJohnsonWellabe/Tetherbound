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
	# F41#15 identity_floor_1112 (OFF until GPU-judged): the uniform floor exists
	# for the near-black grunt-family bodies. A named identity whose own body is
	# not dark (Captain Marrow: pale hair and skin) may state its own floor.
	var identity_floor: Variant = settings.get("identity_floor_1112", {})
	if identity_floor is Dictionary and bool((identity_floor as Dictionary).get("enabled", false)):
		var floors: Dictionary = (identity_floor as Dictionary).get("floors", {})
		if floors.has(canonical):
			result["emission_floor"] = float(floors[canonical])
	result["night_rim"] = (style.get("night_rim", {}) as Dictionary).duplicate(true)
	# F41#8 named_tint_1112 (OFF until GPU-judged): the named villagers' pale skin
	# and hair clip to white under the storm light ("faces burn orange-white", 3/3).
	# A listed identity's body albedo is multiplied by its own grey; nothing emits.
	var named_tint: Variant = settings.get("named_tint_1112", {})
	if named_tint is Dictionary and bool((named_tint as Dictionary).get("enabled", false)):
		var tints: Dictionary = (named_tint as Dictionary).get("tints", {})
		if tints.has(canonical):
			result["tint"] = str(tints[canonical])
	if uniform_rank.is_empty():
		return result
	# F41#18 uniform_separation_1113 (OFF until GPU-judged): the floor at 0 lost
	# the "chalky ghost wash" but the dark cloth then "sinks into the dark green
	# and black ground" (G-things-stormuniform, 3/3). Uniformed ranks keep the
	# floor at 0 and take a strong pale rim instead, plus the rank marks below.
	var separation: Variant = settings.get("uniform_separation_1113", {})
	if separation is Dictionary and bool((separation as Dictionary).get("enabled", false)):
		result["emission_floor"] = float((separation as Dictionary).get("emission_floor", 0.0))
		result["night_rim"] = ((separation as Dictionary).get("night_rim", {}) as Dictionary).duplicate(true)
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
	accessories.append_array(rank_marks(settings, identity, rank))
	# Preserve any individual accessories supplied by an authored placement.
	accessories.append_array((spec.get("accessories", []) as Array).duplicate(true))
	result["accessories"] = accessories
	return result

## F41#18 P2-056 `rank_marks_1104` (OFF until judged): judges read Stormwood
## officers as "small dark figures" with no rank read at normal distance; the
## chest badge is 5-13 cm. When enabled, every uniformed rank gains pale
## shoulder knots on both upper-arm bones and a collar ring on the neck in its
## identity colour, sized up for lieutenants and the captain. Presentation
## only: the base rig, palette, rank and dialogue are unchanged.
static func rank_marks(settings: Dictionary, identity: Dictionary, rank: String) -> Array:
	var cfg: Variant = settings.get("rank_marks_1104", {})
	var separation: Variant = settings.get("uniform_separation_1113", {})
	var with_separation: bool = separation is Dictionary \
			and bool((separation as Dictionary).get("enabled", false)) \
			and bool((separation as Dictionary).get("rank_marks", false))
	if not cfg is Dictionary or not (bool((cfg as Dictionary).get("enabled", false)) or with_separation):
		return []
	var scale := float(((cfg as Dictionary).get("rank_scale", {}) as Dictionary).get(rank, 1.0))
	var colour := str(identity.get("rim_color", (cfg as Dictionary).get("colour", "#d8cba0")))
	var out: Array = []
	for template: Variant in (cfg as Dictionary).get("marks", []):
		if not template is Dictionary:
			continue
		var mark := (template as Dictionary).duplicate(true)
		mark["size"] = float(mark.get("size", 0.1)) * scale
		if mark.has("height"):
			mark["height"] = float(mark.height) * scale
		mark["color"] = colour
		out.append(mark)
	return out

static func _read() -> Dictionary:
	if _settings.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if parsed is Dictionary:
			_settings = parsed
	return _settings
