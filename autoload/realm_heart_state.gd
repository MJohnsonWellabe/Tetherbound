extends RefCounted

## Persistent, data-driven Realm Heart selection.
##
## Earning and placing a Heart are durable story facts, so they live in the
## existing progression flag store.  The one piece that is not a set of facts
## is the player's current choice: exactly one Heart power may be active.  This
## small composed state object owns that selection and nothing scene-specific.
##
## ## Stage B lane 5.B: which half of this is shared
##
## `earned_flag` and `placed_flag` are WORLD flags (`data/progression/flag_scopes.json`),
## so under D103 the shipping way to set one is a `set_world_flag` intent through
## `Game.ledger` -- `realm_heart_shrine.gd::submit_place()` is the only place in
## the game that does it, and `place()` below is the direct write it falls back
## to in a process that has no ledger (every unit fixture). A NEW caller that
## reaches for `place()` in shipping code is writing the world without the host,
## which is the thing D103 exists to stop; submit the intent instead.
##
## `_active_id` is the opposite: it is per player, it lives on the PLAYER half of
## the state split (`PlayerState.save_data()` carries `realm_hearts`), and
## nothing replicates it. Two peers in one world holding two different active
## Hearts is correct behaviour, not drift.

const CONFIG_PATH := "res://data/config/realm_hearts.json"

var revision: int = 0
var _config: Dictionary = {}
var _active_id: String = ""


func _init(config_override: Dictionary = {}) -> void:
	_config = config_override.duplicate(true) if not config_override.is_empty() else _read_config()


func heart(id: String) -> Dictionary:
	var hearts: Variant = _config.get("hearts", {})
	if not hearts is Dictionary:
		return {}
	var raw: Variant = (hearts as Dictionary).get(id, {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func realm(id: String) -> Dictionary:
	var realms: Variant = _config.get("realms", {})
	if not realms is Dictionary:
		return {}
	var raw: Variant = (realms as Dictionary).get(id, {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func scene_for_realm(id: String) -> String:
	return str(realm(id).get("scene", ""))


func entry_key_for_realm(id: String) -> String:
	return str(realm(id).get("entry_key_flag", ""))


## The world flag that records this Heart as earned, or "" for an unknown Heart.
func earned_flag(id: String) -> String:
	return str(heart(id).get("earned_flag", ""))


## The world flag that records this Heart as set into its socket, or "" for an
## unknown Heart. `realm_heart_shrine.gd` quotes it as the `id` of the
## `set_world_flag` intent it submits, so the flag name has one source.
func placed_flag(id: String) -> String:
	return str(heart(id).get("placed_flag", ""))


func is_earned(id: String, progression: RefCounted) -> bool:
	return _has_story_flag(progression, earned_flag(id))


func is_placed(id: String, progression: RefCounted) -> bool:
	return _has_story_flag(progression, placed_flag(id))


## Write the placed flag DIRECTLY. Shipping code does not call this: placing a
## Heart is a world mutation and goes through `realm_heart_shrine.gd::submit_place()`,
## which submits a `set_world_flag` intent so the host is the one writer and both
## peers see the Heart go in. This remains the applier for a process with no
## ledger at all -- every unit fixture in `tests/test_realm_heart_state.gd`.
func place(id: String, progression: RefCounted) -> bool:
	var spec := heart(id)
	if spec.is_empty() or not is_earned(id, progression):
		return false
	var flag := placed_flag(id)
	if flag == "" or progression == null:
		return false
	# MP_STATE_SEAM.md §3: placing a Heart is a WORLD fact, and it is written to
	# the world store BY NAME rather than routed by scope, so a client cannot
	# record it locally from Wave 3. `progression` is normally the merged view
	# (`merged_progression.gd`), which carries `world_flags`; a caller that hands
	# over one flat store -- every unit test in test_realm_heart_state.gd -- has
	# no such field and gets exactly the store it passed, as before.
	var store: Variant = progression.get("world_flags")
	var target: RefCounted = store as RefCounted if store != null else progression
	target.call("set_flag", flag)
	return true


## Equip one placed Heart.  Assigning the id replaces the old selection in one
## write, so there is no frame in which two realm powers can both be active.
func activate(id: String, progression: RefCounted) -> bool:
	if not is_placed(id, progression):
		return false
	if _active_id == id:
		return true
	_active_id = id
	revision += 1
	return true


func clear_active() -> void:
	if _active_id == "":
		return
	_active_id = ""
	revision += 1


func active_id() -> String:
	return _active_id


func active_power() -> Dictionary:
	if _active_id == "":
		return {}
	var raw: Variant = heart(_active_id).get("power", {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func stamina_capacity_multiplier() -> float:
	return maxf(1.0, float(active_power().get("max_stamina_multiplier", 1.0)))


func save_data() -> Dictionary:
	return {"active_id": _active_id}


## Unknown, malformed, or no-longer-placed selections load inactive.  A save
## must never manufacture a power that its story flags do not support.
func load_data(data: Dictionary, progression: RefCounted = null) -> void:
	var candidate := str(data.get("active_id", ""))
	if candidate != "" and heart(candidate).is_empty():
		candidate = ""
	if candidate != "" and progression != null and not is_placed(candidate, progression):
		candidate = ""
	_active_id = candidate
	revision += 1


func _has_story_flag(progression: RefCounted, flag: String) -> bool:
	return progression != null and flag != "" and bool(progression.call("has", flag))


func _read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("realm Heart config missing: %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("realm Heart config is not valid JSON: %s" % CONFIG_PATH)
		return {}
	return parsed as Dictionary
