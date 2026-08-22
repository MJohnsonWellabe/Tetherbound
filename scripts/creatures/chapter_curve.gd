extends RefCounted

## The Meadows chapter's progression curve, read from data/config/chapter_curve.json.
##
## Same shape and the same reasoning as scripts/creatures/progression.gd: pure
## static functions over numbers that live in data, so the curve can be retuned
## by a regional package editing one JSON file instead of by finding every
## place a level got hard-coded into gameplay code.
##
## What this adds that progression.gd could not. `progression.json`'s
## `level.wild_band` is a SINGLE global band -- every wild creature in the
## chapter rolled 2-6, from the practice meadow to the stronghold approach 7.5km
## away. That is fine for one region and wrong for a chapter: it means the field
## stops being opposition after the first hour, and it means a creature caught
## late arrives a dozen levels below the team it is joining, which quietly
## retires the five-creature limit as a decision (see chapter_curve.json's
## `five_slot` comment). This file resolves the band from a spawn's world
## position instead.
##
## `level.wild_band` is NOT removed. It stays the fallback for every caller with
## no position to offer -- the combat sandbox, unit tests, any scene that is not
## the Meadows corridor -- so nothing that worked before this file needs to know
## it exists.

const CONFIG_PATH := "res://data/config/chapter_curve.json"

static var _config: Dictionary = {}


## The shipped chapter_curve.json, cached after the first read.
static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("chapter_curve.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## The regions in route order, each a dictionary straight out of the file.
static func regions(cfg: Dictionary) -> Array:
	return cfg.get("regions", []) as Array


## The region a world z falls in, or an empty dictionary if the table is empty.
##
## Resolved by upper bound in route order, matching
## `world_perimeter.gd::_band_for()` exactly: anything below the first `z_to`
## is region 1, which deliberately also swallows the unauthored north fringe
## behind Grandpa's farm rather than leaving it regionless. A z past the last
## bound returns the last region for the same reason at the other end.
static func region_at(z: float, cfg: Dictionary) -> Dictionary:
	var list: Array = regions(cfg)
	if list.is_empty():
		return {}
	for entry: Variant in list:
		var region: Dictionary = entry as Dictionary
		if z < float(region.get("z_to", 0.0)):
			return region
	return list[list.size() - 1] as Dictionary


## The wild level band `[low, high]` authored for the region containing `z`, or
## an empty array when the curve has nothing to say. An empty return is the
## caller's cue to fall back to `progression.json`'s global `level.wild_band`
## rather than to invent a number here.
static func wild_band_at(z: float, cfg: Dictionary) -> Array:
	var region: Dictionary = region_at(z, cfg)
	var band: Array = region.get("wild_band", []) as Array
	return band if band.size() >= 2 else []


## The team level band `[enter, exit]` the chapter expects at `z`. Measured, not
## wished for -- see chapter_curve.json's `_comment_measurement`. Nothing in the
## game reads this to gate anything (prompt 57: no level-lock UI, no player
## scaling); it exists so a regional package and
## `tests/test_chapter_curve.gd` can check authored content against the same
## numbers.
static func team_band_at(z: float, cfg: Dictionary) -> Array:
	var region: Dictionary = region_at(z, cfg)
	var team: Dictionary = region.get("team", {}) as Dictionary
	if team.is_empty():
		return []
	return [int(team.get("enter", 1)), int(team.get("exit", 1))]


## A copy of `progression_cfg` whose `level.wild_band` is the band authored for
## `z`, ready to hand to `creature_instance.from_species()` or
## `progression.roll_wild_level()`.
##
## A copy, never a mutation: `progression.gd::config()` hands out its own cached
## dictionary, and writing a per-spawn band into it would leave whichever
## creature spawned last silently deciding the band for every later caller in
## the process, including the combat sandbox and any test that ran afterwards.
static func progression_config_at(z: float, progression_cfg: Dictionary, cfg: Dictionary) -> Dictionary:
	var band: Array = wild_band_at(z, cfg)
	if band.is_empty():
		return progression_cfg
	var out: Dictionary = progression_cfg.duplicate(true)
	var level_cfg: Dictionary = out.get("level", {}) as Dictionary
	level_cfg["wild_band"] = band.duplicate()
	out["level"] = level_cfg
	return out
