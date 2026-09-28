extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var prefabs := preload("res://scripts/world/building_prefabs.gd").new()
	prefabs.load_recipes()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = data.settlement.occupied_terrace
	var failures := 0
	for house: Dictionary in data.settlement.houses:
		if not house.has("upper_terrace_position"):
			continue
		var key: String = house.prefab
		var model: Node3D = prefabs.instantiate(key)
		root.add_child(model)
		var local_bounds: AABB = prefabs.combined_aabb(model)
		var at: Array = house.upper_terrace_position
		var placed := Transform3D(Basis(Vector3.UP, PI), Vector3(float(at[0]),float(cfg.height_m),float(at[2]))) * local_bounds
		var far_corner := placed.position + placed.size
		var fits := placed.position.x >= float(cfg.west_x) and far_corner.x <= float(cfg.east_x) \
			and placed.position.z >= float(cfg.front_z) and far_corner.z <= float(cfg.back_z)
		print("PREFAB_BOUNDS ",key," local=",local_bounds," occupied=",placed," floor_fit=",fits)
		if not fits:
			failures += 1
		model.free()
	print("STAGGERED PREFAB FIT failures=",failures)
	quit(0 if failures == 0 else 1)
