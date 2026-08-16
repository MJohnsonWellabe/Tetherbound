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
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

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

# OW11. The owner's report on this screen was *"it's asking you to build
# through a menu and you can't see shit."* The arm-then-place handoff it sounds
# like it is describing was already right — `_pick` arms the piece and closes on
# the same press, and `build_placer.gd` draws a perfectly legible ghost once it
# does (both confirmed from real frames this pass). What was wrong is this
# panel's FOOTPRINT while you are choosing.
#
# It was a fixed 1200x680 slab in a `CenterContainer`, which on the Ally's
# 1920x1080 puts an opaque brown rectangle over y=200..880 — the middle 63% of
# the screen, centred on exactly the ground the ghost is about to stand on. Most
# of that was empty: the grid was a hard 10 columns however few pieces the
# category held, so Structures' five thumbnails sat in a void ten wide.
#
# So the selector docks along the bottom and sizes to its contents. Measured at
# 1920x1080 by `tests/smoke_build_menu_footprint.gd`: 1200x680 covering the
# centre point and 39.4% of the screen, down to 803x439 clear of the centre and
# 17.0%. The three constants below are what set that.

## How far the docked selector's bottom edge sits above the screen bottom.
##
## Small on purpose: the selector lands ON the hotbar block rather than above
## it, which is what Valheim itself does — the build bar replaces the hotbar
## while you are building, it does not stack on top of it.
##
## Occupying that space is not enough by itself to own it. This panel's
## background is semi-transparent, so the first captured frame of the docked
## menu had the hotbar's five numbered slot chips reading straight THROUGH the
## thumbnail row, looking like missing art. `playground_hud.gd` hides the
## hotbar and the context prompt while this menu is open
## (`_yield_bottom_to_build_menu`) — that is the half that makes the swap read
## as one surface replacing another.
##
## Docking above the hotbar instead was tried and does not work: the hotbar's
## top edge is 300px up, and no panel carrying a tab row, a thumbnail row, a
## cost strip and a footer fits into the 240px left below the screen's centre
## line. It would have put the selector back over the middle of the screen —
## the exact thing this item is fixing.
const BOTTOM_MARGIN := 24
## Enough width that the footer's five glyph/label pairs and a cost row read
## as a deliberate strip rather than a cramped one. Categories wider than this
## grow past it on their own; nothing forces the panel back down to it.
const PANEL_MIN_WIDTH := 640
## Rows of thumbnails visible before the grid starts scrolling. Two keeps the
## docked panel short; the `ScrollContainer` still reaches the rest.
const MAX_VISIBLE_ROWS := 2

## How dim an unaffordable grid cell reads next to a full-alpha one it stands
## beside (OF23) -- greyed, not hidden or disabled: the button still has to
## take the press so `_pick` can say WHY it refuses (spec's own "silent
## refusal" complaint, one level up from the missing text this whole item
## fixes).
const UNAFFORDABLE_ALPHA := 0.4

## OF23: how long a refusal/shortfall line sits in `_message` before it clears
## -- same duration `game_menu.gd`'s own `_status` line uses, so a message
## surface next to that one does not read as tuned differently for no reason.
const STATUS_SECONDS := 3.0

## OF24: two doors into this menu now -- `tab_build.gd`'s pause-menu launcher
## and `playground_hud.gd`'s hammer hotkey, straight from the world. Both
## need "the one build menu", not each lazily minting their own competing
## instance that steals focus/mouse-mode from the other. The lookup-or-create
## group is the same convention `interaction_arbiter.gd`'s own `GROUP`
## constant already uses for "find the one of these that exists".
## OF23 also reads this group from `game_menu.gd::_read_actions` before it
## reacts to `menu_cancel` — see that method's own comment on why.
const GROUP := "build_menu"
const SELF_PATH := "res://scripts/ui/build_menu.gd"


## The shared instance, creating it under `tree.root` the first time anything
## asks. Callers that only need "is one open right now" should search `GROUP`
## themselves rather than calling this -- it creates on a miss, which a mere
## open-check should never do.
static func get_or_make(tree: SceneTree) -> CanvasLayer:
	for node in tree.get_nodes_in_group(GROUP):
		if node is CanvasLayer:
			return node as CanvasLayer
	var menu: CanvasLayer = (load(SELF_PATH) as GDScript).new()
	tree.root.add_child(menu)
	return menu

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
## OW11: held so `_build_grid` can size it to the rows the current category
## actually needs. Left to `SIZE_EXPAND_FILL` it ate the whole 680px panel and
## drew most of the void this pass removes.
var _scroll: ScrollContainer = null
var _cell_buttons: Array[Button] = []
var _detail_name: Label = null
var _detail_rows: VBoxContainer = null
var _message: Label = null
var _message_left := 0.0
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
	add_to_group(GROUP)
	# OW10: this panel does not pause the tree (see the header — that is the
	# point of it), so the HUD keeps polling the world's verbs underneath it and
	# a d-pad press meant for this grid also ate a hotbar slot. Joining
	# `input_owner.gd`'s group is the whole fix and the whole contract: every
	# world-verb poll asks that one question, so nothing here has to be kept in
	# sync with what the HUD happens to check.
	add_to_group(INPUT_OWNER.GROUP)
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
	_say("")
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


func _process(delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel") or Input.is_action_just_pressed("build_cancel"):
		# OF23: `menu_cancel` and `build_cancel` share gamepad B (project.godot),
		# so the SAME still-just-pressed press that closes this menu is also
		# what `game_menu.gd::_read_actions` reads as "open the pause menu" on
		# its own `_process` this same frame -- pressing B to leave the build
		# screen would fall straight back into the pause menu it never opened
		# from. Tell it to sit out the next couple frames before we close.
		var game := _game()
		var pause_menu: Node = game.call("menu") if game != null else null
		if pause_menu != null and pause_menu.has_method("suppress_reopen"):
			pause_menu.call("suppress_reopen")
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

	# Cheap (at most a handful of cost rows, at most COLUMNS cells) and keeps
	# owned/required numbers AND which cells are greyed live if the player
	# gathers or crafts while the menu sits open over a still-running world.
	_describe(_selected_index)
	_refresh_afford_state()

	if _message_left > 0.0:
		_message_left -= delta
		if _message_left <= 0.0:
			_message.text = ""


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


## Empties a container NOW, not at the end of the frame.
##
## OW11: `queue_free` alone leaves the old children parented until the frame
## ends, so a container that clears and refills in the same call spends that
## frame holding both sets — and its minimum size is computed from both.
## `_describe` does exactly that on EVERY `_process` tick, so the cost strip
## never saw a frame without its own stale copy in it and laid out at double
## height permanently: 196px of strip for the two cost rows that measure 90.
## That inflation was most of the docked panel's excess height.
##
## `remove_child` first takes them out of the layout immediately; `queue_free`
## still does the actual freeing safely afterwards.
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


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

	# OW11: a bottom dock, not a centre stage. The outer VBox fills the screen
	# and pushes its children to the END, so the row below hugs the bottom
	# edge; the spacer under it lifts the whole thing clear of the hotbar. The
	# inner HBox centres the panel horizontally without stretching it, which is
	# what lets the panel keep its own content width.
	#
	# Both are MOUSE_FILTER_IGNORE: `Dim` above already STOPs the mouse across
	# the full rect, which is what keeps a click meant for a grid cell from
	# falling through to the still-live world behind it. A second STOP here
	# would only take that job away from the node whose comment explains it.
	var dock := VBoxContainer.new()
	dock.name = "Dock"
	dock.set_anchors_preset(Control.PRESET_FULL_RECT)
	dock.alignment = BoxContainer.ALIGNMENT_END
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_theme_constant_override("separation", 0)
	add_child(dock)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(row)

	var margin := Control.new()
	margin.name = "BottomMargin"
	margin.custom_minimum_size = Vector2(0, BOTTOM_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(margin)

	_panel = PanelContainer.new()
	_panel.theme = BUILD_THEME
	# Width only, and a floor rather than a size: the panel takes its height
	# from the tab row, the grid's own rows and the strip, so a category with
	# one row of pieces draws a short panel instead of padding 680px of brown
	# out to a fixed number.
	_panel.custom_minimum_size = Vector2(PANEL_MIN_WIDTH, 0)
	_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_panel.add_theme_stylebox_override("panel", UITokens.build_panel_box())
	row.add_child(_panel)

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

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	root_vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", CELL_GAP)
	_grid.add_theme_constant_override("v_separation", CELL_GAP)
	_scroll.add_child(_grid)

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

	# OF23: the menu's own message surface -- a refused pick used to say
	# nothing at all past a `ui_error` sound. Lives in the strip, right under
	# the cost rows it is explaining, so a refusal reads next to the numbers
	# that caused it rather than somewhere the player was not looking.
	_message = Label.new()
	_message.text = ""
	_message.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_message.add_theme_color_override("font_color", UITokens.DANGER)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	strip_vbox.add_child(_message)

	_footer = RichTextLabel.new()
	_footer.bbcode_enabled = true
	_footer.fit_content = true
	_footer.scroll_active = false
	_footer.custom_minimum_size = Vector2(0, 36)
	root_vbox.add_child(_footer)

	UITokens.make_text_legible(root_vbox)


func _build_tabs() -> void:
	_clear(_tab_row)
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
	_clear(_grid)
	_cell_buttons.clear()

	var pieces := _current_pieces()
	var category := _categories[_category_index] if not _categories.is_empty() else ""
	var remembered := str(_last_piece_per_category.get(category, ""))
	var target_index := 0

	# OW11: the grid is as wide as the category has pieces, up to COLUMNS —
	# not a hard ten every time. Structures holds six, and a fixed ten-column
	# grid spread those six across a row four cells wider than anything drew
	# in, which is most of what read as "you can't see shit".
	_size_grid_to(pieces.size())

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
		# Same reason as the cost-row icon below: a thumbnail bigger than the
		# cell would otherwise drag the whole grid out past CELL_SIZE rather
		# than being scaled down into it.
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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
		_grab_when_in_tree.call_deferred(_cell_buttons[_selected_index])
	_describe(_selected_index)
	_refresh_afford_state()


## Lands focus on a grid cell, one frame late and only if that cell is still
## real.
##
## OW11: `_clear` above now unparents the old cells immediately instead of
## leaving them for the end of the frame, which is what stops the grid from
## laying out at double width. The cost is that a `grab_focus` already
## deferred onto a cell from a PREVIOUS `_build_grid` fires after that cell has
## left the tree — `Condition "!is_inside_tree()" is true`, and no focus. Two
## category switches in quick succession is enough to hit it, and a build menu
## that loses focus is a build menu a controller cannot drive at all.
func _grab_when_in_tree(button: Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree():
		button.grab_focus()


## OW11: columns follow the piece count so a short category draws a short
## grid, and the scroll viewport is given the exact height of the rows that
## produces (capped at MAX_VISIBLE_ROWS). Both numbers are set here rather
## than in `_build_ui` because both change with the category, and the panel
## takes its own height from whatever this leaves behind.
func _size_grid_to(count: int) -> void:
	if _grid == null or _scroll == null:
		return
	var columns := clampi(count, 1, COLUMNS)
	_grid.columns = columns
	var rows := ceili(float(count) / float(columns)) if count > 0 else 1
	var shown := clampi(rows, 1, MAX_VISIBLE_ROWS)
	_scroll.custom_minimum_size = Vector2(0, shown * CELL_SIZE + (shown - 1) * CELL_GAP)


## OF23: dims every grid cell the satchel cannot currently pay for -- greyed
## AT A GLANCE, without needing to focus each one and read the strip. The
## button underneath stays fully pressable (no `disabled`): a press on a
## greyed cell is still a real refusal, and `_pick` is what explains why.
## Free build cells never grey (`GameState.can_afford` already reads it), so
## this reads correctly with no special-casing here.
func _refresh_afford_state() -> void:
	var game := _game()
	if game == null:
		return
	var free := bool(game.get("free_build"))
	var pieces := _current_pieces()
	for i in _cell_buttons.size():
		if i >= pieces.size():
			continue
		var id := str((pieces[i] as Dictionary).get("id", ""))
		var afford := free or bool(game.call("can_afford", id))
		_cell_buttons[i].modulate = Color(1, 1, 1, 1.0 if afford else UNAFFORDABLE_ALPHA)


## Piece name + resource rows (spec 12.4): "[icon] owned / required", green
## when the satchel has enough, red when it does not — or, while free build
## is on, the existing gold banner text in its place (`D16`; this reads the
## SAME `GameState.free_build` toggle `tab_build.gd` already respects, not a
## second opinion about it).
func _describe(index: int) -> void:
	if _detail_name == null:
		return
	var pieces := _current_pieces()
	_clear(_detail_rows)
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
		# OW11: without this a TextureRect's minimum size is its TEXTURE's own
		# size, which made the 22x22 above decorative — the item icons are 64px
		# files, so every cost row laid out 64 tall instead of 22. Three rows of
		# that is 96px of strip on a panel this item exists to make short.
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var icon_path := "res://assets/ui/icons/items/%s.png" % id
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		row.add_child(icon)

		var name := str(items.call("item_name", id)) if items != null else id
		var label := Label.new()
		# OF23: a short row still has to say the actual number missing, not just
		# a colour -- "2 / 6" red reads as "not enough" but not "how much".
		if owned < required:
			label.text = "%s  %d / %d — need %d more" % [name, owned, required, required - owned]
		else:
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
	var piece_name := str(piece.get("name", id))
	var game := _game()

	# An unaffordable pick refuses to arm — the same contract the old flat
	# tab kept ("needs more than you are carrying", pinned by
	# `tests/smoke_free_build.gd`): arming a piece the placer would only
	# refuse hands the player a ghost that can never land. The menu stays
	# open so they can pick something they can pay for.
	#
	# OF23: a refusal used to be JUST the `ui_error` cue — every press on an
	# unaffordable cell looked dead, which owner-reported as "the build menu
	# doesn't work at all." Now it says exactly what is short, in the same
	# `_message` surface the grid's greyed cells are already hinting at.
	var free := game != null and bool(game.get("free_build"))
	if not free and game != null and not bool(game.call("can_afford", id)):
		AUDIO_CUES.play(&"ui_error")
		var shortfall := _shortfall_text(game, id)
		_say(("Can't afford %s — %s" % [piece_name, shortfall]) if not shortfall.is_empty() \
			else "Can't afford %s" % piece_name)
		return
	AUDIO_CUES.play(&"ui_accept")

	if not _categories.is_empty():
		_last_piece_per_category[_categories[_category_index]] = id
	if game != null:
		game.set("pending_build", id)
	close(false)


## "need 4 more Wood" — joined across every resource the satchel is still
## short of for `id`, right now. Empty when `id` is unknown, free build is on
## (`GameState.build_cost_for` already returns no cost then), or the satchel
## already covers it — callers decide what an empty string means.
func _shortfall_text(game: Node, id: String) -> String:
	if game == null:
		return ""
	var items: RefCounted = game.get("items")
	var inventory: RefCounted = game.get("inventory")
	if items == null or inventory == null:
		return ""
	var parts: Array[String] = []
	for requirement: Variant in (game.call("build_cost_for", id) as Array):
		var need: Dictionary = requirement
		var item_id := str(need.get("id", ""))
		var required := int(need.get("n", 0))
		var owned := int(inventory.call("count", item_id))
		var missing := required - owned
		if missing > 0:
			parts.append("%d more %s" % [missing, str(items.call("item_name", item_id))])
	if parts.is_empty():
		return ""
	return "need " + ", ".join(parts)


## The build menu's own message surface (OF23) — a refusal or shortfall line
## under the cost rows it explains. Same decay-on-a-timer shape as
## `game_menu.gd::say`, so this reads as the same kind of thing rather than a
## bespoke toast.
func _say(message: String) -> void:
	if _message == null:
		return
	_message.text = message
	_message_left = STATUS_SECONDS if not message.is_empty() else 0.0
