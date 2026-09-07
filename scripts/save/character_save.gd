extends RefCounted

## D100, the PORTABLE half: `user://characters/<character_id>/character.json`.
##
## One trainer and one team -- the five creatures, the satchel, the hotbar,
## satiety, where this trainer is standing, their Realm Hearts, their per-realm
## maps (fog, landmarks, markers and alpha pins) and their PLAYER-scope story
## flags. Written by every peer for itself and nobody else: the host writes the
## world file and its own character file; a client writes only its character
## file (`session.gd::_save_character_here()`).
##
## Portable is the point. The file names no world, only the last one it played
## in (`last_world_id`), so the same trainer can walk into a friend's world and
## still be the trainer the owner built. That is directive item 20's second
## half, and until this file existed only the first half was true.
##
## The five-creature rule is untouched by portability: `party.gd` is still the
## only thing that knows about the cap, and this file serialises whatever the
## party holds through `save_game.gd`'s one definition of a saved creature.
## There is no storage here, no reserve, no sixth slot -- a character file is
## exactly one party.
##
## Shape and rules mirror `world_save.gd`: `partition()` takes the v22 save
## dictionary and keeps the character half, key names are
## `PlayerState.save_data()`'s verbatim so `PlayerState.load_data(payload)`
## restores one with no adapter, and nothing here is ever fatal.
##
## Two v22 keys are DERIVED rather than stored, and this is deliberate -- an
## eleventh top-level key is how the world half's coverage test got broken once
## already:
##
##   * `map` is the ACTIVE realm's map, which is `realm_maps[realm]`;
##   * `alpha_pins` is that same map's `alpha_pins`, written at the top level by
##     v22 and already inside `map_state.gd::save_data()`.
##
## `merge()` rebuilds both, so the round trip is lossless without storing either
## twice.

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")

const VERSION := 1

const ENVELOPE_KEYS: Array[String] = [
	"version", "character_id", "display_name", "created_at", "last_played",
	"last_world_id", "migrated_from",
]

## The v22 keys this half owns under their own names.
const STATE_KEYS: Array[String] = [
	"party", "inventory", "hotbar", "satiety", "player_pose", "pending_realm_entry",
	"realm_hearts", "realm_maps", "skills", "satchel_escrow",
]

## v22 keys this half owns but does NOT store, because they are recoverable
## from `realm_maps` and storing them twice is how two copies drift apart.
const DERIVED_KEYS: Array[String] = ["map", "alpha_pins"]

var _dir: String

## id -> the envelope fields a re-save must PRESERVE rather than recompute.
##
## `write()` runs on every autosave, and an autosave already writes the v22 slot
## file; re-parsing this file each time only to read `created_at` back would put
## a third full JSON parse on a path that runs while the player is walking
## around. The first write of a session pays one read; the rest do not.
var _envelope_cache: Dictionary = {}


func _init(dir: String = "user://characters/") -> void:
	_dir = dir if dir.ends_with("/") else dir + "/"


func root_dir() -> String:
	return _dir


func dir_for(character_id: String) -> String:
	return "%s%s/" % [_dir, character_id]


func path_for(character_id: String) -> String:
	return "%scharacter.json" % dir_for(character_id)


func has(character_id: String) -> bool:
	return not character_id.is_empty() and FileAccess.file_exists(path_for(character_id))


func list_ids() -> Array:
	if not DirAccess.dir_exists_absolute(_dir):
		return []
	var out: Array = []
	for name: String in DirAccess.get_directories_at(_dir):
		if has(name):
			out.append(name)
	out.sort()
	return out


# --- the partition ------------------------------------------------------------

## The character half of a v22 save dictionary, in `PlayerState.save_data()`'s
## shape. `character_id` and `display_name` are stamped by `write()`.
static func partition(v22: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in STATE_KEYS:
		if v22.has(key):
			out[key] = WORLD_SAVE.copy_value(v22[key])
	out["realm"] = str(v22.get("current_realm", "meadows"))
	out["flags"] = {"flags": WORLD_SAVE.scope_flags(v22, PROGRESSION_STATE.SCOPE_PLAYER)}
	return out


## The inverse of the two `partition()`s: one v22 dictionary from a world half
## and a character half. `map` and `alpha_pins` are rebuilt here from the active
## realm's map, which is the whole reason they are not stored.
##
## Round-tripping this against `save_game.gd`'s own dictionary is the
## key-coverage test (`tests/test_split_key_coverage_equals_v22.gd`): a key
## either survives both directions or the equality fails.
static func merge(world: Dictionary, character: Dictionary, version: int) -> Dictionary:
	var out: Dictionary = {"version": version}
	for key: String in WORLD_SAVE.STATE_KEYS:
		if world.has(key):
			out[key] = WORLD_SAVE.copy_value(world[key])
	for key: String in STATE_KEYS:
		if character.has(key):
			out[key] = WORLD_SAVE.copy_value(character[key])
	out["current_realm"] = str(character.get("realm", "meadows"))

	var world_ids: Array = _flag_ids(world.get("flags", {}))
	var player_ids: Array = _flag_ids(character.get("flags", {}))
	out["progression"] = {"flags": world_ids + player_ids}

	var realm_maps: Variant = out.get("realm_maps", {})
	var active: Dictionary = {}
	if typeof(realm_maps) == TYPE_DICTIONARY:
		var raw: Variant = (realm_maps as Dictionary).get(out["current_realm"], {})
		if typeof(raw) == TYPE_DICTIONARY:
			active = raw as Dictionary
	out["map"] = active.duplicate(true)
	var pins: Variant = active.get("alpha_pins", [])
	out["alpha_pins"] = (pins as Array).duplicate(true) if typeof(pins) == TYPE_ARRAY else []
	return out


static func _flag_ids(raw: Variant) -> Array:
	if typeof(raw) != TYPE_DICTIONARY:
		return []
	var ids: Variant = (raw as Dictionary).get("flags", [])
	return (ids as Array).duplicate(true) if typeof(ids) == TYPE_ARRAY else []


# --- files --------------------------------------------------------------------

## Write `payload` (a `partition()` result) as `character_id`'s file.
## `envelope` may carry `display_name`, `last_world_id` and `migrated_from`.
func write(character_id: String, payload: Dictionary, envelope: Dictionary = {}) -> bool:
	if character_id.is_empty():
		return false
	var dir := dir_for(character_id)
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		push_warning("character save: could not create %s" % dir)
		return false
	var now := Time.get_datetime_string_from_system(true)
	var existing := _preserved(character_id)
	var data := payload.duplicate(true)
	data["version"] = VERSION
	data["character_id"] = character_id
	data["display_name"] = str(envelope.get("display_name", existing.get("display_name", "")))
	data["created_at"] = str(existing.get("created_at", now))
	data["last_played"] = now
	data["last_world_id"] = str(envelope.get("last_world_id", existing.get("last_world_id", "")))
	data["migrated_from"] = str(envelope.get("migrated_from", existing.get("migrated_from", "")))
	var file := FileAccess.open(path_for(character_id), FileAccess.WRITE)
	if file == null:
		push_warning("character save: could not open %s for writing" % path_for(character_id))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_envelope_cache[character_id] = _envelope_of(data)
	return true


## The envelope fields a later write must carry forward, from the cache when
## this saver has already written this id in-process and from the file
## otherwise. A missing or unreadable file is {} -- "there was nothing to
## preserve", never a refusal.
func _preserved(character_id: String) -> Dictionary:
	if _envelope_cache.has(character_id):
		return _envelope_cache[character_id] as Dictionary
	var existing := read(character_id)
	var preserved := _envelope_of(existing)
	_envelope_cache[character_id] = preserved
	return preserved


func _envelope_of(data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in ["display_name", "created_at", "last_world_id", "migrated_from"]:
		if data.has(key):
			out[key] = str(data[key])
	return out


func read(character_id: String) -> Dictionary:
	if not has(character_id):
		return {}
	var file := FileAccess.open(path_for(character_id), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data := parsed as Dictionary
	var version := int(data.get("version", 0)) if WORLD_SAVE.is_number(data.get("version")) else 0
	if version < 1 or version > VERSION:
		push_warning("character '%s' is version %d, this build reads %d -- not loading" % [
			character_id, version, VERSION,
		])
		return {}
	return data


## The state half of a character file, ready for `PlayerState.load_data()`.
func state(character_id: String) -> Dictionary:
	var data := read(character_id)
	if data.is_empty():
		return {}
	var out: Dictionary = {
		"character_id": character_id,
		"display_name": str(data.get("display_name", "")),
	}
	for key: String in STATE_KEYS:
		if data.has(key):
			out[key] = WORLD_SAVE.copy_value(data[key])
	out["realm"] = str(data.get("realm", "meadows"))
	out["flags"] = WORLD_SAVE.copy_value(data.get("flags", {})) if data.get("flags") is Dictionary else {}
	return out


## Load `character_id` onto `game.local`, the portable half of a Continue and
## what a joiner needs to arrive as itself rather than as a fresh trainer.
## Returns whether a character was actually applied.
##
## This is deliberately NOT wired into `save_game.gd::load_slot()`: a slot is
## still one v22 file and loads exactly as it always has (see that function).
## This is the entry point for the multiplayer paths that have a character id
## and no slot at all.
func apply(game: Object, character_id: String) -> bool:
	if game == null:
		return false
	var local: Variant = game.get("local")
	if local == null:
		return false
	var payload := state(character_id)
	if payload.is_empty():
		return false
	(local as RefCounted).call("load_data", payload)
	return true
