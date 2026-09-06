extends RefCounted

## Versioned save/load for the state that has to survive a quit: the party,
## the satchel, the day counter, placed buildings (R3.1), creature
## progression/satiety/the map database (VERSION 2), SB9's progression-flag
## store (VERSION 3), every death satchel the player has left in the world
## (VERSION 4, R3.2), each creature's individuality rolls and traits
## (VERSION 5, R4.2), and — as of VERSION 9 — what each bed of the berry farm
## is growing (R7.6).
##
## Same shape `docs/decisions/D15` set for `user://settings.json`: JSON, a
## `version` field from the first write, and never fatal on load — a missing,
## corrupt, or newer-than-this-build slot just means "nothing to load", the
## same three "carry on, do not brick the player" cases D15 named for
## settings.
##
## ## VERSION 2 — what changed, and the migration story
##
## D30 (creature progression: level/xp/bond/moves) and D33 (the map database) both
## landed after VERSION 1 shipped, and D29 (satiety) needed its own slot in
## the file. A VERSION 1 save on a VERSION 2+ build now migrates instead of
## being refused (`_migrate_v1`): every creature is set to
## `data/config/progression.json`'s `migration.v1_creature_level` (fallback 3),
## `xp` 0, `bond` 0, and its quick/charged moves looked up from
## `data/creatures/species.json` by `species_id` (empty string for a species the
## catalogue no longer knows, same "trust nothing you cannot look up" rule
## `_array_to_party` already followed); satiety is set to full
## (`data/config/vitals.json`'s `satiety.max`, fallback 100); the map comes
## back fresh (nothing visited, nothing discovered — there is no fog trail to
## recover from a save that predates the map); and every building gets
## `yaw_deg: 0.0`. `_migrate_v1` lands on VERSION 2's shape and then chains
## into `_migrate_v2` below, same as a real VERSION 2 file would.
##
## ## VERSION 3 — SB9's progression flags
##
## `autoload/progression_state.gd` did not exist before this, so a VERSION 1
## or 2 save has no flags to recover — `_migrate_v2` hands back an empty
## store, the same "nothing to migrate FROM" answer VERSION 1 -> 2 already
## gave the map. A version newer than this build still refuses exactly as
## VERSION 1 always refused everything but itself — there is still nothing to
## migrate an unreleased future format DOWN from.
##
## ## VERSION 4 — death satchels (R3.2)
##
## `GameState.death_satchels` did not exist before this either, so the same
## "nothing to migrate FROM" answer applies again: `_migrate_v3` hands back
## an empty list. A death satchel dropped under an older build is simply not
## in that save — it was never written down anywhere for this to recover.
##
## ## VERSION 5 — individuality and traits (R4.2)
##
## `creature_instance.gd`'s `iv_hp`/`iv_attack`/`iv_defence` and
## `trait_primary`/`trait_secondary` did not exist before this — same
## "nothing to migrate FROM" answer again. `_migrate_v4` sets every migrated
## creature's IVs to 0.5 (perfectly average, `PROGRESSION.individuality_
## multiplier`'s own no-op value) and both trait fields to "" (no trait
## rolled), which is exactly what a creature caught before this system
## existed should read as: unremarkable and untraited, not retroactively
## graded.
##
## ## VERSION 6 — shiny (OF27)
##
## `creature_instance.gd`'s `shiny` did not exist before this — same
## "nothing to migrate FROM" answer every migration above already gives.
## `_migrate_v5` sets every migrated creature's `shiny` to `false`: a
## creature caught before the roll existed was never entered into it, the
## same way a save from before R4.2 was never entered into the individuality
## roll and comes back merely average rather than retroactively perfect.
##
## ## VERSION 7 — the hotbar became assignable
##
## The hotbar used to be a view, not state: `playground_hud.gd` mirrored
## satchel slots 0-4, so there was nothing to save. Owner directive after
## playing made it a real assignable bar of item ids, which means it is now
## state and has to survive a quit. `_migrate_v6` writes an empty bar and
## `game_state.gd::autofill_hotbar()` refills it from what the player is
## carrying — the closest honest reconstruction of what the old mirror showed,
## minus the raw materials that used to occupy action slots and do nothing.
##
## ## VERSION 8 — permanent stat elixirs (D47)
##
## `creature_instance.gd`'s `boost_hp`/`boost_attack`/`boost_defence` did not
## exist before this. Same "nothing to migrate FROM" answer every migration
## above already gives, and `_migrate_v7` does not need to write anything: the
## read side defaults each to 0, which is what a creature that never drank an
## elixir has. The migration exists only to move the version number.
##
## ## VERSION 9 — the berry farm's beds (R7.6)
##
## `game_state.gd::farm_plots` did not exist before this, so `_migrate_v8`
## gives the same "nothing to migrate FROM" answer: an empty list, read back
## as six fallow beds. This is the first save field whose value CHANGES while
## the player is nowhere near it — a sown bed ripens off `day`, not off a
## timer running in a loaded scene — which is exactly why it had to be in the
## file rather than rebuilt on load the way a harvest node's respawn clock is.
##
## VERSION 9 is also where the migration DISPATCH was rewritten from a
## per-version `if/elif` ladder into a loop (`_migrate_to_current`). That was
## not tidying: the ladder had no branch for versions 6 or 7, so saves written
## between the hotbar change and the elixir one were refused outright by a
## build that had both of their migration steps sitting right there. See that
## function's own comment.
##
## ## VERSION 10 — permanently-chopped vegetation (HARVEST-ALL, D60)
##
## `game_state.gd::harvested_vegetation` did not exist before this. Same
## "nothing to migrate FROM" answer every migration above gives: `_migrate_v9`
## hands back `{}`, read as "nothing chopped yet" — a save from before this
## shipped predates permanent harvesting entirely, so every tree and rock it
## remembers comes back exactly as it was, not retroactively cleared.
##
## ## VERSION 11 — felled-but-ungathered piles (RG9)
##
## `game_state.gd::felled_vegetation` did not exist before this. A VERSION 10
## save has nothing chopped-but-not-yet-picked-up to remember by construction
## — chop-then-gather did not exist yet, every chop paid out immediately — so
## `_migrate_v10` hands back `{}`, the identical "nothing to migrate FROM"
## answer every step above gives its own new field.
##
## ## GAME-F4 — `base_hp`/`base_attack`/`base_defence` join the party fields,
## with NO version bump
##
## Unlike every field above, these are not new state: `creature_instance.gd`
## has always carried them, `_party_to_array` simply never wrote them, so
## `_array_to_party` always left them at the class default of 1.0 — invisible
## until the next level-up/elixir/evolve recomputed the real stats FROM that
## 1.0 and destroyed them (`_apply_level_stats`). This is a bug fix to what a
## save has always been supposed to mean, not a new field a pre-fix save
## honestly has nothing for, so it does not get a `_migrate_vN` step: every
## `_array_to_party` read (regardless of the save's stamped version, VERSION
## 15 included) falls back to the creature's `species.json` entry when
## `base_hp` is absent — the exact repair `apply_species_definition` was
## already promised to do by two comments that pre-date this fix. A version
## bump here would need a `_migrate_v15` that does nothing a version-agnostic
## default in `_array_to_party` cannot already do, and would carry the real
## risk the comment on `_migrate_v13`'s neighbour warns about: forgetting the
## step refuses every existing save outright, which is a strictly worse
## failure than the bug this is fixing. Independently found and fixed with a
## version bump by GATE-F-LEG-S10CDE (measured: a level 3 ripplet loaded
## through the production Load path went from 117.60 max hp to 1.18 on its
## next level-up) -- the bump was reverted here for the same reason S09's was.
##
## ## VERSION 16 — OWNER-0901-BOND-MILESTONES
##
## Bond became an ordered ladder of concrete tasks instead of a bare 0-100
## meter (owner playtest 2026-09-01). Four of its five tasks needed a new
## per-creature counter: `landmarks_visited_together`, `distance_m_together`,
## `rest_nights_together`, `feeds_together` (the fifth, `battles_fought`,
## already existed — see `bond_milestones.json`'s own comment). Same "nothing
## to migrate FROM" answer `_migrate_v13` gives battles_fought's own siblings:
## a pre-16 save was not counting any of these, so zero is the true statement
## that the history was never kept, not a placeholder. The legacy `bond` int
## itself is untouched and keeps round-tripping as-is; nothing reads it as a
## gate any more, but nothing needs to erase it either. This landed after
## VERSION 15 (T3-ENCOUNTER's `world_seed`) went in on `main`, hence 16 rather
## than the 15 an earlier pass on this branch used before rebasing.
##
## ## VERSION 17 — REALMS AND REALM HEARTS
##
## Cloudreach adds a second world scene and the one-active Realm Heart choice.
## `current_realm` selects the scene Continue enters; `realm_hearts` stores the
## active Heart id. Older saves honestly belong to the Meadows and have no
## active Heart, so `_migrate_v16` supplies exactly those defaults.
##
## NOTE (landing lane, merge resolution): this lane and Cloudreach both authored a
## VERSION 17. Per the owner's standing rule that Cloudreach wins a conflict,
## Cloudreach keeps 17 (realms and Realm Hearts) and the alpha pin set became 18.
## `_migrate_to_current` dispatches `_migrate_v<version>` in a loop, so a v16 save
## now runs `_migrate_v16` (realms) and then `_migrate_v17` (pins).

## ## VERSION 18 — CL-W1, the alpha pin set
##
## Owner directive D-0904B-1 with amendment A-3: an alpha within 300 m pins
## itself to the map and the pin stays until that alpha is caught or beaten.
## The closure plan's *fails if* on that row is exactly this file's problem —
## "the pinned set is not persisted; a pin that survives only until the next
## load is worse than none" — so `alpha_pins` is a top-level key here, written
## from and read back into `map_state.gd`'s own `alpha_pin_save_data()` /
## `alpha_pin_load_data()`.
##
## It is deliberately NOT folded into the existing `map` blob, even though the
## map object owns it. `map` is the map database (fog bytes, discovered
## landmarks, regions, markers) and has its own tolerant, versionless internal
## contract; the pinned set is gameplay state that happens to be drawn on the
## map, and a reviewer opening a save file should be able to see whether a pin
## survived without inferring it from a marker list.
##
## Same "nothing to migrate FROM" answer every migration above gives: a pre-18
## save was not tracking pins, so `[]` is the true statement that no alpha had
## been discovered yet, not a placeholder. The player re-pins the moment they
## walk back within 300 m of one, and any alpha they already beat stays cleared
## because clearing reads `progression`'s own `wild_once_<order>` flag, which
## has round-tripped since VERSION 3.
##
## ## The satiety seam
##
## Satiety lives on `PlayerVitals` (`scripts/player/player_vitals.gd`), a
## plain `RefCounted` hanging off the live `Player` node — not on `Game`, and
## not reachable from here without going through the scene tree, which this
## file deliberately never does (see below). So `game` is asked for it
## instead, through the same duck-typed contract `day`/`party`/`inventory`
## already use:
##
##   - if `game` has a `player_vitals()` method and it returns something,
##     that live object is read from (on save) or written to directly (on
##     load) — the actual value a running game cares about, never copied.
##   - otherwise, a plain `satiety` property on `game` itself is the
##     fallback: read on save, written on load. This is the path a headless
##     test double (or `Game` itself before any world scene exists) takes,
##     and it is exactly why `Game` carries its own `satiety` field even
##     though a running game always prefers the live vitals object over it.
##
## Both branches round-trip cleanly, which is the property that actually
## matters: `tests/test_save_format.gd` exercises each one directly, without
## either needing a scene tree.
##
## ## Pure logic, no nodes
##
## `tests/test_save_format.gd` exercises this headlessly — the same split
## `autoload/party.gd`, `autoload/inventory.gd` and `scripts/ui/key_bindings.gd`
## all already draw. `game` below is whatever object holds `day`, `party`,
## `inventory`, `placed_buildings`, `map` and `satiety` as properties (plus,
## optionally, a `player_vitals()` method) — the `Game` autoload in the real
## build, a small fake in tests.

const CREATURE_INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const CREATURE_CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const PROGRESSION_CONFIG_PATH := "res://data/config/progression.json"
const VITALS_CONFIG_PATH := "res://data/config/vitals.json"
const SPECIES_PATH := "res://data/creatures/species.json"

## VERSION 18 — Fly state, stamina fraction, active party slot, and verified
## ground recovery anchor inside player_pose. Airborne reloads resume safely
## grounded; old poses migrate unchanged and all realm rewards are preserved.
## VERSION 19 — separate realm-map fog and discoveries. Untagged legacy map
## payloads belong to Meadows even when an early save selected Cloudreach.
## VERSION 20 — realm ownership for player buildings and death satchels.
## Untagged records migrate to Meadows even when a v19 save selects Cloudreach.
## VERSION 21 — CL-W1's alpha pin set (lane W11-ALPHA-PINS-0904).
##
## NOTE (landing lane): W11 and Cloudreach have now collided on a save version
## twice. W11 first authored 17, was moved to 18 when Cloudreach claimed 17, and
## is moved again to 21 here because Cloudreach's branch claims 18, 19 and 20.
## The owner's standing rule is that Cloudreach wins, so the pin set takes the
## next free number each time. `_migrate_to_current` dispatches
## `_migrate_v<version>` in a loop, so a v16 save now runs realms (16→17), fly
## state (17→18), realm fog (18→19), realm ownership (19→20) and finally the
## pins (20→21), in that order.
## VERSION 22 — the carried day clock (N14-ROUTED-FOLLOWUPS, from
## N13-NIGHT-RESUME §5). Before this key the format carried no clock at all, so
## every Continue rebuilt the world at 08:00 and the player walked the 350
## seconds to nightfall again. Negative means "no carried clock, open at the
## authored morning" — `game_state.gd::CLOCK_UNSET`. N14 authored it as 19,
## which Cloudreach owns; it takes the next free number here for the same
## reason the pin set did.
const VERSION := 22
const WORLD_RECORDS := preload("res://scripts/world/realm_world_records.gd")
const SLOT_COUNT := 5
## Written automatically whenever the player rests (`scripts/build/camp.gd`).
## Slots 1-4 are the player's own manual saves. Nothing enforces the split
## beyond this comment — any slot reads and writes the same way.
const AUTOSAVE_SLOT := 0

## D100's two savers. The v22 slot file above is still written, unchanged and
## byte-identical, and is still what `load_slot()` reads -- see `_write_split()`
## for why this lane ADDED the split rather than replacing the slot with it.
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")

var _dir: String
var _worlds: RefCounted = null
var _characters: RefCounted = null


## `dir` is the slot directory. The two D100 directories are the real
## `user://worlds/` and `user://characters/` ONLY for the real slot directory:
## a saver pointed at a scratch directory (every test in `tests/`, and
## `smoke_alpha_pins`) gets scratch split directories under it, so a unit test
## can never leave a world or a character behind where a real playthrough on the
## same machine would find it.
func _init(dir: String = "user://saves/") -> void:
	_dir = dir if dir.ends_with("/") else dir + "/"
	if _dir == "user://saves/":
		_worlds = WORLD_SAVE.new("user://worlds/")
		_characters = CHARACTER_SAVE.new("user://characters/")
	else:
		_worlds = WORLD_SAVE.new(_dir + "worlds/")
		_characters = CHARACTER_SAVE.new(_dir + "characters/")


## The two savers, for a caller that needs to read a world or a character
## without going through a slot (`session.gd`, `tests/`).
func worlds() -> RefCounted:
	return _worlds


func characters() -> RefCounted:
	return _characters


func slot_path(slot: int) -> String:
	return "%sslot_%d.json" % [_dir, slot]


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## What a slot list screen needs without loading it onto live state — empty
## for no save, an unreadable file, or a version this build cannot read.
func slot_info(slot: int) -> Dictionary:
	var data := _read(slot)
	if data.is_empty():
		return {}
	var version := int(data.get("version", 0)) if _finite_number(data.get("version")) else 0
	return {
		"day": int(data.get("day", 1)),
		"party_size": (data.get("party", []) as Array).size(),
		"realm": str(data.get("current_realm", "meadows")),
		# D100: the title screen lists a slot written by an older build under a
		# "Legacy" label until it has been opened once, because opening it is
		# what splits it into a world and a character. Derived from the stamped
		# version rather than from "is there a legacy-slot-N directory": a slot
		# the player has since re-saved is at the current version and is not
		# legacy any more, and the directory would say it forever.
		"legacy": version > 0 and version < VERSION,
	}


## Serialize `game` into `slot`. Returns whether the write succeeded.
##
## D100's split is written ALONGSIDE the slot file, not instead of it -- see
## `_write_split()`.
##
## `write_split` exists for ONE caller shape: a scratch write that is not a save
## of record. `tools/net/peer_runner.gd` calls `save()` into a scratch slot on
## every heartbeat purely to hash the bytes back, and on every peer. Letting
## that write the D100 store would mint a world and a character named after the
## scratch slot, stamp that scratch id onto the live `Game.local` -- where the
## peer registry then advertises it to everybody -- and rewrite both files
## several times a second. A hash probe must not be able to rename a trainer.
func save(game: Object, slot: int, write_split: bool = true) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	DirAccess.make_dir_recursive_absolute(_dir)

	var data := snapshot(game)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	# A save may be loaded again immediately from the same UI/session. Close the
	# writer before reporting success so that read never observes a buffered or
	# partially flushed JSON document.
	file.close()
	if write_split:
		_write_split(game, slot, data)
	return true


## The v22 save dictionary for `game`, with nothing written to disk.
##
## Split out of `save()` by lane 1.C because three callers now need the
## dictionary rather than the file: `save()` itself, `save_world()` and
## `save_character()`. `tools/net/peer_runner.gd`'s desync hash wanted exactly
## this and said so ("no dictionary-only accessor"), but it is left alone here:
## re-pointing it is a harness change in another lane's file, and it works.
func snapshot(game: Object) -> Dictionary:
	var map_obj: Variant = game.get("map")
	var progression_obj: Variant = game.get("progression")
	var realm_hearts_obj: Variant = game.get("realm_hearts")
	var data := {
		"version": VERSION,
		"day": int(game.get("day")),
		"party": _party_to_array(game.get("party")),
		"inventory": _inventory_to_array(game.get("inventory")),
		"hotbar": _hotbar_to_array(game),
		"placed_buildings": WORLD_RECORDS.normalized(game.get("placed_buildings")),
		"farm_plots": (game.get("farm_plots") as Array).duplicate(true),
		"death_satchels": WORLD_RECORDS.normalized(game.get("death_satchels")),
		"satiety": _read_satiety(game),
		"map": (map_obj as RefCounted).call("save_data") if map_obj != null else {},
		"alpha_pins": (map_obj as RefCounted).call("alpha_pin_save_data") if map_obj != null else [],
		"progression": (progression_obj as RefCounted).call("save_data") if progression_obj != null else {},
		"realm_hearts": (realm_hearts_obj as RefCounted).call("save_data") if realm_hearts_obj != null else {},
		"current_realm": str(game.get("current_realm")) if game.get("current_realm") != null else "meadows",
		"pending_realm_entry": str(game.get("pending_realm_entry")) if game.get("pending_realm_entry") != null else "",
		"harvested_vegetation": (game.get("harvested_vegetation") as Dictionary).duplicate(true),
		"world_seed": int(game.get("world_seed")) if game.get("world_seed") != null else 0,
		"felled_vegetation": (game.get("felled_vegetation") as Dictionary).duplicate(true),
		"player_pose": _capture_traversal_pose(game),
		# N14-ROUTED-FOLLOWUPS, from N13-NIGHT-RESUME §5. VERSION 19. Before
		# this key the format carried no clock at all, so every Continue
		# rebuilt the world at 08:00 and the player walked the 350 seconds to
		# nightfall again. Negative means "no carried clock, open at the
		# authored morning" -- `game_state.gd::CLOCK_UNSET`.
		"clock_elapsed_seconds": _read_clock(game),
	}
	data["realm_maps"] = game.call("save_realm_maps") if game.has_method("save_realm_maps") else _realm_map_payloads(data)
	return data


## Rehydrate `game` from `slot`. Returns whether a save was actually applied —
## false, with `game` left untouched, for a missing, corrupt, or
## newer-than-this-build file.
func load_slot(game: Object, slot: int) -> bool:
	var data := _read(slot)
	if data.is_empty():
		return false
	var version := int(data.get("version", 0))
	if version < 1 or version > VERSION:
		# A newer-than-this-build file still refuses, exactly as VERSION 1
		# always refused everything but itself: there is nothing to migrate an
		# unreleased future format DOWN from.
		push_warning("save slot %d is version %d, this build reads %d -- not loading" % [
			slot, version, VERSION
		])
		return false
	data = _migrate_to_current(data, version, slot)
	if data.is_empty():
		return false

	# D100, before a single field is applied: this slot becomes one world file
	# and one character file, and the slot file itself is not touched.
	_split_legacy_slot(game, slot, data)

	game.set("day", int(data.get("day", 1)))
	_array_to_party(data.get("party", []), game.get("party"))
	_array_to_inventory(data.get("inventory", []), game.get("inventory"))
	_array_to_hotbar(data.get("hotbar", []), game)
	game.set("placed_buildings", WORLD_RECORDS.normalized(data.get("placed_buildings", [])))
	game.set("farm_plots", (data.get("farm_plots", []) as Array).duplicate(true))
	game.set("death_satchels", WORLD_RECORDS.normalized(data.get("death_satchels", [])))
	game.set("world_seed", int(data.get("world_seed", 0)))
	var harvested_raw: Variant = data.get("harvested_vegetation", {})
	game.set("harvested_vegetation", (harvested_raw as Dictionary).duplicate(true) if typeof(harvested_raw) == TYPE_DICTIONARY else {})
	var felled_raw: Variant = data.get("felled_vegetation", {})
	game.set("felled_vegetation", (felled_raw as Dictionary).duplicate(true) if typeof(felled_raw) == TYPE_DICTIONARY else {})
	if game.get("saved_player_pose") != null:
		var pose_raw: Variant = data.get("player_pose", {})
		game.set("saved_player_pose", _sanitise_player_pose(pose_raw))
	if game.get("current_realm") != null:
		game.set("current_realm", str(data.get("current_realm", "meadows")))
	if game.get("pending_realm_entry") != null:
		game.set("pending_realm_entry", str(data.get("pending_realm_entry", "")))
	if game.get("clock_elapsed_seconds") != null:
		game.set("clock_elapsed_seconds", _finite_clock(data.get("clock_elapsed_seconds")))
	_write_satiety(game, float(data.get("satiety", _default_satiety())))

	var map_obj: Variant = game.get("map")
	if map_obj != null and not game.has_method("restore_realm_maps"):
		var map_data: Variant = data.get("map", {})
		(map_obj as RefCounted).call("load_data", map_data if typeof(map_data) == TYPE_DICTIONARY else {})

	var progression_obj: Variant = game.get("progression")
	if progression_obj != null:
		var progression_data: Variant = data.get("progression", {})
		(progression_obj as RefCounted).call("load_data", progression_data if typeof(progression_data) == TYPE_DICTIONARY else {})
		_reconcile_meadows_realm_rewards(progression_obj as RefCounted)
	if game.has_method("restore_realm_maps"):
		game.call("restore_realm_maps", _realm_map_payloads(data))

	# CL-W1. STRICTLY AFTER whichever map restore ran above, because both clear
	# every dynamic marker wholesale — restoring the pins first would rebuild
	# their markers and then immediately throw them away, which is the "a pin
	# that survives only until the next load is worse than none" failure the row
	# is written against.
	#
	# Moved here by the landing lane, 2026-09-05, and this is a real merge
	# interaction rather than a tidy-up. The pin restore used to sit inside the
	# `not game.has_method("restore_realm_maps")` branch above. Cloudreach's
	# VERSION 19 work ADDED `restore_realm_maps`, so that branch became
	# permanently false and the pins stopped being loaded at all —
	# `smoke_alpha_pins` failed with "the pin did not survive a real save and
	# load". Neither lane is wrong on its own; only the combination is. Running
	# it unconditionally after both paths satisfies W11's ordering requirement
	# and leaves Cloudreach's realm-map restore untouched.
	# The map object is RE-READ here rather than reusing `map_obj` from above:
	# `restore_realm_maps()` ends in `bind_realm_map()`, which rebinds
	# `game.map` to the realm's own instance. Loading the pins into the object
	# captured before that call put them on an orphaned map that nothing draws.
	var live_map: Variant = game.get("map")
	if live_map != null:
		var alpha_pin_data: Variant = data.get("alpha_pins", [])
		(live_map as RefCounted).call(
			"alpha_pin_load_data",
			alpha_pin_data if typeof(alpha_pin_data) == TYPE_ARRAY else [])

	var realm_hearts_obj: Variant = game.get("realm_hearts")
	if realm_hearts_obj != null:
		var hearts_data: Variant = data.get("realm_hearts", {})
		(realm_hearts_obj as RefCounted).call(
			"load_data",
			hearts_data if typeof(hearts_data) == TYPE_DICTIONARY else {},
			progression_obj as RefCounted if progression_obj != null else null)
	var loaded_pose := _sanitise_player_pose(data.get("player_pose", {}))
	var traversal: Dictionary = loaded_pose.get("traversal", {})
	if not traversal.is_empty():
		game.set_meta("pending_fly_load", traversal)
		var party: Variant = game.get("party")
		if party != null and int(traversal.get("active_index", -1)) >= 0:
			party.call("set_active", int(traversal["active_index"]))
	elif game.has_meta("pending_fly_load"):
		game.remove_meta("pending_fly_load")
	return true


# --- D100: the world/character split -------------------------------------------
##
## ## Why the v22 slot file is still written
##
## D100 replaces the slot with `user://worlds/<world_id>/world.json` plus
## `user://characters/<character_id>/character.json`, and this lane writes both.
## It does NOT stop writing `user://saves/slot_<n>.json`, and that is a
## deliberate, reported deviation rather than an unfinished half:
## `slot_path()` is read by the whole Gate F operator harness, by
## `tools/net/peer_runner.gd`'s desync hash (which calls `save()` and reads the
## bytes back on EVERY peer, host and client alike), and by nineteen test files.
## Refusing the slot write on a client would have returned `null` from that hash
## on every client heartbeat, which the coordinator reports as a harness fault --
## four other lanes' smokes, broken by a save-format lane. So the slot file
## stays exactly what it was, byte for byte, and the split is written next to it.
##
## What that costs is one duplicated copy of the same dictionary on disk. What
## it buys is that no path in the game changed shape while the character half
## was being added, so a defect here cannot lose an existing save.

## Write the D100 pair for a slot write. Never fatal: a failed split leaves the
## slot file -- which is still the one `load_slot()` reads -- untouched and
## correct.
##
## Ownership, exactly as D100 states it: the host writes the world file, EVERY
## peer writes its own character file, and a client never writes a world file.
## `_is_host()` asks the game, never `multiplayer.is_server()` -- with an
## `OfflineMultiplayerPeer` that call is true and `get_unique_id()` is 1, so it
## cannot tell a solo player from a host and cannot tell a client from either.
func _write_split(game: Object, slot: int, data: Dictionary) -> void:
	var world_id := _world_id_for(game, slot)
	var character_id := _character_id_for(game, slot)
	if _is_host(game):
		_worlds.call("write", world_id, WORLD_SAVE.partition(data),
			{"display_name": _display_name(game)})
	_characters.call("write", character_id, CHARACTER_SAVE.partition(data),
		{"display_name": _display_name(game), "last_world_id": world_id})


## Write only this peer's character file. `session.gd::_save_character_here()`
## calls this on a client, which has no slot and no business writing a world.
func save_character(game: Object, character_id: String) -> bool:
	if game == null or character_id.is_empty():
		return false
	var data := snapshot(game)
	var world_id := ""
	var world: Variant = game.get("world")
	if world != null:
		world_id = str((world as RefCounted).get("world_id"))
	return bool(_characters.call("write", character_id, CHARACTER_SAVE.partition(data),
		{"display_name": _display_name(game), "last_world_id": world_id}))


## Write only the world file. Refuses on a client, so a caller cannot get the
## ownership rule wrong by calling the wrong function.
func save_world(game: Object, world_id: String) -> bool:
	if game == null or world_id.is_empty() or not _is_host(game):
		return false
	return bool(_worlds.call("write", world_id, WORLD_SAVE.partition(snapshot(game)),
		{"display_name": _display_name(game)}))


## D100: a v<=22 slot splits on FIRST LOAD into one world and one character, and
## the original file is never modified and never deleted.
##
## Nothing in this function opens the slot file at all -- it is handed the
## dictionary `load_slot()` already read and migrated in memory, so "the
## original is untouched" is a property of the code shape and not of a promise.
## `tests/test_legacy_slot_split_never_touches_the_original.gd` asserts the
## bytes and the modification time are identical either side of a load.
##
## Both halves record `migrated_from: slot_<n>`, and neither is rewritten on a
## second load: the split is a migration, and re-running it over a slot the
## player has since continued from would throw away whatever the world has done
## since.
func _split_legacy_slot(game: Object, slot: int, data: Dictionary) -> void:
	var world_id := "legacy-slot-%d" % slot
	var character_id := "legacy-slot-%d" % slot
	var origin := "slot_%d" % slot
	var wrote_world := false
	if not bool(_worlds.call("has", world_id)):
		wrote_world = bool(_worlds.call("write", world_id, WORLD_SAVE.partition(data),
			{"display_name": _display_name(game), "migrated_from": origin}))
	if not bool(_characters.call("has", character_id)):
		_characters.call("write", character_id, CHARACTER_SAVE.partition(data),
			{"display_name": _display_name(game), "migrated_from": origin,
			 "last_world_id": world_id})
	if wrote_world:
		print("[save] split %s into worlds/%s and characters/%s (original untouched)" % [
			origin, world_id, character_id,
		])
	# Adopt the migrated ids onto the live state, so the next `save()` to this
	# slot continues writing the world it just migrated rather than minting a
	# second one beside it (`_world_id_for`).
	_adopt_id(game.get("world"), "world_id", world_id)
	_adopt_id(game.get("local"), "character_id", character_id)


func _adopt_id(holder: Variant, field: String, id: String) -> void:
	if holder == null:
		return
	if str((holder as RefCounted).get(field)).is_empty():
		(holder as RefCounted).set(field, id)


## Which world file a slot write goes to.
##
## The slot owns the id. A live id is honoured only when it is already this
## slot's -- either the id this saver mints for it or the one the legacy split
## migrated it to -- so New Game, then Save to slot 2, writes slot 2's world
## rather than overwriting the world that was loaded from slot 1 before it.
func _world_id_for(game: Object, slot: int) -> String:
	var id := "slot-%d" % slot
	var world: Variant = game.get("world") if game != null else null
	if world != null:
		var live := str((world as RefCounted).get("world_id"))
		if live == id or live == "legacy-slot-%d" % slot:
			return live
		(world as RefCounted).set("world_id", id)
	return id


func _character_id_for(game: Object, slot: int) -> String:
	var id := "slot-%d" % slot
	var local: Variant = game.get("local") if game != null else null
	if local != null:
		var live := str((local as RefCounted).get("character_id"))
		if live == id or live == "legacy-slot-%d" % slot:
			return live
		(local as RefCounted).set("character_id", id)
	return id


## "May this process write the world?" -- `game_state.gd::is_host()`, which is
## true solo, true for a host, and true for a process with no session at all
## (a headless test, a capture tool, the `FakeGame` in `test_save_format.gd`).
func _is_host(game: Object) -> bool:
	if game == null:
		return false
	if not game.has_method("is_host"):
		return true
	return bool(game.call("is_host"))


func _display_name(game: Object) -> String:
	var local: Variant = game.get("local") if game != null else null
	if local == null:
		return ""
	return str((local as RefCounted).get("display_name"))


## A completed Meadows save may predate the Warden's realm rewards, including
## one already upgraded to v17 by the first Cloudreach build. Restore only the
## earned entitlements: placement, gate unlock and power selection remain the
## player's choices. set_flag is idempotent and never pays inventory rewards.
func _reconcile_meadows_realm_rewards(progression: RefCounted) -> void:
	if not bool(progression.call("has", "defeated_warden")):
		return
	progression.call("set_flag", "realm_key_cloudreach")
	progression.call("set_flag", "realm_heart_meadows_earned")


## RG7. A corrupt JSON pose must fall back to the authored spawn as one unit.
## Applying a valid position with a NaN/invalid view (or vice versa) creates a
## half-restored player that can be stranded or make the camera unusable.
## The live clock, as a number safe to write. Anything that is not a finite
## number becomes the "no carried clock" sentinel rather than a NaN that would
## come back out of JSON as `null` and restore the world to hour NaN.
func _read_clock(game: Object) -> float:
	return _finite_clock(game.get("clock_elapsed_seconds"))


func _finite_clock(raw: Variant) -> float:
	if not _finite_number(raw):
		return -1.0
	var seconds := float(raw)
	return seconds if seconds >= 0.0 else -1.0


func _sanitise_player_pose(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var pose := raw as Dictionary
	var position_raw: Variant = pose.get("position", [])
	if typeof(position_raw) != TYPE_ARRAY or (position_raw as Array).size() < 3:
		return {}
	for i in 3:
		if not _finite_number((position_raw as Array)[i]):
			return {}
	for key: String in ["model_yaw", "camera_yaw", "camera_pitch"]:
		if not _finite_number(pose.get(key)):
			return {}
	var clean := {
		"realm": str(pose.get("realm", "meadows")),
		"position": [float(position_raw[0]), float(position_raw[1]), float(position_raw[2])],
		"model_yaw": float(pose["model_yaw"]),
		"camera_yaw": float(pose["camera_yaw"]),
		"camera_pitch": float(pose["camera_pitch"]),
	}
	if pose.has("traversal"):
		var traversal := _sanitise_traversal(pose["traversal"])
		if traversal.is_empty() or str(traversal["realm"]) != str(clean["realm"]):
			return {} # invalid airborne state falls back as a unit to realm spawn
		clean["traversal"] = traversal
		if str(traversal["mode"]) in ["glide", "climb", "descent", "exhausted"]:
			var anchor: Array = traversal["safe_anchor"]
			if anchor.size() != 3:
				return {}
			clean["position"] = [anchor[0], float(anchor[1]) + 0.08, anchor[2]]
	return clean


## v18 stores stamina/active identity and a safe flight landing. Resuming a
## suspended flight above unstreamed terrain is deliberately disallowed; the
## saved grounded anchor is used for both same-scene and fresh-world loads.
func _capture_traversal_pose(game: Object) -> Dictionary:
	var raw: Variant = game.get("saved_player_pose")
	if not raw is Dictionary:
		return {}
	var pose := (raw as Dictionary).duplicate(true)
	if game.has_method("_find_player"):
		var player: Node = game.call("_find_player")
		var fly: Node = player.get_node_or_null(^"FlyController") if player != null else null
		if fly != null:
			pose["traversal"] = fly.call("save_data")
	return _sanitise_player_pose(pose)


func _sanitise_traversal(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var data: Dictionary = raw
	if int(data.get("version", 0)) != 1 or not _finite_number(data.get("stamina_fraction")):
		return {}
	var mode := str(data.get("mode", "grounded"))
	if not mode in ["grounded", "glide", "climb", "descent", "exhausted", "recovery"]:
		return {}
	var anchor: Variant = data.get("safe_anchor", [])
	var velocity: Variant = data.get("velocity", [])
	if not anchor is Array or not velocity is Array or (velocity as Array).size() != 3:
		return {}
	if (anchor as Array).size() != 0 and (anchor as Array).size() != 3:
		return {}
	for number: Variant in (anchor as Array) + (velocity as Array):
		if not _finite_number(number):
			return {}
	return {"version": 1, "mode": mode, "realm": str(data.get("realm", "meadows")), "safe_anchor": anchor, "velocity": velocity, "stamina_fraction": clampf(float(data["stamina_fraction"]), 0.0, 1.0), "active_index": clampi(int(data.get("active_index", -1)), -1, 4)}


func _migrate_v17(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 18
	# Old saves have no deployed Fly state. Their existing exact pose is valid.
	return migrated


func _migrate_v18(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 19
	migrated["realm_maps"] = _realm_map_payloads(data)
	return migrated


func _migrate_v19(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 20
	for key: String in ["placed_buildings", "death_satchels"]:
		migrated[key] = WORLD_RECORDS.normalized(data.get(key, []))
	return migrated


## Pre-ownership saves used Meadows' grid regardless of selected scene. Only
## an explicit Cloudreach realm tag identifies that newer grid safely. Never
## reinterpret the bytes using current_realm, which would lose Meadows fog.
func _realm_map_payloads(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var raw: Variant = data.get("realm_maps", {})
	if raw is Dictionary:
		for realm_id: String in ["meadows", "cloudreach"]:
			if raw.get(realm_id) is Dictionary:
				result[realm_id] = raw[realm_id].duplicate(true)
	var legacy: Variant = data.get("map", {})
	if legacy is Dictionary:
		var owner := "cloudreach" if str(legacy.get("realm_id", "")) == "cloudreach" else "meadows"
		if not result.has(owner):
			result[owner] = legacy.duplicate(true)
	for realm_id: String in ["meadows", "cloudreach"]:
		if not result.has(realm_id):
			result[realm_id] = {}
	return result


func _finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


## Run `data` through every migration step from its own version up to this
## build's, or return {} if it cannot get there.
##
## This replaced a hand-written `if version == 1: ... elif version == 2: ...`
## ladder that listed, per starting version, every step from there to the top.
## The ladder was O(versions squared) lines to maintain and it had already
## rotted: it carried branches for versions 1 through 5 and none for 6 or 7,
## so a VERSION 6 or VERSION 7 save — anything written between the hotbar
## change and the elixir one — fell through to the final `elif version !=
## VERSION` and was REFUSED with "not loading", despite `_migrate_v6` and
## `_migrate_v7` both existing, being complete, and being called from the five
## older branches. The bug was invisible from either end: the migrations
## looked written and the ladder looked exhaustive. A loop cannot have that
## shape of hole, which is the whole reason for the rewrite.
##
## Each step is still responsible for stamping its own target version by hand
## (see `_migrate_v3`'s comment on why none of them may write `VERSION`), and
## this checks that it did: a step that forgets refuses the load rather than
## spinning forever on the same number.
func _migrate_to_current(data: Dictionary, version: int, slot: int) -> Dictionary:
	var migrated := data
	while version < VERSION:
		var step := "_migrate_v%d" % version
		if not has_method(step):
			push_warning("save slot %d is version %d and this build has no %s -- not loading" % [
				slot, version, step
			])
			return {}
		migrated = call(step, migrated) as Dictionary
		var advanced := int(migrated.get("version", 0))
		if advanced <= version:
			push_warning("%s left save slot %d at version %d -- not loading" % [
				step, slot, version
			])
			return {}
		version = advanced
	return migrated


## VERSION 1 -> VERSION 2. See the class header for what each field becomes.
## `data` is trusted no further than any other save file — every read below
## has the same "wrong type, missing key -> a safe default" tolerance
## `_array_to_party`/`_array_to_inventory` already apply to VERSION 2 data.
## Lands on VERSION 2's own shape, not the build's current `VERSION` — the
## caller chains straight into `_migrate_v2` after this, same as a real
## VERSION 2 file would.
func _migrate_v1(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 2

	var progression := _read_json_file(PROGRESSION_CONFIG_PATH)
	var migration_cfg: Variant = progression.get("migration", {})
	var default_level := int((migration_cfg as Dictionary).get("v1_creature_level", 3)) \
		if typeof(migration_cfg) == TYPE_DICTIONARY else 3

	var species_raw: Variant = _read_json_file(SPECIES_PATH).get("species", {})
	var species_table: Dictionary = species_raw as Dictionary if typeof(species_raw) == TYPE_DICTIONARY else {}

	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var creature := raw as Dictionary
		creature["level"] = default_level
		creature["xp"] = 0
		creature["bond"] = 0
		var moves := _species_moves(species_table, str(creature.get("species_id", "")))
		creature["move_quick"] = str(moves.get("quick", ""))
		creature["move_charged"] = str(moves.get("charged", ""))
	migrated["party"] = party

	var buildings: Array = migrated.get("placed_buildings", [])
	for raw: Variant in buildings:
		if typeof(raw) == TYPE_DICTIONARY:
			(raw as Dictionary)["yaw_deg"] = 0.0
	migrated["placed_buildings"] = buildings

	migrated["satiety"] = _default_satiety()
	migrated["map"] = {}
	return migrated


## VERSION 2 -> VERSION 3. SB9's progression flags did not exist in VERSION 2,
## so there is nothing to recover — a save from before this system existed
## starts with every flag unset, the same "nothing to migrate FROM" answer
## VERSION 1 -> 2 already gave the map (no fog trail predates the map either).
## Lands on VERSION 3's own shape, not the build's current `VERSION` — every
## caller chains straight into `_migrate_v3` after this, same as a real
## VERSION 3 file would.
func _migrate_v2(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 3
	migrated["progression"] = {}
	return migrated


## VERSION 3 -> VERSION 4. `death_satchels` (R3.2) did not exist in VERSION 3
## either — same "nothing to migrate FROM" answer as `_migrate_v2` above.
## Lands on VERSION 4's own shape via a literal, not `VERSION` — R4.2's own
## VERSION 5 bump is the reason why: this used to read `migrated["version"] =
## VERSION`, which was harmless only by coincidence while VERSION 4 was the
## newest version this file knew about, and would have silently skipped
## `_migrate_v4` below the moment VERSION became 5. Every migration step now
## names its own target version literally, matching `_migrate_v1`/
## `_migrate_v2` above, so the chain stays correct however many more versions
## get added after this one.
func _migrate_v3(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 4
	migrated["death_satchels"] = []
	return migrated


## VERSION 4 -> VERSION 5. `iv_hp`/`iv_attack`/`iv_defence`/`trait_primary`/
## `trait_secondary` (R4.2) did not exist in VERSION 4 either — same
## "nothing to migrate FROM" answer as every migration above. Every party
## member gets 0.5 on each IV (perfectly average, `PROGRESSION.
## individuality_multiplier`'s own no-op value, and the same default
## `creature_instance.gd`'s fields already carry) and "" on both traits —
## a creature caught before this system existed is unremarkable and
## untraited, not retroactively rolled.
func _migrate_v4(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 5
	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var creature := raw as Dictionary
		creature["iv_hp"] = 0.5
		creature["iv_attack"] = 0.5
		creature["iv_defence"] = 0.5
		creature["trait_primary"] = ""
		creature["trait_secondary"] = ""
	migrated["party"] = party
	return migrated


## VERSION 5 -> VERSION 6. `shiny` (OF27) did not exist in VERSION 5 either —
## same "nothing to migrate FROM" answer as every migration above. Every
## party member gets `false`: a creature caught before the roll existed was
## never entered into it, not retroactively granted the rare outcome. Lands
## on VERSION 6's own shape via a literal, not `VERSION`, matching
## `_migrate_v3`'s own comment on why every step names its target version by
## hand rather than trusting the build's current constant.
func _migrate_v5(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 6
	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		(raw as Dictionary)["shiny"] = false
	migrated["party"] = party
	return migrated


## VERSION 6 -> 7: the hotbar became its own assignable bar of item ids.
##
## Before this the HUD mirrored satchel slots 0-4, so a v6 save recorded no
## hotbar at all -- the bar was whatever bag order happened to be. An empty
## array is the honest migration: `game_state.gd::autofill_hotbar()` then
## rebuilds it from what the player is actually carrying, in bag order, which
## is the same thing the mirror used to show minus the wood and stone that
## used to clog the action slots.
func _migrate_v6(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 7
	migrated["hotbar"] = []
	return migrated


## VERSION 7 -> 8: elixir points. Nothing to write; see the header.
func _migrate_v7(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 8
	return migrated


## VERSION 8 -> 9: R7.6's farm beds. An empty list — the same "nothing to
## migrate FROM" answer every step above gives, and the right one here: a save
## written before the farm existed recorded no crop because there was no
## ground to sow. `game_state.gd::farm_plot_at()` reads a short or missing
## list as fallow, so the player loads in to an untilled farm and starts it
## the way a new game would.
func _migrate_v8(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 9
	migrated["farm_plots"] = []
	return migrated


## VERSION 9 -> 10: HARVEST-ALL/D60's permanently-chopped vegetation. An
## empty dictionary — the same "nothing to migrate FROM" answer every step
## above gives: a save written before this shipped recorded no chopped
## placements because nothing was permanently removable yet, so the meadow
## and quarry come back exactly as dense as they were the day that save was
## written.
func _migrate_v9(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 10
	migrated["harvested_vegetation"] = {}
	return migrated


## VERSION 10 -> 11: RG9's felled-but-ungathered piles. An empty dictionary —
## a VERSION 10 save predates chop-then-gather entirely, so every chop it
## remembers already paid out immediately; there is no pile left owed.
func _migrate_v10(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 11
	migrated["felled_vegetation"] = {}
	return migrated


## VERSION 11 -> 12: exact player pose and creature-bed resting state. A v11
## slot has neither; no pose means use the scene's authored spawn, and every
## creature starts available rather than being stranded in a bed that was not
## persisted by that format.
func _migrate_v11(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 12
	migrated["player_pose"] = {}
	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) == TYPE_DICTIONARY:
			(raw as Dictionary)["resting"] = false
			(raw as Dictionary)["rested"] = false
			(raw as Dictionary)["rest_bed_index"] = -1
	migrated["party"] = party
	return migrated


## VERSION 12 -> 13: RG19-spec/D68's creature condition. A v12 creature has
## no nourishment, happiness or rest clock, so it takes the configured
## STARTING values rather than zero -- a creature caught before the model
## existed was never starving, it was simply never measured. `rested` is
## already carried by v12 and is left exactly as the save wrote it, but the
## expiry clock starts empty, so a creature loaded as rested keeps that until
## the next faint rather than for a phantom 45 minutes.
## VERSION 13 -> VERSION 14. FIVE-CREATURE-PRESSURE's three history counters.
##
## The "nothing to migrate FROM" answer every migration above gives, and here it
## is the honest one twice over: a pre-14 save was not counting battles, levels
## or catch day, so zero is not a placeholder for a number that existed -- it is
## the true statement that the history was never kept. `tab_creatures.gd`'s
## ceremony reads that and says nothing rather than claiming "0 battles" about a
## creature that may have fought a hundred.
##
## This function exists even though it writes only the defaults, because
## `_migrate_to_current()` walks one step per version and REFUSES to load a save
## when a step is missing:
##
##     if not has_method(step):
##         push_warning("... this build has no %s -- not loading")
##         return {}
##
## Bumping VERSION without adding the step therefore does not skip a no-op
## migration; it breaks loading for EVERY existing save, back to version 1,
## because the chain cannot get past 13. That is exactly what happened when the
## history counters landed, and `test_save_format.gd` caught it.
## VERSION 15 — the world seed (T3-ENCOUNTER)
##
## `game_state.gd::world_seed` did not exist before this. The same "nothing to
## migrate FROM" answer every step above gives its own new field, and here it is
## also the *right* answer rather than merely the safe one: 0 is the AUTHORED
## world, the one where `encounter_director.gd` never enters the roller and every
## cluster stands up the species `spawns.json` names. So a save written before
## rolled populations existed comes back into exactly the world it was saved
## from -- not an approximation of it, and with no population snapshot to
## reconstruct, because the population is derived from this integer rather than
## stored.
func _migrate_v14(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 15
	migrated["world_seed"] = 0
	return migrated


func _migrate_v13(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 14
	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var creature := raw as Dictionary
		creature["battles_fought"] = 0
		creature["levels_gained_with_you"] = 0
		creature["caught_on_day"] = 0
	migrated["party"] = party
	return migrated


## VERSION 15 -> 16: OWNER-0901-BOND-MILESTONES. See the class header for why
## every one of these is an honest zero rather than a placeholder.
func _migrate_v15(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 16
	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var creature := raw as Dictionary
		creature["landmarks_visited_together"] = 0
		creature["distance_m_together"] = 0.0
		creature["rest_nights_together"] = 0
		creature["feeds_together"] = 0
	migrated["party"] = party
	return migrated


## VERSION 16 -> 17: every pre-Cloudreach save was written in the Meadows and
## predates an active Realm Heart selection.
func _migrate_v16(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 17
	migrated["current_realm"] = "meadows"
	migrated["realm_hearts"] = {}
	var pose: Variant = migrated.get("player_pose", {})
	if pose is Dictionary and not (pose as Dictionary).is_empty():
		(pose as Dictionary)["realm"] = "meadows"
		migrated["player_pose"] = pose
	return migrated


## VERSION 20 -> 21: CL-W1's alpha pin set. See the class header.
func _migrate_v20(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 21
	migrated["alpha_pins"] = []
	return migrated


## VERSION 18 -> 19: N14's persisted day/night clock. A save written before it
## has no memory of the hour, and the honest migration is to say so rather than
## invent one -- the sentinel opens that save at the authored morning, which is
## exactly what it did on the old build.
## VERSION 21 -> 22: the carried day clock. See the class header.
func _migrate_v21(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 22
	migrated["clock_elapsed_seconds"] = -1.0
	return migrated


func _migrate_v12(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = 13
	var party: Array = migrated.get("party", [])
	for raw: Variant in party:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var creature := raw as Dictionary
		creature["nourishment"] = _condition_defaults().get("nourishment", 70.0)
		creature["happiness"] = _condition_defaults().get("happiness", 55.0)
		creature["rested_seconds_left"] = 0.0
	migrated["party"] = party
	return migrated


## creature_condition.json's starting values, read once. The migration and the
## missing-key defaults above both want them, and neither should carry its own
## copy of a number the config owns.
static func _condition_defaults() -> Dictionary:
	var cfg: Dictionary = CREATURE_CONDITION.config()
	return {
		"nourishment": float(cfg.get("nourishment", {}).get("start", 70.0)),
		"happiness": float(cfg.get("happiness", {}).get("start", 55.0)),
	}


func _species_moves(species_table: Dictionary, species_id: String) -> Dictionary:
	var entry_raw: Variant = species_table.get(species_id, {})
	var entry: Dictionary = entry_raw as Dictionary if typeof(entry_raw) == TYPE_DICTIONARY else {}
	var moves_raw: Variant = entry.get("moves", {})
	return moves_raw as Dictionary if typeof(moves_raw) == TYPE_DICTIONARY else {}


func _read(slot: int) -> Dictionary:
	if slot < 0 or slot >= SLOT_COUNT:
		return {}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


## `data/config/vitals.json`'s `satiety.max`, fallback 100 — "full" for a
## VERSION 1 migration, and the last-resort default for a VERSION 2 file
## that is somehow missing its own `satiety` key.
func _default_satiety() -> float:
	var satiety_cfg: Variant = _read_json_file(VITALS_CONFIG_PATH).get("satiety", {})
	return float((satiety_cfg as Dictionary).get("max", 100.0)) if typeof(satiety_cfg) == TYPE_DICTIONARY else 100.0


## The live `PlayerVitals`, if `game` can reach one — see the class header's
## "satiety seam" section.
func _live_vitals(game: Object) -> RefCounted:
	if not game.has_method("player_vitals"):
		return null
	var vitals: Variant = game.call("player_vitals")
	return vitals as RefCounted if vitals is RefCounted else null


func _read_satiety(game: Object) -> float:
	var vitals := _live_vitals(game)
	if vitals != null:
		return float(vitals.get("satiety"))
	var fallback: Variant = game.get("satiety")
	return float(fallback) if fallback != null else _default_satiety()


func _write_satiety(game: Object, value: float) -> void:
	var vitals := _live_vitals(game)
	if vitals != null:
		var max_satiety: float = float(vitals.get("max_satiety"))
		vitals.set("satiety", clampf(value, 0.0, max_satiety) if max_satiety > 0.0 else value)
	else:
		game.set("satiety", value)


func _party_to_array(party: Variant) -> Array:
	var out: Array = []
	if party == null:
		return out
	for creature: Variant in ((party as RefCounted).call("members") as Array):
		var instance := creature as RefCounted
		out.append({
			"species_id": str(instance.get("species_id")),
			"display_name": str(instance.get("display_name")),
			"creature_type": str(instance.get("creature_type")),
			# T3-CREATURES. "" for every mono-typed creature, which is every one
			# that existed before the creature-expansion brief -- so this key is
			# additive and a save written before it round-trips unchanged.
			"secondary_type": str(instance.get("secondary_type")),
			"nickname": str(instance.get("nickname")),
			# GAME-F4. Species-owned but stored on the instance (see
			# creature_instance.gd's own comment on `base_hp`) because a level-up
			# recomputes `max_hp`/`attack`/`defence` from THESE, never from
			# themselves -- so if these are missing on load, the very next
			# level-up (or elixir, or evolve) throws away the creature's real
			# stats and rebuilds it from the class default of 1.0. Independently
			# reproduced by GATE-F-LEG-S09 (a save/load/level-up sequence turned a
			# healthy level-18 party member's max_hp in the 200s into 2 on its
			# next level), GATE-F-LEG-S07 (a hand-seeded level 9-13 party loaded
			# correctly, then the segment's first trainer win silently gutted
			# every stat the same way), and GATE-F-LEG-S10CDE (a level 3 ripplet
			# went from 117.60 max hp to 1.18 on its next level-up).
			"base_hp": float(instance.get("base_hp")),
			"base_attack": float(instance.get("base_attack")),
			"base_defence": float(instance.get("base_defence")),
			"max_hp": float(instance.get("max_hp")),
			"attack": float(instance.get("attack")),
			"defence": float(instance.get("defence")),
			"hp": float(instance.get("hp")),
			"energy": float(instance.get("energy")),
			"fainted": bool(instance.get("fainted")),
			"resting": bool(instance.get("resting")),
			"rested": bool(instance.get("rested")),
			"rest_bed_index": int(instance.get("rest_bed_index")),
			"level": int(instance.get("level")),
			"xp": int(instance.get("xp")),
			"bond": int(instance.get("bond")),
			"battles_fought": int(instance.get("battles_fought")),
			"caught_on_day": int(instance.get("caught_on_day")),
			"levels_gained_with_you": int(instance.get("levels_gained_with_you")),
			"landmarks_visited_together": int(instance.get("landmarks_visited_together")),
			"distance_m_together": float(instance.get("distance_m_together")),
			"rest_nights_together": int(instance.get("rest_nights_together")),
			"feeds_together": int(instance.get("feeds_together")),
			"move_quick": str(instance.get("move_quick")),
			"move_charged": str(instance.get("move_charged")),
			"iv_hp": float(instance.get("iv_hp")),
			"iv_attack": float(instance.get("iv_attack")),
			"iv_defence": float(instance.get("iv_defence")),
			"trait_primary": str(instance.get("trait_primary")),
			"trait_secondary": str(instance.get("trait_secondary")),
			"shiny": bool(instance.get("shiny")),
			"boost_hp": int(instance.get("boost_hp")),
			"boost_attack": int(instance.get("boost_attack")),
			"boost_defence": int(instance.get("boost_defence")),
			"nourishment": float(instance.get("nourishment")),
			"happiness": float(instance.get("happiness")),
			"rested_seconds_left": float(instance.get("rested_seconds_left")),
		})
	return out


## Fields are set directly rather than going through `CreatureInstance.from_species`
## so a load never depends on `species.json` still defining the species —
## an instance's saved stats are trusted as-is, the same "carry on with what
## the file says" spirit as the rest of this class.
func _array_to_party(entries: Variant, party: Variant) -> void:
	if party == null or typeof(entries) != TYPE_ARRAY:
		return
	var party_ref := party as RefCounted
	party_ref.call("clear")
	# Read ONCE, outside the loop, for the baseline repair below. Read through
	# this file's own `_read_json_file` rather than through
	# `creature_species.gd` for the reason this file's header gives: it never
	# reaches into the scene tree or the autoloads, so a headless test double
	# round-trips exactly as a running game does.
	var species_raw: Variant = _read_json_file(SPECIES_PATH).get("species", {})
	var species_table: Dictionary = species_raw as Dictionary \
		if typeof(species_raw) == TYPE_DICTIONARY else {}
	var progression_cfg := _read_json_file(PROGRESSION_CONFIG_PATH)
	for raw: Variant in (entries as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var d := raw as Dictionary
		var creature: RefCounted = CREATURE_INSTANCE.new()
		creature.species_id = str(d.get("species_id", ""))
		creature.display_name = str(d.get("display_name", creature.species_id))
		creature.creature_type = str(d.get("creature_type", "ground"))
		# T3-CREATURES. Absent in a save written before dual typing existed,
		# and "" is the honest answer there: that creature was mono-typed when
		# it was stored. If its species has since gained a second type,
		# `apply_species_definition` repairs it from species.json the same way
		# every other species-owned field on this class is repaired.
		creature.secondary_type = str(d.get("secondary_type", ""))
		creature.nickname = str(d.get("nickname", ""))
		# Defaulted to 0, which is what a pre-VERSION-14 save honestly means:
		# the history was not being kept, so the ceremony says nothing about it
		# rather than inventing a number. No migration pass needed.
		creature.battles_fought = int(d.get("battles_fought", 0))
		creature.caught_on_day = int(d.get("caught_on_day", 0))
		creature.levels_gained_with_you = int(d.get("levels_gained_with_you", 0))
		creature.landmarks_visited_together = int(d.get("landmarks_visited_together", 0))
		creature.distance_m_together = float(d.get("distance_m_together", 0.0))
		creature.rest_nights_together = int(d.get("rest_nights_together", 0))
		creature.feeds_together = int(d.get("feeds_together", 0))
		creature.max_hp = float(d.get("max_hp", 1.0))
		creature.attack = float(d.get("attack", 1.0))
		creature.defence = float(d.get("defence", 1.0))
		creature.hp = float(d.get("hp", creature.max_hp))
		creature.energy = float(d.get("energy", 0.0))
		creature.fainted = bool(d.get("fainted", false))
		creature.resting = bool(d.get("resting", false))
		creature.rested = bool(d.get("rested", false))
		creature.rest_bed_index = int(d.get("rest_bed_index", -1))
		creature.level = int(d.get("level", 1))
		creature.xp = int(d.get("xp", 0))
		creature.bond = int(d.get("bond", 0))
		creature.move_quick = str(d.get("move_quick", ""))
		creature.move_charged = str(d.get("move_charged", ""))
		# Elixir points (D47). Absent on any save older than VERSION 8, and 0
		# is exactly right for one: a creature from before elixirs existed
		# never drank any.
		creature.boost_hp = int(d.get("boost_hp", 0))
		creature.boost_attack = int(d.get("boost_attack", 0))
		creature.boost_defence = int(d.get("boost_defence", 0))
		creature.iv_hp = float(d.get("iv_hp", 0.5))
		creature.iv_attack = float(d.get("iv_attack", 0.5))
		creature.iv_defence = float(d.get("iv_defence", 0.5))
		creature.trait_primary = str(d.get("trait_primary", ""))
		creature.trait_secondary = str(d.get("trait_secondary", ""))
		creature.shiny = bool(d.get("shiny", false))
		# RG19-spec/D68. Absent on any save older than VERSION 13; the
		# defaults are creature_condition.json's own starting values, which is
		# what a creature that predates the model honestly has.
		creature.nourishment = float(d.get("nourishment", _condition_defaults().get("nourishment", 70.0)))
		creature.happiness = float(d.get("happiness", _condition_defaults().get("happiness", 55.0)))
		creature.rested_seconds_left = float(d.get("rested_seconds_left", 0.0))
		# GAME-F4. Trusted from the save like every other field on this class;
		# only a save that predates this fix has nothing here, and for that one
		# case only, `species.json` supplies the value the save itself is
		# missing -- see the GAME-F4 section in this file's header comment and
		# `creature_instance.gd::recompute_stats_from_base()` for why this is
		# never unconditionally re-derived from the catalogue.
		var definition_raw: Variant = species_table.get(creature.species_id, {})
		var definition: Dictionary = definition_raw as Dictionary \
			if typeof(definition_raw) == TYPE_DICTIONARY else {}
		creature.base_hp = float(d.get("base_hp", definition.get("base_hp", 100.0)))
		creature.base_attack = float(d.get("base_attack", definition.get("base_attack", 20.0)))
		creature.base_defence = float(d.get("base_defence", definition.get("base_defence", 20.0)))
		creature.call("recompute_stats_from_base", progression_cfg)
		party_ref.call("add", creature)


func _inventory_to_array(inventory: Variant) -> Array:
	var out: Array = []
	if inventory == null:
		return out
	var inventory_ref := inventory as RefCounted
	var count: int = int(inventory_ref.call("slot_count"))
	for i in count:
		var stack: Dictionary = inventory_ref.call("stack_at", i)
		out.append(null if stack.is_empty() else stack)
	return out


func _array_to_inventory(entries: Variant, inventory: Variant) -> void:
	if inventory == null or typeof(entries) != TYPE_ARRAY:
		return
	var inventory_ref := inventory as RefCounted
	var array := entries as Array
	var count: int = int(inventory_ref.call("slot_count"))
	for i in count:
		var stack: Variant = array[i] if i < array.size() else null
		inventory_ref.call("set_slot", i, _stack_from_json(stack))


## The five action slots, as item ids (see `game_state.gd::hotbar`).
##
## Rebuilt defensively rather than assigned wholesale: a slot naming an item
## this build no longer defines is dropped, and a short or over-long array is
## padded/truncated to the real slot count. Same "trust nothing you cannot look
## up" rule `_array_to_party` already follows for species ids.
##
## Anything still empty afterwards is filled from what the player is actually
## carrying. That covers both a migrated v6 save (which has no bar at all) and
## a save whose bound item no longer exists, and it is why a loaded game never
## comes back with a blank bar the player has to rebuild by hand.
func _array_to_hotbar(entries: Variant, game: Object) -> void:
	# Duck-typed like every other accessor in this file: a headless test double
	# that never grew a hotbar simply has nothing to restore, and must not take
	# the whole load down with it.
	if game == null or typeof(game.get("hotbar")) != TYPE_ARRAY:
		return
	var slots: int = (game.get("hotbar") as Array).size()
	var array: Array = entries as Array if typeof(entries) == TYPE_ARRAY else []
	var can_hold := game.has_method("hotbar_can_hold")
	var rebuilt: Array[String] = []
	for i in slots:
		var id := str(array[i]) if i < array.size() else ""
		rebuilt.append(id if (not can_hold or bool(game.call("hotbar_can_hold", id))) else "")
	game.set("hotbar", rebuilt)
	if game.has_method("autofill_hotbar"):
		game.call("autofill_hotbar")


## The five bindings, or an empty list for an object that has no bar.
func _hotbar_to_array(game: Object) -> Array:
	if game == null or typeof(game.get("hotbar")) != TYPE_ARRAY:
		return []
	return (game.get("hotbar") as Array).duplicate()


## JSON has no integer type — every number round-trips as a float
## (`JSON.parse_string`), so a stack read back from a save would otherwise
## carry `"n": 12.0` instead of `12`. `id`/`n` are Inventory's own stack
## contract (see `autoload/inventory.gd`); `durability` is optional and only
## present on tools.
func _stack_from_json(stack: Variant) -> Variant:
	if typeof(stack) != TYPE_DICTIONARY:
		return null
	var dict := stack as Dictionary
	var fixed := {"id": str(dict.get("id", "")), "n": int(dict.get("n", 0))}
	if dict.has("durability"):
		fixed["durability"] = int(dict.get("durability"))
	if dict.has("durability_bonus"):
		# SD18: a reinforced tool's raised ceiling (inventory.gd::reinforce_tool)
		# is per-slot state exactly like `durability` above, and needs the same
		# JSON-float round-trip fix or a save/load would silently forget the
		# upgrade ever happened.
		fixed["durability_bonus"] = int(dict.get("durability_bonus"))
	return fixed
