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
##
## OF2: using a heal item used to always apply to whichever pal was most hurt,
## with no way for the player to choose. Pressing Use on one now opens a
## target picker instead of applying immediately — a second panel of five
## rows, same shape as the pals tab, confirmed with the SAME button the grid's
## own pick-up-then-place uses (ui_accept, not `interact`, so choosing a
## target can never re-trigger Use on the same press). While it is open the
## shell is held deaf (`menu.hold_input`, tab_settings.gd's own mechanism for
## exactly this — a sub-mode that needs `menu_cancel` for itself instead of
## letting the shell close the whole menu on it) and this tab reads
## `menu_cancel` itself to back out without spending the item.

const CONFIG_PATH := "res://data/config/menu.json"
const PARTY := preload("res://autoload/party.gd")

## Same button as the pals tab's "set active": use the focused item.
const USE_ACTION := "interact"

## Discard the focused item (with confirmation) or split its stack in two.
const DROP_ACTION := "item_drop"
const SPLIT_ACTION := "item_split"

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

## Slot of the item being targeted, or -1 when no picker is open. The item
## stays in its slot and unspent until a target is actually confirmed — this
## is not a second "held" state, nothing moves.
var _targeting: int = -1

## Slot awaiting a drop confirmation, or -1. Same shape as `_targeting`: the
## item stays put until `menu_confirm` actually discards it, so a stray press
## can never lose an item by accident.
var _confirming_drop: int = -1

var _content_row: Control = null
var _target_panel: VBoxContainer = null
var _target_header: Label = null
var _target_rows: Array = []
var _drop_confirm_label: Label = null


func build() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	_target_rows.clear()
	_held = -1
	_targeting = -1
	_confirming_drop = -1

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
	_content_row = row

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

	_target_panel = _build_target_panel()
	_target_panel.visible = false
	add_child(_target_panel)

	_drop_confirm_label = Label.new()
	_drop_confirm_label.add_theme_font_size_override("font_size", 24)
	_drop_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_drop_confirm_label.visible = false
	add_child(_drop_confirm_label)

	poll()


## Five rows, same shape as the pals tab's own list — built once, up front,
## and only rewritten, for the same focus-survival reason every other list in
## this menu does that.
func _build_target_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)

	_target_header = Label.new()
	_target_header.add_theme_font_size_override("font_size", 24)
	panel.add_child(_target_header)

	for i in PARTY.MAX_PALS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(620, 64)
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		var slot := i
		button.pressed.connect(func() -> void: _on_target_row(slot))
		panel.add_child(button)
		_target_rows.append(button)

	return panel


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
	_read_targeting_cancel()
	if _targeting >= 0:
		_refresh_target_panel()
	_read_drop()
	_read_split()

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
## consumables (opens the target picker below rather than applying
## immediately — see the header comment for why) and, R2.2, a damaged tool
## (one press repairs it fully, free — GAME_DESIGN.md 19 says "at appropriate
## station"; there is no placed workbench yet (R2.7), so this is the whole of
## R2.2's "free repair" loop until that station exists to gate it). A tool has
## no target to pick, so it still applies on this same press. Polled rather
## than event-driven for the same reason the pals tab's activate verb is: a
## focused Button eats events, and there is always a focused button here.
func _read_use() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _targeting >= 0 or _confirming_drop >= 0:
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

	var party: RefCounted = _party()
	if party == null or int(party.call("size")) == 0:
		say("Nobody on the belt yet.")
		return

	_targeting = _focused
	menu.call("hold_input", true)
	# hold_input stops the shell reading `menu_cancel` as Close, and this tab
	# reads it as Cancel instead (see _read_targeting_cancel) -- the static
	# footer has to say so too, or it keeps advertising a binding B no longer
	# has for as long as the picker is open.
	menu.call("override_footer", "A  Use on this pal        B  Cancel")
	_content_row.visible = false
	_target_panel.visible = true
	_refresh_target_panel()
	var first := _first_target_row()
	if first != null:
		first.grab_focus()


## The first row that actually holds a pal, so opening the picker focuses
## something useful instead of an empty slot the player would have to walk
## past first.
func _first_target_row() -> Control:
	var party: RefCounted = _party()
	if party == null:
		return null
	for i in _target_rows.size():
		if party.call("at", i) != null:
			return _target_rows[i]
	return null


func _refresh_target_panel() -> void:
	var party: RefCounted = _party()
	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if party == null or inventory == null or db == null:
		return

	var stack: Dictionary = inventory.call("stack_at", _targeting)
	var id := str(stack.get("id", ""))
	_target_header.text = (
		"Use %s on who?" % str(db.call("item_name", id)) if not id.is_empty() else "Use on who?"
	)

	for i in _target_rows.size():
		var button: Button = _target_rows[i]
		var pal: RefCounted = party.call("at", i)
		if pal == null:
			button.text = "  %d.  empty" % (i + 1)
			button.add_theme_color_override("font_color", Color(0.38, 0.39, 0.37))
		else:
			button.text = "%d.  %-16s HP %d / %d" % [
				i + 1, str(pal.call("label")),
				int(round(float(pal.get("hp")))), int(round(float(pal.get("max_hp"))))
			]
			button.add_theme_color_override("font_color", Color(0.87, 0.89, 0.84))


## Confirm a target. Same button the grid's own pick-up-then-place uses
## (ui_accept via Button.pressed), not `interact` — see the header comment.
func _on_target_row(index: int) -> void:
	if _targeting < 0:
		return
	var party: RefCounted = _party()
	var pal: RefCounted = party.call("at", index) if party != null else null
	if pal == null:
		say("Nothing in that slot.")
		return

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	var stack: Dictionary = inventory.call("stack_at", _targeting)
	if stack.is_empty():
		# The stack emptied out from under the picker (shouldn't happen with
		# nothing else able to touch it while the shell is held deaf, but
		# refusing outright beats spending an item that is no longer there).
		_end_targeting()
		return
	var id := str(stack.get("id", ""))
	var heal := float((db.call("definition", id) as Dictionary).get("heal", 0.0))

	var restored := float(pal.call("heal", heal))
	if restored <= 0.0:
		say("%s is already at full health." % str(pal.call("label")))
		return
	inventory.call("remove", id, 1)
	say("%s recovers %d." % [str(pal.call("label")), int(restored)])
	_end_targeting()


func _read_targeting_cancel() -> void:
	if _targeting < 0:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		say("")
		_end_targeting()


func _end_targeting() -> void:
	_targeting = -1
	menu.call("hold_input", false)
	menu.call("override_footer", "")
	_target_panel.visible = false
	_content_row.visible = true
	if _focused >= 0 and _focused < _buttons.size():
		_buttons[_focused].grab_focus()


## Discard the focused item. Two-step, same shape as `_read_use`'s heal
## picker: the first press only arms the confirmation (grid hidden, so no
## focused Button double-fires `menu_confirm` into `_on_slot`), and only a
## second, explicit `menu_confirm` actually empties the slot. `menu_cancel`
## backs out with nothing lost. Deliberate discard, not a world drop — no
## pickup-in-the-world system exists yet (that is `R3.2`'s death-satchel
## territory, not this item's), so "dropped" here means gone.
func _read_drop() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _targeting >= 0:
		return

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if inventory == null or db == null:
		return

	if _confirming_drop < 0:
		if not Input.is_action_just_pressed(DROP_ACTION):
			return
		var stack: Dictionary = inventory.call("stack_at", _focused)
		if stack.is_empty():
			return
		_confirming_drop = _focused
		menu.call("hold_input", true)
		menu.call("override_footer", "A  Discard        B  Cancel")
		_content_row.visible = false
		if _focused >= 0 and _focused < _buttons.size():
			_buttons[_focused].release_focus()
		_drop_confirm_label.text = "Discard %s? This cannot be undone." % [
			str(db.call("item_name", str(stack.get("id", ""))))
		]
		_drop_confirm_label.visible = true
		return

	if Input.is_action_just_pressed("menu_confirm"):
		var dropped: Dictionary = inventory.call("drop_slot", _confirming_drop)
		if not dropped.is_empty():
			say("Discarded %s." % str(db.call("item_name", str(dropped.get("id", "")))))
		_end_drop_confirm()
	elif Input.is_action_just_pressed("menu_cancel"):
		say("")
		_end_drop_confirm()


func _end_drop_confirm() -> void:
	_confirming_drop = -1
	menu.call("hold_input", false)
	menu.call("override_footer", "")
	_drop_confirm_label.visible = false
	_content_row.visible = true
	if _focused >= 0 and _focused < _buttons.size():
		_buttons[_focused].grab_focus()


## Split the focused stack roughly in half into the first empty slot.
## Immediate, no confirmation -- nothing is lost, only redistributed, so this
## does not need the drop verb's two-step guard.
func _read_split() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _targeting >= 0 or _confirming_drop >= 0:
		return
	if not Input.is_action_just_pressed(SPLIT_ACTION):
		return

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if inventory == null or db == null:
		return

	var stack: Dictionary = inventory.call("stack_at", _focused)
	if stack.is_empty():
		say("Nothing there to split.")
		return
	if int(stack.get("n", 0)) <= 1:
		say("Only one — nothing to split.")
		return
	if not bool(inventory.call("split_slot", _focused)):
		say("No empty slot to split into.")
		return
	say("Split %s." % str(db.call("item_name", str(stack.get("id", "")))))


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


func _party() -> RefCounted:
	var game := state()
	return game.get("party") if game != null else null


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
