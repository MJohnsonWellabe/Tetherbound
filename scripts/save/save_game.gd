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
const PROGRESSION_CONFIG_PATH := "res://data/config/progression.json"
const VITALS_CONFIG_PATH := "res://data/config/vitals.json"
const SPECIES_PATH := "res://data/creatures/species.json"

const VERSION := 12
const SLOT_COUNT := 5
## Written automatically whenever the player rests (`scripts/build/camp.gd`).
## Slots 1-4 are the player's own manual saves. Nothing enforces the split
## beyond this comment — any slot reads and writes the same way.
const AUTOSAVE_SLOT := 0

var _dir: String


func _init(dir: String = "user://saves/") -> void:
	_dir = dir if dir.ends_with("/") else dir + "/"


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
	return {
		"day": int(data.get("day", 1)),
		"party_size": (data.get("party", []) as Array).size(),
	}


## Serialize `game` into `slot`. Returns whether the write succeeded.
func save(game: Object, slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	DirAccess.make_dir_recursive_absolute(_dir)

	var map_obj: Variant = game.get("map")
	var progression_obj: Variant = game.get("progression")
	var data := {
		"version": VERSION,
		"day": int(game.get("day")),
		"party": _party_to_array(game.get("party")),
		"inventory": _inventory_to_array(game.get("inventory")),
		"hotbar": _hotbar_to_array(game),
		"placed_buildings": (game.get("placed_buildings") as Array).duplicate(true),
		"farm_plots": (game.get("farm_plots") as Array).duplicate(true),
		"death_satchels": (game.get("death_satchels") as Array).duplicate(true),
		"satiety": _read_satiety(game),
		"map": (map_obj as RefCounted).call("save_data") if map_obj != null else {},
		"progression": (progression_obj as RefCounted).call("save_data") if progression_obj != null else {},
		"harvested_vegetation": (game.get("harvested_vegetation") as Dictionary).duplicate(true),
		"felled_vegetation": (game.get("felled_vegetation") as Dictionary).duplicate(true),
		"player_pose": _sanitise_player_pose(game.get("saved_player_pose")),
	}

	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


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

	game.set("day", int(data.get("day", 1)))
	_array_to_party(data.get("party", []), game.get("party"))
	_array_to_inventory(data.get("inventory", []), game.get("inventory"))
	_array_to_hotbar(data.get("hotbar", []), game)
	game.set("placed_buildings", (data.get("placed_buildings", []) as Array).duplicate(true))
	game.set("farm_plots", (data.get("farm_plots", []) as Array).duplicate(true))
	game.set("death_satchels", (data.get("death_satchels", []) as Array).duplicate(true))
	var harvested_raw: Variant = data.get("harvested_vegetation", {})
	game.set("harvested_vegetation", (harvested_raw as Dictionary).duplicate(true) if typeof(harvested_raw) == TYPE_DICTIONARY else {})
	var felled_raw: Variant = data.get("felled_vegetation", {})
	game.set("felled_vegetation", (felled_raw as Dictionary).duplicate(true) if typeof(felled_raw) == TYPE_DICTIONARY else {})
	if game.get("saved_player_pose") != null:
		var pose_raw: Variant = data.get("player_pose", {})
		game.set("saved_player_pose", _sanitise_player_pose(pose_raw))
	_write_satiety(game, float(data.get("satiety", _default_satiety())))

	var map_obj: Variant = game.get("map")
	if map_obj != null:
		var map_data: Variant = data.get("map", {})
		(map_obj as RefCounted).call("load_data", map_data if typeof(map_data) == TYPE_DICTIONARY else {})

	var progression_obj: Variant = game.get("progression")
	if progression_obj != null:
		var progression_data: Variant = data.get("progression", {})
		(progression_obj as RefCounted).call("load_data", progression_data if typeof(progression_data) == TYPE_DICTIONARY else {})
	return true


## RG7. A corrupt JSON pose must fall back to the authored spawn as one unit.
## Applying a valid position with a NaN/invalid view (or vice versa) creates a
## half-restored player that can be stranded or make the camera unusable.
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
	return {
		"position": [float(position_raw[0]), float(position_raw[1]), float(position_raw[2])],
		"model_yaw": float(pose["model_yaw"]),
		"camera_yaw": float(pose["camera_yaw"]),
		"camera_pitch": float(pose["camera_pitch"]),
	}


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
			"nickname": str(instance.get("nickname")),
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
	for raw: Variant in (entries as Array):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var d := raw as Dictionary
		var creature: RefCounted = CREATURE_INSTANCE.new()
		creature.species_id = str(d.get("species_id", ""))
		creature.display_name = str(d.get("display_name", creature.species_id))
		creature.creature_type = str(d.get("creature_type", "ground"))
		creature.nickname = str(d.get("nickname", ""))
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
