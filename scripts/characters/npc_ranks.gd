extends RefCounted

## Team Tether rank palettes (`NP2`, spec §36) — static lookups, same shape as
## `character_model.gd`'s own `config_for`.
##
## Every rank reuses the Warden's rig (the only faction-appropriate body
## installed today; see `data/config/npc_ranks.json`'s own comment on why),
## with the rank's own body palette (if any) and chest badge accessory laid
## over his base config. The badge, not the body tone, carries the rank read —
## a blind visual pass rejected a body-brightness-only ladder as reading like
## an exposure slider rather than a rank system. `config_for()` returns a dict
## ready for `CharacterModel.build_from_config()` directly.

const RANKS_PATH := "res://data/config/npc_ranks.json"
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

const WARDEN_KEY := "warden"


static func rank_ids() -> Array:
	var ranks: Dictionary = _read().get("ranks", {})
	return ranks.keys()


## The Warden's own base config (model, height, clips) with the named rank's
## palette (if any) and badge accessory laid over it. Empty if the rank or the
## Warden's own config is missing, so a caller can fail loudly rather than
## build a rankless body.
static func config_for(rank: String) -> Dictionary:
	var ranks: Dictionary = _read().get("ranks", {})
	var entry: Variant = ranks.get(rank, {})
	if not entry is Dictionary or (entry as Dictionary).is_empty():
		return {}
	var rank_entry := entry as Dictionary

	var base := CHARACTER_MODEL.config_for(WARDEN_KEY)
	if base.is_empty():
		return {}

	var cfg := base.duplicate(true)
	if rank_entry.has("palette"):
		cfg["palette"] = rank_entry["palette"]
	if rank_entry.has("badge"):
		cfg["accessories"] = [rank_entry["badge"]]
	return cfg


static func label_for(rank: String) -> String:
	var ranks: Dictionary = _read().get("ranks", {})
	var entry: Variant = ranks.get(rank, {})
	return str((entry as Dictionary).get("label", rank.capitalize())) if entry is Dictionary else rank.capitalize()


static func _read() -> Dictionary:
	var file := FileAccess.open(RANKS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
