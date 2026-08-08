extends "res://scripts/ui/menu_tab.gd"

## The satchel: a grid of slots, and what is in the one you are looking at.
##
## GAME_DESIGN.md 19: slot + stack, NO weight limit. There is no encumbrance
## readout here and there must never be one — the only number describing the
## satchel as a whole is how many slots are spoken for.
##
## Slot buttons are created ONCE per opening and then only rewritten. Rebuilding
## them when the contents change would destroy the focused node, and on a
## controller a focus that vanishes mid-press means the cursor cannot be moved
## at all. This is why `revision()` is constant here while the pal tab's is not.
##
## Moving a stack is pick-up-then-place rather than drag. A drag needs a pointer
## and this ships on a handheld; two presses of the same button do the same job
## with a stick and read the same way with a mouse.

const CONFIG_PATH := "res://data/config/menu.json"

var _grid: GridContainer = null
var _summary: Label = null
var _detail_name: Label = null
var _detail_blurb: Label = null
var _detail_count: Label = null
var _buttons: Array = []

## Slot the player has picked up, or -1. Cleared on every rebuild, so a held
## stack can never survive into a state where its source slot no longer means
## what it did.
var _held: int = -1


func build() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	_held = -1

	var config := _config()
	var backpack: Dictionary = config.get("backpack", {}) as Dictionary
	var columns: int = maxi(1, int(backpack.get("columns", 6)))
	var tile := Vector2(
		float(backpack.get("tile_width", 168)),
		float(backpack.get("tile_height", 92))
	)

	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 24)
	_summary.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
	add_child(_summary)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	_grid = GridContainer.new()
	_grid.columns = columns
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	row.add_child(_grid)

	var inventory: RefCounted = _inventory()
	var slots: int = int(inventory.call("slot_count")) if inventory != null else 0
	for i in slots:
		var button := Button.new()
		button.custom_minimum_size = tile
		button.clip_text = true
		button.focus_mode = Control.FOCUS_ALL
		var slot := i
		button.pressed.connect(func() -> void: _on_slot(slot))
		# Inspect follows focus rather than needing its own button: on a
		# controller, moving the cursor onto a thing IS looking at it.
		button.focus_entered.connect(func() -> void: _describe(slot))
		_grid.add_child(button)
		_buttons.append(button)

	row.add_child(_build_detail())
	poll()


func _build_detail() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 10)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 32)
	panel.add_child(_detail_name)

	_detail_count = Label.new()
	_detail_count.add_theme_font_size_override("font_size", 24)
	_detail_count.add_theme_color_override("font_color", Color(0.851, 0.702, 0.251))
	panel.add_child(_detail_count)

	_detail_blurb = Label.new()
	_detail_blurb.add_theme_font_size_override("font_size", 24)
	_detail_blurb.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
	_detail_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_blurb.custom_minimum_size = Vector2(360, 0)
	panel.add_child(_detail_blurb)

	return panel


func first_focus() -> Control:
	return _buttons[0] if not _buttons.is_empty() else null


## Constant. See the note at the top: the slot buttons are rewritten, never
## rebuilt, because a rebuild would destroy the focused node.
func revision() -> int:
	return 0


func poll() -> void:
	var inventory: RefCounted = _inventory()
	if inventory == null or _summary == null:
		return

	var slots: int = int(inventory.call("slot_count"))
	var used: int = int(inventory.call("used_slots"))
	_summary.text = "%d of %d slots used" % [used, slots]
	if _held >= 0:
		_summary.text += "     holding slot %d — choose where it goes" % (_held + 1)

	var db: RefCounted = _items()
	for i in _buttons.size():
		var button: Button = _buttons[i]
		var stack: Dictionary = inventory.call("stack_at", i)
		if stack.is_empty():
			button.text = ""
			button.add_theme_color_override("font_color", Color(0.4, 0.41, 0.39))
		else:
			var id := str(stack.get("id", ""))
			button.text = "%s  %d" % [db.call("item_name", id), int(stack.get("n", 0))]
			button.add_theme_color_override("font_color", db.call("colour", id))
		# The held slot is shown pressed so the player can see what they picked
		# up even after moving the cursor several slots away.
		button.button_pressed = i == _held


## Pick up, or put down. Placing onto an occupied slot merges same-item stacks
## and swaps otherwise, which is autoload/inventory.gd's rule, not this file's.
func _on_slot(index: int) -> void:
	var inventory: RefCounted = _inventory()
	if inventory == null:
		return

	if _held < 0:
		if bool(inventory.call("is_slot_empty", index)):
			say("That slot is empty.")
			return
		_held = index
		return

	if _held == index:
		_held = -1
		say("")
		return

	inventory.call("move_slot", _held, index)
	_held = -1
	poll()


func _describe(index: int) -> void:
	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if inventory == null or db == null or _detail_name == null:
		return

	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		_detail_name.text = "Empty"
		_detail_count.text = ""
		_detail_blurb.text = "Slot %d." % (index + 1)
		return

	var id := str(stack.get("id", ""))
	_detail_name.text = str(db.call("item_name", id))
	_detail_count.text = "%d held  (stacks to %d)" % [
		int(inventory.call("count", id)), int(db.call("stack_size", id))
	]
	_detail_blurb.text = str(db.call("blurb", id))


func _inventory() -> RefCounted:
	var game := state()
	return game.get("inventory") if game != null else null


func _items() -> RefCounted:
	var game := state()
	return game.get("items") if game != null else null


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
