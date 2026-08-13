extends SceneTree

## EV5-remainder-2 (outlet) — close-up of the pond/gorge junction.
##
##   godot --headless --path . --script tools/_probe_outlet_neck.gd
##
## Prints the junction box at 2m with the height above/below the waterline as a
## single character, so the sill between the pond's north-east lobe and the
## gorge's north-west rim can be read off directly, and reports the narrowest
## wet cross-section of the connection (the "neck width" the outlet is judged
## on).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var cfg: Dictionary = HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(cfg)
	var water: Dictionary = cfg.get("water", {})
	var level := float(water.get("level", -22.5))

	print("legend per 2m cell, relative to waterline %.2f:" % level)
	print("  '~' >2m deep   '=' 0.5-2m deep   '-' 0-0.5m deep")
	print("  ':' 0-0.5m dry '+' 0.5-2m dry    '#' >2m dry")
	print("x from -150 (left) to -100, z from 130 (top) to 175\n")
	var header := "      "
	for col in range(26):
		header += ("|" if (int(-150 + col * 2) % 10 == 0) else " ")
	print(header)
	for row in range(23):
		var z := 130.0 + row * 2.0
		var line := "z%+5.0f " % z
		for col in range(26):
			var x := -150.0 + col * 2.0
			var d: float = level - float(field.call("height_at", x, z))
			if d > 2.0:
				line += "~"
			elif d > 0.5:
				line += "="
			elif d > 0.0:
				line += "-"
			elif d > -0.5:
				line += ":"
			elif d > -2.0:
				line += "+"
			else:
				line += "#"
		print(line)

	# Narrowest wet cross-section across the pond -> gorge corridor. Sweep a
	# line perpendicular to the pond-centre -> gorge-centre direction and take
	# the total wet length on it, over stations between the two.
	var pc: Array = water.get("pond_centre", [0, 0])
	var centre := Vector2(float(pc[0]), float(pc[1]))
	var gc := _gorge_centre(cfg)
	var dir := (gc - centre).normalized()
	var perp := Vector2(-dir.y, dir.x)
	print("\nwet cross-section along the pond->gorge line (bearing %.1f deg):" % rad_to_deg(atan2(dir.y, dir.x)))
	var narrowest := INF
	var narrowest_at := 0.0
	for i in range(10, 46):
		var d := float(i)
		var base := centre + dir * d
		var wet := 0.0
		var bands := 0
		var was := false
		for j in range(-80, 81):
			var q := base + perp * (float(j) * 0.5)
			var w: bool = float(field.call("height_at", q.x, q.y)) < level
			if w:
				wet += 0.5
				if not was:
					bands += 1
			was = w
		if d >= 16.0 and d <= 34.0 and wet < narrowest:
			narrowest = wet
			narrowest_at = d
		print("  d %5.1f  wet %5.1fm  bands %d" % [d, wet, bands])
	print("NECK: narrowest wet width between d=16 and d=34 is %.1fm at d=%.1f" % [narrowest, narrowest_at])

	quit()


func _gorge_centre(cfg: Dictionary) -> Vector2:
	for entry: Variant in cfg.get("spokes", {}).get("routes", []):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == "river_gorge":
			var c: Array = (((entry as Dictionary).get("blocker", {}) as Dictionary)
				.get("carve", {}) as Dictionary).get("centre", [0, 0])
			return Vector2(float(c[0]), float(c[1]))
	return Vector2.ZERO
