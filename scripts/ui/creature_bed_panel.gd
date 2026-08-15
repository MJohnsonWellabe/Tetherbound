extends CanvasLayer

## R4.8. A creature bed's rest screen: one row per party slot, press to rest
## that creature -- heals it fully (reviving it if fainted) and grants the
## same flat rest bonus XP overnight camp rest already gives every member
## (`home_recovery.gd`). Built and opened/closed the same pause-and-release-
## mouse way `storage_panel.gd`/`craft_panel.gd` already are: this is not a
## pause-menu tab, it only exists while standing at a placed bed.
##
## GAME_DESIGN.md 16/20's "visible creature rest behaviour" is NOT built
## here. A live in-world animation cue (the active creature's own body
## holding a faint/lie-down pose while this screen is open) is a real,
## scoped next step -- `creature_body.gd` already ships `play_faint()`/
## `revive_animation()`, which is exactly what it would use -- but it is
## visual-affecting (`conventions.md`: any scene/animation change needs a
## rendered, genuinely blind `visual-judge` pass before it counts as done),
## and this item's own budget did not stretch to that pass. What ships here
## is the mechanical half done honestly: a real revival/rest action with
## clear on-screen text feedback, not a placeholder.

const UITokens := preload("res://scripts/ui/ui_tokens.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const HOME_RECOVERY := preload("res://scripts/creatures/home_recovery.gd")

var game: Node = null

var _root: Control = null
var _column: VBoxContainer = null
var _message: Label = null
var _rows: Array[Button] = []
var _open: bool = false
var _bed: Node = null
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false


func _ready() -> void:
	game = get_node_or_null(^"/root/Game")
	_build_shell()
	visible = false


func is_open() -> bool:
	return _open


## `bed` is a creature_bed.gd instance -- kept only for `_process`'s validity
## check (a bed removed from under an open panel closes it), never read for
## its own data.
func open(bed: Node) -> void:
	_bed = bed
	if _open:
		_refresh()
		return
	_open = true
	visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _message != null:
		_message.text = ""
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	Input.mouse_mode = _mouse_before
	get_tree().paused = _paused_before
	_bed = null


func _process(_delta: float) -> void:
	if not _open:
		return
	if Input.is_action_just_pressed("menu_cancel"):
		close()
		return
	if _bed == null or not is_instance_valid(_bed):
		close()
		return
	_refresh()


func _build_shell() -> void:
	for child in get_children():
		child.queue_free()

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
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)

	var title := Label.new()
	title.text = "Rest a Creature"
	title.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title.add_theme_color_override("font_color", UITokens.TEXT_PRIMARY)
	outer.add_child(title)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 6)
	outer.add_child(_column)

	_message = Label.new()
	_message.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	_message.add_theme_color_override("font_color", UITokens.SUCCESS)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_message)

	var hint := Label.new()
	hint.text = "Leave: B / Esc"
	hint.add_theme_font_size_override("font_size", UITokens.FONT_TINY)
	hint.add_theme_color_override("font_color", UITokens.TEXT_MUTED)
	outer.add_child(hint)


func _refresh() -> void:
	if game == null or _column == null:
		return
	var party: RefCounted = game.get("party")
	if party == null:
		return

	for child in _column.get_children():
		child.queue_free()
	_rows.clear()

	for i in PARTY.MAX_CREATURES:
		var creature: RefCounted = party.call("at", i)
		var button := Button.new()
		button.custom_minimum_size = Vector2(370, 52)
		button.focus_mode = Control.FOCUS_ALL
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_stylebox_override("normal", UITokens.slot_box(false))
		button.add_theme_stylebox_override("hover", UITokens.slot_box(false))
		button.add_theme_stylebox_override("pressed", UITokens.slot_box(true))
		button.add_theme_stylebox_override("focus", UITokens.slot_box(true))

		if creature == null:
			button.text = "  %d.  empty" % (i + 1)
			button.disabled = true
		else:
			var fainted := bool(creature.get("fainted"))
			var status := "fainted" if fainted else "HP %d / %d" % [
				int(round(float(creature.get("hp")))), int(round(float(creature.get("max_hp")))),
			]
			button.text = "  %d.  %-16s %s" % [i + 1, str(creature.call("label")), status]
			var index := i
			button.pressed.connect(func() -> void: _on_rest_row(index))

		_column.add_child(button)
		_rows.append(button)

	UITokens.make_text_legible(_root)


func _on_rest_row(index: int) -> void:
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null:
		return

	var was_fainted := bool(creature.get("fainted"))
	var label := str(creature.call("label"))
	HOME_RECOVERY.rest(creature, PROGRESSION.config())

	if _message != null:
		_message.text = (
			"%s wakes up, fully rested." % label if was_fainted
			else "%s rests and wakes refreshed." % label
		)

	_refresh()
