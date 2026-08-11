extends RefCounted

## The conversation state machine. Pure: no nodes, no drawing, no input.
##
## Ported from the previous prototype's `src/ui/DialogueRunner.ts`, minus
## branching. That version supported choices and used them for the starter
## pick; this one deliberately cannot, because docs/OPENING_SEQUENCE.md decided
## the starter is chosen by walking up to a creature. A dialogue system that can
## branch is a dialogue system that will be asked to hold the choice again.
##
## What survives the port is the part that earned its keep: text lives in JSON,
## and EFFECTS are handed back as opaque strings rather than executed. This file
## knows that the last line of the intro emits `beat:starter_choice`; it has no
## idea what a beat is. That separation is what stopped the old runner from
## slowly accumulating game logic, and it means an unrecognised effect is a loud
## no-op at the caller rather than a crash mid-conversation.

const DIALOGUE_PATH := "res://data/dialogue/opening.json"

## Village banter (R7.2), same `{"conversations": {...}}` shape, merged onto the
## opening's table rather than folded into opening.json. Kept as a separate file
## so a villager's line and Grandpa's briefing stay independently editable and
## `test_dialogue_runner.gd`'s coverage of the opening's own ids is unaffected by
## how many villagers exist.
const VILLAGE_DIALOGUE_PATH := "res://data/dialogue/village.json"

signal finished(conversation_id: String)

static var _table: Dictionary = {}

var _conversation: Dictionary = {}
var _id: String = ""
var _index: int = 0
var _active: bool = false
## Effects produced since the last drain.
var _pending: Array[String] = []
## Substitutions applied to every line as it is read, so `$name` in the JSON
## becomes the word the player typed. Set by the caller before `start()`.
var _values: Dictionary = {}


static func table() -> Dictionary:
	if not _table.is_empty():
		return _table
	_table = _load_conversations(DIALOGUE_PATH)

	# Additive only: a missing village.json degrades to "no village banter",
	# never to a broken opening, and an id village.json shares with opening.json
	# loses rather than silently overwriting Grandpa's own lines.
	if ResourceLoader.exists(VILLAGE_DIALOGUE_PATH):
		var village := _load_conversations(VILLAGE_DIALOGUE_PATH)
		for id: String in village:
			if _table.has(id):
				push_warning("%s reuses conversation id '%s'; the opening's own copy wins" % [VILLAGE_DIALOGUE_PATH, id])
				continue
			_table[id] = village[id]
	return _table


static func _load_conversations(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("dialogue missing at %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).get("conversations", {})
	push_error("%s is not valid JSON" % path)
	return {}


static func has(id: String) -> bool:
	return table().has(id)


## Words a line may refer to by name. `$name` is the only one today.
func set_value(key: String, value: String) -> void:
	_values[key] = value


func is_active() -> bool:
	return _active


func conversation_id() -> String:
	return _id


## Begin a conversation. Returns false for an unknown id or an empty one rather
## than opening a panel with nothing in it.
func start(id: String) -> bool:
	var entry: Variant = table().get(id)
	if not entry is Dictionary:
		push_error("unknown conversation '%s'; known: %s" % [id, ", ".join(table().keys())])
		return false
	var conversation: Dictionary = entry
	if (conversation.get("lines", []) as Array).is_empty():
		push_error("conversation '%s' has no lines" % id)
		return false
	_conversation = conversation
	_id = id
	_index = 0
	_active = true
	_collect_effects()
	return true


## The line to draw right now: speaker, portrait, text, and whether advancing
## from here closes the conversation. Empty Dictionary when nothing is running,
## so a poller can assign from it unconditionally.
func line() -> Dictionary:
	if not _active:
		return {}
	var raw: Variant = (_conversation.get("lines", []) as Array)[_index]
	var text := ""
	var speaker := str(_conversation.get("speaker", ""))
	var portrait := str(_conversation.get("portrait", ""))
	if raw is Dictionary:
		var node: Dictionary = raw
		text = str(node.get("text", ""))
		speaker = str(node.get("speaker", speaker))
		portrait = str(node.get("portrait", portrait))
	else:
		text = str(raw)
	return {
		"speaker": _substitute(speaker),
		"portrait": portrait,
		"text": _substitute(text),
		"is_last": _index >= _line_count() - 1,
		"index": _index,
		"count": _line_count(),
	}


## Step to the next line, or close. One button, one line, no way to skip the
## conversation wholesale — this is the beat that explains why there is a
## journey, and the first thing a skip button teaches is that it does not
## matter.
func advance() -> void:
	if not _active:
		return
	if _index >= _line_count() - 1:
		close()
		return
	_index += 1
	_collect_effects()


func close() -> void:
	if not _active:
		return
	var id := _id
	_active = false
	_conversation = {}
	_id = ""
	_index = 0
	finished.emit(id)


## Take the effects produced so far. The caller applies them; see the file
## comment for why they are strings.
func drain_effects() -> Array[String]:
	var out: Array[String] = _pending.duplicate()
	_pending.clear()
	return out


## Split "beat:starter_choice" into ["beat", "starter_choice"].
static func parse_effect(effect: String) -> Array:
	var index := effect.find(":")
	if index < 0:
		return [effect, ""]
	return [effect.substr(0, index), effect.substr(index + 1)]


func _line_count() -> int:
	return (_conversation.get("lines", []) as Array).size()


func _collect_effects() -> void:
	var raw: Variant = (_conversation.get("lines", []) as Array)[_index]
	if not raw is Dictionary:
		return
	var node: Dictionary = raw
	var single := str(node.get("effect", ""))
	if single != "":
		_pending.append(single)
	for extra: Variant in (node.get("effects", []) as Array):
		_pending.append(str(extra))


func _substitute(text: String) -> String:
	var out := text
	for key: String in _values:
		out = out.replace("$%s" % key, str(_values[key]))
	return out
