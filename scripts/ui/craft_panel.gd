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
##
## Layout: spec §15's three-zone Tetherbound treatment (list / hero / detail),
## the same shape `tab_build.gd` already uses for the build catalogue, but in
## `UITokens`' cool palette rather than that tab's warm brass — this is a
## campfire screen, not a build-menu one, and D28 draws that line at the
## token set, not just at the font. "Selected" is simply "focused": with a
## handful of recipes and pad-only navigation there is no separate hover
## state worth tracking, so the left row's focus stylebox IS the highlight
## `_describe` reads off of.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")

const STATUS_SECONDS := 2.4
const ROW_ICON_PX := 40
const CENTER_ICON_PX := 96
const INGREDIENT_ICON_PX := 24

var game: Node = null

var _root: Control = null
var _rows: Array[Button] = []
var _cost_labels: Array[Label] = []
var _recipe_ids: Array[String] = []
var _selected: int = 0

var _center_icon: TextureRect = null
var _center_name: Label = null
var _ingredients_col: VBoxContainer = null
var _output_line: Label = null
var _craft_hint: Label = null
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


## OF30. The list of recipes the player knows can GROW between two visits to a
## campfire — Tam writes the orb recipe down and the row has to be there the
## next time this opens. `_build()` runs once in `_ready()`, so the check is
## here: rebuild only when the known set has actually changed, which is never
## on the common path and exactly once on the interesting one.
## No Game autoload means no item database either (`_items()` reads it off the
## same node), so there is nothing to list and every other method here already
## degrades to drawing an empty panel rather than erroring.
func _known_ids() -> Array:
	if game == null:
		return []
	return game.call("known_recipe_ids") as Array


func _known_ids_differ_from_the_list_on_screen() -> bool:
	var known: Array = _known_ids()
	if known.size() != _recipe_ids.size():
		return true
	for i in known.size():
		if str(known[i]) != _recipe_ids[i]:
			return true
	return false


func open() -> void:
	if _open:
		return
	if _known_ids_differ_from_the_list_on_screen():
		_build()
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
		_select(0)


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
	_cost_labels.clear()
	_recipe_ids.clear()

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
	box.content_margin_left = 28
	box.content_margin_top = 22
	box.content_margin_right = 28
	box.content_margin_bottom = 20

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.custom_minimum_size = Vector2(880, 0)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	panel.add_child(outer)

	var title := Label.new()
	title.text = "Craft"
	title.add_theme_font_size_override("font_size", UITokens.FONT_TITLE)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	outer.add_child(title)

	var zones := HBoxContainer.new()
	zones.add_theme_constant_override("separation", 22)
	outer.add_child(zones)

	zones.add_child(_build_list_zone())
	zones.add_child(_build_center_zone())
	zones.add_child(_build_right_zone())

	var hint := Label.new()
	hint.text = "Leave: %s" % _cancel_glyph()
	hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	outer.add_child(hint)

	UITokens.make_text_legible(_root)
	_describe(0)


## LEFT: one row per recipe — output icon, name, and an affordability-coloured
## cost summary, exactly the fields `_poll` and `_describe` keep live.
##
## OF30: KNOWN recipes, not all of them. A locked recipe is absent rather than
## greyed — a greyed row with no way to explain itself ("come back when someone
## has taught you this") is the silent-refusal shape OF23 was raised about, and
## an orb recipe the player has never been told exists has nothing to say yet.
func _build_list_zone() -> Control:
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	side.custom_minimum_size = Vector2(300, 0)

	var db := _items()
	for id: Variant in _known_ids():
		var recipe_id := str(id)
		_recipe_ids.append(recipe_id)
		var recipe: Dictionary = db.call("recipe", recipe_id) if db != null else {}
		side.add_child(_make_row(recipe_id, recipe))

	return side


func _make_row(id: String, recipe: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(300, 64)
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
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_bottom", 6)
	button.add_child(pad)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	pad.add_child(row)

	var output: Dictionary = recipe.get("output", {})
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(ROW_ICON_PX, ROW_ICON_PX)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_texture(str(output.get("id", "")))
	row.add_child(icon)

	var text_col := VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_theme_constant_override("separation", 2)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	var name := Label.new()
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.text = str(recipe.get("name", id))
	name.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	name.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	text_col.add_child(name)

	var cost_label := Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.text = _cost_line(recipe)
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	text_col.add_child(cost_label)
	_cost_labels.append(cost_label)

	button.pressed.connect(func() -> void: _craft(id))
	var index := _rows.size()
	button.focus_entered.connect(func() -> void: _select(index))
	_rows.append(button)
	return button


## CENTER: the selected recipe's output, large — the one thing the player is
## actually deciding whether to spend materials on.
func _build_center_zone() -> Control:
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	side.custom_minimum_size = Vector2(200, 0)
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_center_icon = TextureRect.new()
	_center_icon.custom_minimum_size = Vector2(CENTER_ICON_PX, CENTER_ICON_PX)
	_center_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_center_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	side.add_child(_center_icon)

	_center_name = Label.new()
	_center_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_name.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_center_name.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	side.add_child(_center_name)

	return side


## RIGHT: what it costs, whether the satchel has it, what it does, and how to
## commit — the detail column `tab_build.gd`'s own list/detail split already
## proved out for the same "can I afford this" decision.
func _build_right_zone() -> Control:
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 10)
	side.custom_minimum_size = Vector2(280, 0)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var ingredients_header := Label.new()
	ingredients_header.text = "Ingredients"
	ingredients_header.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	ingredients_header.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	side.add_child(ingredients_header)

	_ingredients_col = VBoxContainer.new()
	_ingredients_col.add_theme_constant_override("separation", 6)
	side.add_child(_ingredients_col)

	_output_line = Label.new()
	_output_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_output_line.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_output_line.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	side.add_child(_output_line)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	side.add_child(_status)

	_craft_hint = Label.new()
	_craft_hint.text = "Craft: A / Enter"
	_craft_hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_craft_hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	side.add_child(_craft_hint)

	return side


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
	_status.add_theme_color_override("font_color", UITokens.SUCCESS if ok else UITokens.DANGER)
	_status_left = STATUS_SECONDS
	_poll()


## Focus moved onto a different row: redraw the hero/detail columns for it.
func _select(index: int) -> void:
	_selected = index
	_describe(index)


func _poll() -> void:
	var db := _items()
	if db == null:
		return
	for i in _rows.size():
		if i >= _recipe_ids.size():
			continue
		var id := _recipe_ids[i]
		var affordable: bool = bool(game.call("can_craft", id)) if game != null else false
		var colour := UITokens.SUCCESS if affordable else UITokens.DANGER
		if i < _cost_labels.size():
			_cost_labels[i].add_theme_color_override("font_color", colour)
	_describe(_selected)


## Fills the center hero and right detail columns for recipe `index`.
func _describe(index: int) -> void:
	if _center_name == null or index < 0 or index >= _recipe_ids.size():
		return
	var db := _items()
	if db == null:
		return
	var id := _recipe_ids[index]
	var recipe: Dictionary = db.call("recipe", id)
	var output: Dictionary = recipe.get("output", {})
	var output_id := str(output.get("id", ""))

	_center_icon.texture = _icon_texture(output_id)
	_center_name.text = str(recipe.get("name", id))

	for child in _ingredients_col.get_children():
		child.queue_free()

	var inventory := _inventory()
	var raw: Variant = recipe.get("cost", [])
	for entry: Variant in (raw as Array if typeof(raw) == TYPE_ARRAY else []):
		var requirement := entry as Dictionary
		var item_id := str(requirement.get("id", ""))
		var need := int(requirement.get("n", 0))
		var have: int = int(inventory.call("count", item_id)) if inventory != null else 0
		var enough := have >= need
		_ingredients_col.add_child(_make_ingredient_row(item_id, need, have, enough))

	_output_line.text = "Makes: %s — %s" % [str(recipe.get("name", id)), str(recipe.get("blurb", ""))]


func _make_ingredient_row(item_id: String, need: int, have: int, enough: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(INGREDIENT_ICON_PX, INGREDIENT_ICON_PX)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon_texture(item_id)
	row.add_child(icon)

	var db := _items()
	var name := str(db.call("item_name", item_id)) if db != null else item_id
	var label := Label.new()
	label.text = "%s %d / have %d" % [name, need, have]
	label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	label.add_theme_color_override("font_color", UITokens.SUCCESS if enough else UITokens.DANGER)
	row.add_child(label)

	return row


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


## `id`'s 64px silhouette from `data/items/items.json`'s own `icon` field, or
## null for an unknown item — a null `TextureRect.texture` just draws nothing,
## the same "degrade, never crash" rule `item_db.gd`'s header comment states
## for every other unknown-id lookup in this file.
func _icon_texture(id: String) -> Texture2D:
	var db := _items()
	if db == null or id.is_empty():
		return null
	var path := str(db.call("definition", id).get("icon", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _items() -> RefCounted:
	return game.get("items") if game != null else null


func _inventory() -> RefCounted:
	return game.get("inventory") if game != null else null
