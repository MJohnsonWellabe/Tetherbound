extends Control

## The bond tether (spec §8.4): five nodes on a line, the same "how many
## thresholds crossed" shape `creature_instance.gd::bond_nodes()` and
## `progression.gd::bond_nodes()` already compute — this widget only draws
## what those return, it does not decide bond thresholds itself.
##
## A custom `_draw()` rather than five child Controls: five circles on a line
## with a caption underneath is cheaper to keep in sync as one paint call than
## as six nodes whose positions and colours would otherwise all have to agree
## with each other every frame.

const UI_TOKENS := preload("res://scripts/ui/ui_tokens.gd")

const GRAPHIC_SIZE := Vector2(220.0, 28.0)
## Room for "Bond N/100" underneath the graphic.
const CAPTION_HEIGHT := 26.0

const NODE_RADIUS := 5.0
const LINE_WIDTH := 3.0

var _bond: int = 0
var _bond_max: int = 100
var _nodes: int = 0
var _total_nodes: int = 5
var _font: Font = null


func _ready() -> void:
	custom_minimum_size = Vector2(GRAPHIC_SIZE.x, GRAPHIC_SIZE.y + CAPTION_HEIGHT)
	_font = load(UI_TOKENS.FONT_PATH)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `bond`/`bond_max` are for the caption text only; `nodes`/`total_nodes`
## decide how many of the five circles paint filled. Split rather than
## deriving nodes from bond here, because the threshold table
## (`data/config/progression.json`'s `bond.thresholds`) is not this widget's
## to know — `creature_instance.bond_nodes(cfg)` already does that work.
func set_bond(bond: int, bond_max: int, nodes: int, total_nodes: int = 5) -> void:
	_bond = bond
	_bond_max = maxi(bond_max, 1)
	_nodes = clampi(nodes, 0, total_nodes)
	_total_nodes = maxi(total_nodes, 1)
	queue_redraw()


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

	var caption := "Bond %d/%d" % [_bond, _bond_max]
	var caption_pos := Vector2(0.0, GRAPHIC_SIZE.y + UI_TOKENS.FONT_TINY)
	draw_string(
		_font, caption_pos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
		UI_TOKENS.FONT_TINY, UI_TOKENS.TEXT_SECONDARY
	)
