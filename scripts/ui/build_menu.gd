extends CanvasLayer

## The Valheim-style build menu (spec 12, `docs/decisions/D34`).
##
## Unlike `game_menu.gd`, the world stays VISIBLE AND LIVE behind this panel —
## no tree pause, at most a light dim wash — which is the whole "Valheim
## feel" the spec asks for: you are still standing where you were, looking at
## a catalogue, not cutting away to a separate screen.
##
## Reachable today from the pause menu's Build tab (`tab_build.gd`), which
## lazily instantiates and opens this the same way `camp.gd`/
## `storage_container.gd` lazily instantiate `craft_panel.gd`/
## `storage_panel.gd` — added straight under `get_tree().root`, not parented
## to any one scene, since it has to survive whichever world scene opened it.
## A hammer hotkey that opens this directly from exploration is a real gap
## this pass does not close — see the task's own note on that.
##
## Grid cells show ONLY their thumbnail (spec 12.3) — no piece name in the
## grid at all, which is why `buildables.json` grew a `thumbnail` field this
## same pass. The bottom strip is the only place a piece's name and cost
## live.

const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
## D28's warm/brass Theme resource, built for exactly this kind of surface —
## applied to the panel so every Button/Label under it (the category tabs,
## most of all) picks up its brass focus ring and button states for free,
## on top of the `UITokens.BUILD_*` colours this file reaches for directly.
const BUILD_THEME := preload("res://assets/ui/theme/build_theme.tres")
const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")

## Order the tab row draws in when present — `docs/decisions/D34`. A category
## with zero buildables in it (SURVIVAL/FARMING/TETHER stay unbuilt per that
## decision) draws no tab at all (spec 12.2), which is why this is a fixed
## order list rather than "whatever order the JSON happens to list ids in."
const CATEGORY_ORDER: Array[String] = ["survival", "crafting", "structures", "furniture"]
const CATEGORY_LABELS := {
	"survival": "Survival",
	"crafting": "Crafting",
	"structures": "Structures",
	"furniture": "Furniture",
}
const CATEGORY_ICONS := {
	"survival": "res://assets/ui/icons/ui/cat_survival.png",
	"crafting": "res://assets/ui/icons/ui/cat_crafting.png",
	"structures": "res://assets/ui/icons/ui/cat_structures.png",
	"furniture": "res://assets/ui/icons/ui/cat_furniture.png",
}

const COLUMNS := 10
const CELL_SIZE := 92
const CELL_GAP := 7

## Which piece id was last chosen in each category — a plain `static var`
## rather than a save-file field: this is a within-session convenience
## ("I keep placing walls, land the cursor back on Wall"), not state anyone
## needs to persist across a restart.
static var _last_piece_per_category: Dictionary = {}

var _panel: PanelContainer = null
var _tab_row: HBoxContainer = null
var _tab_buttons: Array[Button] = []
var _tab_underlines: Array[ColorRect] = []
var _grid: GridContainer = null
var _cell_buttons: Array[Button] = []
var _detail_name: Label = null
var _detail_rows: VBoxContainer = null
var _footer: RichTextLabel = null

var _categories: Array[String] = []
var _category_index := 0
var _catalogue_by_category: Dictionary = {}
var _selected_index := 0
var _open := false
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
## Same focus-owner watch `game_menu.gd` uses for its own `ui_focus` tick.
var _last_focus_owner: Control = null


func _ready() -> void:
	layer = UITokens.LAYER_WORLD_PANELS
	visible = false
	_build_ui()


func is_open() -> bool:
	return _open


## Opens on whichever category/piece was last used this session (spec 17),
## or the first category/first piece the first time. Frees the mouse the
## same save/restore way `game_menu.gd::open`/`close` do, WITHOUT pausing the
## tree — see this file's header on why that is the point, not an oversight.
func open() -> void:
	if _open:
		return
	var game := _game()
	if game == null:
		return
	_open = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild_catalogue()
	_update_footer()
	visible = true
	if not _categories.is_empty():
		_select_category(_category_index)
	else:
		_describe(-1)


## `play_cue` is false only from `_pick`'s own close-after-select: that
## moment already played `ui_accept`/`ui_error` for the pick itself, and
## stacking `ui_cancel` on top would read as "picking a piece also cancelled
## something" rather than the single confirm it actually is.
func close(play_cue: bool = true) -> void:
	if not _open:
		return
	if play_cue:
		AUDIO_CUES.play(&"ui_cancel")
	_open = false
	visible = false
	Input.mouse_mode = _mouse_before


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel") or Input.is_action_just_pressed("build_cancel"):
		close()
		return
	# `tool_cycle` (keyboard Q / right-stick click) and the rotate-left/right
	# actions (mouse wheel / LT-RB, LB-RT depending on binding — see
	# project.godot) are both free while this menu is open: placement's own
	# reading of them only happens once a piece is armed and the menu has
	# already closed. Reusing them here is "bumpers switch category" (task
	# brief) without a sixth new input action.
	if Input.is_action_just_pressed("tool_cycle") or Input.is_action_just_pressed("build_rotate_right"):
		_select_category(_category_index + 1)
	elif Input.is_action_just_pressed("build_rotate_left"):
		_select_category(_category_index - 1)

	# Focus tick (spec 20): same "only on a real change" watch as
	# `game_menu.gd`, covering both stick-driven grid focus and category
	# switches without a second wiring path.
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != _last_focus_owner:
		_last_focus_owner = focus_owner
		if focus_owner != null:
			AUDIO_CUES.play(&"ui_focus")

	# Cheap (at most a handful of cost rows) and keeps owned/required numbers
	# live if the player gathers or crafts while the menu sits open over a
	# still-running world.
	_describe(_selected_index)


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


# --- catalogue ---------------------------------------------------------


func _rebuild_catalogue() -> void:
	var game := _game()
	var items: RefCounted = game.get("items") if game != null else null
	var all: Array = items.call("buildables") if items != null else []

	_catalogue_by_category.clear()
	for entry: Variant in all:
		var piece: Dictionary = entry
		var category := str(piece.get("category", ""))
		if not _catalogue_by_category.has(category):
			_catalogue_by_category[category] = []
		(_catalogue_by_category[category] as Array).append(piece)

	_categories.clear()
	for category in CATEGORY_ORDER:
		if _catalogue_by_category.has(category) and not (_catalogue_by_category[category] as Array).is_empty():
			_categories.append(category)
	if _category_index >= _categories.size():
		_category_index = 0
	_build_tabs()


func _current_pieces() -> Array:
	if _categories.is_empty():
		return []
	return _catalogue_by_category.get(_categories[_category_index], [])


# --- layout --------------------------------------------------------------


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	# At most a 25% wash (task brief) — the world stays readable behind the
	# panel, unlike the pause menu's own opaque backdrop.
	dim.color = Color(0, 0, 0, 0.25)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	# A menu, per this task's own scenes note: a full-rect Control here has
	# to STOP the mouse, or a click meant for a grid cell falls through to
	# the (still-live) world behind it.
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(center)

	_panel = PanelContainer.new()
	_panel.theme = BUILD_THEME
	_panel.custom_minimum_size = Vector2(1200, 680)
	_panel.add_theme_stylebox_override("panel", UITokens.build_panel_box())
	center.add_child(_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(root_vbox)

	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(_tab_row)

	# A thin brass line under the tab row (task brief) — the same
	# `BUILD_ACCENT` the selected tab's own underline uses, so the row reads
	# as one continuous rail with one segment lit.
	var rail := ColorRect.new()
	rail.color = Color(UITokens.BUILD_ACCENT, 0.35)
	rail.custom_minimum_size = Vector2(0, 2)
	root_vbox.add_child(rail)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", CELL_GAP)
	_grid.add_theme_constant_override("v_separation", CELL_GAP)
	scroll.add_child(_grid)

	var strip := PanelContainer.new()
	var strip_box := UITokens.build_panel_box()
	strip_box.bg_color = UITokens.BUILD_BG_ALT
	strip.add_theme_stylebox_override("panel", strip_box)
	root_vbox.add_child(strip)

	var strip_vbox := VBoxContainer.new()
	strip_vbox.add_theme_constant_override("separation", 6)
	strip.add_child(strip_vbox)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	_detail_name.add_theme_color_override("font_color", UITokens.BUILD_TEXT)
	strip_vbox.add_child(_detail_name)

	_detail_rows = VBoxContainer.new()
	_detail_rows.add_theme_constant_override("separation", 2)
	strip_vbox.add_child(_detail_rows)

	_footer = RichTextLabel.new()
	_footer.bbcode_enabled = true
	_footer.fit_content = true
	_footer.scroll_active = false
	_footer.custom_minimum_size = Vector2(0, 36)
	root_vbox.add_child(_footer)

	UITokens.make_text_legible(root_vbox)


func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	_tab_buttons.clear()
	_tab_underlines.clear()

	for i in _categories.size():
		var category := _categories[i]
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)

		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.text = "  %s" % str(CATEGORY_LABELS.get(category, category.capitalize()))
		button.add_theme_font_size_override("font_size", UITokens.FONT_BUTTON)
		button.add_theme_constant_override("icon_max_width", 28)
		var icon_path: String = CATEGORY_ICONS.get(category, "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			button.icon = load(icon_path)
		var slot := i
		button.pressed.connect(func() -> void: _select_category(slot))
		column.add_child(button)

		# The "brass underline" the task brief asks for on the selected tab —
		# `build_theme.tres`'s own toggled-button style already darkens/lifts
		# the button itself; this is the second, unambiguous signal so
		# "selected" reads even at a glance across the row.
		var underline := ColorRect.new()
		underline.color = UITokens.BUILD_ACCENT
		underline.custom_minimum_size = Vector2(0, 3)
		underline.visible = false
		column.add_child(underline)

		_tab_row.add_child(column)
		_tab_buttons.append(button)
		_tab_underlines.append(underline)


func _select_category(index: int) -> void:
	if _categories.is_empty():
		return
	var wanted := posmod(index, _categories.size())
	# Only a real switch counts (spec 20's "on category switch") -- `open()`
	# calls this with the already-current index to redraw the remembered
	# category, and that redraw is not a player-driven switch.
	if wanted != _category_index:
		AUDIO_CUES.play(&"ui_tab")
	_category_index = wanted
	for i in _tab_buttons.size():
		_tab_buttons[i].button_pressed = i == _category_index
		_tab_underlines[i].visible = i == _category_index
	_build_grid()


## Rebuilds the thumbnail grid for the current category and lands focus on
## the remembered piece (spec 17), or the first cell if none is remembered.
func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cell_buttons.clear()

	var pieces := _current_pieces()
	var category := _categories[_category_index] if not _categories.is_empty() else ""
	var remembered := str(_last_piece_per_category.get(category, ""))
	var target_index := 0

	for i in pieces.size():
		var piece: Dictionary = pieces[i]
		if str(piece.get("id", "")) == remembered:
			target_index = i

		var button := Button.new()
		button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		button.focus_mode = Control.FOCUS_ALL
		button.flat = true
		button.add_theme_stylebox_override("normal", UITokens.slot_box(false))
		var highlight := UITokens.slot_box(true)
		highlight.border_color = UITokens.BUILD_ACCENT
		highlight.bg_color = highlight.bg_color.lightened(0.10)
		button.add_theme_stylebox_override("focus", highlight)
		button.add_theme_stylebox_override("hover", highlight)

		var center := CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(center)

		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(CELL_SIZE - 16, CELL_SIZE - 16)
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var thumbnail_path := str(piece.get("thumbnail", ""))
		if thumbnail_path != "" and ResourceLoader.exists(thumbnail_path):
			thumb.texture = load(thumbnail_path)
		center.add_child(thumb)

		var slot := i
		button.pressed.connect(func() -> void: _pick(slot))
		button.focus_entered.connect(func() -> void: _selected_index = slot; _describe(slot))
		_grid.add_child(button)
		_cell_buttons.append(button)

	_selected_index = target_index
	if not _cell_buttons.is_empty():
		_cell_buttons[_selected_index].call_deferred("grab_focus")
	_describe(_selected_index)


## Piece name + resource rows (spec 12.4): "[icon] owned / required", green
## when the satchel has enough, red when it does not — or, while free build
## is on, the existing gold banner text in its place (`D16`; this reads the
## SAME `GameState.free_build` toggle `tab_build.gd` already respects, not a
## second opinion about it).
func _describe(index: int) -> void:
	if _detail_name == null:
		return
	var pieces := _current_pieces()
	for child in _detail_rows.get_children():
		child.queue_free()
	if index < 0 or index >= pieces.size():
		_detail_name.text = ""
		return

	var piece: Dictionary = pieces[index]
	_detail_name.text = str(piece.get("name", piece.get("id", "?")))

	var game := _game()
	var free := game != null and bool(game.get("free_build"))
	if free:
		var banner := Label.new()
		banner.text = "Free build is on — nothing you place here will cost materials."
		banner.add_theme_color_override("font_color", Color(0.851, 0.702, 0.251))
		banner.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
		_detail_rows.add_child(banner)
		return

	var inventory: RefCounted = game.get("inventory") if game != null else null
	var items: RefCounted = game.get("items") if game != null else null
	var cost: Array = piece.get("cost", [])
	for requirement: Variant in cost:
		var need: Dictionary = requirement
		var id := str(need.get("id", ""))
		var required := int(need.get("n", 0))
		var owned := int(inventory.call("count", id)) if inventory != null else 0

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(22, 22)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path := "res://assets/ui/icons/items/%s.png" % id
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		row.add_child(icon)

		var name := str(items.call("item_name", id)) if items != null else id
		var label := Label.new()
		label.text = "%s  %d / %d" % [name, owned, required]
		label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
		label.add_theme_color_override("font_color", UITokens.SUCCESS if owned >= required else UITokens.DANGER)
		row.add_child(label)

		_detail_rows.add_child(row)


func _update_footer() -> void:
	_footer.text = "%s Place    %s Cancel    %s/%s Rotate    %s Snap step" % [
		INPUT_GLYPH.icon("build_place", 28),
		INPUT_GLYPH.icon("build_cancel", 28),
		INPUT_GLYPH.icon("build_rotate_left", 28),
		INPUT_GLYPH.icon("build_rotate_right", 28),
		INPUT_GLYPH.icon("build_snap_cycle", 28),
	]


## Arms the piece and closes — placement itself is `build_placer.gd`'s job,
## the same handoff `tab_build.gd::_on_pick` already used before this menu
## existed.
func _pick(index: int) -> void:
	var pieces := _current_pieces()
	if index < 0 or index >= pieces.size():
		return
	var piece: Dictionary = pieces[index]
	var id := str(piece.get("id", ""))
	var game := _game()

	# An unaffordable pick refuses to arm — the same contract the old flat
	# tab kept ("needs more than you are carrying", pinned by
	# `tests/smoke_free_build.gd`): arming a piece the placer would only
	# refuse hands the player a ghost that can never land. The menu stays
	# open so they can pick something they can pay for.
	var free := game != null and bool(game.get("free_build"))
	if not free and game != null and not bool(game.call("can_afford", id)):
		AUDIO_CUES.play(&"ui_error")
		return
	AUDIO_CUES.play(&"ui_accept")

	if not _categories.is_empty():
		_last_piece_per_category[_categories[_category_index]] = id
	if game != null:
		game.set("pending_build", id)
	close(false)
