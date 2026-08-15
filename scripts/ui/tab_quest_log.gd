extends "res://scripts/ui/menu_tab.gd"

## SB11: the two-list quest log (spec §16 — Main Story, Local Requests).
##
## Reads `Game.progression`'s flags through `scripts/world/quest_log.gd`, the
## same pure "objective data + flag store" reader `playground_hud.gd`'s
## tracked line uses — this tab and that line can never disagree about what
## counts as done, because both ask the same object the same question. This
## tab invents no state of its own.
##
## No branching, no timers, no prerequisite chains (spec §19, CLAUDE.md): an
## entry is either DONE (its flag is set) or not yet, in the fixed order
## `data/progression/objectives.json` lists it.

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

const DONE_MARK := "✓"  ## a check
const OPEN_MARK := "▸"  ## a small right-pointing triangle, matches the tab row's own ◆ accent language

var _log: RefCounted = QUEST_LOG.new()
var _main_list: VBoxContainer = null
var _local_list: VBoxContainer = null
var _last_progression_revision: int = -1


func build() -> void:
	for child in get_children():
		child.queue_free()
	_last_progression_revision = -1

	var title := Label.new()
	title.text = "QUEST LOG"
	title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	add_child(title)

	_main_list = _section("MAIN STORY")
	_local_list = _section("LOCAL REQUESTS")

	poll()
	UITokens.make_text_legible(self)


func _section(heading_text: String) -> VBoxContainer:
	var heading := Label.new()
	heading.text = heading_text
	heading.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	heading.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	add_child(heading)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_panel(list))
	return list


## Rebuilds only when `progression.revision` actually moved — the same
## polling idiom `progression_state.gd`'s own header describes — not once a
## frame regardless.
func poll() -> void:
	if _main_list == null:
		return
	var game := state()
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression == null:
		return
	var revision := int(progression.get("revision"))
	if revision == _last_progression_revision:
		return
	_last_progression_revision = revision
	_fill(_main_list, _log.call("main_entries", progression), "The road ahead is unclear.")
	_fill(_local_list, _log.call("local_entries", progression), "Nothing outstanding right now.")


func _fill(list: VBoxContainer, entries: Array, empty_text: String) -> void:
	for child in list.get_children():
		child.queue_free()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = empty_text
		empty.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		empty.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		list.add_child(empty)
		return
	for raw: Variant in entries:
		var entry := raw as Dictionary
		var done := bool(entry.get("done", false))
		var row := Label.new()
		row.text = "%s  %s" % [DONE_MARK if done else OPEN_MARK, str(entry.get("label", ""))]
		row.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
		row.add_theme_color_override(
			"font_color", UITokens.TEXT_MUTED if done else UITokens.TEXT_PRIMARY
		)
		list.add_child(row)
