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
## `data/progression/objectives.json` lists it. `_fill_main` below only
## decides what of that fixed order gets DRAWN; it is still `quest_log.gd`'s
## own DONE/not-yet answer for every entry, read once and not cached anywhere
## new.
##
## PRESENTATION FIX (blind-judge pass): a Day-1 save used to print all
## twenty-plus Main Story steps at once — through "Defeat the Meadows
## Warden" — as a flat, equally-weighted list, so the one line the player
## could actually act on sat second in a wall of identical rows and the
## chapter's ending was legible from the first minute. `_fill_main` now draws
## only what the player has reached: every entry already DONE, the one entry
## currently open (`quest_log.gd::tracked_text()`'s own "first not-yet entry
## in file order" rule, reused here rather than re-invented), and exactly one
## step of look-ahead past it -- with the current entry given real visual
## weight instead of sharing a font size with twenty others. The look-ahead
## row is not a softening of the rule: drawing the current step ALONE hid the
## village gate on a fresh save, where the open entry is still "Catch your
## first wild creature", and `tests/smoke_menu.gd` caught it. One line ahead
## is what the player is walking into; twenty were the chapter's ending. Nothing here hides a step the player is IN — a revealed
## objective still reads until it is done — it only stops printing steps
## nobody has reached yet. `objectives.json` and `quest_log.gd` are both
## untouched: the data still holds every entry in the same order, and this is
## the one file (see `_comment_no_spoilers` there) allowed to decide how much
## of it a Day-1 screen actually shows.

const QUEST_LOG := preload("res://scripts/world/quest_log.gd")

const DONE_MARK := "✓"  ## a check
const OPEN_MARK := "▸"  ## a small right-pointing triangle, matches the tab row's own ◆ accent language

## Right-stick pan, px/second at full deflection. Reuses `look_up`/`look_down`
## (project.godot), the same action `tab_map.gd::_read_navigation_input`
## already reads for its own pan, rather than adding a new one — this agent
## may not touch project.godot's input map. Mouse wheel scrolls a
## ScrollContainer for free; this is only the controller half of that job.
const SCROLL_SPEED := 900.0

var _log: RefCounted = QUEST_LOG.new()
var _scroll: ScrollContainer = null
var _main_list: VBoxContainer = null
var _local_list: VBoxContainer = null
var _last_progression_revision: int = -1


func build() -> void:
	for child in get_children():
		child.queue_free()
	_last_progression_revision = -1

	# ONE scroll container for the whole tab (mirrors tab_settings.gd's own
	# `_scroll`, OP21-04): the log's last line used to clip against the
	# panel's bottom edge with nothing to reveal it. AUTO vertical scrolling
	# (the default, left unset) is also the visible affordance itself — a
	# scrollbar only draws when content actually overflows.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	_scroll.add_child(page)

	var title := Label.new()
	title.text = "QUEST LOG"
	title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	page.add_child(title)

	_main_list = _section(page, "MAIN STORY")
	_local_list = _section(page, "LOCAL REQUESTS")

	poll()
	UITokens.make_text_legible(self)


func _section(parent: VBoxContainer, heading_text: String) -> VBoxContainer:
	var heading := Label.new()
	heading.text = heading_text
	heading.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	heading.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	parent.add_child(heading)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_panel(list))
	return list


## Rebuilds only when `progression.revision` actually moved — the same
## polling idiom `progression_state.gd`'s own header describes — not once a
## frame regardless. Scrolling itself is read every frame, revision or not.
func poll() -> void:
	if _main_list == null:
		return
	_read_scroll()
	var game := state()
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression == null:
		return
	var revision := int(progression.get("revision"))
	if revision == _last_progression_revision:
		return
	_last_progression_revision = revision
	_fill_main(_main_list, _log.call("main_entries", progression))
	_fill(_local_list, _log.call("local_entries", progression), "Nothing outstanding right now.")


func _read_scroll() -> void:
	if _scroll == null:
		return
	var axis := Input.get_axis("look_up", "look_down")
	if is_zero_approx(axis):
		return
	_scroll.scroll_vertical += int(roundi(axis * SCROLL_SPEED * get_process_delta_time()))


## The Main Story list. See the file header for why this draws a prefix of
## `entries` rather than all of it: everything DONE, in file order, then the
## one entry currently open — given its own row, first and loudest — and
## nothing past it. `entries[i]["done"]` is `quest_log.gd`'s own answer; this
## function only chooses which of them to draw and how loud.
func _fill_main(list: VBoxContainer, entries: Array) -> void:
	for child in list.get_children():
		child.queue_free()

	if entries.is_empty():
		var empty := Label.new()
		empty.text = "The road ahead is unclear."
		empty.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		empty.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		list.add_child(empty)
		return

	var current_index := -1
	for i in entries.size():
		if not bool((entries[i] as Dictionary).get("done", false)):
			current_index = i
			break

	# -1 means every authored Main Story entry is DONE (quest_log.gd's own
	# "" tracked-text state, spec-honest for a finished chapter) — draw the
	# whole completed history and skip the current-objective row, since there
	# is no longer a current objective.
	var revealed := current_index if current_index >= 0 else entries.size()

	if current_index >= 0:
		list.add_child(_current_row(entries[current_index] as Dictionary))
		# One step of look-ahead, and exactly one. Drawing ONLY the current
		# step reads as a chapter with no shape -- and it hid a step the
		# player is about to be sent to: in a fresh save the open entry is
		# "Catch your first wild creature" and the village gate is the very
		# next one, which `tests/smoke_menu.gd` caught disappearing. One line
		# ahead is what the player is walking into; twenty were the chapter's
		# ending, which is the wall this filter exists to stop printing.
		# Muted and small, so the current step above it is still the loudest
		# thing on the page.
		if current_index + 1 < entries.size():
			list.add_child(_next_row(entries[current_index + 1] as Dictionary))

	if revealed <= 0:
		return

	var done_list := VBoxContainer.new()
	done_list.add_theme_constant_override("separation", 4)
	list.add_child(done_list)
	for i in revealed:
		done_list.add_child(_done_row(entries[i] as Dictionary))


## The one line a Day-1 player can act on: bigger and TEAL, the same accent
## colour the focus ring already means "this is the live one" everywhere else
## in this menu, rather than sharing FONT_BODY with a wall of finished steps.
func _current_row(entry: Dictionary) -> Control:
	var row := Label.new()
	row.text = "%s  %s" % [OPEN_MARK, str(entry.get("label", ""))]
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	row.add_theme_color_override("font_color", UITokens.TEAL)
	return row


## The single step after the current one. Marked OPEN like the current row --
## it is not done -- but at the muted weight the finished history uses, so the
## page still has exactly one loud line on it.
func _next_row(entry: Dictionary) -> Control:
	var row := Label.new()
	row.text = "%s  %s" % [OPEN_MARK, str(entry.get("label", ""))]
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	row.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	return row


func _done_row(entry: Dictionary) -> Control:
	var row := Label.new()
	row.text = "%s  %s" % [DONE_MARK, str(entry.get("label", ""))]
	row.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	row.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	return row


## The Local Requests list. Unlike Main Story, an entry here only exists at
## all once `revealed_by` has fired (`quest_log.gd::_entries`), so the wall-
## of-spoilers problem `_fill_main` fixes does not apply — every entry this
## list ever hands back is one the player has already met in the world, done
## or not, and showing an OPEN one is the point.
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
