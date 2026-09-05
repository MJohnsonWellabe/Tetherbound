extends SceneTree

## W05-TREELINE-0904. Reads the committed scatter bake and reports, per tree
## layer, the rendered HEIGHT distribution in metres against the 1.80 m
## trainer -- the number closure plan CL-B2 / FINISH_THE_MEADOWS 1.2 are
## written in ("grow the trees to 12-18 m, >=3x scale variance per family").
##
##   godot --headless --path . --script tools/_probe_tree_heights_0904.gd
##
## Height = native mesh AABB height (read from the imported glTF scene, not
## guessed) x the baked per-instance scale (which already includes the layer's
## `base_scale` and any `model_scale`; see scatter_rules.gd::_consider). Nothing
## here places anything; it is a reader over data/scatter/playground.

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")
const WORLD_NAME := "playground"
const LAYERS := ["trees", "grove", "saplings", "deadfall"]
## Band 1 (Lower Meadows) is the route the named stands sit on: z < 1450.
const BAND1_Z_MAX := 1450.0


func _init() -> void:
	var seed := int(RULES.config().get("seed", 1))
	if not BAKE.is_fresh(WORLD_NAME, seed):
		print("WARNING: bake is not fresh against the live config")
	var drained: Dictionary = {}
	var by_layer: Dictionary = BAKE.load_all(WORLD_NAME, drained)
	var native: Dictionary = {}
	for layer_name in LAYERS:
		var placements: Array = by_layer.get(layer_name, [])
		print("\n== %s: %d placements" % [layer_name, placements.size()])
		var all_h: Array[float] = []
		var band1_h: Array[float] = []
		var per_model: Dictionary = {}
		for p: Dictionary in placements:
			var model := str(p["model"])
			if not native.has(model):
				native[model] = _native_height(model)
			var h := float(native[model]) * float(p["scale"])
			all_h.append(h)
			var pos: Vector3 = p["position"]
			if pos.z < BAND1_Z_MAX:
				band1_h.append(h)
			if not per_model.has(model):
				per_model[model] = []
			(per_model[model] as Array).append(h)
		_report("  all   ", all_h)
		_report("  band1 ", band1_h)
		for model: String in per_model.keys():
			var heights: Array[float] = []
			for v: Variant in per_model[model]:
				heights.append(float(v))
			print("  %s native %.2f m" % [model.get_file(), float(native[model])])
			_report("    ", heights)
	quit(0)


func _report(label: String, heights: Array[float]) -> void:
	if heights.is_empty():
		print("%s(none)" % label)
		return
	heights.sort()
	var n := heights.size()
	var over12 := 0
	var over8 := 0
	var over15 := 0
	for h in heights:
		if h >= 12.0:
			over12 += 1
		if h >= 8.0:
			over8 += 1
		if h >= 15.0:
			over15 += 1
	print("%sn=%d min %.1f p5 %.1f p25 %.1f p50 %.1f p75 %.1f p95 %.1f max %.1f | max/min %.2f p95/p5 %.2f | >=8m %.1f%% >=12m %.1f%% >=15m %.1f%% | x trainer(1.80): p50 %.1fx max %.1fx" % [
		label, n, heights[0], _pct(heights, 0.05), _pct(heights, 0.25), _pct(heights, 0.5),
		_pct(heights, 0.75), _pct(heights, 0.95), heights[n - 1],
		heights[n - 1] / maxf(heights[0], 0.01), _pct(heights, 0.95) / maxf(_pct(heights, 0.05), 0.01),
		100.0 * over8 / n, 100.0 * over12 / n, 100.0 * over15 / n,
		_pct(heights, 0.5) / 1.8, heights[n - 1] / 1.8])


func _pct(sorted: Array[float], q: float) -> float:
	var idx := clampi(int(round(q * (sorted.size() - 1))), 0, sorted.size() - 1)
	return sorted[idx]


## Native (scale 1.0) height of a model: merged AABB of every MeshInstance3D in
## the imported scene, in the scene's own space.
func _native_height(model: String) -> float:
	var packed: PackedScene = load(model)
	if packed == null:
		push_error("cannot load %s" % model)
		return 0.0
	var node: Node = packed.instantiate()
	var lo := INF
	var hi := -INF
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is MeshInstance3D and (current as MeshInstance3D).mesh != null:
			var mi := current as MeshInstance3D
			var aabb: AABB = mi.mesh.get_aabb()
			# Transform relative to the scene root (accumulate parents' transforms).
			var xf: Transform3D = Transform3D.IDENTITY
			var walker: Node = mi
			while walker != null and walker != node:
				if walker is Node3D:
					xf = (walker as Node3D).transform * xf
				walker = walker.get_parent()
			var world_aabb: AABB = xf * aabb
			lo = minf(lo, world_aabb.position.y)
			hi = maxf(hi, world_aabb.end.y)
		for child in current.get_children():
			stack.append(child)
	node.free()
	if lo == INF:
		return 0.0
	return hi - lo
