extends SceneTree

const RULES := preload("res://scripts/world/scatter_rules.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size: float = float(HEIGHTFIELD.load_config().get("world_size", 512))
	var cfg: Dictionary = RULES.config()
	var layers: Dictionary = cfg.get("layers", {})
	var base_seed: int = int(cfg.get("seed", 1))

	var offset := 0
	for name: String in layers.keys():
		if str(name).begins_with("_"):
			continue
		var layer: Dictionary = layers[name]
		var seed_value := base_seed + offset * 7919 + int(layer.get("seed_offset", 0))
		var removed: Array[Dictionary] = []
		var t0 := Time.get_ticks_msec()
		var result: Array = RULES.placements_for(layer, field, world_size, seed_value, removed)
		var t1 := Time.get_ticks_msec()
		print("layer '%s': %d ms, %d placements" % [name, t1 - t0, result.size()])
		offset += 1

	quit(0)
