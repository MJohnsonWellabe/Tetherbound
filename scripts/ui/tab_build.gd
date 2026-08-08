extends "res://scripts/ui/menu_tab.gd"

## What you can build, what it costs, and whether you can afford it right now.
##
## The catalogue is data/items/buildables.json. This file contains no piece
## names, no costs and no categories, which is the point: GAME_DESIGN.md 20
## lists a dozen buildable categories and the eleventh one after the camp should
## cost a JSON block and nothing else.
##
## Confirming a piece does NOT place geometry. Placement, snapping and the
## hammer belong to the building system (M8), which does not exist and is not
## this agent's to write. Confirming arms `GameState.pending_build` and says so.
## A build button that silently did nothing would read as a bug; one that arms a
## selection is honest about where the work stops, and the seam is already the
## right shape for the system that will read it.

var _rows: Array = []
var _focused: int = 0

var _detail_name: Label = null
var _detail_blurb: Label = null
var _detail_cost: Label = null
var _detail_contains: Label = null
var _detail_status: Label = null


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.custom_minimum_size = Vector2(480, 0)
	row.add_child(list)

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

	row.add_child(_build_detail())
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

	_detail_cost = Label.new()
	_detail_cost.add_theme_font_size_override("font_size", 26)
	# BBCode, because affordability is per-LINE: "12 wood, and you have 3" has to
	# be readable as one shortfall inside a list of three costs you do have.
	panel.add_child(_detail_cost)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", 24)
	_detail_status.add_theme_color_override("font_color", Color(0.851, 0.702, 0.251))
	panel.add_child(_detail_status)

	return panel


func first_focus() -> Control:
	return _rows[0] if not _rows.is_empty() else null


## Constant: the catalogue is data and does not change while the game runs. The
## affordability numbers on it do, and those are written every frame by poll().
func revision() -> int:
	return 0


func poll() -> void:
	var catalogue := _catalogue()
	for i in _rows.size():
		if i >= catalogue.size():
			continue
		var affordable := _can_afford(catalogue[i])
		# Dimmed, never hidden. A piece you cannot afford is the thing that tells
		# you what to go and gather; removing it from the list removes the goal.
		(_rows[i] as Button).add_theme_color_override(
			"font_color",
			Color(0.87, 0.89, 0.84) if affordable else Color(0.5, 0.51, 0.48)
		)
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
		return

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

	var inventory: RefCounted = _inventory()
	var db: RefCounted = _items()
	var lines: Array[String] = []
	for requirement in _cost(entry):
		var id := str(requirement.get("id", ""))
		var need := int(requirement.get("n", 0))
		var have: int = int(inventory.call("count", id)) if inventory != null else 0
		var name := str(db.call("item_name", id)) if db != null else id
		# "Wood 12, you have 62" rather than "Wood 62 / 12". A bare pair of
		# numbers does not say which one is the cost, and the player reading it
		# is deciding whether to go and gather.
		lines.append("%s  %d       you have %d%s" % [
			name, need, have, "" if have >= need else "   — short"
		])
	_detail_cost.text = "Cost\n%s" % "\n".join(lines)

	if _can_afford(entry):
		_detail_status.text = "Ready to build."
	else:
		_detail_status.text = "Not enough to hand."


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
	# a cancelled placement eat a gathering trip.
	game.set("pending_build", str(entry.get("id", "")))
	say("%s is ready to place. Placing lands with the hammer." % name)


func _cost(entry: Dictionary) -> Array:
	var raw: Variant = entry.get("cost", [])
	return raw as Array if typeof(raw) == TYPE_ARRAY else []


func _can_afford(entry: Dictionary) -> bool:
	var inventory: RefCounted = _inventory()
	if inventory == null:
		return false
	for requirement in _cost(entry):
		if typeof(requirement) != TYPE_DICTIONARY:
			continue
		var need := int((requirement as Dictionary).get("n", 0))
		if int(inventory.call("count", str((requirement as Dictionary).get("id", "")))) < need:
			return false
	return true


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
