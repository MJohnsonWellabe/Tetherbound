extends Control

## Gate A front door. This is deliberately a tiny scene with no Terrain3D,
## vegetation or world scripts behind it: launch becomes interactive before the
## expensive Meadows exists, then New/Load transitions into the real world.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const THEME_PATH := "res://assets/ui/theme/tetherbound_theme.tres"
const EXPORT_VERIFY_FLAG := "--verify-export"
const UITokens := preload("res://scripts/ui/ui_tokens.gd")


## A lightweight Meadows vista for the front door.  The approved key-art board
## lives under docs/ and is deliberately excluded from exports, while building
## the real Terrain3D world here would recreate the long blank boot RG25 fixed.
## These flat, layered silhouettes borrow the board's value structure and
## landmark language without introducing a second world scene or a new asset.
class MeadowsBackdrop extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
		queue_redraw()


	func _draw() -> void:
		var view := size
		if view.x <= 0.0 or view.y <= 0.0:
			return

		# A deep upper sky and warm horizon give the screen an authored time of
		# day while retaining enough darkness for the menu's pale lettering.
		var sky_top := Color("#071820")
		var sky_bottom := Color("#4f857f")
		for band in 36:
			var from := float(band) / 36.0
			var to := float(band + 1) / 36.0
			draw_rect(Rect2(0.0, view.y * from, view.x, view.y * (to - from) + 1.0),
				sky_top.lerp(sky_bottom, pow(from, 0.78)))

		var horizon := view.y * 0.49
		var sun_at := Vector2(view.x * 0.76, view.y * 0.235)
		draw_circle(sun_at, view.y * 0.075, Color(Color("#e9c978"), 0.16))
		draw_circle(sun_at, view.y * 0.047, Color(Color("#f4d68a"), 0.72))

		# Distant mountain, foothills and near meadow use separated values so the
		# scene still reads at handheld scale instead of collapsing into one green.
		_polygon([
			Vector2(0.0, horizon + view.y * 0.06),
			Vector2(view.x * 0.36, horizon + view.y * 0.02),
			Vector2(view.x * 0.49, horizon - view.y * 0.08),
			Vector2(view.x * 0.59, horizon - view.y * 0.19),
			Vector2(view.x * 0.66, horizon - view.y * 0.04),
			Vector2(view.x * 0.72, horizon - view.y * 0.12),
			Vector2(view.x * 0.80, horizon + view.y * 0.01),
			Vector2(view.x, horizon - view.y * 0.04),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#385b5b"))
		_polygon([
			Vector2(0.0, horizon + view.y * 0.12),
			Vector2(view.x * 0.18, horizon + view.y * 0.06),
			Vector2(view.x * 0.38, horizon + view.y * 0.12),
			Vector2(view.x * 0.58, horizon + view.y * 0.035),
			Vector2(view.x * 0.77, horizon + view.y * 0.10),
			Vector2(view.x, horizon + view.y * 0.02),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#416d4d"))
		_polygon([
			Vector2(0.0, horizon + view.y * 0.26),
			Vector2(view.x * 0.25, horizon + view.y * 0.16),
			Vector2(view.x * 0.49, horizon + view.y * 0.21),
			Vector2(view.x * 0.71, horizon + view.y * 0.105),
			Vector2(view.x, horizon + view.y * 0.18),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#315c3e"))
		_polygon([
			Vector2(0.0, view.y * 0.86), Vector2(view.x * 0.22, view.y * 0.78),
			Vector2(view.x * 0.45, view.y * 0.86), Vector2(view.x * 0.65, view.y * 0.70),
			Vector2(view.x * 0.82, view.y * 0.76), Vector2(view.x, view.y * 0.69),
			Vector2(view.x, view.y), Vector2(0.0, view.y),
		], Color("#1d3e2f"))

		# A widening trail is the composition's pull into the Meadows, with the
		# distant pylon marking the adventure beyond the welcoming foreground.
		_polygon([
			Vector2(view.x * 0.72, horizon + view.y * 0.10),
			Vector2(view.x * 0.745, horizon + view.y * 0.105),
			Vector2(view.x * 0.64, view.y), Vector2(view.x * 0.47, view.y),
		], Color(Color("#b69b68"), 0.72))
		_draw_pylon(Vector2(view.x * 0.79, horizon + view.y * 0.055), view.y * 0.17)
		_draw_tree(Vector2(view.x * 0.91, view.y * 0.61), view.y * 0.30, Color("#142f25"))
		_draw_tree(Vector2(view.x * 0.84, view.y * 0.70), view.y * 0.19, Color("#214632"))
		_draw_tree(Vector2(view.x * 0.69, view.y * 0.68), view.y * 0.15, Color("#274d35"))

		# Meadow flowers remain restrained highlights; they add scale and warmth
		# without turning the lightweight screen into procedural confetti.
		for flower in [
			Vector2(0.70, 0.83), Vector2(0.75, 0.88), Vector2(0.82, 0.82),
			Vector2(0.87, 0.91), Vector2(0.93, 0.84), Vector2(0.78, 0.94),
		]:
			var point := Vector2(view.x * flower.x, view.y * flower.y)
			draw_line(point, point + Vector2(0.0, view.y * 0.018), Color("#5f8e55"), 3.0)
			draw_circle(point, maxf(3.0, view.y * 0.0045), Color("#efd17d"))


	func _polygon(points: Array[Vector2], color: Color) -> void:
		draw_colored_polygon(PackedVector2Array(points), color)


	func _draw_tree(at: Vector2, height: float, color: Color) -> void:
		var trunk_w := height * 0.075
		draw_rect(Rect2(at.x - trunk_w * 0.5, at.y - height * 0.52, trunk_w, height * 0.52), Color("#493a2b"))
		draw_circle(at - Vector2(height * 0.13, height * 0.58), height * 0.23, color)
		draw_circle(at + Vector2(height * 0.12, -height * 0.64), height * 0.27, color.lightened(0.04))
		draw_circle(at + Vector2(0.0, -height * 0.82), height * 0.22, color.lightened(0.08))


	func _draw_pylon(at: Vector2, height: float) -> void:
		var iron := Color("#263943")
		draw_line(at, at - Vector2(0.0, height * 0.70), iron, maxf(4.0, height * 0.045))
		draw_line(at - Vector2(height * 0.18, height * 0.13), at - Vector2(0.0, height * 0.70), iron, maxf(3.0, height * 0.03))
		draw_line(at + Vector2(height * 0.18, -height * 0.13), at - Vector2(0.0, height * 0.70), iron, maxf(3.0, height * 0.03))
		var crystal := PackedVector2Array([
			at - Vector2(0.0, height), at + Vector2(height * 0.09, -height * 0.82),
			at - Vector2(0.0, height * 0.66), at - Vector2(height * 0.09, height * 0.82),
		])
		draw_colored_polygon(crystal, Color(Color("#55c9c8"), 0.84))
		var crystal_outline := crystal.duplicate()
		crystal_outline.append(crystal[0])
		draw_polyline(crystal_outline, Color(Color("#a5f0df"), 0.70), 2.0)

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
	var backdrop := MeadowsBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# The asymmetric layout leaves the Meadows vista visible as a destination,
	# instead of covering the entire identity of the game with a centred modal.
	var shade := ColorRect.new()
	shade.anchor_right = 0.56
	shade.anchor_bottom = 1.0
	shade.color = Color(Color("#071510"), 0.38)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.055
	panel.anchor_right = 0.445
	panel.anchor_top = 0.085
	panel.anchor_bottom = 0.915
	panel.add_theme_stylebox_override("panel", UITokens.panel_box(Color(Color("#0d1c18"), 0.94), Color(Color("#7ba284"), 0.86)))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 38)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 16)
	margin.add_child(root_box)

	var region := Label.new()
	region.text = "THE MEADOWS"
	region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region.add_theme_font_size_override("font_size", 22)
	region.add_theme_color_override("font_color", Color("#d4b96f"))
	root_box.add_child(region)

	var title := Label.new()
	title.text = "TETHERBOUND"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(UITokens.FONT_PATH))
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color("#f2ead5"))
	root_box.add_child(title)

	var rule := ColorRect.new()
	rule.custom_minimum_size.y = 2
	rule.color = Color(Color("#d4b96f"), 0.72)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_box.add_child(rule)

	var subtitle := Label.new()
	subtitle.text = "Build your team of five. Explore the Meadows."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.add_theme_color_override("font_color", Color("#b8cbbf"))
	root_box.add_child(subtitle)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.y = 12
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

	var footer := Label.new()
	footer.text = "A  SELECT     D-PAD  NAVIGATE"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 18)
	footer.add_theme_color_override("font_color", Color("#8fa9a0"))
	root_box.add_child(footer)

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
