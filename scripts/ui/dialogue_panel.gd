extends CanvasLayer

## Draws the conversation. Owns no state beyond the runner it drives.
##
## Same arrangement as `combat_hud.gd`: everything on screen is PULLED from the
## runner every frame rather than pushed in when it changes. A panel that keeps
## its own copy of the current line is a panel that can disagree with the
## conversation, and the first time that happens it costs an afternoon.
##
## Text treatment is lifted from the combat HUD too — outline and shadow on
## every label, walked over the tree rather than set per node — because this
## panel sits over a sunlit meadow and the measured contrast problem that fixed
## is the same problem here.

const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")

## Frames of deafness after opening.
##
## The press that starts a conversation is the same press the panel would read
## as "advance", and whether it sees it depends on whether this node's
## _physics_process runs before or after the arbiter's. Two frames is deaf to
## the opening press whichever way round the tree is walked, and is far below
## what a human can press twice inside.
##
## OF3: the guard used to simply DROP any press that landed during it rather
## than count it. That is a narrow window (33ms), but it is not zero, and a
## player who taps interact again quickly right after opening a conversation
## (reasonable muscle memory — "one press per line") could lose that tap
## outright rather than have it advance the first line the instant the guard
## clears. `_buffered_during_guard` remembers it instead.
const OPEN_GUARD_FRAMES := 2

const PANEL_BG := Color(0.05, 0.06, 0.07, 0.93)
const PANEL_BORDER := Color(0.55, 0.60, 0.50, 0.55)
const SPEAKER_COLOUR := Color(0.90, 0.83, 0.55)
const HINT_COLOUR := Color(0.62, 0.66, 0.58)

const OUTLINE := Color(0.03, 0.04, 0.05, 0.95)
const OUTLINE_SIZE := 6
const SHADOW := Color(0.0, 0.0, 0.0, 0.55)

signal finished(conversation_id: String)

var _runner: RefCounted = RUNNER.new()
var _guard: int = 0
var _buffered_during_guard: bool = false
var _last_portrait: String = ""

@onready var _box: Control = $Root/Box
@onready var _portrait: TextureRect = $Root/Box/Margin/Row/Portrait
@onready var _speaker: Label = $Root/Box/Margin/Row/Text/Speaker
@onready var _body: Label = $Root/Box/Margin/Row/Text/Body
@onready var _hint: RichTextLabel = $Root/Box/Margin/Row/Text/Hint


func _ready() -> void:
	_dress()
	_make_text_legible($Root)
	_runner.finished.connect(_on_runner_finished)
	_box.visible = false


func _dress() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.content_margin_left = 0.0
	(_box as PanelContainer).add_theme_stylebox_override("panel", box)
	_speaker.add_theme_color_override("font_color", SPEAKER_COLOUR)
	# RichTextLabel's equivalent of Label's `font_color` is `default_color` --
	# a different property name for the same role, easy to miss since both
	# nodes otherwise share the outline/shadow property names below.
	_hint.add_theme_color_override("default_color", HINT_COLOUR)


## Outline and shadow every piece of text in the tree, whatever gets added
## later. Walked rather than listed for the reason combat_hud.gd gives: the
## failure being prevented is a label somebody adds next month.
func _make_text_legible(node: Node) -> void:
	if node is Label or node is RichTextLabel:
		var control := node as Control
		control.add_theme_constant_override("outline_size", OUTLINE_SIZE)
		control.add_theme_color_override("font_outline_color", OUTLINE)
		control.add_theme_color_override("font_shadow_color", SHADOW)
		control.add_theme_constant_override("shadow_offset_x", 0)
		control.add_theme_constant_override("shadow_offset_y", 3)
	for child in node.get_children():
		_make_text_legible(child)


## --- driving ----------------------------------------------------------------

func runner() -> RefCounted:
	return _runner


func is_open() -> bool:
	return _runner.is_active()


func start(conversation_id: String) -> bool:
	if not _runner.start(conversation_id):
		return false
	_guard = OPEN_GUARD_FRAMES
	_buffered_during_guard = false
	_draw()
	return true


## The word the player typed, for a line written as `$name`.
func set_value(key: String, value: String) -> void:
	_runner.set_value(key, value)


func drain_effects() -> Array[String]:
	return _runner.drain_effects()


func advance() -> void:
	_runner.advance()
	_draw()


func close() -> void:
	_runner.close()


func _process(_delta: float) -> void:
	_draw()


## Advance is read on the physics tick, matching the interaction arbiter and the
## combat manager. `is_action_just_pressed` is scoped to the frame the press
## landed in, and readers on different ticks disagree about which frame that was.
func _physics_process(_delta: float) -> void:
	if not _runner.is_active():
		return
	if Input.is_action_just_pressed("interact"):
		if _guard > 0:
			_buffered_during_guard = true
		else:
			advance()
	if _guard > 0:
		_guard -= 1
		if _guard == 0 and _buffered_during_guard:
			_buffered_during_guard = false
			advance()


func _draw() -> void:
	var line: Dictionary = _runner.line()
	if line.is_empty():
		_box.visible = false
		return

	_box.visible = true
	_speaker.text = str(line.get("speaker", ""))
	_body.text = str(line.get("text", ""))
	# Real glyph, not "[X] / [E]" bracket text showing both devices at once --
	# bible sec18: "Do not display both keyboard and controller prompts
	# simultaneously unless context requires it."
	_hint.text = "%s   %s" % [
		INPUT_GLYPH.icon("interact"),
		"Close" if bool(line.get("is_last", false)) else "Continue",
	]

	var portrait := str(line.get("portrait", ""))
	if portrait != _last_portrait:
		_last_portrait = portrait
		# A missing portrait leaves the frame empty rather than pushing an error
		# every frame: dialogue for a speaker with no art yet should still play.
		_portrait.texture = load(portrait) as Texture2D if ResourceLoader.exists(portrait) else null
		_portrait.visible = _portrait.texture != null


func _on_runner_finished(conversation_id: String) -> void:
	_box.visible = false
	finished.emit(conversation_id)
