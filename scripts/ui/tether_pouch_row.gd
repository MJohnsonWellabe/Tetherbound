extends HBoxContainer

## Embedded in Satchel's existing input_owner panel; this row is not a modal.
## Assignment stays an item id binding, never moves a stack. Shared owner must
## persist accepted assignments in the existing character save transaction.
signal assignment_requested(index: int, item_id: String)
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
var _buttons: Array[Button] = []
var _assigned: Array = []
var _items: Dictionary = {}
var _tier := 0
var _outside_combat := false
var _selected_item := ""

func _ready() -> void:
	var label := Label.new()
	label.text = "Command pouch"
	label.add_theme_font_size_override("font_size", 22)
	add_child(label)
	for index: int in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(130, 48)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_request_assignment.bind(index))
		add_child(button)
		_buttons.append(button)
	visible = false

func present(assigned: Array, tier: int, items: Dictionary, counts: Dictionary,
		outside_combat: bool, selected_item: String) -> void:
	visible = COMMANDS.enabled("ui_enabled")
	if not visible or _buttons.is_empty(): return
	_assigned = assigned.duplicate()
	_items = items
	_tier = tier
	_outside_combat = outside_combat
	_selected_item = selected_item
	var profile := COMMANDS.tier_profile(tier)
	var size := int(profile.get("pouch_size", 0))
	for index: int in _buttons.size():
		var button := _buttons[index]
		button.visible = index < size
		var id := str(assigned[index]) if index < assigned.size() else ""
		var item: Dictionary = items.get(id, {})
		button.text = "%s ×%d" % [str(item.get("name", "Empty")), int(counts.get(id, 0))]
		button.disabled = not outside_combat or (not selected_item.is_empty() and not COMMANDS.support_item(items.get(selected_item)))
		button.tooltip_text = "Assign selected item; stacks stay in your Satchel." if outside_combat else "Fill your pouch outside combat."

func _request_assignment(index: int) -> void:
	if not _outside_combat or index < 0 or index >= int(COMMANDS.tier_profile(_tier).get("pouch_size", 0)): return
	if not _selected_item.is_empty() and not COMMANDS.support_item(_items.get(_selected_item)): return
	assignment_requested.emit(index, _selected_item)

func focus_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for button: Button in _buttons:
		if button.visible: buttons.append(button)
	return buttons
