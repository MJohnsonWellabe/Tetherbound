extends SceneTree

## Throwaway probe for EV2-landmark-ceiling's blind-judge verification: dump
## the `grove` layer's real placements so a close-up viewpoint can be picked
## deliberately, rather than hoping one of tools/survey.gd's five fixed
## camera positions happens to land near a clump (it didn't -- a first blind
## pass against the standard survey never named a wide-canopy hero tree at
## all, which is as consistent with "not in any of those five frames" as
## with "still doesn't read as one"). Same seed-reproduction approach as
## tools/_probe_rise_trees.gd, applied to `grove` instead of `trees`.
##
##   godot --headless --path . --script tools/_probe_grove.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")


func _init() -> void:
	var cfg := HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(cfg)
	var world_size := float(cfg.get("world_size", 512.0))
	var base_seed := int(RULES.config().get("seed", 1))

	var veg_cfg: Dictionary = RULES.config().get("layers", {})
	var grove_layer: Dictionary = veg_cfg.get("grove", {}).duplicate(true)

	var layer_offset := 0
	for name: String in veg_cfg.keys():
		if name.begins_with("_"):
			continue
		if name == "grove":
			break
		layer_offset += 1

	var seed_value := base_seed + layer_offset * 7919
	var placements: Array[Dictionary] = RULES.placements_for(grove_layer, field, world_size, seed_value)
	print("total grove placements: %d" % placements.size())
	for p: Dictionary in placements:
		var pos: Vector3 = p["position"]
		var model: String = String(p.get("model", "?")).get_file()
		var scale_v: float = float(p.get("scale", 1.0))
		print("  model=%s  pos=(%.1f, %.1f, %.1f)  scale=%.2f" % [model, pos.x, pos.y, pos.z, scale_v])

	quit()
