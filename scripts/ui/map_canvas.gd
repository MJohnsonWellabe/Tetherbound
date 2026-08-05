extends Control

## The map, drawn. One implementation, two framings.
##
## GAME_DESIGN.md §23 asks for a world map that starts blank and fills in, and a
## minimap showing local terrain, a compass, the player, discovered locations, the
## bed and the death satchels. Those are the SAME PICTURE at two zooms, so they
## are one file: a second drawing routine is a second place the satchel pin can be
## the wrong colour, or missing.
##
##   FIT    — the full-screen map. Frames everything the player has revealed.
##   FOLLOW — the minimap. A fixed number of metres around the trainer.
##
## Drawn with `_draw()` rather than assembled out of Control nodes. A pin is four
## lines and a fog cell is a rectangle; a hundred of them as nodes would be a
## hundred nodes laid out by a container that has no idea what a map is.
##
## IT OWNS NOTHING. Every position it draws is asked for on the frame it is drawn:
## the fog from `world_map.gd`, home from `home.gd`, the bags from `satchel.gd`.
## A cached copy of any of them is a pin that can point at something that is no
## longer there, and the worst version of that bug is a satchel you have already
## emptied still drawn on the map.
##
## NORTH IS ALWAYS UP, in both framings. A minimap that rotates with the camera is
## easier to follow for the first minute and impossible to build a mental map from
## afterwards, and §23 asks for a compass rather than for a rotating disc.

const STYLE := preload("res://scripts/ui/ui_style.gd")

## Frame everything revealed, or a fixed range around the trainer.
const FIT := "fit"
const FOLLOW := "follow"

## Metres of padding around the revealed area in FIT, so the outermost cell is not
## flush against the frame.
const FIT_PADDING := 40.0
## Pixels per metre, clamped. Without a ceiling, a brand-new save with four
## revealed cells would be drawn at a hundred pixels per metre and look like a
## close-up of a lawn.
const MAX_SCALE := 2.2
const MIN_SCALE := 0.05

@export var mode: String = FIT
@export var map_path: NodePath
@export var player_path: NodePath
@export var home_path: NodePath
@export var satchels_path: NodePath
@export var world_path: NodePath
## Draw the compass letters. On by default for the minimap; the full map gets its
## own north arrow in the corner.
@export var show_compass: bool = true
## Metres across, in FOLLOW. Overridden from the map's own config when zero.
@export var range_metres: float = 0.0

## A world position to ring, set by the map screen when the cursor is on a place
## in its list. Vector3.INF for none.
var highlight: Vector3 = Vector3.INF

## Colour per revealed cell, by elevation, computed once and kept. Sampling the
## heightfield for every cell every frame would be a real cost for a picture that
## cannot change: the ground does not move.
var _cell_ink: Dictionary = {}

## --- the map's palette ------------------------------------------------------
##
## Parchment and ink rather than the world's own greens. A map is a drawing the
## trainer made, not a satellite photograph, and the unrevealed part has to read
## as "paper" rather than as "black hole". None of these is the reserved Team
## Tether oxblood (`data/config/palette.json` `_reserved`).
const PAPER := Color(0.13, 0.13, 0.11, 0.94)
const PAPER_EDGE := Color(0.60, 0.65, 0.54, 0.32)
## The revealed ground, dark in the hollows and pale on the tops. The two are far
## apart on purpose: the first version sat between 0.20 and 0.47 and the whole map
## photographed as one flat green, which tells the player nothing about the shape
## of the ground they walked over.
const LAND_LOW := Color(0.14, 0.22, 0.13)
const LAND_HIGH := Color(0.62, 0.65, 0.40)
const GRID_INK := Color(0.0, 0.0, 0.0, 0.16)
const PLAYER_INK := Color(0.96, 0.96, 0.92)
const HOME_INK := Color(0.56, 0.84, 0.42)
const SATCHEL_INK := Color(0.85, 0.62, 0.28)
const MARKER_INK := Color(0.55, 0.76, 0.90)
const COMPASS_INK := Color(0.80, 0.83, 0.74, 0.75)

var _scale: float = 1.0
var _centre: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Redrawn every frame: the trainer moves, the fog opens, a satchel is emptied.
	# `_draw()` on this many primitives is cheap and a map that lags the player by
	# a signal is a map that lies for a frame.
	set_process(true)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


# ------------------------------------------------------------------- the sources

func _map() -> Node:
	var node := get_node_or_null(map_path)
	return node if node != null and node.has_method("revealed_cells") else null


func _player() -> Node3D:
	return get_node_or_null(player_path) as Node3D


func _home() -> Node:
	var node := get_node_or_null(home_path)
	return node if node != null and node.has_method("home_point") else null


func _satchels() -> Node:
	var node := get_node_or_null(satchels_path)
	return node if node != null and node.has_method("satchels") else null


# ---------------------------------------------------------------------- framing

## Metres per pixel and where the middle of the canvas is, in world XZ.
func _frame(map: Node) -> void:
	var trainer := _player()
	var here := trainer.global_position if trainer != null else Vector3.ZERO

	if mode == FOLLOW:
		var span: float = range_metres
		if span <= 0.0 and map != null:
			span = float(map.call("minimap_range"))
		span = maxf(20.0, span)
		_centre = Vector2(here.x, here.z)
		_scale = clampf(minf(size.x, size.y) / span, MIN_SCALE, MAX_SCALE)
		return

	# FIT: everything revealed, plus everything pinned, plus the trainer.
	var low := Vector2(here.x, here.z)
	var high := low
	if map != null:
		var cell_size: float = float(map.call("cell_size"))
		var bounds: Array = map.call("revealed_bounds")
		if int(map.call("revealed_count")) > 0:
			var a: Vector2i = bounds[0]
			var b: Vector2i = bounds[1]
			low.x = minf(low.x, float(a.x) * cell_size)
			low.y = minf(low.y, float(a.y) * cell_size)
			high.x = maxf(high.x, float(b.x + 1) * cell_size)
			high.y = maxf(high.y, float(b.y + 1) * cell_size)
	for point: Vector3 in _pin_points():
		low.x = minf(low.x, point.x)
		low.y = minf(low.y, point.z)
		high.x = maxf(high.x, point.x)
		high.y = maxf(high.y, point.z)

	low -= Vector2(FIT_PADDING, FIT_PADDING)
	high += Vector2(FIT_PADDING, FIT_PADDING)
	_centre = (low + high) * 0.5
	var span_x: float = maxf(1.0, high.x - low.x)
	var span_y: float = maxf(1.0, high.y - low.y)
	_scale = clampf(minf(size.x / span_x, size.y / span_y), MIN_SCALE, MAX_SCALE)


## Every world position something is pinned at, so FIT can frame them all.
func _pin_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var home := _home()
	if home != null:
		var where: Vector3 = home.call("home_point")
		if where != Vector3.INF:
			out.append(where)
	var satchels := _satchels()
	if satchels != null:
		for entry: Variant in satchels.call("satchels"):
			out.append((entry as RefCounted).where as Vector3)
	var map := _map()
	if map != null:
		for marker: Dictionary in map.call("markers"):
			out.append(Vector3(float(marker["x"]), 0.0, float(marker["z"])))
	return out


## World XZ to canvas pixels. North (-Z) is up, so the Z axis maps straight to Y.
func to_canvas(point: Vector3) -> Vector2:
	return size * 0.5 + (Vector2(point.x, point.z) - _centre) * _scale


# ---------------------------------------------------------------------- drawing

func _draw() -> void:
	var map := _map()
	_frame(map)

	draw_rect(Rect2(Vector2.ZERO, size), PAPER, true)
	if map != null:
		_draw_fog(map)
	else:
		# A canvas with no map behind it says so, rather than photographing as a
		# convincing empty map that nobody would think to question.
		_draw_note("no map data wired to this canvas")

	_draw_home()
	_draw_satchels()
	_draw_markers(map)
	_draw_player()
	if show_compass:
		_draw_compass()
	if highlight != Vector3.INF:
		_draw_ring(to_canvas(highlight), 16.0, PLAYER_INK)
	draw_rect(Rect2(Vector2.ZERO, size), PAPER_EDGE, false, 2.0)


## The revealed cells. §23: the map is blank at first and fills in as you walk.
func _draw_fog(map: Node) -> void:
	var cell_size: float = float(map.call("cell_size"))
	var pixels: float = cell_size * _scale
	if pixels <= 0.0:
		return
	for key: Variant in map.call("revealed_cells"):
		var cell: Vector2i = key
		var corner := to_canvas(Vector3(float(cell.x) * cell_size, 0.0, float(cell.y) * cell_size))
		# A cell entirely off the canvas is skipped rather than clipped, which is
		# what keeps the minimap cheap on a fully explored map.
		if corner.x > size.x or corner.y > size.y or corner.x + pixels < 0.0 or corner.y + pixels < 0.0:
			continue
		# +1 pixel, so neighbouring cells share an edge instead of leaving a hairline
		# of paper between them that reads as a grid nobody drew.
		draw_rect(Rect2(corner, Vector2(pixels + 1.0, pixels + 1.0)), _ink_for(cell, cell_size), true)
		if pixels >= 14.0:
			draw_rect(Rect2(corner, Vector2(pixels, pixels)), GRID_INK, false, 1.0)


## A cell's colour, from the ground under it. Low ground darker, high ground
## lighter, which is enough for the shape of the valley and the rises to read.
##
## D09: the height comes from `ground_height_at`, which reads the heightmap. Never
## a raycast.
func _ink_for(cell: Vector2i, cell_size: float) -> Color:
	if _cell_ink.has(cell):
		return _cell_ink[cell]
	var ink := LAND_LOW.lerp(LAND_HIGH, 0.45)
	var world: Node = get_node_or_null(world_path)
	if world != null and world.has_method("ground_height_at"):
		var height: float = float(world.call("ground_height_at",
			(float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size))
		if not is_nan(height):
			# The playground spans roughly -25m to +35m. Normalised loosely rather
			# than exactly: this is shading, not a contour survey.
			ink = LAND_LOW.lerp(LAND_HIGH, clampf((height + 25.0) / 60.0, 0.0, 1.0))
	_cell_ink[cell] = ink
	return ink


func _draw_player() -> void:
	var trainer := _player()
	if trainer == null:
		return
	var at := to_canvas(trainer.global_position)
	# An arrow, pointing where they face. A dot would answer "where am I" and not
	# "which way am I looking", and the second is the question a minimap is for.
	var facing := _facing_of(trainer)
	var forward := Vector2(sin(facing), cos(facing))
	var side := Vector2(forward.y, -forward.x)
	var points := PackedVector2Array([
		at + forward * 11.0,
		at - forward * 7.0 + side * 7.0,
		at - forward * 7.0 - side * 7.0,
	])
	draw_colored_polygon(points, PLAYER_INK)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]),
		Color(0.05, 0.05, 0.05, 0.9), 2.0)


## Which way the trainer is looking. The model's yaw when there is one — the body
## itself does not turn, only the mesh inside it does (`player_controller._face`).
func _facing_of(trainer: Node3D) -> float:
	var model := trainer.get_node_or_null(^"Model") as Node3D
	return model.rotation.y if model != null else trainer.rotation.y


func _draw_home() -> void:
	var home := _home()
	if home == null:
		return
	var where: Vector3 = home.call("home_point")
	if where == Vector3.INF:
		return
	var at := to_canvas(where)
	# A house: a square with a roof. Legible at minimap size, which a letter is
	# not.
	draw_rect(Rect2(at - Vector2(7.0, 5.0), Vector2(14.0, 11.0)), HOME_INK, true)
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-9.0, -5.0), at + Vector2(0.0, -13.0), at + Vector2(9.0, -5.0),
	]), HOME_INK)


## §22: every satchel stays marked. The reason this pin matters more than the
## others is that a satchel you cannot find is a satchel that ate your inventory.
func _draw_satchels() -> void:
	var satchels := _satchels()
	if satchels == null:
		return
	for entry: Variant in satchels.call("satchels"):
		var at := to_canvas((entry as RefCounted).where as Vector3)
		# BIGGER THAN THE OTHER PINS, deliberately. Everything else on this map is
		# somewhere you chose to remember; a satchel is everything you were carrying
		# when you died, and it is the one pin that has to be findable at a glance.
		draw_rect(Rect2(at - Vector2(9.0, 7.0), Vector2(18.0, 15.0)), SATCHEL_INK, true)
		draw_rect(Rect2(at - Vector2(9.0, 7.0), Vector2(18.0, 15.0)),
			Color(0.05, 0.05, 0.05, 0.9), false, 2.0)
		# The strap, so it reads as a bag rather than as a block of colour.
		draw_line(at + Vector2(-5.0, -7.0), at + Vector2(5.0, -7.0), SATCHEL_INK, 4.0)


func _draw_markers(map: Node) -> void:
	if map == null:
		return
	for marker: Dictionary in map.call("markers"):
		var at := to_canvas(Vector3(float(marker["x"]), 0.0, float(marker["z"])))
		draw_line(at + Vector2(-7.0, -7.0), at + Vector2(7.0, 7.0), MARKER_INK, 3.0)
		draw_line(at + Vector2(7.0, -7.0), at + Vector2(-7.0, 7.0), MARKER_INK, 3.0)


func _draw_ring(at: Vector2, radius: float, colour: Color) -> void:
	draw_arc(at, radius, 0.0, TAU, 24, colour, 2.0)


## §23's compass. Letters rather than a rose: north is up and stays up, so the
## compass is a label on a fixed frame, and four letters are readable at minimap
## size where a rose is a smudge.
func _draw_compass() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 18
	var middle := size * 0.5
	for entry: Array in [
		["N", Vector2(middle.x, 20.0)],
		["S", Vector2(middle.x, size.y - 8.0)],
		["W", Vector2(12.0, middle.y + 6.0)],
		["E", Vector2(size.x - 22.0, middle.y + 6.0)],
	]:
		draw_string(font, entry[1] as Vector2, str(entry[0]), HORIZONTAL_ALIGNMENT_LEFT,
			-1.0, font_size, COMPASS_INK)


func _draw_note(text: String) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(16.0, 28.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, COMPASS_INK)
