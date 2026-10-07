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

const ATOMIC_SAVE_FILE := preload("res://scripts/save/atomic_save_file.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")

## Worn items are owned outside the bag; v1 readers must refuse these files
## rather than silently discard the equipment field on their next save.
## Version 3 reserves satchel_escrow for durable reward-delivery rows as well as
## death transactions. Version 4 records the exact world instance that owns a
## saved traversal pose, so older builds must refuse rather than discard it.
## Version 5 records the world instance on durable satchel escrow rows; v4
## readers must refuse rather than replay a row using only a slot locator.
## Version 6 owns the ordered tournament selection alongside the portable party.
## RD-35 resets both merged and portable formats; v6 is a pre-redesign save.
const VERSION := 28
const RESET_MAX_VERSION := 27
const OLD_VERSION_MESSAGE := "This save is from an older version. Start a new game. Your old save has been kept."

const ENVELOPE_KEYS: Array[String] = [
	"version", "character_id", "display_name", "created_at", "last_played",
	"last_world_id", "last_world_instance_id", "migrated_from",
]

## The v22 keys this half owns under their own names.
const STATE_KEYS: Array[String] = [
	"redesign_character",
	"chosen_character", "party", "tournament_selection", "inventory", "equipment", "hotbar", "satiety", "player_pose", "pending_realm_entry",
	"realm_hearts", "realm_maps", "skills", "satchel_escrow",
]

## v22 keys this half owns but does NOT store, because they are recoverable
## from `realm_maps` and storing them twice is how two copies drift apart.
const DERIVED_KEYS: Array[String] = ["map", "alpha_pins"]

var _dir: String
var _legacy_dir: String = ""

## id -> the envelope fields a re-save must PRESERVE rather than recompute.
##
## `write()` runs on every autosave, and an autosave already writes the v22 slot
## file; re-parsing this file each time only to read `created_at` back would put
## a third full JSON parse on a path that runs while the player is walking
## around. The first write of a session pays one read; the rest do not.
var _envelope_cache: Dictionary = {}
var last_load_result: Dictionary = {}


func _init(dir: String = "user://characters/redesign-v28/", legacy_dir: String = "") -> void:
	_dir = dir if dir.ends_with("/") else dir + "/"
	_legacy_dir = legacy_dir if legacy_dir.is_empty() or legacy_dir.ends_with("/") else legacy_dir + "/"
	if _dir == "user://characters/redesign-v28/" and _legacy_dir.is_empty(): _legacy_dir = "user://characters/"


func root_dir() -> String:
	return _dir


func dir_for(character_id: String) -> String:
	return "%s%s/" % [_dir, character_id]


func path_for(character_id: String) -> String:
	return "%scharacter.json" % dir_for(character_id)


func has(character_id: String) -> bool:
	return not character_id.is_empty() and ATOMIC_SAVE_FILE.has_readable(_read_path(character_id))


func _read_path(character_id: String) -> String:
	var current := path_for(character_id)
	if ATOMIC_SAVE_FILE.has_readable(current) or _legacy_dir.is_empty(): return current
	return "%s%s/character.json" % [_legacy_dir, character_id]


func delete(character_id: String) -> bool:
	return not character_id.is_empty() and ATOMIC_SAVE_FILE.delete(path_for(character_id))


func list_ids() -> Array:
	var out: Array = []
	for directory: String in [_dir, _legacy_dir]:
		if directory.is_empty() or not DirAccess.dir_exists_absolute(directory): continue
		for name: String in DirAccess.get_directories_at(directory):
			if has(name) and not out.has(name): out.append(name)
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
	# The old unclassified world lesson is not evidence of this character's trial.
	world_ids.erase("fly_tutorial_completed")
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
## `envelope` may carry `display_name`, world provenance and `migrated_from`.
func write(character_id: String, payload: Dictionary, envelope: Dictionary = {}, retain_previous: bool = false) -> bool:
	if character_id.is_empty():
		return false
	var escrow_errors: Array = preload("res://scripts/net/portal_escrow_validation.gd").escrow_errors(payload.get("satchel_escrow", {}), character_id)
	escrow_errors.append_array(preload("res://scripts/net/actor_vitals_delivery.gd").escrow_errors(payload.get("satchel_escrow", {}), character_id))
	if not escrow_errors.is_empty():
		push_warning("character save refused for '%s': escrow %s" % [character_id, str(escrow_errors)])
		return false
	var loadout_errors: Array = preload("res://scripts/creatures/teaching.gd").party_loadout_errors(payload.get("party",[]),payload.get("redesign_character",{}))
	if not loadout_errors.is_empty():
		push_warning("character save refused for '%s': party loadout %s" % [character_id, str(loadout_errors)])
		return false
	payload = payload.duplicate(true)
	payload["redesign_character"] = preload("res://scripts/creatures/teaching.gd").character_loadout_mirror(payload.get("party",[]),payload.get("redesign_character",preload("res://scripts/data/redesign_state.gd").defaults("character")))
	var contract := preload("res://scripts/data/redesign_state.gd")
	var character_errors: Array = contract.validate("character", payload.get("redesign_character", contract.defaults("character")), contract.uids(payload.get("party", [])))
	if not character_errors.is_empty():
		push_warning("character save refused for '%s': redesign character %s" % [character_id, str(character_errors)])
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
	var instance_raw: Variant = envelope.get("last_world_instance_id",
		existing.get("last_world_instance_id", ""))
	data["last_world_instance_id"] = instance_raw as String \
		if typeof(instance_raw) == TYPE_STRING else ""
	data["migrated_from"] = str(envelope.get("migrated_from", existing.get("migrated_from", "")))
	var encoded := SAVE_DOCUMENT.stringify(data)
	if encoded.is_empty(): return false
	if not ATOMIC_SAVE_FILE.new().write(path_for(character_id), encoded, retain_previous):
		push_warning("character save: could not commit %s" % path_for(character_id))
		return false
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
	var instance_raw: Variant = data.get("last_world_instance_id", null)
	if typeof(instance_raw) == TYPE_STRING:
		out["last_world_instance_id"] = instance_raw as String
	return out


func read(character_id: String) -> Dictionary:
	last_load_result = {"ok": false, "code": "unreadable_save", "message": "That character could not be loaded."}
	if not has(character_id):
		return {}
	var file := FileAccess.open(ATOMIC_SAVE_FILE.readable_path(_read_path(character_id)), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = SAVE_DOCUMENT.parse(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data := parsed as Dictionary
	var raw_version: Variant = data.get("version", null)
	if not WORLD_SAVE.is_number(raw_version) or not is_finite(float(raw_version)) or float(raw_version) != floor(float(raw_version)):
		last_load_result = {"ok": false, "code": "invalid_version", "message": "That character has an invalid version."}
		return {}
	var version := int(data.get("version", 0)) if WORLD_SAVE.is_number(data.get("version")) else 0
	if version <= RESET_MAX_VERSION:
		last_load_result = {"ok": false, "code": "incompatible_old_version", "message": OLD_VERSION_MESSAGE}
		return {}
	if version < 1 or version > VERSION:
		push_warning("character '%s' is version %d, this build reads %d -- not loading" % [
			character_id, version, VERSION,
		])
		return {}
	var contract := preload("res://scripts/data/redesign_state.gd")
	var errors := contract.validate("character", data.get("redesign_character", contract.defaults("character")), contract.uids(data.get("party", [])))
	errors.append_array(preload("res://scripts/creatures/teaching.gd").party_loadout_errors(data.get("party",[]),data.get("redesign_character",{}),true))
	errors.append_array(preload("res://scripts/net/portal_escrow_validation.gd").escrow_errors(data.get("satchel_escrow", {}), character_id))
	errors.append_array(preload("res://scripts/net/actor_vitals_delivery.gd").escrow_errors(data.get("satchel_escrow", {}), character_id))
	if not errors.is_empty():
		last_load_result = {"ok": false, "code": "invalid_schema", "message": "That character contains invalid data.", "errors": errors}
		return {}
	last_load_result = {"ok": true, "code": "ok", "message": ""}
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
