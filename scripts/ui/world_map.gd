extends Node

## What the player has SEEN, and what they have pinned.
##
## GAME_DESIGN.md §23: the world map is "blank initially", "reveals through
## exploration" and "supports manual markers". Those three lines are this file.
## The minimap and the full-screen map both read it; neither keeps a second copy,
## because two lists of where you have been is two lists that can disagree.
##
## WHAT IS NOT HERE, ON PURPOSE:
##
##   * The bed, and the death satchels. §23 wants both on the map, and both are
##     already owned by something else — `home.gd` knows where home is and
##     `satchel.gd` holds every bag. The screens ask THEM. A copy here would be a
##     third place the truth lives, and the first time it drifted would be the
##     time a player walked to a satchel that had already been emptied.
##   * Wild pals. §23: "Do not reveal every wild pal automatically."
##   * Fast travel. §23: "No free map fast travel before teleport progression."
##
## FOG IS A GRID OF CELLS, not a texture. A revealed bitmap would have to be sized
## to a world whose real dimensions are not decided yet (the playground is a test
## area that the authored Meadows replaces wholesale), and it would have to be
## saved as an image. A set of visited cells is a handful of integers, survives the
## world changing size, and draws as squares — which is also the right LOOK for a
## hand-drawn map filling in.

const CONFIG_PATH := "res://data/config/survival.json"

## The key this system owns inside `SaveManager`'s one envelope (D14). A map that
## forgets what you explored every time you close the game is not a map.
const SAVE_DOMAIN := "map"

signal revealed(cell: Vector2i)
signal markers_changed()

@export var player_path: NodePath = NodePath("../Player")

var _player: Node3D = null
var _config: Dictionary = {}

## Visited cells, as a set: `Vector2i -> true`. A Dictionary rather than an Array
## because "have I been here" is asked once per frame per cell in the reveal
## sweep, and a linear scan of a thousand entries would be a real cost for nothing.
var _cells: Dictionary = {}

## Manual pins: `{x, y, z, label}`. Ordered, oldest first, so the numbering the
## player sees is stable.
var _markers: Array[Dictionary] = []
var _marker_serial: int = 0

## Only re-sweep when the trainer has actually gone somewhere. Walking in a circle
## inside one cell should not cost the same as crossing the meadow.
var _last_swept: Vector3 = Vector3(INF, INF, INF)


func _ready() -> void:
	_player = get_node_or_null(player_path) as Node3D
	_register()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var here: Vector3 = _player.global_position
	if _last_swept.is_finite() and here.distance_to(_last_swept) < cell_size() * 0.5:
		return
	_last_swept = here
	reveal_around(here)


## --- the fog ----------------------------------------------------------------

func cell_of(point: Vector3) -> Vector2i:
	var size := cell_size()
	return Vector2i(int(floorf(point.x / size)), int(floorf(point.z / size)))


## The centre of a cell in world space, which is where the map draws it.
func centre_of(cell: Vector2i) -> Vector3:
	var size := cell_size()
	return Vector3((float(cell.x) + 0.5) * size, 0.0, (float(cell.y) + 0.5) * size)


func is_revealed(cell: Vector2i) -> bool:
	return _cells.has(cell)


func revealed_count() -> int:
	return _cells.size()


func revealed_cells() -> Array:
	return _cells.keys()


## Open every cell whose centre is within the reveal radius of a point.
##
## By CENTRE rather than by any overlap, so the revealed shape is a little tighter
## than the radius suggests and a corridor walked in a straight line comes out as
## a corridor rather than as a smear two cells wider than the path.
func reveal_around(point: Vector3) -> int:
	var size := cell_size()
	var radius := reveal_radius()
	var reach := int(ceilf(radius / size)) + 1
	var middle := cell_of(point)
	var opened := 0
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			var cell := Vector2i(middle.x + dx, middle.y + dz)
			if _cells.has(cell):
				continue
			var centre := centre_of(cell)
			if Vector2(centre.x - point.x, centre.z - point.z).length() > radius:
				continue
			_cells[cell] = true
			opened += 1
			revealed.emit(cell)
	return opened


## The rectangle the revealed cells occupy, in cells, as `[min, max]` inclusive.
## What a map screen frames itself around, so a blank map is not drawn at the
## world's full extent with one lit square in the middle of it.
func revealed_bounds() -> Array[Vector2i]:
	if _cells.is_empty():
		return [Vector2i.ZERO, Vector2i.ZERO]
	var low := Vector2i(2147483647, 2147483647)
	var high := Vector2i(-2147483648, -2147483648)
	for key: Variant in _cells.keys():
		var cell: Vector2i = key
		low.x = mini(low.x, cell.x)
		low.y = mini(low.y, cell.y)
		high.x = maxi(high.x, cell.x)
		high.y = maxi(high.y, cell.y)
	return [low, high]


## --- manual markers ---------------------------------------------------------

## Pin a spot. §23 asks for manual markers and says nothing about naming them, and
## there is no text entry on a controller that is worth the four screens it would
## cost — so they are numbered in the order they were placed, which is enough to
## tell two apart in a list.
##
## Refused past `map.max_markers`, so the map cannot become a field of pins. The
## refusal is a `false` the screen turns into a sentence.
func add_marker(where: Vector3, label: String = "") -> bool:
	if _markers.size() >= max_markers():
		return false
	_marker_serial += 1
	_markers.append({
		"x": where.x,
		"y": where.y,
		"z": where.z,
		"label": label if not label.is_empty() else "Marker %d" % _marker_serial,
	})
	markers_changed.emit()
	return true


func remove_marker(index: int) -> bool:
	if index < 0 or index >= _markers.size():
		return false
	_markers.remove_at(index)
	markers_changed.emit()
	return true


func markers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for marker in _markers:
		out.append(marker.duplicate())
	return out


func marker_count() -> int:
	return _markers.size()


func marker_point(index: int) -> Vector3:
	if index < 0 or index >= _markers.size():
		return Vector3.ZERO
	var marker := _markers[index]
	return Vector3(float(marker["x"]), float(marker["y"]), float(marker["z"]))


## --- config -----------------------------------------------------------------

func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("survival.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


func _map_config() -> Dictionary:
	return config().get("map", {})


func cell_size() -> float:
	return maxf(1.0, float(_map_config().get("cell_size", 16.0)))


func reveal_radius() -> float:
	return maxf(1.0, float(_map_config().get("reveal_radius", 40.0)))


func minimap_range() -> float:
	return maxf(10.0, float(_map_config().get("minimap_range", 120.0)))


func max_markers() -> int:
	return maxi(1, int(_map_config().get("max_markers", 16)))


## --- save contributor -------------------------------------------------------

func _save_manager() -> Node:
	var manager: Node = get_node_or_null(^"/root/SaveManager")
	if manager != null:
		_register(manager)
	return manager


func _register(manager: Node = null) -> void:
	var target: Node = manager if manager != null else get_node_or_null(^"/root/SaveManager")
	if target != null and target.has_method("register"):
		target.call("register", SAVE_DOMAIN, self)


## Cells go out as ONE STRING, not as an array of numbers.
##
## `save_manager.gd` writes the envelope indented and key-sorted so two runs can be
## diffed, and an indented JSON array puts every element on its own line — a
## thousand explored cells would be two thousand lines in a file the autosave has
## to write inside half a frame. "x,z x,z" is one line, is still greppable by hand,
## and parses with a split.
func save_data() -> Dictionary:
	var parts := PackedStringArray()
	for key: Variant in _cells.keys():
		var cell: Vector2i = key
		parts.append("%d,%d" % [cell.x, cell.y])
	return {
		"cells": " ".join(parts),
		"markers": markers(),
		"serial": _marker_serial,
	}


func load_data(data: Dictionary) -> void:
	_cells.clear()
	for part: String in str(data.get("cells", "")).split(" ", false):
		var pair := part.split(",")
		if pair.size() != 2:
			continue
		_cells[Vector2i(int(pair[0]), int(pair[1]))] = true

	_markers.clear()
	for entry: Variant in data.get("markers", []):
		if not entry is Dictionary:
			continue
		var marker: Dictionary = entry
		_markers.append({
			"x": float(marker.get("x", 0.0)),
			"y": float(marker.get("y", 0.0)),
			"z": float(marker.get("z", 0.0)),
			"label": str(marker.get("label", "Marker")),
		})
	_marker_serial = maxi(int(data.get("serial", 0)), _markers.size())
	# Force the next sweep: the restored player is somewhere else entirely.
	_last_swept = Vector3(INF, INF, INF)
	markers_changed.emit()
