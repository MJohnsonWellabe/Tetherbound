extends CanvasLayer

## Name your pal. The project's first text entry, and the first time it stops
## being a game you only hold a controller for.
##
## Three things are happening here that have never happened in this project
## before, and each of them is a way for the beat to break on the owner's
## handheld while every test stays green:
##
##  1. **There is no keyboard.** The primary target is a ROG Ally.
##     `DisplayServer.virtual_keyboard_show()` is a mobile API and does nothing
##     on Windows, and Steam's overlay keyboard only exists when the game was
##     launched through Steam. So the game ships its own grid, navigated with the
##     d-pad or the left stick — `scripts/ui/name_entry.gd` is that grid, and it
##     is unit-tested without a screen.
##  2. **Mouse capture has to be released.** `playground_world.gd` sets
##     MOUSE_MODE_CAPTURED at boot and nothing had ever asked for it back. A
##     captured cursor over a modal panel is a panel a desktop player cannot
##     click, and worse, the camera keeps turning under it.
##  3. **The panel is modal.** Locomotion, the interact prompt and the camera all
##     have to stop, or the player names their pal while walking off a cliff.
##     Those are switched off by the sequence director, which owns that decision
##     for every beat; this node only says whether it is open.
##
## Draws by polling, like `combat_hud.gd`. The cells are rebuilt only when the
## cursor moves, because restyling seventy panels every frame is real work for a
## screen that changes about once a second.

const ENTRY := preload("res://scripts/ui/name_entry.gd")

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

signal confirmed(pal_name: String)

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

@onready var _root: Control = $Root
@onready var _title: Label = $Root/Box/Margin/Column/Title
@onready var _entry_label: Label = $Root/Box/Margin/Column/Entry
@onready var _keys: VBoxContainer = $Root/Box/Margin/Column/Keys
@onready var _hint: Label = $Root/Box/Margin/Column/Hint


func _ready() -> void:
	_dress()
	_build_keyboard()
	_make_text_legible($Root)
	_root.visible = false


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
	if node is Label:
		var label := node as Label
		label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		label.add_theme_color_override("font_outline_color", OUTLINE)
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
func open(subject: String) -> void:
	_entry.reset()
	_open = true
	_guard = OPEN_GUARD_FRAMES
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
	_draw()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	Input.mouse_mode = _restore_mouse as Input.MouseMode


func entry() -> RefCounted:
	return _entry


## The name as it stands. Exposed for a test that wants to check the buffer
## without reading into the entry object.
func current_text() -> String:
	return _entry.sanitised()


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

	_tick_cursor(delta)

	if Input.is_action_just_pressed("menu_confirm"):
		_activate()
	elif Input.is_action_just_pressed("menu_cancel"):
		# Backspace, not cancel. Naming is mandatory
		# (docs/OPENING_SEQUENCE.md), so there is nothing to back out to and B
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


## A physical keyboard types straight into the same buffer.
##
## Handled here rather than through a LineEdit so there is exactly one buffer.
## Two Controls that both hold "the name" is two things that can disagree, and
## the one the player is looking at is not necessarily the one that gets stored.
func _unhandled_key_input(event: InputEvent) -> void:
	if not _open:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_BACKSPACE:
			_entry.backspace()
			_draw()
			get_viewport().set_input_as_handled()
			return
		KEY_ENTER, KEY_KP_ENTER:
			if _entry.is_valid():
				_confirm()
			get_viewport().set_input_as_handled()
			return
	var unicode := key.unicode
	if unicode >= 32 and unicode < 127:
		_entry.type(char(unicode))
		_draw()
		get_viewport().set_input_as_handled()


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

func _draw() -> void:
	var caret := "_" if _entry.text.length() < ENTRY.MAX_LENGTH else ""
	_entry_label.text = "%s%s" % [_entry.text, caret]
	var valid: bool = _entry.is_valid()
	_hint.text = "[A] type    [B] delete    OK to finish" if valid \
		else "[A] type    [B] delete    every pal gets a name"

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
