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
##
## TUTORIAL-CHAIN (OP23-04) changed WHAT THIS DRAWS and nothing else. It used
## to render every Main Story entry in the file, done and not-done alike --
## twenty-two rows on a fresh save, of which one was actionable. The owner's
## report is the whole reason this lane exists: the opening should tell you
## the next thing to do, one step at a time, "never fronting the full list".
##
## So the Main Story section now draws `quest_log.gd::guided_entries()` -- what
## is done, plus the one rung the player is on -- with that open rung given the
## panel's emphasis and its `how` line printed underneath it: the concrete
## action and the button to do it with, read live off the InputMap so a rebind
## cannot make it lie. Local Requests are untouched; `revealed_by` already
## gives them their own one-at-a-time rule.
##
## Still no state of its own, still one reader, still no condition in the data.

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
	_fill(
		_main_list,
		_log.call("guided_entries", progression),
		"The road ahead is unclear.",
		int(_log.call("current_index", progression))
	)
	_fill(_local_list, _log.call("local_entries", progression), "Nothing outstanding right now.")


## `current` is the index within `entries` of the one open rung, or -1 when
## there is none (Local Requests never pass one; a finished chapter passes -1).
## That row gets the `how` line under it -- only that row, because a hint for a
## step the player already finished is noise and a hint for one they cannot see
## does not exist.
func _fill(list: VBoxContainer, entries: Array, empty_text: String, current: int = -1) -> void:
	for child in list.get_children():
		child.queue_free()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = empty_text
		empty.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		empty.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		list.add_child(empty)
		return
	for i in entries.size():
		var entry := entries[i] as Dictionary
		var done := bool(entry.get("done", false))
		var row := Label.new()
		row.text = "%s  %s" % [DONE_MARK if done else OPEN_MARK, str(entry.get("label", ""))]
		row.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
		row.add_theme_color_override(
			"font_color", UITokens.TEXT_MUTED if done else UITokens.TEXT_PRIMARY
		)
		list.add_child(row)
		if i != current:
			continue
		var how := str(entry.get("how", ""))
		if how.is_empty():
			continue
		var hint := Label.new()
		# Indented under the row it belongs to, one step quieter than the open
		# objective and one step louder than a finished one: it is the answer
		# to "how", not a second objective competing with the "what" above it.
		#
		# FONT_LABEL, not FONT_TINY, for the reason `tab_backpack.gd`'s own bar
		# hint gives at the same size: this sentence is the instruction, and an
		# instruction nobody can read at handheld scale is the OP23-04 defect
		# happening one layer further in.
		hint.text = "     %s" % how
		hint.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
		hint.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(hint)
