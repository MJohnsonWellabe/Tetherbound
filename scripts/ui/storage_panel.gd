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

const PANEL_BG := Color(0.07, 0.09, 0.13, 0.90)
const PANEL_BORDER := Color(0.55, 0.85, 0.86, 0.65)

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
	Input.mouse_mode = _mouse_before
	get_tree().paused = _paused_before
	_chest = null


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		close()
		return
	if _chest == null or not is_instance_valid(_chest):
		close()
		return
	_refresh()


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

	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
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
	title.add_theme_font_size_override("font_size", 32)
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
	deposit_label.add_theme_font_size_override("font_size", 20)
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
	withdraw_label.add_theme_font_size_override("font_size", 20)
	withdraw_side.add_child(withdraw_label)
	_withdraw_column = VBoxContainer.new()
	_withdraw_column.add_theme_constant_override("separation", 6)
	withdraw_side.add_child(_withdraw_column)

	var hint := Label.new()
	hint.text = "Leave: B / Esc"
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
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

	_rebuild_side(_deposit_column, _deposit_rows, db, player_inventory, func(id: String, n: int) -> void:
		state.call("deposit", player_inventory, id, n))
	_rebuild_side(_withdraw_column, _withdraw_rows, db, chest_inventory, func(id: String, n: int) -> void:
		state.call("withdraw", player_inventory, id, n))


## Shared by both columns: one row per item id the SOURCE inventory
## currently holds, each moving its whole stack when pressed. Rebuilt every
## refresh rather than diffed — this screen only exists while paused at a
## chest, so a handful of button rebuilds a frame is not a cost worth
## optimising away, the same call craft_panel.gd already made for its own
## per-frame `_poll()`.
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
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.text = "  %s x%d" % [str(db.call("item_name", item_id)), have]
		button.pressed.connect(func() -> void:
			on_press.call(item_id, have)
			_refresh())
		column.add_child(button)
		rows.append(button)

	if rows.is_empty():
		var empty := Label.new()
		empty.text = "  (empty)"
		empty.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
		column.add_child(empty)
