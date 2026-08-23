extends SceneTree

## SCRATCH: a proper confined flood fill (not row samples, not the huge
## corridor-wide window _probe_crossings.gd's generic per-entry report uses)
## restricted tightly to the Sigil Gate's own causeway, against the BAKED
## surface. Seeds the south edge of a narrow z-band straddling the gate and
## asks whether the north edge is reachable ANYWHERE in x, at both 45deg
## (player) and 60deg (ridden legendary) -- the definitive "can you walk
## around" answer, not a proxy for it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BOOT_FRAMES := 60
const CELL := 0.5

# Covers both full-depth zones (west inward corner ~x=56.5, east inward
# corner ~x=70.7 at half_length 53) plus generous margin either side, and a
# z-band tight enough to stay inside the gorges' own footprint rather than
# pulling in unrelated open terrain far away.
const MIN_X := 20.0
const MAX_X := 110.0
const MIN_Z := 7380.0
const MAX_Z := 7420.0

var _terrain_data: Object = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in BOOT_FRAMES:
		await physics_frame
	var terrain: Node = world.get_node_or_null(^"Terrain")
	_terrain_data = terrain.get("data")
	if _terrain_data == null:
		print("FAIL no terrain data")
		quit(1)
		return

	_flood(45.0, "player 45deg")
	_flood(60.0, "mount 60deg")
	quit(0)


func _h(x: float, z: float) -> float:
	return float(_terrain_data.call("get_height", Vector3(x, 0.0, z)))


func _flood(limit_deg: float, label: String) -> void:
	var cols := int((MAX_X - MIN_X) / CELL) + 1
	var rows := int((MAX_Z - MIN_Z) / CELL) + 1
	var rise := tan(deg_to_rad(limit_deg)) * CELL

	var height := PackedFloat32Array()
	height.resize(cols * rows)
	for j in rows:
		var z := MIN_Z + float(j) * CELL
		for i in cols:
			height[j * cols + i] = _h(MIN_X + float(i) * CELL, z)

	var seen := PackedByteArray()
	seen.resize(cols * rows)
	var queue := PackedInt32Array()
	for i in cols:
		var idx := i  # row 0 = MIN_Z = south edge
		if is_nan(height[idx]):
			continue
		seen[idx] = 1
		queue.append(idx)

	var head := 0
	var north_reached: Array[int] = []
	while head < queue.size():
		var idx := queue[head]
		head += 1
		var i := idx % cols
		var j := idx / cols
		if j == rows - 1:
			north_reached.append(i)
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := i + step.x
			var nj := j + step.y
			if ni < 0 or ni >= cols or nj < 0 or nj >= rows:
				continue
			var next := nj * cols + ni
			if seen[next] == 1:
				continue
			if is_nan(height[next]) or is_nan(height[idx]):
				continue
			if absf(height[next] - height[idx]) > rise:
				continue
			seen[next] = 1
			queue.append(next)

	print("%s: confined flood x[%.0f,%.0f] z[%.0f,%.0f] at %.1fm cells" % [label, MIN_X, MAX_X, MIN_Z, MAX_Z, CELL])
	if north_reached.is_empty():
		print("  SEALED. South edge cannot reach the north edge anywhere in this window.")
		return
	# Report contiguous x-runs of the north edge reached.
	north_reached.sort()
	var runs: Array = []
	var start_i: int = north_reached[0]
	var prev_i: int = north_reached[0]
	for k in range(1, north_reached.size()):
		var i: int = north_reached[k]
		if i != prev_i + 1:
			runs.append([start_i, prev_i])
			start_i = i
		prev_i = i
	runs.append([start_i, prev_i])
	print("  REACHABLE. North-edge x-run(s):")
	for r in runs:
		var x_lo: float = MIN_X + float(r[0]) * CELL
		var x_hi: float = MIN_X + float(r[1]) * CELL
		print("    world-x %.1f..%.1f (%.1fm)" % [x_lo, x_hi, x_hi - x_lo])
