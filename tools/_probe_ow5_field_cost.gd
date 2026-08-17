extends SceneTree

## OW5 throwaway: which heightfield query is the scatter's load time?
##
##   godot --headless --path . --script tools/_probe_ow5_field_cost.gd
##
## `_probe_ow5_veg_cost.gd` found that the PURE placement pass dominates the
## scatter's build, not the MultiMesh fill or the collider nodes. That matters a
## great deal for OW5, because per-region residency of the RENDERER does not
## touch it: the placement pass would still run over the whole map at load. So
## this asks the next question down — which of `playground_heightfield.gd`'s
## queries `scatter_rules._consider` calls per candidate is actually the cost.
##
## Delete when OW5's scatter half lands or is written up.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const SAMPLES := 4000


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	var field: RefCounted = HEIGHTFIELD.new()

	# Same spread of positions for every method, drawn once, so the comparison
	# is between the methods and not between the points they were asked about.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var points: Array[Vector2] = []
	for i in SAMPLES:
		points.append(Vector2(rng.randf_range(-256.0, 256.0), rng.randf_range(-256.0, 256.0)))

	var methods := [
		"height_at", "slope_degrees_at", "normal_at",
		"path_factor", "stream_factor", "river_factor", "drain_factor",
		"nearest_point_on_paths",
	]
	print("per-call cost over %d samples (microseconds):" % SAMPLES)
	var total := 0.0
	for name: String in methods:
		if not field.has_method(name):
			print("  %-24s (absent)" % name)
			continue
		var started := Time.get_ticks_usec()
		for p: Vector2 in points:
			field.call(name, p.x, p.y)
		var elapsed := float(Time.get_ticks_usec() - started)
		total += elapsed / SAMPLES
		print("  %-24s %8.1f us/call   (%7.1f ms for %d)" % [
			name, elapsed / SAMPLES, elapsed / 1000.0, SAMPLES
		])
	print("  %-24s %8.1f us  <- one candidate that reaches every gate" % ["SUM", total])

	quit()
