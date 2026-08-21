extends Control

## Gate A front door. This is deliberately a tiny scene with no Terrain3D,
## vegetation or world scripts behind it: launch becomes interactive before the
## expensive Meadows exists, then New/Load transitions into the real world.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const THEME_PATH := "res://assets/ui/theme/tetherbound_theme.tres"
const EXPORT_VERIFY_FLAG := "--verify-export"
const UITokens := preload("res://scripts/ui/ui_tokens.gd")

var _main_box: VBoxContainer
var _load_box: VBoxContainer
var _confirm_box: VBoxContainer
var _status: Label
var _new_button: Button
var _load_button: Button
var _quit_button: Button


func _ready() -> void:
	add_to_group(&"title_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var theme: Theme = load(THEME_PATH)
	if theme != null:
		theme = theme
		self.theme = theme
	_build()
	_refresh_load_button()
	# Release verification launches the exported project through its real main
	# scene.  The title is now that main scene, so explicitly preserve the
	# verifier's old contract by taking only its private command-line path into a
	# clean Meadows run.  Normal players still stop here and choose New or Load.
	if should_enter_export_verification(OS.get_cmdline_args()):
		# This is a new exported process, so Game is already clean.  Entering the
		# world directly also keeps the verifier independent of title-button save
		# policy; the world's EXPORT-CHECK remains the sole pass/fail authority.
		_enter_world("Verifying export…")
		return
	_new_button.grab_focus()


static func should_enter_export_verification(arguments: PackedStringArray) -> bool:
	return arguments.has(EXPORT_VERIFY_FLAG)


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#152922")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# A broad meadow-like horizon made from simple UI blocks rather than loading
	# world art. It gives the title a real visual identity while keeping boot cheap.
	var horizon := ColorRect.new()
	horizon.anchor_left = 0.0
	horizon.anchor_right = 1.0
	horizon.anchor_top = 0.58
	horizon.anchor_bottom = 1.0
	horizon.color = Color("#315b3f")
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 650)
	panel.add_theme_stylebox_override("panel", UITokens.panel_box(Color("#17231f"), Color("#6ea58b")))
	centre.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 22)
	margin.add_child(root_box)

	var title := Label.new()
	title.text = "T E T H E R B O U N D"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("#f2ead5"))
	root_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Build your team. Choose your five. Push farther."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("#b8cbbf"))
	root_box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 36
	root_box.add_child(spacer)

	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 14)
	root_box.add_child(_main_box)
	_new_button = _button("Start New Game")
	_load_button = _button("Load Game")
	_quit_button = _button("Quit Game")
	_main_box.add_child(_new_button)
	_main_box.add_child(_load_button)
	_main_box.add_child(_quit_button)
	_new_button.pressed.connect(_on_new_pressed)
	_load_button.pressed.connect(_show_load_slots)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())

	_load_box = VBoxContainer.new()
	_load_box.visible = false
	_load_box.add_theme_constant_override("separation", 10)
	root_box.add_child(_load_box)

	_confirm_box = VBoxContainer.new()
	_confirm_box.visible = false
	_confirm_box.add_theme_constant_override("separation", 12)
	root_box.add_child(_confirm_box)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color("#d2c392"))
	root_box.add_child(_status)

	UITokens.make_text_legible(root_box)


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 58)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 24)
	return button


func _refresh_load_button() -> void:
	var game := get_node_or_null(^"/root/Game")
	var any := false
	if game != null:
		for slot in 5:
			if bool(game.call("has_save", slot)):
				any = true
				break
	_load_button.disabled = not any


func _on_new_pressed() -> void:
	var game := get_node_or_null(^"/root/Game")
	var has_existing := false
	if game != null:
		for slot in 5:
			if bool(game.call("has_save", slot)):
				has_existing = true
				break
	if not has_existing:
		_start_new_game()
		return
	_show_new_confirmation()


func _show_new_confirmation() -> void:
	_main_box.visible = false
	_load_box.visible = false
	_clear(_confirm_box)
	_confirm_box.visible = true
	var text := Label.new()
	text.text = "Start a fresh game? Existing saves stay available, but the autosave will be replaced once this new run saves progress."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_box.add_child(text)
	var go := _button("Start Fresh Game")
	var back := _button("Back")
	_confirm_box.add_child(go)
	_confirm_box.add_child(back)
	go.pressed.connect(_start_new_game)
	back.pressed.connect(_show_main)
	go.grab_focus()


func _start_new_game() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		_status.text = "Game state failed to start."
		return
	game.call("reset_for_new_game")
	_enter_world("Starting new game…")


func _show_load_slots() -> void:
	_main_box.visible = false
	_confirm_box.visible = false
	_clear(_load_box)
	_load_box.visible = true
	var heading := Label.new()
	heading.text = "Choose a save"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	_load_box.add_child(heading)
	var game := get_node_or_null(^"/root/Game")
	var first: Button = null
	for slot in 5:
		var info: Dictionary = game.call("save_slot_info", slot) if game != null else {}
		var label := "Autosave" if slot == 0 else "Save %d" % slot
		var button := _button(label)
		if info.is_empty():
			button.text = "%s — Empty" % label
			button.disabled = true
		else:
			button.text = "%s — Day %d · %d Pals" % [label, int(info.get("day", 1)), int(info.get("party_size", 0))]
			var chosen := slot
			button.pressed.connect(func() -> void: _load_slot(chosen))
			if first == null:
				first = button
		_load_box.add_child(button)
	var back := _button("Back")
	back.pressed.connect(_show_main)
	_load_box.add_child(back)
	(first if first != null else back).grab_focus()


func _load_slot(slot: int) -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null or not bool(game.call("load_game", slot)):
		_status.text = "That save could not be loaded."
		return
	_enter_world("Loading Meadows…")


func _enter_world(message: String) -> void:
	_status.text = message
	_set_buttons_disabled(true)
	await get_tree().process_frame
	get_tree().change_scene_to_file(WORLD_SCENE)


func _show_main() -> void:
	_confirm_box.visible = false
	_load_box.visible = false
	_main_box.visible = true
	_status.text = ""
	_refresh_load_button()
	_new_button.grab_focus()


func _set_buttons_disabled(value: bool) -> void:
	for node in find_children("*", "Button", true, false):
		(node as Button).disabled = value


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel") and (_load_box.visible or _confirm_box.visible):
		_show_main()
		get_viewport().set_input_as_handled()
