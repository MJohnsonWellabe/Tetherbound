extends "res://scripts/ui/menu_tab.gd"

## What you can build, what it costs, and whether you can afford it right now.
##
## The catalogue is data/items/buildables.json. This file contains no piece
## names, no costs and no categories, which is the point: GAME_DESIGN.md 20
## lists a dozen buildable categories and the eleventh one after the camp should
## cost a JSON block and nothing else.
##
## Confirming a piece does NOT place geometry. Placement, grid-snapping,
## neighbour-snapping and rotation belong to the building system (M8 /
## `BG1`), which lives in `scripts/build/build_placer.gd` and
## `scripts/build/build_grid.gd` — this tab only arms `GameState.pending_build`
## and says so. A build button that silently did nothing would read as a bug;
## one that arms a selection is honest about where the work stops, and the
## seam is already the right shape for the system that reads it.
##
## NOTHING HERE DECIDES WHAT A PIECE COSTS. Affordability is `GameState`'s
## `can_afford`, the cost list is `GameState.build_cost_for`, and this file only
## draws what they say. That is what lets the free-build development toggle
## (Settings > Gameplay, docs/decisions/D16) exist in one place instead of five.

var _rows: Array = []
var _focused: int = 0

## Says, the whole time free build is on, that materials are not being spent.
## Temporary, with the toggle it reports; deleting both is one edit each.
var _free_note: Label = null

var _detail_name: Label = null
var _detail_blurb: Label = null
var _detail_cost: RichTextLabel = null
var _detail_contains: Label = null
var _detail_status: Label = null
var _detail_status_pill: PanelContainer = null

## A shortfall line needs its own colour independent of the rest of the cost
## block — matching an "unaffordable" ingredient to the affordable ones was
## exactly what a blind visual pass on menu_build.png caught: the same white
## text on both, and "Not enough to hand" was the only place short of reading
## every number that said which ingredient was the problem. Warm red, not
## gold: gold already means "important progression state" (the tab focus
## ring, the free-build banner), and a shortfall is a warning, not that.
const COST_SHORT := Color(0.86, 0.42, 0.32)
const COST_OK := Color(0.87, 0.89, 0.84)
const COST_FREE := Color(0.6, 0.62, 0.55)

## The bible's Crafting target (§16) names a bullet inventory's own target list
## does not: "clear primary action button." A blind visual-judge pass on this
## tab's real reskin (`tools/capture_menu_panels.gd`) confirmed the ingredient
## rows and hero panel land, but named this gap specifically -- nothing on
## screen reads as a discrete, stateful button, only the plain status line.
## Pressing the already-focused recipe row still IS the build verb (unchanged,
## same as every other tab in this menu); this pill is a non-focusable visual
## treatment of `_detail_status`, not a second focusable Control, so it cannot
## regress controller focus navigation the way a real second Button could.
const CTA_READY_BG := Color(0.13, 0.22, 0.16, 0.9)
const CTA_READY_BORDER := Color(0.38, 0.64, 0.30, 0.9)
const CTA_BLOCKED_BG := Color(0.22, 0.13, 0.12, 0.9)
const CTA_BLOCKED_BORDER := Color(0.86, 0.42, 0.32, 0.55)


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()

	# Above the catalogue rather than inside the detail panel: a cheat that
	# changes what everything costs has to be visible before anything is
	# selected, or the first bug report is a costing bug that is not one.
	_free_note = Label.new()
	_free_note.add_theme_font_size_override("font_size", 24)
	_free_note.add_theme_color_override("font_color", Color(0.851, 0.702, 0.251))
	_free_note.text = "Free build is on — nothing you build will cost materials.  Settings > Gameplay turns it off."
	_free_note.visible = false
	add_child(_free_note)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.custom_minimum_size = Vector2(480, 0)
	row.add_child(_panel(list))

	var catalogue := _catalogue()
	if catalogue.is_empty():
		var empty := Label.new()
		empty.text = "Nothing is buildable yet."
		empty.add_theme_color_override("font_color", Color(0.55, 0.57, 0.52))
		list.add_child(empty)
	for i in catalogue.size():
		var entry: Dictionary = catalogue[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(460, 66)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.focus_mode = Control.FOCUS_ALL
		button.text = "  %s" % str(entry.get("name", entry.get("id", "?")))
		var slot := i
		button.pressed.connect(func() -> void: _on_pick(slot))
		button.focus_entered.connect(func() -> void: _focused = slot)
		list.add_child(button)
		_rows.append(button)

	row.add_child(_panel(_build_detail()))
	poll()


func _build_detail() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 12)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 36)
	panel.add_child(_detail_name)

	_detail_blurb = Label.new()
	_detail_blurb.add_theme_font_size_override("font_size", 24)
	_detail_blurb.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
	_detail_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_blurb.custom_minimum_size = Vector2(460, 0)
	panel.add_child(_detail_blurb)

	_detail_contains = Label.new()
	_detail_contains.add_theme_font_size_override("font_size", 24)
	panel.add_child(_detail_contains)

	_detail_cost = RichTextLabel.new()
	_detail_cost.bbcode_enabled = true
	_detail_cost.fit_content = true
	_detail_cost.scroll_active = false
	_detail_cost.add_theme_font_size_override("normal_font_size", 26)
	# BBCode, because affordability is per-LINE: "12 wood, and you have 3" has to
	# be readable as one shortfall inside a list of three costs you do have.
	panel.add_child(_detail_cost)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", 24)
	_detail_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Coloured per message in _describe(), not fixed here. A blind visual pass
	# on menu_build.png caught this label wearing the same gold whether it
	# said "Ready to build" or "Not enough to hand" -- gold means progression/
	# positive state everywhere else in this HUD language, and a blocked
	# message wearing it undercuts that meaning rather than reinforcing it.
	_detail_status_pill = PanelContainer.new()
	var pill_box := StyleBoxFlat.new()
	pill_box.corner_radius_top_left = 10
	pill_box.corner_radius_top_right = 10
	pill_box.corner_radius_bottom_left = 10
	pill_box.corner_radius_bottom_right = 10
	pill_box.border_width_left = 2
	pill_box.border_width_right = 2
	pill_box.border_width_top = 2
	pill_box.border_width_bottom = 2
	pill_box.content_margin_left = 16.0
	pill_box.content_margin_right = 16.0
	pill_box.content_margin_top = 10.0
	pill_box.content_margin_bottom = 10.0
	_detail_status_pill.add_theme_stylebox_override("panel", pill_box)
	_detail_status_pill.add_child(_detail_status)
	panel.add_child(_detail_status_pill)

	return panel


func first_focus() -> Control:
	return _rows[0] if not _rows.is_empty() else null


## Constant: the catalogue is data and does not change while the game runs. The
## affordability numbers on it do, and those are written every frame by poll().
func revision() -> int:
	return 0


func poll() -> void:
	if _free_note != null:
		_free_note.visible = _free_build()

	var catalogue := _catalogue()
	for i in _rows.size():
		if i >= catalogue.size():
			continue
		var affordable := _can_afford(catalogue[i])
		# Dimmed, never hidden. A piece you cannot afford is the thing that tells
		# you what to go and gather; removing it from the list removes the goal.
		#
		# Set on every text state Button reads (normal/hover/focus/pressed), not
		# just "font_color" (normal). A Button falls back to font_focus_color
		# while it holds focus, so a normal-only override is invisible on
		# whichever row the cursor is actually sitting on — which, with one
		# recipe in the catalogue, is every row there is.
		var colour := Color(0.87, 0.89, 0.84) if affordable else Color(0.5, 0.51, 0.48)
		var row := _rows[i] as Button
		row.add_theme_color_override("font_color", colour)
		row.add_theme_color_override("font_hover_color", colour)
		row.add_theme_color_override("font_focus_color", colour)
		row.add_theme_color_override("font_pressed_color", colour)
	_describe(_focused)


func _describe(index: int) -> void:
	if _detail_name == null:
		return
	var catalogue := _catalogue()
	if index < 0 or index >= catalogue.size():
		_detail_name.text = ""
		_detail_blurb.text = ""
		_detail_cost.text = ""
		_detail_contains.text = ""
		_detail_status.text = ""
		if _detail_status_pill != null:
			_detail_status_pill.visible = false
		return
	if _detail_status_pill != null:
		_detail_status_pill.visible = true

	var entry: Dictionary = catalogue[index]
	_detail_name.text = str(entry.get("name", entry.get("id", "?")))
	_detail_blurb.text = str(entry.get("blurb", ""))

	var contains: Variant = entry.get("contains", [])
	_detail_contains.text = ""
	if typeof(contains) == TYPE_ARRAY and not (contains as Array).is_empty():
		var names: Array[String] = []
		for piece in contains as Array:
			names.append(str(piece))
		_detail_contains.text = "Includes:  %s" % ", ".join(names)

	var free := _free_build()
	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	var lines: Array[String] = []
	for requirement in _cost(entry):
		var id := str(requirement.get("id", ""))
		var need := int(requirement.get("n", 0))
		var have: int = int(inventory.call("count", id)) if inventory != null else 0
		var name := str(db.call("item_name", id)) if db != null else id
		var short := not free and have < need
		# "Wood 12, you have 62" rather than "Wood 62 / 12". A bare pair of
		# numbers does not say which one is the cost, and the player reading it
		# is deciding whether to go and gather. While free build is on there is
		# no shortfall to mark: the numbers are what the piece WOULD cost.
		#
		# Coloured per line, not as one block: a shortfall has to stand out
		# next to the ingredients you DO have, the same way a "— short" suffix
		# alone did not (see COST_SHORT's comment above).
		var line := "%s  %d       you have %d%s" % [
			name, need, have, "" if free or not short else "   — short"
		]
		var line_colour := COST_SHORT if short else (COST_FREE if free else COST_OK)
		lines.append("[color=#%s]%s[/color]" % [line_colour.to_html(false), line])
	var header_colour := COST_FREE if free else COST_OK
	_detail_cost.text = "[color=#%s]%s[/color]\n%s" % [
		header_colour.to_html(false),
		"Cost — free build is on, none of it will be spent" if free else "Cost",
		"\n".join(lines)
	]

	if free:
		_detail_status.text = "Build — free build is on"
		_detail_status.add_theme_color_override("font_color", COST_FREE)
		_pill_style(CTA_READY_BG, CTA_READY_BORDER)
	elif _can_afford(entry):
		_detail_status.text = "Build"
		_detail_status.add_theme_color_override("font_color", Color(0.851, 0.702, 0.251))
		_pill_style(CTA_READY_BG, CTA_READY_BORDER)
	else:
		_detail_status.text = "Not enough materials"
		_detail_status.add_theme_color_override("font_color", COST_SHORT)
		_pill_style(CTA_BLOCKED_BG, CTA_BLOCKED_BORDER)


## The pill's own background/border, matched to the same ready/blocked split
## `_detail_status`'s text colour already carries -- two signals (colour AND
## shape) agreeing is what makes this read as a stateful button rather than
## a coloured label.
func _pill_style(bg: Color, border: Color) -> void:
	if _detail_status_pill == null:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	_detail_status_pill.add_theme_stylebox_override("panel", box)


func _on_pick(index: int) -> void:
	var catalogue := _catalogue()
	if index < 0 or index >= catalogue.size():
		return
	var entry: Dictionary = catalogue[index]
	var name := str(entry.get("name", entry.get("id", "?")))

	if not _can_afford(entry):
		say("%s needs more than you are carrying." % name)
		return

	var game := state()
	if game == null:
		return
	# Arms the selection. Nothing is spent here: the materials come out when the
	# piece is actually placed, and placing is M8's job. Deducting now would let
	# a cancelled placement eat a gathering trip. When M8 does spend, it spends
	# `GameState.build_cost_for(id)` — which is already empty while free build is
	# on, so it needs no opinion about the toggle.
	game.set("pending_build", str(entry.get("id", "")))
	if _free_build():
		say("%s is ready to place, free. Placing lands with the hammer." % name)
	else:
		say("%s is ready to place. Placing lands with the hammer." % name)


## What the catalogue says the piece is worth — for the DISPLAY only, which is
## why it reads the entry rather than `GameState.build_cost_for`. The standing
## price is still worth reading while free build is on; whether it is charged is
## not this file's opinion to have.
func _cost(entry: Dictionary) -> Array:
	var raw: Variant = entry.get("cost", [])
	return raw as Array if typeof(raw) == TYPE_ARRAY else []


## Delegates, always. Every cost check in the game goes through one function so
## that the free-build toggle is respected by all of them or by none.
func _can_afford(entry: Dictionary) -> bool:
	var game := state()
	if game == null:
		return false
	return bool(game.call("can_afford", str(entry.get("id", ""))))


func _free_build() -> bool:
	var game := state()
	return game != null and bool(game.get("free_build"))


func _catalogue() -> Array:
	var db: RefCounted = _items()
	if db == null:
		return []
	var out: Array = []
	for entry in db.call("buildables"):
		if typeof(entry) == TYPE_DICTIONARY:
			out.append(entry)
	return out


func _inventory() -> RefCounted:
	var game := state()
	return game.get("inventory") if game != null else null


func _items() -> RefCounted:
	var game := state()
	return game.get("items") if game != null else null
