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
const RESEARCH_PANEL := preload("res://scripts/ui/research_log_panel.gd")
const RESEARCH_LOG := preload("res://scripts/creatures/research_log.gd")
var _research_panel: CanvasLayer
var _research_reader := Callable()
var _research_button: Button

## F45 supplies its character-bound read-only task projection here.
func configure_research_view(reader: Callable) -> bool:
	if not reader.is_valid(): return false
	_research_reader = reader
	return true

func _research_view(biome: String) -> Dictionary:
	if _research_reader.is_valid():
		var raw: Variant = _research_reader.call(biome)
		return raw if raw is Dictionary else {"ready": false}
	var game := state()
	var local: RefCounted = game.get("local") if game != null else null
	if local == null: return {"ready": false}
	return RESEARCH_LOG.view(local.get("redesign_character"), str(local.get("character_id")), biome)

func _claim_research(species: String, task: String) -> Dictionary:
	var game := state()
	var session: Node = game.get("session") if game != null else null
	if session == null or not session.has_method("request_research_claim"): return {"ok": false, "code": "Research rewards are unavailable."}
	return session.call("request_research_claim", {"species_id": species, "task_id": task})

func _open_research() -> void:
	var game := state()
	if game == null: return
	if not is_instance_valid(_research_panel):
		_research_panel = RESEARCH_PANEL.new()
		_research_panel.set("return_to", _return_to_journal)
		_research_panel.set("claim_task", _claim_research)
		game.add_child(_research_panel)
	menu.call("close")
	if _research_panel.call("open", _research_view) != true: menu.call("open", "quest_log")

func _return_to_journal() -> void:
	if is_instance_valid(menu): menu.call("open", "quest_log")

func first_focus() -> Control:
	return _research_button if is_instance_valid(_research_button) else null

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
	_research_button = null
	if RESEARCH_PANEL.config().get("enabled") == true:
		_research_button = Button.new()
		_research_button.text = "Research log · Species and task rewards"
		_research_button.custom_minimum_size.y = 66
		_research_button.add_theme_font_size_override("font_size", UITokens.FONT_PROMPT)
		_research_button.pressed.connect(_open_research)
		add_child(_research_button)

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

	var game := state()
	if game != null: _log.call("set_realm", str(game.get("current_realm")))
	_main_list = _section(page, str(_log.call("chapter_heading")))
	_local_list = _section(page, "LOCAL REQUESTS")
	if RESEARCH_PANEL.config().get("enabled") == true: _build_bounties(page)

	poll()
	UITokens.make_text_legible(self)

func _build_bounties(page: VBoxContainer) -> void:
	var list := _section(page, "ACTIVE BOUNTIES · Claim at Halda's board")
	var path := "res://scripts/world/bounty_board.gd"
	if not ResourceLoader.exists(path):
		var missing := Label.new()
		missing.text = "The bounty board is unavailable."
		missing.add_theme_font_size_override("font_size", UITokens.FONT_READ)
		list.add_child(missing)
		return
	var game := state()
	var local: RefCounted = game.get("local") if game != null else null
	if local == null: return
	var board: Script = load(path)
	var raw: Variant = board.call("view", local.get("redesign_character"), str(local.get("character_id")))
	if not raw is Dictionary: return
	for row: Dictionary in raw.get("rows", []):
		var label := Label.new()
		label.text = "%s · %s · %s" % [str(row.get("title", "Bounty")), str(row.get("biome", "")).capitalize(),
			"Claimed" if row.get("paid") == true else "Return to board" if row.get("complete") == true else "In progress"]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", UITokens.FONT_READ)
		list.add_child(label)


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
	var realm_changed := bool(_log.call("set_realm", str(game.get("current_realm"))))
	if revision == _last_progression_revision and not realm_changed:
		return
	_last_progression_revision = revision
	_fill(
		_main_list,
		_log.call("guided_entries", progression),
		"The road ahead is unclear.",
		int(_log.call("current_index", progression))
	)
	_fill(_local_list, _log.call("local_entries", progression), "Nothing outstanding right now.")


func _read_scroll() -> void:
	if _scroll == null:
		return
	var axis := Input.get_axis("look_up", "look_down")
	if is_zero_approx(axis):
		return
	_scroll.scroll_vertical += int(roundi(axis * SCROLL_SPEED * get_process_delta_time()))


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
