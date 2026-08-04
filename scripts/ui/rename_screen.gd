extends "res://scripts/ui/screen.gd"

## Giving a pal a name, with a stick.
##
## `pal_instance.gd` has had `rename()`, `nickname` and `clear_nickname()` since
## the day it landed and NOTHING CALLED THEM. A blind reviewer reading the M4
## evidence put it exactly right: every pal in the session was `Pal1`..`Pal5`,
## identical to its slot index, so "nickname" was indistinguishable from
## "auto-assigned default label". A name the player cannot change is not a
## nickname. This screen is the missing half.
##
## A CHARACTER GRID, NOT A LineEdit. `screen.gd` already says why for the mouse —
## "this is a controller-first game and there is no mouse-look action in the input
## map at all" — and the keyboard is the same story: the primary device is a ROG
## Ally, and a text field there is a caret nobody can place. Every input this
## screen takes is `move_*` plus `menu_confirm` plus `menu_cancel`, which is
## exactly what the party menu takes, so there is nothing new to learn.
##
## The keyboard path exists (`_input` below) but it is the SECOND way in, not the
## first. If the two ever disagree, the grid is right.
##
## Pull, don't push, like every other screen: the pal is read every frame rather
## than snapshotted, so a name entry left open while something else changes the
## pal cannot end up describing a creature that no longer exists. The one piece of
## state this screen does own is the string being typed, because that is the whole
## point of it and nothing else in the game knows about it yet.

# STYLE is inherited from screen.gd. Declaring it again here is a parse error,
# which is the language making the same point party_screen.gd makes: there is one
# set of UI colours and one text treatment.

## The longest name a pal can have. TUNABLE, and deliberately a const rather than
## a line in `data/config/party.json` — that file's own header says it may only
## hold values that change how a pal GROWS or how its worth is READ, and the width
## of a text field is neither. It is here because a wider name overflows the slot
## row on the party screen, which is a layout fact about this project's UI and not
## a design decision anybody should be able to change from data.
const MAX_NAME := 12

## How long a refusal stays on screen. The party screen uses 2.0s for the same
## class of message; this one runs slightly longer because the player is mid-task
## and reading a grid rather than a list. Tunable.
const NOTICE_SECONDS := 2.6

## The keys, one string per row, thirteen to a row.
##
## Thirteen because twenty-six divides by it: uppercase is exactly two rows,
## lowercase exactly two, and ten digits plus three punctuation keys exactly one.
## A ragged grid is navigable but not PREDICTABLE — press down from the end of a
## full row into a short one and pressing up does not bring you back — and
## predictable is the only property that matters when the cursor is on a stick.
##
## ASCII ONLY, and that is a rule rather than an accident. The first party footer
## used U+2195 for "up/down" and the project font had no glyph for it, so the one
## prompt telling the player how to move rendered as `[$]`. A name entry that can
## produce a character the font cannot draw is the same bug with the player's own
## pal's name in it.
const KEYS := [
	"ABCDEFGHIJKLM",
	"NOPQRSTUVWXYZ",
	"abcdefghijklm",
	"nopqrstuvwxyz",
	"0123456789-'.",
]
const COLUMNS := 13

## The three keys that are words instead of letters. Their order is the order you
## need them in: a space while typing, a correction, then done.
const COMMANDS := ["Space", "Backspace", "Done"]
const COMMAND_SPACE := 0
const COMMAND_BACKSPACE := 1
const COMMAND_DONE := 2

## Whoever is being renamed. Held as an Object rather than typed, for
## `party_screen.gd`'s reason: this is another agent's file and the screen should
## keep working if it grows a base class.
var _member: Object = null
var _typed: String = ""

## The cursor, as a row and a column, because the grid is two-dimensional and the
## base class's cursor is a single index. Both are kept: `_row`/`_col` are what
## `navigate()` moves, and `set_focus_index()` is fed the flattened result so the
## base class is never holding a stale number and `on_activate()` still arrives
## the way `screen.gd` documents it.
var _row: int = 0
var _col: int = 0

## The column to return to when leaving the command row upwards.
##
## Without it, going down into "Done" and back up dumps you at whatever column the
## proportional mapping chose, which is not where you were, and the cursor feels
## like it slipped rather than moved.
var _char_col: int = 0

var _notice: String = ""
var _notice_left: float = 0.0

var _cells: Array[PanelContainer] = []
var _glyphs: Array[Label] = []
## One stylebox each, shared by every cell, built once.
##
## The party screen builds a fresh `panel_style()` per row per frame and gets away
## with it at five rows. Sixty-eight would be sixty-eight StyleBoxFlat allocations
## every frame of every rename, so the styles are made once and only the two cells
## the cursor left and arrived at are touched. See `_draw_focus`.
var _cell_idle: StyleBoxFlat = null
var _cell_focus: StyleBoxFlat = null
## Which cell currently wears the focus stylebox, or -1 when nothing does.
var _drawn: int = -1
## Every character the grid can produce, for validating keyboard input.
var _allowed: String = ""

@onready var _entry: PanelContainer = $Body/Entry
@onready var _who: Label = $Body/Entry/Pad/Lines/Who
@onready var _typed_label: Label = $Body/Entry/Pad/Lines/Row/Typed
@onready var _count: Label = $Body/Entry/Pad/Lines/Row/Count
@onready var _grid: GridContainer = $Body/Grid
@onready var _commands: HBoxContainer = $Body/Commands
@onready var _notice_label: RichTextLabel = $Body/Notice


func _ready() -> void:
	# Cells are built BEFORE the base class runs, on purpose and for exactly the
	# reason party_screen.gd gives: `screen.gd` walks the whole tree once to
	# outline and shadow every label in it, and a cell duplicated after that walk
	# would be the one unreadable thing on a screen full of single characters —
	# which is the hardest kind of text to read without an outline.
	_build_cells()
	_entry.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE)
	)
	super()


func _build_cells() -> void:
	var template := _grid.get_node_or_null(^"CellTemplate") as PanelContainer
	if template == null:
		push_error("rename screen has no CellTemplate cell to duplicate")
		return
	_grid.remove_child(template)

	_cell_idle = STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE)
	_cell_focus = STYLE.panel_style(STYLE.ROW_FOCUS_BG, STYLE.ROW_FOCUS_EDGE)

	for row: String in KEYS:
		_allowed += row
		for i in row.length():
			# Named by position rather than by the character they carry: node names
			# may not contain "." and the grid has a full stop on it, which would
			# have been a rename that worked for sixty-four keys and renamed nothing
			# on the sixty-fifth.
			_add_cell(template, _grid, row[i], "Key%d" % _cells.size())
	# The space is legal in a name but has no glyph, so on the grid it is the WORD
	# key below rather than a blank cell — a blank cell in a grid reads as a key
	# that failed to draw. It still has to be in `_allowed`, because the keyboard
	# path validates against that string and a space bar that did nothing here
	# would be the one key a typist reaches for without looking.
	_allowed += " "

	for i in COMMANDS.size():
		var cell := _add_cell(template, _commands, str(COMMANDS[i]), "Command%d" % i)
		if cell != null:
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	template.queue_free()


func _add_cell(
	template: PanelContainer, parent: Container, text: String, cell_name: String
) -> PanelContainer:
	var cell := template.duplicate() as PanelContainer
	if cell == null:
		return null
	cell.name = cell_name
	cell.visible = true
	cell.add_theme_stylebox_override("panel", _cell_idle)
	var glyph := cell.get_node(^"Pad/Glyph") as Label
	glyph.text = text
	# Word keys are set smaller than letter keys so "Backspace" does not force the
	# command row twice as tall as the alphabet above it.
	if text.length() > 1:
		glyph.add_theme_font_size_override("font_size", 26)
	parent.add_child(cell)
	_cells.append(cell)
	_glyphs.append(glyph)
	return cell


# --------------------------------------------------------------------- opening

## Point the screen at a pal. Call this BEFORE pushing it.
##
## Not `on_pushed()`, because `on_pushed()` takes no arguments and the stack is
## not going to grow a way to pass one — the stack's whole job is that it does not
## know what a screen contains. The party screen sets the subject and then pushes,
## which is two calls in one place rather than a stack that knows about pals.
func open_for(member: Object) -> void:
	_member = member
	# Seeded with the nickname it ALREADY HAS rather than with the species name.
	# Those are different: `display()` falls back to the species name when there is
	# no nickname, so seeding from `display()` would make "keep the species name"
	# indistinguishable from "I typed Bramblit myself", and the player renaming a
	# pal for the second time would have to retype the name they chose the first
	# time. Empty means empty on purpose.
	_typed = ""
	if member != null:
		var current := str(member.get("nickname"))
		if current != "" and current != "<null>":
			_typed = current.substr(0, MAX_NAME)
	_row = 0
	_col = 0
	_char_col = 0
	_notice = ""
	_notice_left = 0.0
	# Forces `_draw_focus` to restyle on the first frame rather than assuming the
	# cell it highlighted during the last rename is still the right one.
	_drawn = -1
	set_focus_index(0)


func on_popped() -> void:
	# Let go of the pal. A screen that keeps a reference to a creature the player
	# may since have released is a screen that can quietly resurrect it on the next
	# frame it draws.
	_member = null


# --------------------------------------------------------------------- drawing

func screen_title() -> String:
	if _member == null:
		return "Rename"
	return "Rename    %s" % _display_of(_member)


func focus_count() -> int:
	return _cells.size()


## Both directions, both plainly spelled out, and no arrow glyph anywhere — see
## the note on `KEYS` and the one in `party_screen.hints()` about `[$]`.
##
## The A verb NAMES THE KEY UNDER THE CURSOR rather than saying "Select". On a
## grid of sixty-eight keys, "Select" is the least informative word available, and
## the footer is the only place a screenshot can tell you what a press would have
## done.
func hints() -> Array[Array]:
	var full: bool = _typed.length() >= MAX_NAME
	var empty: bool = _typed.strip_edges().is_empty()
	var verb := "Add"
	var ready := not full
	var index := focus_index()
	var command := _command_at(index)
	match command:
		COMMAND_SPACE:
			verb = "Add a space"
		COMMAND_BACKSPACE:
			verb = "Delete a letter"
			ready = not _typed.is_empty()
		COMMAND_DONE:
			verb = "Save the name"
			ready = not empty
		_:
			verb = "Add  %s" % _character_at(index)

	var rows: Array[Array] = []
	rows.append(["Up/Down/Left/Right", "Move", true])
	rows.append(["A", verb, ready])
	rows.append(["B", "Cancel", true])
	return rows


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""
	_draw_entry()
	_draw_focus()
	_draw_notice()


func _draw_entry() -> void:
	var full: bool = _typed.length() >= MAX_NAME

	if _member == null:
		_who.text = "No pal to rename"
	else:
		var species := str(_member.get("display_name"))
		if species == "" or species == "<null>":
			species = "This pal"
		var current := str(_member.get("nickname"))
		if current == "" or current == "<null>":
			_who.text = "%s - no name of its own yet" % species
		else:
			_who.text = "%s - currently called %s" % [species, current]
	_who.modulate = Color.html(STYLE.INK_DIM)

	# The caret is an underscore, and it DISAPPEARS at the cap. That is one of the
	# three ways the limit is visible at once: the caret stops offering a place for
	# the next letter, the counter goes amber, and pressing a key says so out loud.
	# The failure being designed against is a keystroke that is silently dropped,
	# which is indistinguishable from a controller that missed the press.
	_typed_label.text = _typed if full else _typed + "_"
	_typed_label.modulate = Color.WHITE if not _typed.is_empty() else Color.html(STYLE.INK_DIM)

	_count.text = "%d / %d" % [_typed.length(), MAX_NAME]
	_count.modulate = Color.html(STYLE.WARN) if full else Color.html(STYLE.INK_DIM)

	# Dimmed, not hidden, and still pressable — the same discipline as the party
	# screen's "Send out": the verb dims to say it will not work, and pressing it
	# anyway answers with a reason instead of nothing. `ui_style` puts it plainly:
	# a widget that vanishes reads as broken, one that changes reads as an answer.
	var backspace := _command_label(COMMAND_BACKSPACE)
	if backspace != null:
		backspace.modulate = Color.WHITE if not _typed.is_empty() else Color.html(STYLE.INK_DIM)
	var done := _command_label(COMMAND_DONE)
	if done != null:
		var empty: bool = _typed.strip_edges().is_empty()
		done.modulate = Color.html(STYLE.GOOD) if not empty else Color.html(STYLE.INK_DIM)


## Move the highlight, touching only the two cells that changed.
##
## Restyling all sixty-eight every frame would work and would also allocate
## sixty-eight styleboxes a frame; the two shared boxes built in `_build_cells`
## exist so this can be two assignments instead.
func _draw_focus() -> void:
	var index := focus_index()
	if index == _drawn:
		return
	if _drawn >= 0 and _drawn < _cells.size():
		_cells[_drawn].add_theme_stylebox_override("panel", _cell_idle)
	if index >= 0 and index < _cells.size():
		_cells[index].add_theme_stylebox_override("panel", _cell_focus)
	_drawn = index


func _draw_notice() -> void:
	if _notice == "":
		if _notice_label.text != "":
			_notice_label.text = ""
		return
	var wanted := "[center][color=#%s]%s[/color][/center]" % [STYLE.WARN, _notice]
	# Compared before assigning: a RichTextLabel re-parses its bbcode on every
	# write, and this line is identical for every frame of the two seconds it is up.
	if _notice_label.text != wanted:
		_notice_label.text = wanted


# ------------------------------------------------------------------ the cursor

## Which flat cell index a row and column are.
##
## The command row is not part of the grid — it is a separate HBoxContainer with
## three wide cells — but it is addressed as though it were row five, so there is
## one cursor rather than a cursor plus a mode flag.
func _cell_index() -> int:
	if _row < KEYS.size():
		return _row * COLUMNS + _col
	return KEYS.size() * COLUMNS + _col


## The character a flat index types, or "" if that index is a command.
func _character_at(index: int) -> String:
	if index < 0 or index >= KEYS.size() * COLUMNS:
		return ""
	var row: String = str(KEYS[index / COLUMNS])
	return row[index % COLUMNS]


## Which command a flat index is, or -1 if it is a letter.
func _command_at(index: int) -> int:
	var first := KEYS.size() * COLUMNS
	if index < first or index >= first + COMMANDS.size():
		return -1
	return index - first


func _command_label(command: int) -> Label:
	var index := KEYS.size() * COLUMNS + command
	if index < 0 or index >= _glyphs.size():
		return null
	return _glyphs[index]


## Two-dimensional movement, replacing the base class's linear cursor.
##
## `screen.gd` moves a single index on `dy` and hands `dx` to `on_nudge`, which is
## right for a list and wrong for a grid — left and right here are movement, not a
## value being changed. The base's index is still kept in step at the end, so
## `confirm()` and `on_activate()` work exactly as `screen.gd` documents them and
## nothing downstream has to know this screen is special.
##
## Both axes WRAP, for the reason `screen.gd` gives about the party list: a
## selection that stops dead at the edge reads as the stick having disconnected,
## and on a thirteen-wide grid wrapping off the end of a row is a much shorter
## journey than walking back.
func navigate(dx: int, dy: int) -> void:
	if dy != 0:
		_move_vertical(dy)
	if dx != 0:
		_move_horizontal(dx)
	set_focus_index(_cell_index())


func _move_vertical(dy: int) -> void:
	var rows := KEYS.size() + 1
	var wanted: int = posmod(_row + dy, rows)
	if _row < KEYS.size():
		_char_col = _col
	if wanted < KEYS.size():
		# Coming back to the alphabet lands on the column you left it from, not on
		# a column derived from where you were in the command row. The cursor should
		# feel like it went away and came back, not like it drifted.
		_col = clampi(_char_col, 0, COLUMNS - 1)
	else:
		# Going down into three wide keys from thirteen narrow ones, mapped by
		# position rather than by index: the leftmost letters reach Space, the
		# middle reach Backspace, the rightmost reach Done, which is where each key
		# physically sits.
		_col = clampi(_char_col * COMMANDS.size() / COLUMNS, 0, COMMANDS.size() - 1)
	_row = wanted


func _move_horizontal(dx: int) -> void:
	var width: int = COLUMNS if _row < KEYS.size() else COMMANDS.size()
	_col = posmod(_col + dx, width)
	if _row < KEYS.size():
		_char_col = _col


# ------------------------------------------------------------------- the verbs

func on_activate(index: int) -> void:
	match _command_at(index):
		COMMAND_SPACE:
			_append(" ")
		COMMAND_BACKSPACE:
			_backspace()
		COMMAND_DONE:
			_commit()
		_:
			_append(_character_at(index))


## B leaves the name alone and goes back to the party.
##
## Returning false hands the pop to the stack, which is the whole contract in
## `screen.gd`: "Return true to keep the screen open". B does NOT delete a
## character — Backspace is a key on the grid, and a cancel button that sometimes
## means "undo one letter" and sometimes means "throw the whole thing away" is a
## button the player has to test before trusting.
func cancel() -> bool:
	return false


func _append(character: String) -> void:
	if character == "":
		return
	if _typed.length() >= MAX_NAME:
		# Said out loud rather than swallowed, for `combat_hud._on_catch_refused`'s
		# reason that this project keeps relearning: "I pressed it and nothing
		# happened" is indistinguishable from a bug.
		_say("%d letters is the longest a name can be" % MAX_NAME)
		return
	_typed += character


func _backspace() -> void:
	if _typed.is_empty():
		_say("there is nothing to delete yet")
		return
	_typed = _typed.substr(0, _typed.length() - 1)


## Hand the name to the pal, and only close if it took it.
##
## The empty case is checked BY CALLING `rename()` rather than by testing the
## string here first. `pal_instance.rename()` already owns the rule — it strips
## the edges and returns false for an all-whitespace name, so a pal cannot end up
## nameless — and a second copy of that rule in the UI is a second copy that can
## disagree with it. The screen's job is to turn the false into a sentence.
func _commit() -> void:
	if _member == null:
		_say("there is no pal to rename")
		return
	if not _member.has_method("rename"):
		_say("this pal cannot be renamed")
		return
	if bool(_member.call("rename", _typed)):
		_close()
		return
	_say("a pal needs a name - pick some letters first")


## Back to whatever pushed this. Asked of the parent by method rather than by
## class, so a stack that grows a base class or a test that stands this screen up
## under a plain Node does not crash on the way out.
func _close() -> void:
	var stack := get_parent()
	if stack != null and stack.has_method("pop"):
		stack.call("pop")


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS


# ---------------------------------------------------------------- the keyboard

## Typing, for whoever is at a desk. The SECOND way in; the grid is the first.
##
## Deliberately narrow. It handles printable characters and Backspace and nothing
## else: Enter and Escape are already `menu_confirm` and `menu_cancel`, the stack
## polls both in `_physics_process`, and a screen that also handled them here
## would act on one press twice — which is the exact failure `screen_stack.gd`'s
## header warns about ("the player would lose two screens per press").
##
## Only characters the GRID can produce are accepted. A keyboard that can type a
## character the grid cannot is a keyboard that can put a glyph the project font
## has never been checked against into the player's pal's name, and this project
## has already shipped one `[$]`.
func _input(event: InputEvent) -> void:
	if not visible or not is_screen_active():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return

	if key.keycode == KEY_BACKSPACE:
		_backspace()
		_release_navigation()
		get_viewport().set_input_as_handled()
		return

	var unicode := key.unicode
	if unicode < 32 or unicode == 127:
		return
	var character := String.chr(unicode)
	if not _allowed.contains(character):
		return
	_append(character)
	_release_navigation()
	get_viewport().set_input_as_handled()


## Stop a typed letter from ALSO walking the cursor.
##
## WASD are `move_left`/`move_right`/`move_forward`/`move_back` in the input map,
## which is what the stack reads to move the selection — so on a keyboard, typing
## the "a" in "Bramble" would type the letter and slide the highlight one cell
## left at the same time. `set_input_as_handled()` does not help: action state is
## read from `Input`, not from the event queue, and a handled event has still
## already updated it.
##
## Releasing the actions by hand does help, because `Input` only changes an
## action's state when an event arrives, so the release stands until the key is
## physically let go and pressed again. The highlight stays where the player left
## it, and the pad is untouched — a stick held over sends motion events every
## frame and re-presses the action immediately.
func _release_navigation() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			Input.action_release(action)


## The name to show, matching `party_screen._display_of` exactly. `display()` is
## the pal's own answer to "nickname if set, else species name" and neither screen
## second-guesses it.
func _display_of(member: Object) -> String:
	if member.has_method("display"):
		return str(member.call("display"))
	var fallback := str(member.get("display_name"))
	return fallback if fallback != "" and fallback != "<null>" else "?"
