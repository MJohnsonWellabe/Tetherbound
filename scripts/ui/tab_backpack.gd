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

## Discard the focused stack, after a confirm -- destructive, so it gets one.
const DROP_ACTION := "backpack_drop"
## Halve the focused stack into the first empty slot. Non-destructive (both
## halves stay in the satchel), so unlike Use and Drop this applies on the
## same press with no picker or confirm.
const SPLIT_ACTION := "backpack_split"

var _grid: GridContainer = null
var _summary: Label = null
var _detail_name: Label = null
var _detail_kind: Label = null
var _detail_blurb: Label = null
var _detail_effect: Label = null
var _detail_count: Label = null
var _detail_hint: Label = null
var _preview_icon: TextureRect = null
var _preview_name: Label = null
var _buttons: Array = []

## One quantity Label and one durability strip ColorRect per slot button,
## index-matched with `_buttons`. Children of the Button itself (Button is not
## a Container, so nothing auto-lays them out) rather than separate overlay
## nodes tracked by position -- keeping them attached to the slot means they
## travel with it if a future pass ever reflows the grid.
var _qty_labels: Array = []
var _durability_bars: Array = []

## Loaded icon textures, keyed by item id, so 24 slots redrawing every poll()
## does not mean 24 `load()` calls every frame. `load()` on a res:// path
## already hits Godot's resource cache, but a Dictionary lookup is cheaper
## still and makes the cost obviously bounded by "how many distinct items
## exist", not "how many frames have passed".
var _icon_cache: Dictionary = {}

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

## Slot pending a drop confirmation, or -1. Same shape as `_targeting`: the
## item stays in its slot, unspent, until the player actually confirms.
var _confirming: int = -1

var _content_row: Control = null
var _target_panel: VBoxContainer = null
var _target_header: Label = null
var _target_rows: Array = []

var _confirm_panel: VBoxContainer = null
var _confirm_header: Label = null
var _confirm_rows: Array = []


func build() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	_qty_labels.clear()
	_durability_bars.clear()
	_target_rows.clear()
	_confirm_rows.clear()
	_held = -1
	_targeting = -1
	_confirming = -1

	var config := _config()
	var backpack: Dictionary = config.get("backpack", {}) as Dictionary
	var columns: int = maxi(1, int(backpack.get("columns", 6)))
	# Spec §7 wants square 86x86 icon slots (UITokens.SLOT), not the old
	# 168x92 text tiles -- but menu.json's tile_width/tile_height keys are
	# still read by other agents' work-in-progress and this task's brief is
	# explicit that hardcoding a replacement VALUE into menu.json would be
	# the wrong move while that file is being concurrently edited. Only
	# `columns` is load-bearing here (test_menu_data.gd checks columns*rows
	# == SLOT_COUNT); the pixel size is purely this tab's own presentation,
	# so it moves onto the shared token instead of the config file.
	var tile := Vector2(UITokens.SLOT, UITokens.SLOT)

	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_summary.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	add_child(_summary)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)
	_content_row = row

	# Three columns, spec §7: grid ~35%, preview ~30%, detail ~35%. `_panel()`
	# copies size_flags_horizontal from its content but not stretch ratio (a
	# separate float), so the ratio is set on the wrapper it returns.
	_grid = GridContainer.new()
	_grid.columns = columns
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	# SHRINK_CENTER rather than EXPAND_FILL: the grid's own content (6x4 of
	# fixed 86px cells) is narrower than 35% of the row on most layouts, and
	# stretching the GridContainer itself would stretch the gaps between
	# cells rather than the cells -- centering the fixed-size grid in its
	# 35% column reads right at any window width.
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var left_panel := _panel(_grid)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.35
	row.add_child(left_panel)

	var center_panel := _panel(_build_preview())
	center_panel.size_flags_stretch_ratio = 0.30
	row.add_child(center_panel)

	var right_panel := _panel(_build_detail())
	right_panel.size_flags_stretch_ratio = 0.35
	row.add_child(right_panel)

	var inventory: RefCounted = _inventory()
	var slots: int = int(inventory.call("slot_count")) if inventory != null else 0
	for i in slots:
		var button := Button.new()
		button.custom_minimum_size = tile
		button.text = ""
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _slot_style(false))
		var slot := i
		button.pressed.connect(func() -> void: _on_slot(slot))
		# Inspect follows focus rather than needing its own button: on a
		# controller, moving the cursor onto a thing IS looking at it. The
		# selected-slot look (spec §7: teal outline + brighter bg) is driven
		# from these same signals rather than the theme's own focus ring, so
		# it survives exactly as long as the cursor sits on the slot.
		button.focus_entered.connect(func() -> void:
			_focused = slot
			button.add_theme_stylebox_override("normal", _slot_style(true))
			_describe(slot))
		button.focus_exited.connect(func() -> void:
			button.add_theme_stylebox_override("normal", _slot_style(false)))
		_grid.add_child(button)
		_buttons.append(button)

		var qty := Label.new()
		qty.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
		qty.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		qty.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		qty.offset_left = -60
		qty.offset_top = -24
		qty.offset_right = -6
		qty.offset_bottom = -3
		button.add_child(qty)
		_qty_labels.append(qty)

		var bar := ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.pivot_offset = Vector2.ZERO
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -4
		bar.offset_bottom = 0
		bar.visible = false
		button.add_child(bar)
		_durability_bars.append(bar)

	_target_panel = _build_target_panel()
	_target_panel.visible = false
	add_child(_target_panel)

	_confirm_panel = _build_confirm_panel()
	_confirm_panel.visible = false
	add_child(_confirm_panel)

	UITokens.make_text_legible(self)
	poll()


## The 86x86 slot cell (spec §7): dark and barely differentiated from the
## panel when empty, a brighter fill and a 2px teal border when selected.
## `UITokens.slot_box()` draws the cell itself; the content margins on top of
## it are this tab's own choice -- they are what keeps `expand_icon` from
## filling the WHOLE button, so an item's icon reads as sitting inside a
## slot rather than as the slot's entire surface. 13px each side leaves a
## ~60px icon area inside an 86px cell, the ~70% spec §7 asks for.
func _slot_style(selected: bool) -> StyleBoxFlat:
	var box := UITokens.slot_box(selected)
	box.content_margin_left = 13
	box.content_margin_top = 13
	box.content_margin_right = 13
	box.content_margin_bottom = 13
	return box


## Center column, spec §7: a big icon of the selected item and its name
## beneath. Built once; `_describe()` (called on focus and every poll(), same
## as the detail panel) writes the texture and text.
func _build_preview() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 16)

	var icon_wrap := CenterContainer.new()
	_preview_icon = TextureRect.new()
	_preview_icon.custom_minimum_size = Vector2(112, 112)
	_preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_wrap.add_child(_preview_icon)
	panel.add_child(icon_wrap)

	_preview_name = Label.new()
	_preview_name.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_preview_name.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_preview_name)

	return panel


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


## Two rows, built once for the same focus-survival reason as the target
## panel above: "Drop it" and "Cancel". Fixed shape, unlike the target panel's
## five pal rows, because a drop confirmation has nothing to list.
func _build_confirm_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)

	_confirm_header = Label.new()
	_confirm_header.add_theme_font_size_override("font_size", 24)
	_confirm_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_header.custom_minimum_size = Vector2(500, 0)
	panel.add_child(_confirm_header)

	for i in 2:
		var button := Button.new()
		button.custom_minimum_size = Vector2(300, 64)
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		var row := i
		button.pressed.connect(func() -> void: _on_confirm_row(row))
		panel.add_child(button)
		_confirm_rows.append(button)

	return panel


## Right column, spec §7: name, category, description, primary effect number,
## stack count, then the verb hints. Built once; `_describe()` writes it.
func _build_detail() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 10)

	_detail_name = Label.new()
	# Spec asks for 34px; UITokens has no 34 -- FONT_HEADING (32) is the
	# nearest token, and "use exclusively" (this task's own brief) outranks
	# matching the literal number when the token set does not have it.
	_detail_name.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_detail_name.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_detail_name)

	_detail_kind = Label.new()
	_detail_kind.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_kind.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	panel.add_child(_detail_kind)

	_detail_blurb = Label.new()
	_detail_blurb.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	_detail_blurb.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	_detail_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_blurb.custom_minimum_size = Vector2(320, 0)
	panel.add_child(_detail_blurb)

	_detail_effect = Label.new()
	_detail_effect.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_effect.add_theme_color_override("font_color", UITokens.SUCCESS)
	panel.add_child(_detail_effect)

	_detail_count = Label.new()
	_detail_count.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_count.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	panel.add_child(_detail_count)

	_detail_hint = Label.new()
	_detail_hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_detail_hint)

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
	_read_drop()
	_read_split()
	_read_targeting_cancel()
	_read_confirm_cancel()
	if _targeting >= 0:
		_refresh_target_panel()
	if _confirming >= 0:
		_refresh_confirm_panel()

	var slots: int = int(inventory.call("slot_count"))
	var used: int = int(inventory.call("used_slots"))
	_summary.text = "%d of %d slots used" % [used, slots]
	if _held >= 0:
		_summary.text += "     holding slot %d — choose where it goes" % (_held + 1)

	# The preview/detail columns describe whatever is FOCUSED, and that can go
	# stale mid-poll -- a Split changes the source slot's count while the
	# player is still looking at it. Re-describing every frame is cheap
	# (label text writes, no node churn) and is the same "poll writes values"
	# rule the rest of this file already follows.
	if _targeting < 0 and _confirming < 0:
		_describe(_focused)

	var db: RefCounted = _items()
	for i in _buttons.size():
		var button: Button = _buttons[i]
		var qty: Label = _qty_labels[i]
		var bar: ColorRect = _durability_bars[i]
		var stack: Dictionary = inventory.call("stack_at", i)
		if stack.is_empty():
			button.icon = null
			qty.visible = false
			bar.visible = false
		else:
			var id := str(stack.get("id", ""))
			button.icon = _icon_for(db, id)
			var tool_max: int = int(inventory.call("max_durability_at", i))
			if tool_max > 0:
				# R2.2: a tool's count is always 1 (owned, not consumed) --
				# a number here would say nothing; the durability strip does.
				qty.visible = false
				var fraction: float = float(inventory.call("durability_at", i)) / float(tool_max)
				bar.visible = true
				bar.scale = Vector2(clampf(fraction, 0.0, 1.0), 1.0)
				bar.color = _durability_tier_color(fraction)
			else:
				qty.visible = true
				qty.text = str(int(stack.get("n", 0)))
				bar.visible = false
		# The held slot is shown pressed so the player can see what they picked
		# up even after moving the cursor several slots away.
		button.button_pressed = i == _held


## The loaded icon for `id`, cached -- see `_icon_cache`'s own comment.
func _icon_for(db: RefCounted, id: String) -> Texture2D:
	if _icon_cache.has(id):
		return _icon_cache[id]
	var path := str((db.call("definition", id) as Dictionary).get("icon", ""))
	var texture: Texture2D = load(path) as Texture2D if not path.is_empty() else null
	_icon_cache[id] = texture
	return texture


## Spec §7: HP_GREEN above half, WARNING above a quarter, DANGER below --
## the same three-tier shape `combat_hud.gd`'s HP bars already use for a
## fraction that is draining rather than a fraction that is spending.
func _durability_tier_color(fraction: float) -> Color:
	if fraction > 0.5:
		return UITokens.HP_GREEN
	elif fraction > 0.25:
		return UITokens.WARNING
	else:
		return UITokens.DANGER


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
	if _targeting >= 0 or _confirming >= 0:
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


## Drop the focused stack, after a confirm -- it deletes the stack for good
## (see autoload/inventory.gd::drop_slot()'s own comment: there is no
## ground-item entity for it to become, so this is genuinely a delete).
## Confirmed the same way Use's target picker is: `menu.hold_input` so the
## shell stops treating `menu_cancel` as Close, this tab reads it as Cancel
## instead, and the footer says so while the panel is open.
func _read_drop() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _targeting >= 0 or _confirming >= 0 or _held >= 0:
		return
	if not Input.is_action_just_pressed(DROP_ACTION):
		return

	var inventory: RefCounted = _inventory()
	var stack: Dictionary = inventory.call("stack_at", _focused)
	if stack.is_empty():
		say("Nothing there to drop.")
		return

	_confirming = _focused
	menu.call("hold_input", true)
	menu.call("override_footer", "A  Drop it        B  Cancel")
	_content_row.visible = false
	_confirm_panel.visible = true
	_refresh_confirm_panel()
	if not _confirm_rows.is_empty():
		_confirm_rows[0].grab_focus()


func _refresh_confirm_panel() -> void:
	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if inventory == null or db == null or _confirm_header == null:
		return

	var stack: Dictionary = inventory.call("stack_at", _confirming)
	if stack.is_empty():
		_confirm_header.text = "That slot is empty now."
	else:
		var id := str(stack.get("id", ""))
		var tool_max: int = int(inventory.call("max_durability_at", _confirming))
		var what := (
			str(db.call("item_name", id)) if tool_max > 0
			else "%d %s" % [int(stack.get("n", 0)), str(db.call("item_name", id))]
		)
		_confirm_header.text = "Drop %s? This cannot be undone." % what

	if _confirm_rows.size() >= 2:
		_confirm_rows[0].text = "Drop it"
		_confirm_rows[1].text = "Cancel"


## Row 0 is "Drop it", row 1 is "Cancel" -- see _build_confirm_panel().
func _on_confirm_row(index: int) -> void:
	if _confirming < 0:
		return
	if index != 0:
		say("")
		_end_confirm()
		return

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	var stack: Dictionary = inventory.call("stack_at", _confirming)
	if stack.is_empty():
		# Nothing left to drop (shouldn't happen while the shell is held deaf,
		# but refusing beats reporting a drop that didn't happen).
		_end_confirm()
		return

	var id := str(stack.get("id", ""))
	var n := int(stack.get("n", 0))
	inventory.call("drop_slot", _confirming)
	if n > 1:
		say("Dropped %d %s." % [n, str(db.call("item_name", id))])
	else:
		say("Dropped %s." % str(db.call("item_name", id)))
	_end_confirm()


func _read_confirm_cancel() -> void:
	if _confirming < 0:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		say("")
		_end_confirm()


func _end_confirm() -> void:
	_confirming = -1
	menu.call("hold_input", false)
	menu.call("override_footer", "")
	_confirm_panel.visible = false
	_content_row.visible = true
	if _focused >= 0 and _focused < _buttons.size():
		_buttons[_focused].grab_focus()


## Halve the focused stack into the first empty slot. Non-destructive (both
## halves stay in the satchel) and needs no destination choice the way Drop's
## confirm or Use's target does, so it applies on the same press.
func _read_split() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _targeting >= 0 or _confirming >= 0 or _held >= 0:
		return
	if not Input.is_action_just_pressed(SPLIT_ACTION):
		return

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	var stack: Dictionary = inventory.call("stack_at", _focused)
	if stack.is_empty():
		say("Nothing there to split.")
		return

	var id := str(stack.get("id", ""))
	var n := int(stack.get("n", 0))
	var cap := int(db.call("stack_size", id))
	if cap <= 1:
		say("%s can't be split." % str(db.call("item_name", id)))
		return
	if n < 2:
		say("Not enough %s to split." % str(db.call("item_name", id)))
		return

	var target := _first_empty_slot(_focused)
	if target < 0:
		say("No empty slot to split into.")
		return

	var amount := n / 2
	if not bool(inventory.call("split_slot", _focused, target, amount)):
		say("Can't split that.")
		return
	say("Split %d %s into slot %d." % [amount, str(db.call("item_name", id)), target + 1])


## First empty slot other than `exclude`, or -1 when the satchel is full.
func _first_empty_slot(exclude: int) -> int:
	var inventory: RefCounted = _inventory()
	if inventory == null:
		return -1
	var slots: int = int(inventory.call("slot_count"))
	for i in slots:
		if i != exclude and bool(inventory.call("is_slot_empty", i)):
			return i
	return -1


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


## Writes both the center preview and the right detail column for whatever
## is in `index` -- called on every focus change AND every poll() (unlike
## the rest of this file's mostly-static build, these two panels describe
## the FOCUSED slot's live state, e.g. a stack count that changes while the
## player is still looking at it after a Split).
func _describe(index: int) -> void:
	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if inventory == null or db == null or _detail_name == null:
		return

	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		_preview_icon.texture = null
		_preview_name.text = "Empty"
		_detail_name.text = "Empty"
		_detail_kind.text = ""
		_detail_blurb.text = "Slot %d." % (index + 1)
		_detail_effect.text = ""
		_detail_count.text = ""
		_detail_hint.text = ""
		return

	var id := str(stack.get("id", ""))
	var def := db.call("definition", id) as Dictionary
	var name := str(db.call("item_name", id))
	var kind := str(db.call("kind", id))

	_preview_icon.texture = _icon_for(db, id)
	_preview_name.text = name

	_detail_name.text = name
	_detail_kind.text = kind.to_upper()
	_detail_blurb.text = str(def.get("description", db.call("blurb", id)))

	# Primary effect number: heal (consumables) or satiety (food), whichever
	# the item actually declares. Neither present (resources, gear, tools,
	# keys) means no effect line -- an empty Label rather than a "0" that
	# would read as a real, useless stat.
	var heal := float(def.get("heal", 0.0))
	var satiety := float(def.get("satiety", 0.0))
	if heal > 0.0:
		_detail_effect.text = "Heals %d HP" % int(heal)
	elif satiety > 0.0:
		_detail_effect.text = "Restores %d satiety" % int(satiety)
	else:
		_detail_effect.text = ""

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

	_detail_hint.text = _verb_hint(id, kind, def, tool_max)


## The Use/Drop/Split legend for whatever is focused. Only offers a verb the
## item can actually take -- Use never appears on a resource or a key, and a
## tool's Use reads as repair rather than the generic word, matching what
## `_read_use()` actually does with it.
func _verb_hint(id: String, kind: String, def: Dictionary, tool_max: int) -> String:
	var parts: Array[String] = []
	if tool_max > 0:
		parts.append("A  Repair (free)")
	elif kind == "consumable" and float(def.get("heal", 0.0)) > 0.0:
		parts.append("A  Use on a pal")
	parts.append("Drop")
	var db: RefCounted = _items()
	if db != null and int(db.call("stack_size", id)) > 1:
		parts.append("Split")
	return "    ".join(parts)


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
