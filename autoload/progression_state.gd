extends RefCounted

## SB9: the smallest progression-state system that survives the chapter.
##
## Spec §15 — objective flags, completion flags, trainer-defeated state,
## bridge-unlocked, dungeon-cleared, captive-rescued, Sigils, stronghold-
## unlocked, Warden-defeated, post-Warden world state — is all one flat flag
## store. Objectives themselves are DATA (`data/progression/`, once something
## needs to enumerate them); this class only remembers which ids have fired.
##
## Deliberately NOT a quest engine — spec §19 bans one and §15 says so twice.
## No branching, no timers, no prerequisite chains, no scripting language. A
## future need for any of those is a new system to flag, not a growth of
## this one.
##
## Same shape as `autoload/map_state.gd`: pure logic, no `Node`, no
## transform, testable headlessly (`tests/test_progression_state.gd`).
## `revision` is the same polling idiom `party.gd`/`inventory.gd`/
## `map_state.gd` already use, so a quest-log UI (SB11) can redraw only when
## something actually changed instead of listening for a signal per flag.

## Bumped whenever a flag's set-state actually changes. Unchanged by a
## `set_flag()` call that redundantly sets an already-set flag or clears an
## already-unset one, so a poller does not redraw for nothing.
var revision: int = 0

## flag id -> true. Presence means set; absence means unset. There is no
## stored "false" — clearing a flag erases the key rather than writing false,
## so `all_set()` and the save payload only ever list what actually fired.
var _flags: Dictionary = {}


## True once `set_flag(id)` has been called and not since cleared.
func has(id: String) -> bool:
	return _flags.has(id)


## Same query as `has()`, spelled for objective/story call sites where
## "completed" reads better than "has" — the spec's own vocabulary splits
## "objective flags" from "completion flags", but both live in one store.
func completed(id: String) -> bool:
	return has(id)


## Sets or clears `id`. Defaults to setting (`set_flag("bridge_unlocked")`
## reads as the common case); pass `value = false` to clear one back out.
func set_flag(id: String, value: bool = true) -> void:
	if value:
		if _flags.has(id):
			return
		_flags[id] = true
	else:
		if not _flags.has(id):
			return
		_flags.erase(id)
	revision += 1


## Every currently-set flag id — for SB11's quest log to check off against
## `data/progression/`'s objective list.
func all_set() -> Array:
	return _flags.keys()


func save_data() -> Dictionary:
	return {"flags": _flags.keys()}


## Tolerant of a missing or malformed `flags` key — `load_data({})` is a
## working fresh state, the same contract `map_state.gd`'s `load_data()`
## already gives save_game.gd.
func load_data(data: Dictionary) -> void:
	_flags.clear()
	var raw: Variant = data.get("flags", [])
	if typeof(raw) == TYPE_ARRAY:
		for id: Variant in (raw as Array):
			if typeof(id) == TYPE_STRING and not (id as String).is_empty():
				_flags[id] = true
	revision += 1


# --- flag scopes (D99, docs/specs/MP_STATE_SEAM.md §3) -----------------------
##
## Which store a flag id belongs in: the world's (`WorldState.flags`) or one
## player's (`PlayerState.flags`). `autoload/merged_progression.gd` routes every
## `set_flag()` through this, and `tests/test_flag_scopes.gd` proves no id any
## shipped writer site or objective names resolves to "".
##
## The table is DATA (`data/progression/flag_scopes.json`) rather than a match
## statement here, for the same reason `objectives.json` is data: the
## classification is a design decision the owner and Fable make, and a design
## decision that lives in a script is one nobody can review without reading
## GDScript. Cached in a `static var` because it is immutable config, the same
## exemption `progression_feed.gd::config()` keeps -- it is not per-player
## state and cannot differ between two players in one process.

const FLAG_SCOPES_PATH := "res://data/progression/flag_scopes.json"

const SCOPE_WORLD := "world"
const SCOPE_PLAYER := "player"

static var _scope_ids: Dictionary = {}
## [prefix, scope] pairs, longest prefix first, so the first match IS the
## longest match and `scope_of` needs no second pass.
static var _scope_prefixes: Array = []
static var _scopes_loaded: bool = false


## `"world"`, `"player"`, or `""` for an id the table does not name.
##
## Exact id first, then the longest matching prefix. `""` is a real answer and
## the caller decides what to do with it -- `merged_progression.gd` pushes an
## error and writes to the world store so the game does not stall, and the test
## guarantees shipped data never takes that path.
static func scope_of(id: String) -> String:
	_ensure_scopes()
	if id.is_empty():
		return ""
	var exact: Variant = _scope_ids.get(id, "")
	if str(exact) != "":
		return str(exact)
	for entry: Variant in _scope_prefixes:
		var pair := entry as Array
		if id.begins_with(str(pair[0])):
			return str(pair[1])
	return ""


## Every id the table names outright, for the test's coverage sweep.
static func scoped_ids() -> Array:
	_ensure_scopes()
	return _scope_ids.keys()


## Every [prefix, scope] pair, longest prefix first.
static func scoped_prefixes() -> Array:
	_ensure_scopes()
	return _scope_prefixes.duplicate(true)


## Forget the parsed table. Tests only -- a `static var` cache outlives one
## test's fixture, and a test that swaps the file needs a way to say so.
static func reload_scopes() -> void:
	_scopes_loaded = false
	_scope_ids = {}
	_scope_prefixes = []


static func _ensure_scopes() -> void:
	if _scopes_loaded:
		return
	_scopes_loaded = true
	_scope_ids = {}
	_scope_prefixes = []
	var file := FileAccess.open(FLAG_SCOPES_PATH, FileAccess.READ)
	if file == null:
		push_error("flag scope table missing: %s" % FLAG_SCOPES_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("flag scope table is not valid JSON: %s" % FLAG_SCOPES_PATH)
		return
	for scope: String in [SCOPE_WORLD, SCOPE_PLAYER]:
		var block: Variant = (parsed as Dictionary).get(scope, {})
		if not block is Dictionary:
			continue
		for raw: Variant in ((block as Dictionary).get("ids", []) as Array):
			if typeof(raw) == TYPE_STRING and not (raw as String).is_empty():
				_scope_ids[raw as String] = scope
		for raw: Variant in ((block as Dictionary).get("prefixes", []) as Array):
			if typeof(raw) == TYPE_STRING and not (raw as String).is_empty():
				_scope_prefixes.append([raw as String, scope])
	# Longest first, so the first `begins_with` hit is the longest match:
	# `opening:beat:` must win over `opening:`.
	_scope_prefixes.sort_custom(func(a: Array, b: Array) -> bool:
		return str(a[0]).length() > str(b[0]).length())
