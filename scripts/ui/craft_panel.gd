extends CanvasLayer

## R2.4. The campfire's craft screen: every base-tier recipe, its cost, and
## whether the satchel can afford it right now.
##
## Built entirely in code, the way `tab_build.gd` builds its own list —
## there is no paired `.tscn` and does not need one. Not a pause-menu tab:
## `data/recipes/recipes.json`'s own comment and R2.4's brief both scope
## crafting to "at the campfire or workbench", so this only exists while
## standing at one, opened and closed the same way `game_menu.gd` opens
## itself — pause the tree, release the mouse, restore both on close.
##
## Godot's built-in `ui_up`/`ui_down`/`ui_accept` (bound to d-pad, stick and
## gamepad A by default, same physical inputs this project's own
## `menu_confirm` names) drive real `Button` focus navigation, so there is no
## hand-rolled cursor here — see `game_menu.gd`'s own reliance on the same
## default chain.

const COST_SHORT := Color(0.86, 0.42, 0.32)
const COST_OK := Color(0.87, 0.89, 0.84)
const STATUS_SECONDS := 2.4

var game: Node = null

var _root: Control = null
var _rows: Array[Button] = []
var _status: Label = null
var _status_left: float = 0.0
var _open: bool = false
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	_build()
	visible = false


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_poll()
	if not _rows.is_empty():
		_rows[0].grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	Input.mouse_mode = _mouse_before
	get_tree().paused = _paused_before


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()

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
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Craft"
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)

	var db := _items()
	var ids: Array = (db.call("recipe_ids") as Array) if db != null else []
	ids.sort()
	for id in ids:
		var recipe: Dictionary = db.call("recipe", id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(392, 68)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.text = "  %s\n  %s" % [str(recipe.get("name", id)), _cost_line(recipe)]
		var recipe_id := str(id)
		button.pressed.connect(func() -> void: _craft(recipe_id))
		column.add_child(button)
		_rows.append(button)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 22)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_status)

	var hint := Label.new()
	hint.text = "Leave: %s" % _cancel_glyph()
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
	column.add_child(hint)


func _cancel_glyph() -> String:
	# input_glyph.gd (HD1/EV9) covers the exploration/combat prompts named in
	# their own briefs; this screen is neither, so it names the action rather
	# than assuming that glyph set already reaches here.
	return "B / Esc"


func _process(delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		close()
		return
	if _status_left > 0.0:
		_status_left -= delta
		if _status_left <= 0.0:
			_status.text = ""
	_poll()


func _craft(id: String) -> void:
	var ok := bool(game.call("craft", id)) if game != null else false
	var db := _items()
	var name := str(db.call("recipe", id).get("name", id)) if db != null else id
	_status.text = "Crafted a %s." % name if ok else "Not enough materials for %s." % name
	_status.add_theme_color_override("font_color", COST_OK if ok else COST_SHORT)
	_status_left = STATUS_SECONDS
	_poll()


func _poll() -> void:
	var db := _items()
	if db == null:
		return
	for i in _rows.size():
		var ids: Array = db.call("recipe_ids")
		ids.sort()
		if i >= ids.size():
			continue
		var id := str(ids[i])
		var affordable: bool = bool(game.call("can_craft", id)) if game != null else false
		var colour := COST_OK if affordable else COST_SHORT
		var row := _rows[i]
		row.add_theme_color_override("font_color", colour)
		row.add_theme_color_override("font_hover_color", colour)
		row.add_theme_color_override("font_focus_color", colour)
		row.add_theme_color_override("font_pressed_color", colour)


func _cost_line(recipe: Dictionary) -> String:
	var db := _items()
	var inventory := _inventory()
	var parts: Array[String] = []
	var raw: Variant = recipe.get("cost", [])
	for entry in (raw as Array if typeof(raw) == TYPE_ARRAY else []):
		var requirement := entry as Dictionary
		var id := str(requirement.get("id", ""))
		var need := int(requirement.get("n", 0))
		var have: int = int(inventory.call("count", id)) if inventory != null else 0
		var name := str(db.call("item_name", id)) if db != null else id
		parts.append("%d %s (have %d)" % [need, name, have])
	return ", ".join(parts)


func _items() -> RefCounted:
	return game.get("items") if game != null else null


func _inventory() -> RefCounted:
	return game.get("inventory") if game != null else null
