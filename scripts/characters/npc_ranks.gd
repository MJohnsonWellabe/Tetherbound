extends RefCounted

## Team Tether rank palettes (`NP2`, spec §36) — static lookups, same shape as
## `character_model.gd`'s own `config_for`.
##
## NP2-grunt-wire: grunt/officer/captain build on `art.json`'s `grunt` block
## (each rank entry's own `base` key, `data/config/npc_ranks.json`), not the
## Warden's rig — a blind visual pass rejected the old all-ranks-on-the-Warden
## ladder on two counts at once: the four rank frames read as one character
## repainted four times, AND reusing the boss's own body for his subordinates
## meant the boss himself stopped being unique. The Warden is the one rank
## with no `base` override, so `config_for("warden")` still falls back to
## `WARDEN_KEY` below — he is the only one who does not share a rig with
## anyone. The rank's own body palette (if any) and chest badge accessory are
## laid over whichever base that rank names. The badge, not the body tone, is
## still the primary rank read — a blind visual pass rejected a body-
## brightness-only ladder as reading like an exposure slider rather than a
## rank system. `config_for()` returns a dict ready for
## `CharacterModel.build_from_config()` directly.

const RANKS_PATH := "res://data/config/npc_ranks.json"
const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")

const WARDEN_KEY := "warden"


static func rank_ids() -> Array:
	var ranks: Dictionary = _read().get("ranks", {})
	return ranks.keys()


## The rank's own base config (model, height, clips — `art.json`, chosen by
## the rank entry's own `base` key, defaulting to the Warden's if the rank
## names none) with that rank's palette (if any) and badge accessory laid over
## it. Empty if the rank, or its base config, is missing, so a caller can fail
## loudly rather than build a rankless body.
##
## `base_override`, when non-empty, replaces the rank's own `base` key for
## this one call only — T3-INSTALL, 2026-08-30. Wires the seven generated-but-
## unused NPC meshes (`grunt_a/b/c`, `officer_a/b`, `captain_a/b`,
## `docs/specs/ASSET_LEDGER.md`) into the rank ladder: every grunt/officer/captain
## in the game shared exactly one body per rank before this, which is the
## same "one character repainted four times" defect NP2-grunt-wire already
## fixed once for ranks vs the Warden, just one rung down. A trainer entry
## opts in with its own `"base"` key (`trainer_npc.gd::model_config()` reads
## it and passes it here); a trainer that names none keeps the rank's shared
## body exactly as before, so this is additive, not a ladder rewrite.
static func config_for(rank: String, base_override: String = "") -> Dictionary:
	var ranks: Dictionary = _read().get("ranks", {})
	var entry: Variant = ranks.get(rank, {})
	if not entry is Dictionary or (entry as Dictionary).is_empty():
		return {}
	var rank_entry := entry as Dictionary

	var base_key := base_override if base_override != "" else str(rank_entry.get("base", WARDEN_KEY))
	var base := CHARACTER_MODEL.config_for(base_key)
	if base.is_empty():
		return {}

	var cfg := base.duplicate(true)
	if rank_entry.has("palette"):
		cfg["palette"] = rank_entry["palette"]
	# T1-CAST: the rank's own additive emission floor, read by
	# `character_model.gd::_shared_variant_material()` for body surfaces only.
	# Carried on the RANK rather than inferred from the palette multiply,
	# because the two answer different questions -- the multiply is where this
	# rank sits on the value ladder, the floor is how much lift the rig's
	# painted texture needs to clear the tonemap's toe at all, and the captain
	# is the case where a bright multiply and a near-black texture coincide.
	# A rank that declares none gets no floor, same as every unranked NPC.
	if rank_entry.has("emission_floor"):
		cfg["emission_floor"] = rank_entry["emission_floor"]
	# `badges` (an ordered list, back to front) or the single legacy `badge`.
	# The list exists so a rank can layer a rim behind its own face -- a ring and
	# a disc read as insignia where a lone disc read as a decal.
	if rank_entry.has("badges"):
		cfg["accessories"] = rank_entry["badges"]
	elif rank_entry.has("badge"):
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
