extends CanvasLayer

## Name your creature. The project's first text entry, and the first time it stops
## being a game you only hold a controller for.
##
## Two input surfaces, swapped by device rather than picked once:
##
##  1. **A gamepad gets the on-screen grid.** The primary target is a ROG
##     Ally. `DisplayServer.virtual_keyboard_show()` is a mobile API and does
##     nothing on Windows, and Steam's overlay keyboard only exists when the
##     game was launched through Steam. So the game ships its own grid,
##     navigated with the d-pad or the left stick — `scripts/ui/name_entry.gd`
##     is that grid, and it is unit-tested without a screen.
##  2. **A physical keyboard gets `_field`, a real `LineEdit`** — OF25, and
##     the project's first one. Owner report: "the keyboard in game still
##     sucks. Just make it use the real keyboard." The grid used to be the
##     ONLY path, with a second, hand-rolled key reader
##     (`_unhandled_key_input`, now gone) typing straight into the same
##     buffer for a physical keyboard. That reader only ever consumed the
##     raw key EVENT (`set_input_as_handled()`); it did nothing about the
##     ACTION STATE the same keypress also set, so everything else in the
##     game that polls `Input.is_action_just_pressed()` still saw it —
##     typing `i` opened the pause menu over this panel (`inventory`'s
##     default key), space jumped, and Enter both confirmed here AND
##     registered as a `menu_confirm` poll the same frame, closing a panel
##     that had already closed itself. A focused `LineEdit` does not have
##     that problem: Godot's own Control input pipeline consumes a keystroke
##     before it becomes an action-state change, for every key Godot's text
##     editing already understands (typing, backspace, arrows, Enter). See
##     `_apply_mode()` for which device is showing and `_set_menu_deaf()` for
##     the one collision a focused Control cannot prevent on its own — the
##     pause menu's shortcut keys, read by a completely different node.
##
## `_using_gamepad` (`input_glyph.gd`'s own "last input used" signal, `HD1`)
## decides which of the two is live, recomputed every frame so a hand moving
## from the pad to the keyboard mid-prompt is seen the same frame it happens,
## the same as every other glyph in the game. Both keep the SAME buffer
## (`_entry.text`, `scripts/ui/name_entry.gd`) regardless of which is
## currently visible — two Controls that both hold "the name" is two things
## that can disagree, and the one the player is looking at is not
## necessarily the one that gets stored.
##
## Also true regardless of device:
##  - **Mouse capture has to be released.** `playground_world.gd` sets
##    MOUSE_MODE_CAPTURED at boot and nothing had ever asked for it back. A
##    captured cursor over a modal panel is a panel a desktop player cannot
##    click, and worse, the camera keeps turning under it.
##  - **The panel is modal.** Locomotion, the interact prompt and the camera
##    all have to stop, or the player names their creature while walking off
##    a cliff. Those are switched off by the sequence director, which owns
##    that decision for every beat; this node only says whether it is open.
##
## Draws by polling, like `combat_hud.gd`. The grid's cells are rebuilt only
## when the cursor moves, because restyling seventy panels every frame is
## real work for a screen that changes about once a second.

const ENTRY := preload("res://scripts/ui/name_entry.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
## For its `STORY_MODAL_GROUP` name only; see the `add_to_group` in `_ready()`.
const GAME_MENU := preload("res://scripts/ui/game_menu.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

## Frames of deafness after opening, for the reason dialogue_panel.gd gives: the
## press that opened this is still in the same frame's input state.
const OPEN_GUARD_FRAMES := 2

## Held-direction repeat. Without it, reaching 'z' from 'A' is thirty-one
## separate presses on a pad.
const REPEAT_DELAY := 0.42
const REPEAT_INTERVAL := 0.085

const CELL_SIZE := Vector2(66, 62)
const CELL_BG := Color(0.10, 0.12, 0.11, 0.85)
const CELL_BG_SELECTED := Color(0.85, 0.72, 0.30, 0.95)
const CELL_TEXT := Color(0.90, 0.93, 0.87)
const CELL_TEXT_SELECTED := Color(0.06, 0.07, 0.05)
## Done, while the name is still empty. Dimmed rather than hidden: the player has
## to be able to see what they are working towards.
const CELL_TEXT_REFUSED := Color(0.45, 0.48, 0.44)
const PANEL_BG := Color(0.05, 0.06, 0.07, 0.96)
const PANEL_BORDER := Color(0.55, 0.60, 0.50, 0.55)

const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 6

signal confirmed(creature_name: String)

var _entry: RefCounted = ENTRY.new()
var _open: bool = false
var _guard: int = 0
var _repeat_left: float = 0.0
var _held: Vector2i = Vector2i.ZERO
## Flat list of the cell panels, in the same order as name_entry's rows.
var _cells: Array[PanelContainer] = []
var _labels: Array[Label] = []
var _cell_coords: Array[Vector2i] = []
var _drawn_cursor: Vector2i = Vector2i(-1, -1)
var _drawn_valid: bool = false
var _restore_mouse: int = Input.MOUSE_MODE_CAPTURED

## Which surface is live right now. Recomputed from `INPUT_GLYPH.using_gamepad()`
## every `_physics_process`, not just at `open()` — see the file header.
var _using_gamepad: bool = true
## Guards the frame a device switch happens, same reason `_guard` guards the
## frame this whole panel opens: the press that just changed `_using_gamepad`
## is still this frame's action state, and polling it immediately below would
## fire whatever the grid's cursor happens to already sit on.
var _mode_guard: int = 0

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Box/Margin/Column/Title
@onready var _entry_label: Label = $Root/Box/Margin/Column/Entry
@onready var _keys: VBoxContainer = $Root/Box/Margin/Column/Keys
@onready var _field: LineEdit = $Root/Box/Margin/Column/Field
@onready var _hint: RichTextLabel = $Root/Box/Margin/Column/Hint


func _ready() -> void:
	_dress()
	_build_keyboard()
	_make_text_legible($Root)
	_field.max_length = ENTRY.MAX_LENGTH
	_field.text_changed.connect(_on_field_text_changed)
	_field.text_submitted.connect(_on_field_text_submitted)
	_root.visible = false
	# `game_menu.gd::STORY_MODAL_GROUP`. `_set_menu_deaf()` below (OF25) already
	# stops the shell reading buttons while this is up; the group is the same
	# rule stated where the shell can enforce it for every modal at once, and
	# the two are deliberately kept both — the deafness also covers the shell's
	# tab cycling if it were ever open first.
	add_to_group(GAME_MENU.STORY_MODAL_GROUP)
	# OW10: and the same panel claims input, so the world's verbs (the hotbar,
	# the hammer/torch hotkeys) stand down while it is up. The arbiter's own
	# lockout already covers this window, so joining changes nothing today --
	# it is here so "who owns input" has ONE membership list rather than a
	# per-panel scattering of the answer.
	add_to_group(INPUT_OWNER.GROUP)


func _dress() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	($Root/Box as PanelContainer).add_theme_stylebox_override("panel", box)


func _make_text_legible(node: Node) -> void:
	# All three share this theme property name, unlike font_color/
	# default_color below -- see dialogue_panel.gd's own note on that split.
	if node is Label or node is RichTextLabel or node is LineEdit:
		var control := node as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
	for child in node.get_children():
		_make_text_legible(child)


## Built from name_entry.ROWS rather than from a scene, so the grid on screen
## and the grid the cursor walks cannot disagree about how many cells there are.
func _build_keyboard() -> void:
	for child in _keys.get_children():
		child.queue_free()
	_cells.clear()
	_labels.clear()
	_cell_coords.clear()

	var rows: Array = ENTRY.ROWS
	for r in rows.size():
		var row: Array = rows[r]
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 6)
		_keys.add_child(line)
		for c in row.size():
			var cell := PanelContainer.new()
			cell.custom_minimum_size = CELL_SIZE
			var label := Label.new()
			label.text = ENTRY.cell_label(str(row[c]))
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 30 if str(row[c]).length() == 1 and ENTRY.cell_label(str(row[c])).length() == 1 else 22)
			cell.add_child(label)
			line.add_child(cell)
			_cells.append(cell)
			_labels.append(label)
			_cell_coords.append(Vector2i(c, r))


## --- opening and closing ----------------------------------------------------

func is_open() -> bool:
	return _open


## `subject` is what is being named, for the title: "Name your Terrapup".
## `prefill`, non-empty, seeds the buffer with an existing name -- PT-17's
## rename verb (`tab_creatures.gd`) opens this way so a stray press lands on
## the creature's current name already typed, not an empty buffer. This
## panel's own `menu_cancel` handling is backspace, not cancel (see
## `_physics_process`'s comment on why -- naming is mandatory in the opening
## and there is nothing to back out to there), so a prefilled buffer is what
## makes confirming immediately, unedited, a harmless no-op instead of the
## only way out of the panel being to type an entirely new name.
func open(subject: String, prefill: String = "") -> void:
	_entry.reset()
	if prefill != "":
		_entry.text = prefill
	_open = true
	_guard = OPEN_GUARD_FRAMES
	_mode_guard = 0
	_held = Vector2i.ZERO
	_repeat_left = 0.0
	_title.text = "Name your %s" % subject
	_root.visible = true
	_drawn_cursor = Vector2i(-1, -1)
	# Hand the cursor back. Nothing had ever asked for it since
	# playground_world.gd took it at boot, so this is the first release in the
	# project's life and the value to restore is recorded rather than assumed.
	_restore_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_using_gamepad = INPUT_GLYPH.using_gamepad()
	_apply_mode()
	_set_menu_deaf(true)
	_draw()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	Input.mouse_mode = _restore_mouse as Input.MouseMode
	if _field.has_focus():
		_field.release_focus()
	_set_menu_deaf(false)


func entry() -> RefCounted:
	return _entry


## The name as it stands. Exposed for a test that wants to check the buffer
## without reading into the entry object.
func current_text() -> String:
	return _entry.sanitised()


## --- which surface is live ----------------------------------------------------

## Shows and focuses whichever of the grid / `_field` matches `_using_gamepad`,
## and hides the other. Called at `open()` and again the frame the device
## changes (`_physics_process`, below).
func _apply_mode() -> void:
	_keys.visible = _using_gamepad
	_entry_label.visible = _using_gamepad
	_field.visible = not _using_gamepad
	if _using_gamepad:
		if _field.has_focus():
			_field.release_focus()
	else:
		# Resync from the grid's own buffer -- the player may have typed part
		# of the name on the pad before switching devices, and `_field` was
		# not live to see it.
		_field.text = _entry.text
		_field.caret_column = _field.text.length()
		_field.grab_focus()


## OF25: the actual reported defect. `game_menu.gd` reads its own open button
## and its `inventory` shortcut by polling — a completely different node from
## this one, so a focused `LineEdit` consuming a keystroke does nothing to
## stop it. `hold_input` is the shell's own mechanism for exactly this (until
## now used only by its own tabs — the backpack's target picker, the release
## ceremony); this is its first caller from outside the menu's own tree.
## Reached through `/root/Game` rather than the bare `Game` autoload name for
## the reason `scripts/story/party_seam.gd`'s header gives: this script can
## load in a process with no autoloads running at all.
func _set_menu_deaf(held: bool) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null or not game.has_method("menu"):
		return
	var menu: Object = game.call("menu")
	if menu != null and menu.has_method("hold_input"):
		menu.call("hold_input", held)


## --- input ------------------------------------------------------------------
##
## `ui_left/right/up/down` rather than the game's own `move_*` actions. The
## project's move bindings are the left stick ONLY — the d-pad is not in them —
## and a grid you cannot walk with a d-pad is not a grid a handheld player will
## use. Godot's built-in ui_* actions carry the d-pad, the left stick and the
## arrow keys at once, which is exactly the set a menu wants.

func _physics_process(delta: float) -> void:
	if not _open:
		return
	if _guard > 0:
		_guard -= 1
		return

	var now_gamepad := INPUT_GLYPH.using_gamepad()
	if now_gamepad != _using_gamepad:
		_using_gamepad = now_gamepad
		_apply_mode()
		_draw()
		_mode_guard = OPEN_GUARD_FRAMES
	if _mode_guard > 0:
		_mode_guard -= 1
		return

	if not _using_gamepad:
		# `_field` is live and focused; it reads its own keys through Godot's
		# Control input pipeline (`_on_field_text_changed`/`_submitted` below),
		# not by polling. Polling `menu_confirm` here too — the same physical
		# Enter key `_field` just reacted to — is the exact double-confirm OF25
		# reported: this panel closing once from `_on_field_text_submitted` and
		# once from this poll, the second one finding nothing left to close.
		return

	_tick_cursor(delta)

	if Input.is_action_just_pressed("menu_confirm"):
		_activate()
	elif Input.is_action_just_pressed("menu_cancel"):
		# Backspace, not cancel. Naming is mandatory
		# (docs/specs/OPENING_SEQUENCE.md), so there is nothing to back out to and B
		# would otherwise be a dead button on the one screen that needs it most.
		_entry.backspace()
		_draw()


func _tick_cursor(delta: float) -> void:
	var direction := Vector2i(
		int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
		int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	)
	if direction == Vector2i.ZERO:
		_held = Vector2i.ZERO
		_repeat_left = 0.0
		return
	if direction != _held:
		_held = direction
		_repeat_left = REPEAT_DELAY
		_entry.move(direction.x, direction.y)
		_draw()
		return
	_repeat_left -= delta
	if _repeat_left <= 0.0:
		_repeat_left = REPEAT_INTERVAL
		_entry.move(direction.x, direction.y)
		_draw()


## `_field` mirrors every edit straight into `_entry.text` — typing,
## backspace, arrow-key repositioning, all of Godot's own `LineEdit` editing
## are Godot's job, not this file's; this just keeps the one real buffer in
## step with what the box on screen shows. `max_length` (`_ready()`) is the
## native `LineEdit` property doing the same job `name_entry.gd::type()`'s
## own length check does for the grid, so nothing here re-enforces it.
func _on_field_text_changed(new_text: String) -> void:
	_entry.text = new_text
	_draw()


## The ONLY way a physical keyboard confirms (OF25). Firing `_confirm()` from
## both this AND a `menu_confirm` poll below was the reported double-confirm;
## `_physics_process`'s own `_using_gamepad` gate is the other half of why
## that cannot happen any more.
func _on_field_text_submitted(_new_text: String) -> void:
	if not _open:
		return
	if _entry.is_valid():
		_confirm()


func _activate() -> void:
	match str(_entry.activate()):
		"done":
			_confirm()
		_:
			_draw()


func _confirm() -> void:
	# Typed explicitly rather than inferred. `_entry` is a bare RefCounted — the
	# grid is loaded by path, not by class — so `sanitised()` has no declared
	# return type to infer FROM, and `:=` here is a parse error that stops this
	# whole file loading. The scene then instances as a scriptless CanvasLayer:
	# no panel, no grid, and `confirmed` is not even a signal to connect to.
	# Nothing caught it because the unit tests exercise `name_entry.gd`, which is
	# fine, and nothing loads the panel.
	var chosen: String = _entry.sanitised()
	if chosen == "":
		return
	close()
	confirmed.emit(chosen)


## --- drawing ----------------------------------------------------------------

## OF25: the hint below the panel used to be drawn for the grid only and
## shown to both devices — a keyboard player was told "[Enter] type" (that
## icon meant "confirm this grid cell", a cell they were never looking at)
## and "[Esc] delete" (`GLYPHS["cancel"]`'s keyboard icon, which is really
## Escape and does not delete anything for a keyboard player at all; the
## grid's own B/Escape-means-backspace mapping is a gamepad-only substitution
## — see `_physics_process`'s comment on why `menu_cancel` means backspace
## there). Both ids are real (`input_glyph.gd`'s `GLYPHS`); they were just
## being read for a control surface the current device was not using. Now
## each device only ever sees the hint for the surface it is actually
## looking at, and `confirm`'s icon is accurate on both — Enter on a
## keyboard, A on a pad — so it is the only one still shared.
func _draw() -> void:
	var valid: bool = _entry.is_valid()
	var confirm_glyph := INPUT_GLYPH.icon("confirm")
	if _using_gamepad:
		var caret := "_" if _entry.text.length() < ENTRY.MAX_LENGTH else ""
		_entry_label.text = "%s%s" % [_entry.text, caret]
		var glyphs := "%s type    %s delete" % [confirm_glyph, INPUT_GLYPH.icon("cancel")]
		_hint.text = "%s    OK to finish" % glyphs if valid \
			else "%s    every creature gets a name" % glyphs
	else:
		_hint.text = "%s    finishes the name" % confirm_glyph if valid \
			else "every creature gets a name"

	if not _using_gamepad:
		return  # the grid is hidden; nothing below to restyle

	var cursor := Vector2i(int(_entry.column), int(_entry.row))
	if cursor == _drawn_cursor and valid == _drawn_valid:
		return
	_drawn_cursor = cursor
	_drawn_valid = valid

	for i in _cells.size():
		var selected := _cell_coords[i] == cursor
		var style := StyleBoxFlat.new()
		style.bg_color = CELL_BG_SELECTED if selected else CELL_BG
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		_cells[i].add_theme_stylebox_override("panel", style)
		var is_done := _labels[i].text == ENTRY.cell_label(ENTRY.DONE)
		var colour := CELL_TEXT_SELECTED if selected else CELL_TEXT
		if is_done and not valid and not selected:
			colour = CELL_TEXT_REFUSED
		_labels[i].add_theme_color_override("font_color", colour)
