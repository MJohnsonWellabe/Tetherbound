extends VBoxContainer

## F26 prototype: embedded in the existing Settings input-owner shell.
## Restart is an explicit request for that shell to perform safe session exit.
## This widget never quits, changes peers, or changes gameplay authority.
signal changed
signal restart_requested

const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
var _preset: Button
var _feature_buttons: Dictionary = {}
var _shadow: Button
var _distance: Button
var _overlay: Button
var _restart_now: Button
var _later: Button
var _restart_note: Label
var _status: Label


func _ready() -> void:
	add_to_group(INPUT_OWNER.GROUP)
	add_theme_constant_override("separation", 14)
	var title := Label.new()
	title.text = "Graphics"
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)
	_preset = _button(func() -> void:
		var current := GRAPHICS.PRESETS.find(GRAPHICS.selected())
		_result(GRAPHICS.choose(GRAPHICS.PRESETS[(current + 1) % GRAPHICS.PRESETS.size()]))
	)
	for key: String in GRAPHICS.FEATURES:
		var button := _button(func() -> void:
			_result(GRAPHICS.customize(key, not bool(GRAPHICS.values().get(key, false))))
		)
		_feature_buttons[key] = button
	_shadow = _button(func() -> void: _cycle_option("shadow_quality"))
	_distance = _button(func() -> void: _cycle_option("draw_distance"))
	_overlay = _button(func() -> void: _result(GRAPHICS.set_overlay(not GRAPHICS.overlay_enabled())))
	_restart_note = Label.new()
	_restart_note.text = "Applies after restart"
	add_child(_restart_note)
	_restart_now = _button(func() -> void: restart_requested.emit())
	_restart_now.text = "Restart now"
	_later = _button(func() -> void:
		_restart_now.visible = false
		_later.visible = false
		_preset.grab_focus()
		_wire_focus()
		changed.emit()
	)
	_later.text = "Later"
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	refresh()


func _button(on_press: Callable) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_press)
	add_child(button)
	return button


func first_focus() -> Control:
	return _preset


func owns_input() -> bool:
	return is_visible_in_tree()


func last_focus() -> Control:
	var controls := _controls()
	return controls.back() if not controls.is_empty() else _preset


func controls() -> Array[Control]:
	return _controls()


func report_restart_failure(message: String) -> void:
	_status.text = message
	_restart_now.disabled = false


func begin_restart() -> void:
	_restart_now.disabled = true
	_status.text = "Saving progress before restart…"


func _cycle_option(key: String) -> void:
	var options: Array = ["Off", "Low", "Medium", "High"] if key == "shadow_quality" else ["Near", "Normal", "Far"]
	var current := options.find(str(GRAPHICS.values().get(key, options[0])))
	_result(GRAPHICS.customize(key, options[(current + 1) % options.size()]))


func _result(error: Error) -> void:
	if error != OK:
		_status.text = "Could not save graphics settings. Your previous settings are kept."
		return
	_status.text = ""
	refresh()
	changed.emit()


func refresh() -> void:
	if _preset == null:
		return
	var values := GRAPHICS.values()
	_preset.text = "Preset: " + GRAPHICS.selected()
	var labels := {"volumetric_fog": "Volumetric fog", "ssao": "SSAO", "ssil": "SSIL", "glow": "Glow"}
	for key: String in _feature_buttons:
		var button: Button = _feature_buttons[key]
		button.disabled = not GRAPHICS.forward_plus() or GRAPHICS.requested_renderer() == "gl_compatibility"
		var unavailable := "Not available on Low" if GRAPHICS.requested_renderer() == "gl_compatibility" else "Available after Forward+ starts"
		button.text = "%s: %s" % [labels[key], unavailable if button.disabled else ("On" if bool(values.get(key, false)) else "Off")]
	_shadow.text = "Shadow quality: " + str(values.get("shadow_quality", "Medium"))
	_distance.text = "Draw distance: " + str(values.get("draw_distance", "Normal"))
	_overlay.text = "Frame-rate overlay: " + ("On" if GRAPHICS.overlay_enabled() else "Off")
	_restart_note.visible = GRAPHICS.restart_required()
	_restart_now.visible = GRAPHICS.restart_required()
	_later.visible = GRAPHICS.restart_required()
	_wire_focus()


func _controls() -> Array[Control]:
	var controls: Array[Control] = []
	for child in get_children():
		if child is Button and child.visible and not child.disabled:
			controls.append(child)
	return controls


func _wire_focus() -> void:
	var controls := _controls()
	for i in controls.size():
		var button := controls[i]
		button.focus_neighbor_top = button.get_path_to(controls[maxi(0, i - 1)])
		button.focus_neighbor_bottom = button.get_path_to(controls[mini(controls.size() - 1, i + 1)])
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(button)
