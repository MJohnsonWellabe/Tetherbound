extends SceneTree

## GATE-F-LEG-S10CDE. S10c's walk-back stalled hard at world (13.47, -0.08,
## 7416.99), oscillating in place for the rest of a 31500-frame budget while
## trying to reach (-8, 7100). Sample raw terrain height on a grid around the
## stall point to see what stick_navigator.gd's _drops_away probe would have
## seen, without paying for a full 90-frame world stand-up.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var cx := 13.47
	var cz := 7416.99
	print("=== grid around stall point (%.2f, %.2f), heights ===" % [cx, cz])
	for dz in range(-40, 41, 8):
		var row := ""
		for dx in range(-40, 41, 8):
			var h: float = field.height_at(cx + dx, cz + dz)
			row += "%7.2f" % h
		print("z=%7.1f : %s" % [cz + dz, row])
	print("")
	print("=== fine grid (2m step, +-12m) ===")
	for dz in range(-12, 13, 2):
		var row := ""
		for dx in range(-12, 13, 2):
			var h: float = field.height_at(cx + dx, cz + dz)
			row += "%7.2f" % h
		print("z=%7.1f : %s" % [cz + dz, row])
	print("")
	print("=== the target the move_to was heading toward: (-8, 7100) ===")
	print("straight-line direction from stall point: %s" % Vector2(-8.0 - cx, 7100.0 - cz).normalized())
	print("height at stall point itself: %.3f" % field.height_at(cx, cz))
	print("height 4m toward target: %.3f" % field.height_at(cx - 1.86, cz - 4.55))
	print("height 4m away from target (north): %.3f" % field.height_at(cx + 1.86, cz + 4.55))
	# The sigil gate and checkpoint trainer, for scale reference.
	print("")
	print("distance to sigil gate (63.6,7400.0): %.1f m" % Vector2(cx, cz).distance_to(Vector2(63.6, 7400.0)))
	print("distance to checkpoint trainer (45.0,7440.0): %.1f m" % Vector2(cx, cz).distance_to(Vector2(45.0, 7440.0)))
	quit(0)
