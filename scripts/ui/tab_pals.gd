extends "res://scripts/ui/menu_tab.gd"

## The Palworld-style TEAM screen (spec §8): five-slot column, a live 3D
## viewport on the selected pal, and a detail column of moves and bond.
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
##
## The row/reorder/set-active machinery below is unchanged from the original
## two-panel layout, on purpose: `tests/smoke_menu.gd` drives `_rows`, `_held`
## and `ACTIVATE_ACTION` directly, proving the wiring reaches
## `party.move()`/`party.set_active()` for real rather than only in a unit
## test. This pass changes what a row LOOKS like and adds the centre/right
## columns; it does not touch how a row is picked up, placed, or activated.

const PARTY := preload("res://autoload/party.gd")
const PAL_VIEWPORT := preload("res://scripts/ui/pal_viewport.gd")
const MOVE_DB := preload("res://scripts/pals/move_db.gd")
const PROGRESSION := preload("res://scripts/pals/progression.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

## Reordering is pick-up-then-place, matching the backpack. Setting the deployed
## pal needs a second verb, and `interact` (E / X) is the one already bound that
## is not doing anything else inside a menu. This agent may not add actions to
## project.godot's input map.
const ACTIVATE_ACTION := "interact"

const HEALTH_FULL := Color(0.35, 0.62, 0.28)
const HEALTH_LOW := Color(0.72, 0.22, 0.18)

const ROW_HEIGHT := 110.0
const ROW_WIDTH := 420.0
const CHIP_SIZE := Vector2(74.0, 74.0)
## The "+10px wider" selected-row cue (spec §8.1): a negative left margin on
## the selected row's wrapper, so it alone pokes past the others rather than
## every row resizing around it.
const SELECTED_POKE := 10.0

const TYPE_ICONS := {
	"ground": preload("res://assets/ui/icons/ui/type_ground.png"),
	"water": preload("res://assets/ui/icons/ui/type_water.png"),
	"air": preload("res://assets/ui/icons/ui/type_air.png"),
}
const BOND_ICON := preload("res://assets/ui/icons/ui/bond.png")

var _header: Label = null
## Button nodes only — see the header note on why `smoke_menu.gd` needs these
## to be castable straight to `Button`, not a wrapper.
var _rows: Array = []
var _row_wraps: Array = []
var _row_chips: Array = []
var _row_names: Array = []
var _row_levels: Array = []
var _row_hp_bars: Array = []
var _row_hp_fills: Array = []
var _row_bond_counts: Array = []
var _row_content: Array = []

var _focused: int = 0
var _held: int = -1

var _viewport: SubViewportContainer = null
var _shown_species: String = ""

var _detail_name: Label = null
var _detail_type_icon: TextureRect = null
var _detail_type_label: Label = null
var _detail_hp: Label = null
var _detail_stats: Label = null
var _detail_xp: Label = null
var _detail_xp_bar: ProgressBar = null
var _move_quick_icon: TextureRect = null
var _move_quick_name: Label = null
var _move_quick_tag: Label = null
var _move_quick_sub: Label = null
var _move_charged_icon: TextureRect = null
var _move_charged_name: Label = null
var _move_charged_tag: Label = null
var _move_charged_sub: Label = null
var _bond_meter: Control = null
var _bond_caption: Label = null
var _detail_status: Label = null
var _detail_hint: Label = null

var _moves: RefCounted = null


func build() -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()
	_row_wraps.clear()
	_row_chips.clear()
	_row_names.clear()
	_row_levels.clear()
	_row_hp_bars.clear()
	_row_hp_fills.clear()
	_row_bond_counts.clear()
	_row_content.clear()
	_held = -1
	_shown_species = ""
	if _moves == null:
		_moves = MOVE_DB.load_default()

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	add_child(_header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.custom_minimum_size = Vector2(ROW_WIDTH + SELECTED_POKE, 0)
	row.add_child(list)

	for i in PARTY.MAX_PALS:
		list.add_child(_build_slot_row(i))

	_viewport = PAL_VIEWPORT.new()
	row.add_child(_viewport)

	row.add_child(_build_detail())
	UITokens.make_text_legible(self)
	poll()


## One left-column slot: a wrapper (for the selected-row poke) around a
## focusable Button (for `smoke_menu.gd`'s `_rows` contract) around an
## anchored content row (portrait chip, name/level/HP, bond marker) that the
## Button draws neither of on its own.
func _build_slot_row(index: int) -> Control:
	var wrap := MarginContainer.new()
	_row_wraps.append(wrap)

	var button := Button.new()
	button.custom_minimum_size = Vector2(ROW_WIDTH, ROW_HEIGHT)
	button.clip_text = true
	button.focus_mode = Control.FOCUS_ALL
	var slot := index
	button.pressed.connect(func() -> void: _on_row(slot))
	button.focus_entered.connect(func() -> void: _focused = slot)
	wrap.add_child(button)
	_rows.append(button)

	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_right = -14
	content.offset_top = 10
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 14)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)
	_row_content.append(content)

	var chip := PanelContainer.new()
	chip.custom_minimum_size = CHIP_SIZE
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(chip)
	_row_chips.append(chip)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.add_theme_constant_override("separation", 4)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(text_col)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	text_col.add_child(name_label)
	_row_names.append(name_label)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 8)
	text_col.add_child(stat_row)

	var level_label := Label.new()
	level_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	level_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	level_label.custom_minimum_size = Vector2(48, 0)
	stat_row.add_child(level_label)
	_row_levels.append(level_label)

	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(150, 8)
	hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hp_bar.show_percentage = false
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = HEALTH_FULL
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	stat_row.add_child(hp_bar)
	_row_hp_bars.append(hp_bar)
	_row_hp_fills.append(hp_fill)

	var bond_col := VBoxContainer.new()
	bond_col.alignment = BoxContainer.ALIGNMENT_CENTER
	bond_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bond_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(bond_col)

	var bond_icon := TextureRect.new()
	bond_icon.texture = BOND_ICON
	bond_icon.custom_minimum_size = Vector2(18, 18)
	bond_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bond_col.add_child(bond_icon)

	var bond_count := Label.new()
	bond_count.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	bond_count.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	bond_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bond_col.add_child(bond_count)
	_row_bond_counts.append(bond_count)

	return wrap


func _build_detail() -> Control:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_constant_override("separation", 10)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", UITokens.FONT_TITLE)
	panel.add_child(_detail_name)

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 8)
	panel.add_child(type_row)
	_detail_type_icon = TextureRect.new()
	_detail_type_icon.custom_minimum_size = Vector2(22, 22)
	_detail_type_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	type_row.add_child(_detail_type_icon)
	_detail_type_label = Label.new()
	_detail_type_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_type_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	type_row.add_child(_detail_type_label)

	_detail_hp = Label.new()
	_detail_hp.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	panel.add_child(_detail_hp)

	_detail_stats = Label.new()
	_detail_stats.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_stats.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	panel.add_child(_detail_stats)

	_detail_xp = Label.new()
	_detail_xp.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_xp.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	panel.add_child(_detail_xp)

	_detail_xp_bar = ProgressBar.new()
	_detail_xp_bar.custom_minimum_size = Vector2(320, 6)
	_detail_xp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_detail_xp_bar.show_percentage = false
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = UITokens.TEAL
	xp_fill.corner_radius_top_left = 3
	xp_fill.corner_radius_top_right = 3
	xp_fill.corner_radius_bottom_left = 3
	xp_fill.corner_radius_bottom_right = 3
	_detail_xp_bar.add_theme_stylebox_override("fill", xp_fill)
	panel.add_child(_detail_xp_bar)

	panel.add_child(_hairline())

	var quick := _build_move_row()
	_move_quick_icon = quick[0]
	_move_quick_name = quick[1]
	_move_quick_tag = quick[2]
	_move_quick_sub = quick[3]
	panel.add_child(quick[4])

	panel.add_child(_hairline())

	var charged := _build_move_row()
	_move_charged_icon = charged[0]
	_move_charged_name = charged[1]
	_move_charged_tag = charged[2]
	_move_charged_sub = charged[3]
	panel.add_child(charged[4])

	panel.add_child(_hairline())

	var bond_wrap := VBoxContainer.new()
	bond_wrap.add_theme_constant_override("separation", 4)
	panel.add_child(bond_wrap)

	_bond_meter = load("res://scripts/ui/bond_meter.gd").new()
	bond_wrap.add_child(_bond_meter)

	_bond_caption = Label.new()
	_bond_caption.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_bond_caption.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	bond_wrap.add_child(_bond_caption)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	_detail_status.add_theme_color_override("font_color", UITokens.WARNING)
	panel.add_child(_detail_status)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(spacer)

	_detail_hint = Label.new()
	_detail_hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	_detail_hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	_detail_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_hint.text = "A  pick up, then A again to reorder      E / X  send this one out first"
	panel.add_child(_detail_hint)

	return panel


## One horizontal move row (spec §8.3): "[icon] Name  TAG" on line 1,
## "Power x1.0   Energy +26" (or "Cost 100") on line 2. A row, not a card —
## no panel background, just the hairlines `_build_detail` places around it.
## Returns [icon, name_label, tag_label, sub_label, container].
func _build_move_row() -> Array:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 8)
	box.add_child(line1)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	line1.add_child(icon)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_LABEL)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.add_child(name_label)

	var tag_label := Label.new()
	tag_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	tag_label.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line1.add_child(tag_label)

	var sub_label := Label.new()
	sub_label.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	sub_label.add_theme_color_override("font_color", UITokens.TEXT_SECONDARY)
	box.add_child(sub_label)

	return [icon, name_label, tag_label, sub_label, box]


func _hairline() -> Control:
	var line := ColorRect.new()
	line.color = UITokens.BORDER
	line.custom_minimum_size = Vector2(0, 1)
	return line


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
		_header.text = "Belt  %d / %d      Full. A sixth creature means letting one go." % [size, PARTY.MAX_PALS]
	else:
		_header.text = "Belt  %d / %d      %d free" % [size, PARTY.MAX_PALS, PARTY.MAX_PALS - size]
	if _held >= 0:
		_header.text += "      holding slot %d" % (_held + 1)

	var cfg: Dictionary = PROGRESSION.config()
	var active: int = int(party.call("active_index"))
	for i in _rows.size():
		_poll_row(i, party, cfg, active, size)

	_describe(_focused, cfg)


func _poll_row(i: int, party: RefCounted, cfg: Dictionary, active: int, size: int) -> void:
	var button: Button = _rows[i]
	var pal: RefCounted = party.call("at", i)
	var content: Control = _row_content[i]
	var chip: PanelContainer = _row_chips[i]

	button.button_pressed = i == _held
	var selected := i == _focused
	button.add_theme_stylebox_override("normal", UITokens.slot_box(selected))
	(_row_wraps[i] as MarginContainer).add_theme_constant_override(
		"margin_left", 0 if selected else int(SELECTED_POKE)
	)

	if pal == null:
		button.text = "  %d.  empty" % (i + 1)
		button.add_theme_color_override("font_color", Color(0.38, 0.39, 0.37))
		content.visible = false
		return

	button.text = ""
	content.visible = true

	var species_look: Dictionary = SPECIES.placeholder(str(pal.get("species_id")))
	var chip_box := StyleBoxFlat.new()
	var chip_colour := Color(str(species_look.get("colour", "#888888")))
	if bool(pal.get("fainted")):
		chip_colour = chip_colour.darkened(0.5)
	chip_box.bg_color = chip_colour
	chip_box.corner_radius_top_left = UITokens.RADIUS_SLOT
	chip_box.corner_radius_top_right = UITokens.RADIUS_SLOT
	chip_box.corner_radius_bottom_left = UITokens.RADIUS_SLOT
	chip_box.corner_radius_bottom_right = UITokens.RADIUS_SLOT
	chip.add_theme_stylebox_override("panel", chip_box)

	var marker := " *" if i == active and size > 0 else ""
	(_row_names[i] as Label).text = "%s%s" % [str(pal.call("label")), marker]
	(_row_names[i] as Label).add_theme_color_override(
		"font_color", HEALTH_LOW if bool(pal.get("fainted")) else UITokens.TEXT_PRIMARY
	)
	(_row_levels[i] as Label).text = "Lv %d" % int(pal.get("level"))

	var fraction: float = float(pal.call("hp_fraction"))
	(_row_hp_bars[i] as ProgressBar).value = fraction * 100.0
	(_row_hp_fills[i] as StyleBoxFlat).bg_color = HEALTH_LOW.lerp(HEALTH_FULL, fraction)

	var nodes: int = int(pal.call("bond_nodes", cfg))
	var total: int = int(cfg.get("bond", {}).get("thresholds", []).size())
	(_row_bond_counts[i] as Label).text = "%d/%d" % [nodes, maxi(total, 1)]


func _describe(index: int, cfg: Dictionary) -> void:
	if _detail_name == null:
		return
	var party: RefCounted = _party()
	var pal: RefCounted = party.call("at", index) if party != null else null

	if pal == null:
		_detail_name.text = "Empty slot"
		_detail_type_icon.texture = null
		_detail_type_label.text = "Nothing here yet."
		_detail_hp.text = ""
		_detail_stats.text = ""
		_detail_xp.text = ""
		_detail_xp_bar.value = 0.0
		_move_quick_name.text = ""
		_move_quick_sub.text = ""
		_move_quick_tag.text = ""
		_move_quick_icon.texture = null
		_move_charged_name.text = ""
		_move_charged_sub.text = ""
		_move_charged_tag.text = ""
		_move_charged_icon.texture = null
		_bond_meter.call("set_bond", 0, 100, 0, 5)
		_bond_caption.text = ""
		_detail_status.text = ""
		if _shown_species != "":
			_shown_species = ""
			_viewport.call("set_species", "")
		return

	var species_id := str(pal.get("species_id"))
	if species_id != _shown_species:
		_shown_species = species_id
		_viewport.call("set_species", species_id)

	var nickname := str(pal.get("nickname")).strip_edges()
	var display_name := str(pal.get("display_name"))
	var shown_name := str(pal.call("label"))
	# The species line only repeats the name when the pal was never renamed,
	# which is exactly when the player wants to be reminded it is a default.
	_detail_name.text = "%s     Lv %d" % [
		shown_name if not nickname.is_empty() else display_name, int(pal.get("level"))
	]

	var pal_type := str(pal.get("pal_type"))
	_detail_type_icon.texture = TYPE_ICONS.get(pal_type, null)
	_detail_type_label.text = pal_type.capitalize()

	_detail_hp.text = "HP  %d / %d" % [
		int(round(float(pal.get("hp")))), int(round(float(pal.get("max_hp"))))
	]
	_detail_stats.text = "ATK %d    DEF %d" % [
		int(round(float(pal.get("attack")))), int(round(float(pal.get("defence"))))
	]

	var xp: int = int(pal.get("xp"))
	var xp_needed: int = int(pal.call("xp_to_next", cfg))
	_detail_xp.text = "XP  %d / %d" % [xp, xp_needed]
	_detail_xp_bar.value = 0.0 if xp_needed <= 0 else clampf(float(xp) / float(xp_needed), 0.0, 1.0) * 100.0

	_fill_move_row(
		str(pal.get("move_quick")), "QUICK", pal_type,
		_move_quick_icon, _move_quick_name, _move_quick_tag, _move_quick_sub
	)
	_fill_move_row(
		str(pal.get("move_charged")), "CHARGED", pal_type,
		_move_charged_icon, _move_charged_name, _move_charged_tag, _move_charged_sub
	)

	var nodes: int = int(pal.call("bond_nodes", cfg))
	var total: int = int(cfg.get("bond", {}).get("thresholds", []).size())
	var bond_max: int = int(cfg.get("bond", {}).get("max", 100))
	_bond_meter.call("set_bond", int(pal.get("bond")), bond_max, nodes, maxi(total, 1))
	var per_node: float = float(cfg.get("bond", {}).get("effects_per_node", {}).get("attack_scale", 0.0))
	_bond_caption.text = "+%d%% ATK/DEF per node" % int(round(per_node * 100.0))

	if bool(pal.get("fainted")):
		_detail_status.text = "Out of the fight."
	elif index == int(party.call("active_index")):
		_detail_status.text = "Goes out first."
	else:
		_detail_status.text = ""


func _fill_move_row(
	move_id: String, tag: String, fallback_type: String,
	icon: TextureRect, name_label: Label, tag_label: Label, sub_label: Label
) -> void:
	if move_id == "" or not bool(_moves.call("has", move_id)):
		name_label.text = "—"
		sub_label.text = ""
		tag_label.text = tag
		icon.texture = TYPE_ICONS.get(fallback_type, null)
		return

	var data: Dictionary = _moves.call("move", move_id)
	name_label.text = str(data.get("display_name", move_id))
	tag_label.text = tag
	icon.texture = TYPE_ICONS.get(str(data.get("type", fallback_type)), null)

	var power: float = float(data.get("power", 1.0))
	if tag == "CHARGED":
		var cost: int = int(data.get("energy_cost", 100))
		sub_label.text = "Power x%.1f   Cost %d" % [power, cost]
	else:
		var gain: int = int(data.get("energy_gain", 0))
		sub_label.text = "Power x%.1f   Energy +%d" % [power, gain]


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
