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

## Same button as the pals tab's "set active": use the focused item.
const USE_ACTION := "interact"

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

## Slot the cursor is on, for the Use verb. Follows focus the same way the
## detail panel does.
var _focused: int = 0


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
	row.add_child(_panel(_grid))

	var inventory: RefCounted = _inventory()
	var slots: int = int(inventory.call("slot_count")) if inventory != null else 0
	for i in slots:
		var button := Button.new()
		button.custom_minimum_size = tile
		button.clip_text = true
		button.focus_mode = Control.FOCUS_ALL
		# The theme's default 26px clips "Small Potion  2" entirely off a
		# 168px tile with no ellipsis (clip_text hard-cuts, it doesn't
		# truncate-with-dots) -- a blind visual pass caught the quantity
		# vanishing outright. Measured: 20px is the largest size that keeps
		# the longest current item name plus a quantity inside the tile's
		# content width (168 - the theme's 28px button padding).
		button.add_theme_font_size_override("font_size", 20)
		_style_slot(button)
		var slot := i
		button.pressed.connect(func() -> void: _on_slot(slot))
		# Inspect follows focus rather than needing its own button: on a
		# controller, moving the cursor onto a thing IS looking at it.
		button.focus_entered.connect(func() -> void:
			_focused = slot
			_describe(slot))
		_grid.add_child(button)
		_buttons.append(button)

	row.add_child(_panel(_build_detail()))
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
	_read_use()

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
			var tool_max: int = int(inventory.call("max_durability_at", i))
			if tool_max > 0:
				# R2.2: a tool's count is always 1 (owned, not consumed) --
				# showing it here would say nothing; durability does.
				button.text = "%s %d/%d" % [
					db.call("item_name", id), int(inventory.call("durability_at", i)), tool_max]
			else:
				button.text = "%s %d" % [db.call("item_name", id), int(stack.get("n", 0))]
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


## Use the focused item, if it is usable. Today that is the healing
## consumables (one press heals the most-hurt creature on the belt by the
## item's `heal` value and spends one from the stack) and, R2.2, a damaged
## tool (one press repairs it fully, free — GAME_DESIGN.md 19 says "at
## appropriate station"; there is no placed workbench yet (R2.7), so this is
## the whole of R2.2's "free repair" loop until that station exists to gate
## it). Polled rather than event-driven for the same reason the pals tab's
## activate verb is: a focused Button eats events, and there is always a
## focused button here.
func _read_use() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if not Input.is_action_just_pressed(USE_ACTION):
		return

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	var stack: Dictionary = inventory.call("stack_at", _focused)
	if stack.is_empty():
		return
	var id := str(stack.get("id", ""))

	if str(db.call("kind", id)) == "tool":
		var maximum := int(inventory.call("max_durability_at", _focused))
		if maximum > 0:
			var current := int(inventory.call("durability_at", _focused))
			if current >= maximum:
				say("%s is already in good repair." % str(db.call("item_name", id)))
			else:
				inventory.call("repair_tool", _focused)
				say("%s repaired, free." % str(db.call("item_name", id)))
			return

	var heal := float((db.call("definition", id) as Dictionary).get("heal", 0.0))
	if heal <= 0.0:
		say("%s is not something you can use here." % str(db.call("item_name", id)))
		return

	var game := state()
	var party: RefCounted = game.get("party") if game != null else null
	if party == null:
		return
	var patient: RefCounted = null
	var worst := 1.0
	for member: Variant in (party.call("members") as Array):
		var pal: RefCounted = member
		var fraction := float(pal.call("hp_fraction"))
		if fraction < worst:
			worst = fraction
			patient = pal
	if patient == null:
		say("Nobody on the belt is hurt.")
		return

	var restored := float(patient.call("heal", heal))
	if restored <= 0.0:
		say("%s is already at full health." % str(patient.call("label")))
		return
	inventory.call("remove", id, 1)
	say("%s recovers %d." % [str(patient.call("label")), int(restored)])
	# No poll() here — this runs FROM poll(), whose remaining work redraws the
	# slots with the spent stack. Calling back in would recurse.


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
	var tool_max: int = int(inventory.call("max_durability_at", index))
	if tool_max > 0:
		# R2.2: durability, not a held count that would always read "1".
		_detail_count.text = "%d/%d durability" % [
			int(inventory.call("durability_at", index)), tool_max
		]
	else:
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
