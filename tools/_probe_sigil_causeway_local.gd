extends SceneTree

## SCRATCH DIAGNOSTIC -- answers the coordinator's fade-mouth-leak question
## directly against the BAKED surface, restricted tightly to the Sigil Gate's
## own causeway rather than the huge windows _probe_crossings.gd's generic
## per-crossing report uses (those windows are wide enough to swallow
## unrelated open terrain far from the gate and are not useful for reading
## off "how wide is the walkable gap beside the leaf").
##
## Works in the GATE's own local frame: `across` = world direction of the
## gate leaf's own width (perpendicular to travel, matches the carve axis
## 28.6deg); `along` = travel direction (perpendicular to that). For a grid
## of `along` offsets (straddling BOTH gorge fade mouths, not just the gate's
## own position) and a fine sweep of `across` offsets, checks BAKED-surface
## standability at 45deg (player) and 60deg (ridden legendary) by local
## central-difference gradient -- the same criterion smoke_traversal.gd's
## test applies to a real physics body, just cheaper to sweep densely here.
## Reports the widest CONTIGUOUS standable run of `across` offsets at each
## `along` row, which is the true "how far can you walk sideways here"
## answer -- not a windowed connectivity flood fill.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const GATE_AT := Vector2(63.6, 7400.0)
const GATE_YAW_DEG := -28.6

const CELL := 0.5
const BOOT_FRAMES := 60

var _terrain_data: Object = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in BOOT_FRAMES:
		await physics_frame
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null:
		print("FAIL no Terrain node")
		quit(1)
		return
	_terrain_data = terrain.get("data")
	if _terrain_data == null:
		print("FAIL Terrain3D has no data")
		quit(1)
		return

	var yaw := deg_to_rad(GATE_YAW_DEG)
	var across := Vector2(cos(yaw), -sin(yaw)).normalized()  # basis.x world (x,z) for a Y rotation
	# `along` = perpendicular to across, standardised toward +z, matching the test file.
	var along := Vector2(-across.y, across.x)
	if along.y < 0.0:
		along = -along
	print("gate at %v, across=%v, along=%v" % [GATE_AT, across, along])

	# `along` offsets: straddle the gate's own position AND both fade mouths.
	# west centre is ~61m in the -across direction from the gate along `across`
	# itself (both gorge centres sit on the SAME axis as the gate -- see the
	# terrain_playground.json _why), so the fade mouths are found by scanning
	# `across` at along=0 (the gate's own forward position) -- that is the
	# ONE along-offset that matters for "can a player slip past the leaf
	# without moving forward/back", so sweep a few along offsets around 0
	# too, in case the true choke is not exactly at the gate's own z.
	var along_offsets: Array[float] = [-8.0, -4.0, 0.0, 4.0, 8.0]
	for ao in along_offsets:
		_scan_row(ao, across, along, 45.0, "player 45deg")
	print("")
	for ao in along_offsets:
		_scan_row(ao, across, along, 60.0, "mount  60deg")

	print("")
	print("Leaf's own world-x span is 61.8..65.4 (3.6m) -- compare the runs above to that.")
	quit(0)


func _scan_row(along_offset: float, across: Vector2, along: Vector2, limit_deg: float, label: String) -> void:
	var limit_tan := tan(deg_to_rad(limit_deg))
	var base := GATE_AT + along * along_offset
	var runs: Array = []
	var run_start = null
	var last_ok := false
	var a := -90.0
	while a <= 90.0:
		var spot := base + across * a
		var ok := _standable(spot, limit_tan)
		if ok and not last_ok:
			run_start = a
		if (not ok) and last_ok:
			runs.append([run_start, a - CELL])
		last_ok = ok
		a += CELL
	if last_ok:
		runs.append([run_start, a - CELL])

	var descr := ""
	for r in runs:
		var lo: float = r[0]
		var hi: float = r[1]
		var x_lo: float = base.x + across.x * lo
		var x_hi: float = base.x + across.x * hi
		descr += " [across %.1f..%.1f = world-x %.1f..%.1f, %.1fm]" % [
			lo, hi, minf(x_lo, x_hi), maxf(x_lo, x_hi), hi - lo]
	if descr == "":
		descr = " NONE STANDABLE"
	print("%s, along_offset %+.1f: standable across-runs:%s" % [label, along_offset, descr])


func _standable(at: Vector2, limit_tan: float) -> bool:
	var h := _h(at)
	if is_nan(h):
		return false
	var e := _h(at + Vector2(CELL, 0.0))
	var w := _h(at - Vector2(CELL, 0.0))
	var n := _h(at + Vector2(0.0, CELL))
	var s := _h(at - Vector2(0.0, CELL))
	if is_nan(e) or is_nan(w) or is_nan(n) or is_nan(s):
		return false
	var dx := (e - w) / (2.0 * CELL)
	var dz := (n - s) / (2.0 * CELL)
	return sqrt(dx * dx + dz * dz) <= limit_tan


func _h(at: Vector2) -> float:
	return float(_terrain_data.call("get_height", Vector3(at.x, 0.0, at.y)))
