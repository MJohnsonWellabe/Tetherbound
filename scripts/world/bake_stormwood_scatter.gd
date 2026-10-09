extends SceneTree
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
func _init() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json"))
	var placements := SCATTER.placements(FIELD.new(),world)
	var result := BAKE.write_all("stormwood",placements,{},512.0,int(SCATTER.config().seed),SCATTER.fingerprint())
	print("STORMWOOD SCATTER ",result)
	quit(0 if int(result.kept)>1000 else 1)
