extends Control

## The bond tether (spec §8.4): five nodes on a line, the same "how many
## milestones completed" shape `creature_instance.gd::bond_nodes()` and
## `bond_milestones.gd::tier()` already compute — this widget only draws
## what those return, it does not decide the milestone ladder itself.
##
## A custom `_draw()` rather than five child Controls: five circles on a line
## with a caption underneath is cheaper to keep in sync as one paint call than
## as six nodes whose positions and colours would otherwise all have to agree
## with each other every frame.
##
## OWNER-0901-BOND-MILESTONES: the caption used to read a bare "Bond N/100",
## exactly the opaque meter the owner's 2026-09-01 playtest objected to
## ("I don't understand bond. It just goes up."). It now takes the current
## milestone's own progress SENTENCE instead ("38/50 wild creatures defeated
## together") — `bond_milestones.gd::progress_text()` builds it, so this
## widget, the Team screen row and the release ceremony can never disagree
## about the wording.

const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")

const GRAPHIC_SIZE := Vector2(220.0, 28.0)
## Room for the milestone progress line underneath the graphic.
const CAPTION_HEIGHT := 32.0

const NODE_RADIUS := 5.0
const LINE_WIDTH := 3.0

var _caption: String = ""
var _nodes: int = 0
var _total_nodes: int = 5
var _font: Font = null
## PROGRESSION-VISIBLE: how far along (0..1) the NEXT node's task is. Drawn
## as a partial arc on the first hollow node, so the meter itself says "you
## are most of the way to the next one" rather than five identical rings.
var _next_progress: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(GRAPHIC_SIZE.x, GRAPHIC_SIZE.y + CAPTION_HEIGHT)
	_font = load(UI_TOKENS.FONT_PATH)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `caption` is the milestone progress sentence to print underneath (see this
## file's own header); `nodes`/`total_nodes` decide how many of the five
## circles paint filled. Split rather than deriving nodes from the caption
## here, because the milestone ladder (`data/config/bond_milestones.json`) is
## not this widget's to know — `creature_instance.bond_nodes(cfg)` already
## does that work.
func set_bond(caption: String, nodes: int, total_nodes: int = 5, next_progress: float = 0.0) -> void:
	_caption = caption
	_nodes = clampi(nodes, 0, total_nodes)
	_total_nodes = maxi(total_nodes, 1)
	_next_progress = clampf(next_progress, 0.0, 1.0)
	queue_redraw()


func next_progress() -> float:
	return _next_progress


func _draw() -> void:
	if _font == null:
		_font = load(UI_TOKENS.FONT_PATH)

	var y := GRAPHIC_SIZE.y * 0.5
	var left := NODE_RADIUS + 2.0
	var right := GRAPHIC_SIZE.x - NODE_RADIUS - 2.0
	var step := (right - left) / float(maxi(_total_nodes - 1, 1))

	draw_line(Vector2(left, y), Vector2(right, y), UI_TOKENS.BORDER, LINE_WIDTH, true)

	for i in _total_nodes:
		var center := Vector2(left + step * float(i), y)
		if i < _nodes:
			# Teal at the first node, warm gold by the last — a tether that
			# visibly warms up as it fills, rather than five identical dots.
			var t := 0.0 if _total_nodes <= 1 else float(i) / float(_total_nodes - 1)
			draw_circle(center, NODE_RADIUS, UI_TOKENS.TEAL.lerp(UI_TOKENS.WARNING, t))
		else:
			draw_arc(center, NODE_RADIUS, 0.0, TAU, 16, UI_TOKENS.BORDER, 2.0, true)
			if i == _nodes and _next_progress > 0.0:
				# The node being worked toward: a warm arc that closes as the
				# task's counter approaches its target (clockwise from the top).
				draw_arc(center, NODE_RADIUS + 1.0, -TAU * 0.25, -TAU * 0.25 + TAU * _next_progress,
					24, UI_TOKENS.WARNING, 3.0, true)

	# BLIND-JUDGE ROUND 2: this caption measured ~9px on a 1280x800 frame and
	# the judge misread "NEXT" as "NEHT" and ran "FED TOGETHER" together.
	# FONT_LABEL is the glance tier the rest of the HUD reads at.
	var caption_pos := Vector2(0.0, GRAPHIC_SIZE.y + UI_TOKENS.FONT_LABEL)
	draw_string(
		_font, caption_pos, _caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		UI_TOKENS.FONT_LABEL, UI_TOKENS.TEXT_SECONDARY
	)
