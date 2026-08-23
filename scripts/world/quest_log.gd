extends RefCounted

## SB11: the smallest reader over SB9's flag store that turns
## `data/progression/objectives.json` into the HUD's one tracked line and the
## menu's two-list quest log (spec §16). Invents no state of its own -- every
## answer here is a pure function of `progression_state.gd`'s flags plus this
## static data, so there is nothing here to save/load and nothing that can
## drift out of sync with `progression`.
##
## Deliberately NOT a quest engine (spec §19, CLAUDE.md): no branching, no
## prerequisites. An entry is DONE the instant its own `flag_id` is set; the
## tracked line is just the first "main" entry not yet done, in file order.
##
## SF34 added the one exception, and kept it as small as it sounds: an entry
## may carry `count_flags`, a list of flags whose set-count is appended to its
## label as " n/total" (spec §16's own example line is "Defeat the Upper
## Meadows captains. 2/3"). It changes nothing about DONE — that is still the
## entry's own `flag_id` — and an entry without `count_flags` renders exactly
## as it did before. See `data/progression/objectives.json`'s own comment for
## why this is not the counter system §19 bans.

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
		# `revealed_by` (optional, BAND1-D1): the entry does not exist for the
		# player until that flag is set. Absent means always listed, which is
		# every entry that existed before this and every Main Story beat, so
		# nothing already in the file changes.
		#
		# It exists because optional content and the Main Story want opposite
		# things from this list. A main beat should be visible before you do
		# it -- that is the whole point of a tracked objective. An optional
		# one should not: prompt 30's rule is that some optional content is
		# discoverable through curiosity rather than a quest giver and that
		# secrets are not pre-labelled from game start, and an entry reading
		# "Beat the Old Champion" on a fresh save tells the player about a man
		# they have not met, in a field they have not walked to. This panel's
		# own empty state says "Nothing outstanding right now", which is a
		# promise that what is listed is something the player actually knows
		# about.
		var revealed_by := str(entry.get("revealed_by", ""))
		if not revealed_by.is_empty() and not bool(progression.call("has", revealed_by)):
			continue
		var flag_id := str(entry.get("flag_id", ""))
		var done := not flag_id.is_empty() and bool(progression.call("has", flag_id))
		out.append({"label": _label(entry, progression), "done": done})
	return out


## The entry's label, with SF34's " n/total" appended when it carries
## `count_flags`. One place, so the HUD's tracked line and the quest-log row
## can never disagree about the count.
func _label(entry: Dictionary, progression: RefCounted) -> String:
	var label := str(entry.get("label", ""))
	var raw: Variant = entry.get("count_flags", [])
	if typeof(raw) != TYPE_ARRAY:
		return label
	var flags := raw as Array
	if flags.is_empty():
		return label
	var have := 0
	for flag: Variant in flags:
		if bool(progression.call("has", str(flag))):
			have += 1
	return "%s %d/%d" % [label, have, flags.size()]


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
			return _label(entry, progression)
	return ""
