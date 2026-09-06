extends RefCounted

## D100, the HOST-OWNED half: `user://worlds/<world_id>/world.json`.
##
## What happened to a world -- the day, the clock, the seed, everything built,
## farmed, dropped and harvested in it, and the WORLD-scope story flags. One
## file per world, written only by the process that owns that world. A client
## never writes one (`session.gd::_save_character_here()`,
## `game_state.gd::autosave_here()`), and `smoke_net_host_join_leave` asserts a
## client's `user://worlds/` stays empty while the host's does not.
##
## ## Why this partitions a dictionary rather than reading `WorldState`
##
## `partition()` takes the v22 save dictionary `save_game.gd` already builds and
## keeps the world half of it. Three things fall out of that choice, and each is
## the reason for it:
##
##   1. the legacy split and a live save run the SAME code, so a migrated world
##      and a freshly written one cannot disagree about the format;
##   2. `merge()` is its exact inverse, so "did the split drop anything?" is a
##      round-trip equality test rather than a claim
##      (`tests/test_split_key_coverage_equals_v22.gd`);
##   3. it works against any object `save_game.gd` can serialise, including the
##      `FakeGame` in `tests/test_save_format.gd`, which has no `WorldState`.
##
## The key names are `WorldState.save_data()`'s, verbatim, so
## `WorldState.load_data(payload)` restores a world file with no adapter in
## between. `progression` is the one v22 key that SPLITS: the ids
## `progression_state.scope_of()` calls world-scope land here under `flags`, and
## the rest go to `character_save.gd`.
##
## Never fatal, on read or write. A missing, corrupt or newer-than-this-build
## world file is "nothing to load", the same rule `save_game.gd` has always
## applied to a slot (D15).

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

## This file's own format version, independent of the v22 slot format's.
const VERSION := 1

## Written by `write()` around the state payload. Deliberately NOT part of the
## partition: these describe the FILE, not the world, and the key-coverage test
## excludes them for exactly that reason.
const ENVELOPE_KEYS: Array[String] = [
	"version", "world_id", "display_name", "created_at", "last_played", "migrated_from",
]

## The v22 keys this half owns outright, under their own names. `progression`
## is not here: it is the split key, and its world scope arrives as `flags`.
const STATE_KEYS: Array[String] = [
	"day", "clock_elapsed_seconds", "world_seed", "placed_buildings", "farm_plots",
	"death_satchels", "harvested_vegetation", "felled_vegetation",
]

var _dir: String

## id -> the envelope fields a re-save must PRESERVE rather than recompute.
##
## `write()` runs on every autosave, and an autosave already writes the v22 slot
## file; re-parsing this file each time only to read `created_at` back would put
## a third full JSON parse on a path that runs while the player is walking
## around. The first write of a session pays one read; the rest do not.
var _envelope_cache: Dictionary = {}


func _init(dir: String = "user://worlds/") -> void:
	_dir = dir if dir.ends_with("/") else dir + "/"


func root_dir() -> String:
	return _dir


func dir_for(world_id: String) -> String:
	return "%s%s/" % [_dir, world_id]


func path_for(world_id: String) -> String:
	return "%sworld.json" % dir_for(world_id)


func has(world_id: String) -> bool:
	return not world_id.is_empty() and FileAccess.file_exists(path_for(world_id))


## Every world id with a file on disk, sorted. Empty when nothing has written
## one -- which is the state a client must stay in.
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

## The world half of a v22 save dictionary, in `WorldState.save_data()`'s shape.
## `world_id` is stamped by `write()`, not here: the partition describes the
## world's STATE and the id is which file it goes in.
static func partition(v22: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in STATE_KEYS:
		if v22.has(key):
			out[key] = copy_value(v22[key])
	out["flags"] = {"flags": scope_flags(v22, PROGRESSION_STATE.SCOPE_WORLD)}
	return out


## The ids in a v22 `progression` payload whose scope is `scope`.
##
## An id the table does not know is treated as WORLD-scope, which is exactly
## `merged_progression.gd::load_data()`'s rule and the reason it is safe: a flag
## nobody scoped is something that happened to the world, and putting it in a
## character file would let one player carry it to another world. Unscoped ids
## are a `test_flag_scopes.gd` failure, not a save-time one, so this does not
## push an error on a path that runs on every autosave.
static func scope_flags(v22: Dictionary, scope: String) -> Array:
	var raw: Variant = (v22.get("progression", {}) as Dictionary).get("flags", []) if v22.get("progression") is Dictionary else []
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for id: Variant in (raw as Array):
		if typeof(id) != TYPE_STRING or (id as String).is_empty():
			continue
		var resolved := PROGRESSION_STATE.scope_of(id as String)
		if resolved != PROGRESSION_STATE.SCOPE_PLAYER:
			resolved = PROGRESSION_STATE.SCOPE_WORLD
		if resolved == scope:
			out.append(id)
	return out


# --- files --------------------------------------------------------------------

## Write `payload` (a `partition()` result) as `world_id`'s world file.
## `envelope` may carry `display_name` and `migrated_from`; `created_at` is
## preserved from any file already there, so re-saving a world does not
## repeatedly claim it was created just now.
func write(world_id: String, payload: Dictionary, envelope: Dictionary = {}) -> bool:
	if world_id.is_empty():
		return false
	var dir := dir_for(world_id)
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		push_warning("world save: could not create %s" % dir)
		return false
	var now := Time.get_datetime_string_from_system(true)
	var existing := _preserved(world_id)
	var data := payload.duplicate(true)
	data["version"] = VERSION
	data["world_id"] = world_id
	data["display_name"] = str(envelope.get("display_name", existing.get("display_name", "")))
	data["created_at"] = str(existing.get("created_at", now))
	data["last_played"] = now
	data["migrated_from"] = str(envelope.get("migrated_from", existing.get("migrated_from", "")))
	var file := FileAccess.open(path_for(world_id), FileAccess.WRITE)
	if file == null:
		push_warning("world save: could not open %s for writing" % path_for(world_id))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	# Same reason `save_game.gd` closes explicitly: a world may be read back in
	# the same frame it was written, and a buffered document is not a document.
	file.close()
	_envelope_cache[world_id] = _envelope_of(data)
	return true


## The envelope fields a later write must carry forward, from the cache when
## this saver has already written this id in-process and from the file
## otherwise. A missing or unreadable file is {} -- "there was nothing to
## preserve", never a refusal.
func _preserved(world_id: String) -> Dictionary:
	if _envelope_cache.has(world_id):
		return _envelope_cache[world_id] as Dictionary
	var existing := read(world_id)
	var preserved := _envelope_of(existing)
	_envelope_cache[world_id] = preserved
	return preserved


func _envelope_of(data: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in ["display_name", "created_at", "migrated_from"]:
		if data.has(key):
			out[key] = str(data[key])
	return out


## `world_id`'s file, or {} for missing, unreadable, non-object or
## newer-than-this-build content.
func read(world_id: String) -> Dictionary:
	if not has(world_id):
		return {}
	var file := FileAccess.open(path_for(world_id), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data := parsed as Dictionary
	var version := int(data.get("version", 0)) if is_number(data.get("version")) else 0
	if version < 1 or version > VERSION:
		push_warning("world '%s' is version %d, this build reads %d -- not loading" % [
			world_id, version, VERSION,
		])
		return {}
	return data


## The state half of a world file, ready for `WorldState.load_data()`.
func state(world_id: String) -> Dictionary:
	var data := read(world_id)
	if data.is_empty():
		return {}
	var out: Dictionary = {"world_id": world_id}
	for key: String in STATE_KEYS:
		if data.has(key):
			out[key] = copy_value(data[key])
	out["flags"] = copy_value(data.get("flags", {})) if data.get("flags") is Dictionary else {}
	return out


static func copy_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	if typeof(value) == TYPE_ARRAY:
		return (value as Array).duplicate(true)
	return value


static func is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
