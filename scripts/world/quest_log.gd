extends RefCounted

## SB11: the smallest reader over SB9's flag store that turns
## `data/progression/objectives.json` into the HUD's one tracked line and the
## menu's two-list quest log (spec §16). Invents no state of its own -- every
## answer here is a pure function of `progression_state.gd`'s flags plus this
## static data, so there is nothing here to save/load and nothing that can
## drift out of sync with `progression`.
##
## Deliberately NOT a quest engine (spec §19, CLAUDE.md): no branching, no
## prerequisites, no counters. An entry is DONE the instant its own `flag_id`
## is set; the tracked line is just the first "main" entry not yet done, in
## file order.

const DATA_PATH := "res://data/progression/objectives.json"

var _main: Array = []
var _local: Array = []


func _init() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("quest_log.gd: %s missing" % DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("quest_log.gd: %s is not a JSON object" % DATA_PATH)
		return
	var data := parsed as Dictionary
	var main_raw: Variant = data.get("main", [])
	var local_raw: Variant = data.get("local", [])
	_main = main_raw if typeof(main_raw) == TYPE_ARRAY else []
	_local = local_raw if typeof(local_raw) == TYPE_ARRAY else []


## The Main Story list, `{label, done}` in file order.
func main_entries(progression: RefCounted) -> Array:
	return _entries(_main, progression)


## The Local Requests list, same shape.
func local_entries(progression: RefCounted) -> Array:
	return _entries(_local, progression)


func _entries(source: Array, progression: RefCounted) -> Array:
	var out: Array = []
	for raw: Variant in source:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		var flag_id := str(entry.get("flag_id", ""))
		var done := not flag_id.is_empty() and bool(progression.call("has", flag_id))
		out.append({"label": str(entry.get("label", "")), "done": done})
	return out


## Spec §16's one concise HUD line: the first Main Story entry not yet done,
## in file order. "" once every authored Main Story objective is complete --
## the chapter's later phases simply have not authored the next one yet, not
## a bug.
func tracked_text(progression: RefCounted) -> String:
	for raw: Variant in _main:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		var flag_id := str(entry.get("flag_id", ""))
		if flag_id.is_empty() or not bool(progression.call("has", flag_id)):
			return str(entry.get("label", ""))
	return ""
