extends SceneTree

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var field = HEIGHTFIELD.new()
	var min_x := -1024.0
	var max_x := 1024.0
	var step := 4.0
	for z in [1330.0, 7370.8, 7429.2]:
		print("=== z=%.1f ===" % z)
		var prev = null
		var worst_grade := 0.0
		var worst_x := 0.0
		var x := min_x
		while x <= max_x:
			var h = field.height_at(x, z)
			if prev != null and not is_nan(h) and not is_nan(prev):
				var grade = absf(h - prev) / step
				if grade > worst_grade:
					worst_grade = grade
					worst_x = x
			prev = h
			x += step
		print("  worst analytic grade %.3f (%.1f deg) at x=%.1f" % [worst_grade, rad_to_deg(atan(worst_grade)), worst_x])
	quit(0)
