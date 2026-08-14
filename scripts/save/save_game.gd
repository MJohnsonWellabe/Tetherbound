extends RefCounted

## Versioned save/load for the state that has to survive a quit: the party,
## the satchel, the day counter, placed buildings (R3.1), and — as of
## VERSION 2 — creature progression, satiety and the map database.
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
## the file. A VERSION 1 save on a VERSION 2 build now migrates instead of
## being refused (`_migrate_v1`): every creature is set to
## `data/config/progression.json`'s `migration.v1_creature_level` (fallback 3),
## `xp` 0, `bond` 0, and its quick/charged moves looked up from
## `data/creatures/species.json` by `species_id` (empty string for a species the
## catalogue no longer knows, same "trust nothing you cannot look up" rule
## `_array_to_party` already followed); satiety is set to full
## (`data/config/vitals.json`'s `satiety.max`, fallback 100); the map comes
## back fresh (nothing visited, nothing discovered — there is no fog trail to
## recover from a save that predates the map); and every building gets
## `yaw_deg: 0.0`. A version newer than this build still refuses exactly as
## VERSION 1 refused everything but itself — there is still nothing to
## migrate an unreleased future format DOWN from.
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

const VERSION := 2
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
	var data := {
		"version": VERSION,
		"day": int(game.get("day")),
		"party": _party_to_array(game.get("party")),
		"inventory": _inventory_to_array(game.get("inventory")),
		"placed_buildings": (game.get("placed_buildings") as Array).duplicate(true),
		"satiety": _read_satiety(game),
		"map": (map_obj as RefCounted).call("save_data") if map_obj != null else {},
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
	if version == 1:
		data = _migrate_v1(data)
	elif version != VERSION:
		push_warning("save slot %d is version %d, this build reads %d -- not loading" % [
			slot, version, VERSION
		])
		return false

	game.set("day", int(data.get("day", 1)))
	_array_to_party(data.get("party", []), game.get("party"))
	_array_to_inventory(data.get("inventory", []), game.get("inventory"))
	game.set("placed_buildings", (data.get("placed_buildings", []) as Array).duplicate(true))
	_write_satiety(game, float(data.get("satiety", _default_satiety())))

	var map_obj: Variant = game.get("map")
	if map_obj != null:
		var map_data: Variant = data.get("map", {})
		(map_obj as RefCounted).call("load_data", map_data if typeof(map_data) == TYPE_DICTIONARY else {})
	return true


## VERSION 1 -> VERSION 2. See the class header for what each field becomes.
## `data` is trusted no further than any other save file — every read below
## has the same "wrong type, missing key -> a safe default" tolerance
## `_array_to_party`/`_array_to_inventory` already apply to VERSION 2 data.
func _migrate_v1(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	migrated["version"] = VERSION

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
			"level": int(instance.get("level")),
			"xp": int(instance.get("xp")),
			"bond": int(instance.get("bond")),
			"move_quick": str(instance.get("move_quick")),
			"move_charged": str(instance.get("move_charged")),
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
		creature.level = int(d.get("level", 1))
		creature.xp = int(d.get("xp", 0))
		creature.bond = int(d.get("bond", 0))
		creature.move_quick = str(d.get("move_quick", ""))
		creature.move_charged = str(d.get("move_charged", ""))
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
	return fixed
