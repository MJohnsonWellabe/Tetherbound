extends "res://scripts/ui/menu_tab.gd"

## The five pals. All five, always.
##
## CLAUDE.md: "Player can own only five pals total" and "Never implement pal
## storage beyond five." This screen therefore draws exactly MAX_PALS rows
## whether or not they are filled, and the empty ones say "empty" rather than
## being absent. A list that grows from one row to five hides the cap until the
## player hits it; five rows from the first minute make it a fact of the game.
##
## There is no box, no next page and no scrollbar here, and there is nowhere to
## put a sixth pal. That is the design, not an unfinished screen. When a sixth
## capture happens the answer is the release ceremony (M5), which is another
## agent's work and is deliberately not stubbed here.

const PARTY := preload("res://autoload/party.gd")

## Reordering is pick-up-then-place, matching the backpack. Setting the deployed
## pal needs a second verb, and `interact` (E / X) is the one already bound that
## is not doing anything else inside a menu. This agent may not add actions to
## project.godot's input map.
const ACTIVATE_ACTION := "interact"

const HEALTH_FULL := Color(0.35, 0.62, 0.28)
const HEALTH_LOW := Color(0.72, 0.22, 0.18)

var _header: Label = null
var _rows: Array = []
var _focused: int = 0
var _held: int = -1

var _detail_name: Label = null
var _detail_species: Label = null
var _detail_bar: ProgressBar = null
var _detail_bar_fill: StyleBoxFlat = null
var _detail_hp: Label = null
var _detail_status: Label = null
var _detail_hint: Label = null


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()
	_held = -1

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 24)
	add_child(_header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.custom_minimum_size = Vector2(640, 0)
	row.add_child(list)

	for i in PARTY.MAX_PALS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(620, 74)
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		var slot := i
		button.pressed.connect(func() -> void: _on_row(slot))
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

	_detail_species = Label.new()
	_detail_species.add_theme_font_size_override("font_size", 24)
	_detail_species.add_theme_color_override("font_color", Color(0.6, 0.62, 0.55))
	panel.add_child(_detail_species)

	_detail_bar = ProgressBar.new()
	_detail_bar.custom_minimum_size = Vector2(360, 24)
	# Fixed width, not stretched: a health bar spanning the whole panel reads as
	# a divider rather than as a quantity.
	_detail_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_detail_bar.show_percentage = false
	# Own fill stylebox, because the bar slides from green to red as the pal is
	# hurt and a shared theme stylebox would recolour every bar in the menu.
	_detail_bar_fill = StyleBoxFlat.new()
	_detail_bar_fill.bg_color = HEALTH_FULL
	_detail_bar_fill.corner_radius_top_left = 3
	_detail_bar_fill.corner_radius_top_right = 3
	_detail_bar_fill.corner_radius_bottom_left = 3
	_detail_bar_fill.corner_radius_bottom_right = 3
	_detail_bar.add_theme_stylebox_override("fill", _detail_bar_fill)
	panel.add_child(_detail_bar)

	_detail_hp = Label.new()
	_detail_hp.add_theme_font_size_override("font_size", 24)
	panel.add_child(_detail_hp)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", 24)
	_detail_status.add_theme_color_override("font_color", Color(0.851, 0.702, 0.251))
	panel.add_child(_detail_status)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)

	_detail_hint = Label.new()
	_detail_hint.add_theme_font_size_override("font_size", 22)
	_detail_hint.add_theme_color_override("font_color", Color(0.55, 0.57, 0.52))
	_detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_hint.text = "A  pick up, then A again to reorder\nE / X  send this one out first"
	panel.add_child(_detail_hint)

	return panel


func first_focus() -> Control:
	return _rows[0] if not _rows.is_empty() else null


## Row count never changes, so nothing here needs rebuilding — reordering
## rewrites the same five buttons. Constant for the same reason the backpack's
## is: a rebuild destroys the focused node and strands a controller.
func revision() -> int:
	return 0


func poll() -> void:
	var party: RefCounted = _party()
	if party == null or _header == null:
		return
	_read_activate()

	var size: int = int(party.call("size"))
	if bool(party.call("is_full")):
		# Said plainly, and said before it matters. The sixth capture is a
		# ceremony, not an error message, and a player who is surprised by the
		# cap has been let down by this screen.
		_header.text = "Party  %d / %d      Full. A sixth pal means letting one go." % [size, PARTY.MAX_PALS]
	else:
		_header.text = "Party  %d / %d      %d free" % [size, PARTY.MAX_PALS, PARTY.MAX_PALS - size]
	if _held >= 0:
		_header.text += "      holding slot %d" % (_held + 1)

	var active: int = int(party.call("active_index"))
	for i in _rows.size():
		var button: Button = _rows[i]
		var pal: RefCounted = party.call("at", i)
		if pal == null:
			button.text = "  %d.  empty" % (i + 1)
			button.add_theme_color_override("font_color", Color(0.38, 0.39, 0.37))
		else:
			var marker := "*" if i == active and size > 0 else " "
			button.text = "%s %d.  %-16s %-10s %3d / %-3d" % [
				marker, i + 1, str(pal.call("label")), str(pal.get("pal_type")),
				int(round(float(pal.get("hp")))), int(round(float(pal.get("max_hp"))))
			]
			button.add_theme_color_override(
				"font_color",
				Color(0.72, 0.22, 0.18) if bool(pal.get("fainted")) else Color(0.87, 0.89, 0.84)
			)
		button.button_pressed = i == _held

	_describe(_focused)


func _describe(index: int) -> void:
	if _detail_name == null:
		return
	var party: RefCounted = _party()
	var pal: RefCounted = party.call("at", index) if party != null else null

	if pal == null:
		_detail_name.text = "Empty slot"
		_detail_species.text = "Nothing here yet."
		_detail_bar.value = 0.0
		_detail_hp.text = ""
		_detail_status.text = ""
		return

	_detail_name.text = str(pal.call("label"))
	# The species line only repeats the name when the pal was never renamed,
	# which is exactly when the player wants to be reminded it is a default.
	var nickname := str(pal.get("nickname")).strip_edges()
	_detail_species.text = "%s     %s" % [str(pal.get("display_name")), str(pal.get("pal_type"))]
	if nickname.is_empty():
		_detail_species.text += "     (species name)"

	var fraction: float = float(pal.call("hp_fraction"))
	_detail_bar.value = fraction * 100.0
	_detail_bar_fill.bg_color = HEALTH_LOW.lerp(HEALTH_FULL, fraction)
	_detail_hp.text = "HP  %d / %d        ATK %d    DEF %d" % [
		int(round(float(pal.get("hp")))), int(round(float(pal.get("max_hp")))),
		int(round(float(pal.get("attack")))), int(round(float(pal.get("defence"))))
	]

	if bool(pal.get("fainted")):
		_detail_status.text = "Out of the fight."
	elif index == int(party.call("active_index")):
		_detail_status.text = "Goes out first."
	else:
		_detail_status.text = ""


func _on_row(index: int) -> void:
	var party: RefCounted = _party()
	if party == null:
		return

	if _held < 0:
		if party.call("at", index) == null:
			say("Nothing in that slot.")
			return
		_held = index
		return

	if _held == index:
		_held = -1
		say("")
		return

	if party.call("at", index) == null:
		say("Nothing to swap with there.")
		return

	party.call("move", _held, index)
	_held = -1
	poll()


## Set who goes out first. A fainted pal refuses, and says so rather than
## silently doing nothing.
##
## Polled from poll() rather than received as an event, for the same reason the
## shell polls: a focused Button eats events, and this verb has to work while
## one is focused — which is always.
func _read_activate() -> void:
	if not visible or menu == null or not bool(menu.call("is_open")):
		return
	if not Input.is_action_just_pressed(ACTIVATE_ACTION):
		return

	var party: RefCounted = _party()
	if party == null:
		return
	var pal: RefCounted = party.call("at", _focused)
	if pal == null:
		say("Nothing in that slot.")
	elif bool(party.call("set_active", _focused)):
		say("%s goes out first." % str(pal.call("label")))
	else:
		say("%s is out of the fight." % str(pal.call("label")))


func _party() -> RefCounted:
	var game := state()
	return game.get("party") if game != null else null
