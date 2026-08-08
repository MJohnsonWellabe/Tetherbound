extends "res://scripts/ui/menu_tab.gd"

## Settings. Controls first, and for now Controls only.
##
## The owner's ask was "I should be able to map controls to whatever buttons I
## want", so every row shows BOTH bindings — the keyboard one and the gamepad
## one — and either can be changed from the same screen. A handheld player and a
## desk player are looking at the same page.
##
## EVERYTHING HERE IS REACHABLE WITH A STICK ALONE. Each cell is a focusable
## Button and every verb is a press of it: no drag, no right-click, no hover, no
## keyboard shortcut that has no gamepad twin. The cursor is Godot's built-in
## `ui_*` focus navigation, which is exactly why `ui_*` actions are not in the
## rebindable list — they are the road back out of any mistake made on this
## screen.
##
## Rebinding reads RAW EVENTS rather than actions, in `_input`. It has to: the
## whole point is to catch a button before the input map has an opinion about
## what it means, and half the time the button being pressed is one whose
## meaning is about to change.
##
## Sections are a loop over `settings.sections` in data/config/menu.json. Today
## that list has one entry. Display and audio are a JSON entry plus a `_build_*`
## method here, which is the shape the rest of the menu already uses.

const CONFIG_PATH := "res://data/config/menu.json"
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")

## How long the global reset stays armed after the first press. Long enough to
## make the second press deliberate, short enough that it cannot be a surprise
## five minutes later.
const CONFIRM_SECONDS := 4.0

## Frames the shell stays deaf after a capture ends. The button that was just
## bound is still physically down, and without this a fresh `menu_cancel`
## binding would close the menu on the press that created it.
const SETTLE_FRAMES := 3

const LABEL_WIDTH := 440
const CELL_WIDTH := 320
const RESET_WIDTH := 150

const COLOUR_DEFAULT := Color(0.87, 0.89, 0.84)
const COLOUR_CHANGED := Color(0.851, 0.702, 0.251)
const COLOUR_CLASH := Color(0.85, 0.55, 0.25)
const COLOUR_QUIET := Color(0.55, 0.57, 0.52)

var _config: Dictionary = {}
var _rows: Array = []
var _reset_all_button: Button = null
var _scroll: ScrollContainer = null

var _capturing: bool = false
var _capture_action: String = ""
var _capture_slot: String = ""
var _settle: int = 0

var _confirm_left: float = 0.0


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()
	_capturing = false
	_confirm_left = 0.0

	_config = _read_config()
	var bindings: RefCounted = _bindings()
	if bindings == null:
		var broken := Label.new()
		broken.text = "Controls are unavailable: the binding table did not load."
		add_child(broken)
		return

	var settings: Dictionary = _config.get("settings", {}) as Dictionary
	var sections: Variant = settings.get("sections", [])
	if typeof(sections) != TYPE_ARRAY:
		sections = []

	for entry in sections as Array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var section := entry as Dictionary
		match str(section.get("id", "")):
			"controls":
				_build_controls(section, settings.get("controls", {}) as Dictionary)
			_:
				# A section named in JSON with nobody to draw it would otherwise be
				# an invisible gap. Say so rather than skip silently.
				push_warning("settings section '%s' has no builder" % section.get("id", "?"))
	poll()


# --- the Controls section ---------------------------------------------------


func _build_controls(section: Dictionary, controls: Dictionary) -> void:
	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 30)
	heading.text = str(section.get("label", "Controls"))
	add_child(heading)

	# The global reset sits ABOVE the rows on purpose: it is the way out of a
	# layout the player has broken, and the way out should not be at the bottom
	# of a list they may no longer be able to scroll.
	_reset_all_button = Button.new()
	_reset_all_button.custom_minimum_size = Vector2(560, 56)
	_reset_all_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_reset_all_button.focus_mode = Control.FOCUS_ALL
	_reset_all_button.text = "  Reset every control to its default"
	_reset_all_button.pressed.connect(_on_reset_all)
	add_child(_reset_all_button)

	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", COLOUR_QUIET)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Said on the screen as well as in the footer, because a player who has
	# rebound their way out of the menu cannot read the footer.
	hint.text = "A on a binding to change it, then press the button you want. B leaves it alone. From anywhere in the game, hold Menu + View on the pad — or F10 — for a second and a half to put every control back."
	add_child(hint)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	_scroll.add_child(list)

	list.add_child(_column_header())

	var groups: Variant = controls.get("groups", [])
	if typeof(groups) != TYPE_ARRAY:
		return
	var labels: Dictionary = controls.get("labels", {}) as Dictionary
	for entry in groups as Array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		_build_group(list, entry as Dictionary, labels)


func _column_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for pair in [["", LABEL_WIDTH], ["Keyboard / mouse", CELL_WIDTH], ["Gamepad", CELL_WIDTH]]:
		var cell := Label.new()
		cell.custom_minimum_size = Vector2(float(pair[1]), 0)
		cell.add_theme_font_size_override("font_size", 22)
		cell.add_theme_color_override("font_color", COLOUR_QUIET)
		cell.text = str(pair[0])
		row.add_child(cell)
	return row


func _build_group(list: VBoxContainer, group: Dictionary, labels: Dictionary) -> void:
	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", COLOUR_CHANGED)
	heading.text = "\n%s" % str(group.get("name", ""))
	list.add_child(heading)

	var note := str(group.get("note", ""))
	if not note.is_empty():
		var note_label := Label.new()
		note_label.add_theme_font_size_override("font_size", 20)
		note_label.add_theme_color_override("font_color", COLOUR_QUIET)
		note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note_label.custom_minimum_size = Vector2(1100, 0)
		note_label.text = note
		list.add_child(note_label)

	var actions: Variant = group.get("actions", [])
	if typeof(actions) != TYPE_ARRAY:
		return
	var bindings: RefCounted = _bindings()
	for action in actions as Array:
		var name := str(action)
		# An action in the JSON that the input map has never heard of would draw
		# a row that cannot possibly work. tests/test_controls.gd fails the build
		# on this; skipping here keeps the rest of the screen usable meanwhile.
		if not bool(bindings.call("has", name)):
			push_warning("settings lists an action that is not in the input map: %s" % name)
			continue
		list.add_child(_build_row(name, str(labels.get(name, name))))


func _build_row(action: String, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.text = label_text
	row.add_child(name_label)

	var record := {"action": action, "label": label_text, "name_label": name_label}
	for slot in ["keyboard", "gamepad"]:
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(CELL_WIDTH, 52)
		cell.clip_text = true
		cell.focus_mode = Control.FOCUS_ALL
		var captured_slot := str(slot)
		cell.pressed.connect(func() -> void: _start_capture(action, captured_slot))
		cell.focus_entered.connect(func() -> void: _keep_visible(cell))
		row.add_child(cell)
		record[slot] = cell

	var reset := Button.new()
	reset.custom_minimum_size = Vector2(RESET_WIDTH, 52)
	reset.focus_mode = Control.FOCUS_ALL
	reset.text = "Default"
	reset.pressed.connect(func() -> void: _on_reset_action(action))
	reset.focus_entered.connect(func() -> void: _keep_visible(reset))
	row.add_child(reset)
	record["reset"] = reset

	_rows.append(record)
	return row


func _keep_visible(control: Control) -> void:
	if _scroll != null:
		_scroll.ensure_control_visible(control)


# --- the frame loop ---------------------------------------------------------


func first_focus() -> Control:
	if not _rows.is_empty():
		return _rows[0]["keyboard"]
	return _reset_all_button


## Constant. The row set comes from JSON and does not change while the game
## runs, and a rebuild would destroy the focused node — which on a controller
## means the cursor stops moving. Values are written by poll().
func revision() -> int:
	return 0


func poll() -> void:
	var bindings: RefCounted = _bindings()
	if bindings == null:
		return

	# The shell polls actions every frame and would act on the very buttons
	# being rebound. Hold it deaf through the capture and for a few frames after.
	if _capturing or _settle > 0:
		_settle = maxi(0, _settle - 1)
		_hold_shell(true)
	else:
		_hold_shell(false)

	if _confirm_left > 0.0:
		_confirm_left -= get_process_delta_time()
		if _confirm_left <= 0.0 and _reset_all_button != null:
			_reset_all_button.text = "  Reset every control to its default"

	for record in _rows:
		var action := str(record["action"])
		var clashes: Array = bindings.call("current_conflicts", action)
		(record["name_label"] as Label).add_theme_color_override(
			"font_color", COLOUR_CLASH if not clashes.is_empty() else COLOUR_DEFAULT
		)
		for slot in ["keyboard", "gamepad"]:
			var cell: Button = record[slot]
			if _capturing and _capture_action == action and _capture_slot == slot:
				cell.text = "Press a key…" if slot == "keyboard" else "Press a button…"
				cell.add_theme_color_override("font_color", COLOUR_CHANGED)
				continue
			var event: InputEvent = bindings.call("binding", action, slot)
			cell.text = str(bindings.call("describe", event))
			cell.add_theme_color_override(
				"font_color",
				COLOUR_CHANGED if bool(bindings.call("is_overridden", action, slot)) else COLOUR_DEFAULT
			)


# --- capturing --------------------------------------------------------------


func _start_capture(action: String, slot: String) -> void:
	if _capturing:
		return
	_capturing = true
	_capture_action = action
	_capture_slot = slot
	_hold_shell(true)
	say("Press what you want for %s. B or Escape leaves it alone." % _label_of(action))


func _end_capture(message: String) -> void:
	_capturing = false
	_capture_action = ""
	_capture_slot = ""
	_settle = SETTLE_FRAMES
	say(message)


## The raw input path.
##
## `_input` runs before the Control tree sees the event, which is the only place
## a button can be read without the focused Button swallowing it first. Events
## taken here are marked handled so the cursor does not also move.
func _input(event: InputEvent) -> void:
	if not _capturing:
		return
	if menu == null or not bool(menu.call("is_open")) or not visible:
		_end_capture("")
		return
	# Mouse movement is not a binding and would end every capture instantly.
	if event is InputEventMouseMotion:
		return

	if _is_cancel(event):
		get_viewport().set_input_as_handled()
		_end_capture("Left %s as it was." % _label_of(_capture_action))
		return

	var candidate := _candidate(event)
	if candidate == null:
		return
	get_viewport().set_input_as_handled()
	_commit(candidate)


## Escape and gamepad B always cancel, read off the device rather than through
## `menu_cancel` — the player may have just rebound `menu_cancel` to something
## unreachable, and getting out of a capture must not depend on their choices.
##
## The cost is that those two buttons cannot be ASSIGNED from this screen. They
## are the defaults for "back" and "flee" already, and the Default button on a
## row puts them back, so nothing is unreachable.
func _is_cancel(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.pressed and (key.keycode == KEY_ESCAPE or key.physical_keycode == KEY_ESCAPE)
	if event is InputEventJoypadButton:
		var button := event as InputEventJoypadButton
		return button.pressed and button.button_index == JOY_BUTTON_B
	return false


## The event, if it belongs in the slot being captured. Anything else is ignored
## and the capture keeps waiting: a controller player who lands on the keyboard
## column has no keyboard to press, and quietly filing their A button under
## "Keyboard" would be worse than doing nothing.
func _candidate(event: InputEvent) -> InputEvent:
	if KEY_BINDINGS.slot_for(event) != _capture_slot:
		return null

	if event is InputEventKey:
		var key := event as InputEventKey
		return event if key.pressed and not key.echo else null
	if event is InputEventMouseButton:
		return event if (event as InputEventMouseButton).pressed else null
	if event is InputEventJoypadButton:
		return event if (event as InputEventJoypadButton).pressed else null
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return event if absf(motion.axis_value) >= 0.6 else null
	return null


func _commit(event: InputEvent) -> void:
	var bindings: RefCounted = _bindings()
	var action := _capture_action
	var slot := _capture_slot
	var clashes: Array = bindings.call("conflicts", action, slot, event)

	if not bool(bindings.call("set_binding", action, slot, event)):
		_end_capture("That cannot go in the %s column." % slot)
		return
	_save()

	var name := str(bindings.call("describe", bindings.call("binding", action, slot)))
	if clashes.is_empty():
		_end_capture("%s is now %s." % [_label_of(action), name])
		return
	# Duplicates are allowed and said out loud. The game's own defaults share
	# buttons across the world, a fight and a menu; see scripts/ui/key_bindings.gd.
	var others: Array[String] = []
	for other in clashes:
		others.append(_label_of(str(other)))
	_end_capture("%s is now %s — so is %s. Both will fire." % [
		_label_of(action), name, ", ".join(others)
	])


# --- resetting --------------------------------------------------------------


func _on_reset_action(action: String) -> void:
	var bindings: RefCounted = _bindings()
	if bindings == null:
		return
	if not bool(bindings.call("is_overridden", action, "keyboard")) \
			and not bool(bindings.call("is_overridden", action, "gamepad")):
		say("%s is already at its default." % _label_of(action))
		return
	bindings.call("reset_action", action)
	_save()
	say("%s is back to its default." % _label_of(action))


## Two presses, like picking a stack up and putting it down. One stray press
## should not throw away a layout the player spent ten minutes on.
func _on_reset_all() -> void:
	var bindings: RefCounted = _bindings()
	if bindings == null:
		return
	if _confirm_left <= 0.0:
		if not bool(bindings.call("any_overridden")):
			say("Every control is already at its default.")
			return
		_confirm_left = CONFIRM_SECONDS
		_reset_all_button.text = "  Press again to reset every control"
		say("Press again to put every control back.")
		return

	_confirm_left = 0.0
	_reset_all_button.text = "  Reset every control to its default"
	bindings.call("reset_all")
	_save()
	say("Every control is back to its default.")


# --- plumbing ---------------------------------------------------------------


func _label_of(action: String) -> String:
	var controls: Dictionary = (_config.get("settings", {}) as Dictionary).get("controls", {}) as Dictionary
	var labels: Dictionary = controls.get("labels", {}) as Dictionary
	return str(labels.get(action, action))


func _bindings() -> RefCounted:
	return menu.get("bindings") if menu != null else null


func _save() -> void:
	var bindings: RefCounted = _bindings()
	if bindings != null and not bool(bindings.call("save")):
		# Worth saying on screen: the change works this session and vanishes on
		# the next launch, which is a confusing thing to discover tomorrow.
		say("Changed, but the settings file could not be written.")


func _hold_shell(held: bool) -> void:
	if menu != null:
		menu.call("hold_input", held)


func _read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
