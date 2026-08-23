extends SceneTree

## Read the BAKED control map back and report what it actually says.
##
## The bake prints "dry-grass macro variation on N pixels" but a render showed
## no low-frequency change, so the question is whether the data is wrong or the
## shader is not expressing it. This samples real world positions and decodes
## base id / overlay id / blend straight out of the region data.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	_run()

func _run() -> void:
	var cfg := HEIGHTFIELD.load_config()
	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", int(cfg.get("region_size", 256)))
	terrain.set("vertex_spacing", float(cfg.get("vertex_spacing", 2.0)))
	terrain.set("data_directory", "res://data/terrain/playground")
	root.add_child(terrain)
	await process_frame
	var data: Object = terrain.get("data")
	if data == null:
		print("no data object")
		quit(1)
		return

	var counts := {}
	var blends: Array[float] = []
	var samples := 0
	# A 400m square around the band-1 viewpoint, stepped so we cross several
	# macro periods (drift is ~180m).
	for gz in range(0, 60, 4):
		for gx in range(-25, 26, 4):
			var pos := Vector3(8.0 + gx, 0.0, 90.0 + gz)
			var base: int = data.call("get_control_base_id", pos)
			var over: int = data.call("get_control_overlay_id", pos)
			var blend: float = data.call("get_control_blend", pos)
			var key := "base=%d overlay=%d" % [base, over]
			counts[key] = int(counts.get(key, 0)) + 1
			blends.append(blend)
			samples += 1

	print("sampled %d points in the VISIBLE near field ahead of the player" % samples)
	for k in counts.keys():
		print("  %-22s %d" % [k, counts[k]])
	var lo := 1.0
	var hi := 0.0
	var sum := 0.0
	for b in blends:
		lo = minf(lo, b)
		hi = maxf(hi, b)
		sum += b
	print("blend: min %.3f  max %.3f  mean %.3f" % [lo, hi, sum / maxf(1.0, float(blends.size()))])
	quit(0)
