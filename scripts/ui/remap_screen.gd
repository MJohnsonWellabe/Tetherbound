extends "res://scripts/ui/screen.gd"

## Button mapping: every player-facing action, what it is bound to on both
## devices, and the means to change it. "I should be able to map all my buttons
## how I want" — the owner, on the Ally, and CLAUDE.md's controller-first rule
## makes that a hard requirement rather than a preference.
##
## THE LIST COMES FROM THE INPUTMAP, NOT FROM THIS FILE. `settings.gd
## .remappable_actions()` walks the project's real actions (grouped by the data
## in settings.json, engine `ui_*` excluded), so an action added next month is
## on this screen the day it exists. A hardcoded list here would be the screen
## quietly deciding which buttons the player owns.
##
## CONFLICTS ARE REFUSED BY NAME. This project has shipped the two-actions-one-
## button collision twice (`project.godot` records both: inventory + party_menu
## on Y, mount nearly on interact), and both times the symptom was one press
## firing two systems with no arbitration possible. So a rebind that would put
## two same-group actions on one physical input is refused, and the refusal
## says which action holds the button — "sends them out to gather the wrong
## thing" is `build_mode`'s reason for naming the material, and it is the same
## reason here. Cross-group sharing (A confirms in menus, jumps in the world)
## is deliberate and allowed; the groups are data in settings.json.
##
## Rebinding is press-to-listen: A on a row, then the next key or pad button IS
## the answer. While listening this screen swallows the stack's verbs — the
## captured press must not also confirm, cancel or scroll — and for a beat
## afterwards too, because the key is still held when the capture ends and the
## stack reads held directions every physics frame.

const SETTINGS := preload("res://scripts/ui/settings.gd")

const NOTICE_SECONDS := 3.0

## How long after a capture the stack's own verbs stay swallowed. Long enough
## for a human to let go of the key that was just captured; short enough that
## the screen never feels stuck. Tunable.
const SWALLOW_SECONDS := 0.35

const RESET_ROW := "reset"

var _rows: Array[PanelContainer] = []
var _actions: Array[String] = []
var _template: PanelContainer = null
var _listening: bool = false
var _swallow: float = 0.0
var _notice: String = ""
var _notice_left: float = 0.0

@onready var _scroll: ScrollContainer = $Body/Scroll
@onready var _list: VBoxContainer = $Body/Scroll/Rows
@onready var _footnote: RichTextLabel = $Body/Footnote


func _ready() -> void:
	_actions = SETTINGS.remappable_actions()
	_build_rows()
	super()


func _build_rows() -> void:
	_template = _list.get_node_or_null(^"RowTemplate") as PanelContainer
	if _template == null:
		push_error("remap screen has no RowTemplate row to duplicate")
		return
	_list.remove_child(_template)
	# One row per action, and a last row that is the way back to the defaults.
	# A verb would need a button, and every button on this screen is spoken for
	# — it is a screen ABOUT buttons.
	for i in _actions.size() + 1:
		var row := _template.duplicate() as PanelContainer
		row.name = "Row%d" % (i + 1)
		row.visible = true
		_list.add_child(row)
		_rows.append(row)


func screen_title() -> String:
	return "Button Mapping"


func hints() -> Array[Array]:
	var rows: Array[Array] = []
	if _listening:
		rows.append(["…", "Press the new key or button", true])
		rows.append(["Esc", "Keep the old one", true])
		return rows
	rows.append(["Up/Down", "Choose", true])
	var on_reset := focus_index() == _actions.size()
	rows.append([STYLE.glyph(&"menu_confirm"), "Reset all" if on_reset else "Rebind", true])
	rows.append([STYLE.glyph(&"menu_cancel"), "Back", true])
	return rows


func focus_count() -> int:
	return _actions.size() + 1


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""
	_swallow = maxf(0.0, _swallow - get_process_delta_time())

	for i in _rows.size():
		var row := _rows[i]
		var focused := i == focus_index()
		row.add_theme_stylebox_override("panel", STYLE.panel_style(
			STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_BG,
			STYLE.ROW_FOCUS_EDGE if focused else STYLE.PANEL_EDGE
		))
		var label := row.get_node(^"Pad/Line/Label") as Label
		var keys := row.get_node(^"Pad/Line/Keys") as Label
		var pad := row.get_node(^"Pad/Line/Buttons") as Label
		if i >= _actions.size():
			label.text = "Reset all to defaults"
			keys.text = ""
			pad.text = ""
			continue
		label.text = SETTINGS.action_label(_actions[i])
		if focused and _listening:
			keys.text = "press a key or button…"
			keys.modulate = Color(0.95, 0.80, 0.30)
			pad.text = ""
			continue
		keys.modulate = Color.WHITE
		keys.text = _bound_text(_actions[i], "key")
		pad.text = _bound_text(_actions[i], "pad")

	if _notice != "":
		_footnote.text = "[center][color=#%s]%s[/color][/center]" % [STYLE.WARN, _notice]
	else:
		_footnote.text = "[center][color=#%s]Changes are saved as you make them and applied at every boot. Sticks and triggers keep their axes.[/color][/center]" % STYLE.INK_DIM


## What an action is bound to on one device, in `ui_style`'s words — the same
## glyph the verb rows use, so the screen that teaches the buttons and the rows
## that name them cannot disagree.
func _bound_text(action: String, device: String) -> String:
	var parts: Array[String] = []
	for event in InputMap.action_get_events(StringName(action)):
		if device == "key" and event is InputEventKey:
			parts.append(STYLE.key_glyph(event as InputEventKey))
		elif device == "key" and event is InputEventMouseButton:
			parts.append(STYLE.mouse_glyph(event as InputEventMouseButton))
		elif device == "pad" and event is InputEventJoypadButton:
			parts.append(STYLE.button_glyph(int((event as InputEventJoypadButton).button_index)))
		elif device == "pad" and event is InputEventJoypadMotion:
			parts.append(STYLE.axis_glyph(event as InputEventJoypadMotion))
	# Drawn even when empty — an em dash, not a blank. The cooldown-verb lesson:
	# absence reads as a bug, a mark reads as an answer.
	return " / ".join(parts) if not parts.is_empty() else "—"


# ------------------------------------------------------------------ the verbs

func on_focus_changed(index: int) -> void:
	if index < _rows.size():
		# Deferred: the scroll container may not have laid out the row this frame.
		_scroll.call_deferred("ensure_control_visible", _rows[index])


func on_activate(index: int) -> void:
	if _swallow > 0.0 or _listening:
		return
	if index >= _actions.size():
		SETTINGS.reset_bindings()
		_say("every binding is back to the defaults")
		return
	_listening = true


## Swallowed while listening and just after: the captured key is often a
## direction key, still held when the capture ends, and the stack reads held
## directions every physics frame.
func navigate(dx: int, dy: int) -> void:
	if _listening or _swallow > 0.0:
		return
	super(dx, dy)


func cancel() -> bool:
	if _listening:
		_listening = false
		_say("kept the old binding")
		return true
	return _swallow > 0.0


## The capture. Raw events, because while listening the next press is an
## ANSWER, not a command — it must be read before any action it happens to be
## bound to fires. `_input` runs before the stack's `_physics_process` poll,
## and the swallow window covers the frames after.
func _input(event: InputEvent) -> void:
	if not _listening or not visible or not is_screen_active():
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var key := event as InputEventKey
		# Escape backs out of listening, and is therefore the one key that can
		# never be a binding. A rebind screen with no way to say "never mind"
		# assigns a button to whoever bumps the desk.
		if key.physical_keycode == KEY_ESCAPE or key.keycode == KEY_ESCAPE:
			_listening = false
			_swallow = SWALLOW_SECONDS
			_say("kept the old binding")
			return
		var code := int(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
		_capture("key", code, STYLE.key_glyph(key))
	elif event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		var code := int((event as InputEventJoypadButton).button_index)
		_capture("button", code, STYLE.button_glyph(code))


func _capture(kind: String, code: int, glyph: String) -> void:
	_listening = false
	_swallow = SWALLOW_SECONDS
	var action := _actions[mini(focus_index(), _actions.size() - 1)]

	# Already this action's own? Saying "done" is truer than refusing.
	if _holds(action, kind, code):
		_say("%s was already on %s" % [SETTINGS.action_label(action), glyph])
		return

	# THE CONFLICT CHECK. Same group, same physical input: one press would fire
	# both actions, forever, and only one could ever win. Refused, naming the
	# holder, so the player can go move THAT one first if they mean it.
	var holder := SETTINGS.conflicting_holder(action, kind, code)
	if holder != "":
		_say("%s already does %s — move it first" % [glyph, SETTINGS.action_label(holder)])
		return

	# Replace this device's binding, keep the other device's, keep the axes.
	var keys: Array = []
	var buttons: Array = []
	for event in InputMap.action_get_events(StringName(action)):
		if kind != "key" and event is InputEventKey:
			keys.append(int((event as InputEventKey).physical_keycode))
		elif kind != "button" and event is InputEventJoypadButton:
			buttons.append(int((event as InputEventJoypadButton).button_index))
	if kind == "key":
		keys = [code]
	else:
		buttons = [code]
	SETTINGS.set_binding(action, keys, buttons)
	_say("%s is now %s" % [SETTINGS.action_label(action), glyph])


func _holds(action: String, kind: String, code: int) -> bool:
	for event in InputMap.action_get_events(StringName(action)):
		if kind == "key" and event is InputEventKey \
				and int((event as InputEventKey).physical_keycode) == code:
			return true
		if kind == "button" and event is InputEventJoypadButton \
				and int((event as InputEventJoypadButton).button_index) == code:
			return true
	return false


func on_pushed() -> void:
	# Re-asked on every open, so an action added since the screen was built —
	# or a binding another screen changed — is what the rows show. Rebuilding
	# rows only when the count moved keeps the open cheap.
	var latest := SETTINGS.remappable_actions()
	if latest.size() != _actions.size():
		_actions = latest
		for row in _rows:
			row.queue_free()
		_rows.clear()
		if _template != null:
			_list.add_child(_template)
			_build_rows()
			STYLE.make_legible(self)
	else:
		_actions = latest
	_listening = false
	_swallow = 0.0
	_notice = ""
	_notice_left = 0.0
	set_focus_index(0)


func on_popped() -> void:
	_listening = false


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS
