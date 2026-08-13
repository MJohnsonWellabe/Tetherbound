extends SceneTree
## Throwaway: does the river gorge get a water surface, or is it a dry trench?
## Reproduces water.gd::_region() and _build_pond()'s wet-cell flood fill on the
## heightfield alone, then asks how many kept cells sit over the gorge.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


func _init() -> void:
	var field := HEIGHTFIELD.new()
	var cfg: Dictionary = HEIGHTFIELD.load_config()
	var level := float(field.water_level())
	var water: Dictionary = cfg.get("water", {})
	var centre_arr: Array = water.get("pond_centre", [0.0, 0.0])
	var c := Vector2(float(centre_arr[0]), float(centre_arr[1]))
	print("water level %.2f  pond centre %s" % [level, c])

	# --- region, exactly as water.gd ---
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for z in range(int(c.y) - 90, int(c.y) + 91, 4):
		for x in range(int(c.x) - 90, int(c.x) + 91, 4):
			if field.height_at(float(x), float(z)) < level:
				lo = Vector2(minf(lo.x, x), minf(lo.y, z))
				hi = Vector2(maxf(hi.x, x), maxf(hi.y, z))
	for entry: Variant in water.get("stream", {}).get("points", []):
		var p := Vector2(float(entry[0]), float(entry[1]))
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	lo -= Vector2(6, 6)
	hi += Vector2(6, 6)
	var region := Rect2(lo, hi - lo)
	print("region %s  size %s" % [region.position, region.size])

	# --- wet cells + flood fill, exactly as water.gd ---
	var step := 2.0
	var cols := int(ceil(region.size.x / step))
	var rows := int(ceil(region.size.y / step))
	var wet: Dictionary = {}
	for row in rows:
		var z0 := region.position.y + row * step
		for col in cols:
			var x0 := region.position.x + col * step
			for corner: Vector2 in [
				Vector2(x0, z0), Vector2(x0 + step, z0),
				Vector2(x0, z0 + step), Vector2(x0 + step, z0 + step)
			]:
				if field.height_at(corner.x, corner.y) < level + 0.5:
					wet[Vector2i(col, row)] = true
					break
	var seed_cell := Vector2i(
		int((c.x - region.position.x) / step), int((c.y - region.position.y) / step))
	var kept: Dictionary = {}
	if wet.has(seed_cell):
		var frontier: Array[Vector2i] = [seed_cell]
		kept[seed_cell] = true
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for offset: Vector2i in [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
			]:
				var next := cell + offset
				if wet.has(next) and not kept.has(next):
					kept[next] = true
					frontier.append(next)
	print("wet cells %d   kept (connected to pond) %d   orphaned %d"
		% [wet.size(), kept.size(), wet.size() - kept.size()])

	# --- how much of that is the gorge? ---
	var gorge := Vector2(-93.9, 176.6)
	var near_wet := 0
	var near_kept := 0
	for cell: Vector2i in wet.keys():
		var p := region.position + Vector2(cell.x, cell.y) * step
		if p.distance_to(gorge) < 60.0:
			near_wet += 1
			if kept.has(cell):
				near_kept += 1
	print("within 60m of the gorge centre: wet %d, kept %d" % [near_wet, near_kept])

	# --- gorge cross-section and floor ---
	var axis := deg_to_rad(26.3)
	var dir := Vector2(cos(axis), sin(axis))
	var nrm := Vector2(-dir.y, dir.x)
	print("gorge cross-section (v = metres across the axis at the centre):")
	var line := ""
	for i in range(-20, 21, 2):
		var p := gorge + nrm * float(i)
		line += "  v%+d=%.1f" % [i, field.height_at(p.x, p.y)]
		if i % 8 == 0:
			print(line)
			line = ""
	if line != "":
		print(line)
	print("gorge floor along its own axis:")
	line = ""
	for i in range(-80, 81, 20):
		var p := gorge + dir * float(i)
		line += "  u%+d=%.1f" % [i, field.height_at(p.x, p.y)]
	print(line)

	# --- the storm ravine, for contrast ---
	var ravine := Vector2(193.2, 51.8)
	print("storm ravine floor %.1f (level %.1f)" % [field.height_at(ravine.x, ravine.y), level])
	quit()
