extends SceneTree

## Throwaway probe for OF12-remainder: dump `trees` layer instances near the
## Rise route's first leg viewpoint (capture_paths.gd's "the-rise-route",
## eye (27,-15) -> target (45,-22)) so the mirrored-stand symmetry can be
## measured and re-checked after a seed nudge without a full render.
##
##   godot --headless --path . --script tools/_probe_rise_trees.gd -- [seed_offset]

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")

# The-rise-route viewpoint from tools/capture_paths.gd.
const EYE := Vector2(27.0, -15.0)
const TARGET := Vector2(45.0, -22.0)


func _init() -> void:
	var offset := 0
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		offset = int(args[0])

	var cfg := HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(cfg)
	var world_size := float(cfg.get("world_size", 512.0))
	var base_seed := int(RULES.config().get("seed", 1))

	var veg_cfg: Dictionary = RULES.config().get("layers", {})
	var trees_layer: Dictionary = veg_cfg.get("trees", {}).duplicate(true)

	# Reproduce all_placements' own per-layer offset math for `trees`'
	# position in the layer dict, so the base seed matches exactly what the
	# real build uses.
	var layer_offset := 0
	for name: String in veg_cfg.keys():
		if name.begins_with("_"):
			continue
		if name == "trees":
			break
		layer_offset += 1

	var seed_value := base_seed + layer_offset * 7919 + offset
	var placements: Array[Dictionary] = RULES.placements_for(trees_layer, field, world_size, seed_value)
	print("total trees placed: %d (args=%s)" % [placements.size(), str(args)])

	# Forward direction of the view, for a along-path coordinate; perpendicular
	# for left/right of the route's own line, which is what "mirrored either
	# side of the path" actually means (not raw world X).
	var fwd := (TARGET - EYE).normalized()
	var right := Vector2(fwd.y, -fwd.x)

	# Frustum-ish filter: within the camera's forward view (rough FOV cone)
	# and out to render distance, along the eye->target ray extended
	# arbitrarily far — the frame's "gateway" trees can sit well past the
	# target point, near or past the render horizon.
	var hits: Array = []
	for placement: Dictionary in placements:
		var pos: Vector3 = placement["position"]
		var flat := Vector2(pos.x, pos.z)
		var along := (flat - EYE).dot(fwd)
		var side := (flat - EYE).dot(right)
		if along < 0.0 or along > 150.0:
			continue
		if absf(side) > along * 0.85 + 3.0:
			continue
		hits.append({"pos": flat, "along": along, "side": side, "height": pos.y, "scale": placement["scale"]})

	hits.sort_custom(func(a, b): return a["along"] < b["along"])
	print("--- trees roughly in-frame of the-rise-route (seed_offset=%d) ---" % offset)
	var left_count := 0
	var right_count := 0
	for h: Dictionary in hits:
		var side_label := "LEFT" if h["side"] < 0.0 else "RIGHT"
		if h["side"] < 0.0:
			left_count += 1
		else:
			right_count += 1
		print("  %-5s along=%6.1f side=%6.1f pos=(%.1f,%.1f) h=%.1f scale=%.2f" % [
			side_label, h["along"], h["side"], h["pos"].x, h["pos"].y, h["height"], h["scale"]])
	print("--- counts: left=%d right=%d (total %d) ---" % [left_count, right_count, hits.size()])
	quit(0)
