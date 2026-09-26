extends SceneTree

## F07#2 review (b): world-wide audit of the shoulder overpass clearance.
## Builds the production Cloudreach world once with the shoulder audit hook on,
## then re-evaluates every route-shoulder top vertex through the production
## `_walkable_height` twice -- without the clearance (main: every road/deck
## within reach pins the vertex) and with `landmass.shoulder_overpass_clearance_m`
## (branch) -- and reports how many vertices changed, where, and the largest
## adjacent-vertex height jump the cutoff introduces on the shoulder grid.
##
##   godot --headless --path . --script tools/audit_cloudreach_shoulder_overpass.gd
##
## Output: one `SHOULDER OVERPASS AUDIT {json}` line plus per-vertex lines.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const CHANGED_EPS_M := 0.01


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("save_system", SAVE.new("user://audit_shoulder_overpass/"))
	game.set("current_realm", "cloudreach")
	var world: Node3D = SCENE.instantiate()
	world.set("record_shoulder_audit", true)
	root.add_child(world)
	current_scene = world
	for i in 20000:
		await process_frame
		if bool(world.call("shell_build_complete")) and i > 5:
			break
	if not bool(world.call("shell_build_complete")):
		push_error("audit: Cloudreach did not build")
		quit(1)
		return
	var vertices: Array[Dictionary] = world.get("shoulder_audit_vertices")
	var lines: Array[Dictionary] = world.get("_all_route_lines")
	var pads: Array[Dictionary] = world.get("_all_pad_points")
	var landmass: Dictionary = (world.get("_visual_config") as Dictionary).get("landmass", {})
	var clearance := float(landmass.get("shoulder_overpass_clearance_m", INF))
	# Grid of both heights per ridge: key "ridge|row|col" -> [main, branch, raw].
	var grid := {}
	var changed: Array[Dictionary] = []
	var by_ridge := {}
	for v: Dictionary in vertices:
		var raw: Vector3 = v["raw"]
		landmass.erase("shoulder_overpass_clearance_m")
		var h_main := float(world.call("_walkable_height", raw, raw.y, lines, pads))
		landmass["shoulder_overpass_clearance_m"] = clearance
		var h_branch := float(world.call("_walkable_height", raw, raw.y, lines, pads))
		var key := "%s|%d|%d" % [v.ridge, v.row, v.column]
		grid[key] = [h_main, h_branch, raw]
		if absf(h_branch - h_main) > CHANGED_EPS_M:
			changed.append({"ridge": v.ridge, "row": v.row, "column": v.column,
				"x": snappedf(raw.x, 0.1), "z": snappedf(raw.z, 0.1),
				"natural_y": snappedf(raw.y, 0.01), "main_y": snappedf(h_main, 0.01),
				"branch_y": snappedf(h_branch, 0.01), "delta_m": snappedf(h_branch - h_main, 0.01)})
			by_ridge[v.ridge] = int(by_ridge.get(v.ridge, 0)) + 1
	# Adjacent jumps on the shoulder grid: along a row (columns) and between rows.
	var max_main_jump := {"jump_m": 0.0}
	var max_branch_jump := {"jump_m": 0.0}
	var max_introduced := {"introduced_m": 0.0}
	var max_branch_slope_at_changed := {"slope_deg": 0.0}
	# The cutoff's own step: a changed (now natural) vertex beside one the
	# branch still pins to a road. Its jump beyond the authored (natural)
	# shoulder shape is what the all-or-nothing 30 m cutoff adds.
	var max_cutoff_step := {"beyond_authored_m": 0.0}
	var cutoff_pairs := 0
	for key: String in grid:
		var parts := key.split("|")
		var ridge := parts[0]
		var row := int(parts[1])
		var column := int(parts[2])
		for n: String in ["%s|%d|%d" % [ridge, row + 1, column], "%s|%d|%d" % [ridge, row, column + 1]]:
			if not grid.has(n):
				continue
			var a: Array = grid[key]
			var b: Array = grid[n]
			var raw_a: Vector3 = a[2]
			var raw_b: Vector3 = b[2]
			var flat := Vector2(raw_a.x - raw_b.x, raw_a.z - raw_b.z).length()
			var jm := absf(float(a[0]) - float(b[0]))
			var jb := absf(float(a[1]) - float(b[1]))
			var where := {"ridge": ridge, "a": [row, column], "b": n.split("|").slice(1),
				"x": snappedf(raw_a.x, 0.1), "z": snappedf(raw_a.z, 0.1), "flat_m": snappedf(flat, 0.01)}
			if jm > float(max_main_jump.jump_m):
				max_main_jump = where.duplicate()
				max_main_jump["jump_m"] = snappedf(jm, 0.01)
			if jb > float(max_branch_jump.jump_m):
				max_branch_jump = where.duplicate()
				max_branch_jump["jump_m"] = snappedf(jb, 0.01)
			var a_changed := absf(float(a[1]) - float(a[0])) > CHANGED_EPS_M
			var b_changed := absf(float(b[1]) - float(b[0])) > CHANGED_EPS_M
			if not (a_changed or b_changed):
				continue
			var jn := absf(raw_a.y - raw_b.y)
			var a_pinned := absf(float(a[1]) - raw_a.y) > CHANGED_EPS_M
			var b_pinned := absf(float(b[1]) - raw_b.y) > CHANGED_EPS_M
			if (a_changed and b_pinned) or (b_changed and a_pinned):
				cutoff_pairs += 1
				if jb - jn > float(max_cutoff_step.beyond_authored_m) or cutoff_pairs == 1:
					max_cutoff_step = where.duplicate()
					max_cutoff_step["beyond_authored_m"] = snappedf(jb - jn, 0.01)
					max_cutoff_step["branch_jump_m"] = snappedf(jb, 0.01)
					max_cutoff_step["authored_jump_m"] = snappedf(jn, 0.01)
					max_cutoff_step["main_jump_m"] = snappedf(jm, 0.01)
			if jb - jm > float(max_introduced.introduced_m):
				max_introduced = where.duplicate()
				max_introduced["introduced_m"] = snappedf(jb - jm, 0.01)
				max_introduced["main_jump_m"] = snappedf(jm, 0.01)
				max_introduced["branch_jump_m"] = snappedf(jb, 0.01)
				max_introduced["authored_jump_m"] = snappedf(jn, 0.01)
			var slope := rad_to_deg(atan2(jb, maxf(flat, 0.001)))
			if slope > float(max_branch_slope_at_changed.slope_deg):
				max_branch_slope_at_changed = where.duplicate()
				max_branch_slope_at_changed["slope_deg"] = snappedf(slope, 0.1)
				max_branch_slope_at_changed["branch_jump_m"] = snappedf(jb, 0.01)
				max_branch_slope_at_changed["main_jump_m"] = snappedf(jm, 0.01)
	var bounds := {}
	if not changed.is_empty():
		var min_x := INF
		var max_x := -INF
		var min_z := INF
		var max_z := -INF
		var max_delta := 0.0
		for c: Dictionary in changed:
			min_x = minf(min_x, float(c.x))
			max_x = maxf(max_x, float(c.x))
			min_z = minf(min_z, float(c.z))
			max_z = maxf(max_z, float(c.z))
			max_delta = maxf(max_delta, absf(float(c.delta_m)))
		bounds = {"x": [min_x, max_x], "z": [min_z, max_z], "max_abs_delta_m": max_delta}
	for c: Dictionary in changed:
		print("SHOULDER OVERPASS CHANGED " + JSON.stringify(c))
	print("SHOULDER OVERPASS AUDIT " + JSON.stringify({
		"clearance_m": clearance, "shoulder_top_vertices": vertices.size(),
		"ridges": _ridge_count(vertices), "changed_vertices": changed.size(),
		"changed_by_ridge": by_ridge, "changed_bounds": bounds,
		"max_adjacent_jump_main": max_main_jump, "max_adjacent_jump_branch": max_branch_jump,
		"max_adjacent_jump_introduced": max_introduced,
		"max_slope_at_changed_pair": max_branch_slope_at_changed,
		"cutoff_pairs_changed_beside_pinned": cutoff_pairs, "max_cutoff_step": max_cutoff_step,
		"arch_stations": _arches(world)}))
	quit(0)


func _arches(world: Node) -> Array:
	var out: Array = []
	for a: Dictionary in world.get("shoulder_audit_arches"):
		out.append({"ridge": a.ridge, "station": a.station, "ceiling_y": snappedf(float(a.ceiling), 0.1),
			"centre": [snappedf(a.centre.x, 0.1), snappedf(a.centre.y, 0.1), snappedf(a.centre.z, 0.1)]})
	return out


func _ridge_count(vertices: Array[Dictionary]) -> int:
	var seen := {}
	for v: Dictionary in vertices:
		seen[v.ridge] = true
	return seen.size()
