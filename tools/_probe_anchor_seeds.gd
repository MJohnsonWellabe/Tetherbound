extends SceneTree

## STRONGHOLD-R2 scratch: how many of a scatter anchor's wanted instances
## actually place, across the seeds the suite uses. Run with and without the
## stronghold approach road in `terrain_playground.json` to find out whether a
## "placed 0 of N" warning is one the road introduced or one that was already
## there.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const RULES := preload("res://scripts/world/scatter_rules.gd")


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var world_size := float(HEIGHTFIELD.load_config().get("world_size", 512))
	var layers: Dictionary = RULES.config().get("layers", {})
	var trees: Dictionary = layers.get("trees", {})
	for seed_value in [1, 2, 99]:
		print("--- seed %d" % seed_value)
		RULES.placements_for(trees, field, world_size, seed_value)
	quit(0)
