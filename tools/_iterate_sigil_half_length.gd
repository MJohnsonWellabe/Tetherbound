extends SceneTree

## SCRATCH: fast analytic (unbaked) iteration to find the half_length that
## closes the 45deg-WALKABLE causeway (not just the literal zero-depth
## causeway) down to the leaf's own world-x span, 61.8..65.4. Mutates
## half_length for BOTH sigil_gate_gorge_west/_east in-memory (kept
## symmetric, same as the authored config) and re-measures with a fine
## sweep along the gate's own forward line (along_offset 0), which the baked
## probe showed is the binding case.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const GATE_AT := Vector2(63.6, 7400.0)
const GATE_YAW_DEG := -28.6
const CELL := 0.25


func _init() -> void:
	var base_config := HEIGHTFIELD.load_config()
	var yaw := deg_to_rad(GATE_YAW_DEG)
	var across := Vector2(cos(yaw), -sin(yaw)).normalized()

	for hl in [49.0, 50.0, 50.5, 51.0, 51.5, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0]:
		var config := base_config.duplicate(true)
		for entry: Variant in config["crossings"]:
			var d: Dictionary = entry as Dictionary
			if d.get("id", "") in ["sigil_gate_gorge_west", "sigil_gate_gorge_east"]:
				(d["carve"] as Dictionary)["half_length"] = hl
		var field: RefCounted = HEIGHTFIELD.new(config)
		_report(field, hl, across, 45.0)
	quit(0)


func _report(field: RefCounted, hl: float, across: Vector2, limit_deg: float) -> void:
	var limit_tan := tan(deg_to_rad(limit_deg))
	var runs: Array = []
	var run_start = null
	var last_ok := false
	var a := -30.0
	while a <= 30.0:
		var spot := GATE_AT + across * a
		var ok := _standable(field, spot, limit_tan)
		if ok and not last_ok:
			run_start = a
		if (not ok) and last_ok:
			runs.append([run_start, a - CELL])
		last_ok = ok
		a += CELL
	if last_ok:
		runs.append([a if run_start == null else run_start, a])
	var descr := ""
	for r in runs:
		var lo: float = r[0]
		var hi: float = r[1]
		var x_lo: float = GATE_AT.x + across.x * lo
		var x_hi: float = GATE_AT.x + across.x * hi
		descr += " [world-x %.2f..%.2f, %.2fm]" % [minf(x_lo, x_hi), maxf(x_lo, x_hi), hi - lo]
	if descr == "":
		descr = " NONE STANDABLE (fully closed)"
	print("half_length %.1f: %s deg standable near gate:%s" % [hl, str(limit_deg), descr])


func _standable(field: RefCounted, at: Vector2, limit_tan: float) -> bool:
	var h := float(field.call("height_at", at.x, at.y))
	if is_nan(h):
		return false
	var e := float(field.call("height_at", at.x + CELL, at.y))
	var w := float(field.call("height_at", at.x - CELL, at.y))
	var n := float(field.call("height_at", at.x, at.y + CELL))
	var s := float(field.call("height_at", at.x, at.y - CELL))
	if is_nan(e) or is_nan(w) or is_nan(n) or is_nan(s):
		return false
	var dx := (e - w) / (2.0 * CELL)
	var dz := (n - s) / (2.0 * CELL)
	return sqrt(dx * dx + dz * dz) <= limit_tan
