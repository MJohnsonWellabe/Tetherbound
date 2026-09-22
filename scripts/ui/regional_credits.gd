extends CanvasLayer

## Local ending presentation. It owns only this player's screen and input and
## never pauses the world. No scene change occurs, so closing returns to the
## same trainer and world while another peer keeps playing throughout.

const CONFIG_PATH := "res://data/config/regional_credits.json"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const GAME_MENU := preload("res://scripts/ui/game_menu.gd")
const UI := preload("res://scripts/ui/ui_tokens.gd")
const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")

signal acknowledged(character_id: String)

var _open := false
var _elapsed := 0.0
var _expected_character_id := ""
var _expected_world: Object = null
var _expected_session: Node = null
var _session_was_active := false
var _mouse_before := Input.MOUSE_MODE_CAPTURED
var _root: Control = null
var _scroll: ScrollContainer = null
var _continue: Button = null
var _scroll_position := 0.0
var _config: Dictionary = {}


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(INPUT_OWNER.GROUP)
	add_to_group(GAME_MENU.STORY_MODAL_GROUP)
	_config = _read_config()
	_build()
	visible = false


func is_open() -> bool:
	return _open


func open_for(character_id: String, world: Object) -> bool:
	if _open or character_id.is_empty() or world == null or not _config.get("ok", false):
		return false
	var game := get_node_or_null(^"/root/Game")
	_expected_character_id = character_id
	_expected_world = world
	_expected_session = game.get("session") as Node if game != null else null
	_session_was_active = _expected_session != null and _expected_session.has_method("is_active") \
		and bool(_expected_session.call("is_active"))
	if _expected_session != null and _expected_session.has_signal("transport_closed") \
			and not _expected_session.is_connected("transport_closed", _on_transport_closed):
		_expected_session.connect("transport_closed", _on_transport_closed)
	_elapsed = 0.0
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
	_scroll.scroll_vertical = 0
	_scroll_position = 0.0
	_continue.grab_focus()
	return true


func close_without_acknowledgement() -> void:
	_close(false)


func _process(delta: float) -> void:
	if not _open:
		return
	if not _context_is_current():
		_close(false)
		return
	_elapsed += delta
	var motion: Dictionary = _config.get("motion", {}) as Dictionary
	if _elapsed >= float(motion.get("auto_scroll_delay_seconds", 1.5)):
		var bar := _scroll.get_v_scroll_bar()
		var bottom := maxi(0, int(ceil(bar.max_value - bar.page)))
		_scroll_position = maxf(_scroll_position, float(_scroll.scroll_vertical))
		_scroll_position = minf(float(bottom), _scroll_position \
			+ float(motion.get("auto_scroll_speed_px_s", 36.0)) * delta)
		_scroll.scroll_vertical = int(floor(_scroll_position))
	if _elapsed >= float(motion.get("input_guard_seconds", 0.25)) \
			and (Input.is_action_just_pressed("interact") \
			or Input.is_action_just_pressed("menu_cancel")):
		_acknowledge()


func _on_continue_pressed() -> void:
	if _elapsed >= float((_config.get("motion", {}) as Dictionary).get(
			"input_guard_seconds", 0.25)):
		_acknowledge()


func _acknowledge() -> void:
	if not _open or not _context_is_current():
		_close(false)
		return
	var character_id := _expected_character_id
	_close(true)
	acknowledged.emit(character_id)


func _close(_was_acknowledged: bool) -> void:
	if not _open:
		return
	_open = false
	visible = false
	_expected_character_id = ""
	_expected_world = null
	if _expected_session != null and is_instance_valid(_expected_session) \
			and _expected_session.has_signal("transport_closed") \
			and _expected_session.is_connected("transport_closed", _on_transport_closed):
		_expected_session.disconnect("transport_closed", _on_transport_closed)
	_expected_session = null
	_session_was_active = false
	INPUT_OWNER.suppress_pause_reopen(get_tree())
	Input.mouse_mode = _mouse_before as Input.MouseMode
	if INPUT_OWNER.current(get_tree()) == null:
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)


func _exit_tree() -> void:
	if _open:
		_close(false)


func _on_transport_closed() -> void:
	_close(false)


func _context_is_current() -> bool:
	var game := get_node_or_null(^"/root/Game")
	if game == null or game.get("world") != _expected_world \
			or HOMECOMING.character_id(game) != _expected_character_id \
			or game.get("session") != _expected_session:
		return false
	if _session_was_active and (_expected_session == null \
			or not _expected_session.has_method("is_active") \
			or not bool(_expected_session.call("is_active"))):
		return false
	return HOMECOMING.credits_pending(game)


func _build() -> void:
	var config := _config
	var layout: Dictionary = config.get("layout", {}) as Dictionary
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.025, 0.96)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side,
			int(layout.get("safe_margin_px", 48)))
	_root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",
		int(layout.get("column_separation_px", 18)))
	margin.add_child(column)

	var title := Label.new()
	title.text = str(config.get("title", "TETHERBOUND"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(UI.FONT_PATH))
	title.add_theme_font_size_override("font_size", int(layout.get("title_font_px", 44)))
	title.add_theme_color_override("font_color", UI.TEXT_PRIMARY)
	column.add_child(title)

	var frame := PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", UI.panel_box())
	column.add_child(frame)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(_scroll)
	var roll := VBoxContainer.new()
	roll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll.add_theme_constant_override("separation", int(layout.get("roll_separation_px", 28)))
	_scroll.add_child(roll)
	for raw: Variant in config.get("sections", []):
		if not raw is Dictionary:
			continue
		var section: Dictionary = raw
		_add_line(roll, str(section.get("heading", "")),
			int(layout.get("heading_font_px", 28)), UI.TEAL_SOFT)
		for entry: Variant in section.get("lines", []):
			_add_line(roll, str(entry), int(layout.get("body_font_px", 24)), UI.TEXT_SECONDARY)
	_add_line(roll, str(config.get("closing", "")),
		int(layout.get("closing_font_px", 26)), UI.TEXT_PRIMARY)

	_continue = Button.new()
	_continue.text = "Continue exploring"
	_continue.custom_minimum_size = Vector2(float(layout.get("button_width_px", 360)),
		float(layout.get("button_height_px", 64)))
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.add_theme_font_size_override("font_size", int(layout.get("button_font_px", 24)))
	_continue.pressed.connect(_on_continue_pressed)
	column.add_child(_continue)


func _add_line(parent: VBoxContainer, text: String, size: int, colour: Color) -> void:
	if text.is_empty():
		return
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", load(UI.FONT_PATH))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)


func _read_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("regional credits config is missing")
		return {"ok": false, "sections": []}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary:
		push_error("regional credits config is malformed")
		return {"ok": false, "sections": []}
	var out: Dictionary = parsed
	out["ok"] = true
	return out
