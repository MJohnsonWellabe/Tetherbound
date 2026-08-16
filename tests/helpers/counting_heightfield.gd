extends "res://scripts/world/playground_heightfield.gd"

## A heightfield that counts how many times `height_at` re-derives the natural
## ground with `_raw_height`.
##
## Exists for PERF2. `_raw_height` re-runs the whole noise stack — hills,
## detail, valley, and the ridged/terraced rise relief — so it is by far the
## most expensive thing `height_at` can do, and the number of times one query
## triggers it is the difference between a water build that takes two minutes
## and one that takes twenty seconds. That count is a property of the code, not
## of the machine, which is why the test asserts on it instead of on a
## stopwatch.
##
## GDScript methods dispatch dynamically, so the parent's own internals call
## this override rather than the implementation they were compiled against.

var raw_height_calls := 0


func _raw_height(x: float, z: float) -> float:
	raw_height_calls += 1
	return super._raw_height(x, z)
