extends CanvasLayer

## R2.7. A storage chest's transfer screen: everything in the satchel that
## can move into the chest, on the left; everything in the chest that can
## move back, on the right. One press moves the whole stack — the smallest
## coherent version of "put something down and pick it back up later",
## matching the rest of this file family's own scope discipline (craft_panel
## moves one recipe's whole cost, not a partial amount either).
##
## Built entirely in code and opened/closed the same pause-and-release-mouse
## way `craft_panel.gd` is, for the same reason: this is not a pause-menu
## tab, it only exists while standing at a placed chest.
##
## Styling: the same `UITokens` cool palette `craft_panel.gd` carries for
## spec §15 (not the warm build theme) — rows keep their two-column transfer
## layout and all mechanics untouched, just drawn with slot boxes, item icons
## and the shared font/colour tokens instead of bare `Label`/`Button` defaults.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const ROW_ICON_PX := 24

var game: Node = null

var _root: Control = null
var _deposit_column: VBoxContainer = null
var _withdraw_column: VBoxContainer = null
var _deposit_rows: Array[Button] = []
var _withdraw_rows: Array[Button] = []
var _open: bool = false
var _chest: Node = null
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	_build_shell()
	visible = false
	# RG4: see craft_panel.gd's own comment on this line -- `input_owner.gd`
	# has claimed since OW10 that this panel already joins its GROUP; it
	# never did.
	add_to_group(INPUT_OWNER.GROUP)


func is_open() -> bool:
	return _open


## `chest` is a storage_container.gd instance — its own `state` (storage_state.gd)
## is what actually holds the chest's items.
func open(chest: Node) -> void:
	_chest = chest
	if _open:
		_refresh()
		return
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	# RG1: release is determined by the live ownership graph, not by the
	# pause bit this panel happened to observe when it opened. A cached
	# true value can come from a previous modal in the same handoff and
	# restoring it after every visible panel is gone freezes the world.
	if INPUT_OWNER.current(get_tree()) == null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false
	_chest = null


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		INPUT_OWNER.suppress_pause_reopen(get_tree())
		close()
		return
	if _chest == null or not is_instance_valid(_chest):
		close()
		return
	# RG6 (owner: "Menus don't read every input still."). This used to call
	# `_refresh()` unconditionally, every frame, whether or not a deposit or
	# withdraw had actually happened -- the only thing that CAN change the
	# two lists while this screen is open (the tree is paused the whole
	# time, so nothing else in the game is running). Every row was freed and
	# rebuilt from scratch dozens of times a second for no reason, and worse
	# than the waste: a `ui_accept` press held across a rebuild could land on
	# a button that did not exist yet when the press edge fired, and Godot's
	# default `Button` only fires `pressed` on the RELEASE half of a press it
	# itself saw the start of -- so the press was silently dropped, focus and
	# all, on a screen this rebuild-happy. `_refresh()` now runs only from
	# `open()` and from a real deposit/withdraw (see the `on_press` calls
	# below), the same reactive shape `craft_panel.gd`/`shop_panel.gd`
	# already use for their own per-frame `_process`.


func _build_shell() -> void:
	for child in get_children():
		child.queue_free()

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var box := UITokens.panel_box(UITokens.BG_PANEL, UITokens.BORDER)
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	box.content_margin_left = 24
	box.content_margin_top = 20
	box.content_margin_right = 24
	box.content_margin_bottom = 20

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(680, 0)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = "Storage"
	title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	outer.add_child(title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	outer.add_child(columns)

	var deposit_side := VBoxContainer.new()
	deposit_side.add_theme_constant_override("separation", 8)
	deposit_side.custom_minimum_size = Vector2(310, 0)
	columns.add_child(deposit_side)
	var deposit_label := Label.new()
	deposit_label.text = "Satchel — press to store"
	deposit_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	deposit_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	deposit_side.add_child(deposit_label)
	_deposit_column = VBoxContainer.new()
	_deposit_column.add_theme_constant_override("separation", 6)
	deposit_side.add_child(_deposit_column)

	var withdraw_side := VBoxContainer.new()
	withdraw_side.add_theme_constant_override("separation", 8)
	withdraw_side.custom_minimum_size = Vector2(310, 0)
	columns.add_child(withdraw_side)
	var withdraw_label := Label.new()
	withdraw_label.text = "Chest — press to take"
	withdraw_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	withdraw_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	withdraw_side.add_child(withdraw_label)
	_withdraw_column = VBoxContainer.new()
	_withdraw_column.add_theme_constant_override("separation", 6)
	withdraw_side.add_child(_withdraw_column)

	var hint := Label.new()
	hint.text = "Leave: B / Esc"
	hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	outer.add_child(hint)


func _refresh() -> void:
	if game == null or _chest == null:
		return
	var db: RefCounted = game.get("items")
	var player_inventory: RefCounted = game.get("inventory")
	var state: RefCounted = _chest.get("state")
	if db == null or player_inventory == null or state == null:
		return
	var chest_inventory: RefCounted = state.get("inventory")

	# RG6 (owner: "Menus don't read every input still."). `_process` calls
	# this every frame unconditionally, and it has always freed and rebuilt
	# every row on both sides from scratch on every call -- so any focus a
	# controller press had just set was destroyed the very next frame, before
	# `ui_up`/`ui_down` could move it a second time, and nothing ever called
	# `grab_focus()` in the first place either. Capture which side/index held
	# focus before the rebuild below destroys it, so it can go back to the
	# same spot once the row exists again.
	var focus_owner: Control = get_viewport().gui_get_focus_owner() if get_viewport() != null else null
	var focus_side := ""
	var focus_index := -1
	if focus_owner != null:
		var deposit_at := _deposit_rows.find(focus_owner)
		var withdraw_at := _withdraw_rows.find(focus_owner)
		if deposit_at >= 0:
			focus_side = "deposit"
			focus_index = deposit_at
		elif withdraw_at >= 0:
			focus_side = "withdraw"
			focus_index = withdraw_at

	_rebuild_side(_deposit_column, _deposit_rows, db, player_inventory, func(id: String, n: int) -> void:
		state.call("deposit", player_inventory, id, n)
		_refresh())
	_rebuild_side(_withdraw_column, _withdraw_rows, db, chest_inventory, func(id: String, n: int) -> void:
		state.call("withdraw", player_inventory, id, n)
		_refresh())

	var restored := false
	if focus_side == "deposit" and focus_index < _deposit_rows.size():
		_deposit_rows[focus_index].grab_focus()
		restored = true
	elif focus_side == "withdraw" and focus_index < _withdraw_rows.size():
		_withdraw_rows[focus_index].grab_focus()
		restored = true
	if not restored:
		if not _deposit_rows.is_empty():
			_deposit_rows[0].grab_focus()
		elif not _withdraw_rows.is_empty():
			_withdraw_rows[0].grab_focus()

	UITokens.make_text_legible(_root)


## Shared by both columns: one row per item id the SOURCE inventory
## currently holds, each moving its whole stack when pressed. Rebuilt every
## refresh rather than diffed — this screen only exists while paused at a
## chest, so a handful of button rebuilds a frame is not a cost worth
## optimising away. Focus is restored by `_refresh()` above, once, after both
## sides have finished rebuilding — not here, which runs twice per refresh.
func _rebuild_side(
	column: VBoxContainer,
	rows: Array[Button],
	db: RefCounted,
	source: RefCounted,
	on_press: Callable
) -> void:
	for child in column.get_children():
		child.queue_free()
	rows.clear()

	var ids: Array = db.call("ids") as Array
	ids.sort()
	for id: Variant in ids:
		var item_id := str(id)
		var have := int(source.call("count", item_id))
		if have <= 0:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(290, 52)
		button.focus_mode = Control.FOCUS_ALL
		button.text = ""
		button.add_theme_stylebox_override("normal", UITokens.slot_box(false))
		button.add_theme_stylebox_override("hover", UITokens.slot_box(false))
		button.add_theme_stylebox_override("pressed", UITokens.slot_box(true))
		button.add_theme_stylebox_override("focus", UITokens.slot_box(true))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var pad := MarginContainer.new()
		pad.set_anchors_preset(Control.PRESET_FULL_RECT)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_theme_constant_override("margin_left", 10)
		pad.add_theme_constant_override("margin_right", 10)
		button.add_child(pad)

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		pad.add_child(row)

		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(ROW_ICON_PX, ROW_ICON_PX)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _icon_texture(db, item_id)
		row.add_child(icon)

		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text = "%s x%d" % [str(db.call("item_name", item_id)), have]
		label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
		label.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
		row.add_child(label)

		button.pressed.connect(func() -> void:
			on_press.call(item_id, have)
			_refresh())
		column.add_child(button)
		rows.append(button)

	if rows.is_empty():
		var empty := Label.new()
		empty.text = "  (empty)"
		empty.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
		empty.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
		column.add_child(empty)


## `id`'s 64px silhouette from `data/items/items.json`'s own `icon` field, or
## null for an unknown item — mirrors `craft_panel.gd::_icon_texture`'s own
## "degrade, never crash" handling of an id with no icon on record.
func _icon_texture(db: RefCounted, id: String) -> Texture2D:
	if db == null or id.is_empty():
		return null
	var path := str(db.call("definition", id).get("icon", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
