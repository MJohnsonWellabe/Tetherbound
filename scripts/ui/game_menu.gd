extends CanvasLayer

## The pause menu shell: tabs, focus, and the two things opening a menu must do.
##
## Those two things are the whole reason this is not just a Control someone
## dropped into a scene. Opening pauses the tree, and releases the mouse that
## scripts/world/playground_world.gd captures unconditionally and never gives
## back; closing restores both, to whatever they were rather than to a guess.
## Getting the restore wrong is invisible until the player closes the menu and
## finds the camera dead.
##
## The tab list comes from data/config/menu.json. The previous prototype kept
## its pause menu in src/data/pauseMenu.json for the same reason: a new screen
## should be a JSON entry plus a tab script, never a new branch in here.
##
## CONTROLLER FIRST, and this is not a preference. Tetherbound ships on an ROG
## Ally. A menu that needs a mouse is a broken menu, so everything selectable is
## a focusable Control, the theme makes focus the loudest state on screen, and
## Godot's built-in ui_* actions (which carry d-pad and stick bindings by
## default) drive the cursor. Nothing here reads a device.

const CONFIG_PATH := "res://data/config/menu.json"
const THEME_PATH := "res://scenes/ui/menu_theme.tres"

## How long a status line stays up. Long enough to read on a handheld held at
## arm's length, short enough that it is gone before the next one arrives.
const STATUS_SECONDS := 3.0

var game: Node = null

var _config: Dictionary = {}
var _tabs: Array = []
var _bodies: Array = []
var _tab_buttons: Array = []
var _index: int = 0

var _open: bool = false
## Whatever the mouse was doing before the menu opened. Restored on close, so
## the menu works the same whether it was opened from a captured-mouse world or
## from a future scene that never captured it.
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false

var _status_left: float = 0.0
var _last_revision: int = -1

## The fight, found by capability rather than by path so this file holds no
## knowledge of another agent's scene layout. Re-found when it goes away.
var _combat: Node = null

@onready var _root: Control = $Root
@onready var _tab_row: HBoxContainer = $Root/Frame/Panel/Body/Tabs
@onready var _content: MarginContainer = $Root/Frame/Panel/Body/Content
@onready var _title: Label = $Root/Frame/Panel/Body/Header/Title
@onready var _day: Label = $Root/Frame/Panel/Body/Header/Day
@onready var _status: Label = $Root/Frame/Panel/Body/Status
@onready var _footer: Label = $Root/Frame/Panel/Body/Footer


func _ready() -> void:
	game = get_parent()
	_config = _read_config()

	var theme_resource: Theme = load(THEME_PATH)
	if theme_resource != null:
		_root.theme = theme_resource

	_footer.text = str(_config.get("footer", ""))
	_build_tabs()
	_root.visible = false


func _read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("menu config missing: %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("menu config is not a JSON object: %s" % CONFIG_PATH)
		return {}
	return parsed as Dictionary


func _build_tabs() -> void:
	var listed: Variant = _config.get("tabs", [])
	if typeof(listed) != TYPE_ARRAY:
		return

	for entry in listed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var tab := entry as Dictionary
		var script_path := str(tab.get("script", ""))
		var script: GDScript = load(script_path)
		if script == null:
			push_error("menu tab '%s' has no script at %s" % [tab.get("id", "?"), script_path])
			continue

		var body: Control = script.new()
		body.set("menu", self)
		body.visible = false
		_content.add_child(body)

		var button := Button.new()
		button.text = str(tab.get("label", tab.get("id", "?")))
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		# Bound by index rather than by id: two tabs sharing an id is a data bug
		# that should show as a duplicate label, not as a tab that opens another.
		var slot := _tabs.size()
		button.pressed.connect(func() -> void: select(slot))
		_tab_row.add_child(button)

		_tabs.append(tab)
		_bodies.append(body)
		_tab_buttons.append(button)


# --- opening and closing ----------------------------------------------------


func is_open() -> bool:
	return _open


## Open on a tab id, or on whatever was last shown.
##
## Refuses while a fight is running. `menu_cancel` and `combat_run` share a
## binding (Escape / B) in project.godot's input map, so in a fight that button
## already means "flee" — see docs/decisions/D14. This agent may not add input
## actions, so the menu yields rather than stealing the flee button.
func open(tab_id: String = "") -> bool:
	if _open:
		return false
	if _fight_in_progress():
		return false

	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true

	_open = true
	_root.visible = true
	_status.text = ""
	_status_left = 0.0
	# Force a rebuild: state may have moved while the menu was shut.
	_last_revision = -1

	var target := _index
	if not tab_id.is_empty():
		for i in _tabs.size():
			if str((_tabs[i] as Dictionary).get("id", "")) == tab_id:
				target = i
				break
	select(target)
	return true


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	# Restore, do not assume. A future scene may legitimately open the menu with
	# the mouse already visible, and slamming it back to CAPTURED would trap a
	# cursor the player needs.
	Input.mouse_mode = _mouse_before
	get_tree().paused = _paused_before
	if _index >= 0 and _index < _bodies.size():
		_bodies[_index].call("say", "")


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func select(index: int) -> void:
	if _tabs.is_empty():
		return
	_index = posmod(index, _tabs.size())
	for i in _bodies.size():
		_bodies[i].visible = i == _index
		_tab_buttons[i].button_pressed = i == _index
	_title.text = str((_tabs[_index] as Dictionary).get("label", "Paused"))
	_last_revision = -1
	_refresh()

	var focus_target: Control = _bodies[_index].call("first_focus")
	if focus_target != null:
		focus_target.grab_focus()
	else:
		_tab_buttons[_index].grab_focus()


func next_tab() -> void:
	select(_index + 1)


## One status line for the whole menu, so a message cannot appear somewhere the
## player was not looking.
func say(message: String) -> void:
	_status.text = message
	_status_left = STATUS_SECONDS if not message.is_empty() else 0.0


# --- the frame loop ---------------------------------------------------------


func _process(delta: float) -> void:
	_read_actions()
	if not _open:
		return

	if _status_left > 0.0:
		_status_left -= delta
		if _status_left <= 0.0:
			_status.text = ""

	_day.text = "Day %d" % int(game.get("day")) if game != null else ""
	_refresh()


## Rebuild structure only when the state's shape changed; write values always.
func _refresh() -> void:
	if _index < 0 or _index >= _bodies.size():
		return
	var body: Control = _bodies[_index]
	var revision: int = int(body.call("revision"))
	if revision != _last_revision:
		_last_revision = revision
		body.call("build")
	body.call("poll")


# --- input ------------------------------------------------------------------


## Actions are POLLED, not received as events.
##
## Two reasons, and the second is the one that decided it. A focused Button
## swallows ui_accept and would swallow anything sharing its event, so the close
## and cycle keys have to be read outside the Control tree — and reading them
## here keeps the whole menu on one rule with scripts/ui/combat_hud.gd, which
## polls the fight every frame rather than being pushed at.
##
## Cursor movement and button presses are NOT polled: those are Godot's built-in
## ui_* actions driving Control focus, which is what makes the menu work on a
## stick with no code of ours in the path.
func _read_actions() -> void:
	if _tabs.is_empty():
		return

	if not _open:
		if Input.is_action_just_pressed(str(_config.get("open_action", "menu_cancel"))):
			open()
			return
		for action in _shortcuts().keys():
			if Input.is_action_just_pressed(str(action)):
				open(str(_shortcuts()[action]))
				return
		return

	if Input.is_action_just_pressed(str(_config.get("close_action", "menu_cancel"))):
		close()
		return

	if Input.is_action_just_pressed(str(_config.get("cycle_action", "tool_cycle"))):
		next_tab()
		return

	# The shortcut key doubles as a jump-to-tab while the menu is already open,
	# so pressing I twice lands on the backpack rather than opening and closing.
	for action in _shortcuts().keys():
		if Input.is_action_just_pressed(str(action)):
			var wanted := str(_shortcuts()[action])
			for i in _tabs.size():
				if str((_tabs[i] as Dictionary).get("id", "")) == wanted:
					select(i)
					break
			return


func _shortcuts() -> Dictionary:
	var shortcuts: Variant = _config.get("shortcuts", {})
	return shortcuts as Dictionary if typeof(shortcuts) == TYPE_DICTIONARY else {}


## Is a fight running anywhere in the current scene?
##
## Found by looking for a node that answers `is_fighting()` rather than by node
## path. Combat belongs to another agent and its scene layout is theirs to move;
## a hard-coded path here would break silently the day it does.
func _fight_in_progress() -> bool:
	if _combat == null or not is_instance_valid(_combat):
		_combat = _find_combat(get_tree().get_current_scene())
	if _combat == null:
		return false
	return bool(_combat.call("is_fighting"))


func _find_combat(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("is_fighting"):
		return node
	for child in node.get_children():
		var found := _find_combat(child)
		if found != null:
			return found
	return null
