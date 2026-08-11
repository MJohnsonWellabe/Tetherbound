extends CanvasLayer

## The real exploration HUD (`ENVIRONMENT_AND_UI_BIBLE.md` §16-18, EV9).
##
## Draws only what the bible keeps on screen while exploring: health and
## stamina (faded out when neither is doing anything interesting), the party
## and orb counts, and the one contextual interact prompt. Everything else —
## the raw movement/input telemetry this HUD used to dump permanently — is
## still here, because M1 tuning still needs it, but it now lives behind an
## F3 toggle instead of covering a third of the screen by default.
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so text set here is at real handheld pixel density.
##
## No objective line yet: the bible asks for "concise current objective," but
## there is no objective/quest state to read (`SB9`/`SB11`, both still open).
## Wiring a label to nothing would just be a permanent blank box, which is the
## opposite of what §16 asks for ("hide/fade what is not relevant"). A
## follow-on EV9 slice adds the line once that state exists. Same reasoning
## for the compass: §16 says "if it exists," and it does not yet.

## Dark blue-gray translucent panel, thin pale border, teal accent — the
## visual language §16 asks for. No prior HUD panel establishes this; this is
## the first one, so later screens (inventory, crafting) match against it
## rather than the other way round.
const PANEL_BG := Color(0.07, 0.09, 0.13, 0.78)
const PANEL_BORDER := Color(0.55, 0.85, 0.86, 0.65)
## Deliberately more saturated and bluer than PANEL_BORDER — the two read as
## the same colour at a glance otherwise, and the stamina fill needs to stand
## out from its own panel's border, not match it.
const ACCENT_TEAL := Color(0.16, 0.58, 0.76)
const HEALTH_FULL := Color(0.38, 0.64, 0.30)
const HEALTH_LOW := Color(0.74, 0.24, 0.20)
const TRACK := Color(0.05, 0.05, 0.06, 0.85)

## Same treatment combat_hud.gd uses for anything floating over the world with
## no panel behind it — measured contrast on unplated white text there was
## below the large-text minimum, and the party/orb/prompt labels here sit over
## the same kind of unpredictable backdrop.
const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 6
const SHADOW := Color(0.0, 0.0, 0.0, 0.55)
const SHADOW_OFFSET := Vector2(0.0, 2.0)

## A bar at rest fades to this rather than to zero: gone-and-back-again on
## every full heal reads as a layout pop, faint-but-present does not. Blind
## visual review flagged the first value tried (0.28) as unreadable — the fill
## and track blended into each other and the low-alpha edges read as a
## rendering artefact rather than a calm bar.
const FADE_ALPHA := 0.55
const FADE_SPEED := 2.2

const READOUT_INTERVAL := 0.1

const PARTY := preload("res://autoload/party.gd")
const ORB_ITEM_ID := "orb_basic"

@export var player_path: NodePath
@export var arbiter_path: NodePath

## Seconds a pad must be connected with every raw axis pinned near zero before
## the debug view suggests the Ally-specific cause. Long enough that a player
## who is simply reading the screen before touching the stick does not get an
## irrelevant warning; short enough to answer "why won't it move" quickly.
const STUCK_AXES_HINT_AFTER := 3.0
const STUCK_AXES_EPSILON := 0.05

var _player: CharacterBody3D = null
var _arbiter: Node = null
var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0
var _debug_on := false

## Tracks whether a connected pad has EVER reported a non-trivial axis value.
## A single frame's reading cannot tell "not touching the stick right now"
## apart from "the stick physically cannot reach Godot" — this can, given a
## few seconds.
var _pad_connected_for := 0.0
var _max_raw_axis_seen := 0.0

@onready var _health_bar: ProgressBar = $Root/VitalsPanel/Margin/Bars/HealthRow/Health
@onready var _stamina_bar: ProgressBar = $Root/VitalsPanel/Margin/Bars/StaminaRow/Stamina
@onready var _health_label: Label = $Root/VitalsPanel/Margin/Bars/HealthRow/HealthLabel
@onready var _stamina_label: Label = $Root/VitalsPanel/Margin/Bars/StaminaRow/StaminaLabel
@onready var _party_label: Label = $Root/StatusPanel/Margin/Rows/Party
@onready var _orbs_label: Label = $Root/StatusPanel/Margin/Rows/Orbs
@onready var _prompt_label: Label = $Root/Prompt
@onready var _debug_readout: Label = $Root/DebugReadout

var _health_fill: StyleBoxFlat = null
var _stamina_fill: StyleBoxFlat = null


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
	elif _player.has_signal("landed"):
		_player.connect("landed", _on_landed)

	_arbiter = get_node_or_null(arbiter_path)

	_style_panel($Root/VitalsPanel)
	_style_panel($Root/StatusPanel)
	_health_fill = _fill_style(HEALTH_FULL)
	_stamina_fill = _fill_style(ACCENT_TEAL)
	_dress_bar(_health_bar, _health_fill)
	_dress_bar(_stamina_bar, _stamina_fill)
	_make_text_legible(_health_label)
	_make_text_legible(_stamina_label)
	_make_text_legible(_party_label)
	_make_text_legible(_orbs_label)
	_make_text_legible(_prompt_label)

	_debug_readout.visible = _debug_on
	_prompt_label.text = ""


func _style_panel(panel: PanelContainer) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", box)


func _fill_style(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.corner_radius_bottom_left = 8
	box.corner_radius_bottom_right = 8
	return box


func _dress_bar(bar: ProgressBar, fill: StyleBoxFlat) -> void:
	var track := _fill_style(TRACK)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)


## Same walk combat_hud.gd uses: outline and shadow every label under `node`,
## whatever gets added later.
func _make_text_legible(node: Node) -> void:
	if node is Label or node is RichTextLabel:
		var control := node as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
		control.add_theme_color_override("font_shadow_color", SHADOW)
		control.add_theme_constant_override("shadow_offset_x", int(SHADOW_OFFSET.x))
		control.add_theme_constant_override("shadow_offset_y", int(SHADOW_OFFSET.y))
	for child in node.get_children():
		_make_text_legible(child)


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_debug_on = not _debug_on
		_debug_readout.visible = _debug_on


func _process(delta: float) -> void:
	_draw_prompt()
	_update_status()
	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return

	_update_vitals(vitals, delta)

	if _debug_on:
		_since_readout += delta
		if _since_readout >= READOUT_INTERVAL:
			_since_readout = 0.0
			_debug_readout.text = _debug_text(vitals)


func _draw_prompt() -> void:
	if _arbiter == null:
		return
	_prompt_label.text = str(_arbiter.call("prompt"))


## Looked up by path rather than through the `Game` global, matching
## sequence_director.gd's convention, so a HUD instanced without the autoload
## running (a capture tool, an isolated test scene) just shows nothing here
## instead of crashing.
func _update_status() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return
	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")
	if party == null or inventory == null:
		return
	_party_label.text = "Pals  %d / %d" % [int(party.call("size")), PARTY.MAX_PALS]
	_orbs_label.text = "Orbs  %d" % int(inventory.call("count", ORB_ITEM_ID))


## Health and stamina bars fade to FADE_ALPHA when full and idle, full opacity
## the moment either one is doing anything worth looking at.
func _update_vitals(vitals: RefCounted, delta: float) -> void:
	var health_fraction: float = vitals.health_fraction()
	var stamina_fraction: float = vitals.stamina_fraction()

	_health_bar.value = health_fraction * 100.0
	_stamina_bar.value = stamina_fraction * 100.0
	_health_fill.bg_color = HEALTH_FULL.lerp(HEALTH_LOW, 1.0 - health_fraction)

	var sprinting: bool = bool(_player.call("is_sprinting")) if _player.has_method("is_sprinting") else false
	var health_relevant := health_fraction < 0.999
	var stamina_relevant := stamina_fraction < 0.999 or sprinting

	_fade_toward(_health_bar, 1.0 if health_relevant else FADE_ALPHA, delta)
	_fade_toward(_stamina_bar, 1.0 if stamina_relevant else FADE_ALPHA, delta)


func _fade_toward(control: Control, target: float, delta: float) -> void:
	var current: float = control.modulate.a
	var next: float = move_toward(current, target, FADE_SPEED * delta)
	control.modulate.a = next


func _debug_text(vitals: RefCounted) -> String:
	var speed: float = _player.call("ground_speed")
	var sprinting: bool = _player.call("is_sprinting")
	var pos: Vector3 = _player.global_position

	var lines: Array[String] = [
		"M1 debug (F3 to hide)",
		"",
		"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
		"vertical   %+.2f m/s" % _player.velocity.y,
		"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
		"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		"",
		"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
		"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
		"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
	]
	lines.append_array(_input_diagnostics())
	return "\n".join(lines)


## Live input diagnostics.
##
## On screen rather than in a log, because "the controller does nothing" is
## otherwise indistinguishable from four different causes: the handheld sitting
## in desktop/mouse mode so the sticks emit no joypad events at all, the pad
## enumerating without an SDL mapping, a wrong axis or button in the input map,
## or the window simply not having focus. Each of those looks identical from the
## outside and each shows up differently here.
##
## Keyboard values are shown alongside the pad on purpose: if WASD moves the
## capsule and the sticks do not, the game is fine and the problem is upstream
## of Godot.
func _input_diagnostics() -> Array[String]:
	var lines: Array[String] = ["", "--- input ---"]

	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("controller  NONE DETECTED BY GODOT")
		lines.append("  the handheld is probably in desktop/mouse mode,")
		lines.append("  or the window does not have focus")
		_pad_connected_for = 0.0
		_max_raw_axis_seen = 0.0
	else:
		for device_id in pads:
			lines.append("controller  %d: %s" % [device_id, Input.get_joy_name(device_id)])
			if not Input.is_joy_known(device_id):
				lines.append("  NOT a standard mapping: buttons/axes may be wrong")

	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	lines.append("move  %+.2f %+.2f     look  %+.2f %+.2f" % [move.x, move.y, look.x, look.y])

	# Raw axes, bypassing the input map. If these move while `move` above stays
	# zero, the pad is fine and the input map bindings are wrong.
	if not pads.is_empty():
		var device: int = pads[0]
		var lx: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
		var ly: float = Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
		var rx: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_X)
		var ry: float = Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		lines.append("raw axes  L %+.2f %+.2f   R %+.2f %+.2f" % [lx, ly, rx, ry])

		_max_raw_axis_seen = maxf(_max_raw_axis_seen, maxf(
			maxf(absf(lx), absf(ly)), maxf(absf(rx), absf(ry))))
		# On a handheld the readout is throttled to READOUT_INTERVAL, not every
		# frame, so this advances in those same steps.
		_pad_connected_for += READOUT_INTERVAL

		# A pad Godot can name and still never hears from is exactly what the
		# ROG Ally's own "Desktop Mode" produces: the sticks drive the mouse
		# cursor instead of sending joypad axis events, so the device enumerates
		# fine and every axis reads a permanent 0.00. Command Center's own
		# Gamepad Mode is the fix, and it is not a Tetherbound setting — the
		# game has no way to flip it for the player.
		if _pad_connected_for >= STUCK_AXES_HINT_AFTER and _max_raw_axis_seen < STUCK_AXES_EPSILON:
			lines.append("  raw axes have not moved at all since the pad was seen.")
			lines.append("  On ROG Ally: Command Center -> Gamepad Mode (not Desktop")
			lines.append("  Mode) — desktop mode sends the sticks to Windows as a")
			lines.append("  mouse, not to the game as a controller.")

	lines.append("jump %s  sprint %s  interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("pad: left stick move, right stick look, A jump, L3 sprint")
	lines.append("keyboard: WASD move, mouse look, Space jump, Shift sprint")
	return lines


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
