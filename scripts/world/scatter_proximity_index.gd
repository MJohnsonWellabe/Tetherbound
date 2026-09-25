extends RefCounted

## A uniform-grid index over solid scatter footprints, answering exactly what
## `vegetation.gd::has_solid_scatter_near()` answers -- is any footprint's
## (radius + extra) circle within reach of this point on the ground plane --
## without scanning every placement in the world per question.
##
## Why it exists: `band_pickups.gd` asks that question once per pickup and
## again per nudge attempt, about 130 pickups on the Meadows, and each linear
## scan walks every collidable placement plus every soft occluder. Measured on
## a 2-core-throttled run, that was one un-yielded 12-15 s slice of the Meadows
## build (solo boot and the host's realm shell alike), long enough to trip the
## 15 s peer-silent detector when the host's shell reached it during a guest's
## crossing; with this index the same pass took 0.3 s.
##
## A snapshot: built from the scatter as it stands and not updated by later
## harvests. Build one per placement pass (`vegetation.solid_scatter_index()`)
## and let it go.

var _cell: float
var _cells: Dictionary = {}
var _max_radius: float = 0.0
var _count: int = 0


func _init(cell: float = 8.0) -> void:
	_cell = maxf(cell, 0.5)


func add(x: float, z: float, radius: float) -> void:
	var key := Vector2i(floori(x / _cell), floori(z / _cell))
	var row: PackedFloat64Array = _cells.get(key, PackedFloat64Array())
	row.append(x)
	row.append(z)
	row.append(radius)
	_cells[key] = row
	_max_radius = maxf(_max_radius, radius)
	_count += 1


func size() -> int:
	return _count


## Same test as the linear scan: planar distance squared <= (radius + extra)^2.
func has_near(centre: Vector3, extra: float) -> bool:
	# The scan squares the reach, so a negative `extra` still reaches |reach|;
	# the extra cell absorbs float rounding at an exact cell multiple.
	var span := int(ceil(absf(_max_radius + extra) / _cell)) + 1
	var cx := floori(centre.x / _cell)
	var cz := floori(centre.z / _cell)
	for dx in range(-span, span + 1):
		for dz in range(-span, span + 1):
			var row: Variant = _cells.get(Vector2i(cx + dx, cz + dz))
			if row == null:
				continue
			var cells: PackedFloat64Array = row
			for i in range(0, cells.size(), 3):
				var reach: float = cells[i + 2] + extra
				if Vector2(cells[i] - centre.x, cells[i + 1] - centre.z).length_squared() <= reach * reach:
					return true
	return false
