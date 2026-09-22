extends CanvasLayer

## Chooses references from the existing five; never changes ownership or awards.
signal confirmed(members: Array)
signal cancelled

const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const GLYPHS := preload("res://scripts/ui/input_glyph.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const REQUIRED := 3

var _open := false
var _members: Array = []
var _selected: Array = []
var _buttons: Array[Button] = []
var _focus := 0
var _guard := 0
var _restore_mouse: int
var _root: Control
var _cards: HBoxContainer
var _status: Label
var _confirm: Button
var _legend: Label


func _ready() -> void:
	layer = 80
	add_to_group(INPUT_OWNER.GROUP)
	add_to_group(&"story_modal")
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.045, 0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 72)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)
	column.add_child(_label("Choose your tournament three", 54))
	column.add_child(_label("All five stay yours. Only the selected three can fight this round.", 36))
	column.add_child(_label("Pick in deployment order. Remove and pick again to change that order.", 36))
	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 16)
	column.add_child(_cards)
	_status = _label("", 36)
	column.add_child(_status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 24)
	column.add_child(actions)
	_confirm = Button.new()
	_confirm.text = "Register these three"
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.add_theme_font_size_override("font_size", 36)
	_confirm.pressed.connect(_submit)
	actions.add_child(_confirm)
	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.focus_mode = Control.FOCUS_NONE
	cancel_button.add_theme_font_size_override("font_size", 36)
	cancel_button.pressed.connect(_cancel)
	actions.add_child(cancel_button)
	_legend = _label("", 36)
	column.add_child(_legend)
	_root.hide()
	set_process_input(false)


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.95, 0.91))
	return label


func is_open() -> bool:
	return _open


func open_for(party: RefCounted, selected: Array = []) -> bool:
	if _open or party == null:
		return false
	_members = party.call("members")
	if _members.size() < REQUIRED:
		return false
	_selected.clear()
	for member: Variant in selected:
		if _members.has(member) and not _selected.has(member) and _selected.size() < REQUIRED:
			_selected.append(member)
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for index in _members.size():
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 36)
		button.pressed.connect(_toggle.bind(index))
		button.focus_entered.connect(_on_focus.bind(index))
		_cards.add_child(button)
		_buttons.append(button)
	_open = true
	_focus = 0
	_guard = 2
	_restore_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_root.show()
	INPUT_OWNER.set_world_hud_visible(get_tree(), false)
	set_process_input(true)
	_refresh()
	_buttons[0].grab_focus()
	return true


func close() -> void:
	if not _open:
		return
	INPUT_OWNER.suppress_pause_reopen(get_tree())
	_open = false
	_root.hide()
	set_process_input(false)
	Input.mouse_mode = _restore_mouse as Input.MouseMode
	if INPUT_OWNER.current(get_tree()) == null:
		INPUT_OWNER.set_world_hud_visible(get_tree(), true)


func _process(_delta: float) -> void:
	if _guard > 0:
		_guard -= 1
	if _open:
		_legend.text = "%s select/remove    %s register    %s cancel    Left / Right: focus" % [
			GLYPHS.action_name("menu_confirm"), GLYPHS.action_name("interact"), GLYPHS.action_name("menu_cancel")]


func _input(event: InputEvent) -> void:
	if not _open or not event.is_pressed() or event.is_echo():
		return
	if _guard > 0:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("ui_cancel"):
		_cancel()
	elif event.is_action_pressed("interact"):
		_submit()
	elif event.is_action_pressed("menu_confirm") or event.is_action_pressed("ui_accept"):
		_toggle(_focus)
	elif event.is_action_pressed("ui_right"):
		_focus = (_focus + 1) % _buttons.size()
		_buttons[_focus].grab_focus()
	elif event.is_action_pressed("ui_left"):
		_focus = (_focus - 1 + _buttons.size()) % _buttons.size()
		_buttons[_focus].grab_focus()
	else:
		return
	get_viewport().set_input_as_handled()


func _on_focus(index: int) -> void:
	_focus = index


func _toggle(index: int) -> void:
	if not _open or _guard > 0 or index < 0 or index >= _members.size():
		return
	var member: RefCounted = _members[index]
	if _selected.has(member):
		_selected.erase(member)
	elif _selected.size() < REQUIRED:
		_selected.append(member)
	_refresh()


func _refresh() -> void:
	for index in _members.size():
		var member: RefCounted = _members[index]
		var order := _selected.find(member)
		var state := CONDITION.summary(member, CONDITION.config())
		_buttons[index].text = "%s\n\n%s\nLevel %d\n\n%s\n%s\n%s%s" % [
			"Pick %d" % (order + 1) if order >= 0 else "Not entered",
			member.call("label"), int(member.get("level")),
			"Fed" if state.fed else "Needs feeding",
			"Rested" if state.rested else "Needs bed rest",
			"Happy" if state.happy else "Needs care",
			"\nNeeds reviving" if state.fainted else ("\nWake before entry" if bool(member.get("resting")) else "")]
	_confirm.disabled = _selected.size() != REQUIRED
	_status.text = "%d / %d selected. Registering saves your choice; the round still needs your consent." % [_selected.size(), REQUIRED]


func _submit() -> void:
	if not _open or _guard > 0 or _selected.size() != REQUIRED:
		return
	var chosen := _selected.duplicate()
	close()
	confirmed.emit(chosen)


func _cancel() -> void:
	if not _open:
		return
	close()
	cancelled.emit()
