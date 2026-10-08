extends Control

## Presentation over the local F23/F24 host projection. A reader supplies:
## active, creature_uid, ultimate_meter/maximum/armed/arm_fraction,
## commands (the existing tether_command_meter snapshot), and slots keyed by
## quick/charged/utility/dodge with glyph/name/ready/cooldown remaining/total.
## Never infers resource availability or spends anything on a player press.
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const COMMAND_METER := preload("res://scripts/ui/tether_command_meter.gd")
const SCREEN := preload("res://scripts/ui/system_screen.gd")
const GLYPH := preload("res://scripts/ui/input_glyph.gd")
var _read := Callable()
var _commands: Control
var _moves: VBoxContainer
var _ring: Control
var _cells: Dictionary = {}
var _uid := ""
var _meter_caption: Label
var _ultimate_button: Label

class UltimateRing extends Control:
	var fraction := 0.0
	var arm_fraction := 0.0
	var armed := false
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.43
		draw_arc(center, radius, -PI * 0.5, PI * 1.5, 48, Color("#344C56"), 5, true)
		if fraction > 0:
			draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * fraction, 48, Color("#E8B74A"), 5, true)
		if armed and arm_fraction > 0:
			draw_arc(center, radius - 9, -PI * 0.5, -PI * 0.5 + TAU * arm_fraction, 48, Color("#73E6DD"), 3, true)

func configure(read_local_snapshot: Callable) -> bool:
	if not read_local_snapshot.is_valid(): return false
	_read = read_local_snapshot
	return true

## Same local resource already drawn by CombatHUD's ally energy bar. The
## acknowledged overlay UID must match before replacing the charged fill.
func present_charged_energy(expected_uid: String, energy: float, required: float) -> bool:
	if not visible or expected_uid != _uid or expected_uid.is_empty() \
		or not is_finite(energy) or not is_finite(required) or required <= 0.0:
		return false
	var gate: ProgressBar = _cells.charged.cooldown
	gate.visible = true
	gate.max_value = required
	gate.value = clampf(energy, 0.0, required)
	return true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var cfg: Dictionary = SCREEN.config().get("combat", {})
	var left := VBoxContainer.new()
	left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left.offset_left = float(cfg.get("inset", 56))
	left.offset_top = -float(cfg.get("command_bottom", 500))
	add_child(left)
	_commands = COMMAND_METER.new()
	left.add_child(_commands)
	var move_width: float = float(cfg.get("move_width", 420))
	var inset: float = float(cfg.get("inset", 56))
	_moves = VBoxContainer.new()
	_moves.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moves.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_moves.offset_left = -move_width-inset
	_moves.offset_right = -inset
	_moves.offset_top = -float(cfg.get("move_bottom", 380))
	_moves.offset_bottom = -inset
	_moves.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_moves.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_moves.custom_minimum_size.x = move_width
	add_child(_moves)
	var ultimate := HBoxContainer.new()
	ultimate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moves.add_child(ultimate)
	_ring = UltimateRing.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.custom_minimum_size = Vector2(80, 80)
	ultimate.add_child(_ring)
	var rb := Label.new()
	_ultimate_button = rb
	rb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rb.add_theme_font_size_override("font_size", TOKENS.FONT_HEADING)
	_ring.add_child(rb)
	_meter_caption = _label(ultimate, "Ultimate")
	var diamond := VBoxContainer.new()
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diamond.add_theme_constant_override("separation", 8)
	_moves.add_child(diamond)
	var top := CenterContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diamond.add_child(top)
	var middle := HBoxContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_theme_constant_override("separation", 12)
	diamond.add_child(middle)
	var bottom := CenterContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diamond.add_child(bottom)
	var rows: Dictionary = {"charged":top,"quick":middle,"utility":middle,"dodge":bottom}
	# Same readable cell width in a face-button diamond: Y top, X left,
	# B right, A bottom. Containers grow for wrapped names and state text;
	# the bottom anchor keeps that growth above the configured safe inset.
	for slot: String in ["charged", "quick", "utility", "dodge"]:
		var cell := VBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.custom_minimum_size.x = move_width * 0.5 - 6
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		(rows[slot] as Container).add_child(cell)
		var title := _label(cell, "")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cooldown := ProgressBar.new()
		cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown.show_percentage = false
		cooldown.custom_minimum_size.y = 8
		cell.add_child(cooldown)
		_cells[slot] = {"title": title, "cooldown": cooldown}
	TOKENS.make_text_legible(self)

func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", TOKENS.FONT_READ)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func refresh(expected_uid: String, using_pad: bool) -> bool:
	visible = false
	if SCREEN.config().get("enabled") != true or not _read.is_valid(): return false
	var raw: Variant = _read.call()
	if not raw is Dictionary or raw.get("active") != true or raw.get("input_context") != "combat" or expected_uid.is_empty() \
			or raw.get("creature_uid") != expected_uid or not raw.get("slots") is Dictionary \
			or not raw.get("commands") is Dictionary: return false
	# Do not retain the old creature's meter through a switch or reconnect.
	_uid = expected_uid
	var maximum := float(raw.get("ultimate_maximum", 0))
	var meter := float(raw.get("ultimate_meter", -1))
	if not is_finite(maximum) or not is_finite(meter) or maximum <= 0 or meter < 0: return false
	for slot: String in ["quick", "charged", "utility", "dodge"]:
		var row: Variant = raw.slots.get(slot)
		if not row is Dictionary or not row.get("name") is String or not row.get("glyph") is String \
				or not row.get("ready") is bool: return false
	visible = true
	_ring.set("fraction", clampf(meter / maximum, 0, 1))
	_ring.set("armed", raw.get("ultimate_armed") == true)
	_ring.set("arm_fraction", clampf(float(raw.get("arm_fraction", 0)), 0, 1))
	_ring.queue_redraw()
	var arm_button := GLYPH.pad_button_name_for_action("combat_ultimate_arm") if using_pad else GLYPH.key_name_for_action("combat_ultimate_arm")
	_ultimate_button.text = arm_button
	_meter_caption.text = "Ultimate · %d%%\n%s" % [int(clampf(meter / maximum, 0, 1) * 100),
		"Ultimate unavailable" if raw.get("ultimate_available", true) != true else \
		"Choose %s / %s / %s" % [raw.slots.quick.glyph, raw.slots.charged.glyph, raw.slots.utility.glyph] if raw.get("ultimate_armed") == true else "Ready · Tap %s" % arm_button if meter >= maximum else "Build with landed hits"]
	_commands.call("present", raw.commands, using_pad)
	for slot: String in _cells:
		var row: Dictionary = raw.slots[slot]
		var label: Label = _cells[slot].title
		label.text = "%s %s%s" % [row.glyph, row.name, "" if row.ready else " · Unavailable"]
		if slot == "utility": label.text += "\nWind %s" % float(row.get("wind_cost", 24.0))
		label.add_theme_color_override("font_color", TOKENS.TEAL_SOFT if row.ready else TOKENS.TEXT_SECONDARY)
		var cooldown: ProgressBar = _cells[slot].cooldown
		var total := float(row.get("cooldown_total_s", 0))
		cooldown.visible = total > 0 and float(row.get("cooldown_remaining_s", 0)) > 0
		cooldown.max_value = maxf(total, 1)
		cooldown.value = clampf(total - float(row.get("cooldown_remaining_s", 0)), 0, cooldown.max_value)
	return true
