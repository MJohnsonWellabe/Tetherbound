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
## at all. This is why `revision()` is constant here while the creature tab's is not.
##
## Moving a stack is pick-up-then-place rather than drag. A drag needs a pointer
## and this ships on a handheld; two presses of the same button do the same job
## with a stick and read the same way with a mouse.
##
## OF2: using a heal item used to always apply to whichever creature was most hurt,
## with no way for the player to choose. Pressing Use on one now opens a
## target picker instead of applying immediately — a second panel of five
## rows, same shape as the creatures tab, confirmed with the SAME button the grid's
## own pick-up-then-place uses (ui_accept, not `interact`, so choosing a
## target can never re-trigger Use on the same press). While it is open the
## shell is held deaf (`menu.hold_input`, tab_settings.gd's own mechanism for
## exactly this — a sub-mode that needs `menu_cancel` for itself instead of
## letting the shell close the whole menu on it) and this tab reads
## `menu_cancel` itself to back out without spending the item.
##
## OF29: a TM is an item now (see scripts/world/tm_pickup.gd's header for why
## it stopped being a progression flag), and "choose who to teach it to" is
## the same question "choose who to heal" already asks — so a TM reuses this
## exact picker rather than growing a second one. Its rows are eligible by
## `teaching.gd::can_learn` instead of by HP, and confirming SPENDS the disc.

const CONFIG_PATH := "res://data/config/menu.json"
const PARTY := preload("res://autoload/party.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
## D47: elixir caps live in data/config/progression.json, read through the
## same loader the level curve uses.
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

## Owner playtest report: "we should be able to pick what goes in the
## hotbar in our inventory." That already works -- HD2's hotbar
## (playground_hud.gd::_update_hotbar) mirrors satchel slots 0-4 directly,
## and this grid already lets a player move any item into any slot
## (pick-up-then-place, the same mechanic that powers Drop/Split). The gap
## was never the mechanic, it was that nothing in this screen told the
## player those five slots WERE the hotbar -- so placing an item in slot 3
## silently changed what D-pad-right does out in the field with no visible
## connection between the two. `_HOTBAR_ACTIONS` matches playground_hud.gd's
## own list exactly, badge-for-badge, so the glyph shown here on a slot is
## the identical glyph the field HUD shows for that same slot.
const HOTBAR_BADGE_ACTIONS := ["hotbar_1", "hotbar_2", "hotbar_3", "hotbar_4", "hotbar_5"]

## Same button as the creatures tab's "set active": use the focused item.
const USE_ACTION := "interact"

## Discard the focused stack, after a confirm -- destructive, so it gets one.
const DROP_ACTION := "backpack_drop"
## Halve the focused stack into the first empty slot. Non-destructive (both
## halves stay in the satchel), so unlike Use and Drop this applies on the
## same press with no picker or confirm.
const SPLIT_ACTION := "backpack_split"

## Put the focused item on an action slot (or take it off). Keyboard G, gamepad
## Y -- Y is `inventory`'s button, which on this tab has nothing left to do
## (`game_menu.gd` now skips a shortcut aimed at the tab already showing).
const ASSIGN_ACTION := "backpack_assign"

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
## One badge per slot button, index-matched with `_buttons`. Shows the input
## glyph of the action slot the item in that tile is bound to, or nothing.
var _hotbar_badges: Array = []

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

## Effect fields of the item being targeted, captured once when `_read_use()`
## opens the picker. `_refresh_target_panel()`, `_eligible()`,
## `_first_eligible_target_row()` and `_on_target_row()` all read these rather
## than re-deriving them from the slot, so which rows are choosable can never
## drift from what actually opened the picker mid-frame. `_targeting_revive`
## is OF32's field (a Revive item) — coded defensively here since nothing in
## the shipped item set sets it yet; a plain heal item leaves it at 0.
var _targeting_heal: float = 0.0
var _targeting_revive: float = 0.0

## OF29: the TM id being targeted, or "" when the open picker is a heal/revive
## one. Captured alongside the two numbers above and read by exactly the same
## four functions, so "which rows are choosable" has one answer whichever kind
## of item opened the picker.
var _targeting_tm: String = ""

## D47. The elixir item id being targeted, or "" when the open picker is a
## heal/revive/TM one. Same shape and same four readers as `_targeting_tm` --
## an elixir asks the identical question a TM asks ("which of yours gets
## this?") and spends itself the same way, so it reuses the picker rather than
## growing a fourth one.
var _targeting_elixir: String = ""

## TM/move lookups, loaded on first use and kept. `tm_db.gd` owns the
## compatibility list and `move_db.gd` owns power/type/slot; this screen reads
## both and duplicates neither (OF29's brief: reconcile, don't duplicate).
var _tms: RefCounted = null
var _moves: RefCounted = null

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
	_hotbar_badges.clear()
	_target_rows.clear()
	_confirm_rows.clear()
	_held = -1
	_targeting = -1
	_targeting_heal = 0.0
	_targeting_revive = 0.0
	_targeting_tm = ""
	_targeting_elixir = ""
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

		# A badge on EVERY tile, blank until the item sitting there is bound to
		# an action slot. It used to be created only on tiles 0-4 and never
		# updated, because the hotbar WAS satchel slots 0-4 -- a badge on a
		# position. The bar is assignable now, so the badge belongs to the
		# ITEM and has to travel with it; `poll()` writes the text.
		var badge := RichTextLabel.new()
		badge.bbcode_enabled = true
		badge.fit_content = true
		badge.scroll_active = false
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		badge.offset_left = 2
		badge.offset_top = 2
		badge.offset_right = 24
		badge.offset_bottom = 24
		badge.text = ""
		button.add_child(badge)
		_hotbar_badges.append(badge)

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


## Five rows, same shape as the creatures tab's own list — built once, up front,
## and only rewritten, for the same focus-survival reason every other list in
## this menu does that.
func _build_target_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 8)

	_target_header = Label.new()
	_target_header.add_theme_font_size_override("font_size", 24)
	panel.add_child(_target_header)

	for i in PARTY.MAX_CREATURES:
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
## five creature rows, because a drop confirmation has nothing to list.
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
	_read_assign()
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
	var game := state()
	for i in _buttons.size():
		var button: Button = _buttons[i]
		var qty: Label = _qty_labels[i]
		var bar: ColorRect = _durability_bars[i]
		var badge: RichTextLabel = _hotbar_badges[i] if i < _hotbar_badges.size() else null
		var stack: Dictionary = inventory.call("stack_at", i)
		if stack.is_empty():
			button.icon = null
			qty.visible = false
			bar.visible = false
			if badge != null:
				badge.text = ""
		else:
			var id := str(stack.get("id", ""))
			button.icon = _icon_for(db, id)
			# The action slot this ITEM is bound to, if any -- so the glyph sits
			# on the stack wherever the player has moved it, which is the whole
			# difference between an assignable bar and the old position mirror.
			if badge != null:
				var bound := int(game.call("hotbar_slot_of", id)) if game != null else -1
				badge.text = INPUT_GLYPH.icon(HOTBAR_BADGE_ACTIONS[bound], 18) \
						if bound >= 0 and bound < HOTBAR_BADGE_ACTIONS.size() else ""
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
## immediately — see the header comment for why), food (D29: restores the
## PLAYER's satiety and grants the item's buff — satiety lives on
## `player_vitals.gd`, never on a creature, so unlike a heal item this applies on
## this same press with no target to choose), and, R2.2, a damaged tool
## (one press repairs it fully, free — GAME_DESIGN.md 19 says "at appropriate
## station"; there is no placed workbench yet (R2.7), so this is the whole of
## R2.2's "free repair" loop until that station exists to gate it). A tool has
## no target to pick, so it still applies on this same press. OF29 adds TMs,
## which take the same target picker a heal item does — a TM has a target to
## choose and that is the whole point of the owner's report. Polled rather
## than event-driven for the same reason the creatures tab's activate verb is: a
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
	var def := db.call("definition", id) as Dictionary

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

	var satiety := float(def.get("satiety", 0.0))
	if satiety > 0.0:
		var player := _player_node()
		var vitals: RefCounted = player.get("vitals") as RefCounted if player != null else null
		if vitals == null:
			say("Nothing to eat that here.")
			return
		vitals.call("eat", satiety, def.get("buff", {}))
		inventory.call("remove", id, 1)
		say("Ate %s." % str(db.call("item_name", id)))
		return

	# D47: an elixir picks its drinker the same way a TM picks its student.
	# Placed ahead of the TM branch only because `kind` is checked in order;
	# the two are mutually exclusive kinds and neither shadows the other.
	if str(db.call("kind", id)) == "elixir":
		_targeting_elixir = id
		_open_target_picker(
			0.0, 0.0, "",
			"Nobody can take any more of that.",
			"Who drinks it? This is permanent."
		)
		return

	# OF29: a TM picks its student the same way a potion picks its patient.
	# The refusal line names the MOVE, not the disc, because "nobody can learn
	# Stone Rush" is the fact the player needs; the disc's own name is already
	# on screen in the detail panel next to the cursor.
	if str(db.call("kind", id)) == "tm":
		_open_target_picker(
			0.0, 0.0, id,
			"Nobody on the belt can learn %s." % _tm_move_name(id),
			"A  Teach this creature        B  Cancel"
		)
		return

	# Revive is OF32's field, added to items.json in parallel -- coded for here
	# defensively (a plain heal item never sets it, so `revive` reads 0.0 and
	# every branch below behaves exactly as it did before OF32 exists).
	var heal := float(def.get("heal", 0.0))
	var revive := float(def.get("revive", 0.0))
	if heal <= 0.0 and revive <= 0.0:
		say("%s is not something you can use here." % str(db.call("item_name", id)))
		return

	_open_target_picker(
		heal, revive, "",
		"Nobody needs reviving." if revive > 0.0 else "Everyone is already at full health.",
		"A  Use on this creature        B  Cancel"
	)


## Open the picker on the focused slot for an item with these effect fields,
## or refuse outright with `refusal` when no row could take it. One function
## for both kinds of targeted item (heal/revive, and OF29's TMs) so the
## "never open a picker nobody can use" rule OF22 exists to enforce cannot
## come back for the new kind alone.
func _open_target_picker(
	heal: float, revive: float, tm: String, refusal: String, footer: String
) -> void:
	var party: RefCounted = _party()
	if party == null or int(party.call("size")) == 0:
		say("Nobody on the belt yet.")
		return

	if not _any_eligible_target(party, heal, revive, tm):
		# Nobody this item could possibly help -- refuse instead of opening a
		# picker with every row greyed out and nowhere for focus to land.
		# Focus stays exactly where it already is, on the item grid.
		say(refusal)
		return

	_targeting = _focused
	_targeting_heal = heal
	_targeting_revive = revive
	_targeting_tm = tm
	menu.call("hold_input", true)
	# hold_input stops the shell reading `menu_cancel` as Close, and this tab
	# reads it as Cancel instead (see _read_targeting_cancel) -- the static
	# footer has to say so too, or it keeps advertising a binding B no longer
	# has for as long as the picker is open.
	menu.call("override_footer", footer)
	_content_row.visible = false
	_target_panel.visible = true
	_refresh_target_panel()
	var first := _first_eligible_target_row()
	if first != null:
		first.grab_focus()
	else:
		# Defensive only: `_any_eligible_target` just said yes above, so this
		# should be unreachable. If party state somehow changed between that
		# check and here, refuse cleanly rather than leave the picker open
		# with focus on nothing -- the exact failure mode this task exists
		# to close.
		say("Nobody eligible right now.")
		_end_targeting()


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
	menu.call("override_footer", "{menu_confirm} / A  Drop it        {menu_cancel} / B  Cancel")
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
## Bind the focused item to an action slot, or unbind it.
##
## Owner directive: the hotbar is "a separate assignable bar", and raw
## materials must never fill action slots. `game_state.gd::hotbar` holds the
## five bindings; this is the only place a player edits them.
##
## Pressing the verb cycles the focused item forward through the slots and then
## off the bar entirely: unbound -> 1 -> 2 -> 3 -> 4 -> 5 -> unbound. A cycle
## rather than a slot picker because it is one button on a handheld, it needs
## no new panel, and the answer is visible immediately in the badges on the
## grid and on the field HUD's own bar. `assign_hotbar` moves an already-bound
## item rather than duplicating it, so cycling can never leave the same stack
## on two slots.
func _read_assign() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if _targeting >= 0 or _confirming >= 0 or _held >= 0:
		return
	if not Input.is_action_just_pressed(ASSIGN_ACTION):
		return

	var game := state()
	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	if game == null or inventory == null or db == null:
		return
	var stack: Dictionary = inventory.call("stack_at", _focused)
	if stack.is_empty():
		say("Nothing there to put on the bar.")
		return

	var id := str(stack.get("id", ""))
	var item_name := str(db.call("item_name", id))
	if not bool(game.call("hotbar_can_hold", id)):
		# The material rule, said out loud. A silent refusal here reads as the
		# button being broken, which is how the old mirror felt when wood
		# occupied a slot and answered "not something you can use here".
		say("%s is a raw material — the bar is for things you use." % item_name)
		return

	var slots: int = (game.get("hotbar") as Array).size()
	var next := int(game.call("hotbar_slot_of", id)) + 1
	if next >= slots:
		game.call("assign_hotbar", int(game.call("hotbar_slot_of", id)), "")
		say("%s taken off the bar." % item_name)
	else:
		game.call("assign_hotbar", next, id)
		say("%s on slot %d." % [item_name, next + 1])


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


## Whether `creature` is a legal target for an item with these effect fields --
## the single source of truth `_refresh_target_panel()` (rendering),
## `_any_eligible_target()` / `_first_eligible_target_row()` (focus) and
## `_on_target_row()` (confirm) all defer to, so the three can never disagree
## about which rows are choosable. A `revive` item (> 0, OF32) targets ONLY
## fainted creatures; a `heal` item targets creatures that are alive AND below
## max HP; a creature that is neither is never a valid target for either kind.
## A `tm` (OF29) ignores HP entirely and asks `teaching.gd` instead.
## Elixir points this creature can still take on the stat the open picker's
## elixir raises. 0 means the row is refused with "already at the limit".
func _elixir_headroom(creature: RefCounted) -> int:
	if creature == null or _targeting_elixir.is_empty():
		return 0
	var db: RefCounted = _items()
	if db == null:
		return 0
	var definition := db.call("definition", _targeting_elixir) as Dictionary
	var stat := str(definition.get("elixir_stat", ""))
	var cap := int(PROGRESSION.config().get("elixirs", {}).get("cap_per_stat", 24))
	var current := 0
	match stat:
		"hp": current = int(creature.get("boost_hp"))
		"attack": current = int(creature.get("boost_attack"))
		"defence": current = int(creature.get("boost_defence"))
		_: return 0
	return maxi(0, cap - current)


func _eligible(creature: RefCounted, heal: float, revive: float, tm: String) -> bool:
	if creature == null:
		return false
	if not _targeting_elixir.is_empty():
		# Any living creature can drink one; the only refusal is a stat that
		# has already taken all the elixir points it will ever hold.
		return not bool(creature.get("fainted")) and _elixir_headroom(creature) > 0
	if not tm.is_empty():
		return _tm_teachable(creature, tm)
	var is_fainted := bool(creature.get("fainted"))
	if revive > 0.0:
		return is_fainted
	if heal > 0.0:
		return not is_fainted and float(creature.call("hp_fraction")) < 1.0
	return false


## Why a row is greyed out, shown IN the row text so the reason is never
## hidden behind a colour a player might not register on a handheld outdoors.
## "" for an eligible row (nothing to explain).
func _ineligible_reason(creature: RefCounted, heal: float, revive: float, tm: String) -> String:
	if creature == null:
		return "empty"
	if not _targeting_elixir.is_empty():
		if bool(creature.get("fainted")):
			return "fainted"
		return "" if _elixir_headroom(creature) > 0 else "already at the limit"
	if not tm.is_empty():
		if _tm_already_known(creature, tm):
			return "already knows it"
		return "" if _tm_teachable(creature, tm) else "can't learn it"
	var is_fainted := bool(creature.get("fainted"))
	if revive > 0.0:
		return "" if is_fainted else "not fainted"
	if heal > 0.0:
		if is_fainted:
			return "fainted"
		elif float(creature.call("hp_fraction")) >= 1.0:
			return "full health"
	return ""


## OF29: can this creature take this TM right now? Compatibility is
## `teaching.gd::can_learn` — the one rule GAME_DESIGN.md §13 states, read
## from `tm_db.gd`'s own list rather than re-derived here — plus "does not
## already have that exact move in the slot it would land in", which is not a
## compatibility question and so is this screen's to answer. Fainted is
## deliberately NOT a bar: teaching is not medicine.
func _tm_teachable(creature: RefCounted, tm_id: String) -> bool:
	if not TEACHING.can_learn(str(creature.get("creature_type")), tm_id, _tm_db()):
		return false
	var move_id := str(_tm_db().call("move_id", tm_id))
	if not bool(_move_db().call("has", move_id)):
		return false
	return not _tm_already_known(creature, tm_id)


## Whether the creature already carries this TM's move in the slot that move
## occupies. Reads the slot from the move's own data, exactly as
## `teaching.gd::teach()` does, so this preview and that write can never
## disagree about which slot is at stake.
func _tm_already_known(creature: RefCounted, tm_id: String) -> bool:
	var move_id := str(_tm_db().call("move_id", tm_id))
	if move_id.is_empty():
		return false
	var slot := str(_move_db().call("slot", move_id))
	if slot != "quick" and slot != "charged":
		return false
	var current := str(creature.get("move_quick" if slot == "quick" else "move_charged"))
	return current == move_id


## Is there ANY row this item could land on, checked against the live party
## rather than `_target_rows`' rendered text -- called before the picker opens
## at all, so a fully-healed party (or a belt of creatures that all already
## know a TM's move, or none that can learn it) refuses the picker instead of
## opening one nobody can use.
func _any_eligible_target(party: RefCounted, heal: float, revive: float, tm: String) -> bool:
	for i in PARTY.MAX_CREATURES:
		if _eligible(party.call("at", i), heal, revive, tm):
			return true
	return false


## The first ELIGIBLE row, so opening the picker focuses something the player
## can actually confirm instead of an empty or ineligible row -- or, same as
## the old bug, nothing at all. Returns null only when `_any_eligible_target()`
## said yes moments ago and the party changed underneath that answer; callers
## treat null as "refuse, do not open" rather than "focus nothing".
func _first_eligible_target_row() -> Control:
	var party: RefCounted = _party()
	if party == null:
		return null
	for i in _target_rows.size():
		if _eligible(party.call("at", i), _targeting_heal, _targeting_revive, _targeting_tm):
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
	if not _targeting_tm.is_empty():
		# OF29: the verb is the question. "Use a TM on who" reads as consuming
		# it on a creature the way a potion is; "teach ... to who" is what the
		# player is actually deciding.
		_target_header.text = "Teach %s to who?" % _tm_move_name(_targeting_tm)
	else:
		_target_header.text = (
			"Use %s on who?" % str(db.call("item_name", id)) if not id.is_empty() else "Use on who?"
		)

	for i in _target_rows.size():
		var button: Button = _target_rows[i]
		var creature: RefCounted = party.call("at", i)
		var eligible := _eligible(creature, _targeting_heal, _targeting_revive, _targeting_tm)
		if creature == null:
			button.text = "  %d.  empty" % (i + 1)
		else:
			var hp_text := "%d.  %-16s HP %d / %d" % [
				i + 1, str(creature.call("label")),
				int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp"))))
			]
			var reason := _ineligible_reason(
				creature, _targeting_heal, _targeting_revive, _targeting_tm
			)
			button.text = hp_text if eligible else "%s  (%s)" % [hp_text, reason]
		# Ineligible rows are greyed AND pulled out of focus order (not just
		# `disabled`, which stops a mouse click/gamepad press but NOT
		# ui_focus_next/previous walking a stick onto them) -- this is the
		# actual fix for "focus lands on nothing": a null-returning
		# `_first_eligible_target_row()` never had this problem, ineligible
		# rows sitting IN the focus chain did.
		button.disabled = not eligible
		button.focus_mode = Control.FOCUS_ALL if eligible else Control.FOCUS_NONE
		button.add_theme_color_override(
			"font_color",
			Color(0.87, 0.89, 0.84) if eligible else Color(0.38, 0.39, 0.37)
		)


## The message for a press that should not have been possible (a disabled,
## focus-skipped row pressed anyway -- e.g. a stale mouse click queued the
## same frame the picker refreshed). Never a silent no-op: every exit from
## targeting has to land focus somewhere concrete, and this one does by
## falling through to `_end_targeting()`.
func _ineligible_row_message(creature: RefCounted) -> String:
	if creature == null:
		return "Nothing in that slot."
	match _ineligible_reason(creature, _targeting_heal, _targeting_revive, _targeting_tm):
		"full health":
			return "%s is already at full health." % str(creature.call("label"))
		"fainted":
			return "%s has fainted." % str(creature.call("label"))
		"not fainted":
			return "%s hasn't fainted." % str(creature.call("label"))
		"already knows it":
			return "%s already knows %s." % [
				str(creature.call("label")), _tm_move_name(_targeting_tm)
			]
		"can't learn it":
			return "%s can't learn %s." % [
				str(creature.call("label")), _tm_move_name(_targeting_tm)
			]
		_:
			return "Can't use that there."


## Confirm a target. Same button the grid's own pick-up-then-place uses
## (ui_accept via Button.pressed), not `interact` — see the header comment.
func _on_target_row(index: int) -> void:
	if _targeting < 0:
		return
	var party: RefCounted = _party()
	var creature: RefCounted = party.call("at", index) if party != null else null
	if not _eligible(creature, _targeting_heal, _targeting_revive, _targeting_tm):
		# Ineligible rows are disabled and out of the focus chain (see
		# `_refresh_target_panel()`), so this should not be reachable through
		# normal input -- but it must never be a dead end that leaves the
		# picker sitting open and unresponsive if it somehow is.
		say(_ineligible_row_message(creature))
		_end_targeting()
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

	if not _targeting_elixir.is_empty():
		var definition := db.call("definition", id) as Dictionary
		var gained: int = int(creature.call("drink_elixir",
			str(definition.get("elixir_stat", "")),
			int(definition.get("elixir_points", 0)),
			PROGRESSION.config()))
		if gained <= 0:
			# `_eligible()` said yes a line ago; this is the same defensive
			# dead-end guard the TM branch below keeps. Never leave the picker
			# open, never spend a permanent item on nothing.
			say("%s can't take any more of that." % str(creature.call("label")))
			_end_targeting()
			return
		inventory.call("remove", id, 1)
		say("%s drank the %s. +%d, permanently." % [
			str(creature.call("label")), str(db.call("item_name", id)), gained
		])
		_end_targeting()
		return

	if not _targeting_tm.is_empty():
		if not TEACHING.teach(creature, _targeting_tm, _tm_db(), _move_db()):
			# `_eligible()` said yes a line ago, so this is the same defensive
			# dead-end guard the ineligible-row branch above is: never leave
			# the picker open, never spend the disc on a teach that failed.
			say("%s can't learn that." % str(creature.call("label")))
			_end_targeting()
			return
		# OF29, an owner-directed change to R4.4: a TM used to be permanent
		# knowledge that any number of creatures could be taught from. "Choose
		# who to teach it to" only means something if the choice costs
		# something, so one disc now teaches one creature. Reverting to the
		# never-consumed design is exactly this one line.
		inventory.call("remove", id, 1)
		say("%s learned %s!" % [str(creature.call("label")), _tm_move_name(_targeting_tm)])
		_end_targeting()
		return

	if _targeting_revive > 0.0:
		# OF32 lands `creature_instance.gd::revive()` in parallel; nothing in
		# the shipped item set sets a `revive` field yet, so this branch
		# cannot fire today. It stays honest about the contract this picker
		# was written against rather than assuming a revive item can only
		# ever arrive alongside a working revive() to call.
		if not creature.has_method("revive"):
			say("Can't revive that here yet.")
			_end_targeting()
			return
		creature.call("revive", _targeting_revive)
		inventory.call("remove", id, 1)
		say("%s is back on its feet." % str(creature.call("label")))
		_end_targeting()
		return

	var restored := float(creature.call("heal", _targeting_heal))
	inventory.call("remove", id, 1)
	say("%s recovers %d." % [str(creature.call("label")), int(restored)])
	_end_targeting()


func _read_targeting_cancel() -> void:
	if _targeting < 0:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		say("")
		_end_targeting()


func _end_targeting() -> void:
	_targeting = -1
	_targeting_heal = 0.0
	_targeting_revive = 0.0
	_targeting_tm = ""
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

	var hotbar_note := (
		"  •  Hotbar %d" % (index + 1) if index < HOTBAR_BADGE_ACTIONS.size() else ""
	)

	var stack: Dictionary = inventory.call("stack_at", index)
	if stack.is_empty():
		_preview_icon.texture = null
		_preview_name.text = "Empty"
		_detail_name.text = "Empty"
		_detail_kind.text = ""
		_detail_blurb.text = "Slot %d.%s" % [
			index + 1,
			" Whatever you place here is also hotbar slot %d." % (index + 1)
			if index < HOTBAR_BADGE_ACTIONS.size() else "",
		]
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
	_detail_kind.text = "%s%s" % [kind.to_upper(), hotbar_note]
	_detail_blurb.text = str(def.get("description", db.call("blurb", id)))

	# Primary effect number: heal or revive (consumables) or satiety (food),
	# whichever the item actually declares. `revive` is OF32's field, read
	# defensively here since nothing in the shipped item set sets it yet.
	# None present (resources, gear, tools, keys) means no effect line -- an
	# empty Label rather than a "0" that would read as a real, useless stat.
	var heal := float(def.get("heal", 0.0))
	var revive := float(def.get("revive", 0.0))
	var satiety := float(def.get("satiety", 0.0))
	if kind == "tm":
		# OF29, the owner's "I see it's stats": what the disc teaches, what
		# that move is, and who can take it. Every number here is read from
		# the move/TM tables (move_db.gd, tm_db.gd) rather than copied into
		# items.json, so a balance pass on a move updates this line for free.
		_detail_effect.text = _tm_detail(id)
	elif revive > 0.0:
		_detail_effect.text = "Revives, restores %d HP" % int(revive)
	elif heal > 0.0:
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
	elif float(def.get("satiety", 0.0)) > 0.0:
		parts.append("A  Eat")
	elif kind == "tm":
		parts.append("A  Teach a creature")
	elif kind == "consumable" and (float(def.get("heal", 0.0)) > 0.0 or float(def.get("revive", 0.0)) > 0.0):
		parts.append("A  Use on a creature")
	parts.append("Drop")
	var db: RefCounted = _items()
	if db != null and int(db.call("stack_size", id)) > 1:
		parts.append("Split")
	return "    ".join(parts)


## OF29's detail block for a `kind: "tm"` item: what it teaches, that move's
## own stats, and who can take it. `move_db.gd` owns the stats and `tm_db.gd`
## owns the compatibility list — the item entry only names its `move` id, and
## this reads the rest rather than duplicating it (the brief's "reconcile,
## don't duplicate"). The item id IS the TM id (items.json's `_comment_tm`),
## so no lookup table stands between the two.
func _tm_detail(item_id: String) -> String:
	var moves := _move_db()
	var move_id := str(_tm_db().call("move_id", item_id))
	if move_id.is_empty() or not bool(moves.call("has", move_id)):
		# A TM item whose move or TM entry is missing -- tests/test_moves.gd
		# fails the build on exactly this, so it is a data bug in progress,
		# not a state a player should ever see. Say so plainly instead of
		# printing a blank effect line that reads as "does nothing".
		return "Teaches an unknown move (%s)." % item_id
	var stats := "%s  ·  %s  ·  power %s" % [
		str(moves.call("slot", move_id)).capitalize(),
		str((moves.call("move", move_id) as Dictionary).get("type", "?")).capitalize(),
		String.num(float(moves.call("power", move_id)), 2),
	]
	var types: Array = _tm_db().call("compatible_types", item_id)
	var learners := "nothing can learn it"
	if not types.is_empty():
		var names: Array[String] = []
		for t: Variant in types:
			names.append(str(t).capitalize())
		learners = "%s creatures can learn it" % " / ".join(names)
	return "Teaches %s\n%s\n%s" % [str(moves.call("display_name", move_id)), stats, learners]


## The taught move's display name — what the picker header, the refusals and
## the confirmation all call a TM, because "Stone Rush" is the thing the
## player is choosing, not "TM: Stone Rush" the object.
func _tm_move_name(item_id: String) -> String:
	var move_id := str(_tm_db().call("move_id", item_id))
	if move_id.is_empty():
		return str(_tm_db().call("display_name", item_id))
	return str(_move_db().call("display_name", move_id))


func _tm_db() -> RefCounted:
	if _tms == null:
		_tms = TM_DB.load_default()
	return _tms


func _move_db() -> RefCounted:
	if _moves == null:
		_moves = MOVE_DB.load_default()
	return _moves


func _inventory() -> RefCounted:
	var game := state()
	return game.get("inventory") if game != null else null


func _items() -> RefCounted:
	var game := state()
	return game.get("items") if game != null else null


func _party() -> RefCounted:
	var game := state()
	return game.get("party") if game != null else null


## Same defensive lookup `tab_map.gd::_player_node()` already uses: no tree,
## no current scene, or no `Player` node all read as "nothing to eat this
## with," never a crash.
func _player_node() -> Node3D:
	if not is_inside_tree():
		return null
	var world := get_tree().get_current_scene()
	if world == null:
		return null
	return world.get_node_or_null(^"Player") as Node3D


func _config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
