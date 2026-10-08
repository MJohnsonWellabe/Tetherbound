extends CanvasLayer

signal dismissed(lesson_id: String)
const OWNER := preload("res://scripts/ui/input_owner.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const GLYPH := preload("res://scripts/ui/input_glyph.gd")
## Same membership contract as the dialogue panel and game_menu's guard.
const STORY_MODAL_GROUP := &"story_modal"
var _open := false
var _closing := false
var _opening_edge := false
var _row: Dictionary = {}
var _line := 0
var _text: Label
var _mouse_before := Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	add_to_group(OWNER.GROUP)
	add_to_group(STORY_MODAL_GROUP)
	visible = false

func open(row: Dictionary) -> bool:
	if _open or _closing or OWNER.current(get_tree()) != null or row.get("lines", []).is_empty(): return false
	_row = row.duplicate(true)
	_line = 0
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.06, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(780, 360)
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)
	var speaker := Label.new()
	speaker.text = str(row.speaker)
	speaker.add_theme_font_size_override("font_size", TOKENS.FONT_PROMPT)
	box.add_child(speaker)
	_text = Label.new()
	_text.custom_minimum_size = Vector2(780, 200)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", TOKENS.FONT_PROMPT)
	box.add_child(_text)
	var controls := Label.new()
	controls.text = "%s Continue   ·   %s Skip lesson" % [GLYPH.action_name("menu_confirm"), GLYPH.action_name("menu_cancel")]
	controls.add_theme_font_size_override("font_size", TOKENS.FONT_PROMPT)
	box.add_child(controls)
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_open = true
	_opening_edge = _answer_held()
	visible = true
	OWNER.set_world_hud_visible(get_tree(), false)
	_show_line()
	return true

func _show_line() -> void:
	_text.text = str(_row.lines[_line]) + "\n\nNext: " + str(_row.goal)

func owns_input() -> bool: return _open or _closing
func is_open() -> bool: return _open

func _input(event: InputEvent) -> void:
	if not _open: return
	if _opening_edge:
		if event.is_action("menu_cancel") or event.is_action("menu_confirm") or event.is_action("ui_accept"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("menu_confirm") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_line += 1
		if _line >= _row.lines.size(): close()
		else: _show_line()

func close(acknowledge: bool = true) -> void:
	if not _open: return
	OWNER.suppress_pause_reopen(get_tree())
	_open = false
	_closing = true
	visible = false
	if acknowledge: dismissed.emit(str(_row.id))
	_release_presentation()

func _release_presentation() -> void:
	remove_from_group(OWNER.GROUP)
	if OWNER.current(get_tree()) == null:
		Input.mouse_mode = _mouse_before
		OWNER.set_world_hud_visible(get_tree(), true)
	add_to_group(OWNER.GROUP)

func _process(_delta: float) -> void:
	if _opening_edge and not _answer_held(): _opening_edge = false
	if _closing and not _answer_held():
		_closing = false

func _answer_held() -> bool:
	return Input.is_action_pressed("menu_cancel") or Input.is_action_pressed("menu_confirm") or Input.is_action_pressed("ui_accept")

func _exit_tree() -> void:
	if _open or _closing:
		_open = false
		_closing = false
		_release_presentation()
