extends CanvasLayer

## Shared controller modal presentation only. Services keep transaction state;
## closing this surface never cancels or resubmits an admitted request.
const OWNER := preload("res://scripts/ui/input_owner.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
var _shown := false
var _closing := false
var _mouse_before := Input.MOUSE_MODE_VISIBLE
var _root: Control
var body: VBoxContainer
var heading: Label
var status: Label
var footer: Label
var _buttons: Array[Button] = []
var return_to := Callable()
static var _config_loaded := false
static var _config: Dictionary = {}
var _opened_context: Dictionary = {}

static func character_context(game: Node) -> Dictionary:
	if not is_instance_valid(game): return {}
	var local: Variant = game.get("local")
	var world: Variant = game.get("world")
	if not local is RefCounted or not world is RefCounted: return {}
	return {"character_id": local.get("character_id"), "world_id": world.get("world_id"),
		"world_namespace": world.get("reward_delivery_namespace")}

static func config() -> Dictionary:
	if _config_loaded: return _config
	_config_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	_config = raw.get("new_system_screens", {}) if raw is Dictionary else {}
	return _config

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	add_to_group(OWNER.GROUP)
	visible = false

func begin(title: String, legend: String) -> bool:
	if not is_inside_tree() or _shown or _closing or OWNER.current(get_tree()) != null:
		return false
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_shown = true
	_opened_context = character_context(get_node_or_null(^"/root/Game"))
	visible = true
	OWNER.set_world_hud_visible(get_tree(), false)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.theme = load("res://assets/ui/theme/tetherbound_theme.tres")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, int(config().get("safe_margin", 48)))
	_root.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", TOKENS.panel_box(TOKENS.BG_DEEP, TOKENS.BORDER))
	margin.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)
	heading = line(layout, title, TOKENS.FONT_TITLE)
	status = line(layout, "")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	footer = line(layout, legend)
	_buttons.clear()
	button(layout, "Back", close, "back")
	return true

func line(parent: Node, text: String, font_size: int = TOKENS.FONT_READ) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TOKENS.TEXT_PRIMARY)
	parent.add_child(label)
	return label

func button(parent: Node, text: String, action: Callable, key: String, enabled: bool = true) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = float(config().get("row_height", 66))
	control.add_theme_font_size_override("font_size", TOKENS.FONT_PROMPT)
	control.disabled = not enabled
	control.set_meta("system_focus_key", key)
	control.pressed.connect(action)
	parent.add_child(control)
	_buttons.append(control)
	return control

func finish(preferred: String = "") -> void:
	# Rebuilds retain stable row identity, never a list index.
	var enabled: Array[Button] = []
	for control: Button in _buttons:
		if is_instance_valid(control) and not control.disabled: enabled.append(control)
	if enabled.is_empty(): return
	var target: Button = enabled[0]
	for control: Button in enabled:
		if body.is_ancestor_of(control):
			target = control
			break
	for index: int in enabled.size():
		var control := enabled[index]
		control.focus_neighbor_top = control.get_path_to(enabled[(index - 1 + enabled.size()) % enabled.size()])
		control.focus_neighbor_bottom = control.get_path_to(enabled[(index + 1) % enabled.size()])
		control.focus_previous = control.focus_neighbor_top
		control.focus_next = control.focus_neighbor_bottom
		if str(control.get_meta("system_focus_key", "")) == preferred: target = control
	TOKENS.make_text_legible(_root)
	target.call_deferred("grab_focus")

func clear_body() -> String:
	var focused := get_viewport().gui_get_focus_owner()
	var key := str(focused.get_meta("system_focus_key", "")) if is_instance_valid(focused) else ""
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var retained: Array[Button] = []
	for control: Button in _buttons:
		if is_instance_valid(control) and control.is_inside_tree(): retained.append(control)
	_buttons = retained
	return key

func owns_input() -> bool: return _shown or _closing
func is_open() -> bool: return _shown

func close() -> void:
	if not _shown: return
	OWNER.suppress_pause_reopen(get_tree())
	_shown = false
	_closing = true
	visible = false
	_release_presentation()
	if is_instance_valid(_root):
		remove_child(_root)
		_root.queue_free()
	_buttons.clear()

func _release_presentation() -> void:
	if not is_inside_tree(): return
	remove_from_group(OWNER.GROUP)
	if OWNER.current(get_tree()) == null:
		Input.mouse_mode = _mouse_before
		OWNER.set_world_hud_visible(get_tree(), true)
	add_to_group(OWNER.GROUP)

func _process(_delta: float) -> void:
	if _shown and character_context(get_node_or_null(^"/root/Game")) != _opened_context:
		# A character/host-world switch disposes presentation, never its receipt.
		return_to = Callable()
		close()
	if _closing and not Input.is_action_pressed("menu_cancel") and not Input.is_action_pressed("ui_cancel") \
			and not Input.is_action_pressed("ui_accept"):
		_closing = false
		if return_to.is_valid(): return_to.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if not _shown: return
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _shown:
		_shown = false
		_closing = false
		_release_presentation()
