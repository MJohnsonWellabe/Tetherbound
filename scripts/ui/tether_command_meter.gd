extends VBoxContainer

## Bottom-centre command lane mounted by the shared CombatHUD writer.
## Snapshot is presentation only: affordability never authorizes an action.
const COMMANDS := preload("res://scripts/combat/tether_commands.gd")
const GLYPH := preload("res://scripts/ui/input_glyph.gd")
const TOKENS := preload("res://scripts/ui/ui_tokens.gd")
const SYSTEM_SCREEN := preload("res://scripts/ui/system_screen.gd")
var _bar: ProgressBar
var _title: Label
var _reason: Label
var _labels: Dictionary = {}
var _refusal_left := 0.0

class CostBar extends ProgressBar:
	var costs: Array[float] = []
	func _draw() -> void:
		for cost: float in costs:
			var x := size.x * cost / max_value
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#B8C5C4"), 2)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui: Dictionary = COMMANDS.config().get("ui", {})
	if SYSTEM_SCREEN.config().get("enabled") == true:
		ui = ui.duplicate(true)
		ui["font_size"] = maxi(int(ui.get("font_size", 22)), TOKENS.FONT_READ)
	custom_minimum_size.x = float(SYSTEM_SCREEN.config().get("combat", {}).get("command_width", ui.get("width", 580)))
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", int(ui.get("font_size", 22)))
	add_child(_title)
	var cost_bar := CostBar.new()
	for id: String in COMMANDS.COMMAND_IDS:
		cost_bar.costs.append(float(COMMANDS.config().commands[id].cost))
	_bar = cost_bar
	_bar.show_percentage = false
	_bar.custom_minimum_size.y = float(ui.get("bar_height", 18))
	add_child(_bar)
	var buttons := GridContainer.new()
	buttons.columns = 4
	buttons.add_theme_constant_override("h_separation", 20)
	add_child(buttons)
	for id: String in COMMANDS.COMMAND_IDS:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", int(ui.get("font_size", 22)))
		label.custom_minimum_size.x = (custom_minimum_size.x - 60.0) * 0.25
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		buttons.add_child(label)
		_labels[id] = label
	_reason = Label.new()
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason.add_theme_color_override("font_color", TOKENS.WARNING)
	_reason.add_theme_font_size_override("font_size", int(ui.get("font_size", 22)))
	add_child(_reason)
	_reason.visible = false
	visible = false

func _process(delta: float) -> void:
	_refusal_left = maxf(0, _refusal_left - delta)
	if _reason != null and _refusal_left == 0:
		_reason.text = ""
		_reason.visible = false

## Reader sends remaining durations rather than comparing a client clock with
## host ticks. Rebound-aware token expands once the shared glyph map is wired.
func present(snapshot: Dictionary, using_pad: bool) -> void:
	visible = COMMANDS.enabled("ui_enabled") and snapshot.get("active") == true
	if not visible or _bar == null: return
	var meter := float(snapshot.get("meter", 0))
	var maximum := float(COMMANDS.config().meter.maximum)
	_bar.max_value = maximum
	_bar.value = clampf(meter, 0, maximum)
	_title.text = "Commands  %d / %d" % [int(meter), int(maximum)]
	for id: String in COMMANDS.COMMAND_IDS:
		var row: Dictionary = COMMANDS.config().commands[id]
		var label: Label = _labels[id]
		var suffix := ""
		if id == "item_throw": suffix = " ×%d" % int(snapshot.get("pouch_count", 0))
		if id == "tag_combo" and float(snapshot.get("combo_remaining_s", 0)) > 0:
			suffix = " %.1fs" % float(snapshot.combo_remaining_s)
		if id == "snare" and snapshot.get("wild_target") != true: suffix = " —"
		var action := COMMANDS.input_action(id)
		var button_name := GLYPH.pad_button_name_for_action(action) if using_pad else GLYPH.key_name_for_action(action)
		label.text = "%s\n%s\n%d%s" % [button_name, str(row.label), int(row.cost), suffix]
		var available := meter >= float(row.cost) and (snapshot.get("unlocked_commands", []) as Array).has(id)
		if id == "tag_combo": available = available and float(snapshot.get("combo_remaining_s", 0)) > 0
		if id == "snare": available = available and snapshot.get("wild_target") == true
		if id == "item_throw": available = available and int(snapshot.get("pouch_count", 0)) > 0
		label.add_theme_color_override("font_color", TOKENS.TEAL_SOFT if available else TOKENS.TEXT_MUTED)

func refused(reason: String) -> void:
	if _reason == null: return
	_reason.text = reason
	_reason.visible = true
	_refusal_left = float(COMMANDS.config().get("ui", {}).get("refusal_seconds", 2.5))
