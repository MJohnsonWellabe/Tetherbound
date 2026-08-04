extends CanvasLayer

## What you are about to build, which buttons change it, and why the game is
## refusing.
##
## Build mode shipped with none of this. `build_mode.gd` has known its selected
## piece, its cycle list, whether the ghost is placeable and the exact reason it
## is not since the day it landed, and nothing read any of it — so the palette
## was invisible, the piece list was invisible, and a refused placement was a
## ghost that turned amber for a reason the player had to guess. Everything here
## reads accessors that already existed. Nothing was added to `build_mode.gd`.
##
## NOT a screen on the stack. Build mode is a live world mode — the trainer is
## standing in the meadow, the camera is theirs, the ghost is tracking where they
## are looking — and putting it behind a modal would suspend the exact input it
## exists to take. This is a strip, like the combat HUD is a strip.
##
## Pull, don't push, for `combat_hud.gd`'s reason. The piece name, the index and
## the ghost's validity are read every frame from `build_mode`, because those are
## VALUES. The signals are only used for MOMENTS — something was placed, or a
## press was refused — which are things that happen rather than things that are
## true, and which have to survive past the frame they occurred on to be read.

const STYLE := preload("res://scripts/ui/ui_style.gd")

## How long a refusal or a confirmation stays up. `combat_hud` uses 1.6s for a
## refused throw and this is the same class of message. Tunable.
const MESSAGE_SECONDS := 1.8

@export var build_path: NodePath

var _build: Node = null
var _message: String = ""
var _message_left: float = 0.0
var _message_good: bool = false

@onready var _strip: PanelContainer = $Root/Strip
@onready var _piece: Label = $Root/Strip/Pad/Lines/Piece
@onready var _status: RichTextLabel = $Root/Strip/Pad/Lines/Status
@onready var _hints: RichTextLabel = $Root/Strip/Pad/Lines/Hints
@onready var _message_label: RichTextLabel = $Root/Message


func _ready() -> void:
	_build = get_node_or_null(build_path)
	_strip.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.PANEL_BG, STYLE.PANEL_EDGE, 8)
	)
	STYLE.make_legible($Root)

	if _build == null:
		push_warning("build palette has no build mode; it will stay hidden")
	else:
		_build.connect("placed", _on_placed)
		_build.connect("refused", _on_refused)
		_build.connect("closed", _on_closed)

	_hints.text = _hint_row()
	_strip.visible = false
	_message_label.text = ""


func _process(delta: float) -> void:
	_tick_message(delta)

	var open: bool = _build != null and bool(_build.call("is_open"))
	_strip.visible = open
	if not open:
		return

	_draw_piece()
	_draw_status()


## The piece, and where it sits in the list.
##
## "3 / 21" rather than just the name, because the single most likely thing to go
## wrong with a build palette that shows one item is that the player never learns
## there are twenty others. The count is the whole hint.
func _draw_piece() -> void:
	var name := str(_build.call("selected_name"))
	if name == "":
		name = str(_build.call("selected_id"))
	var ids: Array = _build.call("piece_ids")
	var index := ids.find(str(_build.call("selected_id")))
	if index < 0 or ids.is_empty():
		_piece.text = name if name != "" else "no pieces"
		return
	_piece.text = "%s        %d / %d" % [name, index + 1, ids.size()]


## Green when it will go down, amber and a reason when it will not.
##
## The line is ALWAYS drawn — "ready to place" when the ghost is valid rather than
## an empty row that fills in only on failure. `build_mode.gd` already learned
## this from the cooldown verbs and says so about the ghost itself: "it goes amber
## instead of vanishing... a widget that disappears reads as broken, one that
## changes colour reads as an answer." The same two colours as the ghost, so the
## strip and the thing it is describing agree.
func _draw_status() -> void:
	if bool(_build.call("ghost_valid")):
		_status.text = "[center][color=#%s]ready to place[/color][/center]" % STYLE.GOOD
		return
	var reason := str(_build.call("refusal"))
	_status.text = "[center][color=#%s]%s[/color][/center]" % [
		STYLE.WARN, reason if reason != "" else "cannot build there"
	]


## The buttons, from the input map, in the order you use them.
##
## Pad glyphs are the Xbox layout the input map is written against: cycle is
## `combat_switch_left`/`right` on the D-pad, rotate is `tool_cycle` on LB, place
## is `combat_quick` on A, remove is `combat_charged` on X, and `build_toggle` on
## RB is the way out. Built once — unlike the combat prompt row, none of these
## can be unavailable, so there is nothing here to dim.
func _hint_row() -> String:
	var rows: Array[Array] = []
	rows.append(["◄►", "Piece", true])
	rows.append(["LB", "Rotate", true])
	rows.append(["A", "Place", true])
	rows.append(["X", "Remove", true])
	rows.append(["RB", "Leave", true])
	return STYLE.hint_row(rows)


## Moments, drawn above the strip rather than inside it.
##
## Separate from the ghost's status line because they answer different questions.
## The status line says why the thing under your cursor cannot go there right
## now; this says what happened when you pressed the button. Collapsing them puts
## "nothing here to remove" in the slot that is meant to describe a placement,
## and the player reads it as the reason their wall was rejected.
##
## It draws whether or not the strip does: `build_mode` refuses to OPEN during a
## fight, and that refusal has nowhere else to appear.
func _tick_message(delta: float) -> void:
	if _message_left <= 0.0:
		if _message != "":
			_message = ""
			_message_label.text = ""
		return
	_message_left -= delta
	_message_label.text = "[center][color=#%s]%s[/color][/center]" % [
		STYLE.GOOD if _message_good else STYLE.WARN, _message
	]


func _on_placed(piece_id: String) -> void:
	# The display name if the selection is still what was placed — which it is,
	# since placing does not cycle — and the id humanised if it somehow is not.
	# A confirmation that says `wall_stone_half` is a debug string.
	var name := str(_build.call("selected_name"))
	if str(_build.call("selected_id")) != piece_id or name == "":
		name = piece_id.replace("_", " ").capitalize()
	_say("placed %s" % name, true)


func _on_refused(reason: String) -> void:
	_say(reason, false)


func _on_closed() -> void:
	# A refusal left hanging after the mode closes describes a mode that is no
	# longer open.
	_message = ""
	_message_left = 0.0
	_message_label.text = ""


func _say(message: String, good: bool) -> void:
	_message = message
	_message_good = good
	_message_left = MESSAGE_SECONDS
