extends SceneTree

## Throwaway probe for OF11: does the rebuilt rise relief actually change the
## surface, and does it stay inside the playground's own slope-fraction bounds?
##
##   godot --headless --path . --script tools/_probe_rise_form.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var cfg := HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(cfg)
	var soil_at := float(cfg["colour"]["soil_slope_deg"])
	var rock_at := float(cfg["colour"]["rock_slope_deg"])

	# 1. Whole-map steep fraction, the same sampling test_playground_heightfield
	#    uses (bounds: > 2%, < 45%).
	var steep := 0
	var samples := 0
	for z in range(-240, 241, 10):
		for x in range(-240, 241, 10):
			samples += 1
			if field.slope_degrees_at(float(x), float(z)) >= 30.0:
				steep += 1
	print("steep fraction (>=30deg): %.2f%%  [test wants 2%%..45%%]" % (100.0 * steep / samples))

	# 2. The road's last leg (OF10a truncated it to end at 74,-41). Nothing here
	#    may have moved.
	var worst := 0.0
	for i in 60:
		var t := i / 59.0
		var p := Vector2(45.0, -22.0).lerp(Vector2(74.0, -41.0), t)
		worst = maxf(worst, field.slope_degrees_at(p.x, p.y))
	print("road last leg worst slope: %.1f deg  [OF10a measured 13.3]" % worst)

	# 3. A radial transect of peaks[0], east bearing: height, slope, band bias.
	print("--- transect east from (140,-90) ---")
	print(" dist   height   slope  bias  band")
	var line := ""
	for d in range(0, 90, 3):
		var x := 140.0 + d
		var z := -90.0
		var h: float = field.height_at(x, z)
		var s: float = field.slope_degrees_at(x, z, 6.0)
		var b: float = field.rock_bias_deg(x, z)
		var band := "grass"
		if s + b > rock_at:
			band = "ROCK"
		elif s + b > soil_at:
			band = "soil"
		print("%5d %8.2f %7.1f %5.1f  %s" % [d, h, s, b, band])
		line += band.substr(0, 1)
	print("bands: " + line)

	# 4. Material share over the whole rise footprint.
	var counts := {"grass": 0, "soil": 0, "rock": 0}
	var relief_min := INF
	var relief_max := -INF
	for zi in range(-78, 79, 2):
		for xi in range(-78, 79, 2):
			if Vector2(xi, zi).length() >= 78.0:
				continue
			var x := 140.0 + xi
			var z := -90.0 + zi
			var s: float = field.slope_degrees_at(x, z, 6.0) + field.rock_bias_deg(x, z)
			if s > rock_at:
				counts["rock"] += 1
			elif s > soil_at:
				counts["soil"] += 1
			else:
				counts["grass"] += 1
			var r: float = field.height_at(x, z)
			relief_min = minf(relief_min, r)
			relief_max = maxf(relief_max, r)
	var total: int = counts["grass"] + counts["soil"] + counts["rock"]
	print("rise footprint bands: grass %.0f%%  soil %.0f%%  rock %.0f%%" % [
		100.0 * counts["grass"] / total, 100.0 * counts["soil"] / total,
		100.0 * counts["rock"] / total])
	print("rise height range: %.1f .. %.1f" % [relief_min, relief_max])
	quit(0)
